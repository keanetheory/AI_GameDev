# profile_phys_probe.gd - a node for tools/profile_ready.gd: logs when the physics pass reaches it (it is given the lowest or
# the highest physics priority, so two of them bracket every other node's _physics_process).
extends Node


func _physics_process(_d: float) -> void:
	get_meta("log").append([Time.get_ticks_usec(), "first" if process_physics_priority < 0 else "last"])
