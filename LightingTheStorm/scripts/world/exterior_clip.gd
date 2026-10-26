# exterior_clip.gd - takes the parts of the generated exterior mesh that stand INSIDE the rooms out of the exterior (creator, 2026-10-26: "island mesh jutting through
# the L2 floor", "island meshes coming through on the stairwell", the orange chimney breast showing in the kitchen).
# The exterior is one scanned mesh with the old stair, chimney breasts, rafters and wall remnants still inside it; the interior is built as its own layer on top, so any
# exterior triangle that lies entirely inside a room's air volume is a stray: it shows through the lining or pokes through a floor. Triangles of the exterior's own walls and
# roof are never inside the volumes (the lining stands in front of the wall, the ceiling below the roof), so removing the strays loses nothing the outside shows.
# Volumes: the tower's lining (radius from the lining itself, tower_shell.gd wall_radius, less a margin) from the ground-floor ring to the lamp room floor, and the first
# floor between its lining planes under the old ceiling (rooms_tower.gd _ceiling's two slopes, less a margin). Runs once, when the interior is built.
extends Node

const MARGIN := 0.06
const TOWER := Vector2(3.5, 3.6)
const HOUSE_O := Vector2(-3.494, 8.874)      # the house frame in the Lighthouse frame (interior_rooms.gd DOOR_SILL, YAW)
const YAW := 0.4457

var removed := 0
var examined := 0


## `lh` the Lighthouse node, `frame` the house frame, `shell` the tower shell (wall_radius), `l1` the first floor's height.
func apply(lh: Node3D, frame: Node3D, shell, l1: float) -> void:
	var cv := lh.get_node_or_null("convert")
	if cv == null:
		return
	for mi in cv.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		if m.mesh == null:
			continue
		var xf: Transform3D = lh.global_transform.affine_inverse() * m.global_transform
		var out_mesh := ArrayMesh.new()
		var changed := false
		for s in m.mesh.get_surface_count():
			var arr := m.mesh.surface_get_arrays(s)
			var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array(range(v.size()))
			var keep := PackedInt32Array()
			for t in range(0, idx.size(), 3):
				examined += 1
				var a: Vector3 = xf * v[idx[t]]
				var b: Vector3 = xf * v[idx[t + 1]]
				var c: Vector3 = xf * v[idx[t + 2]]
				if _inside(a, frame, shell, l1) and _inside(b, frame, shell, l1) and _inside(c, frame, shell, l1):
					removed += 1
					changed = true
					continue
				keep.append(idx[t])
				keep.append(idx[t + 1])
				keep.append(idx[t + 2])
			arr[Mesh.ARRAY_INDEX] = keep
			out_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
			out_mesh.surface_set_material(out_mesh.get_surface_count() - 1, m.mesh.surface_get_material(s))
		if changed:
			m.mesh = out_mesh
	print("exterior_clip: %d of %d exterior triangles stood inside the rooms and were taken out" % [removed, examined])


func _inside(p: Vector3, frame: Node3D, shell, l1: float) -> bool:
	# the tower: inside the lining
	if p.y > 0.97 and p.y < 17.9:
		var d := Vector2(p.x - TOWER.x, p.z - TOWER.y)
		var th := rad_to_deg(atan2(d.y, d.x))
		var r: float = shell.wall_radius(p.y, fposmod(th, 360.0)) - MARGIN
		if d.length() < r and d.length() > 0.0:
			return true
	# the first floor: between the lining planes, from the floor up to the old ceiling's slopes
	var rx := p.x - HOUSE_O.x
	var rz := p.z - HOUSE_O.y
	var u := rx * cos(YAW) - rz * sin(YAW)
	var v := -(rx * sin(YAW) + rz * cos(YAW))
	if p.y > l1 + 0.05 and u > -3.0 + MARGIN and u < 5.39 - MARGIN and v > 0.95 + MARGIN and v < 8.7 - MARGIN:
		var rel := p.y - l1
		var ceil_rel := 1.45 + (v - 0.9) * (4.0 - 1.45) / (5.0 - 0.9) if v <= 5.0 else 4.0 - (v - 5.0) * (4.0 - 1.6) / (8.9 - 5.0)
		if rel < ceil_rel - 0.1:
			return true
	return false


