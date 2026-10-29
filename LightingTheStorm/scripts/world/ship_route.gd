# ship_route.gd - the passenger ship's lane as plain functions (no nodes), read from data/world/ship_route.json.
# Points are Vector2(x, z) in world metres. The ship's yaw is set so its bow (-Z) faces the direction of travel.
extends RefCounted

const PATH := "res://data/world/ship_route.json"


static func load_spec(path := PATH) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("ship_route: cannot read %s" % path)
		return {}
	var d: Variant = JSON.parse_string(f.get_as_text())
	return d if d is Dictionary else {}


static func points(arr: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in arr:
		out.append(Vector2(float(p[0]), float(p[1])))
	return out


static func length(pts: PackedVector2Array) -> float:
	var total := 0.0
	for i in range(pts.size() - 1):
		total += pts[i].distance_to(pts[i + 1])
	return total


## The point s metres along the polyline (clamped to its ends) and the unit direction of travel there.
static func sample(pts: PackedVector2Array, s: float) -> Dictionary:
	if pts.size() < 2:
		return {"pos": pts[0] if pts.size() == 1 else Vector2.ZERO, "dir": Vector2(0, 1)}
	var left := maxf(s, 0.0)
	for i in range(pts.size() - 1):
		var seg := pts[i].distance_to(pts[i + 1])
		if left <= seg or i == pts.size() - 2:
			var t := clampf(left / maxf(seg, 0.001), 0.0, 1.0)
			return {"pos": pts[i].lerp(pts[i + 1], t), "dir": (pts[i + 1] - pts[i]).normalized()}
		left -= seg
	return {"pos": pts[pts.size() - 1], "dir": Vector2(0, 1)}


## Yaw (radians about Y) that points the model's bow (-Z) along dir (x, z).
static func yaw_for(dir: Vector2) -> float:
	return atan2(-dir.x, -dir.y)


## The hull as sample points (centre line and both sides, bow to stern) for clearance checks.
static func hull_points(pos: Vector2, dir: Vector2, length_m: float, beam_m: float, step_m := 10.0) -> PackedVector2Array:
	var out := PackedVector2Array()
	var side := Vector2(-dir.y, dir.x)
	var a := -length_m * 0.5
	while a <= length_m * 0.5 + 0.01:
		for b in [-beam_m * 0.5, 0.0, beam_m * 0.5]:
			out.append(pos + dir * a + side * b)
		a += step_m
	return out
