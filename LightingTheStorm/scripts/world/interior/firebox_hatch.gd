# firebox_hatch.gd - the boiler's firebox door: a CarrySocket that takes shovelfuls of coal and burns them (coal_job.gd).
# It never holds an item: the coal goes into the fire. Offered only while the player holds a shovelful.
extends "res://scripts/interaction/carry_socket.gd"

@export var job_path: NodePath


func _init() -> void:
	super._init()
	accepts_kind = "coal"
	allow_take = false
	reach = 1.9
	vertical_reach = 2.0
	aim_height = 0.3
	min_facing = 0.2
	prompt = "Feed the boiler"


func prompt_text() -> String:
	return "Shovel the coal into the firebox"


## The coal burns: the shovelful is used up (the shovel is thrust at the firebox, tipped and put away), the socket stays empty.
func receive(node: Node3D) -> void:
	var job := get_node_or_null(job_path)
	if job:
		job.fed()
		job.animate_feed(node)
	else:
		node.queue_free()
	placed.emit(node)
