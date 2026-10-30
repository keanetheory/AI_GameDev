# game_state.gd - the central GameState autoload (Technical Strategy, "Core state contract").
# It owns the phase machine, the single event bus (emit_event), a debug event log and restart().
# Gameplay scripts report what happened by calling GameState.emit_event("BOILER_FED") and nothing else; they
# never set the phase themselves. GameState then
#   - advances the phase (forward only) from the PHASE_ON_EVENT table,
#   - tells the Dialogue autoload (scripts/dialogue/dialogue_loader.gd) so Ted/Arthur/Daniel lines play,
#   - drives the lighting rig's phase (the rig no longer listens to the boat itself),
#   - turns the boat's signals into events (BOAT_CAST_OFF, SALTGATE_REACHED, RETURN_DEPARTED ...).
# Gate 1 retry model: fail, then restart the slice (restart() reloads the scene and clears the attempt).
# It builds no triggers, door, gate, boiler or fail screen: those tasks call emit_event(). The hidden ship deadline and the passenger
# ship are created here at run time (ship_deadline.gd, T07), so the level scene carries neither.
# Debug keys (debug_keys): F9 restarts the slice, F10 prints the event log, F11 fires BURNER_PICKED_UP (until the
# pickup task exists, nothing else does, so without it leaving the Saltgate never starts the RETURN phase).
extends Node

const DebugFlags := preload("res://scripts/core/debug_flags.gd")
const ShipDeadline := preload("res://scripts/core/ship_deadline.gd")
const AudioMixer := preload("res://scripts/core/audio_mixer.gd")
const OutcomeScreen := preload("res://scripts/ui/outcome_screen.gd")
const SailorsSequence := preload("res://scripts/world/sailors_sequence.gd")
const DiagnosisSequence := preload("res://scripts/world/diagnosis_sequence.gd")
const IntroSequence := preload("res://scripts/world/intro_sequence.gd")
const BoardingSequence := preload("res://scripts/world/boarding_sequence.gd")
const CrossingSequence := preload("res://scripts/world/crossing_sequence.gd")
const GuidanceHud := preload("res://scripts/ui/guidance_hud.gd")

signal event_emitted(id: String, phase: int)
signal phase_changed(old_phase: int, new_phase: int)
signal restarted

# Technical Strategy: ARRIVAL_AND_COAL -> SHELTER_AND_GATE -> BEACON_DIAGNOSIS -> BOARDING -> OUTBOUND -> SALTGATE
# -> RETURN -> FINAL_REPAIR -> RESOLUTION (WIN or FAIL).
enum Phase { ARRIVAL_AND_COAL, SHELTER_AND_GATE, BEACON_DIAGNOSIS, BOARDING, OUTBOUND, SALTGATE, RETURN, FINAL_REPAIR, RESOLUTION }
enum Outcome { NONE, WIN, FAIL }

# Stable event IDs: AIAgentCrew/canon.py OPENING_EVENTS, in the same order.
const EVENTS := [
	"GAME_STARTED", "LIGHTHOUSE_ENTERED", "ENGINE_ROOM_ENTERED", "COAL_LOADED_FIRST", "COAL_LOADED_HALF",
	"BOILER_FED", "SAILORS_MOORED", "WINDOW_LOOKED", "GATE_APPROACHED", "GATE_OPENED", "SAILORS_INSIDE",
	"DANIEL_IN_BASEMENT", "BEACON_STILL_DARK", "LAMP_ROOM_ENTERED", "BURNER_DIAGNOSED", "BURNER_BRIEFING",
	"BOARDING_THRESHOLD", "SHIP_SIGHTED", "BOAT_CAST_OFF", "OUTBOUND_NEAR_MISS", "OUTBOUND_COLLISION",
	"SALTGATE_REACHED", "BURNER_PICKED_UP", "RETURN_DEPARTED", "POSTER_EXAMINED", "WALL_WHISPER_HEARD",
	"BASEMENT_BANG", "BASEMENT_TALK", "IDLE_STEP_1", "IDLE_STEP_2", "IDLE_STEP_3", "IDLE_SALTGATE",
	# After the opening: canon.py LATER_EVENTS (accepted by the creator, 19 October 2026; LAMP_ROOM_REENTERED added 29 October 2026).
	"RETURN_ARRIVED", "LAMP_ROOM_REENTERED", "BURNER_FITTED", "SHIP_WIN", "SHIP_FAIL",
]

# These may fire more than once per attempt. Every other event is one-shot: a repeat is logged and ignored.
const REPEATABLE := ["OUTBOUND_NEAR_MISS", "OUTBOUND_COLLISION"]

# The phase an event moves the game to (forward only). Accepted by the creator on 19 October 2026; mirrored in
# canon.py PHASE_ON_EVENT and the Technical Strategy core state contract, so change all three together.
const PHASE_ON_EVENT := {
	"BOILER_FED": Phase.SHELTER_AND_GATE,
	"DANIEL_IN_BASEMENT": Phase.BEACON_DIAGNOSIS,
	"BURNER_BRIEFING": Phase.BOARDING,
	"BOAT_CAST_OFF": Phase.OUTBOUND,
	"SALTGATE_REACHED": Phase.SALTGATE,
	"RETURN_DEPARTED": Phase.RETURN,
	"RETURN_ARRIVED": Phase.FINAL_REPAIR,
	"LAMP_ROOM_REENTERED": Phase.FINAL_REPAIR,
	"BURNER_FITTED": Phase.FINAL_REPAIR,
	"SHIP_WIN": Phase.RESOLUTION,
	"SHIP_FAIL": Phase.RESOLUTION,
}

# Lighting phases (lighting_rig.gd PHASES) per game phase. ISLAND runs from arrival to the beacon diagnosis,
# OUTBOUND covers the boarding, the crossing out and the Saltgate, RETURN the crossing back. BEACON_RELIT is
# set by BURNER_FITTED (see _lighting_target).
const LIGHTING_FOR_PHASE := {
	Phase.ARRIVAL_AND_COAL: "ISLAND",
	Phase.SHELTER_AND_GATE: "ISLAND",
	Phase.BEACON_DIAGNOSIS: "ISLAND",
	Phase.BOARDING: "ISLAND",   # the rig switches to OUTBOUND on cast-off, as it did before GameState
	Phase.OUTBOUND: "OUTBOUND",
	Phase.SALTGATE: "OUTBOUND",
	Phase.RETURN: "RETURN",
	Phase.FINAL_REPAIR: "RETURN",
}

@export var debug_log := true
## F9 restart, F10 event log, F11 burner stand-in. Only ever on in a debug build (see debug_flags.gd).
@export var debug_keys := true
## RETURN_DEPARTED needs BURNER_PICKED_UP first (invariant: a pickup precedes the return). Until the pickup task
## exists nothing fires BURNER_PICKED_UP, so leaving the Saltgate does not start RETURN unless this is off.
@export var require_burner_for_return := true

var phase: int = Phase.ARRIVAL_AND_COAL
var outcome: int = Outcome.NONE
var attempt := 1
var event_log: Array = []        # {t_msec, id, phase, attempt, note} for this attempt
var fired: Dictionary = {}       # one-shot events already fired this attempt
var burner_aboard := false       # set by BURNER_PICKED_UP
var burner_fitted := false       # set by BURNER_FITTED

var _dialogue: Node
var _boat: Node
var _director: Node            # ship_deadline.gd: the hidden clock and the passenger ship
var _mixer: Node               # audio_mixer.gd: the placeholder audio (T14)
var _outcome_screen: Node      # outcome_screen.gd: the Failed screen and the win card (T08)
var _sailors: Node             # sailors_sequence.gd: the rowboat, the gate and the walk-in (T04)
var _diagnosis: Node           # diagnosis_sequence.gd: Ted, the lamp room, the broken burner and the briefing (T05)
var _intro: Node               # intro_sequence.gd: Ted behind the door, the knock, the greeting (creator, 30 Oct 2026)
var _boarding: Node            # boarding_sequence.gd: Arthur walks to the launch, boards, steps ashore on the return (T11)
var _crossing: Node            # crossing_sequence.gd: the return forecast laid on the sea: hazards, safe lane, Arthur's calls (T10)
var _guidance: Node            # guidance_hud.gd: the goal tracker (upper right) and the controls list (lower right) (T54, T55)
var _level_root: Node
var _rig: Node
var _lighting_phase := ""


func _ready() -> void:
	debug_keys = debug_keys and DebugFlags.allowed()
	_dialogue = get_node_or_null("/root/Dialogue")
	if _dialogue == null:
		push_error("GameState: the Dialogue autoload is missing (project.godot [autoload])")
	else:
		_dialogue.condition_provider = Callable(self, "dialogue_condition")
		if debug_log:
			_dialogue.line_started.connect(_on_line_started)
	# The level has no script of its own, so notice scenes entering the root and bind to them once they are ready.
	get_tree().root.child_entered_tree.connect(_on_root_child_entered)
	# The main scene is added to the root before the autoloads' _ready runs, so on the very first start that
	# signal has already fired and was missed (the log began at attempt #2). Pick the scene up here as well;
	# _scene_ready is safe to run twice (the binds are guarded and GAME_STARTED is one-shot).
	for child in get_tree().root.get_children():
		if child != self and not ProjectSettings.has_setting("autoload/" + String(child.name)):
			_scene_ready.call_deferred()
			break


## The single entry point. Returns true if the event was accepted (not unknown, not a repeat).
func emit_event(id: String) -> bool:
	if id.begins_with("IDLE_"):
		idle(id)
		return true
	if not EVENTS.has(id):
		if OS.is_debug_build():
			push_warning("GameState: unknown event id '%s' (not in the contract)" % id)
		_record(id, "ignored: unknown id")
		return false
	if id == "SHIP_WIN" or id == "SHIP_FAIL":
		if outcome != Outcome.NONE:   # the outcome resolves once per attempt
			_record(id, "ignored: outcome already %s" % Outcome.keys()[outcome])
			return false
		outcome = Outcome.WIN if id == "SHIP_WIN" else Outcome.FAIL
	if not REPEATABLE.has(id):
		if fired.has(id):
			_record(id, "ignored: already fired this attempt")
			return false
		fired[id] = true
	_record(id, "")
	match id:
		"BURNER_PICKED_UP":
			burner_aboard = true
		"BURNER_FITTED":
			burner_fitted = true
	if PHASE_ON_EVENT.has(id):
		_advance_phase(PHASE_ON_EVENT[id])
	_update_lighting(false)
	event_emitted.emit(id, phase)
	if _dialogue:
		_dialogue.trigger(id)
	return true


## The player stalled on a step: next nudge tier (key is IDLE_STEP_1/2/3 or IDLE_SALTGATE).
func idle(key: String) -> void:
	if _dialogue:
		_dialogue.idle(key)


func reset_idle(key: String) -> void:
	if _dialogue:
		_dialogue.reset_idle(key)


## Gate 1 retry model: fail, then restart the slice. Clears everything for the attempt and reloads the level.
## The new level entering the tree emits GAME_STARTED again (see _on_root_child_entered).
func restart() -> void:
	attempt += 1
	_reset_state()
	get_tree().paused = false   # a restart from the pause key must not reload into a frozen level
	if _dialogue:
		_dialogue.reset_for_restart()   # clears played lines, idle tiers and the queue
	restarted.emit()
	if get_tree().current_scene == null:
		push_warning("GameState: restart() has no current scene to reload")
		return
	get_tree().reload_current_scene()


func phase_name(p: int = -1) -> String:
	return Phase.keys()[phase if p < 0 else p]


func dump_log() -> void:
	print("--- GameState event log (attempt %d, phase %s, outcome %s) ---" % [attempt, phase_name(), Outcome.keys()[outcome]])
	for e in event_log:
		print("  %6d ms  %-20s %-17s %s" % [e["t_msec"], e["id"], e["phase"], e["note"]])
	if deadline() != null:
		deadline().dump()


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if not debug_keys or key == null or not key.pressed or key.echo:
		return
	if key.keycode == KEY_F9:
		restart()
		get_viewport().set_input_as_handled()
	elif key.keycode == KEY_F10:
		dump_log()
		get_viewport().set_input_as_handled()
	elif key.keycode == KEY_F11:   # stand-in for the burner pickup so the return crossing can be QA'd before it exists
		emit_event("BURNER_PICKED_UP")
		get_viewport().set_input_as_handled()


# ---------------- internals ----------------

func _reset_state() -> void:
	phase = Phase.ARRIVAL_AND_COAL
	outcome = Outcome.NONE
	event_log.clear()
	fired.clear()
	burner_aboard = false
	burner_fitted = false
	_lighting_phase = ""
	_director = null
	_mixer = null
	_outcome_screen = null
	_sailors = null
	_diagnosis = null
	_intro = null
	_boarding = null
	_crossing = null
	_guidance = null
	_level_root = null


func _record(id: String, note: String) -> void:
	event_log.append({"t_msec": Time.get_ticks_msec(), "id": id, "phase": phase_name(), "attempt": attempt, "note": note})
	if debug_log:
		print("[GameState] #%d %s (%s)%s" % [attempt, id, phase_name(), " " + note if note != "" else ""])


func _advance_phase(target: int) -> void:
	if target <= phase:   # forward only
		return
	var old := phase
	phase = target
	if debug_log:
		print("[GameState] phase %s -> %s" % [phase_name(old), phase_name()])
	phase_changed.emit(old, phase)


func _on_line_started(line_id: String, _speaker: String, subtitle: String, _delivery: String) -> void:
	print("[Dialogue] %s: %s" % [line_id, subtitle])


## A scene entered the root. Autoloads are skipped; anything else is the slice (or a test scene). Deferred so the
## scene's own _ready (which builds the level) has finished before we look for the boat and the rig.
func _on_root_child_entered(node: Node) -> void:
	if node == self or ProjectSettings.has_setting("autoload/" + String(node.name)):
		return
	_scene_ready.call_deferred()


func _scene_ready() -> void:
	# Only the game level counts: the title and settings screens come first and must not start the game (and Ted's first line).
	if get_tree().get_first_node_in_group("boat") == null:
		return
	_bind_boat(get_tree().get_first_node_in_group("boat"))
	_bind_director()
	_bind_rig(get_tree().get_first_node_in_group("lighting_rig"))
	if _intro != null and _intro.holds_start:
		return       # the game starts when the player knocks (intro_sequence.gd)
	emit_event("GAME_STARTED")   # ignored if this attempt already started


func _bind_boat(b: Node) -> void:
	if b == null or b == _boat:
		return
	_boat = b
	if b.has_signal("departed"):
		b.departed.connect(_on_boat_departed)
	if b.has_signal("docked"):
		b.docked.connect(_on_boat_docked)
	if b.has_signal("hazard_hit"):
		b.hazard_hit.connect(_on_boat_hazard_hit)


func _bind_director() -> void:
	if _director != null and is_instance_valid(_director):
		return
	if _boat == null or _boat.get_parent() == null:
		return
	_level_root = _boat.get_parent()
	_intro = IntroSequence.new()
	_intro.name = "IntroSequence"
	_boat.get_parent().add_child(_intro)
	_intro.setup(self, _boat.get_parent())
	_director = ShipDeadline.new()
	_director.name = "ShipDeadline"
	_boat.get_parent().add_child(_director)
	_director.setup(self, _boat.get_parent())
	_mixer = AudioMixer.new()
	_mixer.name = "AudioMixer"
	_boat.get_parent().add_child(_mixer)
	_mixer.setup(self, _boat.get_parent())
	_outcome_screen = OutcomeScreen.new()
	_boat.get_parent().add_child(_outcome_screen)
	_outcome_screen.setup(self, _boat.get_parent())
	_sailors = SailorsSequence.new()
	_sailors.name = "SailorsSequence"
	_boat.get_parent().add_child(_sailors)
	_sailors.setup(self, _boat.get_parent())
	_diagnosis = DiagnosisSequence.new()
	_diagnosis.name = "DiagnosisSequence"
	_boat.get_parent().add_child(_diagnosis)
	_diagnosis.setup(self, _boat.get_parent())
	_boarding = BoardingSequence.new()
	_boarding.name = "BoardingSequence"
	_boat.get_parent().add_child(_boarding)
	_boarding.setup(self, _boat.get_parent())
	_crossing = CrossingSequence.new()
	_crossing.name = "CrossingSequence"
	_boat.get_parent().add_child(_crossing)
	_crossing.setup(self, _boat.get_parent())
	_guidance = GuidanceHud.new()
	_guidance.name = "GuidanceHud"
	_boat.get_parent().add_child(_guidance)
	_guidance.setup(self, _boat.get_parent())


## The hidden ship deadline as 0..1 (1 = the clock ran out), -1 until the return crossing starts it. The sea (wave_system.gd)
## and the perceptual storm cues read this; nothing shows it to the player.
func deadline_progress() -> float:
	if _director != null and is_instance_valid(_director):
		return _director.progress()
	return -1.0


func guidance() -> Node:
	return _guidance if _guidance != null and is_instance_valid(_guidance) else null


func crossing() -> Node:
	return _crossing if _crossing != null and is_instance_valid(_crossing) else null


func boarding() -> Node:
	return _boarding if _boarding != null and is_instance_valid(_boarding) else null


func intro() -> Node:
	return _intro if _intro != null and is_instance_valid(_intro) else null


func diagnosis() -> Node:
	return _diagnosis if _diagnosis != null and is_instance_valid(_diagnosis) else null


func sailors() -> Node:
	return _sailors if _sailors != null and is_instance_valid(_sailors) else null


func outcome_screen() -> Node:
	return _outcome_screen if _outcome_screen != null and is_instance_valid(_outcome_screen) else null


func audio() -> Node:
	return _mixer if _mixer != null and is_instance_valid(_mixer) else null


## The basement under the lighthouse house (world). The island dock and the sea are outside these bounds.
const BASEMENT_X := Vector2(-6.0, 12.0)
const BASEMENT_Z := Vector2(-10.0, 3.0)
const BASEMENT_MAX_Y := 9.3


func player_in_basement() -> bool:
	var p := get_tree().get_first_node_in_group("player") as Node3D
	if p == null:
		return false
	var g := p.global_position
	return g.y < BASEMENT_MAX_Y and g.x > BASEMENT_X.x and g.x < BASEMENT_X.y and g.z > BASEMENT_Z.x and g.z < BASEMENT_Z.y


## Is the player inside the lighthouse (the house, its basement, or the tower)? Ted's lines are only spoken while they are (creator,
## 30 October 2026; how loud and how muffled he should be elsewhere is for the Tuesday sound review). The knock greeting is the one
## exception: it carries no `requires`.
const TOWER_CENTRE := Vector2(8.5, -4.9)
const TOWER_RADIUS := 3.4


func player_inside_building() -> bool:
	var p := get_tree().get_first_node_in_group("player") as Node3D
	if p == null or _level_root == null or not is_instance_valid(_level_root):
		return false
	var g := p.global_position
	if g.y > 9.0 and Vector2(g.x - TOWER_CENTRE.x, g.z - TOWER_CENTRE.y).length() < TOWER_RADIUS:
		return true
	var rooms := _level_root.get_node_or_null("InteriorRooms")
	var culling := _level_root.get_node_or_null("InteriorCulling")
	if rooms == null or culling == null or rooms.get("frame") == null:
		return false
	var local: Vector3 = (rooms.frame as Node3D).to_local(g)
	var u := local.x
	var v := -local.z
	var hu: Vector2 = culling.HOUSE_U
	var hv: Vector2 = culling.HOUSE_V
	return u > hu.x and u < hu.y and v > hv.x and v < hv.y


## What a dialogue line's `requires` field asks (see dialogue_loader.gd). Daniel only speaks when he and the player are both
## in the basement (creator, 30 October 2026).
func dialogue_condition(name: String) -> bool:
	match name:
		"player_inside":
			return player_inside_building()
		"player_and_daniel_in_basement":
			return fired.has("DANIEL_IN_BASEMENT") and player_in_basement()
	push_warning("GameState: unknown dialogue condition '%s'" % name)
	return true


func deadline() -> Node:
	return _director if _director != null and is_instance_valid(_director) else null


func _bind_rig(r: Node) -> void:
	if r == null or r == _rig:
		return
	_rig = r
	_lighting_phase = ""
	_update_lighting(true)   # the rig starts on its own start_phase; bring it in line with the state


func _on_boat_departed(zone_id: String) -> void:
	if zone_id == "DOCK_LIGHTHOUSE":
		emit_event("BOAT_CAST_OFF")
	elif zone_id == "DOCK_PORT":
		if burner_aboard or not require_burner_for_return:
			emit_event("RETURN_DEPARTED")
		else:
			push_warning("GameState: the boat left DOCK_PORT with no burner aboard (BURNER_PICKED_UP not fired); RETURN_DEPARTED not emitted")


func _on_boat_docked(zone_id: String) -> void:
	if zone_id == "DOCK_PORT":
		emit_event("SALTGATE_REACHED")
	elif zone_id == "DOCK_LIGHTHOUSE" and phase == Phase.RETURN:
		emit_event("RETURN_ARRIVED")


func _on_boat_hazard_hit() -> void:
	if phase == Phase.OUTBOUND:
		emit_event("OUTBOUND_COLLISION")
	# OUTBOUND_NEAR_MISS stays unwired: the boat has no near-miss signal yet.


## The lighting phase the current state calls for, or "" to leave the rig where it is.
func _lighting_target() -> String:
	if burner_fitted:
		return "BEACON_RELIT"
	return LIGHTING_FOR_PHASE.get(phase, "")


func _update_lighting(instant: bool) -> void:
	if _rig == null or not is_instance_valid(_rig) or not _rig.has_method("set_phase"):
		return
	var target := _lighting_target()
	if target == "" or target == _lighting_phase:
		return
	_lighting_phase = target
	_rig.set_phase(target, instant)
