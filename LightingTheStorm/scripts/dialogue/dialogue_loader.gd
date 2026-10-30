# dialogue_loader.gd - Godot 4 / GDScript
# Reads dialogue_opening.json (Ted, Arthur and Daniel for steps 1-3 of the Gate 1 slice) and plays
# lines when the game reports a stable event ID. Attach to a Node (or make it an autoload) and call
# trigger("BOILER_FED") etc. from the gameplay scripts. Lines in the same "group" are alternates:
# one is picked at random. The loader never shows a timer or a quest marker (Pillars 2 and 3);
# assist_hint is only emitted when assist_mode is on.
extends Node

signal line_started(line_id: String, speaker: String, subtitle: String, delivery: String)
signal line_finished(line_id: String)
signal journal_entry_added(journal_id: String, text: String)
signal assist_hint(step: int, text: String)
signal playback_done  # emit via notify_audio_finished() when real voice audio ends

@export_file("*.json") var data_path := "res://data/dialogue/dialogue_opening.json"
@export var assist_mode := false
## true: lines advance after an estimated reading time. false: wait for notify_audio_finished().
@export var auto_advance := true
@export var seconds_per_word := 0.38
@export var min_line_seconds := 1.4

var data: Dictionary = {}
var speakers: Dictionary = {}

var _by_trigger := {}
var _journal_by_trigger := {}
var _played := {}
var _idle_tier := {}
var _queue: Array = []
var _held: Array = []      # lines waiting for their `requires` condition (e.g. Daniel speaks only with the player in the basement)
var _held_check := 0.0
## Answers a line's `requires` name: set by GameState (dialogue_condition). With none set every line plays.
var condition_provider: Callable = Callable()
var _playing := false
var _generation := 0   # bumped by reset_for_restart() so a line still being played from the old attempt is dropped


func _ready() -> void:
	var file := FileAccess.open(data_path, FileAccess.READ)
	if file == null:
		push_error("Dialogue data not found: %s" % data_path)
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY or not parsed.has("lines"):
		push_error("dialogue_opening.json is not valid dialogue data")
		return
	data = parsed
	speakers = data.get("speakers", {})
	for line in data["lines"]:
		var trig: String = line["trigger"]
		if not _by_trigger.has(trig):
			_by_trigger[trig] = []
		_by_trigger[trig].append(line)
	for entry in data.get("journal", []):
		var jt: String = entry["trigger"]
		if not _journal_by_trigger.has(jt):
			_journal_by_trigger[jt] = []
		_journal_by_trigger[jt].append(entry)


## Report a game event (e.g. "GATE_OPENED"). Queues every matching line, picking one per group.
func trigger(event_id: String) -> void:
	if data.is_empty():
		return
	for entry in _journal_by_trigger.get(event_id, []):
		journal_entry_added.emit(entry["journal_id"], entry["text"])
	_enqueue(_pick_lines(_by_trigger.get(event_id, [])))


## Call when the player has made no progress on a step. key is "IDLE_STEP_1", "IDLE_STEP_2",
## "IDLE_STEP_3" or "IDLE_SALTGATE". Each call escalates one tier (1 hint, 2 sharper, 3 explicit).
func idle(key: String) -> void:
	if data.is_empty() or _playing:
		return
	var candidates: Array = _by_trigger.get(key, [])
	if candidates.is_empty():
		return
	var tier: int = mini(int(_idle_tier.get(key, 0)) + 1, candidates.size())
	_idle_tier[key] = tier
	for line in candidates:
		if int(line["tier"]) == tier:
			_enqueue([line])
			return


## Call when the player progresses so the next stall starts again at tier 1.
func reset_idle(key: String) -> void:
	_idle_tier.erase(key)


func notify_audio_finished() -> void:
	playback_done.emit()


func reset_for_restart() -> void:
	# Gate 1 retry model: fail, then restart the slice.
	_played.clear()
	_idle_tier.clear()
	_queue.clear()
	_held.clear()
	_generation += 1    # a _play_queue() coroutine mid-line sees this on waking and returns without speaking
	_playing = false


func _condition_met(line: Dictionary) -> bool:
	var need: String = String(line.get("requires", ""))
	if need == "" or not condition_provider.is_valid():
		return true
	return bool(condition_provider.call(need))


## Held lines are retried a few times a second; one whose condition has come true joins the queue.
func _process(delta: float) -> void:
	if _held.is_empty():
		return
	_held_check -= delta
	if _held_check > 0.0:
		return
	_held_check = 0.25
	var ready: Array = []
	for line in _held:
		if _condition_met(line):
			ready.append(line)
	if ready.is_empty():
		return
	for line in ready:
		_held.erase(line)
	_enqueue(ready)


func _pick_lines(candidates: Array) -> Array:
	var chosen: Array = []
	var group_slot := {}  # group name -> index in chosen
	var group_pool := {}  # group name -> Array of lines
	for line in candidates:
		if bool(line.get("once", true)) and _played.has(line["line_id"]):
			continue
		var g: String = line.get("group", "")
		if g == "":
			chosen.append(line)
		elif not group_slot.has(g):
			group_slot[g] = chosen.size()
			group_pool[g] = [line]
			chosen.append(line)
		else:
			group_pool[g].append(line)
	for g in group_slot:
		var pool: Array = group_pool[g]
		chosen[group_slot[g]] = pool[randi() % pool.size()]
	return chosen


func _enqueue(lines: Array) -> void:
	for line in lines:
		if not _condition_met(line):
			var already := false
			for h in _held:
				if h["line_id"] == line["line_id"]:
					already = true
			if not already:
				_held.append(line)      # not played, not marked played: it speaks when its condition comes true
			continue
		_played[line["line_id"]] = true
		_queue.append(line)
	if not _playing and not _queue.is_empty():
		_play_queue()


func _play_queue() -> void:
	_playing = true
	var gen := _generation
	while not _queue.is_empty():
		var line: Dictionary = _queue.pop_front()
		var pause: float = float(line.get("pause_before", 0.0))
		if pause > 0.0:
			await get_tree().create_timer(pause).timeout
			if gen != _generation:
				return   # the slice was restarted while waiting; leave _playing to the new attempt
		line_started.emit(line["line_id"], line["speaker"], line["subtitle"], line["delivery"])
		if assist_mode and line.has("assist_text"):
			assist_hint.emit(int(line["step"]), line["assist_text"])
		if auto_advance:
			await get_tree().create_timer(_reading_time(line)).timeout
		else:
			await playback_done
		if gen != _generation:
			return
		line_finished.emit(line["line_id"])
	_playing = false


func _reading_time(line: Dictionary) -> float:
	var words: int = String(line["text"]).split(" ", false).size()
	return maxf(min_line_seconds, words * seconds_per_word)
