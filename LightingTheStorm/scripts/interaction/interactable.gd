# interactable.gd - something the player can use with E (the "interact" action). Backlog T03.
# Put one in the world (or extend this script) and connect `interacted`, or override interact(). The Interaction
# autoload (interaction_manager.gd) picks the best interactable in reach, shows its single prompt and calls interact().
# The prompt is plain text at the bottom of the view: no outline, glow or quest marker (Pillar 3).
#
# Extend it by path, not by class name, so it works in headless tests before the editor has scanned the project:
#     extends "res://scripts/interaction/interactable.gd"
#     func prompt_text() -> String: return "Open the door" if not is_open else "Close the door"
#     func interact(player: Node3D) -> void: toggle()
extends Node3D

## Emitted when the player uses it (after interact() runs its default behaviour).
signal interacted(player: Node3D)

## Shown as "[E] <prompt>". Override prompt_text() when it changes with state.
@export var prompt := "Use"
## Metres (flat) from this node's origin the player must be within.
@export var reach := 2.5
## Metres up or down from the reach point the player may be (2 is a floor either way; a slot on a boat deck seen from
## the dock above it needs more).
@export var vertical_reach := 2.0
## Dot of the view direction and the direction to the aim point; 0.3 is roughly "within 70 degrees of the middle".
@export var min_facing := 0.3
## The point the player has to be looking at, this far above the origin.
@export var aim_height := 1.0
## Off means it is neither offered nor usable. Flip it from the owning script as the story moves on.
@export var enabled := true


func _ready() -> void:
	add_to_group("interactable")


## Override for conditions beyond `enabled` (for example "needs the burner in hand").
func can_interact(_player: Node3D) -> bool:
	return enabled


func prompt_text() -> String:
	return prompt


## Override to do the work. The default only announces the use.
func interact(player: Node3D) -> void:
	interacted.emit(player)


func aim_point() -> Vector3:
	return global_position + Vector3.UP * aim_height


## Where reach is measured from. The origin by default; a door measures from the middle of its doorway.
func reach_point() -> Vector3:
	return global_position


## How good a target this is for the player's camera: -1 if it cannot be used right now, otherwise a number where
## lower is better (nearer and more in the middle of the view).
func focus_score(player: Node3D, camera: Camera3D) -> float:
	if not can_interact(player):
		return -1.0
	var from := reach_point()
	var flat := Vector2(player.global_position.x - from.x, player.global_position.z - from.z)
	if flat.length() > reach or absf(player.global_position.y - from.y) > vertical_reach:
		return -1.0
	var facing := (-camera.global_transform.basis.z).dot((aim_point() - camera.global_position).normalized())
	if facing < min_facing:
		return -1.0
	return flat.length() / maxf(reach, 0.01) + (1.0 - facing)
