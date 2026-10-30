# test_npc.gd - run: Godot --headless --path . --script res://tools/test_npc.gd
# T30: the capsule sailors (scripts/character/npc.gd) and their baked routes (data/world/npc_paths.json) against the real level.
#   1. the routes exist, start at the south jetty and end where the story needs them (Arthur in the hall, Daniel at his basement marker);
#   2. a walker's body (chest-high, 0.3 m radius) fits along every route with the gate and door open, and the island gate shut
#      stops the dock route (a control: the test can tell a blocked route);
#   3. the walker follows a route to its end in about length / speed, fires arrived once, stays put afterwards (Daniel stays);
#   4. wait() pauses and resumes, follow() keeps its distance, sit() rides a moving seat and release_seat() puts the walker back.
extends SceneTree

const Npc := preload("res://scripts/character/npc.gd")
const Routes := preload("res://scripts/character/npc_routes.gd")
const Check := preload("res://tools/check_interior_reach.gd")

var _lv: Node
var _f := 0
var _fails := 0


func _initialize() -> void:
	_lv = load("res://scenes/Level.tscn").instantiate()
	root.add_child(_lv)


func _check(cond: bool, msg: String) -> void:
	print("%s  %s" % ["PASS" if cond else "FAIL", msg])
	if not cond:
		_fails += 1


func _physics_process(_d: float) -> bool:
	_f += 1
	if _f == 5:
		for g in get_nodes_in_group("gate"):
			g.open()
		_lv.get_node("LighthouseDoor").open()
	if _f == 60:
		_run()
	elif _f == 61:
		for g in get_nodes_in_group("gate"):
			g.close()
	elif _f == 160:
		_run_shut_gate()
		quit(1 if _fails > 0 else 0)
	return false


func _blocked_points(pts: PackedVector3Array) -> Array:
	var space: PhysicsDirectSpaceState3D = _lv.get_world_3d().direct_space_state
	var cap := CapsuleShape3D.new()
	cap.radius = 0.3
	cap.height = 1.0
	var ex: Array[RID] = [(_lv.get_node("Player") as CharacterBody3D).get_rid()]
	var bad := []
	var last := Vector3(INF, INF, INF)
	for p in pts:
		if p.distance_to(last) < 0.5:
			continue
		last = p
		var q := PhysicsShapeQueryParameters3D.new()
		q.shape = cap
		q.transform = Transform3D(Basis(), p + Vector3(0.0, 1.15, 0.0))     # chest height: the floor, steps and rails below do not count
		q.exclude = ex
		q.margin = 0.0
		if not space.intersect_shape(q, 1).is_empty():
			bad.append(p)
	return bad


func _run() -> void:
	var names := Routes.names()
	for n in ["sailors_dock_to_porch", "sailors_dock_to_hall", "daniel_dock_to_basement", "hall_to_porch", "porch_to_hall", "hall_to_launch_berth", "ted_to_lamp"]:
		_check(names.has(n), "route %s is baked" % n)
	var to_hall := Routes.route("sailors_dock_to_hall")
	var to_base := Routes.route("daniel_dock_to_basement")
	var start := Vector3(-27.0, 1.48, 26.3)
	_check(to_hall[0].distance_to(start) < 0.3 and to_base[0].distance_to(start) < 0.3, "the sailors' routes start at the south jetty, the rowboat's berth")
	var door: Node3D = _lv.get_node("LighthouseDoor")
	var out_v: Vector3 = door.global_transform.basis.z
	var rel: Vector3 = to_hall[-1] - door.middle()
	_check(rel.dot(out_v) < -1.2 and rel.dot(out_v) > -3.5 and rel.length() < 3.5 and absf(to_hall[-1].y - 10.58) < 0.3, "Arthur's route ends just past the main door, inside the hall (%.1f m in, %.1f m from the door; %s)" % [-rel.dot(out_v), rel.length(), to_hall[-1]])
	var daniel_marker: Vector3 = Check.markers(_lv)["B1_daniel_marker"]
	_check(Vector2(to_base[-1].x - daniel_marker.x, to_base[-1].z - daniel_marker.z).length() < 1.5 and to_base[-1].y < 9.0, "Daniel's route ends in the basement next to his marker (%.1f m off)" % Vector2(to_base[-1].x - daniel_marker.x, to_base[-1].z - daniel_marker.z).length())
	var through_door := false
	for p in to_hall:
		if Vector2(p.x - door.middle().x, p.z - door.middle().z).length() < 0.5:
			through_door = true
	_check(through_door, "the route passes through the door opening")

	# fit
	for n in ["sailors_dock_to_hall", "daniel_dock_to_basement", "hall_to_launch_berth", "ted_to_lamp"]:
		var bad := _blocked_points(Routes.route(n))
		_check(bad.is_empty(), "%s is clear for a walker's body along its whole length (%d blocked sample points)%s" % [n, bad.size(), "" if bad.is_empty() else ", first at " + str(bad[0])])
	_walk_tests(to_hall, to_base)


func _run_shut_gate() -> void:
	var shut := _blocked_points(Routes.route("sailors_dock_to_hall"))
	_check(not shut.is_empty(), "control: with the island gate shut the same route is blocked (%d points)" % shut.size())
	print("RESULT: %s (%d failed)" % ["OK" if _fails == 0 else "FAILED", _fails])


func _walk_tests(to_hall: PackedVector3Array, to_base: PackedVector3Array) -> void:
	for g in get_nodes_in_group("gate"):
		g.open()
	# walking
	var arthur := Npc.spawn(_lv, "ARTHUR", to_hall[0])
	var daniel := Npc.spawn(_lv, "DANIEL", to_base[0])
	_check(arthur.get_node_or_null("Model") != null and daniel.get_node("Capsule") != null and daniel.is_in_group("npc"), "Arthur has his model and Daniel is a capsule")
	var arrivals := []
	arthur.arrived.connect(func(n: String) -> void: arrivals.append("arthur:" + n))
	daniel.arrived.connect(func(n: String) -> void: arrivals.append("daniel:" + n))
	arthur.walk(to_hall, "sailors_dock_to_hall")
	daniel.walk(to_base, "daniel_dock_to_basement")
	var t := 0.0
	while (arthur.state != Npc.State.IDLE or daniel.state != Npc.State.IDLE) and t < 200.0:
		arthur._process(0.1)
		daniel._process(0.1)
		t += 0.1
	var routes_spec: Dictionary = Routes.spec("routes")
	var expect_a: float = float(routes_spec["sailors_dock_to_hall"]["length_m"]) / arthur.walk_speed
	var expect_d: float = float(routes_spec["daniel_dock_to_basement"]["length_m"]) / daniel.walk_speed
	_check(arrivals.count("arthur:sailors_dock_to_hall") == 1 and arrivals.count("daniel:daniel_dock_to_basement") == 1, "both arrive, once each (%s)" % [arrivals])
	_check(t > 0.0 and absf(t - maxf(expect_a, expect_d)) < 3.0, "the walk takes about length / speed (%.0f s, expected %.0f s)" % [t, maxf(expect_a, expect_d)])
	_check(arthur.global_position.distance_to(to_hall[-1]) < 0.05 and daniel.global_position.distance_to(to_base[-1]) < 0.05, "each ends on the last route point")
	var rest := daniel.global_position
	for i in 200:
		daniel._process(0.1)
	_check(daniel.global_position == rest and daniel.state == Npc.State.IDLE, "Daniel stays in the basement (stays put for 20 s after arriving)")

	# wait: pauses a walk in progress and resumes
	var w := Npc.spawn(_lv, "ARTHUR", to_hall[0])
	w.walk(to_hall, "w")
	for i in 100:
		w._process(0.1)
	var at_wait := w.global_position
	w.wait(3.0)
	for i in 25:
		w._process(0.1)
	_check(w.state == Npc.State.WAITING and w.global_position == at_wait, "wait() holds the walker still")
	for i in 10:
		w._process(0.1)
	_check(w.state == Npc.State.WALKING, "and the walk resumes after the wait")
	w.queue_free()

	# follow
	var target := Node3D.new()
	_lv.add_child(target)
	target.global_position = Vector3(0, 10.5, 40)
	var fol := Npc.spawn(_lv, "DANIEL", Vector3(0, 10.5, 50))
	fol.follow(target, 2.0)
	for i in 100:
		fol._process(0.1)
	var gap := Vector2(fol.global_position.x - target.global_position.x, fol.global_position.z - target.global_position.z).length()
	_check(absf(gap - 2.0) < 0.15, "follow() closes to the set gap (%.2f m)" % gap)
	target.global_position += Vector3(0, 0, -30)
	for i in 300:
		fol._process(0.1)
	var gap2 := Vector2(fol.global_position.x - target.global_position.x, fol.global_position.z - target.global_position.z).length()
	_check(absf(gap2 - 2.0) < 0.15, "and keeps it when the target moves off (%.2f m)" % gap2)
	fol.queue_free()
	target.queue_free()

	# sit
	var seat := Node3D.new()
	_lv.add_child(seat)
	seat.global_position = Vector3(-27.0, 0.6, 18.2)
	var sitter := Npc.spawn(_lv, "ARTHUR", Vector3(-20, 0, 18))
	sitter.sit(seat, Vector3(0.9, 0.0, 0.8))
	_check(sitter.state == Npc.State.SEATED and sitter.get_parent() == seat, "sit() seats the walker on the seat node")
	seat.global_position += Vector3(0, 0, 40)
	_check(sitter.global_position.distance_to(seat.global_position + Vector3(0.9, 0.0, 0.8)) < 0.01, "a seated walker rides along when the seat moves")
	sitter.release_seat()
	_check(sitter.get_parent() == _lv and sitter.state == Npc.State.IDLE and sitter.global_position.distance_to(seat.global_position + Vector3(0.9, 0.0, 0.8)) < 0.01, "release_seat() puts the walker back in the level where they sat")
