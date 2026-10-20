# cliff_layout.gd - builds the cliff line from data/world/cliff_layout.json, so the coastline is one table.
# Put this on the "Cliffs" node. Each module becomes a child (collider_builder.gd instance) named by its id, so
# everything that looks under Cliffs (the mainland, the tests) keeps working. Edit the JSON, not the scene.
# @tool: runs in the editor too, so the coast shows in the 3D viewport; the generated children have no owner and are never saved.
@tool
extends Node3D

const BUILDER := preload("res://scripts/world/collider_builder.gd")
const MODELS := {
	"cliff_wall": "res://Assets/Models/cliff_terrain/cliff_wall.glb",
	"cliff_headland": "res://Assets/Models/cliff_terrain/cliff_headland.glb",
}

@export_file("*.json") var layout_path := "res://data/world/cliff_layout.json"


func _ready() -> void:
	for c in get_children():
		c.free()
	var f := FileAccess.open(layout_path, FileAccess.READ)
	if f == null:
		push_error("cliff_layout: %s not found" % layout_path)
		return
	var d = JSON.parse_string(f.get_as_text())
	if not (d is Dictionary) or not d.has("modules"):
		push_error("cliff_layout: %s has no modules" % layout_path)
		return
	for m in d["modules"]:
		var n := Node3D.new()
		n.set_script(BUILDER)
		n.name = m["id"]
		n.set("model_path", MODELS[m["model"]])
		n.set("collision_kind", int(m.get("collision_kind", 1)))
		n.set("body_layers", 3)
		n.set("double_sided", false)
		n.set("backface_collision", true)     # the cliff shells are one-sided: make their colliders solid from both sides
		var p: Array = m["pos"]
		var s: Array = m.get("scale", [1.0, 1.0, 1.0])
		n.position = Vector3(p[0], p[1], p[2])
		n.rotation.y = deg_to_rad(float(m.get("yaw", 0.0)))
		n.scale = Vector3(s[0], s[1], s[2])
		add_child(n)
