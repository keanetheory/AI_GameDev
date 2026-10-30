# probe_rowboat.gd - prints the rowboat model's bounds as imported (size and where the origin sits in it).
extends SceneTree


func _initialize() -> void:
	var n: Node3D = (load("res://Assets/Models/boat/" + OS.get_environment("MODEL") + ".glb") as PackedScene).instantiate()
	root.add_child(n)
	var out := AABB()
	var first := true
	for c in n.find_children("*", "MeshInstance3D", true, false):
		var mi := c as MeshInstance3D
		var b: AABB = mi.global_transform * mi.get_aabb()
		out = b if first else out.merge(b)
		first = false
	print("ROWBOAT bounds position ", out.position, " size ", out.size)
	quit()
