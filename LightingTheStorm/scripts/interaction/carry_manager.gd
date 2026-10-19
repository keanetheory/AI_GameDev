# carry_manager.gd - the Carry autoload (backlog T29): the player's hands.
# One item at a time, held in view in front of the camera. The creator's rule (Decisions to be made, A18): the item
# cannot be put down anywhere except a CarrySocket (the boat's cargo slot, and the lamp socket for T32), so there is
# no drop key and nothing here releases an item into the world.
#
# An item is any Node3D (the burner's model). The first hold remembers its rest transform and how it is held in
# metadata on the item, so a socket can put it down and the hands can pick it up again exactly as before.
# The Interaction autoload and CarrySocket (carry_socket.gd) do the offering and prompts; this only moves the item.
extends Node

signal picked_up(item: Node3D, kind: String)
signal placed(item: Node3D, socket: Node3D)
signal taken(item: Node3D, socket: Node3D)

var held: Node3D = null
var held_kind := ""
var held_label := ""


func _ready() -> void:
	var gs := get_node_or_null("/root/GameState")
	if gs:
		gs.restarted.connect(clear)


func is_holding() -> bool:
	return held != null and is_instance_valid(held)


## Take an item into the hands. False if the hands are already full or there is no player camera.
## `kind` decides which sockets accept it ("burner"); `label` is how prompts name it ("burner").
func hold(item: Node3D, kind: String, label: String, offset: Vector3, rotation_deg: Vector3, item_scale: float) -> bool:
	if item == null or is_holding():
		return false
	var camera := _camera()
	if camera == null:
		return false
	if not item.has_meta("carry_rest"):
		item.set_meta("carry_rest", item.transform)   # where and how big it is when it is not in hands
		item.set_meta("carry_pose", [offset, rotation_deg, item_scale])
	item.set_meta("carry_kind", kind)
	item.set_meta("carry_label", label)
	_attach_to_camera(item, camera)
	held = item
	held_kind = kind
	held_label = label
	picked_up.emit(item, kind)
	return true


## Put the held item into a socket that accepts it. False (and nothing moves) if it does not.
func place(socket: Node3D) -> bool:
	if not is_holding() or not socket.accepts(held_kind):
		return false
	var item := held
	held = null
	held_kind = ""
	held_label = ""
	_set_shadows(item, GeometryInstance3D.SHADOW_CASTING_SETTING_ON)
	socket.receive(item)
	placed.emit(item, socket)
	return true


## Pick the item in a socket back up into the hands. False if the hands are full or the socket is empty.
func take(socket: Node3D) -> bool:
	if is_holding():
		return false
	var camera := _camera()
	var item: Node3D = socket.give() if camera != null else null
	if item == null:
		return false
	_attach_to_camera(item, camera)
	held = item
	held_kind = String(item.get_meta("carry_kind", ""))
	held_label = String(item.get_meta("carry_label", ""))
	taken.emit(item, socket)
	return true


## Forget the held item (the slice restarted; the scene and its items are being replaced).
func clear() -> void:
	held = null
	held_kind = ""
	held_label = ""


func _attach_to_camera(item: Node3D, camera: Camera3D) -> void:
	var pose: Array = item.get_meta("carry_pose")
	item.reparent(camera, false)
	var r: Vector3 = pose[1] * (PI / 180.0)
	item.transform = Transform3D(Basis.from_euler(r).scaled(Vector3.ONE * float(pose[2])), pose[0])
	_set_shadows(item, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)   # a held item must not shadow the view


func _set_shadows(item: Node3D, mode: int) -> void:
	for g in item.find_children("*", "GeometryInstance3D", true, false):
		(g as GeometryInstance3D).cast_shadow = mode as GeometryInstance3D.ShadowCastingSetting


func _camera() -> Camera3D:
	var player := get_tree().get_first_node_in_group("player")
	return player.get_node_or_null("Head/Camera3D") if player else null
