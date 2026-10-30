# probe_jaw_axis.gd - the Meshy rig's jaw bone: its name, parent and which local axis opens the mouth (for jaw_lipsync.gd).
extends SceneTree

var _n: Node3D
var _f := 0


func _initialize() -> void:
	_n = (load("res://Assets/Characters/ted.glb") as PackedScene).instantiate()
	root.add_child(_n)


func _process(_d: float) -> bool:
	_f += 1
	if _f >= 3:
		var sk := _n.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
		for i in sk.get_bone_count():
			if sk.get_bone_name(i).to_lower().contains("jaw"):
				print("JAW bone ", i, " name '", sk.get_bone_name(i), "' parent ", sk.get_bone_name(sk.get_bone_parent(i)))
				var rest := sk.get_bone_global_rest(i)
				print("JAW rest origin ", rest.origin, " basis x ", rest.basis.x, " y ", rest.basis.y, " z ", rest.basis.z)
				var fwd := Vector3(0, 0, 1)   # the raw rig faces +Z
				for ax in [Vector3.RIGHT, Vector3.UP, Vector3.FORWARD]:
					var a: Vector3 = (rest.basis * ax).normalized()
					print("JAW local axis ", ax, " = model ", a, "  +angle swings a forward point to y ", a.cross(fwd).y)
		var head := sk.get_bone_name(sk.find_bone("mixamorig_Head") if sk.find_bone("mixamorig_Head") >= 0 else 0)
		print("JAW sample bone names ", [sk.get_bone_name(0), sk.get_bone_name(1), head])
		quit()
	return false
