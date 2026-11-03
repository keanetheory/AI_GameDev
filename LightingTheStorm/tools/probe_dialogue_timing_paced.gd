# probe_dialogue_timing_paced.gd - QA-05 (Playtest QA), observe only.
#   Godot --headless --path . --script res://tools/probe_dialogue_timing_paced.gd [-- fail]
# The same full-slice run and the same log as probe_dialogue_timing.gd, but the scripted player is patient: before each step
# it waits until nobody is talking (the dialogue queue is empty, at most 90 s), the way a player who listens would. Whatever
# still overruns or overlaps here does so for a player who waits for every line, so it is structural, not the player's haste.
# The return crossing itself is sailed at the playthrough's fixed pace (about 9 m/s), so Arthur's calls meet their hazards as
# they would at the helm. Some of the playthrough's own checks may fail under this pacing; only the timeline matters here.
extends "res://tools/probe_dialogue_timing.gd"

const DRAIN_CAP_S := 90.0


func _until(cond: Callable, timeout_s: float, what: String) -> bool:
	var dlg := root.get_node("Dialogue")
	var t0 := _t
	# from the burner on the clock is running: a player casts off at once, so no waiting from there (the return is sailed as is)
	var patient: bool = _gs == null or not _gs.fired.has("BURNER_PICKED_UP")
	while patient and (dlg._playing or not dlg._queue.is_empty()) and _t - t0 < DRAIN_CAP_S:
		await process_frame
	if _t - t0 > 0.5:
		_log("WAIT", "drain", "%.1f s before: %s" % [_t - t0, what])
	return await super._until(cond, timeout_s, what)
