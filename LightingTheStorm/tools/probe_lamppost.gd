# probe_lamppost.gd - the imported lamppost's size and where its origin sits (needs a frame for the transforms).
extends SceneTree

var _n: Node3D
var _f := 0


func _initialize() -> void:
	_n = (load("res://Assets/Models/lamppost/lamppost.glb") as PackedScene).instantiate()
	root.add_child(_n)


func _process(_d: float) -> bool:
	_f += 2
	if _f >= 4:
		var out := AABB()
		var first := true
		for c in _n.find_children("*", "MeshInstance3D", true, false):
			var b: AABB = (c as MeshInstance3D).global_transform * (c as MeshInstance3D).get_aabb()
			out = b if first else out.merge(b)
			first = false
		print("LAMPPOST bounds ", out.position, " size ", out.size)
		quit()
	return false
