# test_island_walk.gd - run: Godot --headless --path . --script res://tools/test_island_walk.gd
# Walks the player along routes on the craggy island (island_craggy.glb), from the dock_harbour jetties up the
# HarbourStairs (stone_stairs.gd) to the plateau, on to the lighthouse and back down. Reports for each route whether the player got to the
# end, how high they climbed and how long they spent off the floor (falling or stuck on a ledge).
extends SceneTree

# Each route: name, then world-space waypoints (y is ignored; the player starts 1.5 m above the first one).
# Waypoints count as reached within 1 m, so the stair-top one on the way down sits west of the landing: the player then
# lines up with the island gate's 1.36 m opening instead of walking into its east pillar.
const ROUTES := [
	["north jetty -> back quay -> stone stairs -> plateau", [Vector3(-27.0, 1.5, 14.7), Vector3(-19.0, 0, 14.7), Vector3(-19.0, 0, 25.5), Vector3(-16.25, 0, 25.5), Vector3(-16.25, 0, 16.8), Vector3(-16.25, 0, 9.0), Vector3(-13.0, 0, 8.5), Vector3(-9.0, 0, 6.0)]],
	["south jetty -> back quay -> stone stairs landing", [Vector3(-27.0, 1.5, 26.3), Vector3(-19.0, 0, 26.3), Vector3(-19.0, 0, 25.5), Vector3(-16.25, 0, 25.5), Vector3(-16.25, 0, 16.8)]],
	["plateau -> lighthouse", [Vector3(-9.0, 10.0, 6.0), Vector3(2.0, 0, 10.0), Vector3(5.0, 0, 6.5)]],
	["plateau -> stone stairs -> back quay -> north jetty", [Vector3(-9.0, 10.0, 6.0), Vector3(-13.0, 0, 8.5), Vector3(-17.2, 0, 9.0), Vector3(-16.25, 0, 16.8), Vector3(-16.25, 0, 25.7), Vector3(-17.3, 0, 25.7), Vector3(-19.0, 0, 25.7), Vector3(-19.0, 0, 14.7), Vector3(-26.0, 0, 14.7)]],
]

var _lv: Node
var _p: CharacterBody3D
var _f := 0
var _route := -1
var _wps: Array = []
var _wp := 0
var _frames := 0
var _off := 0
var _top := -INF


func _initialize() -> void:
	_lv = load("res://scenes/Level.tscn").instantiate()
	root.add_child(_lv)
	_p = _lv.get_node("Player")


func _begin() -> void:
	_route += 1
	if _route == 0:
		for g in get_nodes_in_group("gate"):   # the island gate on the stairs; tools/test_island_gate.gd covers it shut
			g.open()
	if _route >= ROUTES.size():
		quit()
		return
	_wps = ROUTES[_route][1]
	_wp = 1
	_frames = 0
	_off = 0
	_top = -INF
	_p.global_position = _wps[0] + Vector3.UP * 1.5
	_p.velocity = Vector3.ZERO
	print("-- route: ", ROUTES[_route][0])


func _physics_process(_dt: float) -> bool:
	_f += 1
	if _f < 20:
		return false
	if _route < 0:
		_begin()
		return false
	_frames += 1
	_top = maxf(_top, _p.global_position.y)
	if not _p.is_on_floor():
		_off += 1
	var to: Vector3 = _wps[_wp]
	var dv := Vector3(to.x - _p.global_position.x, 0.0, to.z - _p.global_position.z)
	if dv.length() < 1.0 and _wp < _wps.size() - 1:
		_wp += 1
		return false
	var done := _wp == _wps.size() - 1 and dv.length() < 1.2
	if done or _frames > 1500 or _p.global_position.y < -1.0:
		print("end: (%.1f, %.1f, %.1f) after %d frames; waypoint %d of %d; highest %.1f; frames off the floor %d; %s" % [
			_p.global_position.x, _p.global_position.y, _p.global_position.z, _frames, _wp + 1, _wps.size(), _top, _off,
			"REACHED THE END" if done else "DID NOT FINISH"])
		Input.action_release("move_forward")
		_begin()
		return false
	_p.rotation.y = atan2(-dv.x, -dv.z)
	Input.action_press("move_forward")
	return false
