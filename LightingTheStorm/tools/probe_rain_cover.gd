# probe_rain_cover.gd - headless: Godot --headless --path . --script res://tools/probe_rain_cover.gd
# Rain probe, CPU side. Samples the house's first floor and attic on a grid (house frame) and lists indoor points (a ray up hits the roof
# or ceiling, and at least 7 of 8 horizontal rays hit a wall within 15 m) that the RainShelter boxes do NOT cover.
extends SceneTree

var _lv: Node
var _f := 0


func _initialize() -> void:
	_lv = load("res://scenes/Level.tscn").instantiate()
	root.add_child(_lv)


func _physics_process(_d: float) -> bool:
	_f += 1
	if _f < 6:
		return false
	var rs = _lv.get_node("RainShelter")
	var fr: Node3D = _lv.get_node("InteriorRooms").frame
	var space := root.world_3d.direct_space_state
	var miss := {}
	var total := 0
	var indoor := 0
	for yi in range(0, 21):
		var y := 5.4 + yi * 0.2
		var map_row := (absf(y - 6.6) < 0.01 or absf(y - 8.6) < 0.01)
		var rows: Array = []
		for vi in range(0, 44):
			var v := vi * 0.25
			var line := ""
			for ui in range(-18, 30):
				var u := ui * 0.25
				var p: Vector3 = fr.to_global(Vector3(u, y, -v))
				total += 1
				var q := PhysicsRayQueryParameters3D.create(p, p + Vector3(0, 6, 0))
				if space.intersect_ray(q).is_empty():
					line += "."
					continue
				var hits := 0
				for k in 8:
					var a := TAU * k / 8.0
					var q2 := PhysicsRayQueryParameters3D.create(p, p + Vector3(cos(a), 0, sin(a)) * 15.0)
					if not space.intersect_ray(q2).is_empty():
						hits += 1
				if hits < 7:
					line += "o"
					continue
				indoor += 1
				line += "#" if rs.covers(p) else "X"
				if not rs.covers(p):
					var key := "y%.1f" % y
					miss[key] = miss.get(key, 0) + 1
			rows.append(line)
		if map_row:
			print("MAP y=%.1f  (u -4.5..7.25 across, v 0 at top .25 steps; . no roof above, o open sides, # indoor covered, X indoor UNCOVERED)" % y)
			for r in rows:
				print(r)
	print("grid points %d, indoor %d, indoor and NOT covered by the shelter: %d" % [total, indoor, int(miss.values().reduce(func(a, b): return a + b, 0))])
	for k in miss:
		print("  ", k, " uncovered ", miss[k])
	quit(0)
	return false
