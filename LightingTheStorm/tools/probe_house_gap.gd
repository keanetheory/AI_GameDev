# probe_house_gap.gd - headless: maps which cells of the house's front and west walls have exterior wall (#), show the room lining (L) or nothing (.)
# from outside, at the first floor. House frame (kit.gd): u across, v front-to-back, y up. Usage: Godot --headless --path . --script res://tools/probe_house_gap.gd
extends SceneTree
var _lv: Node
var _f := 0
func _initialize() -> void:
	_lv = load("res://scenes/Level.tscn").instantiate()
	root.add_child(_lv)
func _physics_process(_d: float) -> bool:
	_f += 1
	if _f < 8:
		return false
	var frame: Node3D = _lv.get_node("InteriorRooms").frame
	var lh := _lv.get_node("Lighthouse")
	var space := root.world_3d.direct_space_state
	for wall in ["front", "west"]:
		print("== %s wall (rows: y from 8.0 down to 3.0; columns every 0.25 m)" % wall)
		var depths := []
		var y := 8.0
		while y >= 3.0:
			var row := "%4.1f " % y
			var a := -4.0 if wall == "front" else -1.0
			while a <= (1.0 if wall == "front" else 4.0):
				var o: Vector3 = Vector3(a, y, 4.0) if wall == "front" else Vector3(-7.0, y, -a)
				var t: Vector3 = o + (Vector3(0, 0, -6.0) if wall == "front" else Vector3(6.0, 0, 0))
				var q := PhysicsRayQueryParameters3D.create(frame.to_global(o), frame.to_global(t))
				q.hit_back_faces = true
				var r := space.intersect_ray(q)
				var ch := "."
				if not r.is_empty():
					var p: Vector3 = frame.to_local(r["position"])
					if lh.is_ancestor_of(r["collider"]):
						ch = "#"
						depths.append(p.z if wall == "front" else p.x)
					else:
						ch = "L" if "Lining" in String(r["collider"].get_path()) else "o"
				row += ch
				a += 0.25
			print(row)
			y -= 0.25
		depths.sort()
		if depths.size() > 0:
			print("   outer face (median %s): %.2f" % ["v" if wall == "front" else "u", depths[depths.size() / 2]])
	quit(0)
	return false
