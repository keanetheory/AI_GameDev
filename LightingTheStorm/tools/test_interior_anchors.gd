# test_interior_anchors.gd - run: Godot --headless --path . --script res://tools/test_interior_anchors.gd
# The named anchors other agents attach to exist, are unique, and sit where the greybox says (inside the lighthouse for
# the interior ones; the two outside ones near it).
extends SceneTree

const NEEDED := ["door_outside", "entry", "ted_greeting", "window_ground", "boiler_interaction", "coal_pickup", "daniel", "arc_lamp_socket", "burner_fit",
	"ted_lantern", "window_tower_eye", "rowboat_sighting", "lamp_eye"]
var _lv: Node
var _f := 0


func _initialize() -> void:
	_lv = load("res://scenes/Level.tscn").instantiate()
	root.add_child(_lv)


func _physics_process(_d: float) -> bool:
	_f += 1
	if _f < 5:
		return false
	var fails := 0
	var found := {}
	for a in get_nodes_in_group("lhi_anchor"):
		found[a.get_meta("role")] = a
	for role in NEEDED:
		var ok: bool = found.has(role)
		print(("PASS  " if ok else "FAIL  ") + "anchor " + role + ("" if not ok else "  at %s  (%s)" % [(found[role] as Node3D).global_position, found[role].get_meta("note")]))
		fails += int(not ok)
	var interior: Node3D = _lv.get_node("LighthouseInterior")
	var inside := 0
	for role in ["entry", "ted_greeting", "boiler_interaction", "coal_pickup", "daniel", "arc_lamp_socket", "ted_lantern"]:
		if found.has(role) and (found[role] as Node3D).global_position.distance_to(interior.global_position) < 40.0:
			inside += 1
	var ok2 := inside == 7
	print(("PASS  " if ok2 else "FAIL  ") + "the seven interior anchors are all within the lighthouse (%d of 7)" % inside)
	fails += int(not ok2)
	print("\n%s" % ("ALL PASSED" if fails == 0 else "%d FAILED" % fails))
	quit(1 if fails > 0 else 0)
	return false
