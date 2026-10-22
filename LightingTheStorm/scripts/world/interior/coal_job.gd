# coal_job.gd - the boiler coal job (backlog T33), the first hands-on task: shovel coal from the coal store into the
# boiler's firebox until the pressure gauge climbs, and the dynamo runs. Built on the interaction system and the hands
# (Carry): E at the coal heap takes a shovelful ("[E] Shovel coal"), E at the firebox door feeds it
# ("[E] Shovel the coal into the firebox"). One shovelful at a time, as with the burner.
#   first shovelful -> COAL_LOADED_FIRST, half way -> COAL_LOADED_HALF, the last -> BOILER_FED
# The gauge, the fire's light and the glow in the firebox door climb with each load; at BOILER_FED the engine's flywheel
# starts to turn and the switchboard's green lamp comes on (the Sound agent hooks the dynamo hum at the node
# LHI_Audio_dynamo). Everything here is data on the node: loads needed, the pose of the shovel in the hands.
extends Node

const Interactable := "res://scripts/interaction/interactable.gd"

@export var loads_needed := 6
## How the shovelful is held: low and to the right, the blade forward, tilted down.
@export var held_offset := Vector3(0.28, -0.42, -0.8)
@export var held_rotation_deg := Vector3(-62.0, 18.0, 0.0)
@export var held_scale := 0.75

## Set by rooms_house.gd.
var gauge: Node3D
var fire_light: OmniLight3D
var fire_glow: MeshInstance3D
var flywheel: Node3D
var green_lamp: MeshInstance3D
var shovel_template: Dictionary = {}

var loads := 0
var done := false
var running := false
var _fire_base := 2.0
var _spin := 0.0


func _ready() -> void:
	if fire_light:
		_fire_base = fire_light.light_energy
	_apply()
	var gs := get_node_or_null("/root/GameState")
	if gs and gs.has_signal("restarted") and not gs.restarted.is_connected(reset):
		gs.restarted.connect(reset)


func reset() -> void:
	loads = 0
	done = false
	running = false
	_apply()


## The heap's interaction: take a shovelful into the hands.
func take_shovelful() -> bool:
	var carry := get_node_or_null("/root/Carry")
	if carry == null or carry.is_holding() or done:
		return false
	var shovel := _make_shovel()
	add_child(shovel)      # the hands reparent an item into the camera; it must be in the tree first (a parentless node is never shown)
	if not carry.hold(shovel, "coal", "shovelful of coal", held_offset, held_rotation_deg, held_scale):
		shovel.queue_free()
		return false
	_scoop(shovel)
	return true


## The shovel dips into the heap and comes up loaded: down and forward, the coal appears on the blade, back up to the carry pose.
func _scoop(shovel: Node3D) -> void:
	_set_coal_visible(shovel, false)
	var base := shovel.position
	var base_rot := shovel.rotation
	var tw := shovel.create_tween()
	tw.tween_property(shovel, "position", base + Vector3(0.04, -0.2, -0.22), 0.22).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(shovel, "rotation", base_rot + Vector3(deg_to_rad(28.0), 0.0, 0.0), 0.22)
	tw.tween_callback(_set_coal_visible.bind(shovel, true))
	tw.tween_property(shovel, "position", base + Vector3(0.0, 0.03, 0.02), 0.28).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.parallel().tween_property(shovel, "rotation", base_rot, 0.28)
	tw.tween_property(shovel, "position", base, 0.1)


## The shovel is thrust at the firebox, tipped, the coal goes in, and it is drawn back and put away (the shovelful is spent).
func animate_feed(shovel: Node3D) -> void:
	if not is_instance_valid(shovel):
		return
	var base := shovel.position
	var base_rot := shovel.rotation
	var tw := shovel.create_tween()
	tw.tween_property(shovel, "position", base + Vector3(0.0, 0.1, -0.42), 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(shovel, "rotation", base_rot + Vector3(deg_to_rad(-30.0), 0.0, 0.0), 0.2)
	tw.tween_callback(_set_coal_visible.bind(shovel, false))
	tw.tween_interval(0.1)
	tw.tween_property(shovel, "position", base + Vector3(0.0, -0.3, 0.1), 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.tween_callback(shovel.queue_free)


func _set_coal_visible(shovel: Node3D, v: bool) -> void:
	if not is_instance_valid(shovel):
		return
	for n in shovel.get_children():
		if String(n.name).begins_with("Coal_"):
			(n as Node3D).visible = v


## The firebox's interaction (called by the hatch socket): one shovelful has gone in.
func fed() -> void:
	if done:
		return
	loads += 1
	var gs := get_node_or_null("/root/GameState")
	if gs:
		if loads == 1:
			gs.emit_event("COAL_LOADED_FIRST")
		if loads >= int(ceil(loads_needed * 0.5)):
			gs.emit_event("COAL_LOADED_HALF")      # one-shot in GameState: the repeats are ignored
		if loads >= loads_needed:
			gs.emit_event("BOILER_FED")
	else:
		push_warning("coal_job: no GameState autoload; the coal events were not reported")
	if loads >= loads_needed:
		done = true
		running = true
	_apply()


func _apply() -> void:
	var f := clampf(float(loads) / float(maxi(loads_needed, 1)), 0.0, 1.0)
	if gauge and gauge.has_method("set_level"):
		gauge.set_level(f)
	if fire_light:
		fire_light.light_energy = _fire_base * (0.55 + 0.9 * f)
	if fire_glow:
		var m := fire_glow.material_override as StandardMaterial3D
		if m:
			m.emission_energy_multiplier = 0.8 + 1.6 * f
	if green_lamp:
		green_lamp.visible = true
		var lm := green_lamp.material_override as StandardMaterial3D
		if lm:
			lm.emission_energy_multiplier = 2.5 if running else 0.0
			lm.albedo_color = Color(0.2, 1.0, 0.35) if running else Color(0.08, 0.2, 0.1)


func _process(delta: float) -> void:
	if running and flywheel:
		_spin += delta * 5.5
		flywheel.rotate_object_local(Vector3.UP, delta * 5.5)


## A shovel with coal on the blade: built on demand so the heap is never short of one.
func _make_shovel() -> Node3D:
	var root := Node3D.new()
	root.name = "ShovelOfCoal"
	var handle := MeshInstance3D.new()
	var hm := CylinderMesh.new()
	hm.top_radius = 0.018
	hm.bottom_radius = 0.018
	hm.height = 0.9
	handle.mesh = hm
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color(0.35, 0.22, 0.12)
	wood.roughness = 0.8
	handle.material_override = wood
	handle.position = Vector3(0.0, 0.45, 0.0)
	root.add_child(handle)
	var blade := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.24, 0.035, 0.3)
	blade.mesh = bm
	var iron := StandardMaterial3D.new()
	iron.albedo_color = Color(0.3, 0.3, 0.33)
	iron.metallic = 0.7
	iron.roughness = 0.5
	blade.material_override = iron
	blade.position = Vector3(0.0, 0.0, -0.12)
	root.add_child(blade)
	var coal := StandardMaterial3D.new()
	coal.albedo_color = Color(0.07, 0.07, 0.08)
	coal.roughness = 0.45
	coal.metallic = 0.15
	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	for i in 9:
		var lump := MeshInstance3D.new()
		var lm := BoxMesh.new()
		var s := rng.randf_range(0.05, 0.1)
		lm.size = Vector3(s, s * 0.8, s)
		lump.mesh = lm
		lump.material_override = coal
		lump.name = "Coal_%d" % i
		lump.position = Vector3(rng.randf_range(-0.08, 0.08), 0.04 + rng.randf_range(0.0, 0.04), -0.12 + rng.randf_range(-0.1, 0.1))
		lump.rotation = Vector3(rng.randf() * TAU, rng.randf() * TAU, rng.randf() * TAU)
		root.add_child(lump)
	return root
