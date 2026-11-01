# exterior_clip.gd - takes the parts of the generated exterior mesh that stand INSIDE the rooms out of the exterior (creator, 2026-10-26: "island mesh jutting through
# the L2 floor", "island meshes coming through on the stairwell", the orange chimney breast showing in the kitchen).
# The exterior is one scanned mesh with the old stair, chimney breasts, rafters and wall remnants still inside it; the interior is built as its own layer on top, so any
# exterior triangle that lies entirely inside a room's air volume is a stray: it shows through the lining or pokes through a floor. Triangles of the exterior's own walls and
# roof are never inside the volumes (the lining stands in front of the wall, the ceiling below the roof), so removing the strays loses nothing the outside shows.
# Volumes: the tower's lining (radius from the lining itself, tower_shell.gd wall_radius, less a margin) from the ground-floor ring to the lamp room floor, and the first
# floor between its lining planes under the old ceiling (rooms_tower.gd _ceiling's two slopes, less a margin). Runs once, when the interior is built.
# In the tower a triangle that only partly stands inside the lining is a stray too when none of it reaches out to the real wall (all of it within TOWER_REACH
# of the lining): those are the old inner wall pieces whose corners showed through the stairwell (T47, 1 Nov 2026; the outer wall is 0.7 m and more out).
extends Node

const MARGIN := 0.06
const TOWER_REACH := 0.7
const STRAY_DEPTH := 0.0       # any corner (or edge middle) in front of the lining: a sliver flush with it still shows through at a grazing angle
const TOWER := Vector2(3.5, 3.6)
const HOUSE_O := Vector2(-3.494, 8.874)      # the house frame in the Lighthouse frame (interior_rooms.gd DOOR_SILL, YAW)
const YAW := 0.4457

var removed := 0
var examined := 0


## `lh` the Lighthouse node, `frame` the house frame, `shell` the tower shell (wall_radius), `l1` the first floor's height.
func apply(lh: Node3D, frame: Node3D, shell, l1: float) -> void:
	# the scan's "convert" node: directly under the Lighthouse for v3, one level down (lighthouse_exterior_v4/convert) for the repaired v4. It looked only
	# directly under, so since the v4 swap nothing was clipped (T47, 1 Nov 2026)
	var cv := lh.find_child("convert", true, false)
	if cv == null:
		push_warning("exterior_clip: no 'convert' node under the Lighthouse: nothing clipped")
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
				var da := _tower_depth(a, shell)
				var db := _tower_depth(b, shell)
				var dc := _tower_depth(c, shell)
				# a flat triangle across the curved lining can dip inside between corners that are all outside it: test the edges' middles and the centre too
				var deepest := maxf(maxf(da, maxf(db, dc)), maxf(maxf(_tower_depth((a + b) * 0.5, shell), _tower_depth((b + c) * 0.5, shell)),
						maxf(_tower_depth((c + a) * 0.5, shell), _tower_depth((a + b + c) / 3.0, shell))))
				if deepest > STRAY_DEPTH and minf(da, minf(db, dc)) > -TOWER_REACH:
					removed += 1      # pokes into the stairwell and reaches nowhere near the outer wall
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
			m.set_meta("clipped_after_build", true)      # tools/test_collider_bake.gd compares its collision, not its triangles
	print("exterior_clip: %d of %d exterior triangles stood inside the rooms and were taken out" % [removed, examined])


## How far p stands inside the tower's lining (negative: outside it), or -INF above or below the lining.
func _tower_depth(p: Vector3, shell) -> float:
	if p.y <= 0.97 or p.y >= 17.9:
		return -INF
	var d := Vector2(p.x - TOWER.x, p.z - TOWER.y)
	return float(shell.wall_radius(p.y, fposmod(rad_to_deg(atan2(d.y, d.x)), 360.0))) - d.length()


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
		var ceil_rel := 1.72 + (v - 0.9) * (4.0 - 1.72) / (5.0 - 0.9) if v <= 5.0 else 4.0 - (v - 5.0) * (4.0 - 1.6) / (8.9 - 5.0)
		if rel < ceil_rel - 0.1:
			return true
	return false


