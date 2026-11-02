# island_lod.gd - keeps Bracken Isle cheap when it is seen from the sea and from the Saltgate (Island Creator, ISL-09).
# Measured on 2 Nov 2026 (tools/measure_island_cost.gd): from the Saltgate, 540 m off, the island was about 1,570 of the frame's 1,770
# draw calls, almost all of them small pieces a few pixels across or hidden inside the tower: the tower lining and the spiral stair
# (InteriorRooms/TowerShell, /SpiralDown), the interior greybox, the 71 planks of the door and the 135 pieces of the gate and its walls.
# This gives each of those a visibility range, so they stop being drawn beyond it; the rock, the rock patches, the harbour, the harbour
# stairs, the lighthouse shell and its window surrounds, the lamp room and its gallery, the beam, the lamp posts and every glowing thing
# (lamp heads, lit windows) keep none and are drawn at any distance, so the silhouette and the beacon are unchanged. (The lamp posts were
# tried at 150 m: hiding the post uncovered its glowing head, which its lantern had hidden from some angles, a visible change for a few
# draw calls, so they are left alone.)
# Only sets ranges on pieces that have none (interior_culling.gd's 34 m house ranges are left alone). Visual only: no collision changes.
# The rock's own cost is cut by LODs instead: collider_builder.gd keep_lods on the Island node puts LODs back on the carved mesh, and
# ROCK_LOD_BIAS below lets Godot use them at the distances the island is seen from the sea (at the default bias the coarsest LOD's
# error, about 2.5 m, is more than a pixel until about 1.5 km, so the full 185k triangles were drawn all the way to the Saltgate).
extends Node

## [node path from the level, range end in metres, fade]. Fade: the piece dissolves over the margin (outside pieces you could see
## going); no fade: it simply stops (pieces only seen through a window, where nobody can tell).
const GROUPS := [
	["InteriorRooms/TowerShell", 100.0, false],
	["InteriorRooms/SpiralDown", 100.0, false],
	["LighthouseInterior", 100.0, false],
	["LighthouseDoor", 150.0, true],
	["IslandGate", 150.0, true],
]
const MARGIN_M := 12.0
## lod_bias for the island rock's mesh (1 = Godot's default; lower uses the coarser LODs closer in). Chosen from measured stills: see
## GERFramework/reports/island_lod.md.
const ROCK_LOD_BIAS := 0.3
const ROCK := ["Island"]
## Nothing that reaches up into the lamp room is ever given a range (world height of the lamp room floor).
const LAMP_ROOM_Y := 27.0
## Paths that are never given a range, whatever group they are in.
const NEVER := ["/LampRoom/", "/BeamPivot/", "lighthouse_exterior"]

var ranged := 0                 # pieces given a range (for the tests)
var applied := false
var _frames_to_wait := 4


# Waits for the builders that make their pieces after the first physics frames (the lamp posts, the interior's culling).
func _ready() -> void:
	get_tree().physics_frame.connect(_on_physics_frame)


func _on_physics_frame() -> void:
	_frames_to_wait -= 1
	if _frames_to_wait > 0:
		return
	get_tree().physics_frame.disconnect(_on_physics_frame)
	apply()


func apply() -> void:
	var level := get_parent()
	for r in ROCK:
		var rock := level.get_node_or_null(r)
		if rock:
			for n in rock.find_children("*", "GeometryInstance3D", true, false):
				(n as GeometryInstance3D).lod_bias = ROCK_LOD_BIAS
	for grp in GROUPS:
		var root := level.get_node_or_null(grp[0])
		if root == null:
			continue
		for n in root.find_children("*", "GeometryInstance3D", true, false):
			var g := n as GeometryInstance3D
			if g.visibility_range_end > 0.0 or not _may_range(g):
				continue
			g.visibility_range_end = grp[1]
			g.visibility_range_end_margin = MARGIN_M
			g.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF if grp[2] \
					else GeometryInstance3D.VISIBILITY_RANGE_FADE_DISABLED
			ranged += 1
	applied = true


## May this piece stop being drawn at distance? Not the landmark (lamp room, beam, the lighthouse shell), not anything that glows.
static func may_range(g: GeometryInstance3D) -> bool:
	var path := String(g.get_path())
	for bit in NEVER:
		if path.contains(bit):
			return false
	if g is MeshInstance3D and (g as MeshInstance3D).mesh:
		var mi := g as MeshInstance3D
		if (mi.global_transform * mi.mesh.get_aabb()).end.y > LAMP_ROOM_Y:
			return false
		if _glows(mi.material_override):
			return false
		for s in mi.mesh.get_surface_count():
			if _glows(mi.get_active_material(s)):
				return false
	elif _glows(g.material_override):
		return false
	return true


func _may_range(g: GeometryInstance3D) -> bool:
	return may_range(g)


## Emission at or above this is a light (a lamp head, a lit window); below it is toon_look.gd's indoor fill (0.05), which is not.
const GLOW_ENERGY := 0.25


# Unshaded or really emissive (a lamp head, a lit window card) or a shader we cannot read: it may be a light seen from the sea, so keep it.
static func _glows(m: Material) -> bool:
	if m == null:
		return false
	if m is BaseMaterial3D:
		var b := m as BaseMaterial3D
		return (b.emission_enabled and b.emission_energy_multiplier >= GLOW_ENERGY) or b.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED
	return m is ShaderMaterial
