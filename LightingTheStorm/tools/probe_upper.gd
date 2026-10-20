extends SceneTree
# probe_upper.gd - map the first-floor space inside the house shell: for each house-frame (u, v) cell, the headroom
# under the roof above a floor at FLOOR_Y, and whether a wall is within 0.45 m. '.' = no roof overhead (outside),
# 'w' = wall close, digits = headroom in metres (rounded down, 9 = 9+).
# Run: Godot --headless --path . --script res://tools/probe_upper.gd
const OFF := Vector3(5, 9.61, -8.5)
const SILL := Vector3(-3.494, 0.0, 8.874)
const U := Vector3(0.9024, 0.0, -0.4309)
const V := Vector3(-0.4309, 0.0, -0.9024)
const FLOOR_Y := 5.2
var _f := 0


func _hw(u: float, y: float, v: float) -> Vector3:
	return OFF + SILL + U * u + V * v + Vector3(0, y, 0)


func _initialize() -> void:
	root.add_child(load("res://scenes/Level.tscn").instantiate())


func _physics_process(_d: float) -> bool:
	_f += 1
	if _f < 20:
		return false
	var sp := root.get_world_3d().direct_space_state
	print("map at floor y %.1f: columns u -4.5..9.5 step 0.5; rows v -2..11 step 0.5" % FLOOR_Y)
	var hdr := "       "
	for iu in range(-9, 20):
		hdr += "%s" % (str(absi(iu * 5 / 10) % 10) if iu % 2 == 0 else " ")
	print(hdr)
	for iv in range(-4, 23):
		var v := iv * 0.5
		var line := "v%5.1f " % v
		for iu in range(-9, 20):
			var u := iu * 0.5
			var a := _hw(u, FLOOR_Y + 0.1, v)
			var ru := sp.intersect_ray(PhysicsRayQueryParameters3D.create(a, a + Vector3.UP * 7.0))
			var ch := "."
			if not ru.is_empty():
				var hr: float = ru["position"].y - (OFF.y + FLOOR_Y)
				ch = str(clampi(int(hr), 0, 9))
				for d in [U, -U, V, -V]:
					var q := sp.intersect_ray(PhysicsRayQueryParameters3D.create(_hw(u, FLOOR_Y + 1.0, v), _hw(u, FLOOR_Y + 1.0, v) + d * 0.45))
					if not q.is_empty():
						ch = "w"
						break
			line += ch
		print(line)
	quit()
	return false
