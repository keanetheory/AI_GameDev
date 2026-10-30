# jaw_lipsync.gd - Godot 4.3 / GDScript
# Drives a character's "mixamorig:Jaw" bone (imported by Godot as "mixamorig_Jaw"; tools/add_jaw_bone.py adds it to a Meshy rig) from voice loudness, or from a procedural flap while a
# line is "spoken" but no audio is playing (dialogue_loader's auto_advance mode).
#
# Setup:
#  1. Attach to the character's root node (the imported ted.glb scene).
#  2. Play that character's voice audio on the bus named `voice_bus` (default "Voice"). The script
#     creates the bus and a spectrum analyser on it if they are missing.
#  3. Optional: set `dialogue_loader` to the DialogueLoader node and `speaker_id` to "TED" so the
#     procedural flap runs for that speaker's lines when no audio is playing.
# The jaw only moves when the analyser hears the voice bus (or the procedural flap is on), so it
# never fights an AnimationPlayer: no animation needs a jaw track.
extends Node

@export var skeleton_path: NodePath  ## Leave empty to find the first Skeleton3D under the parent.
@export var jaw_bone := "mixamorig:Jaw"
@export var voice_bus := "Voice"
@export var max_open_deg := 18.0  ## Fully loud syllable. Keep this small; the face is a flat texture.
@export var open_axis := Vector3.RIGHT  ## Bone-local axis the jaw hinges on. See the note below.
@export var open_sign := 1.0  ## Flip to -1.0 if the jaw closes into the neck instead of opening.
@export var attack := 25.0  ## Higher = jaw opens faster.
@export var release := 12.0  ## Higher = jaw closes faster.
@export var noise_floor_db := -50.0  ## Voice quieter than this leaves the jaw shut.
@export var loud_db := -18.0  ## Voice at this level opens the jaw fully.

@export_group("Dialogue link")
@export var dialogue_loader: Node
@export var speaker_id := "TED"
@export var flap_hz := 5.5  ## Procedural flap rate when no audio is playing.

var _skeleton: Skeleton3D
var _jaw_idx := -1
var _rest_rot := Quaternion.IDENTITY
var _analyser: AudioEffectInstance
var _open := 0.0
var _speaking_text := false
var _flap_t := 0.0

# Note on axis/sign: the jaw bone was made in Blender and opens by rotating about its local X. Checked on the Meshy "Ironclad
# Mariner" rig (tools/probe_jaw_axis.gd): Vector3.RIGHT and +1.0 swing the chin down. If another rig differs, change open_axis
# (try Vector3.RIGHT, UP, FORWARD) and open_sign until it opens downward.


func _ready() -> void:
	_skeleton = get_node_or_null(skeleton_path) as Skeleton3D
	if _skeleton == null:
		var found := get_parent().find_children("*", "Skeleton3D", true, false)
		if not found.is_empty():
			_skeleton = found[0] as Skeleton3D
	if _skeleton == null:
		push_error("jaw_lipsync: no Skeleton3D found")
		set_process(false)
		return
	_jaw_idx = _skeleton.find_bone(jaw_bone)
	if _jaw_idx < 0:
		# Godot's glTF import turns the ':' of Mixamo bone names into '_' ("mixamorig_Jaw"); accept that, or any bone ending in "Jaw"
		_jaw_idx = _skeleton.find_bone(jaw_bone.replace(":", "_"))
	if _jaw_idx < 0:
		for i in _skeleton.get_bone_count():
			if _skeleton.get_bone_name(i).ends_with("Jaw"):
				_jaw_idx = i
				break
	if _jaw_idx < 0:
		push_error("jaw_lipsync: bone '%s' not found; is this the jaw-rigged ted.glb?" % jaw_bone)
		set_process(false)
		return
	_rest_rot = _skeleton.get_bone_rest(_jaw_idx).basis.get_rotation_quaternion()
	_setup_bus()
	if dialogue_loader:
		dialogue_loader.line_started.connect(_on_line_started)
		dialogue_loader.line_finished.connect(_on_line_finished)


func _setup_bus() -> void:
	var bus := AudioServer.get_bus_index(voice_bus)
	if bus < 0:
		AudioServer.add_bus()
		bus = AudioServer.bus_count - 1
		AudioServer.set_bus_name(bus, voice_bus)
		AudioServer.set_bus_send(bus, "Master")
	for i in AudioServer.get_bus_effect_count(bus):
		if AudioServer.get_bus_effect(bus, i) is AudioEffectSpectrumAnalyzer:
			_analyser = AudioServer.get_bus_effect_instance(bus, i)
			return
	AudioServer.add_bus_effect(bus, AudioEffectSpectrumAnalyzer.new())
	_analyser = AudioServer.get_bus_effect_instance(bus, AudioServer.get_bus_effect_count(bus) - 1)


func _process(delta: float) -> void:
	var target := _voice_level()
	if target <= 0.0 and _speaking_text:
		_flap_t += delta
		# Two out-of-phase sines give an uneven, speech-like rhythm rather than a metronome.
		target = clampf(0.45 + 0.35 * sin(_flap_t * TAU * flap_hz) + 0.2 * sin(_flap_t * TAU * flap_hz * 0.37), 0.0, 1.0)
	var rate := attack if target > _open else release
	_open = lerpf(_open, target, 1.0 - exp(-rate * delta))
	var angle := deg_to_rad(max_open_deg) * _open * open_sign
	_skeleton.set_bone_pose_rotation(_jaw_idx, _rest_rot * Quaternion(open_axis.normalized(), angle))


## 0..1 loudness of the speech band (roughly 150 Hz - 4 kHz) on the voice bus.
func _voice_level() -> float:
	if _analyser == null:
		return 0.0
	var mag := (_analyser as AudioEffectSpectrumAnalyzerInstance).get_magnitude_for_frequency_range(150.0, 4000.0)
	var db := linear_to_db(mag.length())
	return clampf(inverse_lerp(noise_floor_db, loud_db, db), 0.0, 1.0)


## Call directly to make the jaw flap for a fixed time (cutscenes, barks without audio).
func talk_for(seconds: float) -> void:
	_speaking_text = true
	await get_tree().create_timer(seconds).timeout
	_speaking_text = false


func _on_line_started(_line_id: String, speaker: String, _subtitle: String, _delivery: String) -> void:
	_speaking_text = speaker == speaker_id
	_flap_t = 0.0


func _on_line_finished(_line_id: String) -> void:
	_speaking_text = false
