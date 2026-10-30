# probe_ted.gd - Ted's imported size and facing (the rigged test character).
extends SceneTree

var _n: Node3D
var _f := 0


func _initialize() -> void:
	_n = (load("res://Assets/Characters/ted.glb") as PackedScene).instantiate()
	root.add_child(_n)


func _process(_d: float) -> bool:
	_f += 1
	if _f == 3:
		var out := AABB()
		var first := true
		for c in _n.find_children("*", "MeshInstance3D", true, false):
			var mi := c as MeshInstance3D
			var b: AABB = mi.global_transform * mi.get_aabb()
			out = b if first else out.merge(b)
			first = false
		print("TED bounds ", out.position, " size ", out.size, " root scale ", _n.scale)
		var sk := _n.find_children("*", "Skeleton3D", true, false)
		print("TED skeletons ", sk.size(), " animation players ", _n.find_children("*", "AnimationPlayer", true, false).size())
		quit()
	return false
