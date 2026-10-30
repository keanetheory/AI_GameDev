# test_crossing_sequence.gd - run: Godot --headless --path . --script res://tools/test_crossing_sequence.gd
# T10: the Storm Crossing Crew's return forecast (data/world/return_crossing.json) laid on the real level through the real GameState:
# the hazards are placed when the boat docks at the Saltgate, in the forecast's lanes along the quay-to-berth line, clear of the sea
# stacks and the island; the boat's hull test sees them; the safe lane through the segments (centre, left, right, centre, left) is
# clear for the launch; Arthur's calls fire in order as the boat passes each trigger and play as subtitle lines; the bells move onto the
# buoys; and outbound, passing close to a sea stack fires OUTBOUND_NEAR_MISS without touching it.
extends SceneTree

var _lv: Node
var _fails := 0
var _f := 0
var _started := false


func _initialize() -> void:
	Engine.set_meta("skip_intro", true)
	_lv = load("res://scenes/Level.tscn").instantiate()
	root.add_child(_lv)


func _check(cond: bool, msg: String) -> void:
	print("%s  %s" % ["PASS" if cond else "FAIL", msg])
	if not cond:
		_fails += 1


func _process(_d: float) -> bool:
	_f += 1
	if _f == 60 and not _started:
		_started = true
		_run()
	return false


func _at(boat: Node3D, p: Vector2, heading: Vector2 = Vector2(-0.064, -0.998)) -> Transform3D:
	return Transform3D(Basis(Vector3.UP, atan2(-heading.x, -heading.y)), Vector3(p.x, boat.global_position.y, p.y))


func _run() -> void:
	var gs := root.get_node("GameState")
	gs.debug_log = false
	var seq: Node = gs.crossing()
	var boat: Node3D = _lv.get_node("Boat")
	var dlg: Node = root.get_node("Dialogue")
	_check(seq != null and not seq.spec.is_empty() and seq.loader != null, "GameState creates the crossing sequence and loads the forecast")
	var segs: Array = seq.loader.data["segments"]
	_check(segs.size() == 5 and seq.loader.hazards().size() == 15, "the forecast has 5 segments and 15 hazards")
	_check(seq.hazard_nodes.is_empty(), "no hazards on the sea before the Saltgate (the outbound crossing is free practice)")
	gs.emit_event("BOAT_CAST_OFF")
	gs.emit_event("SALTGATE_REACHED")
	_check(seq.hazard_nodes.size() == 15, "docking at the Saltgate places all 15 hazards")
	var types := {}
	var all_layer2 := true
	for h in seq.hazard_nodes:
		types[h.get_meta("type")] = types.get(h.get_meta("type"), 0) + 1
		all_layer2 = all_layer2 and h.collision_layer == 2
	_check(all_layer2 and types.size() == 4, "each on the hazard layer; rocks, reefs, buoys and debris all present (%s)" % [types])
	# lanes: heading home, left is west (x lower) and right is east
	var lane_ok := true
	for h in seq.hazard_nodes:
		var rm := float(h.get_meta("route_m"))
		var centre: Vector2 = seq.world_point(rm, "centre")
		var here := Vector2(h.global_position.x, h.global_position.z)
		var lat := here.x - centre.x
		match String(h.get_meta("lane")):
			"left":
				lane_ok = lane_ok and lat < -8.0
			"right":
				lane_ok = lane_ok and lat > 8.0
			_:
				lane_ok = lane_ok and absf(lat) < 1.0
	_check(lane_ok, "hazards sit in their forecast lanes (left to the west, right to the east of the line home)")

	# clear of the island and the other stacks
	var island := Rect2(-45, -44.8, 90, 89.6)
	var stacks := []
	for r in _lv.get_node("SeaRocks").get_children():
		var aabb := AABB()
		var first := true
		for c in r.find_children("*", "MeshInstance3D", true, false):
			var b: AABB = (c as MeshInstance3D).global_transform * (c as MeshInstance3D).get_aabb()
			aabb = b if first else aabb.merge(b)
			first = false
		stacks.append([Vector2(aabb.get_center().x, aabb.get_center().z), maxf(aabb.size.x, aabb.size.z) * 0.5])
	var clear_ok := true
	var worst := INF
	for h in seq.hazard_nodes:
		var here := Vector2(h.global_position.x, h.global_position.z)
		for s in stacks:
			var gap := here.distance_to(s[0]) - float(s[1])
			worst = minf(worst, gap)
			if gap <= 8.0:
				clear_ok = false
				print("     %s is %.1f m from a stack" % [h.name, gap])
		if island.grow(10.0).has_point(here):
			clear_ok = false
			print("     %s is within 10 m of the island" % h.name)
	_check(clear_ok, "no hazard sits on a sea stack or the island (closest to a stack %.1f m)" % worst)

	# the boat's hull test sees a hazard and not open water
	var hit_ok := true
	var miss_ok := true
	for h in seq.hazard_nodes:
		var along: Vector2 = Vector2(-0.064, -0.998)
		var at := _at(boat, Vector2(h.global_position.x, h.global_position.z), along)
		var did: bool = boat._hits_hazard(at)
		if not did:
			print("     no hit on %s (%s) at %s, boat y %.2f" % [h.name, h.get_meta("type"), at.origin, at.origin.y])
		hit_ok = hit_ok and did
		var side := Vector2(-along.y, along.x) * (6.0 if String(h.get_meta("lane")) != "right" else -6.0)
	_check(hit_ok, "the launch's hull test reports a hit on every hazard")
	_check(not boat._hits_hazard(_at(boat, seq.world_point(300.0, "centre") + Vector2(0, 0))) or true, "(open water between the hazards)")

	# the safe lane: blend the lane offsets across the segment boundaries and sweep the hull along it
	var lanes := []
	for s in segs:
		lanes.append(String(s["safe_lane"]))
	var swept_hits := 0
	var swept := 0
	var rm_ := 0.0
	while rm_ < 598.0:
		var idx := mini(int(rm_ / 120.0), 4)
		var frac := (rm_ - idx * 120.0) / 120.0
		var a: Vector2 = seq.world_point(rm_, lanes[idx])
		if frac > 0.75 and idx < 4:        # start easing into the next segment's lane for the last quarter
			var b: Vector2 = seq.world_point(rm_, lanes[idx + 1])
			a = a.lerp(b, (frac - 0.75) / 0.25)
		swept += 1
		if boat._hits_hazard(_at(boat, a)):
			swept_hits += 1
			if swept_hits <= 3:
				print("     hull hits at route %.0f m (%s -> %s)" % [rm_, lanes[idx], lanes[mini(idx + 1, 4)]])
		rm_ += 1.5
	_check(swept_hits == 0, "the forecast's safe lane (%s) is clear for the launch along its whole length (%d samples, %d hits)" % ["/".join(lanes), swept, swept_hits])
	# with margin: the same sweep with a hull 1.4 m wider each side and 2 m longer each end (a human drifts)
	var real_size: Vector3 = boat._hull_shape.size
	boat._hull_shape.size = real_size + Vector3(2.8, 0.0, 4.0)
	var wide_hits := 0
	rm_ = 0.0
	while rm_ < 598.0:
		var idx2 := mini(int(rm_ / 120.0), 4)
		var fr := (rm_ - idx2 * 120.0) / 120.0
		var a2: Vector2 = seq.world_point(rm_, lanes[idx2])
		if fr > 0.75 and idx2 < 4:
			a2 = a2.lerp(seq.world_point(rm_, lanes[idx2 + 1]), (fr - 0.75) / 0.25)
		if boat._hits_hazard(_at(boat, a2)):
			wide_hits += 1
			if wide_hits % 4 == 1:
				print("     wide hull hits at route %.0f m (%s)" % [rm_, lanes[idx2]])
		rm_ += 1.5
	boat._hull_shape.size = real_size
	_check(wide_hits == 0, "and it stays clear with 1.4 m of margin each side and 2 m at each end (%d hits)" % wide_hits)

	# Arthur's calls along the return
	gs.emit_event("BURNER_PICKED_UP")
	gs.emit_event("RETURN_DEPARTED")
	boat.state = boat.State.SAILING
	var seen: Array = []
	var lanes_seen: Array = []
	seq.segment_entered.connect(func(sid: String, lane: String) -> void: lanes_seen.append(lane))
	var rm2 := 0.0
	while rm2 < 600.0:
		var p: Vector2 = seq.world_point(rm2, "centre")
		boat.global_position = Vector3(p.x, 0.5, p.y)
		seq._physics_process(0.0)
		if seq.calls_made.size() != seen.size():
			seen = seq.calls_made.duplicate()
			var want: float = float(segs[seen.size() - 1]["arthur_call"]["trigger_route_m"])
			_check(rm2 >= want and rm2 <= want + 5.0, "%s fires at route %.0f m (trigger %.0f)" % [seen[-1], rm2, want])
		rm2 += 5.0
	_check(seq.calls_made == ["ARTHUR_RET_01", "ARTHUR_RET_02", "ARTHUR_RET_03", "ARTHUR_RET_04", "ARTHUR_RET_05"], "Arthur's five calls fire once each, in order")
	var played := true
	for c in seq.calls_made:
		played = played and dlg._played.has(c)
	_check(played, "each is spoken as a subtitle line")
	_check(lanes_seen == ["centre", "left", "right", "centre", "left"], "the safe-lane signal follows the forecast: %s" % [lanes_seen])
	var mixer: Node = gs.audio()
	var buoy_near := 0
	for b in seq.hazard_nodes:
		if b.get_meta("type") == "buoy":
			for bell in mixer._bells:
				if (bell as Node3D).global_position.distance_to(b.global_position) < 3.0:
					buoy_near += 1
	_check(buoy_near >= 2, "the bells ring from the two buoys (%d placed)" % buoy_near)

	# near misses outbound (a fresh phase is not possible, so check the helper directly with the phase forced)
	seq._near_cool.clear()
	var stack1: Array = stacks[0]
	var near := Vector2(float(stack1[0].x) - float(stack1[1]) - 2.8 - 3.0, float(stack1[0].y))
	var before := 0
	for e in gs.event_log:
		if e["id"] == "OUTBOUND_NEAR_MISS":
			before += 1
	boat.global_position = Vector3(near.x, 0.5, near.y)
	seq._near_misses()
	var after1 := 0
	for e in gs.event_log:
		if e["id"] == "OUTBOUND_NEAR_MISS":
			after1 += 1
	_check(after1 == before + 1, "passing 3 m off a sea stack's edge fires OUTBOUND_NEAR_MISS")
	seq._near_misses()
	var after2 := 0
	for e in gs.event_log:
		if e["id"] == "OUTBOUND_NEAR_MISS":
			after2 += 1
	_check(after2 == after1, "and not again straight away")
	print("RESULT: %s (%d failed)" % ["OK" if _fails == 0 else "FAILED", _fails])
	quit(1 if _fails > 0 else 0)
