# burner_pickup.gd - the replacement burner on the Saltgate quay (backlog T06 and T29).
# E picks it up when the player is close and facing it. It then rides in front of the camera, in the lower half of
# the view, through boarding, the return crossing and beyond; it cannot be put down (only the lamp fit, T32, takes
# it). Picking it up reports BURNER_PICKED_UP to GameState, which lets casting off from DOCK_PORT start RETURN.
# The hands are the Carry autoload (scripts/interaction/carry_manager.gd); the burner can only be put down in a
# CarrySocket (the boat's cargo slot, then the lamp). The boat keeps its own E (board, cast off), so this sits
# outside the boat's board_radius.
# It is an Interactable (scripts/interaction/): the Interaction autoload owns the prompt, the reach and facing test
# and the E key; this script only says what E does.
extends "res://scripts/interaction/interactable.gd"

## Held pose in camera space: low and centred, so the burner fills the lower half of the screen.
@export var held_offset := Vector3(0.0, -0.5, -0.8)
@export var held_rotation_deg := Vector3(8.0, 25.0, 0.0)
@export var held_scale := 0.45

## True while the burner is in the player's hands (not while it sits in a socket).
var held: bool:
	get:
		var carry := get_node_or_null("/root/Carry")
		return carry != null and carry.is_holding() and carry.held == _model

var _model: Node3D
var _picked := false


func _init() -> void:
	prompt = "Pick up the burner"
	aim_height = 0.45


func _ready() -> void:
	super._ready()
	add_to_group("burner")
	_model = get_node_or_null("Model")
	if _model == null:
		push_error("burner_pickup: no 'Model' child to pick up")


func can_interact(_player: Node3D) -> bool:
	return enabled and not _picked


func interact(player: Node3D) -> void:
	pick_up()
	interacted.emit(player)


## Take the burner into the player's hands. Also used by tools/test_burner_pickup.gd.
func pick_up() -> void:
	var carry := get_node_or_null("/root/Carry")
	if _picked or _model == null or carry == null:
		return
	if not carry.hold(_model, "burner", "burner", held_offset, held_rotation_deg, held_scale):
		return   # no player camera yet, or the hands are full
	_picked = true
	var gs := get_node_or_null("/root/GameState")
	if gs:
		gs.emit_event("BURNER_PICKED_UP")
	else:
		push_warning("burner_pickup: no GameState autoload; BURNER_PICKED_UP not reported")
