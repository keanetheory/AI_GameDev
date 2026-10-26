# probe_holes.gd - headless: boundary-edge loops of the exterior mesh (Lighthouse/convert after the carves): every place the wall mesh has an open edge.
# A loop is listed with its bounding box in the Lighthouse frame, its perimeter and the number of edges. Windows and the door show up here too (they are real openings).
extends SceneTree
var _lv: Node
var _f := 0
func _initialize() -> void:
	_lv = load("res://scenes/Level.tscn").instantiate()
	root.add_child(_lv)
func _process(_d: float) -> bool:
	_f += 1
	if _f < 6:
		return false
	var lh := _lv.get_node("Lighthouse") as Node3D
	var mis := lh.get_node("convert").find_children("*", "MeshInstance3D", true, false)
	var edges := {}      # quantised endpoint pair -> count
	var pos := {}
	for mi in mis:
		var m := mi as MeshInstance3D
		var f := m.mesh.get_faces()
		var xf: Transform3D = lh.global_transform.affine_inverse() * m.global_transform
		for t in range(0, f.size(), 3):
			for e in 3:
				var a: Vector3 = xf * f[t + e]
				var b: Vector3 = xf * f[t + (e + 1) % 3]
				var ka := Vector3i(roundi(a.x * 200), roundi(a.y * 200), roundi(a.z * 200))
				var kb := Vector3i(roundi(b.x * 200), roundi(b.y * 200), roundi(b.z * 200))
				if ka == kb:
					continue
				var key := [ka, kb] if (ka.x < kb.x or (ka.x == kb.x and (ka.y < kb.y or (ka.y == kb.y and ka.z < kb.z)))) else [kb, ka]
				var ks := str(key)
				edges[ks] = edges.get(ks, 0) + 1
				pos[ks] = [a, b]
	var open: Array = []
	for k in edges:
		if edges[k] == 1:
			open.append(pos[k])
	print("HOLES open edges ", open.size())
	# union-find loops by shared endpoints
	var parent := {}
	var find := func(x):
		while parent[x] != x:
			parent[x] = parent[parent[x]]
			x = parent[x]
		return x
	for e in open:
		for p in e:
			var kp := Vector3i(roundi(p.x * 50), roundi(p.y * 50), roundi(p.z * 50))
			if not parent.has(kp):
				parent[kp] = kp
		var ka := Vector3i(roundi(e[0].x * 50), roundi(e[0].y * 50), roundi(e[0].z * 50))
		var kb := Vector3i(roundi(e[1].x * 50), roundi(e[1].y * 50), roundi(e[1].z * 50))
		var ra = find.call(ka)
		var rb = find.call(kb)
		if ra != rb:
			parent[ra] = rb
	var groups := {}
	for e in open:
		var ka := Vector3i(roundi(e[0].x * 50), roundi(e[0].y * 50), roundi(e[0].z * 50))
		var r = find.call(ka)
		if not groups.has(r):
			groups[r] = {"n": 0, "len": 0.0, "lo": Vector3(1e9, 1e9, 1e9), "hi": Vector3(-1e9, -1e9, -1e9)}
		var g: Dictionary = groups[r]
		g["n"] += 1
		g["len"] += (e[0] as Vector3).distance_to(e[1])
		for p in e:
			g["lo"] = (g["lo"] as Vector3).min(p)
			g["hi"] = (g["hi"] as Vector3).max(p)
	var rows := groups.values()
	rows.sort_custom(func(a, b): return a["len"] > b["len"])
	for g in rows.slice(0, 40):
		var lo: Vector3 = g["lo"]
		var hi: Vector3 = g["hi"]
		var hb := Vector2(1e9, 1e9)
		var hb2 := Vector2(-1e9, -1e9)
		var vb := Vector2(1e9, 1e9)
		var vb2 := Vector2(-1e9, -1e9)
		for corner in [Vector3(lo.x, 0, lo.z), Vector3(hi.x, 0, lo.z), Vector3(lo.x, 0, hi.z), Vector3(hi.x, 0, hi.z)]:
			var rx: float = corner.x + 3.494
			var rz: float = corner.z - 8.874
			var uu: float = rx * cos(0.4457) - rz * sin(0.4457)
			var vv: float = -(rx * sin(0.4457) + rz * cos(0.4457))
			hb = Vector2(minf(hb.x, uu), minf(hb.y, vv))
			hb2 = Vector2(maxf(hb2.x, uu), maxf(hb2.y, vv))
		print("HOLES    house frame u %.1f..%.1f v %.1f..%.1f" % [hb.x, hb2.x, hb.y, hb2.y])
		print("HOLES loop edges %4d perimeter %6.2f  x %.1f..%.1f  y %.1f..%.1f  z %.1f..%.1f   (axis-relative x %.1f..%.1f z %.1f..%.1f)" % [g["n"], g["len"], lo.x, hi.x, lo.y, hi.y, lo.z, hi.z, lo.x - 3.5, hi.x - 3.5, lo.z - 3.6, hi.z - 3.6])
	quit(0)
	return false
