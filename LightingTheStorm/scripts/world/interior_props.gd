# interior_props.gd - the small physical pieces the lighthouse openings need (Lighthouse Interior Creator Agent).
# The exterior model has no real windows: its panes are painted on or modelled solid. The level carves openings
# (Level.tscn, node Lighthouse: carve_oriented and carve_cylinders). This script gives those openings what they need:
#   - a frame around the ground-floor window and the tower landing window, hiding the cut's ragged edge;
#   - eight slim posts holding the lantern roof up (the glass band was cut away) and faint glass panes between them;
#   - a "glass" barrier across the tower window so nobody walks or jumps out of it and falls 25 m. It is solid for the
#     player but is tagged group "glass": sight tests and Ted's view ignore it, as eyes do.
# Everything is greybox: plain dark materials, boxes. Positions come from the carve boxes' maths; see tools/test_sightlines.gd.
extends Node3D

const AXIS := Vector3(8.5, 0.0, -4.9)           # the tower's and lamp's axis in the world
const LANTERN_Y := Vector2(28.0, 31.5)           # the cut glass band
const POST_R := 2.62
const WOOD := Color(0.17, 0.11, 0.075)
const IRON := Color(0.06, 0.06, 0.07)

var _wood: StandardMaterial3D
var _iron: StandardMaterial3D
var _glass: StandardMaterial3D


func _ready() -> void:
	_wood = _mat(WOOD, 0.9, 0.0)
	_iron = _mat(IRON, 0.55, 0.6)
	_glass = StandardMaterial3D.new()
	_glass.albedo_color = Color(0.55, 0.7, 0.8, 0.07)
	_glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_glass.roughness = 0.05
	_glass.metallic = 0.3
	_glass.cull_mode = BaseMaterial3D.CULL_DISABLED
	# ground-floor window beside the door: a 1.2 x 1.45 opening, centre (-3.302, 12.2, -0.657), wall along (0.4309, 0, 0.9024)
	# (the wooden frame that stood here floated off the wall: the ground window now gets a measured stone surround from exterior_openings.gd)
	# tower landing window: a 1.0 x 1.8 opening at bearing -57 degrees, 2.85 m from the axis, centre y 24.7
	var az := deg_to_rad(-57.0)
	var tc := AXIS + Vector3(sin(az) * 2.85, 24.7, cos(az) * 2.85)
	# (the wooden frame that stood here is gone: the window is dressed by tower_shell.gd inside and exterior_openings.gd outside)
	_barrier(AXIS + Vector3(sin(az) * 2.3, 24.7, cos(az) * 2.3), az, 1.4, 2.4)
	# the lamp room's glass, mullions and ceiling are built by interior/lantern.gd (interior_rooms.gd) now


func _mat(c: Color, rough: float, metal: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	return m


## A box with collision, rotated about Y so its local x runs along the wall.
func _box(parent: Node3D, pos: Vector3, yaw: float, size: Vector3, mat: Material, solid := true) -> Node3D:
	var n := Node3D.new()
	n.position = pos
	n.rotation.y = yaw
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	n.add_child(mi)
	if solid:
		var sb := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = size
		cs.shape = sh
		sb.add_child(cs)
		n.add_child(sb)
	parent.add_child(n)
	return n


## Four bars round an opening of `w` x `h` centred at `c`; `yaw` turns local x along the wall.
func _frame(c: Vector3, yaw: float, w: float, h: float, depth: float, nm: String) -> void:
	var root_n := Node3D.new()
	root_n.name = nm
	add_child(root_n)
	var t := 0.12
	var along := Vector3(cos(yaw), 0.0, -sin(yaw))
	_box(root_n, c + along * (w * 0.5 + t * 0.5), yaw, Vector3(t, h + 2.0 * t, depth), _wood)
	_box(root_n, c - along * (w * 0.5 + t * 0.5), yaw, Vector3(t, h + 2.0 * t, depth), _wood)
	_box(root_n, c + Vector3(0, h * 0.5 + t * 0.5, 0), yaw, Vector3(w + 2.0 * t, t, depth), _wood)
	_box(root_n, c - Vector3(0, h * 0.5 + t * 0.5, 0), yaw, Vector3(w + 2.0 * t, t, depth + 0.1), _wood)     # the sill sticks out a little


## An invisible-to-eyes wall across the window, on the inside of the opening, so the player cannot leave through it.
func _barrier(c: Vector3, yaw: float, w: float, h: float) -> void:
	var sb := StaticBody3D.new()
	sb.name = "TowerWindowGlass"
	sb.add_to_group("glass")
	sb.position = c
	sb.rotation.y = yaw
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(w, h, 0.1)
	cs.shape = sh
	sb.add_child(cs)
	add_child(sb)


func _lantern() -> void:
	var root_n := Node3D.new()
	root_n.name = "LanternPosts"
	add_child(root_n)
	var h := LANTERN_Y.y - LANTERN_Y.x
	var yc := (LANTERN_Y.x + LANTERN_Y.y) * 0.5
	for k in 8:
		var a := deg_to_rad(22.5 + 45.0 * k)
		var pos := AXIS + Vector3(sin(a) * POST_R, yc, cos(a) * POST_R)
		_box(root_n, pos, a, Vector3(0.18, h, 0.18), _iron)
		# a faint glass pane to the next post, so the lamp room still reads as glazed
		var b := deg_to_rad(45.0 * k)     # the middle of this panel
		var mid := AXIS + Vector3(sin(b) * POST_R * cos(deg_to_rad(22.5)), yc, cos(b) * POST_R * cos(deg_to_rad(22.5)))
		_box(root_n, mid, b, Vector3(2.0 * POST_R * sin(deg_to_rad(22.5)), h, 0.02), _glass, false)
