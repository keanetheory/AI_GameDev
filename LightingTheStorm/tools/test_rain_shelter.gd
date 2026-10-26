# test_rain_shelter.gd - run: Godot --headless --path . --script res://tools/test_rain_shelter.gd
# LHF-03: no rain indoors. The RainShelter boxes (scripts/world/rain_shelter.gd) must cover every interior anchor, the whole tower
# stairwell at every height up to the lamp room, and must NOT cover the outside (the door's outer step, the dock, the lantern gallery
# beyond the glass). GPU particles cannot be run headless, so this checks the volumes; the visual is checked with a shot.
extends SceneTree

var _lv: Node
var _f := 0


func _initialize() -> void:
	_lv = load("res://scenes/Level.tscn").instantiate()
	root.add_child(_lv)


func _physics_process(_d: float) -> bool:
	_f += 1
	if _f < 5:
		return false
	var rs = _lv.get_node_or_null("RainShelter")
	var fails := 0
	var anchors := {}
	for a in get_nodes_in_group("lhi_anchor"):
		anchors[a.get_meta("role")] = (a as Node3D).global_position
	print("shelter boxes: %d" % (rs.volumes.size() if rs else -1))
	if rs == null or rs.volumes.is_empty():
		print("FAIL  no RainShelter boxes")
		quit(1)
		return false
	for role in ["entry", "ted_greeting", "boiler_interaction", "coal_pickup", "daniel", "arc_lamp_socket", "burner_fit", "ted_lantern", "lamp_eye"]:
		var p: Vector3 = anchors.get(role, Vector3.INF)
		# anchors are floor or eye markers; test a point a little above them
		var ok: bool = rs.covers(p + Vector3(0, 0.3, 0))
		print(("PASS  " if ok else "FAIL  ") + "covered: " + role + " " + str(p))
		fails += int(not ok)
	for role in ["door_outside", "rowboat_sighting"]:
		var p2: Vector3 = anchors.get(role, Vector3.INF)
		var out: bool = not rs.covers(p2 + Vector3(0, 0.3, 0))
		print(("PASS  " if out else "FAIL  ") + "outside, not covered: " + role + " " + str(p2))
		fails += int(not out)
	# the whole stairwell: a ring of points at radius 1.5 (inside the stair) every metre of height from the tower floor to the lamp room
	var lh := _lv.get_node("Lighthouse") as Node3D
	var miss := 0
	for y in range(1, 21):
		for k in 8:
			var a2 := TAU * k / 8.0
			var pt := lh.to_global(Vector3(3.5 + cos(a2) * 1.5, float(y) + 0.5, 3.6 + sin(a2) * 1.5))
			if not rs.covers(pt):
				miss += 1
	print(("PASS  " if miss == 0 else "FAIL  ") + "stairwell points uncovered: %d of 160" % miss)
	fails += int(miss > 0)
	# the L2 ring and the rest of the stairwell out to the wall (r 2.2 to 2.9, every 22.5 degrees, several heights), and the attic under the ridge
	var ring_miss := 0
	var ring_n := 0
	for y2 in [10.0, 11.0, 13.0, 16.0]:
		for k2 in 16:
			for rr2 in [2.2, 2.6, 2.9]:
				var a3 := TAU * k2 / 16.0
				ring_n += 1
				if not rs.covers(lh.to_global(Vector3(3.5 + cos(a3) * rr2, y2, 3.6 + sin(a3) * rr2))):
					ring_miss += 1
	print(("PASS  " if ring_miss == 0 else "FAIL  ") + "the L2 ring and the stairwell out to the wall are covered (%d of %d points uncovered)" % [ring_miss, ring_n])
	fails += int(ring_miss > 0)
	var attic: Vector3 = _lv.get_node("InteriorRooms").frame.to_global(Vector3(1.0, 8.4, -5.0))
	var attic_ok: bool = rs.covers(attic)
	print(("PASS  " if attic_ok else "FAIL  ") + "the first-floor attic up under the ridge is covered")
	fails += int(not attic_ok)
	# the lantern gallery, beyond the glass (r 3.6), is open to the sky
	var gal := lh.to_global(Vector3(3.5 + 3.6, 18.6, 3.6))
	var gok: bool = not rs.covers(gal)
	print(("PASS  " if gok else "FAIL  ") + "gallery outside the glass is not covered")
	fails += int(not gok)
	print("\n%s" % ("ALL PASSED" if fails == 0 else "%d FAILED" % fails))
	quit(1 if fails > 0 else 0)
	return false
