extends SceneTree
# bake_tower_radii.gd - measure how far the exterior model's inner wall is from the tower axis, per bearing and height, and
# write data/world/tower_radii.json: the interior lining (scripts/world/interior/tower_shell.gd) follows the table so it always
# sits just inside the real wall (no exterior surface pokes through it) and tapers up the tower. Re-run after changing the
# exterior model or the window carves. Run: Godot --headless --path . --script res://tools/bake_tower_radii.gd
const OFF := Vector3(5, 9.61, -8.5)
const STEP_DEG := 3.75
const Y0 := 4.0
const Y_STEP := 0.5
const Y_ROWS := 28
const MARGIN := 0.12
const MIN_R := 2.6
var _f := 0


func _initialize() -> void:
	var lv: Node = load("res://scenes/Level.tscn").instantiate()
	root.add_child(lv)


func _physics_process(_d: float) -> bool:
	_f += 1
	if _f == 2:
		var rooms := root.get_node("Level/InteriorRooms")     # measure the exterior alone
		rooms.free()
		return false
	if _f < 12:
		return false
	var sp := root.get_world_3d().direct_space_state
	var axis := OFF + Vector3(3.5, 0, 3.6)
	var rows := []
	for j in Y_ROWS:
		var row := []
		for k in int(360.0 / STEP_DEG):
			var rmin := 99.0
			for dy in [0.05, 0.25, 0.45]:
				for da in [-0.45, -0.15, 0.15, 0.45]:
					var a := deg_to_rad(STEP_DEG * (float(k) + 0.5 + da))
					var d := Vector3(cos(a), 0, sin(a))
					var from := axis + Vector3(0, Y0 + Y_STEP * float(j) + dy, 0) + d * 2.1
					var r := _hit_exterior(sp, from, from + d * 3.5)
					if r > 0.0:
						rmin = minf(rmin, r)
			row.append(snappedf(rmin, 0.01) if rmin < 90.0 else -1.0)
		rows.append(row)
	var out := {"bearing_step": STEP_DEG, "y0": Y0, "y_step": Y_STEP, "margin": MARGIN, "min_radius": MIN_R, "rows": rows}
	FileAccess.open("res://data/world/tower_radii.json", FileAccess.WRITE).store_string(JSON.stringify(out))
	print("baked tower_radii.json: %d rows x %d bearings" % [rows.size(), rows[0].size()])
	quit()
	return false


## Radius (from the axis) of the first hit of the Lighthouse exterior along a ray, ignoring anything else; -1 if none.
func _hit_exterior(sp: PhysicsDirectSpaceState3D, from: Vector3, to: Vector3) -> float:
	var skip: Array[RID] = []
	for i in 6:
		var q := PhysicsRayQueryParameters3D.create(from, to)
		q.hit_back_faces = true
		q.exclude = skip
		var h := sp.intersect_ray(q)
		if h.is_empty():
			return -1.0
		var chain := ""
		var c: Node = h["collider"]
		while c != null and c != root:
			chain = String(c.name) + "/" + chain
			c = c.get_parent()
		if chain.contains("/Lighthouse/"):
			var p: Vector3 = h["position"] - (OFF + Vector3(3.5, 0, 3.6))
			return Vector2(p.x, p.z).length()
		skip.append(h["rid"])
	return -1.0
