# bake_walkway.gd - run: Godot --headless --path . --script res://tools/bake_walkway.gd
# Measures the UNCUT cliff along the walkway and writes data/world/walkway_profile.json, which mainland.gd turns into
# the ledge at start-up. Nothing is cut from the cliff: the ledge is built against the face, so there is no cutting at
# load time and no triangle surgery. Re-run it whenever data/world/cliff_layout.json changes.
#
# For every metre along the walkway it records:
#   y       the floor height: the ramp, but never above the ground behind (it ends flush with the cliff top)
#   z_deep  the deepest the rock face is at floor height (the ledge's back edge is buried a little beyond it)
#   z_low   where the face is three metres lower (the rock shelf under the ledge reaches back to it)
#   cap     the height of the ground behind the face (the cliff top)
# It measures the real meshes with a triangle-mesh ray test, not the collision hulls, so it sees the rock you see.
extends SceneTree

const STEP := 1.0
const X0 := 46.0
const X_MIN := -240.0
const OUT := "res://data/world/walkway_profile.json"
const BIN_MIN := -400.0               # the cliff triangles are binned over the whole coast: the waterline profile below needs all of it
const BIN_MAX := 410.0
const FOOT_OUT := "res://data/world/cliff_foot.json"
const END_TAPER := 8              # samples after the ledge meets the cliff top, over which it runs out flush

var _lv: Node
var _f := 0


func _initialize() -> void:
	_lv = load("res://scenes/Level.tscn").instantiate()
	root.add_child(_lv)


const MeshRays := preload("res://tools/mesh_rays.gd")
var _rays := MeshRays.new()


func _ray(from: Vector3, dir: Vector3) -> Variant:
	return _rays.first_hit(from, dir)


func _physics_process(_d: float) -> bool:
	_f += 1
	if _f < 20:
		return false
	var main: Node = _lv.get_node("Mainland")
	for c in _lv.get_node("Cliffs").get_children():
		for mi in c.find_children("*", "MeshInstance3D", true, false):
			var m := mi as MeshInstance3D
			_rays.add_mesh(m, BIN_MIN, BIN_MAX)
	print("bake: %d cliff triangles sorted for ray tests" % _rays.triangles)
	var n := int((X0 - X_MIN) / STEP) + 1
	var ys: Array[float] = []
	var zd: Array[float] = []
	var zl: Array[float] = []
	var zp: Array[float] = []
	var caps: Array[float] = []
	var misses := 0
	for i in n:
		var x := X0 - i * STEP - 0.37          # off the metre lines, so no ray runs exactly along a triangle edge
		var ramp: float = main.ramp_y(x)
		var y := ramp
		if i < 6:
			y = lerpf(2.75, ramp, float(i) / 6.0)       # the first 6 m ramp up from the boardwalk deck (contract: no step at the seam)
		# the ground behind: look down from above at the likely back edge
		var z_guess: float = zd[i - 1] if i > 0 else 566.0
		var cap_hit: Variant = _ray(Vector3(x, 95.0, z_guess + 3.0), Vector3(0, -1, 0))
		var cap: float = caps[i - 1] if i > 0 else y + 30.0
		if cap_hit != null and (cap_hit as Vector3).y > y - 6.0:      # a hit far below the floor is the sea bed, not the cliff top
			cap = (cap_hit as Vector3).y
		caps.append(cap)
		y = minf(y, cap)
		ys.append(y)
		# deepest face at floor height, from readings taken below the cliff top only (above it the ray flies over the rock)
		var deep := -INF
		var prot := INF
		for dh in [0.3, 1.2, 2.4, 4.0, 6.0]:
			if y + dh > cap - 0.4:
				continue
			var h: Variant = _ray(Vector3(x, y + dh, 470.0), Vector3(0, 0, 1))
			if h != null:
				if dh <= 2.4:
					deep = maxf(deep, (h as Vector3).z)
				prot = minf(prot, (h as Vector3).z)      # the most protruding rock up to 6 m above the floor
		var prev: float = zd[i - 1] if i > 0 else 566.0
		if deep == -INF:
			misses += 1
			deep = prev
		deep = clampf(deep, prev - 3.0, prev + 3.0)       # the face does not jump; a reading that does is a stray hit
		zd.append(deep)
		zp.append(prot if prot != INF else deep)
		var lo: Variant = _ray(Vector3(x, y - 3.0, 470.0), Vector3(0, 0, 1))
		var low: float = (lo as Vector3).z if lo != null else deep
		zl.append(clampf(low, deep - 6.0, deep + 1.0))
	# where does the ramp meet the cliff top? from there the ledge just follows the ground and runs out
	var i_end := n - 1
	for i in range(8, n - 3):
		var x := X0 - i * STEP
		if main.ramp_y(x) >= caps[i] - 0.1 and main.ramp_y(x - 1.0) >= caps[i + 1] - 0.1 and main.ramp_y(x - 2.0) >= caps[i + 2] - 0.1:
			i_end = i
			break
	var keep := mini(n, i_end + END_TAPER + 1)
	ys = ys.slice(0, keep)
	zd = _smooth(_maxfilter(zd.slice(0, keep), 2), 3)       # the back edge goes just past the deepest recess near it
	zl = _smooth(_maxfilter(zl.slice(0, keep), 2), 3)
	caps = caps.slice(0, keep)
	zp = _smooth(_maxfilter(zp.slice(0, keep), 0), 0)
	var worst := 0.0
	for i in keep:
		worst = maxf(worst, zd[i] - zp[i])
	print("bake: rock columns stand up to %.1f m in front of the deepest recess" % worst)
	var out := {"x0": X0, "step": STEP, "i_end": i_end, "end_taper": END_TAPER, "y": _r(ys), "z_deep": _r(zd), "z_low": _r(zl), "z_prot": _r(zp), "cap": _r(caps)}
	var f := FileAccess.open(OUT, FileAccess.WRITE)
	f.store_string(JSON.stringify(out))
	f.close()
	print("bake: wrote %s: %d samples, ledge meets the cliff top at x = %.0f (y %.1f), face z %.1f to %.1f, %d samples had no face hit" % [
		OUT, keep, X0 - i_end * STEP, ys[i_end], zd.min(), zd.max(), misses])
	_bake_foot()
	quit(0)
	return false


## Where the rock meets the water along the whole coast, every 3 m: for the rubble, the stacks and the spray.
func _bake_foot() -> void:
	var xs := []
	var zs := []
	var x := -395.0
	while x <= 405.0:
		var h: Variant = _ray(Vector3(x + 0.13, 1.0, 400.0), Vector3(0, 0, 1))
		if h != null:
			xs.append(snappedf(x, 0.1))
			zs.append(snappedf((h as Vector3).z, 0.1))
		x += 3.0
	var f := FileAccess.open(FOOT_OUT, FileAccess.WRITE)
	f.store_string(JSON.stringify({"x": xs, "z": zs}))
	f.close()
	print("bake: wrote %s: waterline of the rock at %d points" % [FOOT_OUT, xs.size()])


func _maxfilter(a: Array, r: int) -> Array[float]:
	var o: Array[float] = []
	for i in a.size():
		var m: float = a[i]
		for k in range(maxi(0, i - r), mini(a.size(), i + r + 1)):
			m = maxf(m, a[k])
		o.append(m)
	return o


func _smooth(a: Array, passes: int) -> Array[float]:
	var o: Array[float] = []
	for v in a:
		o.append(v)
	for p in passes:
		var nxt: Array[float] = o.duplicate()
		for i in range(1, o.size() - 1):
			nxt[i] = maxf(o[i], (o[i - 1] + 2.0 * o[i] + o[i + 1]) * 0.25)     # smoothing may round a bump but never pulls the edge out of the rock
		o = nxt
	return o


func _r(a: Array) -> Array:
	var o := []
	for v in a:
		o.append(snappedf(v, 0.01))
	return o
