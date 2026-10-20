# poster.gd - a Flighted poster on the hall wall: E reads it and fires POSTER_EXAMINED (canon event, optional beat:
# Arthur's reaction once he is inside). It is an Interactable (scripts/interaction/), so the Interaction autoload owns
# the prompt, the reach and the key; this only says what E does. The event is one-shot in GameState.
extends "res://scripts/interaction/interactable.gd"


func _init() -> void:
	prompt = "Read the poster"
	reach = 2.2
	aim_height = 0.0
	vertical_reach = 1.6


func interact(player: Node3D) -> void:
	var gs := get_node_or_null("/root/GameState")
	if gs:
		gs.emit_event("POSTER_EXAMINED")
	interacted.emit(player)
