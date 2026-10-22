# test_coal_job.gd - run: Godot --headless --path . --script res://tools/test_coal_job.gd
# The first hands-on job (backlog T33) and the interior's canon event triggers, through the real E key:
#   1. walking into the hall reports LIGHTHOUSE_ENTERED, down the stairs ENGINE_ROOM_ENTERED (once each);
#   2. a Flighted poster read with E reports POSTER_EXAMINED;
#   3. at the coal heap with empty hands "[E] Shovel coal" is offered; E puts a shovelful in the hands (one at a time);
#   4. at the firebox with the shovelful "[E] Shovel the coal into the firebox"; E feeds it: hands empty, gauge up;
#   5. COAL_LOADED_FIRST on the first load, COAL_LOADED_HALF at half, BOILER_FED on the last, which moves the phase to
#      SHELTER_AND_GATE, and the flywheel starts to turn; once fed, the heap is no longer offered;
#   6. the wall voids' triggers report WALL_WHISPER_HEARD, and BASEMENT_BANG only after BOILER_FED.
# Exits 0 when every check passes, 1 otherwise.
extends SceneTree

var _lv: Node
var _player: CharacterBody3D
var _gs: Node
var _carry: Node
var _im: Node
var _rooms: Node
var _job: Node
var _pile: Node3D
var _hatch: Node3D
var _f := 0
var _step := 0
var _wait := 0
var _failed := 0
var _loads_done := 0
var _angle0 := 0.0


func _initialize() -> void:
	_lv = load("res://scenes/Level.tscn").instantiate()
	root.add_child(_lv)
	_player = _lv.get_node("Player")
	_gs = root.get_node_or_null("GameState")
	_carry = root.get_node_or_null("Carry")
	_im = root.get_node_or_null("Interaction")
	_rooms = _lv.get_node_or_null("InteriorRooms")
	Engine.max_physics_steps_per_frame = 20


func _physics_process(_delta: float) -> bool:
	_f += 1
	if _f < 30:
		return false
	if _wait > 0:
		_wait -= 1
		return false
	Input.action_release("interact")
	match _step:
		0:
			_job = _rooms.refs.get("coal_job")
			_pile = _rooms.refs.get("coal_pile")
			_hatch = _rooms.refs.get("firebox_hatch")
			_check(_job != null and _pile != null and _hatch != null, "the coal job, heap and firebox door exist")
			if _job == null:
				quit(1)
				return false
			_check(not _gs.fired.has("LIGHTHOUSE_ENTERED"), "LIGHTHOUSE_ENTERED has not fired yet")
			_stand_at(_a("entry") + Vector3(0, 0.05, 0), _a("entry") + Vector3(2, 1.2, 4))
			_next(10)
		1:
			_check(_gs.fired.has("LIGHTHOUSE_ENTERED"), "walking into the hall reported LIGHTHOUSE_ENTERED")
			_stand_at(_a("spiral_foot") + Vector3(0, 0.05, 0), _a("spiral_foot") + Vector3(2, 1.2, 0))
			_next(10)
		2:
			_check(_gs.fired.has("ENGINE_ROOM_ENTERED"), "going down to the basement reported ENGINE_ROOM_ENTERED")
			# the poster: stand at the hall's Storms poster and press E
			var poster: Node3D = _rooms.house.refs["Poster_Storms"]
			var face: Vector3 = poster.global_position
			var out: Vector3 = poster.get_parent().global_transform.basis.z    # the sheet's normal: toward the room
			_stand_at(face + out * 1.2 - Vector3(0, 1.75 - 0.0, 0) * 0.0 + Vector3(0, -0.78, 0), face)
			_next(8)
		3:
			var poster: Node3D = _rooms.house.refs["Poster_Storms"]
			_check(_im.focus == poster, "facing the poster, it is offered (focus: %s)" % str(_im.focus))
			_check(_im._label.text == "[E] Read the poster", "poster prompt reads '%s'" % _im._label.text)
			Input.action_press("interact")
			_next(4)
		4:
			_check(_gs.fired.has("POSTER_EXAMINED"), "E on the poster reported POSTER_EXAMINED")
			# the coal heap
			_stand_at(_a("coal_pickup") + Vector3(0, 0.05, 0), _pile.global_position + Vector3(0, 0.3, 0))
			_next(8)
		5:
			_check(_im.focus == _pile, "empty-handed at the coal store the heap is offered (focus: %s)" % str(_im.focus))
			_check(_im._label.text == "[E] Shovel coal", "heap prompt reads '%s'" % _im._label.text)
			# not offered at the firebox with nothing in the hands
			_stand_at(_a("boiler_interaction") + Vector3(0, 0.05, 0), _hatch.global_position)
			_next(8)
		6:
			_check(_im.focus != _hatch, "at the firebox with empty hands nothing is offered (focus: %s)" % str(_im.focus))
			_to_heap()
		7:   # at the heap, empty-handed: take a shovelful
			Input.action_press("interact")
			_next(4)
		8:
			_check(_carry.is_holding() and _carry.held_kind == "coal", "E at the heap put a shovelful in the hands")
			_check(_im.focus != _pile, "with a shovelful in hand the heap is not offered again (one at a time)")
			_stand_at(_a("boiler_interaction") + Vector3(0, 0.05, 0), _hatch.global_position)
			_next(8)
		9:   # at the firebox with the shovelful
			if _loads_done == 0:
				_check(_im.focus == _hatch, "at the firebox with a shovelful, it is offered (focus: %s)" % str(_im.focus))
				_check(_im._label.text == "[E] Shovel the coal into the firebox", "firebox prompt reads '%s'" % _im._label.text)
			Input.action_press("interact")
			_next(4)
		10:
			_loads_done += 1
			_check(_job.loads == _loads_done and not _carry.is_holding(), "E fed load %d: the hands are empty again (loads %d)" % [_loads_done, _job.loads])
			if _loads_done == 1:
				_check(_gs.fired.has("COAL_LOADED_FIRST"), "the first shovelful reported COAL_LOADED_FIRST")
				_check(not _gs.fired.has("BOILER_FED"), "the boiler is not fed yet")
			if _loads_done == 3:
				_check(_gs.fired.has("COAL_LOADED_HALF"), "half way reported COAL_LOADED_HALF")
				_check(absf(_job.gauge.level - 0.5) < 0.01, "the gauge is at half (%.2f)" % _job.gauge.level)
			if _loads_done < _job.loads_needed:
				_to_heap()
			else:
				_next(4)
		11:
			_check(_gs.fired.has("BOILER_FED"), "the last shovelful reported BOILER_FED")
			_check(_gs.phase_name() == "SHELTER_AND_GATE", "the phase is SHELTER_AND_GATE (%s)" % _gs.phase_name())
			_check(_job.done and _job.running and absf(_job.gauge.level - 1.0) < 0.01, "the job is done, the engine runs, the gauge is full")
			_angle0 = _job.flywheel.basis.get_euler().length()
			_stand_at(_a("coal_pickup") + Vector3(0, 0.05, 0), _pile.global_position + Vector3(0, 0.3, 0))
			_next(30)
		12:
			_check(_im.focus != _pile, "once the boiler is fed the heap is no longer offered (focus: %s)" % str(_im.focus))
			_check(absf(_job.flywheel.basis.get_euler().length() - _angle0) > 0.01, "the flywheel is turning")
			var bz: Node3D = _lv.find_child("Zone_B_WallVoid_West", true, false)
			var wz: Node3D = _lv.find_child("Zone_G_WallVoid_West", true, false)
			_check(bz != null and wz != null, "the wall voids have trigger zones")
			_stand_at(wz.global_position + Vector3(0, -0.5, 0), wz.global_position + Vector3(1, 0, 1))
			_next(10)
		13:
			_check(_gs.fired.has("WALL_WHISPER_HEARD"), "standing by the hall wall void reported WALL_WHISPER_HEARD")
			var bz2: Node3D = _lv.find_child("Zone_B_WallVoid_West", true, false)
			_stand_at(bz2.global_position + Vector3(0, -0.5, 0), bz2.global_position + Vector3(1, 0, 1))
			_next(10)
		14:
			_check(_gs.fired.has("BASEMENT_BANG"), "standing by the basement wall void reported BASEMENT_BANG (after BOILER_FED)")
			print("RESULT: %s (%d failed)" % ["OK" if _failed == 0 else "FAILED", _failed])
			quit(0 if _failed == 0 else 1)
	if _f > 5000:
		print("FAIL: TIMEOUT in step ", _step)
		quit(1)
	return false


## Stand at the heap, empty-handed, and go to the step that presses E.
func _to_heap() -> void:
	_stand_at(_a("coal_pickup") + Vector3(0, 0.05, 0), _pile.global_position + Vector3(0, 0.3, 0))
	_step = 7
	_wait = 8


## A named interior anchor's world position (the InteriorAnchors markers, which include the furnished rooms' places).
func _a(role: String) -> Vector3:
	var m := _lv.get_node("InteriorAnchors").anchors.get(role) as Node3D
	return m.global_position if m != null else Vector3.ZERO


func _stand_at(at: Vector3, look_at_point: Vector3) -> void:
	_player.velocity = Vector3.ZERO
	_player.global_position = at
	var flat := Vector3(look_at_point.x, at.y, look_at_point.z)
	if flat.distance_to(at) > 0.01:
		_player.look_at(flat, Vector3.UP)
	var eye := at + Vector3.UP * 1.6
	var d := Vector2(look_at_point.x - eye.x, look_at_point.z - eye.z).length()
	_player.get_node("Head").rotation.x = atan2(look_at_point.y - eye.y, maxf(d, 0.01))


func _next(frames: int) -> void:
	_step += 1
	_wait = frames


func _check(ok: bool, what: String) -> void:
	print(("PASS  " if ok else "FAIL  ") + what)
	if not ok:
		_failed += 1
