# bake_wall_patch.gd - run (no --headless needed): Godot --headless --path . --script res://tools/bake_wall_patch.gd
# Finds the holes in the exterior wall and saves the patches (copies of the wall) to res://Assets/Models/lighthouse/wall_patch.res and wall_patch.json.
# Re-run after the exterior mesh or its carves (Level.tscn) change. LHF_NO_WALL_PATCH=1 makes the game skip the patches.
extends SceneTree
var _lv: Node
var _f := 0
func _initialize() -> void:
	OS.set_environment("LHF_NO_WALL_PATCH", "1")      # the level is loaded WITHOUT the old patches
	_lv = load("res://scenes/Level.tscn").instantiate()
	root.add_child(_lv)
func _physics_process(_d: float) -> bool:
	_f += 1
	if _f < 8:
		return false
	var wp := Node3D.new()
	wp.set_script(load("res://scripts/world/wall_patch.gd"))
	var t0 := Time.get_ticks_msec()
	wp.build_and_save(_lv.get_node("Lighthouse"), root.world_3d.direct_space_state)
	print("bake_wall_patch: %d cells in %d regions, %d s" % [wp.patched_cells, wp.regions.size(), (Time.get_ticks_msec() - t0) / 1000])
	for r in wp.regions:
		if str(r["kind"]).begins_with("house"):
			print("   region ", r)
	quit(0)
	return false
