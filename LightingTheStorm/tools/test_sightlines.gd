# test_sightlines.gd - run: Godot --headless --path . --script res://tools/test_sightlines.gd
# The two sightlines the GDD makes load-bearing (Decisions 22 and 26):
#  1. the window beside the door sees the island dock where the rowboat is moored (Ted watches the sailors arrive);
#  2. the lamp room has views all around, so the ship's end (it passes or crashes on the rock beside the island) can be seen.
# Rays are cast from eye height against everything solid in the level (physics layers 1 and 2) and, for the dock view,
# against the visible exterior mesh too, so a window that is open for the player but walled over on screen would show.
extends SceneTree

const EYE := 1.6
## Where the rowboat is seen arriving: just outside the harbour mouth (the berth is at -27, 18; the mouth at -41, 18).
const ROWBOAT_SIGHT := Vector3(-48.0, 0.8, 24.0)
var _lv: Node
var _f := 0
var _fails := 0


func _initialize() -> void:
	_lv = load("res://scenes/Level.tscn").instantiate()
	root.add_child(_lv)


func _ok(cond: bool, what: String) -> void:
	print(("PASS  " if cond else "FAIL  ") + what)
	if not cond:
		_fails += 1


func _first_hit(space: PhysicsDirectSpaceState3D, a: Vector3, b: Vector3) -> Dictionary:
	# eyes see through glass: skip bodies in the group "glass" (the tower window's barrier)
	var skip: Array[RID] = []
	for k in 6:
		var q := PhysicsRayQueryParameters3D.create(a, b)
		q.collision_mask = 3
		q.hit_back_faces = true
		q.exclude = skip
		var h := space.intersect_ray(q)
		if h.is_empty() or not (h["collider"] as Node).is_in_group("glass"):
			return h
		skip.append(h["rid"])
	return {}


func _name_of(h: Dictionary) -> String:
	var n: Node = h["collider"]
	while n != null and n.get_parent() != _lv:
		n = n.get_parent()
	return String(n.name) if n else "?"


func _physics_process(_d: float) -> bool:
	_f += 1
	if _f < 20:
		return false
	var space: PhysicsDirectSpaceState3D = _lv.get_world_3d().direct_space_state
	var interior: Node3D = _lv.get_node("LighthouseInterior")
	var f := FileAccess.open("res://Assets/Models/lighthouse/interior/lighthouse_greybox_v3_alignment.json", FileAccess.READ)
	var al: Dictionary = JSON.parse_string(f.get_as_text())
	var mk: Dictionary = al["markers"]
	# 1a. the ground-floor window beside the door is closed up (creator, 2026-10-27): a ray straight out of it meets the wall within a few metres
	var w: Array = mk["G_window_view_marker"]
	# the marker sits at the wall corner; the opening is 1.2 m wide starting there, so stand at its middle (0.6 m along the wall)
	var eye := interior.to_global(Vector3(w[0], float(al["ground_floor_y"]) + EYE, w[2])) + Vector3(0.4309, 0.0, 0.9024) * 0.6
	var out := Vector3(-0.9024, 0.0, 0.4309)
	var hw := _first_hit(space, eye, eye + out * 12.0)
	_ok(not hw.is_empty() and eye.distance_to(hw["position"]) < 3.0, "ground-floor window: closed (first thing in the way %s)" % ("none within 12 m" if hw.is_empty() else "%s at %.1f m" % [_name_of(hw), eye.distance_to(hw["position"])]))
	# 1b. the dock berth where the rowboat is moored is NOT visible from low windows: the island top is a plateau at about y 9.7
	# and the harbour drops away beyond it. Measured from here, a window needs an eye height of about 22 m to see the berth.
	var dock := Vector3(-27.0, 1.0, 18.2)
	_ok(not _first_hit(space, eye, dock).is_empty(), "(information) the dock is hidden from the ground-floor window, as measured: the island plateau is in the way")
	# 1c. the tower landing window: the spiral stair has a step at about -57 deg (the dock's bearing from the tower axis) near y 23.3
	# ... but the water just outside the harbour mouth is: the rowboat is seen arriving there (map of visible water measured 2026-10-20)
	var sight := ROWBOAT_SIGHT
	var axis := Vector3(8.5, 0.0, -4.9)
	var az := deg_to_rad(-57.0)
	var land_eye := axis + Vector3(sin(az) * 1.6, 24.9, cos(az) * 1.6)
	var dist := land_eye.distance_to(sight)
	_ok(not _first_hit(space, land_eye, dock).is_empty(), "(information) the berth inside the harbour is hidden from the tower window too: the harbour stairs and walls are in the way")
	var seen := 0
	var total := 0
	for dy in [-0.3, 0.0, 0.3]:
		for side in [-0.4, 0.0, 0.4]:
			total += 1
			var e2: Vector3 = land_eye + Vector3(cos(az), 0.0, -sin(az)) * side + Vector3(0, dy, 0)
			if _first_hit(space, e2, sight).is_empty():
				seen += 1
	var h1 := _first_hit(space, land_eye, sight)
	_ok(h1.is_empty(), "tower landing window to the rowboat sighting point outside the harbour mouth: %s (%.0f m)" % ["clear" if h1.is_empty() else "blocked by %s at %.1f m" % [_name_of(h1), land_eye.distance_to(h1["position"])], dist])
	_ok(seen >= 5, "tower landing window: the sighting point is visible from %d of %d nearby eye positions (needs 5)" % [seen, total])
	# 2. the lamp room sees all round
	var s: Array = mk["Lantern_arc_lamp_socket_marker"]
	var lamp_eye := interior.to_global(Vector3(s[0], float(al["lantern_floor_y"]) + EYE, s[2]))
	var clear := 0
	var blocked_dirs := []
	for i in 36:
		var a := TAU * i / 36.0
		var open := false
		var last_hit := {}
		for jit in [-0.07, 0.0, 0.07]:       # about 4 degrees either side: a railing post must not hide a whole direction
			var dir := Vector3(sin(a + jit), -0.02, cos(a + jit))
			var hit := _first_hit(space, lamp_eye + dir * 2.6, lamp_eye + dir * 90.0)     # start outside the lamp glass at 2.6 m from its axis
			if hit.is_empty() or lamp_eye.distance_to(hit["position"]) > 60.0:
				open = true
				break
			last_hit = hit
		if open:
			clear += 1
		else:
			blocked_dirs.append("%d deg: %s at %.0f m" % [i * 10, _name_of(last_hit), lamp_eye.distance_to(last_hit["position"])])
	_ok(clear >= 32, "lamp room: %d of 36 directions are open for 60 m (needs 32)%s" % [clear, "; blocked: " + ", ".join(blocked_dirs.slice(0, 6)) if not blocked_dirs.is_empty() else ""])
	# towards the Saltgate (+z) and towards the dock side (-x, +z): the two the story needs
	for name in ["Saltgate (+z)", "dock side (-x, +z)"]:
		var d2 := Vector3(0, -0.02, 1.0) if name.begins_with("Saltgate") else Vector3(-0.77, -0.02, 0.64)
		var ok2 := false
		for jit2 in [-0.07, 0.0, 0.07]:
			var dd := d2.normalized().rotated(Vector3.UP, jit2)
			var hit2 := _first_hit(space, lamp_eye + dd * 2.6, lamp_eye + dd * 200.0)
			if hit2.is_empty() or lamp_eye.distance_to(hit2["position"]) > 60.0:
				ok2 = true
		_ok(ok2, "lamp room sees %s" % name)
	print("\n%s" % ("ALL PASSED" if _fails == 0 else "%d FAILED" % _fails))
	quit(1 if _fails > 0 else 0)
	return false
