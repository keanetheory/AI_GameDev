# exterior_openings.gd - builds the opening kit (opening_kit.gd) on the outside of every window and the main door (LHF-12).
# The windows come from data/world/lighthouse_windows.json (five in the tower, three in the house); the door is the LighthouseDoor
# node. The exterior wall's real outer face is found with rays from outside, at two points beside each window (the opening itself
# is a hole), so the surround sits on the actual wall, not on a guess. Done a couple of physics frames after load, when the
# exterior's collision exists. Put one node of this script in Level.tscn after LighthouseWallDetail and InteriorRooms.
extends Node

const Kit := preload("res://scripts/world/opening_kit.gd")
const WINDOWS_JSON := "res://data/world/lighthouse_windows.json"
const TOWER := Vector2(3.5, 3.6)          # the tower's axis, in the Lighthouse node's frame
const HOUSE_WEST_U := -3.06               # kit.gd: the house frame's lining planes
const HOUSE_BACK_V := 8.7
const WALL_D := 1.05                      # the house wall's measured thickness behind the lining (see test_openings)
const L1_Y := 5.2025                      # the first floor (rooms_tower.gd L1)
const BELT_Y1 := 4.05                      # a continuous stone belt course from PATCH_Y0 up to here (covers the first-floor slab's edge wherever the wall is missing)
const PATCH_Y0 := 3.3                      # the patch starts here, just above the ground-floor wall: the hole in the wall reaches down to the first-floor slab's underside (3.95)
const CELL := 0.5

@export var door_path := NodePath("../LighthouseDoor")
@export var lighthouse_path := NodePath("../Lighthouse")
@export var rooms_path := NodePath("../InteriorRooms")
@export var wall_detail_path := NodePath("../LighthouseWallDetail")

var surrounds := {}                        # opening id -> the Node3D of its surround
var distances := {}                        # opening id -> measured distance of the outer face (house: from the lining plane)
var fallback := []                        # windows whose own face rays found nothing (the wall is missing there): placed on the wall's measured plane
var wall_d := {}                           # wall -> measured thickness behind the lining
var patched_cells := 0                     # cells of missing exterior wall closed with masonry
var attempts := {}                         # window id -> what each ray attempt hit (for the test's report)
var tower_radii := {}                      # window id -> [y, measured outer radius]
var missed := []                           # ids whose outer wall face was not found
var built := false
var wall_stone: Material                   # masonry for patches and the facade: the colour of the baked wall
var facade: Node3D                          # the front facade round the main door


func _ready() -> void:
	_build.call_deferred()


func _build() -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame
	var lh := get_node_or_null(lighthouse_path) as Node3D
	var rooms := get_node_or_null(rooms_path)
	var det := get_node_or_null(wall_detail_path)
	if lh == null:
		return
	var stone: Material = det.flat_material() if det and det.has_method("flat_material") else _fallback_stone()
	wall_stone = det.flat_material(Color(0.33, 0.26, 0.2)) if det and det.has_method("flat_material") else stone      # the patches and the facade match the old wall's dark baked stone
	var iron := _plain(Color(0.07, 0.075, 0.09), 0.6)
	var glass := _plain(Color(0.35, 0.22, 0.1), 0.3)
	glass.emission_enabled = true                     # the fanlight over the door is lit from the hall: warm amber, not a dark hole (creator, 2026-10-25)
	glass.emission = Color(1.0, 0.62, 0.28)
	glass.emission_energy_multiplier = 0.9
	glass.cull_mode = BaseMaterial3D.CULL_DISABLED      # the fanlight's triangles face inward: from outside it was culled and only the spokes showed (creator, "missing textures over the door")
	var space := lh.get_world_3d().direct_space_state
	var wins := _windows()
	var repaired: bool = lh.get("_repaired") == true      # the repaired exterior (v4) has no holes: no masonry plates over them, no facade panels
	if rooms != null and rooms.get("frame") != null and OS.get_environment("LHF_NO_PATCH") != "1" and not repaired:
		_house_walls(rooms.frame, lh, space, wall_stone, wins)
	for w in wins:
		if w["kind"] == "tower":
			_tower_window(lh, space, w, stone)
		elif rooms != null and rooms.get("frame") != null:
			_house_window(rooms.frame, lh, space, w, stone)
	var door := get_node_or_null(door_path) as Node3D
	if door:
		var holder := Node3D.new()
		holder.name = "LighthouseDoor_Kit"
		add_child(holder)
		var dw := float(door.get("width"))
		var centre: Vector3 = door.to_global(Vector3(dw * 0.5, 0.0, 0.0))
		var out: Vector3 = door.global_transform.basis.z
		var side: Vector3 = door.global_transform.basis.x
		# the door sits back in a thick arched wall: find the wall's real outer face beside it, at about hip height
		var ds := []
		for sgn in [-1.0, 1.0]:
			var o: Vector3 = centre + side * (dw * 0.5 + 0.8) * sgn + Vector3.UP * 1.0
			var hit := _hit(space, lh, o + out * 3.0, o - out * 1.0)
			if hit != Vector3.INF:
				ds.append((hit - centre).dot(out))
		var dd := 0.0
		if not ds.is_empty():
			dd = clampf((ds[0] + ds[-1]) * 0.5, 0.0, 1.2)
			distances["door"] = dd
		else:
			fallback.append("door")
		holder.global_transform = Transform3D(door.global_transform.basis, centre + out * dd)
		surrounds["door"] = Kit.door(holder, "Door", dw, float(door.get("height")), stone, iron, glass)
		if rooms != null and rooms.get("frame") != null and OS.get_environment("LHF_NO_FACADE") != "1" and not repaired:
			_front_facade(rooms.frame, wall_stone, dd)
	built = true


## Windows that are baked carves in Level.tscn rather than entries in lighthouse_windows.json: the kit still dresses them.
## house frame (u, y, v): the ground-floor window over the dock, on the west wall at v 3.0.
const EXTRA_WINDOWS := [{"id": "T_landing_147", "kind": "tower", "bearing": 147.0, "y": 15.09, "w": 1.0, "h": 1.8}]      # (the ground-floor carve at world (-3.3, 12.2, -0.66) is on a recessed wall and is NOT the arched window beside the door: left undressed)


func _windows() -> Array:
	var f := FileAccess.open(WINDOWS_JSON, FileAccess.READ)
	if f == null:
		return []
	var out: Array = (JSON.parse_string(f.get_as_text()) as Dictionary).get("windows", [])
	out.append_array(EXTRA_WINDOWS)
	return out


## First hit on the exterior model along a ray from `from` to `to` (world). Returns INF when nothing of the lighthouse is hit.
## Like _hit, but only a surface that faces the ray counts (a front face). Where the outer face of the wall is missing, a ray from outside meets
## the INSIDE of the wall (a back face): that is a hole, not a wall.
func _hit_front(space: PhysicsDirectSpaceState3D, lh: Node, from: Vector3, to: Vector3) -> Vector3:
	var q := PhysicsRayQueryParameters3D.create(from, to)
	q.collision_mask = 1
	q.hit_back_faces = true
	var r := space.intersect_ray(q)
	if r.is_empty() or not lh.is_ancestor_of(r["collider"]):
		return Vector3.INF
	if (r["normal"] as Vector3).dot((to - from).normalized()) > -0.05:
		return Vector3.INF
	return r["position"]


func _hit(space: PhysicsDirectSpaceState3D, lh: Node, from: Vector3, to: Vector3) -> Vector3:
	var q := PhysicsRayQueryParameters3D.create(from, to)
	q.collision_mask = 1
	var r := space.intersect_ray(q)
	if r.is_empty() or not lh.is_ancestor_of(r["collider"]):
		return Vector3.INF
	return r["position"]


func _tower_window(lh: Node3D, space: PhysicsDirectSpaceState3D, w: Dictionary, stone: Material) -> void:
	var b := deg_to_rad(float(w["bearing"]))
	var y := float(w["y"])
	var ww := float(w["w"])
	var hh := float(w["h"])
	var dir := Vector3(cos(b), 0.0, sin(b))
	var tang := Vector3(-sin(b), 0.0, cos(b))
	var axis := Vector3(TOWER.x, y, TOWER.y)
	var radii := []
	for off in [-(ww * 0.5 + 0.5), ww * 0.5 + 0.5]:
		# from outside, inward; a roof or the house may be in the way at the usual start, so try a few starts and keep the first
		# hit that is plausibly the tower's wall (2.8 to 4.8 m from the axis)
		for start in [5.2, 4.5, 6.0, 4.0]:
			var hit: Vector3 = _hit(space, lh, lh.to_global(axis + dir * start + tang * off), lh.to_global(axis + tang * off))
			var rr0 := (lh.to_local(hit) - axis).dot(dir) if hit != Vector3.INF else -1.0
			attempts[w["id"]] = attempts.get(w["id"], []) + [[start, snappedf(rr0, 0.01)]]
			if hit != Vector3.INF:
				var rr := (lh.to_local(hit) - axis).dot(dir)
				if rr > 2.8 and rr < 4.8:
					radii.append(rr)
					break
	var r := 0.0
	if radii.is_empty():
		# the exterior wall is cut away behind this window: use the radius measured at the nearest height (the tower tapers slowly)
		var best := INF
		for id in tower_radii:
			var dy := absf(float(tower_radii[id][0]) - y)
			if dy < best:
				best = dy
				r = float(tower_radii[id][1])
		if r == 0.0:
			missed.append(w["id"])
			return
		fallback.append(w["id"])
	else:
		r = (radii[0] + radii[-1]) * 0.5
		tower_radii[w["id"]] = [y, r]
	var holder := Node3D.new()
	holder.name = w["id"] + "_Kit"
	lh.add_child(holder)
	holder.transform = Transform3D(Basis(-tang, Vector3.UP, dir), axis + dir * r)      # x = up x outward: a right-handed basis (a mirrored one turns the normals inside out)
	surrounds[w["id"]] = Kit.window(holder, w["id"], ww, hh, stone, 0.02)
	_trim_tower_reveal(w["id"], r)


func _house_window(frame: Node3D, lh: Node, space: PhysicsDirectSpaceState3D, w: Dictionary, stone: Material) -> void:
	var west: bool = w["wall"] == "west"
	var at := float(w["at"])
	var y := float(w["y"])
	var ww := float(w["w"])
	var hh := float(w["h"])
	# frame coordinates (kit.gd p(): x = u, y, z = -v). West wall faces -u; the back wall faces +v.
	var outward := Vector3(-1, 0, 0) if west else Vector3(0, 0, -1)
	var along := Vector3(0, 0, 1) if west else Vector3(-1, 0, 0)       # right-handed with up and outward
	var plane := Vector3(HOUSE_WEST_U, y, -at) if west else Vector3(at, y, -HOUSE_BACK_V)
	var dists := []
	for off in [-(ww * 0.5 + 0.5), ww * 0.5 + 0.5]:
		var p: Vector3 = plane + along * off
		var hit: Vector3 = _hit(space, lh, frame.to_global(p + outward * 3.5), frame.to_global(p - outward * 2.6))
		if hit != Vector3.INF:
			dists.append((frame.to_local(hit) - plane).dot(outward))
	var d: float = wall_d.get(w["wall"], WALL_D)
	if w.has("face_d"):
		d = float(w["face_d"])
	elif not dists.is_empty():
		d = (dists[0] + dists[-1]) * 0.5
	else:
		fallback.append(w["id"])
	distances[w["id"]] = d
	var holder := Node3D.new()
	holder.name = w["id"] + "_Kit"
	frame.add_child(holder)
	holder.transform = Transform3D(Basis(along, Vector3.UP, outward), plane + outward * d)
	surrounds[w["id"]] = Kit.window(holder, w["id"], ww, hh, stone)
	_trim_house_reveal(w["id"], west, d)


func _plain(c: Color, rough: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	return m


func _fallback_stone() -> Material:
	return _plain(Color(0.62, 0.57, 0.48), 0.95)


## Where the carve removed the exterior's wall at the first floor, the lining shows from outside. Close those cells with masonry on the
## wall's real outer plane (found by rays through intact cells), leaving every window opening clear for its surround.
func _house_walls(frame: Node3D, lh: Node, space: PhysicsDirectSpaceState3D, stone: Material, wins: Array) -> void:
	# per wall: outward direction, direction of increasing `at`, the lining plane, the range along it, the top (all house frame)
	var defs := {
		"west": [Vector3(-1, 0, 0), Vector3(0, 0, -1), HOUSE_WEST_U, -0.5, 8.7, L1_Y + 2.7],
		"back": [Vector3(0, 0, -1), Vector3(1, 0, 0), -HOUSE_BACK_V, -3.06, 5.4, L1_Y + 1.85],
		"front": [Vector3(0, 0, 1), Vector3(1, 0, 0), -0.88, -3.8, 5.4, L1_Y + 1.5],     # the wall with the door: holes either side of the porch
	}
	for wall in defs:
		var west: bool = wall == "west"
		var dd: Array = defs[wall]
		var outward: Vector3 = dd[0]
		var along: Vector3 = dd[1]
		var lining: float = dd[2]
		var a0: float = dd[3]
		var a1: float = dd[4]
		var y1: float = dd[5]
		# 1) the wall's thickness: the median hit distance over the whole panel
		var hits := []
		var cells := []
		var na := int(floor((a1 - a0) / CELL))
		var ny := int(floor((y1 - PATCH_Y0) / CELL))
		for i in na:
			for j in ny:
				var at := a0 + (i + 0.5) * CELL
				var y := PATCH_Y0 + (j + 0.5) * CELL
				var plane: Vector3 = Vector3(lining, y, -at) if west else Vector3(at, y, lining)
				var hit: Vector3 = _hit_front(space, lh, frame.to_global(plane + outward * 3.0), frame.to_global(plane - outward * 1.6))
				var d := INF
				if hit != Vector3.INF:
					d = (frame.to_local(hit) - plane).dot(outward)
					if d > 0.2 and d < 1.6:
						hits.append(d)
				cells.append([at, y, plane, d])
		var thick := WALL_D
		if hits.size() >= 6:
			hits.sort()
			thick = hits[hits.size() / 2]
		wall_d[wall] = thick
		# 2) every cell with no exterior wall near that plane, and not inside a window, gets a masonry quad
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var quads := 0
		for c in cells:
			var d: float = c[3]
			var in_belt: bool = float(c[1]) >= BELT_Y1     # above 4.05 the whole face is stone (the first-floor shell); below it only holes in the real ground-floor wall are patched
			if d != INF and absf(d - thick) < 0.5 and not in_belt:
				continue                                  # the wall is there (the belt course goes over it anyway)
			var at: float = c[0]
			var y: float = c[1]
			var in_window := false
			for w in wins:
				if w["kind"] == "house" and w["wall"] == wall:
					if absf(at - float(w["at"])) < float(w["w"]) * 0.5 + 0.35 and absf(y - float(w["y"])) < float(w["h"]) * 0.5 + 0.35:
						in_window = true
			if in_window:
				continue
			var centre: Vector3 = (c[2] as Vector3) + outward * (thick + 0.05)
			var ha := along * (CELL * 0.5)
			var hy := Vector3.UP * (CELL * 0.5)
			var pts := [centre - ha - hy, centre + ha - hy, centre + ha + hy, centre - ha + hy]
			# Godot's front face is clockwise: wind the quad so its geometric normal points INTO the wall (the front patch was wound the other way
			# and rendered black from outside, "the missing texture over the door")
			var flip: bool = (pts[1] - pts[0]).cross(pts[2] - pts[0]).dot(outward) > 0.0
			var order: Array = [0, 2, 1, 0, 3, 2] if flip else [0, 1, 2, 0, 2, 3]
			for t in order:
				st.set_normal(outward)
				st.add_vertex(pts[t])
			quads += 1
		patched_cells += quads
		if quads > 0:
			var mi := MeshInstance3D.new()
			mi.name = "L1_%s_Masonry" % wall
			mi.mesh = st.commit()
			mi.material_override = stone
			frame.add_child(mi)


## The interior's reveal boxes for a tower window are a fixed 0.8 m deep, and on a thinner wall they stick out past the real outer face
## (measured 0.17 to 0.82 m). Shorten them to end at the measured face (the surround covers the end), keeping the inner end where it is.
func _trim_tower_reveal(id: String, r_out: float) -> void:
	var rooms := get_node_or_null(rooms_path)
	if rooms == null:
		return
	var lining_r := -1.0
	var new_depth := 0.0
	for part in ["Sill", "Head", "JambL", "JambR"]:
		var mi := rooms.find_child(id + "_" + part, true, false) as MeshInstance3D
		if mi == null:
			continue
		var bm := mi.mesh as BoxMesh
		var v := Vector2(mi.position.x - TOWER.x, mi.position.z - TOWER.y)
		var rc := v.length()
		var inner := rc - bm.size.z * 0.5
		var nd := clampf(r_out - inner - 0.02, 0.1, bm.size.z)
		if nd >= bm.size.z - 0.001:
			return
		lining_r = inner
		new_depth = nd
		bm.size = Vector3(bm.size.x, bm.size.y, nd)
		var u := v / rc
		var rn := inner + nd * 0.5
		mi.position = Vector3(TOWER.x + u.x * rn, mi.position.y, TOWER.y + u.y * rn)
	if lining_r < 0.0:
		return
	# the glass and the mullion sit at the reveal's outer end
	for part in ["Glass", "Mullion"]:
		var g := rooms.find_child(id + "_" + part, true, false) as MeshInstance3D
		if g == null:
			continue
		var gv := Vector2(g.position.x - TOWER.x, g.position.z - TOWER.y)
		var gu := gv / gv.length()
		var gr := lining_r + new_depth - (0.0 if part == "Glass" else 0.01)
		g.position = Vector3(TOWER.x + gu.x * gr, g.position.y, TOWER.y + gu.y * gr)


## The interior's reveal boxes for a house window were built a fixed 1.05 m deep, but the real wall is as thin as 0.55 m, so they stuck out
## through it (the garbled boxes beside the door). Cut them to end 2 cm inside the measured outer face; the glass and mullion move with them.
func _trim_house_reveal(id: String, west: bool, d: float) -> void:
	var rooms := get_node_or_null(rooms_path)
	if rooms == null:
		return
	var f0 := HOUSE_WEST_U if west else HOUSE_BACK_V       # the lining plane
	var nd := clampf(d - 0.02, 0.1, 1.05)
	for part in ["Sill", "Head", "JambL", "JambR"]:
		var mi := rooms.find_child(id + "_" + part, true, false) as MeshInstance3D
		if mi == null:
			continue
		var bm := mi.mesh as BoxMesh
		if west:
			bm.size = Vector3(nd, bm.size.y, bm.size.z)
			mi.position = Vector3(f0 - nd * 0.5, mi.position.y, mi.position.z)
		else:
			bm.size = Vector3(bm.size.x, bm.size.y, nd)
			mi.position = Vector3(mi.position.x, mi.position.y, -(f0 + nd * 0.5))
	for part in ["Glass", "Mullion"]:
		var g := rooms.find_child(id + "_" + part, true, false) as MeshInstance3D
		if g == null:
			continue
		var off := 0.05 if part == "Glass" else 0.05
		if west:
			g.position = Vector3(f0 - nd + off, g.position.y, g.position.z)
		else:
			g.position = Vector3(g.position.x, g.position.y, -(f0 + nd - off))


## A smooth stone facade round the main door (creator, 2026-10-25: "smoothen the external wall around the main entrance door"). The exterior model's
## front wall there is lumpy: it stands 1.1 to 1.4 m out of the door's plane (tools/probe_front_face.gd), with holes and bulges. Two flat panels of
## coursed masonry stand just in front of the highest lump on each side of the door, up to the underside of the first floor, and a clean stone
## passage (two reveals and a soffit) runs from the door back to the facade, so the door sits in a plain recess. Frame coordinates: x = u, z outward.
const FACADE_Z := 1.46                    # the front of the panels: just beyond the largest bulge measured (1.44)
const FACADE_T := 0.5                     # their thickness (they are slabs, the back hidden in the wall)
const FACADE_TOP := 3.95                  # the underside of the first floor slab; above it the upper storey's own wall (it juts out to 1.9) takes over


func _front_facade(frame: Node3D, stone: Material, dd: float) -> void:
	var gf := 0.97
	var parts := [
		["FacadeLeft", Vector3(-3.1, gf, FACADE_Z - FACADE_T), Vector3(-1.38, FACADE_TOP, FACADE_Z)],
		["FacadeRight", Vector3(1.38, gf, FACADE_Z - FACADE_T), Vector3(3.1, FACADE_TOP, FACADE_Z)],
		["PassageLeft", Vector3(-0.99, gf, 0.04), Vector3(-0.9, gf + 3.1, FACADE_Z - 0.01)],
		["PassageRight", Vector3(0.9, gf, 0.04), Vector3(0.99, gf + 3.1, FACADE_Z - 0.01)],
		["PassageSoffit", Vector3(-0.99, gf + 3.04, 0.04), Vector3(0.99, gf + 3.14, FACADE_Z - 0.01)],
		["PassageFloor", Vector3(-0.99, gf - 0.04, 0.04), Vector3(0.99, gf + 0.02, FACADE_Z + 0.4)],
	]
	var g := Node3D.new()
	g.name = "FrontFacade"
	frame.add_child(g)
	for p in parts:
		var a: Vector3 = p[1]
		var b: Vector3 = p[2]
		var bm := BoxMesh.new()
		bm.size = b - a
		var mi := MeshInstance3D.new()
		mi.name = p[0]
		mi.mesh = bm
		mi.material_override = stone
		mi.position = (a + b) * 0.5
		g.add_child(mi)
	facade = g
