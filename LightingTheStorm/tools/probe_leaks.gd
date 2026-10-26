# probe_leaks.gd - run: Godot --headless --path . --script res://tools/probe_leaks.gd [-- nopatch]
# Where does the exterior mesh leak? From a lattice of points inside each room (the house's ground floor and first floor, the tower) rays go out in 162 directions. A ray
# that leaves the room's air volume and then reaches far (30 m) without touching an exterior triangle went through a hole in the wall or the roof. Each leak is filed
# by the face of the volume it left through (west / east / front / back wall, roof, tower wall by bearing and height) and grouped on a 0.3 m grid; the groups are printed
# as rectangles in the wall's own coordinates, biggest first: those are the holes. Uses the exterior mesh as it is in the game (with the baked patches unless `nopatch`).
extends SceneTree

var _lv: Node
var _f := 0
var _wp: Node3D
var _sp: Dictionary


func _initialize() -> void:
	if "nopatch" in OS.get_cmdline_user_args():
		OS.set_environment("LHF_NO_WALL_PATCH", "1")
	_lv = load("res://scenes/Level.tscn").instantiate()
	root.add_child(_lv)


func _hf(u: float, y: float, v: float) -> Vector3:
	var o: Array = _sp["house_origin"]
	var yaw: float = _sp["house_yaw"]
	return Vector3(float(o[0]) + u * cos(yaw) + (-v) * sin(yaw), y, float(o[1]) + u * (-sin(yaw)) + (-v) * cos(yaw))


func _uv(p: Vector3) -> Vector3:
	var o: Array = _sp["house_origin"]
	var yaw: float = _sp["house_yaw"]
	var rx := p.x - float(o[0])
	var rz := p.z - float(o[1])
	return Vector3(rx * cos(yaw) - rz * sin(yaw), p.y, -(rx * sin(yaw) + rz * cos(yaw)))


func _process(_d: float) -> bool:
	_f += 1
	if _f < 10:
		return false
	var sf := FileAccess.open("res://data/world/shell_spec.json", FileAccess.READ)
	_sp = JSON.parse_string(sf.get_as_text())
	var lh := _lv.get_node("Lighthouse") as Node3D
	var wp := Node3D.new()
	wp.set_script(load("res://scripts/world/wall_patch.gd"))
	wp.set("_lh", lh)
	wp.set("_sp", _sp)
	wp._collect()
	wp._collect_grid()
	_wp = wp
	print("leaks: exterior triangles ", wp._tris.size())
	# directions
	var dirs: Array = []
	var n := 162
	for i in n:
		var yy := 1.0 - 2.0 * (i + 0.5) / n
		var r := sqrt(1.0 - yy * yy)
		var th := PI * (1.0 + sqrt(5.0)) * i
		dirs.append(Vector3(cos(th) * r, yy, sin(th) * r))
	var gu: Array = _sp["ground_u"]
	var gv: Array = _sp["ground_v"]
	var fu: Array = _sp["first_u"]
	var fv: Array = _sp["first_v"]
	var rooms := [
		{"name": "ground", "u": gu, "v": gv, "y": [1.3, 3.4]},
		{"name": "first", "u": fu, "v": fv, "y": [5.6, 6.6]},
	]
	var leaks := {}
	for rm in rooms:
		var u0: float = rm["u"][0]
		var u1: float = rm["u"][1]
		var v0: float = rm["v"][0]
		var v1: float = rm["v"][1]
		for iu in 7:
			for iv in 7:
				for iy in 2:
					var p := _hf(lerpf(u0 + 0.2, u1 - 0.2, iu / 6.0), lerpf(float(rm["y"][0]), float(rm["y"][1]), iy), lerpf(v0 + 0.2, v1 - 0.2, iv / 6.0))
					for d in dirs:
						var o := p
						var hit: Dictionary = _wp._grid_hit(o, d, 40.0, true)
						if not hit.is_empty():
							continue
						# where does the ray leave the air volume of this room? march until outside the box (house frame)
						var t := 0.0
						var q := o
						while t < 14.0:
							var h: Vector3 = _uv(q)
							if h.x < u0 or h.x > u1 or h.z < v0 or h.z > v1 or h.y > 12.0:
								break
							t += 0.05
							q = o + d * t
						var e := _uv(q)
						var face := "roof"
						var s := Vector2(e.x, e.z)
						if e.x < u0:
							face = "west"
							s = Vector2(e.z, e.y)
						elif e.x > u1:
							face = "east"
							s = Vector2(e.z, e.y)
						elif e.z < v0:
							face = "front"
							s = Vector2(e.x, e.y)
						elif e.z > v1:
							face = "back"
							s = Vector2(e.x, e.y)
						var key := "%s/%s/%d/%d" % [rm["name"], face, int(floor(s.x / 0.4)), int(floor(s.y / 0.4))]
						if not leaks.has(key):
							leaks[key] = {"room": rm["name"], "face": face, "s0": s, "s1": s, "n": 0}
						var L: Dictionary = leaks[key]
						L["s0"] = (L["s0"] as Vector2).min(s)
						L["s1"] = (L["s1"] as Vector2).max(s)
						L["n"] += 1
	# merge neighbouring cells of the same room+face into rectangles by a simple flood on the 0.4 m grid
	var by_face := {}
	for k in leaks:
		var L: Dictionary = leaks[k]
		var fk := "%s/%s" % [L["room"], L["face"]]
		if not by_face.has(fk):
			by_face[fk] = []
		by_face[fk].append(L)
	for fk in by_face:
		var arr: Array = by_face[fk]
		var used := {}
		for i in arr.size():
			if used.has(i):
				continue
			var lo: Vector2 = arr[i]["s0"]
			var hi: Vector2 = arr[i]["s1"]
			var cnt := 0
			var stack := [i]
			used[i] = true
			while not stack.is_empty():
				var a: int = stack.pop_back()
				var A: Dictionary = arr[a]
				lo = lo.min(A["s0"])
				hi = hi.max(A["s1"])
				cnt += int(A["n"])
				for j in arr.size():
					if used.has(j):
						continue
					var B: Dictionary = arr[j]
					if (A["s0"] as Vector2).distance_to(B["s0"]) < 0.9 or (A["s1"] as Vector2).distance_to(B["s1"]) < 0.9:
						used[j] = true
						stack.append(j)
			print("LEAK %-14s  %5d rays   along-wall/x %.1f..%.1f   height/z %.1f..%.1f" % [fk, cnt, lo.x, hi.x, lo.y, hi.y])
	quit(0)
	return false
