# ship_deadline.gd - the hidden ship deadline (T07, Technical Strategy "Deadline" rules) and the passenger ship it drives.
# GameState creates one of these inside the level once the level is ready, so Level.tscn carries neither the clock nor the ship.
#
# Rules (Decisions A6, A23, A28, A29):
#   - the clock is inactive until RETURN_DEPARTED (burner aboard, the boat under way home); before that there is no fail;
#   - it is numeric only: the player sees the ship's position and lights and the weather, never a number;
#   - it stops in menus and on deliberate pause (P toggles pause, and pausing the tree freezes the clock and the ship);
#   - BURNER_FITTED freezes it and the ship steers clear of the rock; running out fires SHIP_FAIL once, and the ship, now
#     committed, runs onto the rock (passenger_ship.gd), emitting impact for the fail presentation (T08).
# Debug aids (debug builds only, see debug_flags.gd): Page Up / Page Down step the clock's time scale, Home resets it, or pass
# "-- --deadline-scale=4". Every start, pause, scale change, penalty and expiry goes to `log` (printed, and by GameState.dump_log).
extends Node

const Route := preload("res://scripts/world/ship_route.gd")
const Ship := preload("res://scripts/world/passenger_ship.gd")
const DebugFlags := preload("res://scripts/core/debug_flags.gd")

signal started
signal expired
signal pause_changed(paused: bool)

enum State { WAITING, RUNNING, FROZEN, EXPIRED }

var state: int = State.WAITING
var elapsed := 0.0                 # deadline seconds used (scaled by time_scale)
var length_s := 210.0
var time_scale := 1.0
var ship: Node3D
var log: Array = []                # {t_msec, kind, elapsed, note}
var spec: Dictionary = {}

var _gs: Node
var _scales: Array = [1.0]
var _mouse_before := Input.MOUSE_MODE_VISIBLE


func setup(gs: Node, level: Node) -> void:
	_gs = gs
	spec = Route.load_spec()
	if spec.is_empty():
		push_error("ship_deadline: no route data, the deadline will not run")
		return
	length_s = float(spec["deadline"]["length_s"])
	_scales = spec["deadline"]["debug_time_scales"]
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("--deadline-scale="):
			time_scale = float(String(a).get_slice("=", 1))
	process_mode = Node.PROCESS_MODE_ALWAYS     # the pause key must still be heard while the tree is paused
	ship = Ship.new()
	ship.name = "PassengerShip"
	ship.process_mode = Node.PROCESS_MODE_PAUSABLE
	level.add_child(ship)
	ship.setup(spec)
	ship.set_deadline_length(length_s)
	ship.impact.connect(func() -> void: _note("impact", "the ship strikes the rock"))
	ship.passed.connect(func() -> void: _note("passed", "the ship is safe in port"))
	gs.event_emitted.connect(_on_event)
	if time_scale != 1.0:
		_note("scale", "time scale %s (command line)" % time_scale)


## 0..1 once the clock has started (it holds its last value when frozen), -1 before. The sea and lighting read this.
func progress() -> float:
	if state == State.WAITING:
		return -1.0
	return clampf(elapsed / length_s, 0.0, 1.0)


func is_running() -> bool:
	return state == State.RUNNING


## T19: collision and recovery costs add seconds to the clock; nothing calls this until the values are decided.
func add_penalty(seconds: float, why := "") -> void:
	if state != State.RUNNING:
		return
	elapsed += seconds
	_note("penalty", "+%.1f s %s" % [seconds, why])


func dump() -> void:
	print("--- Deadline log (state %s, %.1f of %.1f s, scale %s) ---" % [State.keys()[state], elapsed, length_s, time_scale])
	for e in log:
		print("  %6d ms  %-8s %6.1f s  %s" % [e["t_msec"], e["kind"], e["elapsed"], e["note"]])


func _process(delta: float) -> void:
	if state != State.RUNNING or get_tree().paused:
		return
	elapsed += delta * time_scale
	if elapsed >= length_s:
		elapsed = length_s
		_expire()
	elif ship:
		ship.set_progress(elapsed / length_s)


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if key.keycode == KEY_P:
		toggle_pause()
		get_viewport().set_input_as_handled()
	elif _gs and _gs.debug_keys:
		if key.keycode == KEY_PAGEUP or key.keycode == KEY_PAGEDOWN:
			_step_scale(1 if key.keycode == KEY_PAGEUP else -1)
			get_viewport().set_input_as_handled()
		elif key.keycode == KEY_HOME:
			time_scale = 1.0
			_note("scale", "time scale 1")
			get_viewport().set_input_as_handled()


## The deadline and the ship stop with the tree. Not allowed once the outcome is settled.
func toggle_pause() -> void:
	var tree := get_tree()
	if tree.paused:
		tree.paused = false
		Input.mouse_mode = _mouse_before
	else:
		if _gs and _gs.outcome != _gs.Outcome.NONE:
			return
		_mouse_before = Input.mouse_mode
		tree.paused = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_note("pause" if tree.paused else "resume", "")
	pause_changed.emit(tree.paused)


func _step_scale(dir: int) -> void:
	var i := 0
	for k in _scales.size():
		if is_equal_approx(float(_scales[k]), time_scale):
			i = k
	i = clampi(i + dir, 0, _scales.size() - 1)
	time_scale = float(_scales[i])
	_note("scale", "time scale %s" % time_scale)


func _on_event(id: String, _phase: int) -> void:
	match id:
		"BOILER_FED", "LAMP_ROOM_ENTERED", "BURNER_DIAGNOSED", "BOARDING_THRESHOLD", "SHIP_SIGHTED", "BOAT_CAST_OFF":
			if ship:
				ship.appear()   # the unplanned ship comes up on the horizon once the boiler is fed (creator, 29 Oct 2026), so it is there to see from the lamp room
		"RETURN_DEPARTED":
			_start()
		"BURNER_FITTED", "SHIP_WIN":
			_saved()
		"SHIP_FAIL":
			_failed()


func _start() -> void:
	if state != State.WAITING:
		return
	state = State.RUNNING
	elapsed = 0.0
	if ship:
		ship.appear()
	_note("start", "clock started, %.0f s" % length_s)
	started.emit()


func _saved() -> void:
	if state == State.EXPIRED or state == State.FROZEN:
		return
	state = State.FROZEN
	_note("frozen", "burner fitted; the ship steers clear")
	if ship:
		ship.avoid()


func _failed() -> void:
	if state == State.EXPIRED or state == State.FROZEN:
		return
	state = State.EXPIRED
	_note("expired", "SHIP_FAIL; the ship is committed to the rock")
	if ship:
		ship.commit()
	expired.emit()


func _expire() -> void:
	if state != State.RUNNING:
		return
	state = State.EXPIRED       # before the event, so the SHIP_FAIL handler above does not run twice
	_note("expired", "the deadline ran out")
	if ship:
		ship.commit()
	expired.emit()
	if _gs:
		_gs.emit_event("SHIP_FAIL")


func _note(kind: String, note: String) -> void:
	log.append({"t_msec": Time.get_ticks_msec(), "kind": kind, "elapsed": elapsed, "note": note})
	if _gs == null or _gs.debug_log:
		print("[Deadline] %s %.1f s %s" % [kind, elapsed, note])
