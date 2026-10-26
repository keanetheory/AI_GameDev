# probe_rain_roof.gd - headless: roof underside and top over the house footprint (house frame), vs the RainShelter house box top.
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
	var fr: Node3D = _lv.get_node("InteriorRooms").frame
	var space := root.world_3d.direct_space_state
	var max_under := -99.0
	var max_top := -99.0
	var n := 0
	for ui in range(-14, 24):
		var line := ""
		for vi in range(2, 38):
			var u := ui * 0.25
			var v := vi * 0.25
			var lo: Vector3 = fr.to_global(Vector3(u, 5.45, -v))
			var qu := PhysicsRayQueryParameters3D.create(lo, lo + Vector3(0, 12, 0))
			var ru := space.intersect_ray(qu)
			if ru.is_empty():
				line += "."
				continue
			var under: float = fr.to_local(ru["position"]).y
			var hi: Vector3 = fr.to_global(Vector3(u, 16.0, -v))
			var qd := PhysicsRayQueryParameters3D.create(hi, hi - Vector3(0, 14, 0))
			var rd := space.intersect_ray(qd)
			var top: float = fr.to_local(rd["position"]).y if not rd.is_empty() else -99.0
			max_under = maxf(max_under, under)
			max_top = maxf(max_top, top)
			n += 1
			line += "%d" % clampi(int(under - 5.0), 0, 9)
		if ui % 2 == 0:
			print(line)
	print("columns %d  highest ceiling/roof underside (frame y) %.2f   highest roof top %.2f   shelter house box top 8.90" % [n, max_under, max_top])
	quit(0)
	return false
