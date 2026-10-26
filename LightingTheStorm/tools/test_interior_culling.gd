# test_interior_culling.gd - run: Godot --headless --path . --script res://tools/test_interior_culling.gd
# LHF-06: the interior culling (interior_culling.gd) puts every house mesh on a level, hides the right levels for where the camera is
# (first floor from the ground floor and basement; the ground floor and basement from the first floor), never hides the tower or the
# lamp room, and leaves everything drawn when the camera is outside the house. Uses a Camera3D placed by the test.
extends SceneTree

var _lv: Node
var _cam: Camera3D
var _ic
var _f := 0
var _step := 0
var _wait := 0
var _fails := 0


func _initialize() -> void:
	_lv = load("res://scenes/Level.tscn").instantiate()
	root.add_child(_lv)
	_cam = Camera3D.new()
	_lv.add_child(_cam)
	_cam.current = true


func _ok(c: bool, what: String) -> void:
	print(("PASS  " if c else "FAIL  ") + what)
	if not c:
		_fails += 1


func _at(u: float, y: float, v: float) -> void:
	_cam.global_position = _lv.get_node("InteriorRooms").frame.to_global(Vector3(u, y - 9.61, -v))
	_wait = 3
	_ic.apply()


func _visible_count(l: int) -> int:
	var n := 0
	for g in _ic.levels[l]:
		if (g as Node3D).visible:
			n += 1
	return n


func _physics_process(_d: float) -> bool:
	_f += 1
	if _f < 20:
		return false
	if _wait > 0:
		_wait -= 1
		return false
	_ic = _lv.get_node("InteriorCulling")
	match _step:
		0:
			var b: int = _ic.levels[0].size()
			var g: int = _ic.levels[1].size()
			var l1: int = _ic.levels[2].size()
			_ok(b > 100 and g > 100 and l1 > 100, "meshes per level: basement %d, ground %d, first floor %d" % [b, g, l1])
			var tower_hit := false
			for lvl in _ic.levels:
				for m in _ic.levels[lvl]:
					if String((m as Node).get_path()).contains("LampRoom") or String((m as Node).get_path()).contains("TowerShell"):
						tower_hit = true
						if _fails < 6:
							print("   offender: ", String((m as Node).get_path()).trim_prefix("/root/Level/InteriorRooms/"))
			_ok(not tower_hit, "no tower, stair shell or lamp-room mesh is on a cullable level")
			_at(0.5, 1.7 + 10.58, 2.0)        # standing in the hall
			_step = 1
		1:
			_ok(_ic.inside, "camera in the hall counts as inside the house")
			_ok(_visible_count(2) == 0, "on the ground floor the first floor is hidden")
			_ok(_visible_count(1) > 100 and _visible_count(0) > 100, "on the ground floor the ground floor and the basement are drawn")
			_at(1.0, 14.8 + 1.6, 4.0)         # first floor, mess
			_step = 2
		2:
			_ok(_visible_count(2) > 100 and _visible_count(1) == 0 and _visible_count(0) == 0, "on the first floor only the first floor is drawn")
			# the floor you stand on is never culled (the 2026-10-25 bug: the first floor's thick slab was filed under the ground floor)
			var fl := _lv.get_node("InteriorRooms").frame.find_child("L1_Floor", true, false) as Node3D
			_ok(OS.get_environment("LHF_SHELL") == "2" or (fl != null and fl.visible and _ic.levels[2].has(fl)), "on the first floor its floor slab is on the first-floor level and drawn")
			var gc := _lv.get_node("InteriorRooms").frame.find_child("G_Ceiling", true, false) as Node3D
			_ok(OS.get_environment("LHF_SHELL") == "2" or (gc != null and _ic.levels[1].has(gc)), "the ground-floor ceiling stays on the ground-floor level")
			_ok(_ic.culled_meshes > 300, "meshes hidden up there: %d" % _ic.culled_meshes)
			_at(1.0, 8.6, 4.0)                # basement
			_step = 3
		3:
			_ok(_visible_count(2) == 0 and _visible_count(0) > 100, "in the basement the first floor is hidden")
			_at(-30.0, 14.0, 20.0)            # outside
			_step = 4
		4:
			_ok(not _ic.inside, "outside the house is not inside")
			_ok(_visible_count(0) > 100 and _visible_count(1) > 100 and _visible_count(2) > 100, "outside, every level is drawn")
			print("\n%s" % ("ALL PASSED" if _fails == 0 else "%d FAILED" % _fails))
			quit(1 if _fails > 0 else 0)
	return false
