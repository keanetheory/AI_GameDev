# interior_lights.gd - keeps the lighthouse's interior lights inside the Lighting agent's budget.
# The interior has 15 lights placed room by room. The lighting spec allows 8 dynamic lights for the whole scene and only
# 2 shadow casters (data/world/lighting_spec.json), and all 15 were live with shadows. This keeps them all in the scene
# but turns on only the few nearest the player: at most MAX_LIVE are lit at once, and only the nearest MAX_SHADOWS cast
# shadows. Lights fade in and out so nothing pops. Put it on the LighthouseInteriorLights node.
# They only come on while the player is INSIDE the building (GameState.player_inside_building): from outside, the hall lights
# used to fade up as the player walked to the door and wash the front wall and the steps orange (creator, 31 Oct 2026, T58).
# A level without GameState (a test's stand-in) keeps the old distance-only rule.
extends Node3D

const MAX_LIVE := 6          # of the 8-light scene budget, leaving 2 for the beacon and the player's own light
const MAX_SHADOWS := 2       # the spec's shadow-caster budget
const RANGE_EXTRA := 3.5     # a light is only lit if the player is within its range plus this
@export var fade_per_s := 5.0

var _lights: Array[OmniLight3D] = []
var _base := {}
var _level := {}             # current brightness 0..1 per light


func _ready() -> void:
	for c in get_children():
		if c is OmniLight3D:
			_lights.append(c)
			_base[c] = (c as OmniLight3D).light_energy
			_level[c] = 0.0
			(c as OmniLight3D).visible = false
			(c as OmniLight3D).shadow_enabled = false


## Take a light made after _ready (the furnished rooms' lights) under the same budget.
func adopt(l: OmniLight3D) -> void:
	if _lights.has(l):
		return
	_lights.append(l)
	_base[l] = l.light_energy
	_level[l] = 0.0
	l.visible = false
	l.shadow_enabled = false


func _process(delta: float) -> void:
	var t := Time.get_ticks_msec() * 0.001
	var player := get_tree().get_first_node_in_group("player") as Node3D
	var pos := player.global_position if player else Vector3(1e6, 1e6, 1e6)
	var order: Array[OmniLight3D] = _lights.duplicate()
	order.sort_custom(func(a: OmniLight3D, b: OmniLight3D) -> bool: return a.global_position.distance_squared_to(pos) < b.global_position.distance_squared_to(pos))
	var live := 0
	var inside := _player_inside()
	for i in order.size():
		var l := order[i]
		var want := 0.0
		if inside and live < MAX_LIVE and l.global_position.distance_to(pos) < l.omni_range + RANGE_EXTRA:
			want = 1.0
			live += 1
		_level[l] = move_toward(_level[l], want, fade_per_s * delta)
		var fl: float = l.get_meta("flicker", 0.0)
		var wob := 1.0 + fl * (sin(t * 4.0 + float(l.get_instance_id() % 7)) * 0.5 + sin(t * 9.0) * 0.3 + sin(t * 1.7) * 0.2) if fl > 0.0 else 1.0
		l.light_energy = _base[l] * _level[l] * wob
		l.visible = _level[l] > 0.01
		l.shadow_enabled = want > 0.0 and live <= MAX_SHADOWS


func _player_inside() -> bool:
	var gs := get_node_or_null("/root/GameState")
	if gs == null or not gs.has_method("player_inside_building") or gs.get("_level_root") == null:
		return true
	if gs.player_inside_building():
		return true
	# the upper floors of the house (the keeper's quarters, the hut) lie outside the ground-floor footprint GameState tests
	var p := get_tree().get_first_node_in_group("player") as Node3D
	if p == null:
		return false
	var d := Vector2(p.global_position.x - global_position.x, p.global_position.z - global_position.z).length()
	return p.global_position.y > global_position.y + 2.4 and d < 14.0


## For tests: how many interior lights are lit, and how many of those cast shadows.
func live_count() -> int:
	var n := 0
	for l in _lights:
		if l.visible:
			n += 1
	return n


func shadow_count() -> int:
	var n := 0
	for l in _lights:
		if l.visible and l.shadow_enabled:
			n += 1
	return n
