# audit_lighthouse.gd - run: Godot --headless --path . --script res://tools/audit_lighthouse.gd [-- json]
# usage with "-- check": exits 1 if the budget below is exceeded (a regression test).
# LHF-06: the lighthouse's geometry cost, measured (headless: triangles and surfaces from the mesh data; a surface is one draw call
# per pass, and a MultiMesh counts once). Prints a table by SOURCE (what made it) and by LEVEL (where it is), the top meshes, material
# and duplicate-mesh counts, and the shadow-casting load. Writes GERFramework/reports/lighthouse_finisher_audit.json when given "json".
extends SceneTree

const LEVELS := [["basement", -99.0, 10.45], ["ground", 10.45, 14.5], ["first floor", 14.5, 19.0], ["tower and L2", 19.0, 28.0], ["lamp room and gallery", 28.0, 99.0]]

## The lighthouse's budget (LHF-06), set from the measured result with some headroom: it was 2.54 M triangles before the audit.
const MAX_TRIS := 900000
const MAX_ONE_MESH := 100000
const MAX_SURFACES := 1600
const MAX_MATERIALS := 120
const MAX_NODES := 3200

var _f := 0


func _initialize() -> void:
	root.add_child(load("res://scenes/Level.tscn").instantiate())


func _surf_tris(m: Mesh, s: int) -> int:
	var a := m.surface_get_arrays(s)
	var idx = a[Mesh.ARRAY_INDEX]
	if idx != null and (idx as PackedInt32Array).size() > 0:
		return (idx as PackedInt32Array).size() / 3
	var v = a[Mesh.ARRAY_VERTEX]
	return (v as PackedVector3Array).size() / 3 if v != null else 0


func _source(mi: Node, lv: Node) -> String:
	var p: Node = mi
	var chain := ""
	while p != null and p != lv:
		chain = String(p.name) + "/" + chain
		p = p.get_parent()
	if chain.begins_with("Lighthouse/"):
		return "exterior model"
	if chain.begins_with("LighthouseInterior/"):
		return "v3 greybox shell"
	if "Hero_" in chain:
		return "hero props (FAL)"
	if "/Trim/" in chain:
		return "trim"
	if "StairTread" in chain or "Step_" in chain or "SpiralStep" in chain:
		return "stair treads"
	if "ExteriorOpenings" in chain or "LighthouseDoor_Kit" in chain:
		return "opening kit"
	if chain.begins_with("RoomLightCards"):
		return "light cards"
	if "Gallery" in chain or "LampRoom" in chain or "LampBeacon" in chain:
		return "lamp room + gallery"
	if chain.begins_with("InteriorRooms/"):
		return "interior kit (boxes, rods)"
	return "other"


func _physics_process(_d: float) -> bool:
	_f += 1
	if _f < 16:
		return false
	var lv := root.get_child(root.get_child_count() - 1)
	for c in root.get_children():
		if c.name == "Level":
			lv = c
	var roots: Array[Node] = []
	for n in ["Lighthouse", "LighthouseInterior", "InteriorRooms", "ExteriorOpenings", "LighthouseDoor", "RoomLightCards"]:
		var r := lv.get_node_or_null(n)
		if r:
			roots.append(r)
	var by_src := {}
	var by_lvl := {}
	var meshes := []
	var mats := {}
	var dup := {}
	var total_t := 0
	var total_s := 0
	var total_m := 0
	var shadow_t := 0
	var nodes := 0
	for r in roots:
		nodes += r.find_children("*", "", true, false).size()
		for n in r.find_children("*", "GeometryInstance3D", true, false):
			var g := n as GeometryInstance3D
			if not g.is_visible_in_tree():
				continue
			var tris := 0
			var surfs := 0
			if g is MeshInstance3D:
				var mi := g as MeshInstance3D
				if mi.mesh == null:
					continue
				for s in mi.mesh.get_surface_count():
					tris += _surf_tris(mi.mesh, s)
					surfs += 1
					var m := mi.get_active_material(s)
					if m:
						mats[m] = true
				var key := "%d:%s" % [mi.mesh.get_rid().get_id(), str(mi.material_override)]
				dup[mi.mesh] = dup.get(mi.mesh, 0) + 1
			elif g is MultiMeshInstance3D:
				var mmi := g as MultiMeshInstance3D
				if mmi.multimesh == null or mmi.multimesh.mesh == null:
					continue
				for s in mmi.multimesh.mesh.get_surface_count():
					tris += _surf_tris(mmi.multimesh.mesh, s) * mmi.multimesh.instance_count
					surfs += 1
			else:
				continue
			var src := _source(g, lv)
			var y := g.global_position.y
			var lvl := "other"
			for l in LEVELS:
				if y >= l[1] and y < l[2]:
					lvl = l[0]
			for d in [[by_src, src], [by_lvl, lvl]]:
				var e: Dictionary = (d[0] as Dictionary).get(d[1], {"meshes": 0, "surfaces": 0, "tris": 0})
				e["meshes"] += 1
				e["surfaces"] += surfs
				e["tris"] += tris
				(d[0] as Dictionary)[d[1]] = e
			total_t += tris
			total_s += surfs
			total_m += 1
			if g.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
				shadow_t += tris
			meshes.append([tris, String(g.get_path()).get_slice("/", 3) + "/" + String(g.name), src])
	meshes.sort_custom(func(a, b): return a[0] > b[0])
	print("AUDIT nodes %d, drawn meshes %d, surfaces (draw calls per pass) %d, triangles %d, shadow-casting triangles %d, materials %d" % [nodes, total_m, total_s, total_t, shadow_t, mats.size()])
	print("BY SOURCE")
	var keys := by_src.keys()
	keys.sort_custom(func(a, b): return by_src[a]["tris"] > by_src[b]["tris"])
	for k in keys:
		print("  %-28s %5d meshes %5d surfaces %9d tris" % [k, by_src[k]["meshes"], by_src[k]["surfaces"], by_src[k]["tris"]])
	print("BY LEVEL")
	for l in LEVELS:
		var e: Dictionary = by_lvl.get(l[0], {"meshes": 0, "surfaces": 0, "tris": 0})
		print("  %-28s %5d meshes %5d surfaces %9d tris" % [l[0], e["meshes"], e["surfaces"], e["tris"]])
	print("TOP MESHES")
	for i in mini(12, meshes.size()):
		print("  %9d  %s  (%s)" % [meshes[i][0], meshes[i][1], meshes[i][2]])
	var shared := 0
	for m in dup:
		if dup[m] > 1:
			shared += dup[m] - 1
	print("meshes sharing a Mesh resource with another: %d" % shared)
	if "check" in OS.get_cmdline_user_args():
		var fails := 0
		for chk in [[total_t <= MAX_TRIS, "triangles %d within %d" % [total_t, MAX_TRIS]], [meshes[0][0] <= MAX_ONE_MESH, "largest mesh %d within %d" % [meshes[0][0], MAX_ONE_MESH]],
				[total_s <= MAX_SURFACES, "surfaces %d within %d" % [total_s, MAX_SURFACES]], [mats.size() <= MAX_MATERIALS, "materials %d within %d" % [mats.size(), MAX_MATERIALS]],
				[nodes <= MAX_NODES, "nodes %d within %d" % [nodes, MAX_NODES]]]:
			print(("PASS  " if chk[0] else "FAIL  ") + chk[1])
			fails += int(not chk[0])
		print("
%s" % ("ALL PASSED" if fails == 0 else "%d FAILED" % fails))
		quit(1 if fails > 0 else 0)
		return false
	if "json" in OS.get_cmdline_user_args():
		var out := {"nodes": nodes, "meshes": total_m, "surfaces": total_s, "tris": total_t, "shadow_tris": shadow_t, "materials": mats.size(), "by_source": by_src, "by_level": by_lvl}
		var f := FileAccess.open("res://../GERFramework/reports/lighthouse_finisher_audit.json", FileAccess.WRITE)
		if f:
			f.store_string(JSON.stringify(out, "  "))
	quit()
	return false
