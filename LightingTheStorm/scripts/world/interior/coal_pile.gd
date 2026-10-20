# coal_pile.gd - the heap in the coal store: E takes a shovelful (coal_job.gd). Offered only with empty hands and
# while the boiler is still hungry.
extends "res://scripts/interaction/interactable.gd"

@export var job_path: NodePath


func _init() -> void:
	prompt = "Shovel coal"
	reach = 1.9
	vertical_reach = 2.2
	aim_height = 0.5
	min_facing = 0.2


func can_interact(player: Node3D) -> bool:
	if not super.can_interact(player):
		return false
	var carry := get_node_or_null("/root/Carry")
	var job := get_node_or_null(job_path)
	return carry != null and not carry.is_holding() and job != null and not job.done


func interact(player: Node3D) -> void:
	var job := get_node_or_null(job_path)
	if job:
		job.take_shovelful()
	interacted.emit(player)
