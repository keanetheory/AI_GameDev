# probe_dialogue_timing.gd - QA-05 (Playtest QA), observe only.
#   Godot --headless --path . --script res://tools/probe_dialogue_timing.gd [-- fail]
# Runs the full-slice playthrough (test_slice_playthrough.gd, unchanged) and logs, in game seconds, every story event, every
# line queued / started / finished (with its real clip length), the music track and the outcome screen. Prints a TIMELINE
# block and a CSV block that GERFramework/reports/playtest_qa_timing.md is built from. It changes nothing in the game.
# Note: the scripted player teleports between beats, so the gaps between events are the shortest a player could make them;
# a line that overruns here is the fast-player worst case.
extends "res://tools/test_slice_playthrough.gd"

var _rows: Array = []        # [t, kind, id, extra]
var _started_at := {}
var _music := ""
var _screen_shown := false
var _wired := false
var _queued_seen := {}
var _held_seen := {}


func _initialize() -> void:
	super._initialize()


func _log(kind: String, id: String, extra: String = "") -> void:
	_rows.append([_t, kind, id, extra])


func _wire() -> void:
	_wired = true
	var gs := root.get_node("GameState")
	var dlg := root.get_node("Dialogue")
	gs.event_emitted.connect(func(id: String, _p: int) -> void: _log("EVENT", id))
	gs.restarted.connect(func() -> void: _log("RESTART", "-"))
	dlg.line_started.connect(func(id: String, spk: String, _s: String, _d: String) -> void:
		var clip: AudioStream = dlg._clip(id)
		var ln := clip.get_length() if clip else -1.0
		_started_at[id] = _t
		_log("START", id, "%s clip=%.2f" % [spk, ln]))
	dlg.line_finished.connect(func(id: String) -> void:
		_log("END", id, "dur=%.2f" % (_t - float(_started_at.get(id, _t)))))


func _process(delta: float) -> bool:
	var r := super._process(delta)
	if not _wired and root.has_node("GameState"):
		_wire()
	var dl := root.get_node_or_null("Dialogue")
	if dl:      # a line is marked played when it is queued; a held line waits in _held for its condition
		for id in dl._played.keys():
			if not _queued_seen.has(id):
				_queued_seen[id] = true
				_log("QUEUED", id)
		for h in dl._held:
			if not _held_seen.has(h["line_id"]):
				_held_seen[h["line_id"]] = true
				_log("HELD", h["line_id"], String(h.get("requires", "")))
		if dl._played.is_empty() and not _queued_seen.is_empty():
			_queued_seen.clear()      # a restart cleared the loader
			_held_seen.clear()
	var gs := root.get_node_or_null("GameState")
	if gs:
		var mx: Node = gs.get("_mixer")
		if mx != null and is_instance_valid(mx):
			var tr := String(mx.get("music_track"))
			if tr != _music:
				_music = tr
				_log("MUSIC", tr)
		var scr: Node = gs.outcome_screen() if gs.has_method("outcome_screen") else null
		if scr != null and is_instance_valid(scr):
			var sh := bool(scr.get("showing"))
			if sh != _screen_shown:
				_screen_shown = sh
				_log("SCREEN", String(scr.get("kind")) if sh else "hidden")
	return r


func _finalize() -> void:
	print("=== TIMELINE (game s) ===")
	for row in _rows:
		print("%8.2f  %-7s %-24s %s" % row)
	print("=== CSV ===")
	for row in _rows:
		print("CSV,%.2f,%s,%s,%s" % row)
