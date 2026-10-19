# interior_reach.gd - the lighthouse interior's walkable map, shared by tools/check_interior_reach.gd and
# tools/test_interior_walk.gd. A breadth-first flood fill over standable spots on a 0.25 m grid, using the game's
# real collision and the player's capsule (radius 0.3, height 1.7; the player steps up 0.4 m, routes use 0.3 m). A spot is standable when a floor
# faces up there and the body fits above it from step height up (a standing capsule overlaps the next riser on any
# stair; the player's step-up handles that, so only the part above STEP is tested); neighbours connect when the
# height change is a step the player can take.
extends RefCounted

const CELL := 0.25
const STEP := 0.3   # under the player's 0.4 m step-up, over the 0.18-0.19 m risers, so routes climb by the treads
const RADIUS := 0.34   # the player's 0.3 plus a little clearance: a slot exactly 0.6 m wide is walkable but not climbable
const HEIGHT := 1.7
const LIGHTHOUSE := Vector3(5, 9.61, -8.5)     # the Lighthouse / LighthouseInterior node origin
const LOCAL_MIN := Vector3(-10.0, -2.6, -1.0)  # search box in the lighthouse's local frame
const LOCAL_MAX := Vector3(8.0, 22.0, 11.5)

var floors := {}    # "ix,iz" -> Array of standable floor heights (world y)
var seen := {}      # "ix,iz,k" -> parent key ("" for the start): every spot reached from the start
var spot_count := 0

var _space: PhysicsDirectSpaceState3D
var _exclude: Array[RID] = []
var _capsule := CapsuleShape3D.new()


func _init(space: PhysicsDirectSpaceState3D, exclude: Array[RID]) -> void:
	_space = space
	_exclude = exclude
	_capsule.radius = RADIUS
	_capsule.height = HEIGHT - STEP


## Find every standable spot in the search box.
func build() -> void:
	var nx := int((LOCAL_MAX.x - LOCAL_MIN.x) / CELL)
	var nz := int((LOCAL_MAX.z - LOCAL_MIN.z) / CELL)
	floors.clear()
	spot_count = 0
	for ix in nx:
		for iz in nz:
			var p := cell_centre(ix, iz)
			var list := []
			var top := LIGHTHOUSE.y + LOCAL_MAX.y + 2.0
			var bottom := LIGHTHOUSE.y + LOCAL_MIN.y
			for _i in 60:
				var q := PhysicsRayQueryParameters3D.create(Vector3(p.x, top, p.y), Vector3(p.x, bottom, p.y))
				q.exclude = _exclude
				q.hit_back_faces = false
				var hit := _space.intersect_ray(q)
				if hit.is_empty():
					break
				var y: float = hit.position.y
				if hit.normal.y > 0.7 and _fits(Vector3(p.x, y, p.y)):
					list.append(y)
				top = y - 0.05
			if not list.is_empty():
				floors["%d,%d" % [ix, iz]] = list
				spot_count += list.size()


## Breadth-first from the spot nearest `start` (world). Returns false if there is no spot near it.
func flood(start: Vector3) -> bool:
	seen.clear()
	var first := nearest(start, false)
	if first.is_empty():
		return false
	seen[first["key"]] = ""
	var queue := [first]
	var head := 0
	while head < queue.size():
		var n: Dictionary = queue[head]
		head += 1
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var jx: int = n["ix"] + d.x
			var jz: int = n["iz"] + d.y
			var col: Array = floors.get("%d,%d" % [jx, jz], [])
			for k in col.size():
				var y: float = col[k]
				if absf(y - n["y"]) > STEP:
					continue
				var key := "%d,%d,%d" % [jx, jz, k]
				if seen.has(key):
					continue
				seen[key] = n["key"]
				queue.append(_spot(jx, jz, k))
	return true


## Nearest standable spot to `p` (world), only among reached spots when `reached_only`. Empty if none.
func nearest(p: Vector3, reached_only: bool) -> Dictionary:
	var cx := int(floor((p.x - LIGHTHOUSE.x - LOCAL_MIN.x) / CELL))
	var cz := int(floor((p.z - LIGHTHOUSE.z - LOCAL_MIN.z) / CELL))
	var best := {}
	var best_d := INF
	for r in range(0, 40):
		for ix in range(cx - r, cx + r + 1):
			for iz in range(cz - r, cz + r + 1):
				if maxi(absi(ix - cx), absi(iz - cz)) != r:
					continue
				var col: Array = floors.get("%d,%d" % [ix, iz], [])
				for k in col.size():
					if reached_only and not seen.has("%d,%d,%d" % [ix, iz, k]):
						continue
					var s := _spot(ix, iz, k)
					var d := Vector3(s["pos"].x - p.x, (s["pos"].y - p.y) * 2.0, s["pos"].z - p.z).length()
					if d < best_d:
						best_d = d
						best = s
		if not best.is_empty() and r * CELL > best_d:
			break
	return best


## World positions (floor height) from the start to `spot`, following the flood fill's parents.
func path_to(spot: Dictionary) -> Array[Vector3]:
	var out: Array[Vector3] = []
	var key: String = spot["key"]
	while key != "":
		var parts := key.split(",")
		out.push_front(_spot(int(parts[0]), int(parts[1]), int(parts[2]))["pos"])
		key = seen[key]
	return out


## x/z of a grid cell's centre (world), as a Vector2 (x, z).
func cell_centre(ix: int, iz: int) -> Vector2:
	return Vector2(LIGHTHOUSE.x + LOCAL_MIN.x + (ix + 0.5) * CELL, LIGHTHOUSE.z + LOCAL_MIN.z + (iz + 0.5) * CELL)


func _spot(ix: int, iz: int, k: int) -> Dictionary:
	var c := cell_centre(ix, iz)
	var y: float = floors["%d,%d" % [ix, iz]][k]
	return {"ix": ix, "iz": iz, "k": k, "y": y, "pos": Vector3(c.x, y, c.y), "key": "%d,%d,%d" % [ix, iz, k]}


func _fits(floor_point: Vector3) -> bool:
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = _capsule
	q.transform = Transform3D(Basis(), floor_point + Vector3.UP * (STEP + (HEIGHT - STEP) * 0.5))
	q.exclude = _exclude
	q.margin = 0.01
	return _space.intersect_shape(q, 1).is_empty()
