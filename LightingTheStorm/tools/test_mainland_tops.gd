# test_mainland_tops.gd - headless: the mainland's cliff-top bake (T23) is current, was used at load, and matches a live measure.
# Godot --headless --path . --script res://tools/test_mainland_tops.gd
extends SceneTree
var _lv: Node
var _f := 0
var _fails := 0


func _check(ok: bool, msg: String) -> void:
	print(("PASS  " if ok else "FAIL  ") + msg)
	if not ok:
		_fails += 1


func _initialize() -> void:
	_lv = load("res://scenes/Level.tscn").instantiate()
	root.add_child(_lv)


func _process(_d: float) -> bool:
	_f += 1
	if _f < 3:
		return false
	var ml := _lv.get_node("Mainland")
	_check(ml.tops_from_bake, "the mainland read its cliff tops from %s (else re-run tools/bake_mainland_tops.gd)" % ml.TOPS_BAKE)
	var baked: Array = ml._tops_real.duplicate()
	var t := Time.get_ticks_msec()
	ml._measure_tops()
	var live_ms := Time.get_ticks_msec() - t
	var worst := 0.0
	for i in baked.size():
		worst = maxf(worst, absf(float(baked[i]) - float(ml._tops_real[i])))
	_check(baked.size() == ml._tops_real.size() and worst < 0.001, "the baked tops match a live measure (worst difference %.4f m; live measure took %d ms)" % [worst, live_ms])
	print("RESULT: %s (%d failed)" % ["OK" if _fails == 0 else "FAILED", _fails])
	quit(1 if _fails else 0)
	return false
