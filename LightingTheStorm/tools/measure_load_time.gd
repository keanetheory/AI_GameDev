# measure_load_time.gd - times how long a part of the level takes to load, headless.
# Run one part per process (resources cache, so a second part in the same process would load faster):
#   Godot --headless --path . --script res://tools/measure_load_time.gd -- all|no_cliffside|cliffside|island|saltgate
# tools/measure_load_time.py runs every part and prints a table. The time covers loading the scene's resources,
# instantiating it and running every _ready (collider building, the walkway cut, the trees).
extends SceneTree

const KEEP := {
	"all": [],
	"no_cliffside": ["Cliffs", "Mainland"],      # these are REMOVED
	"cliffside": ["Cliffs", "Mainland"],         # these are KEPT (plus the environment nodes)
	"island": ["Island", "RockPatchSE", "RockPatchSE2", "RockPatchNE"],
	"saltgate": ["Saltgate", "SaltgateWest", "SaltgateEast", "BoardwalkWest", "BoardwalkEast", "BoardwalkLink", "Harbour", "HarbourStairs"],
}
const ALWAYS := ["WorldEnvironment", "Sun", "Sea", "WaveSystem", "LightingRig"]

var _t0 := 0
var _part := "all"
var _f := 0


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	_part = args[0] if args.size() > 0 else "all"
	_t0 = Time.get_ticks_msec()
	var lv: Node = (load("res://scenes/Level.tscn") as PackedScene).instantiate()
	var t_loaded := Time.get_ticks_msec()
	if _part == "no_cliffside":
		for c in lv.get_children():
			if c.name in KEEP["no_cliffside"]:
				c.free()
	elif _part != "all":
		for c in lv.get_children():
			if not (c.name in KEEP[_part] or c.name in ALWAYS):
				c.free()
	root.add_child(lv)
	print("LOADTIME part=%s resources+instantiate=%d ms" % [_part, t_loaded - _t0])


func _process(_d: float) -> bool:
	_f += 1
	if _f == 2:
		print("LOADTIME part=%s total=%d ms (to second frame)" % [_part, Time.get_ticks_msec() - _t0])
		quit(0)
	return false
