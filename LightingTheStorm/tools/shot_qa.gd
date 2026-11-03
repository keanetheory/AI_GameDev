# shot_qa.gd - QA-06 (Playtest QA), observe only: shot.gd plus the characters at their standing spots.
# Run like shot.gd (no --headless): Godot --path . --write-movie out.png --fixed-fps 10 --quit-after 12 --script res://tools/shot_qa.gd -- x y z tx ty tz [phase] [sea]
# Every SHOT_* variable of shot.gd still works. One more:
#   SHOT_CAST="TED:8.63,27.51,-6.87|ARTHUR:-0.37,10.58,-1.12"  spawns each character there, turned to face the camera.
# Used by GERFramework/reports/playtest_qa_visual (the QA-06 sweep); the views are in tools/visual_views.json ("env" field).
extends "res://tools/shot.gd"

const NpcScript := preload("res://scripts/character/npc.gd")

var _cast_done := false


func _process(d: float) -> bool:
	var r := super._process(d)
	if not _cast_done and _f == 4 and OS.get_environment("SHOT_CAST") != "":
		_cast_done = true
		for item in OS.get_environment("SHOT_CAST").split("|", false):
			var who := item.get_slice(":", 0)
			var c := item.get_slice(":", 1).split(",")
			var at := Vector3(float(c[0]), float(c[1]), float(c[2]))
			var n: Node3D = NpcScript.spawn(_lv, who, at)
			var face := Vector3(_from.x, at.y, _from.z)
			if face.distance_to(at) > 0.05:
				n.look_at(face, Vector3.UP)      # as shot.gd's SHOT_NPC: -Z towards where they look
	return r
