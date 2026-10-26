# interior_culling.gd - draws only the part of the house the player can see (Lighthouse Finisher Agent, LHF-06).
# The house has three levels (basement, ground floor, first floor) of about 1,200 meshes. Wherever you stand, one level or two are in
# view: the floor and ceiling hide the rest. This hides the others, with these rules (the house is only culled while the camera is
# inside its footprint, and the tower, the stair and the lamp room are never touched):
#   - on the ground floor you see the ground floor and, down the stairwell, the basement; not the first floor;
#   - in the basement you see the basement and, up the stairwell, the ground floor; not the first floor;
#   - on the first floor you see the first floor; not the ground floor or the basement;
#   - outside, everything inside range stays drawn (windows look into the rooms), and every interior mesh stops being drawn beyond
#     `far_m` so the lighthouse seen from the sea or the island does not pay for its furniture.
# Checked twice a second, with a margin so a step on a stair does not flip a level. Visual only: nothing here touches collision.
extends Node

const GF_Y := 10.58                  # ground floor, world
const L1_SLAB_Y := 13.5                # world height of the underside of the first floor slab (house frame 3.9): ground-floor ceiling stuff is below it
const L1_Y := 14.8                  # first floor, world
const HOUSE_U := Vector2(-3.3, 5.35)
const HOUSE_V := Vector2(0.2, 9.3)

@export var rooms_path := NodePath("../InteriorRooms")
@export var far_m := 34.0
@export var margin := 0.6
## Off: every level always drawn (triage switch; also LHF_NO_CULL=1 in the environment).
@export var enabled := true

var levels := {0: [], 1: [], 2: []}     # 0 basement, 1 ground, 2 first floor: the meshes of each
var shown := {0: true, 1: true, 2: true}
var culled_meshes := 0                   # how many meshes are hidden right now (for tests)
var inside := false

var _frame: Node3D
var _t := 0.0
var _built := false


func _ready() -> void:
	_build.call_deferred()


func _build() -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame
	var rooms := get_node_or_null(rooms_path)
	if rooms == null or rooms.get("frame") == null:
		return
	_frame = rooms.frame
	for n in rooms.find_children("*", "GeometryInstance3D", true, false):
		var g := n as GeometryInstance3D
		var c := g.global_position
		if g is MeshInstance3D and (g as MeshInstance3D).mesh:
			c = g.global_transform * (g as MeshInstance3D).mesh.get_aabb().get_center()
		var path := String(g.get_path())
		if c.y > 21.0 or path.contains("/LampRoom/") or path.contains("/TowerShell/") or path.contains("/SpiralDown/") or path.contains("/BeamPivot/"):
			# above the house roof, the stair, the tower lining and the beacon's beam are seen from everywhere. They get NO visibility range: it used to be set
			# before this test, and Godot measures it from the node's origin, so the beam (whose origin is 35 m out along its length) vanished whenever it
			# swept away from the viewer, "going out" for most of every turn (creator, 2026-10-26)
			continue
		g.visibility_range_end = far_m
		g.visibility_range_end_margin = 4.0
		g.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED
		var p := _frame.to_local(c)
		var u := p.x
		var v := -p.z
		if u < HOUSE_U.x or u > HOUSE_U.y or v < HOUSE_V.x or v > HOUSE_V.y:
			continue                      # the tower, the stair and the lamp room are never culled
		# a mesh belongs to the level it STANDS on: its bottom edge decides, not its centre (the first floor's slab is 1.25 m thick and its centre
		# sits under the first floor's own surface, which filed it under the ground floor and hid the floor you were standing on)
		var bottom := c.y
		if g is MeshInstance3D and (g as MeshInstance3D).mesh:
			bottom = (g.global_transform * (g as MeshInstance3D).mesh.get_aabb()).position.y
		var lvl := 0 if bottom < GF_Y - 0.2 else (1 if bottom < L1_SLAB_Y else 2)
		levels[lvl].append(g)
	_built = true


func _process(delta: float) -> void:
	if not _built:
		return
	_t += delta
	if _t < 0.5:
		return
	_t = 0.0
	apply()


func apply() -> void:
	if OS.get_environment("LHF_NO_CULL") == "1":
		enabled = false
	var cam := get_viewport().get_camera_3d()
	var want := {0: true, 1: true, 2: true}
	inside = false
	if enabled and cam != null and _frame != null:
		var p := _frame.to_local(cam.global_position)
		var u := p.x
		var v := -p.z
		inside = u > HOUSE_U.x and u < HOUSE_U.y and v > HOUSE_V.x and v < HOUSE_V.y
		if inside:
			var y := cam.global_position.y
			if y > L1_Y - margin:               # on the first floor: only the first floor
				want = {0: false, 1: false, 2: true}
			elif y > GF_Y - margin:             # on the ground floor: down the stairwell, the basement
				want = {0: true, 1: true, 2: false}
			else:                               # in the basement: up the stairwell, the ground floor
				want = {0: true, 1: true, 2: false}
	culled_meshes = 0
	for l in levels:
		if want[l] != shown[l]:
			shown[l] = want[l]
			for g in levels[l]:
				if is_instance_valid(g):
					g.visible = want[l]
		if not want[l]:
			culled_meshes += levels[l].size()
