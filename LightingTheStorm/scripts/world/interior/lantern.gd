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
const LAMP_Y := 19.45           # the burner seat

var socket: Node3D
var beacon: Node3D


func build_lantern(kit, lh: Node3D) -> void:
	K = kit
	_lh = lh
	var P := Node3D.new()
	P.name = "LampRoom"
	lh.add_child(P)
	_shell(P)
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
	for i in 12:
		var a := 15.0 + 30.0 * i
		_cyl(P, "Lamp_Mullion_%d" % i, _pt(a, GLASS_R, DECK), _pt(a, GLASS_R, CEIL_Y), 0.05, _m("iron_dark"), false)
	var glass := _arc(P, "Lamp_Glass", GLASS_R - 0.012, GLASS_R + 0.012, 0.0, 360.0, DECK, CEIL_Y, _m("glass"), true)
	(glass.get_node("Body") as StaticBody3D).add_to_group("glass")      # solid for the player, invisible to sight tests
	for k in 2:
		var y := DECK + 1.2 + 1.2 * k
		_arc(P, "Lamp_Transom_%d" % k, GLASS_R - 0.03, GLASS_R + 0.05, 0.0, 360.0, y, y + 0.06, _ds("iron_dark"), false)
	# ceiling, ring beam and a hole for the lamp's chimney
	_arc(P, "Lamp_Ceiling", 0.2, 3.0, 0.0, 360.0, CEIL_Y, CEIL_Y + 0.14, _ds("plaster_dark"), false)
	_arc(P, "Lamp_RingBeam", 2.45, 3.02, 0.0, 360.0, CEIL_Y - 0.28, CEIL_Y + 0.14, _ds("iron_dark"), false)
	_arc(P, "Lamp_RingTrim", 2.4, 3.05, 0.0, 360.0, CEIL_Y - 0.34, CEIL_Y - 0.28, _ds("brass"), false)
	for i in 12:
		var a := 30.0 * i
		_cyl(P, "Lamp_Rafter_%d" % i, _pt(a, 0.55, CEIL_Y - 0.02), _pt(a, 2.5, CEIL_Y - 0.02), 0.04, _m("iron_dark"), false)
	# a lamp on the glass side of the room for the player to read the dark by
	_wall_lamp(P, "Lamp_RoomLamp", 235.0, 2.6, FLOOR + 1.2, 1.2)


func _arc_lamp(P: Node3D) -> void:
	var cx := TOWER.x
	var cz := TOWER.y
	var c := Vector3(cx, 0.0, cz)
	var brass := _m("brass")
	var iron := _m("iron_dark")
	_cyl(P, "Lamp_PedestalBase", c + Vector3(0, FLOOR, 0), c + Vector3(0, FLOOR + 0.22, 0), 0.62, brass, false)
	_cyl(P, "Lamp_PedestalColumn", c + Vector3(0, FLOOR + 0.22, 0), c + Vector3(0, FLOOR + 1.05, 0), 0.34, iron, false)
	_cyl(P, "Lamp_PedestalFlare", c + Vector3(0, FLOOR + 1.05, 0), c + Vector3(0, LAMP_Y - 0.1, 0), 0.58, brass, false)
	# the burner bay: a cage of brass bars round the seat, open on the player's side
	for i in 8:
		var a := 45.0 * i + 22.5
		_cyl(P, "Lamp_BayBar_%d" % i, _pt(a, 0.62, LAMP_Y - 0.1), _pt(a, 0.62, LAMP_Y + 0.5), 0.022, brass, false)
	_arc(P, "Lamp_BayRingLow", 0.58, 0.66, 0.0, 360.0, LAMP_Y - 0.12, LAMP_Y - 0.06, _ds("brass"), false)
	_arc(P, "Lamp_BayRingHigh", 0.58, 0.66, 0.0, 360.0, LAMP_Y + 0.46, LAMP_Y + 0.52, _ds("brass"), false)
	# a solid cylinder to bump into: the whole lamp is one 0.65 m column to the physics
	var sb := StaticBody3D.new()
	sb.name = "LampBody"
	sb.collision_layer = 1
	var cs := CollisionShape3D.new()
	var sh := CylinderShape3D.new()
	sh.radius = 0.62
	sh.height = LAMP_Y - FLOOR + 0.5
	cs.shape = sh
	sb.add_child(cs)
	sb.position = Vector3(cx, FLOOR + sh.height * 0.5, cz)
	P.add_child(sb)
	# the Fresnel lens drum above the bay: eight glass bands in brass rings (a "Lens" mesh lights up with the lamp)
	beacon = Node3D.new()
	beacon.name = "LampBeacon"
	beacon.position = Vector3(cx, 0.0, cz)
	beacon.set_script(BeaconScript)
	P.add_child(beacon)
	var lens_base := LAMP_Y + 0.55
	for i in 8:
		var y0 := lens_base + 0.2 * i
		var lm := StandardMaterial3D.new()
		lm.albedo_color = Color(0.7, 0.82, 0.85, 0.35)
		lm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		lm.roughness = 0.1
		lm.metallic = 0.3
		lm.cull_mode = BaseMaterial3D.CULL_DISABLED
		var rr := 0.78 + 0.12 * sin(float(i) / 7.0 * PI)
		var band := _cyl(beacon, "Lens_%d" % i, Vector3(0, y0, 0), Vector3(0, y0 + 0.17, 0), rr, lm, false)
		band.position = Vector3(0, y0 + 0.085, 0)
		_cyl(beacon, "LensRing_%d" % i, Vector3(0, y0 + 0.17, 0), Vector3(0, y0 + 0.2, 0), rr + 0.015, brass, false).position = Vector3(0, y0 + 0.185, 0)
	var top := lens_base + 1.6
	_cyl(beacon, "Lamp_Cap", Vector3(0, top, 0), Vector3(0, top + 0.18, 0), 0.62, brass, false).position = Vector3(0, top + 0.09, 0)
	_cyl(beacon, "Lamp_Chimney", Vector3(0, top + 0.18, 0), Vector3(0, CEIL_Y + 0.4, 0), 0.2, iron, false).position = Vector3(0, (top + 0.18 + CEIL_Y + 0.4) * 0.5, 0)
	# the arc itself: a bright core among the lens bands, dark until lit
	var core_mat := StandardMaterial3D.new()
	core_mat.albedo_color = Color(1.0, 0.95, 0.8)
	core_mat.emission_enabled = true
	core_mat.emission = Color(1.0, 0.9, 0.6)
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
	glow.light_color = Color(1.0, 0.88, 0.62)
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
void fragment() {
	float along = 1.0 - UV.y;
	ALBEDO = vec3(1.0, 0.9, 0.65) * strength * pow(along, 1.6);
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
	spot.light_color = Color(1.0, 0.9, 0.7)
	spot.light_energy = 0.0
	spot.shadow_enabled = false
	pivot.add_child(spot)
	# the burner socket: where E fits the burner
	socket = Node3D.new()
	socket.name = "LampSocket"
	socket.set_script(SocketScript)
	socket.position = Vector3(cx, LAMP_Y, cz)
	socket.set("mount_offset", Vector3(0, 0.0, 0))
	socket.set("mount_rotation_deg", Vector3(0.0, 0.0, 0.0))
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
