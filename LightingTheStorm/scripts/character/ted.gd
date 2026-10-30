# ted.gd - Ted, the lighthouse master (the rigged test character, Assets/Characters/ted.glb), placed in the level at run time by
# scripts/world/diagnosis_sequence.gd. He has no idle clip, so he stands in the first frame of one of the clips he does have
# (set in data/world/diagnosis_sequence.json), frozen. Forward is -Z; face() turns him to look at a point on the ground plane.
# Voice only for now: his lines are subtitles (the dialogue loader); there is no lip-sync audio yet.
extends Node3D

const MODEL := "res://Assets/Characters/ted.glb"

var model: Node3D
var _player: AnimationPlayer


func setup(pose_clip: String, pose_time: float) -> void:
	name = "Ted"
	var ps := load(MODEL) as PackedScene
	if ps == null:
		push_warning("ted: %s did not load" % MODEL)
		return
	model = ps.instantiate()
	add_child(model)
	add_to_group("ted")
	var aps := model.find_children("*", "AnimationPlayer", true, false)
	if not aps.is_empty():
		_player = aps[0]
		if _player.has_animation(pose_clip):
			_player.play(pose_clip)
			_player.seek(pose_time, true)
			_player.pause()


func face(point: Vector3) -> void:
	var flat := Vector3(point.x - global_position.x, 0.0, point.z - global_position.z)
	if flat.length() > 0.01:
		rotation.y = atan2(-flat.x, -flat.z)
