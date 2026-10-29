# npc_routes.gd - reads the baked NPC routes (data/world/npc_paths.json, written by tools/bake_npc_paths.gd).
extends RefCounted

const PATH := "res://data/world/npc_paths.json"

static var _cache: Dictionary = {}


static func load_all() -> Dictionary:
	if not _cache.is_empty():
		return _cache
	var f := FileAccess.open(PATH, FileAccess.READ)
	if f == null:
		push_error("npc_routes: cannot read %s (run tools/bake_npc_paths.gd)" % PATH)
		return {}
	var d: Variant = JSON.parse_string(f.get_as_text())
	if d is Dictionary:
		_cache = d
	return _cache


static func names() -> Array:
	return load_all().get("routes", {}).keys()


## The baked points of a route, world positions at floor height. Empty (with an error) if the route is unknown.
static func route(route_name: String) -> PackedVector3Array:
	var r: Dictionary = load_all().get("routes", {})
	var out := PackedVector3Array()
	if not r.has(route_name):
		push_error("npc_routes: no route '%s'" % route_name)
		return out
	for p in r[route_name]["points"]:
		out.append(Vector3(float(p[0]), float(p[1]), float(p[2])))
	return out


static func spec(key: String) -> Variant:
	return load_all().get(key)
