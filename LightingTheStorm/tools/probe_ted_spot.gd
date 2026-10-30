# probe_ted_spot.gd - where Ted can stand in the lamp room without being in the player's way to the arc lamp.
extends SceneTree

const Reach := preload("res://tools/interior_reach.gd")
var _lv: Node
var _f := 0


func _initialize() -> void:
	_lv = load("res://scenes/Level.tscn").instantiate()
	root.add_child(_lv)
	var ted: Node = (load("res://Assets/Characters/ted.glb") as PackedScene).instantiate()
	for ap in ted.find_children("*", "AnimationPlayer", true, false):
		print("TED animations ", (ap as AnimationPlayer).get_animation_list())


func _physics_process(_d: float) -> bool:
	_f += 1
	if _f == 5:
		_lv.get_node("LighthouseDoor").open()
	if _f == 60:
		var space: PhysicsDirectSpaceState3D = _lv.get_world_3d().direct_space_state
		var ex: Array[RID] = [(_lv.get_node("Player") as CharacterBody3D).get_rid()]
		var reach := Reach.new(space, ex)
		reach.build()
		var door: Node3D = _lv.get_node("LighthouseDoor")
		reach.flood(door.middle() + door.global_transform.basis.z + Vector3(0, 0.05, 0))
		var anchors: Dictionary = _lv.get_node("InteriorRooms").anchors
		var stand: Vector3 = anchors["lamp_stand"]
		var goal := reach.nearest(stand, true)
		var path := reach.path_to(goal)
		print("LAMP route ends ", path[-1], " via ", path.size(), " cells; stairs top near ", path[maxi(path.size() - 25, 0)])
		var lamp: Vector3 = anchors["lamp_socket"]
		var cap := CapsuleShape3D.new()
		cap.radius = 0.4
		cap.height = 1.8
		for k in 12:
			var a := TAU * k / 12.0
			var p := Vector3(lamp.x + cos(a) * 1.9, stand.y, lamp.z + sin(a) * 1.9)
			var q := PhysicsShapeQueryParameters3D.new()
			q.shape = cap
			q.transform = Transform3D(Basis(), p + Vector3(0, 0.95, 0))
			q.exclude = ex
			var clear := space.intersect_shape(q, 1).is_empty()
			var dmin := 99.0
			for w in path:
				if absf(w.y - stand.y) < 1.5:
					dmin = minf(dmin, Vector2(w.x - p.x, w.z - p.z).length())
			var rq := PhysicsRayQueryParameters3D.create(p + Vector3(0, 1, 0), p + Vector3(0, -2, 0))
			rq.exclude = ex
			var rh := space.intersect_ray(rq)
			print("SPOT %2d  %s clear %s floor %s  %.1f m from the player's route" % [k, p, clear, "none" if rh.is_empty() else snappedf(rh["position"].y, 0.01), dmin])
		quit()
	return false
