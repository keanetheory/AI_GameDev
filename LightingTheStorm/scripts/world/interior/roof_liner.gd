# roof_liner.gd - gives the first floor a ceiling of its own (Lighthouse Finisher Agent, LHF-02).
# The attic rooms (L1) had no ceiling: you looked up at the exterior model's roof, wearing the exterior's weathered texture. This
# samples the roof's real underside with rays (a grid over the first floor, once the exterior's collision exists) and hangs a
# plaster liner 2 cm below it, so the interior is lined by interior geometry. Visual only, no collision; the beams the rooms
# already hang from the roof stay in front of it.
extends Node3D

const Kit := preload("res://scripts/world/interior/kit.gd")

const U := Vector2(-2.7, 5.2)        # the first floor's footprint, in the house frame, inset from the walls
const V := Vector2(1.1, 8.8)
const STEP := 0.25
const FROM_Y := 5.3                  # just above the first floor
const REACH := 7.0
const GAP := 0.02                    # the liner hangs this far under the roof
const MAX_JUMP := 0.7                # a bigger step between neighbours is a wall or the stairwell, not the roof

var frame: Node3D
var material: Material
var hit_cells := 0
var built := false


func build(f: Node3D, mat: Material) -> void:
	frame = f
	material = mat
	_build_later()


func _build_later() -> void:
	# the exterior's trimesh collision is made in its _ready and joins the physics space a frame or two later
	await get_tree().physics_frame
	await get_tree().physics_frame
	var lh := get_node_or_null("../../Lighthouse")
	if lh == null or frame == null:
		return
	var space := frame.get_world_3d().direct_space_state
	var nu := int(round((U.y - U.x) / STEP)) + 1
	var nv := int(round((V.y - V.x) / STEP)) + 1
	var ys := PackedFloat32Array()
	ys.resize(nu * nv)
	for j in nv:
		for i in nu:
			var u := U.x + i * STEP
			var v := V.x + j * STEP
			var a := frame.to_global(Kit.p(u, FROM_Y, v))
			var q := PhysicsRayQueryParameters3D.create(a, a + Vector3(0, REACH, 0))
			q.collision_mask = 1
			var r := space.intersect_ray(q)
			var y := NAN
			if not r.is_empty() and lh.is_ancestor_of(r["collider"]):
				y = frame.to_local(r["position"]).y - GAP
				hit_cells += 1
			ys[j * nu + i] = y
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_normal(Vector3.DOWN)
	for j in nv - 1:
		for i in nu - 1:
			var c := [ys[j * nu + i], ys[j * nu + i + 1], ys[(j + 1) * nu + i + 1], ys[(j + 1) * nu + i]]
			var ok := true
			for k in 4:
				if is_nan(c[k]) or absf(c[k] - c[0]) > MAX_JUMP:
					ok = false
			if not ok:
				continue
			var pts := [
				Kit.p(U.x + i * STEP, c[0], V.x + j * STEP), Kit.p(U.x + (i + 1) * STEP, c[1], V.x + j * STEP),
				Kit.p(U.x + (i + 1) * STEP, c[2], V.x + (j + 1) * STEP), Kit.p(U.x + i * STEP, c[3], V.x + (j + 1) * STEP)]
			for t in [0, 1, 2, 0, 2, 3]:
				st.add_vertex(pts[t])
	var mesh := st.commit()
	if mesh == null or mesh.get_surface_count() == 0:
		push_warning("roof_liner: no roof found above the first floor")
		return
	var mi := MeshInstance3D.new()
	mi.name = "L1_CeilingLiner"
	mi.mesh = mesh
	var m := (material as StandardMaterial3D).duplicate() as StandardMaterial3D
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	frame.add_child(mi)
	built = true
