# probe_seat_heights.gd - the vertex heights of a boat model around a seat spot, to find the thwart/deck the seated sailor should sit on.
# run: Godot --headless --path . --script res://tools/probe_seat_heights.gd -- <model.glb> <x> <z> [radius]
extends SceneTree

var _n: Node3D
var _f := 0
var _x := 0.0
var _z := 0.0
var _r := 0.35


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	_n = (load(a[0]) as PackedScene).instantiate()
	_x = float(a[1])
	_z = float(a[2])
	if a.size() > 3:
		_r = float(a[3])
	root.add_child(_n)


func _process(_d: float) -> bool:
	_f += 1
	if _f >= 3:
		var ys: Array = []
		var lo := 1e9
		var hi := -1e9
		for c in _n.find_children("*", "MeshInstance3D", true, false):
			var mi := c as MeshInstance3D
			var t := mi.global_transform
			for s in mi.mesh.get_surface_count():
				var arr := mi.mesh.surface_get_arrays(s)
				for v in (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array):
					var w := t * v
					lo = minf(lo, w.y)
					hi = maxf(hi, w.y)
					if absf(w.x - _x) < _r and absf(w.z - _z) < _r:
						ys.append(snappedf(w.y, 0.05))
		print("SEAT model y range ", lo, " .. ", hi)
		var counts := {}
		for y in ys:
			counts[y] = int(counts.get(y, 0)) + 1
		var keys := counts.keys()
		keys.sort()
		for k in keys:
			print("SEAT y ", k, " verts ", counts[k])
		quit()
	return false
