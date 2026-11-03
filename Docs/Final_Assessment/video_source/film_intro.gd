extends SceneTree
# Film the opening for the assessment video: the player at the front door, the knock, Ted's greeting (TED_S1_01, its voice
# clip and subtitle), the door opening. Run with --write-movie; the game plays it by itself, nobody presses a key.
var _lv: Node
var _f := 0
var _knocked := false


func _initialize() -> void:
	_lv = load("res://scenes/Level.tscn").instantiate()
	root.add_child(_lv)


func _process(_d: float) -> bool:
	_f += 1
	var door: Node3D = _lv.get_node_or_null("LighthouseDoor")
	var player: CharacterBody3D = _lv.get_node_or_null("Player")
	if door == null or player == null:
		return false
	if _f == 2:
		var out_v: Vector3 = door.global_transform.basis.z
		var stand: Vector3 = door.middle() + out_v * 3.2
		stand.y = door.middle().y - 0.9
		player.global_position = stand
		var look: Vector3 = door.middle() - stand
		player.rotation.y = atan2(-look.x, -look.z)
		player.get_node("Head").rotation.x = deg_to_rad(4.0)
	if _f < 60:
		player.velocity = Vector3.ZERO
	if _f == 60 and not _knocked:
		_knocked = true
		door.interact(player)
		print("FILM: knocked at frame ", _f)
	return false
