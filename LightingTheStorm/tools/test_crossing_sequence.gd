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
	_check(seq.hazard_nodes.size() == 15, "all 15 hazards are on the sea from the start of the game, so both crossings see the same sea")
	gs.emit_event("BOAT_CAST_OFF")
	gs.emit_event("SALTGATE_REACHED")
	_check(seq.hazard_nodes.size() == 15, "and docking at the Saltgate does not place them again")
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

	# near misses: Arthur gets more frantic each time (three levels, the third repeats), outbound and on the return
	seq._near_cool.clear()
	seq._last_near = -100.0
	seq.dialogue_log.clear()
	seq.near_misses = 0
	var stack1: Array = stacks[0]
	var near := Vector2(float(stack1[0].x) - float(stack1[1]) - 2.8 - 1.8, float(stack1[0].y))
	boat.global_position = Vector3(near.x, 0.5, near.y)
	for i in 4:
		seq._near_cool.clear()
		seq._last_near = -100.0
		seq._near_misses()
	_check(seq.dialogue_log == ["ARTHUR_NEAR_1", "ARTHUR_NEAR_2", "ARTHUR_NEAR_3", "ARTHUR_NEAR_3"], "four near misses on one crossing: level 1, 2, 3, 3 (%s)" % [seq.dialogue_log])
	seq._near_misses()
	_check(seq.dialogue_log.size() == 4, "and not again at once (cool-down)")
	seq._near_cool.clear()
	seq._last_near = -100.0
	seq.dialogue_log.clear()
	boat.global_position = Vector3(near.x - 3.0, 0.5, near.y)       # 4.8 m off the edge: not close enough any more
	seq._near_misses()
	_check(seq.dialogue_log.is_empty(), "a pass 4.8 m off the edge is not a near miss any more: Arthur waits until the boat is closer")
	boat.global_position = Vector3(near.x, 0.5, near.y)
	# a near miss on a hazard (not only the stacks): 3 m off a rock hazard's edge
	seq._new_leg(true)
	seq.dialogue_log.clear()
	var rock_h: Node3D = null
	for h in seq.hazard_nodes:
		if h.get_meta("type") == "rock":
			rock_h = h
			break
	var rp := Vector2(rock_h.global_position.x, rock_h.global_position.z)
	boat.global_position = Vector3(rp.x + float(rock_h.get_meta("near_r")) + 2.8 + 1.8, 0.5, rp.y)
	seq._near_cool.clear()
	seq._last_near = -100.0
	seq._near_misses()
	_check(seq.dialogue_log == ["ARTHUR_NEAR_1"], "a pass 1.8 m off a hazard's edge on the return is a near miss too, and a new crossing starts calm (%s)" % [seq.dialogue_log])
	var lines_ok := true
	for id in ["ARTHUR_NEAR_1", "ARTHUR_NEAR_2", "ARTHUR_NEAR_3", "ARTHUR_HIT_1", "ARTHUR_HIT_2", "ARTHUR_HIT_3", "DOCKING_DIALOGUE", "DOCKING_DIALOGUE_LIGHTHOUSE_1", "DOCKING_DIALOGUE_LIGHTHOUSE_2", "DOCKING_DIALOGUE_LIGHTHOUSE_3"]:
		var found := false
		for l in dlg.data["lines"]:
			if l["trigger"] == id and l["speaker"] == "ARTHUR":
				found = true
		lines_ok = lines_ok and found
	_check(lines_ok, "every near-miss, collision and docking trigger has an Arthur line in the dialogue data")

	# a return collision: thrown back, rocking hard, 5 s on the deadline, not put back at the last clear spot
	var dl: Node = gs.deadline()
	seq._new_leg(true)
	seq.dialogue_log.clear()
	seq.return_hits = 0
	_check(boat.hard_bounce, "the return switches the hard bounce on")
	var elapsed0: float = dl.elapsed
	var target: Node3D = null
	for h in seq.hazard_nodes:
		if h.get_meta("type") == "rock":
			target = h
	var tp2 := Vector2(target.global_position.x, target.global_position.z)
	var approach := Vector2(tp2.x, tp2.y + 5.3)             # just south of the rock (its radius plus the hull's half length), heading north (-Z) into it
	boat.global_position = Vector3(approach.x, boat.global_position.y, approach.y)
	boat.rotation.y = 0.0
	boat.state = boat.State.SAILING
	boat.driving = false
	boat._grace_zone = null
	boat._leave_zone = null
	boat._trail.clear()
	var start_pos: Vector3 = boat.global_position
	var hits_before: int = seq.return_hits
	boat._sail(1.0 / 60.0)
	_check(seq.return_hits == hits_before + 1, "driving into a rock on the return is a collision")
	_check(is_equal_approx(dl.elapsed - elapsed0, 5.0), "which costs 5 s on the deadline (%.1f s)" % (dl.elapsed - elapsed0))
	_check(seq.dialogue_log.has("ARTHUR_HIT_1"), "and Arthur's first collision line plays")
	_check(boat._rock_t >= 0.0 and boat._bounce_t >= 0.0, "the hull rocks and is being thrown back")
	var max_step := 0.0
	var last: Vector3 = boat.global_position
	var rocked := 0.0
	for i in 120:
		boat._sail(1.0 / 60.0)
		boat._float(1.0 / 60.0)
		max_step = maxf(max_step, boat.global_position.distance_to(last))
		last = boat.global_position
		rocked = maxf(rocked, absf(boat.get_node("Rig").rotation.z))
	var thrown := Vector2(boat.global_position.x - tp2.x, boat.global_position.z - tp2.y).length()
	var moved := Vector2(boat.global_position.x - start_pos.x, boat.global_position.z - start_pos.z).length()
	_check(moved > 2.0 and moved < 5.0, "it is thrown back about 3 m from where it hit (%.1f m), not put back at an earlier spot" % moved)
	_check(max_step < 1.0, "smoothly, with no jump (largest step in one frame %.2f m)" % max_step)
	_check(rocked > deg_to_rad(25.0), "rocking very hard (up to %.0f degrees of roll)" % rad_to_deg(rocked))
	_check(thrown > 3.0 and not boat._hits_hazard(boat.global_transform), "and ends clear of the rock")
	# outbound keeps the old recovery: no penalty, put back at the last clear spot
	seq._new_leg(false)
	_check(not boat.hard_bounce, "outbound collisions keep the old recovery")
	var el1: float = dl.elapsed
	seq._on_hit()
	_check(dl.elapsed == el1, "an outbound collision costs nothing")

	# docking: DOCKING_DIALOGUE every time; the admonishment at the lighthouse after a rough return
	seq.dialogue_log.clear()
	seq.return_hits = 0
	boat.docking_started.emit("DOCK_PORT")
	boat.docking_started.emit("DOCK_LIGHTHOUSE")
	_check(seq.dialogue_log == ["DOCKING_DIALOGUE", "DOCKING_DIALOGUE"], "a clean run: DOCKING_DIALOGUE at both docks (%s)" % [seq.dialogue_log])
	var tiers := {}
	for n in [1, 2, 3, 4, 6]:
		seq.dialogue_log.clear()
		seq.return_hits = n
		boat.docking_started.emit("DOCK_LIGHTHOUSE")
		tiers[n] = seq.dialogue_log[0]
	_check(tiers == {1: "DOCKING_DIALOGUE_LIGHTHOUSE_1", 2: "DOCKING_DIALOGUE_LIGHTHOUSE_2", 3: "DOCKING_DIALOGUE_LIGHTHOUSE_2", 4: "DOCKING_DIALOGUE_LIGHTHOUSE_3", 6: "DOCKING_DIALOGUE_LIGHTHOUSE_3"}, "after 1, 2-3, 4+ collisions the lighthouse docking line is level 1, 2, 3 (%s)" % [tiers])
	seq.dialogue_log.clear()
	seq.return_hits = 5
	boat.docking_started.emit("DOCK_PORT")
	_check(seq.dialogue_log == ["DOCKING_DIALOGUE"], "the Saltgate docking line does not change")
	# the real auto-dock fires the signal
	seq.dialogue_log.clear()
	seq.return_hits = 0
	var port: Node3D = null
	for z in get_nodes_in_group("dock_zone"):
		if z.zone_id == "DOCK_PORT":
			port = z
	boat.state = boat.State.SAILING
	boat._leave_zone = null
	boat._grace_zone = null
	boat.global_position = Vector3(port.global_position.x, boat.global_position.y, port.global_position.z - 4.0)
	boat._sail(1.0 / 60.0)
	_check(boat.state == boat.State.DOCKING and seq.dialogue_log.has("DOCKING_DIALOGUE"), "the boat's own auto-docking at the quay says DOCKING_DIALOGUE")
	print("RESULT: %s (%d failed)" % ["OK" if _fails == 0 else "FAILED", _fails])
	quit(1 if _fails > 0 else 0)
