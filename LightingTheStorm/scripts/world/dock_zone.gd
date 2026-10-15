# dock_zone.gd - an auto-dock zone (DOCK_LIGHTHOUSE, DOCK_PORT in boat_spec.json).
# Place this node at the boat's berth. A sailing boat that enters `radius` is slowed,
# eased into the berth and tied up. `landing` is where the player steps out onto the dock.
extends Marker3D

@export var zone_id := "DOCK_LIGHTHOUSE"
@export var radius := 12.0
## Heading the boat ties up at, degrees about Y (0 = bow towards -Z).
@export var berth_yaw_deg := 0.0
## World position the player is placed at when stepping off the boat.
@export var landing := Vector3.ZERO


func _ready() -> void:
	add_to_group("dock_zone")
