# carry_socket.gd - the only places a carried item can be put down (backlog T29): the boat's cargo slot, and the
# lamp socket (T32). It is an Interactable, so the Interaction autoload offers it and shows its prompt:
#   holding something it accepts, and empty     -> "[E] Put the burner down"
#   holding nothing, and it holds an item       -> "[E] Pick up the burner"   (unless allow_take is off)
# The item is parented to this node, so a socket that is a child of the boat's rig carries the item with the boat,
# through waves and hazard recoveries.
#
# For a socket that keeps what it is given for good (the lamp), set allow_take = false and listen to `placed`.
extends "res://scripts/interaction/interactable.gd"

## The item went in / came out. Both carry the item node.
signal placed(item: Node3D)
signal taken(item: Node3D)

## Which kind of item fits ("burner"). Empty accepts any.
@export var accepts_kind := ""
## false: whatever goes in stays (the lamp socket). The prompt to take it out is never offered.
@export var allow_take := true
## Where the item sits, in this node's space.
@export var mount_offset := Vector3.ZERO
@export var mount_rotation_deg := Vector3.ZERO

var item: Node3D = null


func _init() -> void:
	reach = 3.0
	aim_height = 0.4


func accepts(kind: String) -> bool:
	return item == null and (accepts_kind == "" or accepts_kind == kind)


func can_interact(_player: Node3D) -> bool:
	if not enabled:
		return false
	var carry := _carry()
	if carry == null:
		return false
	if carry.is_holding():
		return accepts(carry.held_kind)
	return item != null and allow_take


func prompt_text() -> String:
	var carry := _carry()
	if carry != null and carry.is_holding():
		return "Put the %s down" % carry.held_label
	if item != null:
		return "Pick up the %s" % String(item.get_meta("carry_label", "item"))
	return prompt


func interact(player: Node3D) -> void:
	var carry := _carry()
	if carry == null:
		return
	if carry.is_holding():
		carry.place(self)
	else:
		carry.take(self)
	interacted.emit(player)


## Called by Carry.place(): the item comes to rest here.
func receive(node: Node3D) -> void:
	var rest: Transform3D = node.get_meta("carry_rest", Transform3D.IDENTITY)
	node.reparent(self, false)
	node.transform = Transform3D(Basis.from_euler(mount_rotation_deg * (PI / 180.0)).scaled(rest.basis.get_scale()), mount_offset)
	item = node
	placed.emit(node)


## Called by Carry.take(): hands the item over and empties the socket.
func give() -> Node3D:
	var node := item
	if node == null or not allow_take:
		return null
	item = null
	taken.emit(node)
	return node


func _carry() -> Node:
	return get_node_or_null("/root/Carry")
