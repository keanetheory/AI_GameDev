# zone_trigger.gd - a box in the interior that reports a canon event the first time the player walks into it
# (LIGHTHOUSE_ENTERED, ENGINE_ROOM_ENTERED, WALL_WHISPER_HEARD, BASEMENT_BANG ...). GameState treats every one of these as
# one-shot, so a second walk through is ignored there. `size` is in this node's own space (an Area3D, mask 1 = bodies
# on the world layer, which is what the player's body is on).
extends Area3D

@export var event_id := ""
@export var size := Vector3(2, 2, 2)
## The event only fires once this one has (for beats that follow another), "" for none.
@export var after_event := ""

var fired := false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	monitoring = true
	var cs := CollisionShape3D.new()
	var bx := BoxShape3D.new()
	bx.size = size
	cs.shape = bx
	add_child(cs)
	add_to_group("lhi_zone")
	body_entered.connect(_on_body)


func _on_body(body: Node3D) -> void:
	if fired or not body.is_in_group("player"):
		return
	var gs := get_node_or_null("/root/GameState")
	if gs == null:
		return
	if after_event != "" and not gs.fired.has(after_event):
		return
	fired = true
	gs.emit_event(event_id)
