# test_boat_float.gd - run: Godot --headless --path . --script res://tools/test_boat_float.gd
# 1. The docked boat rides the same waves as the sea (height and tilt follow Sea.wave_height).
# 2. A player dropped onto the deck from above lands and stays on it while it heaves.
# 3. A player standing on the boat is carried along when the boat sails (cast off by script).
extends SceneTree

const Sea := preload("res://scripts/world/sea.gd")

var _lv: Node
var _boat: Node3D
var _player: CharacterBody3D
var _f := 0
var _step := 0
var _t := 0.0
var _samples: Array[float] = []
var _rel_y: Array[float] = []
var _start_local := Vector3.ZERO
var _tilt_max := 0.0
var _heave_min := 99.0
var _heave_max := -99.0
var _err_max := 0.0


func _initialize() -> void:
	_lv = load("res://scenes/Level.tscn").instantiate()
	root.add_child(_lv)
	_boat = _lv.get_node("Boat")
	_player = _lv.get_node("Player")


func _physics_process(delta: float) -> bool:
	_f += 1
	if _f < 20:
		return false
	_t += delta
	var rig: Node3D = _boat.get_node("Rig")
	match _step:
		0:   # 1) follow the waves while tied up
			var surf: float = _boat.water_level + Sea.wave_height(_boat.global_position.x, _boat.global_position.z, Sea.wave_time)
			_err_max = maxf(_err_max, absf(_boat.global_position.y + _boat.draft - surf))
			_heave_min = minf(_heave_min, _boat.global_position.y)
			_heave_max = maxf(_heave_max, _boat.global_position.y)
			_tilt_max = maxf(_tilt_max, maxf(absf(rig.rotation.x), absf(rig.rotation.z)))
			if _t > 20.0:
				print("float: keel height ranged %.2f .. %.2f m over 20 s; worst gap to the wave surface %.3f m; max tilt %.2f deg" % [_heave_min, _heave_max, _err_max, rad_to_deg(_tilt_max)])
				# 2) drop the player 3 m above the cockpit
				_player.global_position = rig.to_global(Vector3(0.0, 3.0, 0.8))
				_player.velocity = Vector3.ZERO
				_next()
		1:   # let them land, then watch for 12 s
			if _t > 1.5:
				var local: Vector3 = rig.to_local(_player.global_position)
				print("land: on_floor=%s, local pos (%.2f, %.2f, %.2f) (cockpit floor is ~0.8)" % [_player.is_on_floor(), local.x, local.y, local.z])
				_start_local = local
				_rel_y.clear()
				_next()
		2:
			var local2: Vector3 = rig.to_local(_player.global_position)
			_rel_y.append(local2.y)
			if _t > 12.0:
				var mn: float = _rel_y.min()
				var mx: float = _rel_y.max()
				print("stay: over 12 s the player's height above the deck ranged %.2f .. %.2f, on_floor=%s, horizontal drift %.2f m" % [mn, mx, _player.is_on_floor(), Vector2(local2.x - _start_local.x, local2.z - _start_local.z).length()])
				# 3) sail away with the player standing on board (not seated)
				_boat.state = _boat.State.SAILING
				_boat._leave_zone = _boat.current_zone
				_boat.velocity = Vector3.ZERO
				_next()
		3:
			if _t > 10.0:
				var local3: Vector3 = rig.to_local(_player.global_position)
				var moved := _boat.global_position.distance_to(Vector3(16.5, 0.15, 35.8))
				print("carry: boat moved %.0f m; player is at (%.2f, %.2f, %.2f) in boat space, on_floor=%s" % [moved, local3.x, local3.y, local3.z, _player.is_on_floor()])
				print("DONE")
				quit()
	if _t > 120.0:
		print("TIMEOUT in step ", _step)
		quit()
	return false


func _next() -> void:
	_step += 1
	_t = 0.0
