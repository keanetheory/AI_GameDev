# lamp_beacon.gd - the arc lamp itself: dark and cold until the burner is fitted, then it comes up over a few seconds and
# throws a sweeping beam out over the water. A placeholder look for Gate 1 (the Lighting agent owns the final beacon,
# backlog T13); everything it needs is exported so it can be re-tuned or replaced.
# It lights on relight(), which the lamp socket calls, and also on the BURNER_FITTED event from GameState, so a debug
# jump or another script that fires the event lights it too. It never lights twice.
extends Node3D

## Seconds for the lamp to come up to full.
@export var rise_s := 3.5
## Degrees a second the beam sweeps.
@export var sweep_deg_s := 28.0
@export var beam_length := 70.0
@export var beam_end_radius := 5.0
@export var lens_energy := 0.22
## The lit lamp's colour: warm gold, the style guide's amber and gold (it was a cold white that blew the lens out to flat white).
## How dark the lamp is before the burner is fitted (1 = as modelled).
const DARK := 0.32
@export var lit_colour := Color(1.0, 0.84, 0.5)
@export var glow_light_energy := 1.0
@export var glow_light_range := 12.0

## Seconds the open lamp stays open after the burner is fitted, so the burner is seen seated before the bay closes.
@export var close_delay_s := 1.2

var lit := false
var _closing_in := -1.0
var level := 0.0                  # 0 dark .. 1 full

var _lens_mats: Array[StandardMaterial3D] = []
var _glow: OmniLight3D
var _beam_pivot: Node3D
var _beam_mat: ShaderMaterial
var _spot: SpotLight3D
var _core: MeshInstance3D


## Called by lantern.gd once the lamp's parts are all in place (they are added after this node enters the tree).
func setup() -> void:
	_glow = get_node_or_null("Glow") as OmniLight3D
	_beam_pivot = get_node_or_null("BeamPivot") as Node3D
	_spot = get_node_or_null("BeamPivot/Spot") as SpotLight3D
	_core = get_node_or_null("Core") as MeshInstance3D
	# the generated lamp's own materials, copied so the shared ones are untouched
	for n in find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if mi.name.begins_with("Core") or mi.mesh == null:
			continue
		for i in mi.mesh.get_surface_count():
			var src := mi.get_active_material(i) as StandardMaterial3D
			if src == null:
				continue
			var m := src.duplicate() as StandardMaterial3D
			m.emission_texture = m.albedo_texture
			m.set_meta("base_albedo", m.albedo_color)
			mi.set_surface_override_material(i, m)
			_lens_mats.append(m)
	var beam := get_node_or_null("BeamPivot/Beam") as MeshInstance3D
	if beam:
		_beam_mat = beam.material_override as ShaderMaterial
	_apply(0.0)
	var gs := get_node_or_null("/root/GameState")
	if gs and gs.has_signal("event_emitted"):
		gs.event_emitted.connect(_on_event)


func _on_event(id: String, _phase: int) -> void:
	if id == "BURNER_DIAGNOSED":
		_show_open(true)
	elif id == "BURNER_FITTED":
		_closing_in = close_delay_s
		relight()


## The lamp shows closed, then open and empty from the diagnosis, then closed again once the burner is fitted.
func _show_open(open: bool) -> void:
	var closed := get_node_or_null("LampModel") as Node3D
	var opened := get_node_or_null("LampModelOpen") as Node3D
	if closed == null or opened == null:
		return
	closed.visible = not open
	opened.visible = open


func relight() -> void:
	lit = true


func _process(delta: float) -> void:
	if _closing_in >= 0.0:
		_closing_in -= delta
		if _closing_in < 0.0:
			_show_open(false)
	if lit and level < 1.0:
		level = minf(1.0, level + delta / maxf(rise_s, 0.01))
		_apply(level)
	if level > 0.0 and _beam_pivot:
		_beam_pivot.rotation.y += deg_to_rad(sweep_deg_s) * delta


func _apply(v: float) -> void:
	var e := v * v * (3.0 - 2.0 * v)       # smoothstep: the arc strikes, then settles
	for m in _lens_mats:
		var base: Color = m.get_meta("base_albedo", Color.WHITE)
		m.albedo_color = (base * lerpf(DARK, 1.0, e)).lerp(base * lit_colour * 0.9, e * 0.5)       # cold and dark until the arc strikes, then warm
		m.emission_enabled = e > 0.01
		m.emission = lit_colour
		m.emission_energy_multiplier = lens_energy * e
	if _glow:
		_glow.light_color = lit_colour
		_glow.light_energy = glow_light_energy * e
		_glow.omni_range = glow_light_range
		_glow.visible = e > 0.01
	if _spot:
		_spot.light_color = lit_colour
		_spot.light_energy = 14.0 * e
		_spot.visible = e > 0.01
	if _beam_mat:
		_beam_mat.set_shader_parameter("strength", 0.34 * e)
		_beam_mat.set_shader_parameter("tint", Vector3(lit_colour.r, lit_colour.g, lit_colour.b))
	if _core:
		_core.visible = e > 0.01
		var cm := _core.material_override as StandardMaterial3D
		if cm:
			cm.emission_energy_multiplier = 6.0 * e
	if _beam_pivot:
		_beam_pivot.visible = e > 0.01
