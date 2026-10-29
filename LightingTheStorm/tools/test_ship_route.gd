# test_ship_route.gd - run: Godot --headless --path . --script res://tools/test_ship_route.gd
# T31: proves the passenger ship's lane (data/world/ship_route.json) against the real level:
#   1. the approach lane keeps the hull clear of the island and of every sea stack except the grounding rock;
#   2. with no beacon the bow meets the grounding rock (the ship is committed to it) and the ship's impact signal fires;
#   3. with the beacon lit at any moment up to the deadline the ship clears the rock, the island and the other stacks and reaches port;
#   4. the lamp room sees the grounding rock, the crash and the pass, and the ship's approach lane, with nothing in between.
extends SceneTree

const Route := preload("res://scripts/world/ship_route.gd")
const Ship := preload("res://scripts/world/passenger_ship.gd")

const HULL_MARGIN := 10.0      # clear water the hull must keep from rock or island on every lane
const SIGHT_EYE_Y := 29.1      # eye height standing at the lamp (world y of ANCHOR_lamp_stand 27.5 plus 1.6), in the lamp room
const BOAT_SEES_MIN := 0.5     # share of the return route from which the boat must see the ship
const SIGHT_MIN := 0.9         # fraction of sampled lane points the lamp room must see

var _lv: Node
var _f := 0
var _fails := 0
var _spec: Dictionary = {}
var _island := Rect2()
var _stacks: Array = []          # {name, centre Vector2, r}
var _rock: Dictionary = {}
var _eye := Vector3.ZERO


func _initialize() -> void:
	_lv = load("res://scenes/Level.tscn").instantiate()
	root.add_child(_lv)


func _check(cond: bool, msg: String) -> void:
	print("%s  %s" % ["PASS" if cond else "FAIL", msg])
	if not cond:
		_fails += 1


func _process(_d: float) -> bool:
	_f += 1
	if _f == 14:
		_run()
		quit(1 if _fails > 0 else 0)
	return false


func _aabb_of(n: Node) -> AABB:
	var out := AABB()
	var first := true
	var stack: Array = [n]
	while not stack.is_empty():
		var c: Node = stack.pop_back()
		for k in c.get_children():
			stack.append(k)
		var mi := c as MeshInstance3D
		if mi and mi.mesh:
			var b: AABB = mi.global_transform * mi.get_aabb()
			out = b if first else out.merge(b)
			first = false
	return out


func _run() -> void:
	_spec = Route.load_spec()
	_check(not _spec.is_empty(), "ship_route.json loads")
	var ib := _aabb_of(_lv.get_node("Island"))
	_island = Rect2(ib.position.x, ib.position.z, ib.size.x, ib.size.z)
	for r in _lv.get_node("SeaRocks").get_children():
		var b := _aabb_of(r)
		_stacks.append({"name": String(r.name), "centre": Vector2(b.get_center().x, b.get_center().z), "r": maxf(b.size.x, b.size.z) * 0.5})
	var rock_name: String = String(_spec["grounding_rock"]["node"]).get_file()
	for s in _stacks:
		if s["name"] == rock_name:
			_rock = s
	_check(not _rock.is_empty(), "grounding rock %s exists in SeaRocks" % rock_name)
	var rc: Array = _spec["grounding_rock"]["centre"]
	_check(_rock["centre"].distance_to(Vector2(float(rc[0]), float(rc[1]))) < 1.0, "the data's rock centre matches the model (%.1f, %.1f)" % [_rock["centre"].x, _rock["centre"].y])
	_check(absf(_rock["r"] - float(_spec["grounding_rock"]["radius_m"])) < 1.5, "the data's rock radius %.1f matches the model's %.1f" % [float(_spec["grounding_rock"]["radius_m"]), _rock["r"]])
	var lamp := _aabb_of(_lv.find_child("Lamp_SillRing", true, false))
	_eye = Vector3(lamp.get_center().x, SIGHT_EYE_Y, lamp.get_center().z)
	print("lamp room eye at ", _eye)
	_test_lane()
	_test_crash()
	_test_pass()
	_test_sight()
	print("RESULT: %s (%d failed)" % ["OK" if _fails == 0 else "FAILED", _fails])


## Clear water between the hull's sample points and the island or a stack (negative = inside).
func _clearance(pts: PackedVector2Array, skip_rock := false) -> float:
	var m := INF
	var isl := _island.grow(0.0)
	for p in pts:
		var dx := maxf(maxf(isl.position.x - p.x, p.x - isl.end.x), 0.0)
		var dz := maxf(maxf(isl.position.y - p.y, p.y - isl.end.y), 0.0)
		m = minf(m, sqrt(dx * dx + dz * dz) if (dx > 0.0 or dz > 0.0) else -1.0)
		for s in _stacks:
			if skip_rock and s["name"] == _rock["name"]:
				continue
			m = minf(m, p.distance_to(s["centre"]) - float(s["r"]))
	return m


func _hull(pos: Vector2, dir: Vector2) -> PackedVector2Array:
	return Route.hull_points(pos, dir, float(_spec["ship"]["length_m"]), float(_spec["ship"]["beam_m"]), 8.0)


func _test_lane() -> void:
	var pts := Route.points(_spec["approach"]["points"])
	var total := Route.length(pts)
	var commit: float = total - float(_spec["approach"]["commit_distance_m"])
	_check(commit > 0.0 and commit < total, "the commit point (%.0f of %.0f m) lies inside the approach lane" % [commit, total])
	var worst := INF
	var s := 0.0
	while s <= total:
		var smp: Dictionary = Route.sample(pts, s)
		var c := _clearance(_hull(smp["pos"], smp["dir"]), true)
		worst = minf(worst, c)
		s += 5.0
	_check(worst >= HULL_MARGIN, "approach lane keeps the hull %.1f m (>= %.0f) off the island and every other stack" % [worst, HULL_MARGIN])
	var rock_worst := INF
	s = 0.0
	while s <= total - float(_spec["ship"]["length_m"]):
		var smp2: Dictionary = Route.sample(pts, s)
		for p in _hull(smp2["pos"], smp2["dir"]):
			rock_worst = minf(rock_worst, p.distance_to(_rock["centre"]) - float(_rock["r"]))
		s += 5.0
	_check(rock_worst > 5.0, "the hull stays %.1f m clear of the grounding rock until the last %.0f m" % [rock_worst, float(_spec["ship"]["length_m"])])


func _test_crash() -> void:
	var ship := _new_ship()
	ship.set_progress(1.0)
	ship.commit()
	var impacts := [0]
	ship.impact.connect(func() -> void: impacts[0] += 1)
	var t := 0.0
	while ship.mode != Ship.Mode.CRASHED and t < 120.0:
		ship._process(0.1)
		t += 0.1
	_check(ship.mode == Ship.Mode.CRASHED and impacts[0] == 1, "no beacon: the ship crashes (impact fired once), %.1f s after the deadline" % t)
	var bow: Vector2 = ship.position2() + ship.direction2() * float(_spec["ship"]["length_m"]) * 0.5
	var gap := bow.distance_to(_rock["centre"]) - float(_rock["r"])
	_check(absf(gap) < 3.5, "the bow meets the rock face (gap %.1f m)" % gap)
	ship.queue_free()


func _test_pass() -> void:
	var total_commit: float = Route.length(Route.points(_spec["approach"]["points"])) - float(_spec["approach"]["commit_distance_m"])
	var all_ok := true
	var worst := INF
	for frac in [0.0, 0.25, 0.5, 0.8, 0.95, 0.99, 1.0]:
		var ship := _new_ship()
		ship.set_progress(frac)
		ship.avoid()
		var t := 0.0
		var min_c := INF
		while ship.mode == Ship.Mode.AVOIDING and t < 1200.0:
			ship._process(0.1)
			min_c = minf(min_c, _clearance(_hull(ship.position2(), ship.direction2())))
			t += 0.1
		var ok: bool = ship.mode == Ship.Mode.PASSED and min_c >= HULL_MARGIN
		all_ok = all_ok and ok
		worst = minf(worst, min_c)
		print("     beacon lit at %3.0f%% (%.0f m): %s, closest the hull came to rock or island %.1f m" % [frac * 100.0, frac * total_commit, "passes into port" if ship.mode == Ship.Mode.PASSED else "DOES NOT REACH PORT", min_c])
		ship.queue_free()
	_check(all_ok, "beacon lit at any moment up to the deadline: the ship reaches port with at least %.0f m clear (worst %.1f m)" % [HULL_MARGIN, worst])


func _new_ship() -> Node3D:
	var ship: Node3D = Ship.new()
	_lv.add_child(ship)
	ship.setup(_spec)
	ship.set_deadline_length(float(_spec["deadline"]["length_s"]))
	ship.appear()
	return ship


# ---- the lamp room's view ----

func _terrain(n: Node) -> bool:
	var p := n
	while p != null and p != _lv:
		var nm := String(p.name)
		if nm == "Island" or nm.begins_with("RockPatch") or nm == "SeaRocks":
			return true
		p = p.get_parent()
	return false


## True when nothing of the island or the stacks lies between the lamp-room eye and the point.
func _sees(target: Vector3) -> bool:
	var space := _lv.get_viewport().world_3d.direct_space_state
	var exclude: Array[RID] = []
	for i in 120:
		var q := PhysicsRayQueryParameters3D.create(_eye, target)
		q.exclude = exclude
		var hit := space.intersect_ray(q)
		if hit.is_empty():
			return true
		var col := hit["collider"] as Node
		if col != null and _terrain(col):
			if hit["position"].distance_to(target) < 6.0:   # the target sits on the rock itself
				return true
			return false
		exclude.append(hit["rid"])
	return false   # ran out of retries inside the lighthouse's own bodies: count it as blocked


func _test_sight() -> void:
	_check(not _sees(Vector3(30.0, -6.0, -20.0)), "control: the sight test does report the island when it is in the way (a point under its east side)")
	var rock_c: Vector2 = _rock["centre"]
	var toward := (Vector2(_eye.x, _eye.z) - rock_c).normalized()
	var face := rock_c + toward * (float(_rock["r"]) * 0.8)
	_check(_sees(Vector3(face.x, 9.0, face.y)), "the lamp room sees the grounding rock's face")
	var pts := Route.points(_spec["approach"]["points"])
	var total := Route.length(pts)
	var crash_pos: Dictionary = Route.sample(pts, total)
	var cp: Vector2 = crash_pos["pos"]
	_check(_sees(Vector3(cp.x, 12.0, cp.y)), "the lamp room sees the ship's centre at the moment of impact")
	var bow: Vector2 = cp + crash_pos["dir"] * float(_spec["ship"]["length_m"]) * 0.5
	_check(_sees(Vector3(bow.x, 8.0, bow.y)), "the lamp room sees the bow strike the rock")
	var seen := 0
	var n := 0
	var s := total * 0.3
	while s <= total:
		var smp: Dictionary = Route.sample(pts, s)
		var p: Vector2 = smp["pos"]
		n += 1
		if _sees(Vector3(p.x, 14.0, p.y)):
			seen += 1
		s += 15.0
	_check(float(seen) / float(n) >= SIGHT_MIN, "the lamp room sees the ship along its approach (%d of %d sampled points)" % [seen, n])
	var safe := Route.points(_spec["safe_lane"]["points"])
	var sp: Vector2 = safe[0]
	_check(_sees(Vector3(sp.x, 14.0, sp.y)), "the lamp room sees the ship pass the rock on the safe lane")
	var start: Vector2 = pts[0]
	_check(_sees(Vector3(start.x, 20.0, start.y)), "the lamp room sees the ship's lights at its starting point on the horizon")
	_test_boat_view(pts, total)


## The player's boat on the return crossing (heading north up the west side, the ship off to its right) must see the ship for most of
## the way: sampled every 40 m of the route, at the ship's lights at the start, half way in, at the turn and at the moment of impact.
## Some of the route is shadowed by the sea stacks beside it; that is scenery, so the bar is a share of the route, not all of it.
func _test_boat_view(pts: PackedVector2Array, total: float) -> void:
	var spots := {"start": 0.0, "half way": total * 0.5, "the turn": Route.length(PackedVector2Array([pts[0], pts[1]])), "impact": total}
	var saved := _eye
	for label in spots:
		var smp: Dictionary = Route.sample(pts, float(spots[label]))
		var p: Vector2 = smp["pos"]
		var seen := 0
		var n := 0
		var z := 100.0
		while z <= 520.0:
			_eye = Vector3(lerpf(-24.0, 4.0, (z - 100.0) / 420.0), 2.0, z)
			n += 1
			if _sees(Vector3(p.x, 14.0, p.y)):
				seen += 1
			z += 40.0
		print("     return crossing: the ship at its %s is in view from %d of %d points along the route" % [label, seen, n])
		_check(float(seen) / float(n) >= BOAT_SEES_MIN, "the boat sees the ship at its %s from %.0f%% of the return route (>= %.0f%%)" % [label, 100.0 * seen / n, 100.0 * BOAT_SEES_MIN])
	_eye = saved
