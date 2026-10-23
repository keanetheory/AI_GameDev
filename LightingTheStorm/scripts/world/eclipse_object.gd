# eclipse_object.gd - the dark sphere that eclipses the moon (lore: sys_eclipse).
# The sphere is drawn inside the sky shader (storm_sky.gdshader), between the moon and the clouds, so cloud drifts
# in front of it just as it does the moon. This node decides where it is, and how much of the moon is left, and hands
# both to the lighting rig, which dims the moon's light, the sky's moonglow and the sea's foam to match.
# Seen from the player it starts just off the moon's right edge and slides across the disc as the story moves:
#   before the first crossing  touching the moon's right edge
#   end of the outbound leg    its leading edge at the moon's centre line
#   half way along the return  centred on the moon: a total eclipse, the moon a ring round the sphere, and the
#                              lightning the main light on the sea
# The sphere is a little smaller than the moon (size_vs_moon) so the ring shows. It drifts toward its target
# rather than jumping, so a phase change or a reload mid-crossing never pops. The texture is eclipse_albedo.png, the
# model's own albedo at 1024x512 (it is a distant object, so detail is not needed).
extends Node3D

const TEXTURE := "res://Assets/Models/eclipse_object/eclipse_albedo.png"
const SPEC := "res://data/world/lighting_spec.json"

## Radius of the sphere as a multiple of the moon's own disc radius. Under 1 leaves a ring of moon at totality.
@export_range(0.5, 1.5) var size_vs_moon := 0.9
## How hard the dimming follows the moon's uncovered area (1 = in proportion, more = darker sooner).
@export var dim_power := 1.5
## Where along the return the eclipse is total (0 = leaving the Saltgate, 1 = at the lighthouse).
@export_range(0.05, 1.0) var total_at_return := 0.5
## Share of the sky's reflections left once the eclipse is total. They start to fade the moment the return begins.
@export_range(0.0, 1.0) var reflection_floor := 0.12
## Seconds the sphere takes to settle on a new target.
@export var settle_s := 4.0
## Debug: -1 follows the game; 0..1 pins the story: 0 to 0.5 is the outbound crossing, 0.5 to 1 the return.
@export_range(-1.0, 1.0) var force_story := -1.0
## Slow spin so the surface is not a frozen picture (turns per minute); 0 stops it.
@export var spin_turns_min := 0.4

var _dir := Vector3(0.0, 0.37, -0.93)   # towards the moon
var _moon_ang := deg_to_rad(2.42)        # angular radius of the moon disc
var _off := 2.0                          # centre of the sphere right of the moon centre, in moon radii
var _spin := 0.0
var _tex: Texture2D
var _rig: Node
var _gs: Node
var _waves: Node


func _ready() -> void:
	_read_spec()
	if ResourceLoader.exists(TEXTURE):
		_tex = load(TEXTURE) as Texture2D
	if _tex == null:   # not imported yet (a fresh checkout before the editor has scanned): read the file directly
		var img := Image.load_from_file(TEXTURE)
		if img != null:
			img.generate_mipmaps()
			_tex = ImageTexture.create_from_image(img)
	if _tex == null:
		push_error("eclipse_object: cannot read %s" % TEXTURE)
	_gs = get_node_or_null("/root/GameState")
	_off = _target_offset()
	_push()


func _process(delta: float) -> void:
	_off = lerpf(_off, _target_offset(), 1.0 - exp(-delta / maxf(settle_s, 0.01)))
	_spin = fposmod(_spin + spin_turns_min / 60.0 * delta, 1.0)
	_push()


## Where the sphere's centre is, in moon radii right of the moon's centre.
func _target_offset() -> float:
	var k := size_vs_moon
	var phase := String(_gs.phase_name()) if _gs else "ARRIVAL_AND_COAL"
	var p := _route_progress()   # 0 at the lighthouse dock, 1 at the quay
	var story := force_story
	if story < 0.0:
		match phase:
			"OUTBOUND":
				story = 0.5 * p
			"SALTGATE":
				story = 0.5
			"RETURN":
				story = 0.5 + 0.5 * (1.0 - p)
			"FINAL_REPAIR", "RESOLUTION":
				story = 1.0
			_:
				story = 0.0
	if story <= 0.5:
		return lerpf(1.0 + k, k, story * 2.0)      # touching the right edge -> leading edge at the centre line
	return k * (1.0 - clampf((story - 0.5) * 2.0 / total_at_return, 0.0, 1.0))   # -> centred


## Reflected sky: full until the return crossing begins, then fading to reflection_floor by the time the eclipse is total.
func _reflection() -> float:
	var story := force_story
	if story < 0.0:
		var phase := String(_gs.phase_name()) if _gs else ""
		match phase:
			"RETURN":
				story = 0.5 + 0.5 * (1.0 - _route_progress())
			"FINAL_REPAIR", "RESOLUTION":
				story = 1.0
			_:
				return 1.0
	if story <= 0.5:
		return 1.0
	return lerpf(1.0, reflection_floor, clampf((story - 0.5) * 2.0 / total_at_return, 0.0, 1.0))


## Share of the moon's disc still uncovered, 0..1 (circle overlap of the moon, radius 1, and the sphere, radius k).
func _moon_visible(d: float) -> float:
	var k := size_vs_moon
	var overlap := 0.0
	if d >= 1.0 + k:
		overlap = 0.0
	elif d <= absf(1.0 - k):
		overlap = PI * minf(1.0, k) * minf(1.0, k)
	else:
		overlap = k * k * acos(clampf((d * d + k * k - 1.0) / (2.0 * d * k), -1.0, 1.0)) 			+ acos(clampf((d * d + 1.0 - k * k) / (2.0 * d), -1.0, 1.0)) 			- 0.5 * sqrt(maxf((-d + k + 1.0) * (d + k - 1.0) * (d - k + 1.0) * (d + k + 1.0), 0.0))
	return clampf(1.0 - overlap / PI, 0.0, 1.0)


func _route_progress() -> float:
	if _waves == null or not is_instance_valid(_waves):
		_waves = get_tree().get_first_node_in_group("wave_system")
	if _waves != null and _waves.has_method("route_progress"):
		return float(_waves.route_progress())
	return 0.0


func _push() -> void:
	if _rig == null or not is_instance_valid(_rig):
		_rig = get_tree().get_first_node_in_group("lighting_rig")
		if _rig == null:
			return
	# "Right" as the player sees it while facing the moon.
	var right := _dir.cross(Vector3.UP).normalized()
	var r_obj := _moon_ang * size_vs_moon
	var theta := _moon_ang * _off
	var d := (_dir * cos(theta) + right * sin(theta)).normalized()
	var left := pow(_moon_visible(_off), dim_power)
	_rig.set_eclipse(_tex, d, right, r_obj, _spin, left, _reflection())


func _read_spec() -> void:
	var f := FileAccess.open(SPEC, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	if not (parsed is Dictionary) or not parsed.has("moon"):
		return
	var m: Dictionary = parsed["moon"]
	var az := deg_to_rad(float(m["azimuth_deg"]))
	var el := deg_to_rad(float(m["elevation_deg"]))
	_dir = Vector3(sin(az) * cos(el), sin(el), -cos(az) * cos(el)).normalized()
	_moon_ang = deg_to_rad(1.1 * float(m["disc_scale"]))   # same as lighting_rig.gd's moon_radius
