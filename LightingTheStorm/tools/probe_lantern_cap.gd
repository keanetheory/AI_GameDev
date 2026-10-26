# probe_lantern_cap.gd - headless: rays straight down onto the lantern roof from y 40, over the tower axis out to r 3.2: where is the first hit and is there a hole?
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
	var lh := _lv.get_node("Lighthouse") as Node3D
	var space := root.world_3d.direct_space_state
	for r in [0.0, 0.1, 0.2, 0.3, 0.5, 0.8, 1.2, 1.8, 2.4, 2.8, 3.2]:
		var line := "r %.1f: " % r
		for b in [0, 90, 180, 270]:
			var a := deg_to_rad(b)
			var p := lh.to_global(Vector3(3.5 + cos(a) * r, 40.0, 3.6 + sin(a) * r))
			var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(p, p - Vector3(0, 40, 0)))
			line += "  b%d -> %s" % [b, ("local y %.2f (%s)" % [lh.to_local(hit["position"]).y, str((hit["collider"] as Node).name)]) if not hit.is_empty() else "nothing"]
		print(line)
	quit(0)
	return false
