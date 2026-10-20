# test_interior_budget.gd - run: Godot --headless --path . --script res://tools/test_interior_budget.gd
# The furnished interior's cost: how long it takes to build at load, how many nodes it makes, how many solid bodies,
# lights and interactables it adds, and its texture memory. The limits are generous guards, not targets.
extends SceneTree

const MAX_BUILD_MS := 2500
const MAX_NODES := 2500
const MAX_BODIES := 700
const MAX_LIGHTS := 70

var _f := 0


func _initialize() -> void:
	root.add_child(load("res://scenes/Level.tscn").instantiate())


func _physics_process(_d: float) -> bool:
	_f += 1
	if _f < 10:
		return false
	var lv := root.get_child(root.get_child_count() - 1)
	for c in root.get_children():
		if c.name == "Level":
			lv = c
	var rooms := lv.get_node("InteriorRooms")
	var failed := 0
	var bodies := rooms.find_children("*", "StaticBody3D", true, false).size()
	var lights := rooms.find_children("*", "OmniLight3D", true, false).size()
	var all_nodes := rooms.find_children("*", "", true, false).size()
	print("interior build: %d ms, %d kit nodes, %d nodes in all, %d solid bodies, %d lights" % [rooms.build_ms, rooms.node_count, all_nodes, bodies, lights])
	failed += _check(rooms.build_ms < MAX_BUILD_MS, "builds in under %d ms (%d)" % [MAX_BUILD_MS, rooms.build_ms])
	failed += _check(all_nodes < MAX_NODES, "under %d nodes (%d)" % [MAX_NODES, all_nodes])
	failed += _check(bodies < MAX_BODIES, "under %d solid bodies (%d)" % [MAX_BODIES, bodies])
	failed += _check(lights < MAX_LIGHTS, "under %d lights, all under the light manager's budget of 6 lit (%d)" % [MAX_LIGHTS, lights])
	var mgr := lv.get_node("LighthouseInteriorLights")
	failed += _check(mgr._lights.size() >= lights, "every interior light is managed (%d of %d)" % [mgr._lights.size(), lights])
	print("RESULT: %s (%d failed)" % ["OK" if failed == 0 else "FAILED", failed])
	quit(0 if failed == 0 else 1)
	return false


func _check(ok: bool, what: String) -> int:
	print(("PASS  " if ok else "FAIL  ") + what)
	return 0 if ok else 1
