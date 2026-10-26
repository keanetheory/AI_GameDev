# bake_colliders.gd - run: Godot --headless --path . --script res://tools/bake_colliders.gd
# Loads Level.tscn with collider_builder.gd's bake_writes on, so every builder node (the island, the lighthouse, the cliffs,
# the sea stacks, the Saltgate pieces ...) works out its flattening, carve and collision shapes once and saves them to
# res://Assets/Baked/colliders/. Later loads read those instead (see collider_builder.gd). Bake files no node uses any more
# are deleted. Re-run it whenever a builder's settings, data/world/cliff_layout.json or one of its .glb models changes:
# until then the changed node is still built live (correct, just slower) and says so in the log.
extends SceneTree

const Builder := preload("res://scripts/world/collider_builder.gd")

var _f := 0


func _initialize() -> void:
	Builder.bake_writes = true
	var t0 := Time.get_ticks_msec()
	root.add_child((load("res://scenes/Level.tscn") as PackedScene).instantiate())
	print("bake_colliders: level loaded, building ... (%d ms so far)" % (Time.get_ticks_msec() - t0))


func _process(_d: float) -> bool:
	_f += 1
	if _f < 2:              # the builders run in the first frame
		return false
	var written := Builder.written
	var removed := 0
	var dir := DirAccess.open(Builder.BAKE_DIR)
	if dir:
		for f in dir.get_files():
			var path := Builder.BAKE_DIR + f
			if f.ends_with(".res") and not path in written:
				dir.remove(f)
				removed += 1
				print("bake_colliders: removed unused ", f)
	var bytes := 0
	for p in written:
		var fa := FileAccess.open(p, FileAccess.READ)
		if fa:
			bytes += fa.get_length()
	print("bake_colliders: wrote %d bakes (%.1f MB), removed %d unused" % [written.size(), bytes / 1048576.0, removed])
	quit(0 if written.size() > 0 else 1)
	return false
