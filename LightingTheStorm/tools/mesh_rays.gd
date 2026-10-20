# mesh_rays.gd - ray tests against the VISIBLE triangles of meshes (not the collision shapes), for tools and tests.
# Every ray this helper takes lies in a plane of constant x (the coast runs along x), so triangles are sorted into
# columns of x and a ray only tests its own column. Both faces of every triangle count as a hit.
extends RefCounted

var cell := 2.0
var _bins := {}
var triangles := 0


func add_mesh(mi: MeshInstance3D, x_min: float, x_max: float) -> void:
	if mi.mesh == null:
		return
	var xf := mi.global_transform
	var wb: AABB = xf * mi.mesh.get_aabb()
	if wb.end.x < x_min - cell or wb.position.x > x_max + cell:
		return
	var faces := mi.mesh.get_faces()
	for t in range(0, faces.size(), 3):
		var a := xf * faces[t]
		var b := xf * faces[t + 1]
		var c := xf * faces[t + 2]
		var lo := int(floor(minf(a.x, minf(b.x, c.x)) / cell))
		var hi := int(floor(maxf(a.x, maxf(b.x, c.x)) / cell))
		for k in range(lo, hi + 1):
			if not _bins.has(k):
				_bins[k] = PackedVector3Array()
			var arr: PackedVector3Array = _bins[k]
			arr.append(a)
			arr.append(b)
			arr.append(c)
			_bins[k] = arr
		triangles += 1


## First hit along from + dir * t (t > 0), as a world position, or null.
func first_hit(from: Vector3, dir: Vector3) -> Variant:
	var k := int(floor(from.x / cell))
	if not _bins.has(k):
		return null
	var arr: PackedVector3Array = _bins[k]
	var best := INF
	var hit: Variant = null
	for t in range(0, arr.size(), 3):
		var r: Variant = Geometry3D.ray_intersects_triangle(from, dir, arr[t], arr[t + 1], arr[t + 2])
		if r != null:
			var d := from.distance_to(r as Vector3)
			if d < best:
				best = d
				hit = r
	return hit
