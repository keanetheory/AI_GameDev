# lantern.gd - the lamp room, redesigned (Lighthouse Interior Creator Agent, pass 3).
# The exterior model's lantern was a solid dark wall with the glazing painted on. The level already cuts the whole band
# away (Level.tscn, node Lighthouse); this builds what stands in the gap, in the lighthouse's own frame:
#   - a timber floor out to the glass and a low iron kerb round it, flush with the gallery deck outside (y 18.3);
#   - twelve slim iron mullions and one continuous pane of glass from the kerb to the lamp-room ceiling, so the player
#     looks out over the sea, the island, the cliffs and the Saltgate from every side;
#   - a plaster ceiling and a ring beam, covering the torn underside of the roof the cut left behind;
#   - the arc lamp: brass pedestal, burner bay, a Fresnel lens drum, a chimney; dark and cold until the burner is fitted;
#   - the burner socket (lamp_socket.gd): hold the burner, face the lamp, E, and the lamp lights (lamp_beacon.gd);
#   - the broken burner Ted took out, left on the floor.
# Measured on the exterior model: gallery deck top y 18.3 from radius 2.9 outward, roof underside 22.06 at radius 2.0
# and 22.5 at 2.5, no wall in the band at all (tools/probe_lantern.gd).
extends "res://scripts/world/interior/rooms_tower.gd"

const SocketScript := preload("res://scripts/world/interior/lamp_socket.gd")
const BeaconScript := preload("res://scripts/world/interior/lamp_beacon.gd")
const BROKEN_BURNER := "res://Assets/Models/prop/burner_broken.glb"

const FLOOR := 17.9
const DECK := 18.3
const CEIL_Y := 21.95
const GLASS_R := 2.82
const LAMP_Y := 19.45           # the burner seat (the anchors use this height)
const LAMP_SCALE := 2.9         # the 0.9 m generated lamp, scaled to 2.6 m
const LAMP_FACE_DEG := 215.0    # the bearing the burner bay faces: toward where the player stands (anchor lamp_stand)

var socket: Node3D
var beacon: Node3D


func build_lantern(kit, lh: Node3D) -> void:
	K = kit
	_lh = lh
	var P := Node3D.new()
	P.name = "LampRoom"
	lh.add_child(P)
	_shell(P)
	_gallery(P)
	_arc_lamp(P)
	_broken_burner(P)
	anchors_lh["lamp_socket"] = Vector3(TOWER.x, LAMP_Y, TOWER.y)
	anchors_lh["arc_lamp_socket"] = anchors_lh["lamp_socket"]      # the v3 marker sat inside the lamp bay; these replace it
	anchors_lh["burner_fit"] = anchors_lh["lamp_socket"]
	anchors_lh["lamp_stand"] = _pt(215.0, 1.65, FLOOR)
	refs["lamp_socket"] = socket
	refs["lamp_beacon"] = beacon


func _shell(P: Node3D) -> void:
	# floor out to the glass, and the kerb the glass stands on
	_arc(P, "Lamp_Floor", 2.07, 2.75, 0.0, 360.0, FLOOR - 0.3, FLOOR - 0.004, _ds("planks"), true)
	_arc(P, "Lamp_Kerb", 2.75, 2.95, 0.0, 360.0, FLOOR - 0.3, DECK, _ds("iron_dark"), true)
	_arc(P, "Lamp_KerbCap", 2.72, 2.9, 0.0, 360.0, DECK - 0.0, DECK + 0.05, _ds("brass"), false)
	# the stair opening's edge (the greybox gallery leaves the last turn of the spiral open): a rail, with a gap where
	# the stair arrives
	_rail(P, "Lamp_StairRail", FLOOR, 297.0, 507.0, [Vector2(128.0, 152.0)])
	# mullions and glass
	# the lantern from the sea (creator, 2026-10-25: the roof looked like it floated): twenty-four slim mullions instead of twelve, three glazing
	# rings, a heavy sill ring and head ring, and the glass itself is a visible pale-slate pane (it was 14% opaque, so the band read as empty sky)
	for i in 24:
		var a := 7.5 + 15.0 * i
		_cyl(P, "Lamp_Mullion_%d" % i, _pt(a, GLASS_R, DECK), _pt(a, GLASS_R, CEIL_Y), 0.045 if i % 2 == 0 else 0.03, _m("iron_dark"), false)
	_arc(P, "Lamp_SillRing", GLASS_R - 0.06, GLASS_R + 0.1, 0.0, 360.0, DECK, DECK + 0.16, _ds("iron_dark"), false)
	_arc(P, "Lamp_HeadRing", GLASS_R - 0.06, GLASS_R + 0.1, 0.0, 360.0, CEIL_Y - 0.2, CEIL_Y, _ds("iron_dark"), false)
	# the lantern's own glass: a darker, denser pane than a window's, so from the sea the band under the roof reads as a glazed drum and the roof
	# sits ON something (a window's pane is 30% opaque; this is 65%)
	var lg := (_m("glass") as StandardMaterial3D).duplicate() as StandardMaterial3D
	lg.albedo_color = Color(0.2, 0.27, 0.33, 0.65)
	var glass := _arc(P, "Lamp_Glass", GLASS_R - 0.012, GLASS_R + 0.012, 0.0, 360.0, DECK, CEIL_Y, lg, true)
	(glass.get_node("Body") as StaticBody3D).add_to_group("glass")      # solid for the player, invisible to sight tests
	for k in 3:
		var y := DECK + 0.9 + 0.95 * k
		_arc(P, "Lamp_Transom_%d" % k, GLASS_R - 0.03, GLASS_R + 0.05, 0.0, 360.0, y, y + 0.06, _ds("iron_dark"), false)
	# ceiling, ring beam and a hole for the lamp's chimney
	_arc(P, "Lamp_Ceiling", 0.2, 3.0, 0.0, 360.0, CEIL_Y, CEIL_Y + 0.14, _ds("plaster_dark"), false)
	_arc(P, "Lamp_RingBeam", 2.45, 3.02, 0.0, 360.0, CEIL_Y - 0.28, CEIL_Y + 0.14, _ds("iron_dark"), false)
	_arc(P, "Lamp_RingTrim", 2.4, 3.05, 0.0, 360.0, CEIL_Y - 0.34, CEIL_Y - 0.28, _ds("brass"), false)
	for i in 12:
		var a := 30.0 * i
		_cyl(P, "Lamp_Rafter_%d" % i, _pt(a, 0.55, CEIL_Y - 0.02), _pt(a, 2.5, CEIL_Y - 0.02), 0.04, _m("iron_dark"), false)
	# (no wall lamp here: the one that stood on the glass read as a floating bulb; the room is lit by the Lantern light and the arc lamp)


func _arc_lamp(P: Node3D) -> void:
	var cx := TOWER.x
	var cz := TOWER.y
	var c := Vector3(cx, 0.0, cz)
	var brass := _m("brass")
	var iron := _m("iron_dark")
	# a solid cylinder to bump into: the whole lamp is one column to the physics
	var sb := StaticBody3D.new()
	sb.name = "LampBody"
	sb.collision_layer = 1
	var cs := CollisionShape3D.new()
	var sh := CylinderShape3D.new()
	sh.radius = 0.85
	sh.height = 2.5
	cs.shape = sh
	sb.add_child(cs)
	sb.position = Vector3(cx, FLOOR + sh.height * 0.5, cz)
	P.add_child(sb)
	# the generated arc lamp (lhi_arc_lamp.glb): a pedestal with an arched burner bay at its foot, a Fresnel lens drum, a brass
	# gallery and a chimney cap. 2.6 m tall, turned so the bay faces the stair side of the room (bearing LAMP_FACE_DEG). Its
	# materials are darkened until the burner is fitted and lamp_beacon.gd brings them up with an emission.
	beacon = Node3D.new()
	beacon.name = "LampBeacon"
	beacon.position = Vector3(cx, 0.0, cz)
	beacon.set_script(BeaconScript)
	P.add_child(beacon)
	var face := deg_to_rad(LAMP_FACE_DEG)
	var ps := load("res://Assets/Models/prop/lhi_arc_lamp.glb") as PackedScene
	if ps:
		var lm := Node3D.new()
		lm.name = "LampModel"
		lm.position = Vector3(0, FLOOR, 0)
		lm.rotation.y = atan2(cos(face), sin(face))
		lm.scale = Vector3.ONE * LAMP_SCALE
		lm.add_child(ps.instantiate())
		beacon.add_child(lm)
	var lens_base := FLOOR + 0.95
	# the arc itself: a bright core among the lens bands, dark until lit
	var core_mat := StandardMaterial3D.new()
	core_mat.albedo_color = Color(1.0, 0.9, 0.66)
	core_mat.emission_enabled = true
	core_mat.emission = Color(1.0, 0.84, 0.5)
	core_mat.emission_energy_multiplier = 0.0
	var core := MeshInstance3D.new()
	core.name = "Core"
	var sm := SphereMesh.new()
	sm.radius = 0.16
	sm.height = 0.32
	core.mesh = sm
	core.material_override = core_mat
	core.position = Vector3(0, lens_base + 0.7, 0)
	core.visible = false
	beacon.add_child(core)
	var glow := OmniLight3D.new()
	glow.name = "Glow"
	glow.position = Vector3(0, lens_base + 0.7, 0)
	glow.light_color = Color(1.0, 0.84, 0.5)
	glow.light_energy = 0.0
	glow.omni_range = 16.0
	glow.visible = false
	beacon.add_child(glow)
	# the sweeping beam: a long cone and a spot light, turning with the lamp
	var pivot := Node3D.new()
	pivot.name = "BeamPivot"
	pivot.position = Vector3(0, lens_base + 0.7, 0)
	pivot.visible = false
	beacon.add_child(pivot)
	var beam := MeshInstance3D.new()
	beam.name = "Beam"
	var cm := CylinderMesh.new()
	cm.top_radius = 0.3
	cm.bottom_radius = 5.0
	cm.height = 70.0
	cm.radial_segments = 20
	cm.rings = 1
	cm.cap_top = false
	cm.cap_bottom = false
	beam.mesh = cm
	var bm := ShaderMaterial.new()
	var beam_shader := Shader.new()
	# a soft cone: bright at the lamp, fading to nothing at the far mouth, added to the picture, never writing depth
	beam_shader.code = """shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, fog_disabled;
uniform float strength = 0.0;
uniform vec3 tint = vec3(1.0, 0.84, 0.5);
void fragment() {
	float along = 1.0 - UV.y;                                  // 1 at the lamp, 0 at the far mouth
	// soft edges: bright where the cone faces the eye, fading to nothing at its silhouette (no hard capsule outline)
	float face = pow(clamp(abs(dot(normalize(NORMAL), normalize(VIEW))), 0.0, 1.0), 1.6);
	float fade_end = smoothstep(0.0, 0.5, along);              // the far mouth dissolves; no disc at the end
	ALBEDO = tint * strength * pow(along, 1.3) * face * fade_end;
}
"""
	bm.shader = beam_shader
	beam.material_override = bm
	beam.rotation.z = deg_to_rad(90.0)
	beam.position = Vector3(35.0, 0, 0)
	pivot.add_child(beam)
	var spot := SpotLight3D.new()
	spot.name = "Spot"
	spot.rotation.y = deg_to_rad(-90.0)
	spot.spot_range = 90.0
	spot.spot_angle = 11.0
	spot.light_color = Color(1.0, 0.84, 0.5)
	spot.light_energy = 0.0
	spot.shadow_enabled = false
	pivot.add_child(spot)
	# the burner socket: where E fits the burner
	socket = Node3D.new()
	socket.name = "LampSocket"
	socket.set_script(SocketScript)
	socket.position = Vector3(cx + cos(face) * 0.78, FLOOR + 0.42, cz + sin(face) * 0.78)      # in the mouth of the lamp's burner bay
	socket.set("mount_offset", Vector3(0, 0.0, 0))
	socket.set("mount_rotation_deg", Vector3(0.0, rad_to_deg(atan2(cos(face), sin(face))), 0.0))
	P.add_child(socket)
	beacon.setup()
	socket.set("beacon_path", socket.get_path_to(beacon))
	K.count += 20


## The broken burner Ted took out, on the floor by the glass (the story's diagnosis, TED_S3).
func _broken_burner(P: Node3D) -> void:
	var ps := load(BROKEN_BURNER) as PackedScene
	if ps == null:
		return
	var n := ps.instantiate() as Node3D
	n.name = "BrokenBurner"
	var pos := _pt(262.0, 2.3, FLOOR)
	n.position = pos + Vector3(0, 0.1, 0)
	n.rotation = Vector3(deg_to_rad(-90.0), deg_to_rad(40.0), 0.0)
	n.scale = Vector3.ONE * 0.55
	P.add_child(n)
	_cyl(P, "BrokenBurnerCloth", pos + Vector3(0, 0.0, 0), pos + Vector3(0, 0.02, 0), 0.5, _m("canvas"), false)


## The gallery balustrade (LHF-13): the exterior model's rail was a ring of lumpy posts, now carved away (Level.tscn, carve_cylinders). In
## its place: sixteen iron newel posts with brass caps, a brass handrail, a mid rail, and a ring of slim balusters (one MultiMesh, so
## 120 rods cost one draw call). Visual only: nobody walks out there, the glass is sealed.
const GAL_R := 3.9
const GAL_TOP := 19.38

func _gallery(P: Node3D) -> void:
	var iron := _m("iron_dark")
	var brass := _m("brass")
	var G := Node3D.new()
	G.name = "Gallery"
	P.add_child(G)
	for i in 16:
		var a := 22.5 * i
		_cyl(G, "GalPost_%d" % i, _pt(a, GAL_R, DECK), _pt(a, GAL_R, GAL_TOP), 0.045, iron, false)
		_cyl(G, "GalCap_%d" % i, _pt(a, GAL_R, GAL_TOP), _pt(a, GAL_R, GAL_TOP + 0.07), 0.065, brass, false)
		var ball := MeshInstance3D.new()
		ball.name = "GalFinial_%d" % i
		var sm := SphereMesh.new()
		sm.radius = 0.055
		sm.height = 0.11
		ball.mesh = sm
		ball.material_override = brass
		ball.position = _pt(a, GAL_R, GAL_TOP + 0.12)
		G.add_child(ball)
	_arc(G, "GalHandrail", GAL_R - 0.04, GAL_R + 0.04, 0.0, 360.0, GAL_TOP - 0.03, GAL_TOP + 0.03, brass, false)
	_arc(G, "GalMidRail", GAL_R - 0.02, GAL_R + 0.02, 0.0, 360.0, DECK + 0.45, DECK + 0.49, iron, false)
	_arc(G, "GalToeBoard", GAL_R - 0.03, GAL_R + 0.05, 0.0, 360.0, DECK, DECK + 0.12, iron, false)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var rod := CylinderMesh.new()
	rod.top_radius = 0.014
	rod.bottom_radius = 0.014
	rod.height = GAL_TOP - DECK - 0.1
	rod.radial_segments = 6
	rod.rings = 1
	mm.mesh = rod
	var n := 120
	mm.instance_count = n
	for i in n:
		var a2 := 360.0 * float(i) / float(n) + 1.5
		mm.set_instance_transform(i, Transform3D(Basis.IDENTITY, _pt(a2, GAL_R, DECK + 0.1 + rod.height * 0.5)))
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "GalBalusters"
	mmi.multimesh = mm
	mmi.material_override = iron
	G.add_child(mmi)
	K.count += 4
