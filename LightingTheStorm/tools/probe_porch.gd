# probe_porch.gd - lists every upward-facing surface under points between the plateau and the lighthouse porch.
extends SceneTree

var _lv: Node
var _f := 0


func _initialize() -> void:
	_lv = load("res://scenes/Level.tscn").instantiate()
	root.add_child(_lv)


func _physics_process(_d: float) -> bool:
	_f += 1
	if _f == 40:
		var space: PhysicsDirectSpaceState3D = _lv.get_world_3d().direct_space_state
		var ex: Array[RID] = [(_lv.get_node("Player") as CharacterBody3D).get_rid()]
		for z in [6.0, 5.0, 4.0, 3.5, 3.0, 2.5, 2.0, 1.4]:
			var top := 45.0
			var ys := []
			for _i in 12:
				var q := PhysicsRayQueryParameters3D.create(Vector3(1.9, top, z), Vector3(1.9, -5.0, z))
				q.exclude = ex
				var h := space.intersect_ray(q)
				if h.is_empty():
					break
				if h["normal"].y > 0.5:
					ys.append(snappedf(h["position"].y, 0.01))
				top = h["position"].y - 0.05
			print("PORCH z=%.1f ups %s" % [z, ys])
		quit()
	return false
