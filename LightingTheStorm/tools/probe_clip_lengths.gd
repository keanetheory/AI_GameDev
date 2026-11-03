# probe_clip_lengths.gd - QA-05 (Playtest QA), observe only: every dialogue line with its trigger, pause and recorded clip length.
#   Godot --headless --path . --script res://tools/probe_clip_lengths.gd
# Prints CLIP,<line_id>,<speaker>,<trigger>,<pause_before>,<clip s>,<requires>
extends SceneTree


func _initialize() -> void:
	var f := FileAccess.open("res://data/dialogue/dialogue_opening.json", FileAccess.READ)
	var d: Dictionary = JSON.parse_string(f.get_as_text())
	var total := 0.0
	for l in d["lines"]:
		var path := "res://Assets/Audio/voice/%s.mp3" % l["line_id"]
		var ln := -1.0
		if ResourceLoader.exists(path):
			ln = (load(path) as AudioStream).get_length()
			total += ln
		print("CLIP,%s,%s,%s,%.2f,%.2f,%s" % [l["line_id"], l["speaker"], l["trigger"], float(l.get("pause_before", 0.0)), ln, l.get("requires", "")])
	print("TOTAL,%.1f s of recorded speech in %d lines" % [total, d["lines"].size()])
	quit(0)
