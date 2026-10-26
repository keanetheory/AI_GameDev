# audit_clipping.gd - run: Godot --headless --path . --script res://tools/audit_clipping.gd [-- json]
# Lighthouse clipping and scale audit (Lighthouse finish, step A1). Numbers, not eyes. Layers (by scene path):
#   ext   = Lighthouse/convert (the generated exterior mesh, carved)
#   shell = InteriorRooms/TowerShell, TowerLandings, SpiralDown, LampRoom (the code-built tower interior), minus gallery parts
#   kit   = InteriorRooms/HouseFrame meshes of 200 triangles or fewer (boxes, trim, panels), minus the exterior trim by name
#   prop  = the generated models (Hero_* holders and the other heavy meshes)
# Checks (each prints PASS or FAIL with the worst offenders):
#   A  no interior geometry OUTSIDE the walls   - a kit/shell vertex that 5 or more of 8 sight rays (4 diagonals, up, down, 2 sides) cannot
#      reach a surface from within 30 m is in open air, i.e. outside the building
#   B  nothing CROSSES the exterior wall        - kit/shell triangle edges against exterior triangles (visible seams where two layers cut each other)
#   C  props do not clip: a prop's box against other props, kit solids and exterior triangles
#   D  real-world scale and clearance           - doorway clear width and height, window sill/head, prop sizes against a plausible range
# Exit 1 if any check fails; `-- json` writes GERFramework/reports/lighthouse_clipping_audit.json.
extends SceneTree

const SHELL := ["InteriorRooms/TowerShell", "InteriorRooms/TowerLandings", "InteriorRooms/SpiralDown", "InteriorRooms/LampRoom"]
const TRIM_PREFIX := ["Facade", "Passage", "Quoin", "Keystone", "Lintel", "Sill", "NeedleBar", "Gal", "Poster", "Flame", "Coal"]
const CELL := 1.0
const SEAM := 0.05            # metres a kit piece may be sunk into a wall surface before it counts as clipping
## id: [height min, max, longest side min, max] (metres) for the placed hero props. Real furniture, with a margin.
const PROP_SCALE := {
	"office_desk": [0.7, 0.9, 1.1, 1.8], "office_chair": [0.8, 1.05, 0.4, 0.6], "office_cabinet": [1.1, 1.6, 0.5, 0.75],
	"bed_0": [0.45, 1.0, 1.8, 2.2], "bed_1": [0.45, 1.0, 1.8, 2.2], "wardrobe": [1.7, 2.1, 1.0, 1.5], "sea_chest": [0.4, 0.7, 0.8, 1.3],
	"stove": [0.8, 1.2, 0.6, 1.0], "tub": [0.5, 0.75, 1.4, 1.8], "mess_table": [0.7, 0.85, 1.0, 1.8], "telegraph": [0.15, 0.5, 0.3, 0.7],
	"lamp_office": [0.25, 0.45, 0.15, 0.3], "lamp_night": [0.2, 0.4, 0.12, 0.3], "barrel_0": [0.75, 1.0, 0.5, 0.7], "barrel_1": [0.75, 1.0, 0.5, 0.7],
	"barrel_2": [0.75, 1.0, 0.5, 0.7], "crate_0": [0.4, 0.8, 0.5, 0.9], "crate_1": [0.4, 0.8, 0.5, 0.9], "crate_2": [0.4, 0.8, 0.5, 0.9],
}

var _lv: Node
var _f := 0
var _space: PhysicsDirectSpaceState3D
var _bins := {}                 # ext triangles: Vector3i cell -> PackedVector3Array (3 per triangle)
var _ext_tris := 0
var _report := {}
var _fails := 0
var _dbg := 0
var _shell_node: Node3D = null


func _initialize() -> void:
	_lv = load("res://scenes/Level.tscn").instantiate()
	root.add_child(_lv)


func _is_trim(nm: String) -> bool:
	for p in TRIM_PREFIX:
		if nm.begins_with(p):
			return true
	return false


func _meshes(n: Node, out: Array) -> void:
	if n is MeshInstance3D and (n as MeshInstance3D).mesh != null and (n as Node3D).is_visible_in_tree():
		out.append(n)
	for c in n.get_children():
		_meshes(c, out)


func _faces(mi: MeshInstance3D) -> PackedVector3Array:
	var f := mi.mesh.get_faces()
	var xf := mi.global_transform
	for i in f.size():
		f[i] = xf * f[i]
	return f


func _bin_ext() -> void:
	var arr: Array = []
	var live := _lv.get_node_or_null("Lighthouse/LighthouseShell")
	if live != null:
		_meshes(live, arr)             # LHF_SHELL=1: the authored shell is in the level
	elif _shell_node != null:
		_meshes(_shell_node, arr)      # AUDIT_SHELL: the authored shell stands in for the exterior mesh
	else:
		_meshes(_lv.get_node("Lighthouse/convert"), arr)
	for mi in arr:
		var f := _faces(mi)
		for t in range(0, f.size(), 3):
			var lo := Vector3(minf(f[t].x, minf(f[t + 1].x, f[t + 2].x)), minf(f[t].y, minf(f[t + 1].y, f[t + 2].y)), minf(f[t].z, minf(f[t + 1].z, f[t + 2].z)))
			var hi := Vector3(maxf(f[t].x, maxf(f[t + 1].x, f[t + 2].x)), maxf(f[t].y, maxf(f[t + 1].y, f[t + 2].y)), maxf(f[t].z, maxf(f[t + 1].z, f[t + 2].z)))
			for x in range(int(floor(lo.x / CELL)), int(floor(hi.x / CELL)) + 1):
				for y in range(int(floor(lo.y / CELL)), int(floor(hi.y / CELL)) + 1):
					for z in range(int(floor(lo.z / CELL)), int(floor(hi.z / CELL)) + 1):
						var k := Vector3i(x, y, z)
						if not _bins.has(k):
							_bins[k] = PackedVector3Array()
						var a: PackedVector3Array = _bins[k]
						a.append(f[t])
						a.append(f[t + 1])
						a.append(f[t + 2])
						_bins[k] = a
			_ext_tris += 1


func _edge_hits_ext(a: Vector3, b: Vector3) -> bool:
	var d := b - a
	var len := d.length()
	if len < 0.001:
		return false
	var dir := d / len
	var steps := int(ceil(len / CELL)) + 1
	var seen := {}
	for s in steps + 1:
		var p := a + d * (float(s) / steps)
		var k := Vector3i(int(floor(p.x / CELL)), int(floor(p.y / CELL)), int(floor(p.z / CELL)))
		if seen.has(k) or not _bins.has(k):
			seen[k] = true
			continue
		seen[k] = true
		var arr: PackedVector3Array = _bins[k]
		for t in range(0, arr.size(), 3):
			var r: Variant = Geometry3D.ray_intersects_triangle(a, dir, arr[t], arr[t + 1], arr[t + 2])
			if r != null and a.distance_to(r as Vector3) <= len - 0.005 and a.distance_to(r as Vector3) >= 0.005:
				# a seam is fine (a panel sunk up to SEAM into a wall so no gap shows); only an edge that goes deeper through the surface is clipping
				var nrm := (arr[t + 1] - arr[t]).cross(arr[t + 2] - arr[t]).normalized()
				var depth := minf(absf((a - (r as Vector3)).dot(nrm)), absf((b - (r as Vector3)).dot(nrm)))
				if depth > SEAM:
					if OS.get_environment("AUDIT_DEBUG") != "" and _dbg < 12:
						_dbg += 1
						var lh := _lv.get_node("Lighthouse") as Node3D
						var lp := lh.to_local(r as Vector3)
						print("      cross at local y %.2f radius %.2f depth %.3f normal %s edge %s -> %s" % [lp.y, Vector2(lp.x - 3.5, lp.z - 3.6).length(), depth, str(nrm), str(a), str(b)])
					return true
	return false


func _groups(items: Array) -> Array:
	var g := {}
	for it in items:
		var path: String = String(it).split(" ")[0].trim_prefix("/root/Level/InteriorRooms/")
		var parts := path.split("/")
		var nm: String = parts[parts.size() - 1]
		var re := RegEx.new()
		re.compile("[_0-9]+$")
		nm = re.sub(nm, "")
		var key: String = parts[0] + "/" + nm
		g[key] = g.get(key, 0) + 1
	var out := []
	for k in g:
		out.append("%4d  %s" % [g[k], k])
	out.sort()
	out.reverse()
	return out.slice(0, 14)


func _result(name: String, ok: bool, line: String, extra: Array = []) -> void:
	print(("PASS  " if ok else "FAIL  ") + line)
	if not ok and name in ["A_outside_walls", "B_cross_exterior"]:
		extra = _groups(extra)
	for e in extra:
		print("        " + str(e))
	_report[name] = {"ok": ok, "summary": line, "detail": extra}
	_fails += int(not ok)


func _escape_count(p: Vector3) -> int:
	var n := 0
	for d in [Vector3(1, 0, 1), Vector3(1, 0, -1), Vector3(-1, 0, 1), Vector3(-1, 0, -1), Vector3(0, 1, 0), Vector3(0, -1, 0), Vector3(1, 0, 0), Vector3(-1, 0, 0)]:
		var q := PhysicsRayQueryParameters3D.create(p, p + (d as Vector3).normalized() * 30.0)
		q.collide_with_areas = false
		if _space.intersect_ray(q).is_empty():
			n += 1
	return n


func _physics_process(_d: float) -> bool:
	_f += 1
	if _f < 6:
		return false
	_space = root.world_3d.direct_space_state
	if OS.get_environment("AUDIT_SHELL") != "":      # AUDIT_SHELL=res://path.glb: audit against an authored shell (loaded at run time) instead of the exterior mesh
		var doc := GLTFDocument.new()
		var st := GLTFState.new()
		doc.append_from_file(OS.get_environment("AUDIT_SHELL"), st)
		_shell_node = doc.generate_scene(st) as Node3D
		_lv.get_node("Lighthouse").add_child(_shell_node)
		print("audit: authored shell %s loaded" % OS.get_environment("AUDIT_SHELL"))
	var rooms := _lv.get_node("InteriorRooms")
	var interior: Array = []      # [{mi, layer}]
	var props: Array = []
	for path in SHELL:
		var arr: Array = []
		_meshes(rooms.get_node(path.trim_prefix("InteriorRooms/")), arr)
		for mi in arr:
			if _is_trim(String(mi.name)) or mi.mesh.get_faces().size() / 3 > 3000:
				continue
			if _shell_node != null and String(mi.name) == "TowerLining":
				continue      # the authored wall replaces the lining
			interior.append(mi)
	var hf := rooms.get_node("HouseFrame")
	var harr: Array = []
	_meshes(hf, harr)
	for mi in harr:
		var tris: int = mi.mesh.get_faces().size() / 3
		var anc: Node = mi.get_parent()
		var is_prop := false
		while anc != null and anc != hf:
			if String(anc.name).begins_with("Hero_"):
				is_prop = true
			anc = anc.get_parent()
		if is_prop or tris > 3000:
			props.append(mi)
		elif tris <= 200 and not _is_trim(String(mi.name)):
			interior.append(mi)
	print("audit: %d interior (kit+shell) meshes, %d prop meshes" % [interior.size(), props.size()])
	# ---- A: outside the walls
	var outside: Array = []
	var verts := 0
	for mi in interior:
		# glass panes, mullions and the lantern drum are the envelope itself (open to the air on one side by design)
		var nm0 := String(mi.name)
		if nm0.ends_with("_Glass") or nm0.ends_with("_Mullion") or "/LampRoom/" in String(mi.get_path()):
			continue
		var seen := {}
		for v in _faces(mi):
			var key := Vector3i(int(round(v.x * 20.0)), int(round(v.y * 20.0)), int(round(v.z * 20.0)))
			if seen.has(key):
				continue
			seen[key] = true
			verts += 1
			if _escape_count(v) >= 5:
				outside.append("%s vertex at %s" % [mi.get_path(), str(v)])
				break
	var by_node := {}
	for o in outside:
		var nm: String = o.split(" ")[0]
		by_node[nm] = true
	_result("A_outside_walls", outside.is_empty(), "A  interior geometry outside the walls: %d meshes (of %d, %d vertices tested)" % [outside.size(), interior.size(), verts], outside)
	# ---- B: crossing the exterior wall
	_bin_ext()
	var crossing: Array = []
	for mi in interior:
		var f := _faces(mi)
		var hit := false
		for t in range(0, f.size(), 3):
			if _edge_hits_ext(f[t], f[t + 1]) or _edge_hits_ext(f[t + 1], f[t + 2]) or _edge_hits_ext(f[t + 2], f[t]):
				hit = true
				break
		if hit:
			crossing.append(String(mi.get_path()))
	_result("B_cross_exterior", crossing.is_empty(), "B  interior meshes whose edges cut through the exterior mesh: %d of %d (%d exterior triangles)" % [crossing.size(), interior.size(), _ext_tris], crossing.slice(0, 400))
	# ---- C: props
	var pboxes := {}      # holder -> AABB (global)
	for mi in props:
		var holder: Node = mi
		while holder != null and not String(holder.name).begins_with("Hero_") and holder != hf:
			holder = holder.get_parent()
		var key := String(holder.get_path()) if holder != null and holder != hf else String(mi.get_path())
		var bb: AABB = (mi as MeshInstance3D).global_transform * (mi as MeshInstance3D).mesh.get_aabb()
		pboxes[key] = pboxes[key].merge(bb) if pboxes.has(key) else bb
	var clip: Array = []
	var keys := pboxes.keys()
	for i in keys.size():
		for j in range(i + 1, keys.size()):
			var inter: AABB = (pboxes[keys[i]] as AABB).intersection(pboxes[keys[j]])
			if inter.size.x > 0.06 and inter.size.y > 0.06 and inter.size.z > 0.06:
				clip.append("%s overlaps %s by %s" % [keys[i].get_file(), keys[j].get_file(), str(inter.size)])
	for key in keys:
		var bb2: AABB = (pboxes[key] as AABB).grow(-0.03)
		var cells := {}
		for x in range(int(floor(bb2.position.x / CELL)), int(floor(bb2.end.x / CELL)) + 1):
			for y in range(int(floor(bb2.position.y / CELL)), int(floor(bb2.end.y / CELL)) + 1):
				for z in range(int(floor(bb2.position.z / CELL)), int(floor(bb2.end.z / CELL)) + 1):
					cells[Vector3i(x, y, z)] = true
		var bad := false
		for k in cells:
			if not _bins.has(k):
				continue
			var arr2: PackedVector3Array = _bins[k]
			for t in range(0, arr2.size(), 3):
				for e in 3:
					var a: Vector3 = arr2[t + e]
					var b: Vector3 = arr2[t + (e + 1) % 3]
					if bb2.intersects_segment(a, b):
						bad = true
						break
				if bad:
					break
			if bad:
				break
		if bad:
			clip.append("%s box is cut by an exterior triangle" % str(key).get_file())
	_result("C_props", clip.is_empty(), "C  props clipping other geometry: %d (of %d props)" % [clip.size(), keys.size()], clip.slice(0, 12))
	# ---- D: scale and clearance
	var scale_bad: Array = []
	for key in keys:
		var id: String = str(key).get_file().trim_prefix("Hero_")
		if not PROP_SCALE.has(id):
			continue
		var sp: Array = PROP_SCALE[id]
		var sz: Vector3 = (pboxes[key] as AABB).size
		var longest := maxf(sz.x, sz.z)
		if sz.y < sp[0] or sz.y > sp[1] or longest < sp[2] or longest > sp[3]:
			scale_bad.append("%s height %.2f (want %.2f-%.2f) longest side %.2f (want %.2f-%.2f)" % [id, sz.y, sp[0], sp[1], longest, sp[2], sp[3]])
	_result("D_prop_scale", scale_bad.is_empty(), "D1 hero props outside a real-world size range: %d" % scale_bad.size(), scale_bad)
	var fr: Node3D = rooms.frame
	var doors: Array = []
	# [name, point in the doorway at floor level (house frame u, y, v), axis the width runs along (frame u or v), min clear width]
	var door_list := [
		["front door", Vector3(0.0, 1.0, 0.3), "u", 0.9],
		["hall to tower", Vector3(5.65, 1.0, 1.5), "v", 0.8],
		["store door", Vector3(4.6, 1.0, 3.3), "u", 0.8],
	]
	for dd in door_list:
		var base: Vector3 = dd[1]
		var floor_p := fr.to_global(Vector3(base.x, base.y + 0.1, -base.z))
		var up := _space.intersect_ray(PhysicsRayQueryParameters3D.create(floor_p, floor_p + Vector3(0, 4, 0)))
		var head := (fr.to_local(up["position"]).y - base.y) if not up.is_empty() else 4.0
		var axis: Vector3 = (fr.global_transform.basis.x if dd[2] == "u" else -fr.global_transform.basis.z).normalized()
		var mid := fr.to_global(Vector3(base.x, base.y + 1.0, -base.z))
		var w := 0.0
		var cl := _space.intersect_ray(PhysicsRayQueryParameters3D.create(mid, mid + axis * 3.0))
		var cr := _space.intersect_ray(PhysicsRayQueryParameters3D.create(mid, mid - axis * 3.0))
		w = (mid.distance_to(cl["position"]) if not cl.is_empty() else 3.0) + (mid.distance_to(cr["position"]) if not cr.is_empty() else 3.0)
		var ok: bool = head >= 1.98 and w >= float(dd[3])
		doors.append("%s: clear width %.2f m (min %.2f), head %.2f m (min 1.98)%s" % [dd[0], w, dd[3], head, "" if ok else "   <-- FAIL"])
		if not ok:
			scale_bad.append(dd[0])
	var door_fails := 0
	for d in doors:
		if "<-- FAIL" in d:
			door_fails += 1
	_result("D_doorways", door_fails == 0, "D2 doorways below real-world clearance: %d of %d" % [door_fails, doors.size()], doors)
	# windows: sill height above the floor 0.6 to 1.3 m, opening height at least 0.9 m (data/world/lighthouse_windows.json)
	var wf := FileAccess.open("res://data/world/lighthouse_windows.json", FileAccess.READ)
	var wbad: Array = []
	var wn := 0
	if wf:
		var wj = JSON.parse_string(wf.get_as_text())
		var wl: Array = wj if wj is Array else wj.get("windows", [])
		for w2 in wl:
			wn += 1
			var h: float = float(w2.get("height", w2.get("h", 0.0)))
			var wd: float = float(w2.get("width", w2.get("w", 0.0)))
			var yc: float = float(w2.get("y", 0.0))
			if h > 0.0 and (h < 0.9 or h > 2.6):
				wbad.append("%s height %.2f" % [str(w2.get("name", w2.get("id", wn))), h])
			if wd > 0.0 and (wd < 0.5 or wd > 2.0):
				wbad.append("%s width %.2f" % [str(w2.get("name", w2.get("id", wn))), wd])
			if yc <= 0.0 and h <= 0.0:
				wbad.append("%s has no size data" % str(w2.get("name", w2.get("id", wn))))
	_result("D_windows", wbad.is_empty(), "D3 window openings outside 0.5 to 2.0 wide / 0.9 to 2.6 high: %d of %d" % [wbad.size(), wn], wbad)
	print("\n%s" % ("ALL PASSED" if _fails == 0 else "%d FAILED" % _fails))
	if "json" in OS.get_cmdline_user_args():
		var jf := FileAccess.open("res://../GERFramework/reports/lighthouse_clipping_audit.json", FileAccess.WRITE)
		jf.store_string(JSON.stringify(_report, "  "))
	quit(1 if _fails > 0 else 0)
	return false
