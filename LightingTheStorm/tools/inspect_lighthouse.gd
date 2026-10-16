# inspect_lighthouse.gd - run (windowed, not --headless: the meshes and screenshots need a renderer):
#   Godot --path . --script res://tools/inspect_lighthouse.gd [-- --out=<dir>] [--search] [--shot=name,cx,cy,cz,lx,ly,lz ...]
# Measures how the lighthouse sits on the island: on a 0.5 m grid over the lighthouse footprint it
# compares the underside of the lighthouse with the island surface, prints a map of island rock that
# rises inside the lighthouse (cutting into it) and of gaps where it floats, then saves screenshots of
# the lighthouse from around the island (or from the --shot cameras instead).
# --search also tries nearby positions and lists the ones with the least rock inside the lighthouse.
extends SceneTree

const CELL := 0.5
const SHOTS := [
	["n", Vector3(0, 6, -32)], ["e", Vector3(30, 6, 0)], ["s", Vector3(0, 6, 32)],
	["w", Vector3(-30, 6, 0)], ["ne_low", Vector3(14, 1.5, -14)], ["sw_low", Vector3(-14, 1.5, 14)],
	["top", Vector3(0.1, 45, 0.1)],
]

var _lv: Node
var _f := 0
var _out := "user://lighthouse_shots"
var _cam: Camera3D
var _centre := Vector3.ZERO
var _shot := 0
var _extra := []


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			_out = a.substr(6)
		elif a.begins_with("--shot="):   # --shot=name,cx,cy,cz,lx,ly,lz (world camera and look-at points)
			var v := a.substr(7).split(",")
			_extra.append([v[0], Vector3(float(v[1]), float(v[2]), float(v[3])), Vector3(float(v[4]), float(v[5]), float(v[6]))])
	DirAccess.make_dir_recursive_absolute(_out)
	_lv = load("res://scenes/Level.tscn").instantiate()
	root.add_child(_lv)


func _process(_d: float) -> bool:
	_f += 1
	if _f == 5:
		_measure()
		_cam = Camera3D.new()
		_cam.fov = 55
		_lv.add_child(_cam)
		_cam.make_current()
		var p := _lv.get_node_or_null("Player")
		if p:
			p.process_mode = Node.PROCESS_MODE_DISABLED
	if _f >= 20 and _f % 10 == 0:
		var shots: Array = _extra if not _extra.is_empty() else SHOTS
		if _shot > 0:
			var img := root.get_viewport().get_texture().get_image()
			img.save_png("%s/%s.png" % [_out, shots[_shot - 1][0]])
		if _shot >= shots.size():
			print("shots saved to ", ProjectSettings.globalize_path(_out))
			quit()
			return true
		if _extra.is_empty():
			var off: Vector3 = shots[_shot][1]
			_cam.global_position = _centre + off
			_cam.look_at(_centre + Vector3(0, 8 if off.y < 40 else 0, 0), Vector3.UP if off.y < 40 else Vector3.FORWARD)
		else:
			_cam.global_position = shots[_shot][1]
			_cam.look_at(shots[_shot][2], Vector3.UP)
		_shot += 1
	return false


# Every triangle of every mesh under `node`, in world space, appended to `out`.
func _world_tris(node: Node, out: PackedVector3Array) -> void:
	for n in node.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if mi.mesh == null:
			continue
		var xf := mi.global_transform
		for s in mi.mesh.get_surface_count():
			var arr := mi.mesh.surface_get_arrays(s)
			var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
			if idx.is_empty():
				idx = PackedInt32Array(range(v.size()))
			for i in idx.size():
				out.append(xf * v[idx[i]])


# Rasterises triangles onto the 0.5 m grid inside [lo, hi] (XZ): per cell keeps the lowest (lo_map)
# and highest (hi_map) surface height of any triangle covering the cell centre.
func _raster(t: PackedVector3Array, lo: Vector2, hi: Vector2, lo_map: Dictionary, hi_map: Dictionary) -> void:
	for i in range(0, t.size(), 3):
		var a := t[i]
		var b := t[i + 1]
		var c := t[i + 2]
		var mnx := minf(a.x, minf(b.x, c.x))
		var mxx := maxf(a.x, maxf(b.x, c.x))
		var mnz := minf(a.z, minf(b.z, c.z))
		var mxz := maxf(a.z, maxf(b.z, c.z))
		if mxx < lo.x or mnx > hi.x or mxz < lo.y or mnz > hi.y:
			continue
		var den := (b.z - c.z) * (a.x - c.x) + (c.x - b.x) * (a.z - c.z)
		if absf(den) < 1e-9:
			continue
		for gx in range(ceili(mnx / CELL - 0.5), floori(mxx / CELL - 0.5) + 1):
			var x := (gx + 0.5) * CELL
			for gz in range(ceili(mnz / CELL - 0.5), floori(mxz / CELL - 0.5) + 1):
				var z := (gz + 0.5) * CELL
				var w1 := ((b.z - c.z) * (x - c.x) + (c.x - b.x) * (z - c.z)) / den
				var w2 := ((c.z - a.z) * (x - c.x) + (a.x - c.x) * (z - c.z)) / den
				var w3 := 1.0 - w1 - w2
				if w1 < -1e-4 or w2 < -1e-4 or w3 < -1e-4:
					continue
				var y := w1 * a.y + w2 * b.y + w3 * c.y
				var k := Vector2i(gx, gz)
				lo_map[k] = minf(lo_map.get(k, INF), y)
				hi_map[k] = maxf(hi_map.get(k, -INF), y)


func _measure() -> void:
	var lh: Node3D = _lv.get_node("Lighthouse")
	var isl: Node3D = _lv.get_node("Island")
	var lt := PackedVector3Array()
	_world_tris(lh, lt)
	var it := PackedVector3Array()
	_world_tris(isl, it)
	var lo := Vector3(INF, INF, INF)
	var hi := -lo
	for p in lt:
		lo = lo.min(p)
		hi = hi.max(p)
	_centre = Vector3((lo.x + hi.x) * 0.5, lo.y, (lo.z + hi.z) * 0.5)
	print("lighthouse node at ", lh.global_position, "  mesh AABB ", lo, " .. ", hi,
		"  size ", hi - lo, "  tris ", lt.size() / 3, "   island tris ", it.size() / 3)
	var r0 := Vector2(lo.x - 4, lo.z - 4)
	var r1 := Vector2(hi.x + 4, hi.z + 4)
	var l_under := {}
	var l_top := {}
	_raster(lt, r0, r1, l_under, l_top)
	var i_lo := {}
	var i_top := {}
	_raster(it, r0, r1, i_lo, i_top)

	# Map: one character per 0.5 m cell, north (-Z) at the top, +X to the right.
	#   .  island only   #  lighthouse sits on the island (within 0.3 m)
	#   1-9  island rock rises that many metres (rounded up) inside the lighthouse
	#   f  lighthouse 0.3-1.5 m above the island   F  more than 1.5 m above   o  no island under it
	var poke := 0
	var worst := 0.0
	var floating := 0
	print("map x %.1f..%.1f (left->right), z %.1f..%.1f (top->bottom)" % [r0.x, r1.x, r0.y, r1.y])
	for gz in range(floori(r0.y / CELL), floori(r1.y / CELL) + 1):
		var row := ""
		for gx in range(floori(r0.x / CELL), floori(r1.x / CELL) + 1):
			var k := Vector2i(gx, gz)
			var has_l := l_under.has(k)
			var has_i := i_top.has(k)
			if not has_l:
				row += "." if has_i else " "
			elif not has_i:
				row += "o"
				floating += 1
			else:
				var d: float = i_top[k] - l_under[k]
				if d > 0.3:
					row += str(mini(9, ceili(d)))
					poke += 1
					worst = maxf(worst, d)
				elif d < -1.5:
					row += "F"
					floating += 1
				elif d < -0.3:
					row += "f"
					floating += 1
				else:
					row += "#"
		print(row)
	print("cells with island rock inside the lighthouse: %d (worst %.2f m)   floating cells: %d" % [poke, worst, floating])
	if "--search" in OS.get_cmdline_user_args():
		_search(lt, lo, hi, l_under, it)


# Tries moving the lighthouse up to 10 m in X/Z (0.5 m steps). For each offset the height is set so the
# base sinks SINK m into the median ground, then counts cells where rock rises more than 0.8 m above the
# base (cutting in) and cells where the base hangs more than 0.4 m above the ground (floating).
func _search(lt: PackedVector3Array, lo: Vector3, hi: Vector3, l_under: Dictionary, it: PackedVector3Array) -> void:
	const SINK := 0.35
	const R := 20
	var i_lo := {}
	var i_top := {}
	_raster(it, Vector2(lo.x - R * CELL - 1, lo.z - R * CELL - 1), Vector2(hi.x + R * CELL + 1, hi.z + R * CELL + 1), i_lo, i_top)
	var res := []
	for dx in range(-R, R + 1):
		for dz in range(-R, R + 1):
			var ds := []
			var missing := 0
			for k in l_under:
				var k2 := Vector2i(k.x + dx, k.y + dz)
				if not i_top.has(k2):
					missing += 1
					continue
				ds.append(i_top[k2] - l_under[k])
			if ds.size() < l_under.size() * 0.9:
				continue
			ds.sort()
			var raise: float = ds[ds.size() / 2] - SINK
			var cut := 0
			var cut_sum := 0.0
			var flo := missing
			for d in ds:
				var e: float = d - raise
				if e > 0.8:
					cut += 1
					cut_sum += e - 0.8
				elif e < -0.4:
					flo += 1
			res.append([cut_sum + flo * 0.5, dx * CELL, dz * CELL, raise, cut, cut_sum, flo, ds[-1] - raise])
	res.sort_custom(func(a, b): return a[0] < b[0])
	print("best offsets (dx, dz, raise y, cells cut >0.8 m, cut volume, floating cells, worst cut):")
	for r in res.slice(0, 15):
		print("  dx=%5.1f dz=%5.1f raise=%5.2f  cut=%4d (%.1f)  float=%4d  worst=%.2f" % [r[1], r[2], r[3], r[4], r[5], r[6], r[7]])
	for r in res:
		if r[1] == 0.0 and r[2] == 0.0:
			print("  current:  raise=%5.2f  cut=%4d (%.1f)  float=%4d  worst=%.2f" % [r[3], r[4], r[5], r[6], r[7]])
