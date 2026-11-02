# bake_npc_paths.gd - run: Godot --headless --path . --script res://tools/bake_npc_paths.gd
# Bakes the routes the capsule sailors (scripts/character/npc.gd) walk into data/world/npc_paths.json. Outdoors the route is a
# hand-picked polyline (the waypoints tools/test_island_walk.gd already walks the player along) with the floor height read off the
# real collision every 0.4 m; indoors it is the interior flood fill's path (tools/interior_reach.gd), a standable cell every 0.25 m
# that already climbs the stairs by their treads. Run it again whenever the island, the harbour, the door or the interior change, then
# run tools/test_npc.gd. The island gate and the lighthouse door are opened first so their bars and leaf are not in the way.
extends SceneTree

const Reach := preload("res://tools/interior_reach.gd")
const Check := preload("res://tools/check_interior_reach.gd")
const OUT := "res://data/world/npc_paths.json"
const STEP_UP := 0.45     # the most a walker steps up between two samples (stair risers are about 0.19 m)
const BODY_R := 0.36      # the walker's clearance radius: the player's 0.3 plus a little
const SAMPLE := 0.1       # outdoor sampling distance: fine enough to land on every stair tread

## South jetty (where the rowboat is moored) -> back quay -> up the stone stairs through the gate -> plateau -> the porch.
const DOCK_TO_PORCH := [Vector2(-27.0, 26.3), Vector2(-19.0, 26.3), Vector2(-19.0, 25.5), Vector2(-16.25, 25.5), Vector2(-16.25, 16.8),
		Vector2(-16.25, 9.0), Vector2(-13.0, 8.5), Vector2(-12.4, 5.8), Vector2(-9.0, 5.6)]
## (creator, 2 Nov 2026: the sailors walked through a boulder on the plateau between the gate and the lighthouse, x -11.5..-9.5,
## z 6.5..8.5; the line now passes south of it, where the ground is clear all the way to the door)
## From the plateau at the top of the stairs to the front of the lighthouse; the last corner (towards the door) is a wide arc.
const PLATEAU_TO_DOOR := [Vector2(2.0, 6.0)]
const DOOR_ARC_M := 3.0
## Corners kept tight: the top of the stone stairs is just past the island gate, and a wide arc there swings the walker through the
## gate's post. They go straight through the gate, then curve away.
const TIGHT_CORNERS := {Vector2(-16.25, 9.0): 0.25}
## The player's launch berth (north jetty), reached down the same stairs and along the back quay.
const STAIRS_TO_LAUNCH := [Vector2(-13.0, 8.5), Vector2(-16.25, 9.0), Vector2(-16.25, 16.8), Vector2(-16.25, 25.7), Vector2(-19.0, 25.7), Vector2(-19.0, 14.7), Vector2(-26.0, 14.7)]

var _lv: Node
var _f := 0


func _initialize() -> void:
	_lv = load("res://scenes/Level.tscn").instantiate()
	root.add_child(_lv)


func _physics_process(_d: float) -> bool:
	_f += 1
	if _f == 5:
		for g in get_nodes_in_group("gate"):
			g.open()
		_lv.get_node("LighthouseDoor").open()
	if _f < 60:
		return false
	_bake()
	quit()
	return true


## The walkable surface at x, z reached from the height `expected` (a step up or a drop of up to 1.5 m), so a porch roof or a ceiling above is not taken for the floor.
func _ground(space: PhysicsDirectSpaceState3D, x: float, z: float, exclude: Array[RID], expected: float) -> float:
	var top := 45.0
	var best := NAN
	for _i in 40:
		var q := PhysicsRayQueryParameters3D.create(Vector3(x, top, z), Vector3(x, -5.0, z))
		q.exclude = exclude
		var hit := space.intersect_ray(q)
		if hit.is_empty():
			break
		var y: float = hit["position"].y
		if hit["normal"].y > 0.5:
			# the highest surface a walker can step up to from where they were (a porch roof or ceiling above is too high)
			if y <= expected + STEP_UP and y >= expected - 1.5 and (is_nan(best) or y > best):
				best = y
		top = y - 0.05
	return best


## A polyline on the ground: subdivided every 0.1 m, each point set on the floor.
func _outdoor(space: PhysicsDirectSpaceState3D, pts: Array, exclude: Array[RID], from_y: float) -> Array:
	var out: Array = []
	var last_y := from_y
	for i in range(pts.size() - 1):
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[i + 1]
		var n := maxi(int(ceil(a.distance_to(b) / SAMPLE)), 1)
		for k in n + (1 if i == pts.size() - 2 else 0):
			var p := a.lerp(b, float(k) / float(n))
			var y := _ground(space, p.x, p.y, exclude, last_y)
			if is_nan(y):
				y = last_y
			last_y = y
			out.append(Vector3(p.x, y, p.y))
	return _despike(space, _smooth(space, _nudge(space, out, exclude), exclude, 8, true), exclude, true)     # smooth out the sideways shifts' kinks


## Does a walker's chest-high body (floor, steps and rails below it do not count) touch the level at p?
func _blocked(space: PhysicsDirectSpaceState3D, p: Vector3, exclude: Array[RID]) -> bool:
	var cap := CapsuleShape3D.new()
	cap.radius = BODY_R
	cap.height = 1.0
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = cap
	q.transform = Transform3D(Basis(), p + Vector3(0.0, 1.15, 0.0))
	q.exclude = exclude
	q.margin = 0.0
	return not space.intersect_shape(q, 1).is_empty()


## Does a knee-high rock touch the walker's legs at p (a sphere 0.25-0.75 m above the floor)? The chest test above misses low rocks
## on the plateau, which the sailors walked through (creator, 2 Nov 2026). Outdoors on the plateau only: elsewhere treads and kerbs would count.
func _blocked_low(space: PhysicsDirectSpaceState3D, p: Vector3, exclude: Array[RID]) -> bool:
	if p.y < 8.0:
		return false        # the plateau only: down on the quay and the jetties the kerbs and step edges are walked over
	var sph := SphereShape3D.new()
	sph.radius = 0.25
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = sph
	q.transform = Transform3D(Basis(), p + Vector3(0.0, 0.5, 0.0))
	q.exclude = exclude
	q.margin = 0.0
	return not space.intersect_shape(q, 1).is_empty()


## Where the hand-picked polyline brushes a rock or a rail, slide the route sideways by the least amount that clears it, tapering the
## shift in and out over about a metre so the walker does not kink.
func _nudge(space: PhysicsDirectSpaceState3D, pts: Array, exclude: Array[RID]) -> Array:
	var n := pts.size()
	var offs: Array = []
	offs.resize(n)
	offs.fill(0.0)
	var perps: Array = []
	for i in n:
		var a: Vector3 = pts[maxi(i - 1, 0)]
		var b: Vector3 = pts[mini(i + 1, n - 1)]
		var d := Vector2(b.x - a.x, b.z - a.z).normalized()
		perps.append(Vector2(-d.y, d.x))
	var moved := 0
	for i in n:
		var p: Vector3 = pts[i]
		if not _blocked(space, p, exclude) and not _blocked_low(space, p, exclude):
			continue
		var found := NAN
		for step in range(1, 16):
			for sgn in [1.0, -1.0]:
				var o: float = step * 0.1 * sgn
				var c := Vector3(p.x + perps[i].x * o, p.y, p.z + perps[i].y * o)
				if not _blocked(space, c, exclude) and not _blocked_low(space, c, exclude):
					found = o
					break
			if not is_nan(found):
				break
		if is_nan(found):
			push_warning("bake_npc_paths: no clear sideways shift at %s" % p)
			continue
		var reach := 10
		for j in range(maxi(i - reach, 0), mini(i + reach + 1, n)):
			var w := 1.0 - float(absi(j - i)) / float(reach + 1)
			var v := found * w
			if absf(v) > absf(offs[j]):
				offs[j] = v
		moved += 1
	var out: Array = []
	for i in n:
		var p: Vector3 = pts[i]
		var o: float = offs[i]
		if o == 0.0:
			out.append(p)
			continue
		var x: float = p.x + perps[i].x * o
		var z: float = p.z + perps[i].y * o
		var y: float = _ground(space, x, z, exclude, p.y + 0.05)
		out.append(Vector3(x, p.y if is_nan(y) else y, z))
	if moved > 0:
		print("bake_npc_paths: slid %d blocked samples sideways" % moved)
	return out


## Round every corner of a hand-picked polyline (x, z) into an arc (a quadratic curve through the corner's neighbourhood), r metres
## each side of the corner or less on short legs; the last corner gets r_last (the swing in front of the door, creator 2 Nov 2026).
func _round(pts: Array, r: float, r_last: float) -> Array:
	var out: Array = [pts[0]]
	for i in range(1, pts.size() - 1):
		var a: Vector2 = pts[i - 1]
		var b: Vector2 = pts[i]
		var c: Vector2 = pts[i + 1]
		var rr: float = r_last if i == pts.size() - 2 else TIGHT_CORNERS.get(b, r)
		var d := minf(rr, minf(a.distance_to(b), b.distance_to(c)) * 0.45)
		var p0 := b + (a - b).normalized() * d
		var p2 := b + (c - b).normalized() * d
		for k in 9:
			var t := float(k) / 8.0
			out.append(p0.lerp(b, t).lerp(b.lerp(p2, t), t))
	out.append(pts[-1])
	return out


## Smooth a dense route into curves (creator, 2 Nov 2026: no zigzags, no right-angle turns): each pass moves every inner point halfway
## to the middle of its neighbours, back onto the floor; a move that would leave the floor or put the body into a wall is not made.
func _smooth(space: PhysicsDirectSpaceState3D, pts: Array, exclude: Array[RID], passes := 14, outdoors := false) -> Array:
	var p := pts.duplicate()
	var n := p.size()
	for _it in passes:
		var q := p.duplicate()
		for i in range(1, n - 1):
			var b: Vector3 = p[i]
			var t: Vector3 = b.lerp(((p[i - 1] as Vector3) + (p[i + 1] as Vector3)) * 0.5, 0.5)
			var y := _ground(space, t.x, t.z, exclude, b.y + 0.05)
			if is_nan(y) or absf(y - b.y) > 0.35:
				continue
			var cand := Vector3(t.x, y, t.z)
			if _blocked(space, cand, exclude) or (outdoors and _blocked_low(space, cand, exclude)):
				continue
			q[i] = cand
		p = q
	return p


## Drop single points that make a spike (a turn sharper than 60 degrees between neighbouring steps), where the straight line past
## them is clear: a sideways shift round a post can leave one point standing out that smoothing cannot move.
func _despike(space: PhysicsDirectSpaceState3D, pts: Array, exclude: Array[RID], outdoors: bool) -> Array:
	var p := pts.duplicate()
	var i := 2
	while i < p.size():
		var a: Vector3 = p[i - 2]
		var b: Vector3 = p[i - 1]
		var c: Vector3 = p[i]
		var d1 := Vector2(b.x - a.x, b.z - a.z)
		var d2 := Vector2(c.x - b.x, c.z - b.z)
		if d1.length() > 0.05 and d2.length() > 0.05 and absf(d1.angle_to(d2)) > deg_to_rad(60.0):
			var mid := a.lerp(c, 0.5)
			if not _blocked(space, mid, exclude) and not (outdoors and _blocked_low(space, mid, exclude)):
				p.remove_at(i - 1)
				i = maxi(i - 1, 2)
				continue
		i += 1
	return p


func _bake() -> void:
	var player: CharacterBody3D = _lv.get_node("Player")
	var exclude: Array[RID] = [player.get_rid()]
	var space: PhysicsDirectSpaceState3D = _lv.get_world_3d().direct_space_state
	var door: Node3D = _lv.get_node("LighthouseDoor")
	var out_v: Vector3 = door.global_transform.basis.z
	var porch: Vector3 = door.middle() + out_v * 1.0
	var reach := Reach.new(space, exclude)
	reach.build()
	if not reach.flood(porch + Vector3.UP * 0.05):
		push_error("bake_npc_paths: no standable spot in the porch")
		quit(1)
		return
	# the porch cell the interior routes start from, and the exterior route's end: a polyline across the plateau to it
	var start_spot := reach.nearest(porch, true)
	var porch_cell: Vector3 = start_spot["pos"]
	var dock_to_porch: Array = DOCK_TO_PORCH.duplicate()
	dock_to_porch.append_array(PLATEAU_TO_DOOR)
	dock_to_porch.append(Vector2(porch_cell.x, porch_cell.z))
	var ext: Array = _outdoor(space, _round(dock_to_porch, 1.2, DOOR_ARC_M), exclude, 1.5)    # the jetty deck is about 1.5 m up
	# interior routes
	# Arthur waits just past the main door (creator, 30 October 2026): 1.7 m inside, to one side of the doorway so he does not block it
	var side_v := Vector3(out_v.z, 0.0, -out_v.x)
	var hall_goal := {}
	for sgn in [-1.0, 1.0]:
		var cand: Vector3 = door.middle() - out_v * 1.7 + side_v * 1.2 * sgn
		var g := reach.nearest(cand, true)
		if not g.is_empty() and Vector2(g["pos"].x - cand.x, g["pos"].z - cand.z).length() < 0.5 and not _blocked(space, g["pos"], exclude):
			hall_goal = g
			print("bake_npc_paths: Arthur's wait spot ", g["pos"], " (door side ", sgn, ")")
			break
	if hall_goal.is_empty():
		hall_goal = reach.nearest(door.middle() - out_v * 2.5, true)
	var anchors: Dictionary = _lv.get_node("InteriorRooms").anchors
	var daniel_goal := reach.nearest(Check.markers(_lv)["B1_daniel_marker"], true)
	var hall_path: Array = _smooth(space, reach.centre_path_to(hall_goal), exclude)
	var basement_path: Array = _smooth(space, reach.centre_path_to(daniel_goal), exclude)
	var routes := {}
	routes["sailors_dock_to_porch"] = {"note": "From the south jetty (the rowboat's berth) up the stone stairs and across the plateau to the lighthouse porch.", "points": ext}
	var to_hall := ext.duplicate()
	to_hall.pop_back()
	to_hall.append_array(hall_path)
	routes["sailors_dock_to_hall"] = {"note": "Arthur's walk-in: the dock, the stairs, the porch, through the door into the hall (SAILORS_INSIDE).", "points": to_hall}
	var to_basement := ext.duplicate()
	to_basement.pop_back()
	to_basement.append_array(basement_path)
	routes["daniel_dock_to_basement"] = {"note": "Daniel's walk-in: as Arthur's, then through the hall and down the spiral stairs to the basement, where he stays (DANIEL_IN_BASEMENT).", "points": to_basement}
	routes["hall_to_porch"] = {"note": "Inside the door (the hall) back out to the porch.", "points": _reverse(hall_path)}
	routes["porch_to_hall"] = {"note": "The porch to the hall spot inside the door.", "points": hall_path}
	var back: Array = [Vector2(porch_cell.x, porch_cell.z)]
	var rev_plateau: Array = PLATEAU_TO_DOOR.duplicate()
	rev_plateau.reverse()
	back.append_array(rev_plateau)
	back.append(DOCK_TO_PORCH[-1])
	back.append(DOCK_TO_PORCH[-2])          # round the plateau boulder on its south side, as on the way in
	back.append_array(STAIRS_TO_LAUNCH)
	var to_launch: Array = _reverse(hall_path)
	to_launch.append_array(_outdoor(space, _round(back, 1.2, 1.2), exclude, porch_cell.y))
	routes["hall_to_launch_berth"] = {"note": "Arthur from the hall to the player's launch berth (the north jetty), for boarding (T11).", "points": to_launch}
	# Ted: from where he greets the player, up the spiral stairs to his spot beside the arc lamp
	var ted_from: Vector3 = (_lv.get_node("InteriorAnchors").anchors["ted_greeting"] as Node3D).global_position
	print("bake_npc_paths: Ted greets from ", ted_from)
	if reach.flood(ted_from + Vector3(0, 0.05, 0)):
		var ted_goal := reach.nearest(Vector3(8.5, 27.51, -6.8), true)
		if not ted_goal.is_empty():
			routes["ted_to_lamp"] = {"note": "Ted from the greeting spot behind the front door up the tower stairs to his spot beside the arc lamp (he walks it while he sends the player to the coal). Down the middle of the hall and the stairs, smoothed into curves.", "points": _smooth(space, reach.centre_path_to(ted_goal), exclude)}
	else:
		push_warning("bake_npc_paths: no standable spot at Ted's greeting spot")
	var data := {"spec_id": "npc_paths_v1", "baked_by": "tools/bake_npc_paths.gd", "note": "Baked world-space routes with floor heights. Do not edit by hand; re-run the bake tool when the level changes.", "routes": {}}
	for k in routes:
		var pts: Array = []
		var len_m := 0.0
		var prev := Vector3.ZERO
		for i in routes[k]["points"].size():
			var v: Vector3 = routes[k]["points"][i]
			pts.append([snappedf(v.x, 0.01), snappedf(v.y, 0.01), snappedf(v.z, 0.01)])
			if i > 0:
				len_m += v.distance_to(prev)
			prev = v
		data["routes"][k] = {"note": routes[k]["note"], "length_m": snappedf(len_m, 0.1), "points": pts}
		print("route %-26s %4d points  %6.1f m  ends at %s" % [k, pts.size(), len_m, routes[k]["points"][-1]])
	var f := FileAccess.open(OUT, FileAccess.WRITE)
	f.store_string(JSON.stringify(data, "  "))
	f.close()
	print("wrote ", OUT)


func _reverse(a: Array) -> Array:
	var out := a.duplicate()
	out.reverse()
	return out
