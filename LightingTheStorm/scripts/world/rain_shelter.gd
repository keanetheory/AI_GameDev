# rain_shelter.gd - keeps the rain out of the lighthouse (Lighthouse Finisher Agent, LHF-03; reworked in the lighthouse finish).
# The rain's height field only knows the top surface under the camera, and GPU particle collision hides a drop a frame or two AFTER
# it enters a collider (up to about 0.9 m at the rain's speed: tools/probe_rain_heightfield.gd), so drops were still drawn in the
# attic, the lamp-room dome and the roof cavity. This node now only DESCRIBES the interior air: boxes (turned about the vertical axis)
# that fill the house, the tower stairwell and the lamp room. LightingRig hands them to the rain and splash material
# (scripts/world/rain_streak.gdshader), which discards every fragment inside one at draw time, so no drop is ever drawn indoors
# whatever the frame rate. The old GPUParticlesCollisionBox3D nodes are gone: they added the latency and threw splash specks off their
# invisible tops. Windows and the open door are in the walls, which the boxes stay inside of, so rain is still seen outside them.
# Put one node of this script in Level.tscn after InteriorRooms (before LightingRig). Needs the Lighthouse node and InteriorRooms.
# Guards: tools/test_rain_cover.gd (CPU: every interior air point is inside a box) and tools/probe_rain_render.gd (GPU frames).
extends Node3D

## The house in its own frame (kit.gd: u along the front wall, v inward, y absolute model height), inset from the walls.
const HOUSE_U := Vector2(-2.9, 5.4)
const HOUSE_V := Vector2(1.0, 8.9)
const HOUSE_Y := Vector2(-2.0, 12.4)      # up through the roof cavity: the ceiling/roof underside over the first floor measures 5 to 10.0, and 11 to 12.2 where the exterior roof has holes (tools/test_rain_cover.gd). The old top of 8.9 left drops drawn under the ridge (tools/probe_rain_render.gd)
## The tower in the Lighthouse node's frame: the stairwell and ring up to the lantern floor, then the lantern room inside its glass.
const TOWER := Vector2(3.5, 3.6)
const STAIR_R := 3.15         # radius of the stairwell volume: eight bars through the axis, 22.5 degrees apart, cover the whole circle (three squares left pockets at the L2 ring)
const STAIR_Y := Vector2(0.97, 17.9)
const LANTERN_R := 2.84       # the lantern glass stands at 2.82 (lantern.gd GLASS_R): a smaller radius left a ring of rain between the volume and the glass
const LANTERN_Y := Vector2(17.9, 25.3)       # up through the lantern cap (its apex is 25.18): the air under the dome is inside too

var volumes: Array = []       # [{xf: Transform3D (global), size: Vector3}] for tools/test_rain_shelter.gd


func _ready() -> void:
	var rooms := get_node_or_null("../InteriorRooms")
	var frame: Node3D = rooms.get("frame") if rooms else null
	if frame:
		var c := Vector3((HOUSE_U.x + HOUSE_U.y) * 0.5, (HOUSE_Y.x + HOUSE_Y.y) * 0.5, -(HOUSE_V.x + HOUSE_V.y) * 0.5)   # kit.gd p(): z = -v
		var s := Vector3(HOUSE_U.y - HOUSE_U.x, HOUSE_Y.y - HOUSE_Y.x, HOUSE_V.y - HOUSE_V.x)
		_add(frame, "House", Transform3D(Basis.IDENTITY, c), s)
	var lh := get_node_or_null("../Lighthouse") as Node3D
	if lh:
		for ring in [[STAIR_R, STAIR_Y, "Stair"], [LANTERN_R, LANTERN_Y, "Lantern"]]:
			var rr: float = ring[0]
			var y: Vector2 = ring[1]
			# a bar of length 2R and width 2R*tan(11.25 deg) through the axis, eight of them 22.5 degrees apart: any point within R of the axis lies
			# within (R * sin 11.25) of some bar's centre line, so the union covers the whole circle
			var wbar := 2.0 * rr * tan(deg_to_rad(11.25)) * 1.05
			for k in 8:
				var b := Basis(Vector3.UP, deg_to_rad(22.5 * k))
				_add(lh, "%s%d" % [ring[2], k], Transform3D(b, Vector3(TOWER.x, (y.x + y.y) * 0.5, TOWER.y)), Vector3(2.0 * rr, y.y - y.x, wbar))


func _add(parent: Node3D, nm: String, local: Transform3D, size: Vector3) -> void:
	volumes.append({"xf": parent.global_transform * local, "size": size, "name": nm})


## True if a world point is inside one of the shelter boxes.
func covers(p: Vector3) -> bool:
	for v in volumes:
		var q: Vector3 = (v["xf"] as Transform3D).affine_inverse() * p
		var h: Vector3 = (v["size"] as Vector3) * 0.5
		if absf(q.x) <= h.x and absf(q.y) <= h.y and absf(q.z) <= h.z:
			return true
	return false
