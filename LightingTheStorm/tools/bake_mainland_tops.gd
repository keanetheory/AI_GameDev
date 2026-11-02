# bake_mainland_tops.gd - run after changing the cliffs: Godot --headless --path . --script res://tools/bake_mainland_tops.gd
# Measures the cliff-top heights the mainland plateau is built on and saves them to Assets/Baked/mainland_tops.json (T23), so a load
# reads the table instead of walking every cliff triangle. tools/test_mainland_tops.gd checks the bake is current and matches a live measure.
extends SceneTree
var _lv: Node
var _f := 0
func _initialize() -> void:
	_lv = load("res://scenes/Level.tscn").instantiate()
	root.add_child(_lv)
func _process(_d: float) -> bool:
	_f += 1
	if _f < 3:
		return false
	var ml := _lv.get_node("Mainland")
	ml.bake_tops()
	print("bake_mainland_tops: wrote %s (key %s)" % [ml.TOPS_BAKE, ml.tops_key().substr(0, 12)])
	quit(0)
	return false
