# measure_island_cost.gd - ISL-09: what the island costs to draw from the sea and the Saltgate (needs a window).
# Run: Godot --path . --script res://tools/measure_island_cost.gd -- <out_dir> <tag> [breakdown]
# Puts a free camera at points on the return crossing (Saltgate dock -> island dock, boat eye height, looking at the
# lighthouse) in the RETURN phase, and at the Saltgate quay in OUTBOUND and BEACON_RELIT, and for each prints the frame's
# draw calls, primitives and objects (Performance monitors: every pass, shadows included) and the GPU/CPU render time,
# then the same with the island hidden, so the island's share is the difference. Saves a still per point as
# <out_dir>/isl09_<tag>_<point>.png for the before/after silhouette comparison.
# With "breakdown", also hides each island node in turn and prints what it costs at each point.
extends SceneTree

## The island: every top-level node of Level.tscn that sits on Bracken Isle (the lighthouse included, for the totals).
const ISLAND := ["Island", "RockPatchSE", "RockPatchSE2", "RockPatchNE", "Lighthouse", "LighthouseInterior",
	"InteriorRooms", "InteriorProps", "RainShelter", "LighthouseThreshold", "LighthouseDoor", "IslandReactions",
	"Harbour", "HarbourStairs", "IslandGate", "Lampposts", "LighthouseInteriorLights"]
const LOOK_AT := Vector3(5.0, 14.0, -8.5)                # the lighthouse, about half way up the tower
const DOCK := Vector3(-27.0, 3.0, 26.0)                  # just off the island's harbour
const SALTGATE := Vector3(6.0, 3.0, 531.0)               # the Saltgate berth (DockZonePort)

var _out := ""
var _tag := ""
var _breakdown := false
var _lv: Node
var _rig: Node
var _cam: Camera3D
var _plan: Array = []
var _k := 0
var _f := 0
var _step := 0          # 0 settle, 1 with island, 2 island hidden, 3+ breakdown
var _acc := {}
var _n := 0
var _rows: Array = []
var _cur := {}
var _bd_i := 0


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	_out = a[0] if a.size() > 0 else "user://"
	_tag = a[1] if a.size() > 1 else "now"
	_breakdown = a.size() > 2 and a[2] == "breakdown"
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	_lv = load("res://scenes/Level.tscn").instantiate()
	root.add_child(_lv)
	# the return crossing: points by distance from the lighthouse, on the straight line Saltgate -> dock
	for d in [530.0, 400.0, 300.0, 200.0, 130.0, 80.0, 45.0]:
		var t := _t_at_distance(d)
		var p := SALTGATE.lerp(DOCK, t)
		_plan.append({"name": "ret%03d" % int(d), "phase": "RETURN", "cam": p, "at": LOOK_AT})
	# the Saltgate quay, the player's eye looking back at the island
	_plan.append({"name": "saltgate_out", "phase": "OUTBOUND", "cam": Vector3(5.4, 7.0, 538.0), "at": LOOK_AT})
	_plan.append({"name": "saltgate_relit", "phase": "BEACON_RELIT", "cam": Vector3(5.4, 7.0, 538.0), "at": LOOK_AT})


func _t_at_distance(d: float) -> float:
	var best := 0.0
	var err := 1e9
	for i in 1001:
		var t := i / 1000.0
		var p := SALTGATE.lerp(DOCK, t)
		var e := absf(Vector2(p.x - 5.0, p.z + 8.5).length() - d)
		if e < err:
			err = e
			best = t
	return best


func _set_island_visible(on: bool) -> void:
	for n in ISLAND:
		var node := _lv.get_node_or_null(n) as Node3D
		if node:
			node.visible = on


func _sample() -> void:
	var vp := root.get_viewport_rid()
	var m := {
		"draws": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		"prims": Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
		"objs": Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),
		"gpu": RenderingServer.viewport_get_measured_render_time_gpu(vp),
		"cpu": RenderingServer.viewport_get_measured_render_time_cpu(vp),
	}
	for k in m:
		_acc[k] = _acc.get(k, 0.0) + m[k]
	_n += 1


func _avg() -> Dictionary:
	var r := {}
	for k in _acc:
		r[k] = _acc[k] / maxf(_n, 1)
	_acc = {}
	_n = 0
	return r


func _process(_d: float) -> bool:
	_f += 1
	if _f < 20:
		return false
	if _f == 20:
		RenderingServer.viewport_set_measure_render_time(root.get_viewport_rid(), true)
		_cam = Camera3D.new()
		_cam.fov = 70.0
		_cam.far = 3000.0
		root.add_child(_cam)
		_cam.make_current()
		var gs := root.get_node_or_null("GameState")
		if gs and gs.guidance():
			gs.guidance().visible = false
		_rig = _lv.get_node("LightingRig")
		_begin_point()
		return false
	if _rig:
		_rig._next_flash = 1e9
		_rig._flash_t = -1.0
	_f_point += 1
	# 12 frames to settle after each change, then 8 samples
	if _f_point <= 12:
		return false
	_sample()
	if _n < 8:
		return false
	var r := _avg()
	if _step == 0:
		_cur["with"] = r
		root.get_texture().get_image().save_png(_out.path_join("isl09_%s_%s.png" % [_tag, _plan[_k]["name"]]))
		_set_island_visible(false)
		_step = 1
	elif _step == 1:
		_cur["without"] = r
		_set_island_visible(true)
		_step = 2
		_bd_i = 0
		if _breakdown:
			_hide_one(_bd_i, false)
		else:
			_finish_point()
			return false
	else:
		_cur["bd_" + ISLAND[_bd_i]] = r
		_hide_one(_bd_i, true)
		_bd_i += 1
		if _bd_i >= ISLAND.size():
			_finish_point()
			return false
		_hide_one(_bd_i, false)
	_f_point = 0
	return false


var _f_point := 0


func _hide_one(i: int, show: bool) -> void:
	var node := _lv.get_node_or_null(ISLAND[i]) as Node3D
	if node:
		node.visible = show


func _begin_point() -> void:
	var p: Dictionary = _plan[_k]
	_rig.set_phase(p["phase"], true)
	_cam.look_at_from_position(p["cam"], p["at"], Vector3.UP)
	_cur = {"name": p["name"], "phase": p["phase"], "dist": Vector2(p["cam"].x - 5.0, p["cam"].z + 8.5).length()}
	_step = 0
	_f_point = 0


func _finish_point() -> void:
	var w: Dictionary = _cur["with"]
	var o: Dictionary = _cur["without"]
	print("ISL09 %s %-15s %-12s d=%4.0f  draws %5.0f (island %5.0f)  prims %8.0f (island %8.0f)  objs %4.0f (island %4.0f)  gpu %.2f ms (island %.2f)  cpu %.2f ms" % [
		_tag, _cur["name"], _cur["phase"], _cur["dist"], w["draws"], w["draws"] - o["draws"], w["prims"],
		w["prims"] - o["prims"], w["objs"], w["objs"] - o["objs"], w["gpu"], w["gpu"] - o["gpu"], w["cpu"]])
	if _breakdown:
		for n in ISLAND:
			var b: Dictionary = _cur.get("bd_" + n, {})
			if b.is_empty():
				continue
			var dd: float = w["draws"] - b["draws"]
			var dp: float = w["prims"] - b["prims"]
			if absf(dd) >= 1.0 or absf(dp) >= 500.0:
				print("ISL09   %-26s draws %5.0f  prims %8.0f" % [n, dd, dp])
	_rows.append(_cur)
	_k += 1
	if _k >= _plan.size():
		print("ISL09 done")
		quit()
		return
	_begin_point()
