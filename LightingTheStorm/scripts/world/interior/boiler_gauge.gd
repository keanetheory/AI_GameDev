# boiler_gauge.gd - the boiler's pressure gauge and water-level glass, for the coal job (backlog T33).
# Put it on a Node3D that has a "Needle" child (a thin bar pointing up, pivoting at its own origin, face looking along +x) and optionally a "Water" child
# (a box whose scale.y is the water level). set_level(0..1) moves them; the needle sweeps 220 degrees.
extends Node3D

const SWEEP_DEG := 300.0

var level := 0.0


func set_level(v: float) -> void:
	level = clampf(v, 0.0, 1.0)
	var needle := get_node_or_null("Needle") as Node3D
	if needle:
		# the face looks along +x (the house's +u). The bar points up at 0; positive turns are anticlockwise seen from the
		# front, so the sweep starts at 7 o'clock (+150 degrees) and ends at 5 o'clock (-150) through 12.
		needle.rotation = Vector3(deg_to_rad(SWEEP_DEG * 0.5 - SWEEP_DEG * level), 0.0, 0.0)
	var water := get_node_or_null("Water") as Node3D
	if water:
		water.scale.y = 0.15 + 0.7 * level
