# probe_floor_at.gd - headless: what the first collider is straight below / above given world points. Usage: -- x y z [x y z ...]
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
	for i in range(0, a.size(), 3):
		var p := Vector3(float(a[i]), float(a[i + 1]), float(a[i + 2]))
		var r := root.world_3d.direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(p + Vector3(0, 1.5, 0), p - Vector3(0, 4, 0)))
		print("FLOOR below ", p, " -> ", (str(r["collider"].get_path()) + " at y %.2f" % r["position"].y) if not r.is_empty() else "nothing")
	quit(0)
	return false
