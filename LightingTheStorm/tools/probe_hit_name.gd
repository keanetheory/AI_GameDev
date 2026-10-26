# probe_hit_name.gd - headless: what the first collider and visible mesh are along a ray. Usage: -- x y z  tx ty tz
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
	var a := OS.get_cmdline_user_args()
	var o := Vector3(float(a[0]), float(a[1]), float(a[2]))
	var t := Vector3(float(a[3]), float(a[4]), float(a[5]))
	var r := root.world_3d.direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(o, t + (t - o).normalized() * 0.2))
	print("HIT ", r["collider"].get_path() if not r.is_empty() else "none", " at ", r.get("position"))
	if not r.is_empty():
		var par: Node = r["collider"].get_parent()
		for c in par.get_children():
			if c is MeshInstance3D:
				var m := (c as MeshInstance3D).mesh.surface_get_material(0)
				print("  sibling mesh ", c.name, " mat ", m.resource_name if m else "none", " emission ", (m as StandardMaterial3D).emission_enabled if m is StandardMaterial3D else "-")
	quit(0)
	return false
