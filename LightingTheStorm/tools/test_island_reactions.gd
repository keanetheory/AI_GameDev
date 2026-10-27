# test_island_reactions.gd - run: Godot --headless --path . --script res://tools/test_island_reactions.gd
# Island Creator ISL-05: the island reacts to the storm (scripts/world/island_reactions.gd). Checks: the spray ring is built; calm sea (state 1)
# leaves the rock dry and the spray faint; a storm (state 5) soaks the rock (darker, glossier) and raises the spray; the reduced-intensity
# preset (Sea.intensity 0.6) scales both down; the node adds no lights.
extends SceneTree

const Sea := preload("res://scripts/world/sea.gd")

var _f := 0
var _lv: Node
var _fails := 0
var _lights0 := 0


func _initialize() -> void:
	_lv = load("res://scenes/Level.tscn").instantiate()
	root.add_child(_lv)


func _ok(cond: bool, msg: String) -> void:
	print(("PASS  " if cond else "FAIL  ") + msg)
	_fails += int(not cond)


func _hold(state: float, intensity: float) -> void:
	Sea.intensity = intensity
	Sea.state = state
	Sea.target_state = state
	var ws := _lv.get_node_or_null("WaveSystem")
	if ws:
		ws.force_state = state


func _process(delta: float) -> bool:
	_f += 1
	var ir := _lv.get_node_or_null("IslandReactions")
	if _f == 6:
		_ok(ir != null, "IslandReactions node is in the level")
		if ir == null:
			quit(1)
			return true
		_ok(ir.spray.size() >= 10, "shoreline spray ring built (%d bursts)" % ir.spray.size())
		_ok(ir.get("_rock").size() >= 1, "rock materials found (%d)" % ir.get("_rock").size())
		_ok(ir.find_children("*", "Light3D", true, false).is_empty(), "no lights added")
		_hold(1.0, 1.0)
		ir.wetness = 0.0
	if _f == 8:
		ir._process(0.0)
		var m: StandardMaterial3D = ir.get("_rock")[0][0]
		var dry: Color = ir.get("_rock")[0][1]
		_ok(absf(m.albedo_color.v - dry.v) < 0.01 and ir.spray[0].amount_ratio < 0.1, "calm (state 1): rock dry (value %.3f), spray faint (%.2f)" % [m.albedo_color.v, ir.spray[0].amount_ratio])
		_hold(5.0, 1.0)
		ir.wetness = 1.0                                    # skip the ten-second soak
	if _f == 10:
		ir._process(0.0)
		var m: StandardMaterial3D = ir.get("_rock")[0][0]
		var dry: Color = ir.get("_rock")[0][1]
		var wet := m.albedo_color.v < dry.v * 0.8 and m.roughness <= 0.36
		_ok(wet, "storm (state 5): rock soaked (value %.3f of dry %.3f, roughness %.2f)" % [m.albedo_color.v, dry.v, m.roughness])
		_ok(ir.spray[0].amount_ratio > 0.9, "storm: spray at full (%.2f)" % ir.spray[0].amount_ratio)
		_hold(5.0, 0.6)
		ir.wetness = ir.target_wetness(5.0, 0.6)
	if _f == 12:
		ir._process(0.0)
		_ok(ir.wetness < 0.7 and ir.spray[0].amount_ratio < 0.5, "reduced preset (intensity 0.6): wetness %.2f, spray %.2f" % [ir.wetness, ir.spray[0].amount_ratio])
		Sea.intensity = 1.0
		print("RESULT: %s (%d failed)" % ["OK" if _fails == 0 else "FAIL", _fails])
		quit(1 if _fails else 0)
	return false
