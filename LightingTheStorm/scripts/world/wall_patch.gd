# wall_patch.gd - closes the holes in the lighthouse's exterior wall with COPIES OF THE WALL ITSELF (creator, 2026-10-26).
# The generated exterior mesh (Lighthouse/convert) has ragged holes where the interior's carves cut through it, and the stone patches that were put over them
# (exterior_openings.gd) read as flat brown plates. This finds each missing stretch of wall by casting rays at it from outside, then builds new wall over it from
# the nearest INTACT stretch of the same wall at the same height: the donor's outer surface (its real relief) and its texture coordinates, moved sideways round the
# tower (rotated about the axis) or along the house wall. The copy is a thin outer skin 1.5 cm inside the real surface, so it never covers wall that exists, never
# reaches the interior, and takes the wall's own material, so the baked stone, the masonry shader and the cel look all carry over.
# Real openings (the windows in data/world/lighthouse_windows.json, the hall and first-floor doorways into the tower, the front door) are left open.
# The search is slow (tens of thousands of rays), so it runs OFFLINE: tools/bake_wall_patch.gd calls build_and_save() and writes res://Assets/Models/lighthouse/wall_patch.res
# plus wall_patch.json (which surface of which exterior mesh each patch copies its material from). At run time this node only loads that mesh and adds it to the
# exterior, so it is made before LighthouseWallDetail runs and the masonry shader and the cel look treat the copy like the rest of the wall.
extends Node3D

const WINDOWS_JSON := "res://data/world/lighthouse_windows.json"
const TOWER := Vector2(3.5, 3.6)
const THETA_STEP := 1.875                # degrees between rays on the tower
const Y_STEP := 0.125
const TOWER_Y0 := 4.0                    # below this the tower stands in the rock: its base is hidden by the island, not a hole
const TOWER_Y1 := 17.6
const G_DOOR := Vector2(127.5, 165.0)    # bearings of the hall's and the first floor's doorways into the tower (tower_shell.gd)
const HOUSE_SIDE := Vector2(139.0, 165.0)
const MIN_WALL := 0.3                    # a ray hitting this far outside the inner radius has hit the wall's outer skin; nearer than that it hit something inside
const SKIN_INSET := 0.015
const MIN_HOUSE_NODES := 160           # nodes are 0.1 x 0.125 m: 160 is 2 square metres
const OPEN_MARGIN := 0.12                # a window's opening is kept clear this far beyond its edges

@export var lighthouse_path := NodePath("../Lighthouse")
@export var enabled := true

var built := false
var patched_cells := 0
var holes_found := 0                       # hole cells found (nodes of the lattice) before patching
var holes_left := 0                        # hole cells with no donor
var regions: Array = []                    # [{kind, theta0, theta1, y0, y1, donor_shift, cells}] for the test
var _tris: Array = []                      # [a, b, c, uva, uvb, uvc, surface_index, mesh_instance] in the Lighthouse frame
var _bins := {}                            # Vector2i(theta bin, y bin) -> PackedInt32Array of triangle indices
var _lh: Node3D
var _mesh_mat: Dictionary = {}             # MeshInstance3D -> its surface materials


func _ready() -> void:
	if enabled and OS.get_environment("LHF_NO_WALL_PATCH") != "1":
		_load_baked()


static func inner_radius(y: float) -> float:
	return 3.0 if y < 4.92 else maxf(2.9, 3.4 - 0.0385 * (y - 4.92))


const MESH_PATH := "res://Assets/Models/lighthouse/wall_patch.res"
const MAP_PATH := "res://Assets/Models/lighthouse/wall_patch.json"
var _out: Array = []                       # [{mesh: ArrayMesh, src: String (exterior mesh instance name), surf: int}]


## Run time: add the baked copies of wall to the exterior.
func _load_baked() -> void:
	_lh = get_node_or_null(lighthouse_path) as Node3D
	if _lh == null or _lh.get_node_or_null("convert") == null or not ResourceLoader.exists(MESH_PATH):
		return
	var mesh := load(MESH_PATH) as ArrayMesh
	var f := FileAccess.open(MAP_PATH, FileAccess.READ)
	if mesh == null or f == null:
		return
	var map: Array = JSON.parse_string(f.get_as_text())
	var srcs := {}
	for mi in _lh.get_node("convert").find_children("*", "MeshInstance3D", true, false):
		srcs[String(mi.name)] = mi
	for s in mesh.get_surface_count():
		var src = srcs.get(map[s]["src"])
		if src == null:
			continue
		var m := ArrayMesh.new()
		m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh.surface_get_arrays(s))
		var mi := MeshInstance3D.new()
		mi.name = "WallPatch_%d" % s
		mi.mesh = m
		var mat: Material = (src as MeshInstance3D).mesh.surface_get_material(int(map[s]["surf"]))
		if mat != null:
			mi.set_surface_override_material(0, mat)
		_lh.get_node("convert").add_child(mi)
		mi.global_transform = _lh.global_transform
		patched_cells += int(map[s].get("cells", 0))
	built = true


## Offline (tools/bake_wall_patch.gd): find the holes and save their patches.
func build_and_save(lh: Node3D, space: PhysicsDirectSpaceState3D = null) -> void:
	_lh = lh
	_space = space
	_build()
	var mesh := ArrayMesh.new()
	var map: Array = []
	for e in _out:
		var am: ArrayMesh = e["mesh"]
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, am.surface_get_arrays(0))
		map.append({"src": e["src"], "surf": e["surf"], "cells": e["cells"]})
	ResourceSaver.save(mesh, MESH_PATH)
	var f := FileAccess.open(MAP_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify(map))


func _build() -> void:
	if _lh == null:
		_lh = get_node_or_null(lighthouse_path) as Node3D
	if _lh == null or _lh.get_node_or_null("convert") == null:
		return
	var sf := FileAccess.open("res://data/world/shell_spec.json", FileAccess.READ)
	if sf:
		_sp = JSON.parse_string(sf.get_as_text())
	_collect()
	var windows := _windows()
	_patch_tower(windows)
	_collect_grid()
	# (the house walls: _patch_plane() can fill rectangles of the west and back walls, but the exterior's rock footing at ground level makes the wall depth there ambiguous,
	# so no house hole is filled yet: see the report)
	built = true



# ------------------------------------------------------------------------------------------------ the exterior's triangles

func _collect() -> void:
	var inv := _lh.global_transform.affine_inverse()
	for mi in _lh.get_node("convert").find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		if m.mesh == null:
			continue
		var xf: Transform3D = inv * m.global_transform
		for s in m.mesh.get_surface_count():
			var arr := m.mesh.surface_get_arrays(s)
			var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var uv: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV] if arr[Mesh.ARRAY_TEX_UV] != null else PackedVector2Array()
			var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array(range(v.size()))
			for t in range(0, idx.size(), 3):
				var a: Vector3 = xf * v[idx[t]]
				var b: Vector3 = xf * v[idx[t + 1]]
				var c: Vector3 = xf * v[idx[t + 2]]
				var ua := uv[idx[t]] if not uv.is_empty() else Vector2.ZERO
				var ub := uv[idx[t + 1]] if not uv.is_empty() else Vector2.ZERO
				var uc := uv[idx[t + 2]] if not uv.is_empty() else Vector2.ZERO
				var ti := _tris.size()
				_tris.append([a, b, c, ua, ub, uc, s, m])
				# bin by bearing and height; skip triangles far from the tower (the island, the house's far side)
				var cen := (a + b + c) / 3.0
				if Vector2(cen.x - TOWER.x, cen.z - TOWER.y).length() > 16.0 or cen.y > 19.0 or cen.y < 0.0:
					continue
				var lo_t := 1e9
				var hi_t := -1e9
				var th0 := _theta(a)
				for p in [a, b, c]:
					var th := th0 + wrapf(_theta(p) - th0, -180.0, 180.0)
					lo_t = minf(lo_t, th)
					hi_t = maxf(hi_t, th)
				var y_lo := minf(a.y, minf(b.y, c.y))
				var y_hi := maxf(a.y, maxf(b.y, c.y))
				for tb in range(int(floor(lo_t / 3.75)), int(floor(hi_t / 3.75)) + 1):
					for yb in range(int(floor(y_lo / 0.5)), int(floor(y_hi / 0.5)) + 1):
						var key := Vector2i(posmod(tb, 96), yb)
						var lst: PackedInt32Array = _bins.get(key, PackedInt32Array())
						lst.append(ti)
						_bins[key] = lst


func _theta(p: Vector3) -> float:
	return rad_to_deg(atan2(p.z - TOWER.y, p.x - TOWER.x))


## The first hit of a horizontal ray travelling inward to the tower axis at bearing `theta` (degrees) and height `y`: {r, tri, bary} or {} if none.
func _radial_hit(theta: float, y: float) -> Dictionary:
	var th := deg_to_rad(theta)
	var dir_out := Vector3(cos(th), 0.0, sin(th))
	var o := Vector3(TOWER.x, y, TOWER.y) + dir_out * 16.0
	var d := -dir_out
	var key := Vector2i(posmod(int(floor(theta / 3.75)), 96), int(floor(y / 0.5)))
	if not _bins.has(key):
		return {}
	var best := {}
	var best_t := INF
	for ti in _bins[key]:
		var tr: Array = _tris[ti]
		var hit: Variant = Geometry3D.ray_intersects_triangle(o, d, tr[0], tr[1], tr[2])
		if hit != null:
			var t: float = o.distance_to(hit as Vector3)
			if t < best_t:
				best_t = t
				best = {"p": hit, "tri": ti}
	if best.is_empty():
		return {}
	var p: Vector3 = best["p"]
	best["r"] = Vector2(p.x - TOWER.x, p.z - TOWER.y).length()
	return best


# ------------------------------------------------------------------------------------------------ the tower

func _windows() -> Array:
	var out: Array = []
	var f := FileAccess.open(WINDOWS_JSON, FileAccess.READ)
	if f:
		for w in (JSON.parse_string(f.get_as_text()) as Dictionary).get("windows", []):
			if w["kind"] == "tower":
				out.append(w)
	out.append({"id": "T_landing_147", "kind": "tower", "bearing": 147.0, "y": 15.09, "w": 1.0, "h": 1.8})
	return out


## True where the tower's wall at this bearing and height is inside the house (its footprint, shell_spec.json, grown by the wall thickness and up to the ridge): the
## house's own wall is what you see there, and a gap in its roof or wall is not a gap in the tower.
func _in_house(theta: float, y: float) -> bool:
	if y > 10.4:
		return false
	var sp := _sp
	if sp.is_empty():
		return false
	var o: Array = sp["house_origin"]
	var yaw: float = sp["house_yaw"]
	var th := deg_to_rad(theta)
	var r := 3.3
	var rx := TOWER.x + r * cos(th) - float(o[0])
	var rz := TOWER.y + r * sin(th) - float(o[1])
	var u := rx * cos(yaw) - rz * sin(yaw)
	var v := -(rx * sin(yaw) + rz * cos(yaw))
	var upper: bool = y >= float(sp["slab_top"])
	var uu: Array = sp["first_u"] if upper else sp["ground_u"]
	var vv: Array = sp["first_v"] if upper else sp["ground_v"]
	var t: float = sp["house_wall_t"] + 0.3
	return u > float(uu[0]) - t and u < float(uu[1]) + t and v > float(vv[0]) - t and v < float(vv[1]) + t


func _is_open(theta: float, y: float, windows: Array) -> bool:
	var t := fposmod(theta, 360.0)
	if _in_house(t, y):
		return true
	if y < 3.6 and t > G_DOOR.x and t < G_DOOR.y:
		return true
	if y > 4.8 and y < 7.7 and t > HOUSE_SIDE.x and t < HOUSE_SIDE.y:
		return true
	for w in windows:
		var r := inner_radius(float(w["y"])) + 0.45
		var half := rad_to_deg((float(w["w"]) * 0.5 + OPEN_MARGIN) / r)
		if absf(wrapf(t - float(w["bearing"]), -180.0, 180.0)) < half and absf(y - float(w["y"])) < float(w["h"]) * 0.5 + OPEN_MARGIN:
			return true
	return false


## The exterior's tower is a thin shell: its outer radius at height y is the median of the hits (2.6 to 5.6 m from the axis) all round. Wall = a hit within 0.9 m
## inside that or anywhere outside it (the house's walls at the bearings the house covers); hole = no hit, or a hit well inside (the stairs, the lining).
var _r_med := {}
var _sp: Dictionary = {}


func _is_wall(h: Dictionary, y: float) -> bool:
	if h.is_empty():
		return false
	var rm: float = _r_med.get(snappedf(y, Y_STEP), 3.2)
	return float(h["r"]) >= rm - 0.9


func _patch_tower(windows: Array) -> void:
	var n_t := int(360.0 / THETA_STEP)
	var n_y := int(round((TOWER_Y1 - TOWER_Y0) / Y_STEP)) + 1
	# the median outer radius of every row
	for j in n_y:
		var y0 := TOWER_Y0 + j * Y_STEP
		var rs: Array = []
		for i in range(0, n_t, 2):
			var hh := _radial_hit(THETA_STEP * i, y0)
			if not hh.is_empty() and float(hh["r"]) > 2.6 and float(hh["r"]) < 5.6:
				rs.append(float(hh["r"]))
		rs.sort()
		_r_med[snappedf(y0, Y_STEP)] = rs[rs.size() / 2] if not rs.is_empty() else 3.2
	# classify every lattice node: 0 wall, 1 hole, 2 legitimately open
	var cls := PackedByteArray()
	cls.resize(n_t * n_y)
	var hits: Array = []
	hits.resize(n_t * n_y)
	for j in n_y:
		var y := TOWER_Y0 + j * Y_STEP
		for i in n_t:
			var th := THETA_STEP * i
			var h := _radial_hit(th, y)
			hits[j * n_t + i] = h
			if _is_open(th, y, windows):
				cls[j * n_t + i] = 2
			elif _is_wall(h, y):
				cls[j * n_t + i] = 0
			else:
				cls[j * n_t + i] = 1
	# hole nodes grouped into connected regions
	var seen := PackedByteArray()
	seen.resize(n_t * n_y)
	var surf_pts := {}          # material surface key -> arrays
	for j0 in n_y:
		for i0 in n_t:
			if cls[j0 * n_t + i0] != 1 or seen[j0 * n_t + i0] == 1:
				continue
			var comp: Array = []
			var stack: Array = [Vector2i(i0, j0)]
			seen[j0 * n_t + i0] = 1
			while not stack.is_empty():
				var c: Vector2i = stack.pop_back()
				comp.append(c)
				for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 1), Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1)]:
					var ni: int = posmod(c.x + d.x, n_t)
					var nj: int = c.y + d.y
					if nj < 0 or nj >= n_y:
						continue
					if cls[nj * n_t + ni] == 1 and seen[nj * n_t + ni] == 0:
						seen[nj * n_t + ni] = 1
						stack.append(Vector2i(ni, nj))
			holes_found += comp.size()
			if comp.size() < 2:
				continue            # a stray node: a crack in the mesh, not a hole
			_fill_component(comp, cls, hits, n_t, n_y)
	print("wall_patch: %d hole nodes, %d cells patched, %d without a donor" % [holes_found, patched_cells, holes_left])


func _fill_component(comp: Array, cls: PackedByteArray, hits: Array, n_t: int, n_y: int) -> void:
	var lo_i := 1 << 30
	var hi_i := -(1 << 30)
	var lo_j := 1 << 30
	var hi_j := -(1 << 30)
	# the component may wrap the 0/360 seam: unwrap relative to its first node
	var base_i: int = (comp[0] as Vector2i).x
	for c in comp:
		var ii: int = base_i + (posmod((c as Vector2i).x - base_i + n_t / 2, n_t) - n_t / 2)
		lo_i = mini(lo_i, ii)
		hi_i = maxi(hi_i, ii)
		lo_j = mini(lo_j, (c as Vector2i).y)
		hi_j = maxi(hi_j, (c as Vector2i).y)
	var width := hi_i - lo_i + 1
	# the donor: the nearest sideways shift (in lattice steps) at which every node of the component's rows has intact wall; try both directions outward
	var shift := 0
	var found := false
	var gap := 4
	for k in range(1, n_t / 2):
		for sgn in [1, -1]:
			var s: int = sgn * (width + gap + k - 1)
			var ok := true
			for c in comp:
				var di := posmod((c as Vector2i).x + s, n_t)
				var node := (c as Vector2i).y * n_t + di
				if cls[node] != 0:
					ok = false
					break
			if ok:
				shift = s
				found = true
				break
		if found:
			break
	var info := {"kind": "tower", "theta0": THETA_STEP * lo_i, "theta1": THETA_STEP * hi_i, "y0": TOWER_Y0 + lo_j * Y_STEP, "y1": TOWER_Y0 + hi_j * Y_STEP, "shift": shift * THETA_STEP, "nodes": comp.size()}
	if not found:
		holes_left += comp.size()
		info["donor"] = false
		regions.append(info)
		return
	info["donor"] = true
	regions.append(info)
	# the cells of the lattice that touch a hole node of this component (a cell is patched if any of its four corners is a hole node)
	var cell_set := {}
	for c in comp:
		for d in [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(0, -1), Vector2i(-1, -1)]:
			var ci: int = posmod((c as Vector2i).x + d.x, n_t)
			var cj: int = (c as Vector2i).y + d.y
			if cj < 0 or cj >= n_y - 1:
				continue
			cell_set[Vector2i(ci, cj)] = true
	var per_surface := {}       # key (mesh instance id, surface) -> {st, mat, cells}
	var rot := deg_to_rad(shift * THETA_STEP)       # donor bearing = hole bearing + shift: rotate donor points back by -shift
	for cell in cell_set:
		var corners: Array = []
		var ok := true
		for d in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1)]:
			var ni: int = posmod((cell as Vector2i).x + d.x, n_t)
			var nj: int = (cell as Vector2i).y + d.y
			var di := posmod(ni + shift, n_t)
			var dh: Dictionary = hits[nj * n_t + di]
			if dh.is_empty():
				ok = false
				break
			var tr: Array = _tris[dh["tri"]]
			var p: Vector3 = dh["p"]
			# barycentric uv at the donor's hit
			var a: Vector3 = tr[0]
			var b: Vector3 = tr[1]
			var cc: Vector3 = tr[2]
			var v0 := b - a
			var v1 := cc - a
			var v2 := p - a
			var d00 := v0.dot(v0)
			var d01 := v0.dot(v1)
			var d11 := v1.dot(v1)
			var d20 := v2.dot(v0)
			var d21 := v2.dot(v1)
			var den := d00 * d11 - d01 * d01
			var bv := (d11 * d20 - d01 * d21) / den if absf(den) > 1e-12 else 0.0
			var bw := (d00 * d21 - d01 * d20) / den if absf(den) > 1e-12 else 0.0
			var uv: Vector2 = (tr[3] as Vector2) * (1.0 - bv - bw) + (tr[4] as Vector2) * bv + (tr[5] as Vector2) * bw
			# move the donor point to the hole's bearing and 1.5 cm inside
			var rr := Vector2(p.x - TOWER.x, p.z - TOWER.y)
			var rad := maxf(rr.length() - SKIN_INSET, 0.1)
			var th := deg_to_rad(THETA_STEP * float(ni))
			var pos := Vector3(TOWER.x + cos(th) * rad, p.y, TOWER.y + sin(th) * rad)
			corners.append({"pos": pos, "uv": uv, "tri": dh["tri"], "n": Vector3(cos(th), 0, sin(th))})
		if not ok:
			continue
		var key: String = str((_tris[corners[0]["tri"]] as Array)[7].get_instance_id()) + ":" + str((_tris[corners[0]["tri"]] as Array)[6])
		if not per_surface.has(key):
			var st := SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			per_surface[key] = {"st": st, "mi": (_tris[corners[0]["tri"]] as Array)[7], "surf": (_tris[corners[0]["tri"]] as Array)[6], "cells": 0}
		var st2: SurfaceTool = per_surface[key]["st"]
		for tri_idx in [[0, 1, 2], [0, 2, 3]]:
			for q in tri_idx:
				st2.set_normal(corners[q]["n"])
				st2.set_uv(corners[q]["uv"])
				st2.add_vertex(corners[q]["pos"])
		patched_cells += 1
		per_surface[key]["cells"] += 1
	for key in per_surface:
		var entry: Dictionary = per_surface[key]
		_out.append({"mesh": (entry["st"] as SurfaceTool).commit(), "src": String((entry["mi"] as MeshInstance3D).name), "surf": int(entry["surf"]), "cells": entry["cells"]})


# ------------------------------------------------------------------------------------------------ the house walls (planes in the house frame)

var _space: PhysicsDirectSpaceState3D
var _grid := {}                    # Vector3i cell (0.5 m) -> PackedInt32Array of triangle indices, for the triangles round the house


## True when a ray from outside reaches the INTERIOR (the code-built rooms or the greybox) before the exterior wall: you can see into the building there, so the wall is missing.
func _sees_interior(from: Vector3, to: Vector3) -> bool:
	var ex: Array[RID] = []
	var q := PhysicsRayQueryParameters3D.create(_lh.to_global(from), _lh.to_global(to))
	for _i in 8:
		var r := _space.intersect_ray(q)
		if r.is_empty():
			return false
		var path := String((r["collider"] as Node).get_path())
		if "/InteriorRooms/" in path or "/LighthouseInterior/" in path:
			# the tiny interior pieces that are meant to be seen from outside (window glass, the barrier panes, the door) do not count
			if "_Glass" in path or "_Barrier" in path or "LighthouseDoor" in path or "_Mullion" in path:
				return false
			return true
		if "/convert" in path or "WallPatch" in path or "Island" in path or "Rock" in path:
			return false
		q.exclude = q.exclude + [r["rid"]]
	return false


func _house_xf(u: float, y: float, v: float) -> Vector3:
	var o: Array = _sp["house_origin"]
	var yaw: float = _sp["house_yaw"]
	return Vector3(float(o[0]) + u * cos(yaw) + (-v) * sin(yaw), y, float(o[1]) + u * (-sin(yaw)) + (-v) * cos(yaw))


func _collect_grid() -> void:
	for ti in _tris.size():
		var tr: Array = _tris[ti]
		var a: Vector3 = tr[0]
		var b: Vector3 = tr[1]
		var c: Vector3 = tr[2]
		var lo := a.min(b).min(c)
		var hi := a.max(b).max(c)
		if hi.x < -14.0 or lo.x > 6.0 or hi.z < -2.0 or lo.z > 13.0 or hi.y < 0.0 or lo.y > 10.5:
			continue
		for x in range(int(floor(lo.x * 2.0)), int(floor(hi.x * 2.0)) + 1):
			for y in range(int(floor(lo.y * 2.0)), int(floor(hi.y * 2.0)) + 1):
				for z in range(int(floor(lo.z * 2.0)), int(floor(hi.z * 2.0)) + 1):
					var key := Vector3i(x, y, z)
					var lst: PackedInt32Array = _grid.get(key, PackedInt32Array())
					lst.append(ti)
					_grid[key] = lst


## First hit of a ray (origin, unit direction, up to `length`) against the exterior triangles: {p, tri} or {}.
func _grid_hit(o: Vector3, d: Vector3, length: float) -> Dictionary:
	var best := {}
	var best_t := INF
	var seen := {}
	var t := 0.0
	while t <= length:
		var p := o + d * t
		var key := Vector3i(int(floor(p.x * 2.0)), int(floor(p.y * 2.0)), int(floor(p.z * 2.0)))
		if _grid.has(key):
			for ti in _grid[key]:
				if seen.has(ti):
					continue
				seen[ti] = true
				var tr: Array = _tris[ti]
				var hit: Variant = Geometry3D.ray_intersects_triangle(o, d, tr[0], tr[1], tr[2])
				if hit != null:
					var tt := o.distance_to(hit as Vector3)
					if tt < best_t:
						best_t = tt
						best = {"p": hit, "tri": ti}
			if not best.is_empty() and best_t <= t:
				break
		t += 0.2
	return best


func _bary_uv(tri: int, p: Vector3) -> Vector2:
	var tr: Array = _tris[tri]
	var a: Vector3 = tr[0]
	var v0: Vector3 = (tr[1] as Vector3) - a
	var v1: Vector3 = (tr[2] as Vector3) - a
	var v2 := p - a
	var d00 := v0.dot(v0)
	var d01 := v0.dot(v1)
	var d11 := v1.dot(v1)
	var d20 := v2.dot(v0)
	var d21 := v2.dot(v1)
	var den := d00 * d11 - d01 * d01
	var bv := (d11 * d20 - d01 * d21) / den if absf(den) > 1e-12 else 0.0
	var bw := (d00 * d21 - d01 * d20) / den if absf(den) > 1e-12 else 0.0
	return (tr[3] as Vector2) * (1.0 - bv - bw) + (tr[4] as Vector2) * bv + (tr[5] as Vector2) * bw


func _to_house(p: Vector3) -> Vector2:
	var o: Array = _sp["house_origin"]
	var yaw: float = _sp["house_yaw"]
	var rx := p.x - float(o[0])
	var rz := p.z - float(o[1])
	return Vector2(rx * cos(yaw) - rz * sin(yaw), -(rx * sin(yaw) + rz * cos(yaw)))


## One wall of the house: `kind` "west" (outward -u, runs along v) or "back" (outward +v, runs along u); s_range along the wall, y_range, `openings` the real
## windows ({at, y, w, h}, along-wall position) that stay open. Same method as the tower: rays from outside, hole = no hit or a hit well inside the wall's usual
## outer face; the copy comes from the nearest stretch of the same wall at the same height, moved along the wall.
func _patch_plane(kind: String, s_range: Vector2, y_range: Vector2, openings: Array, rects: Array = []) -> void:
	var step_s := 0.1
	var n_s := int(round((s_range.y - s_range.x) / step_s)) + 1
	var n_y := int(round((y_range.y - y_range.x) / Y_STEP)) + 1
	var west := kind == "west"
	var front := kind == "front"
	var cls := PackedByteArray()
	cls.resize(n_s * n_y)
	var hits: Array = []
	hits.resize(n_s * n_y)
	var outs: Array = []
	outs.resize(n_s * n_y)
	var row_med := []
	var start_of: Array = []
	var end_of: Array = []
	start_of.resize(n_s * n_y)
	end_of.resize(n_s * n_y)
	for j in n_y:
		var y := y_range.x + j * Y_STEP
		var vals: Array = []
		for i in n_s:
			var s := s_range.x + i * step_s
			var start := _house_xf(-9.0 if west else s, y, s if west else (15.0 if kind == "back" else -9.0))
			var tgt := _house_xf(0.0 if west else s, y, s if west else 0.0)
			start_of[j * n_s + i] = start
			end_of[j * n_s + i] = tgt
			var h := _grid_hit(start, (tgt - start).normalized(), 24.0)
			hits[j * n_s + i] = h
			var outv := -999.0
			if not h.is_empty():
				var uv := _to_house(h["p"])
				outv = -uv.x if west else (-uv.y if front else uv.y)
				vals.append(outv)
			outs[j * n_s + i] = outv
		vals.sort()
		row_med.append(vals[vals.size() / 2] if not vals.is_empty() else 0.0)
	for j in n_y:
		var y := y_range.x + j * Y_STEP
		for i in n_s:
			var s := s_range.x + i * step_s
			var open := false
			for w in openings:
				if absf(s - float(w["at"])) < float(w["w"]) * 0.5 + OPEN_MARGIN and absf(y - float(w["y"])) < float(w["h"]) * 0.5 + OPEN_MARGIN:
					open = true
			if open:
				cls[j * n_s + i] = 2
			elif not rects.is_empty():
				# explicit hole rectangles (found from the exterior mesh's open edges): everything in a rectangle is hole, intact wall is a possible donor, the rest is neutral
				var in_rect := false
				for rc in rects:
					if (rc as Rect2).has_point(Vector2(s, y)):
						in_rect = true
				if in_rect:
					cls[j * n_s + i] = 1
				elif not (hits[j * n_s + i] as Dictionary).is_empty() and float(outs[j * n_s + i]) >= float(row_med[j]) - 0.9:
					cls[j * n_s + i] = 0
				else:
					cls[j * n_s + i] = 3
			elif _space != null and _sees_interior(start_of[j * n_s + i], end_of[j * n_s + i]) and not (hits[j * n_s + i] as Dictionary).is_empty():
				cls[j * n_s + i] = 1
			else:
				cls[j * n_s + i] = 0
	var seen := PackedByteArray()
	seen.resize(n_s * n_y)
	var found_total := 0
	for j0 in n_y:
		for i0 in n_s:
			if cls[j0 * n_s + i0] != 1 or seen[j0 * n_s + i0] == 1:
				continue
			var comp: Array = []
			var stack: Array = [Vector2i(i0, j0)]
			seen[j0 * n_s + i0] = 1
			while not stack.is_empty():
				var c: Vector2i = stack.pop_back()
				comp.append(c)
				for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 1), Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1)]:
					var ni: int = c.x + d.x
					var nj: int = c.y + d.y
					if ni < 0 or ni >= n_s or nj < 0 or nj >= n_y:
						continue
					if cls[nj * n_s + ni] == 1 and seen[nj * n_s + ni] == 0:
						seen[nj * n_s + ni] = 1
						stack.append(Vector2i(ni, nj))
			holes_found += comp.size()
			found_total += comp.size()
			if comp.size() >= 30:
				var clo := Vector2i(1 << 30, 1 << 30)
				var chi := Vector2i(-(1 << 30), -(1 << 30))
				for cc in comp:
					clo = Vector2i(mini(clo.x, (cc as Vector2i).x), mini(clo.y, (cc as Vector2i).y))
					chi = Vector2i(maxi(chi.x, (cc as Vector2i).x), maxi(chi.y, (cc as Vector2i).y))
				print("   %s component %d nodes: s %.1f..%.1f y %.2f..%.2f" % [kind, comp.size(), s_range.x + clo.x * step_s, s_range.x + chi.x * step_s, y_range.x + clo.y * Y_STEP, y_range.x + chi.y * Y_STEP])
			if comp.size() < (20 if not rects.is_empty() else MIN_HOUSE_NODES):
				continue      # smaller than a window (about 2 square metres): a real opening, not a hole
			_fill_plane_component(kind, comp, cls, hits, outs, n_s, n_y, s_range, y_range, step_s)
	print("wall_patch: house %s wall: %d hole nodes" % [kind, found_total])


func _fill_plane_component(kind: String, comp: Array, cls: PackedByteArray, hits: Array, outs: Array, n_s: int, n_y: int, s_range: Vector2, y_range: Vector2, step_s: float) -> void:
	var lo_i := 1 << 30
	var hi_i := -(1 << 30)
	var lo_j := 1 << 30
	var hi_j := -(1 << 30)
	for c in comp:
		lo_i = mini(lo_i, (c as Vector2i).x)
		hi_i = maxi(hi_i, (c as Vector2i).x)
		lo_j = mini(lo_j, (c as Vector2i).y)
		hi_j = maxi(hi_j, (c as Vector2i).y)
	var width := hi_i - lo_i + 1
	var shift := 0
	var found := false
	for k in range(1, n_s):
		for sgn in [1, -1]:
			var sh: int = sgn * (width + 3 + k - 1)
			var bad := 0
			for c in comp:
				var di: int = (c as Vector2i).x + sh
				if di < 0 or di >= n_s or cls[(c as Vector2i).y * n_s + di] != 0 or (hits[(c as Vector2i).y * n_s + di] as Dictionary).is_empty():
					bad += 1
			if bad <= int(comp.size() * 0.08):
				shift = sh
				found = true
				break
		if found:
			break
	var info := {"kind": "house_" + kind, "s0": s_range.x + lo_i * step_s, "s1": s_range.x + hi_i * step_s, "y0": y_range.x + lo_j * Y_STEP, "y1": y_range.x + hi_j * Y_STEP, "shift": shift * step_s, "nodes": comp.size(), "donor": found}
	regions.append(info)
	if not found:
		holes_left += comp.size()
		return
	var west := kind == "west"
	var inward: Vector3 = (_house_xf(1, 0, 0) - _house_xf(0, 0, 0)) if west else ((_house_xf(0, 0, 1) - _house_xf(0, 0, 0)) if kind == "front" else (_house_xf(0, 0, -1) - _house_xf(0, 0, 0)))
	var along: Vector3 = (_house_xf(0, 0, 1) - _house_xf(0, 0, 0)) if west else (_house_xf(1, 0, 0) - _house_xf(0, 0, 0))
	var cell_set := {}
	for c in comp:
		for d in [Vector2i(0, 0), Vector2i(-1, 0), Vector2i(0, -1), Vector2i(-1, -1)]:
			var ci: int = (c as Vector2i).x + d.x
			var cj: int = (c as Vector2i).y + d.y
			if ci < 0 or ci >= n_s - 1 or cj < 0 or cj >= n_y - 1:
				continue
			cell_set[Vector2i(ci, cj)] = true
	# depth: the copy sits at the depth of the wall round the hole (the nearest intact node to the left and right in each row, blended), plus the donor's own relief
	var row_l := {}
	var row_r := {}
	for j in range(lo_j, hi_j + 1):
		var li := lo_i - 1
		while li >= 0 and cls[j * n_s + li] != 0:
			li -= 1
		var ri := hi_i + 1
		while ri < n_s and cls[j * n_s + ri] != 0:
			ri += 1
		row_l[j] = float(outs[j * n_s + li]) if li >= 0 else NAN
		row_r[j] = float(outs[j * n_s + ri]) if ri < n_s else NAN
	var per_surface := {}
	for cell in cell_set:
		var corners: Array = []
		var ok := true
		for d in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1)]:
			var ni: int = (cell as Vector2i).x + d.x
			var nj: int = (cell as Vector2i).y + d.y
			var di := ni + shift
			if di < 0 or di >= n_s:
				ok = false
				break
			var dh: Dictionary = hits[nj * n_s + di]
			if dh.is_empty():
				ok = false
				break
			var p: Vector3 = dh["p"]
			var jj := clampi(nj, lo_j, hi_j)
			var tl: float = row_l.get(jj, NAN)
			var tr_: float = row_r.get(jj, NAN)
			var t_frac := clampf(float(ni - lo_i) / maxf(float(hi_i - lo_i), 1.0), 0.0, 1.0)
			var target := (tl * (1.0 - t_frac) + tr_ * t_frac) if (not is_nan(tl) and not is_nan(tr_)) else (tl if not is_nan(tl) else (tr_ if not is_nan(tr_) else float(outs[nj * n_s + di])))
			var donor_out: float = float(outs[nj * n_s + di])
			# the donor's relief about its own row mean across the donor span
			var mean := 0.0
			var cnt := 0
			for q in range(lo_i + shift, hi_i + shift + 1):
				if q >= 0 and q < n_s and cls[jj * n_s + q] == 0:
					mean += float(outs[jj * n_s + q])
					cnt += 1
			var relief := donor_out - (mean / cnt if cnt > 0 else donor_out)
			# move along the inward direction by (donor depth - wanted depth)
			var pos := p - along * (shift * step_s) + inward * (donor_out - (target + relief) + SKIN_INSET)
			corners.append({"pos": pos, "uv": _bary_uv(dh["tri"], p), "tri": dh["tri"], "n": -inward})
		if not ok:
			continue
		var tr0: Array = _tris[corners[0]["tri"]]
		var key: String = str((tr0[7] as Object).get_instance_id()) + ":" + str(tr0[6])
		if not per_surface.has(key):
			var st := SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			per_surface[key] = {"st": st, "mi": tr0[7], "surf": tr0[6], "cells": 0}
		var st2: SurfaceTool = per_surface[key]["st"]
		for tri_idx in [[0, 1, 2], [0, 2, 3]]:
			for q in tri_idx:
				st2.set_normal(corners[q]["n"])
				st2.set_uv(corners[q]["uv"])
				st2.add_vertex(corners[q]["pos"])
		patched_cells += 1
		per_surface[key]["cells"] += 1
	for key in per_surface:
		var entry: Dictionary = per_surface[key]
		_out.append({"mesh": (entry["st"] as SurfaceTool).commit(), "src": String((entry["mi"] as MeshInstance3D).name), "surf": int(entry["surf"]), "cells": entry["cells"]})
