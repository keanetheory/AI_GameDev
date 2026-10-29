# probe_npc_block.gd - what a walker's chest-high body touches at given route points (gate and door open).
extends SceneTree

var _lv: Node
var _f := 0


func _initialize() -> void:
	_lv = load("res://scenes/Level.tscn").instantiate()
	root.add_child(_lv)


func _physics_process(_d: float) -> bool:
	_f += 1
	if _f == 5:
		for g in get_nodes_in_group("gate"):
			g.open()
		_lv.get_node("LighthouseDoor").open()
	if _f == 60:
		var Routes := preload("res://scripts/character/npc_routes.gd")
		var space: PhysicsDirectSpaceState3D = _lv.get_world_3d().direct_space_state
		var cap := CapsuleShape3D.new()
		cap.radius = 0.3
		cap.height = 1.0
		var ex: Array[RID] = [(_lv.get_node("Player") as CharacterBody3D).get_rid()]
		var last := Vector3(INF, INF, INF)
		for p in Routes.route("sailors_dock_to_hall"):
			if p.distance_to(last) < 0.5:
				continue
			last = p
			var q := PhysicsShapeQueryParameters3D.new()
			q.shape = cap
			q.transform = Transform3D(Basis(), p + Vector3(0, 1.15, 0))
			q.exclude = ex
			for h in space.intersect_shape(q, 4):
				print("BLOCK at %s by %s" % [p, (h["collider"] as Node).get_path()])
		quit()
	return false
