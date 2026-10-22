# lamp_socket.gd - the arc lamp's burner socket: where the player fits the replacement burner (backlog T32, the end of
# the crossing, retrieval and repair loop). It is a CarrySocket (scripts/interaction/carry_socket.gd) that
#   - is offered only while the player is holding a burner ("[E] Fit the burner into the lamp"),
#   - keeps the burner for good (allow_take is off: nothing takes it back out),
#   - on fitting reports BURNER_FITTED to GameState, which moves the game to FINAL_REPAIR and the lighting to
#     BEACON_RELIT, and wakes the lamp (lamp_beacon.gd listens for the same event).
# Once the lamp has come up to full (a few seconds), SHIP_WIN is reported if the ship has not already been lost: the beacon is
# relit in time, the passenger ship is saved (GameState resolves the outcome once; a SHIP_FAIL that came first stands).
# The broken burner (diagnosis, TED_S3) is NOT in the socket: Ted has taken it out and left it on the lamp-room floor.
extends "res://scripts/interaction/carry_socket.gd"

## Set by lantern.gd: the lamp that lights when the burner goes in.
@export var beacon_path: NodePath
## Seconds after the fit before SHIP_WIN: the lamp's rise time plus a beat to see it burning.
@export var win_delay_s := 4.5

var fitted := false


func _init() -> void:
	super._init()
	accepts_kind = "burner"
	allow_take = false
	reach = 3.4
	vertical_reach = 3.2
	aim_height = 0.35
	min_facing = 0.15
	prompt = "Fit the burner"


func prompt_text() -> String:
	var carry := _carry()
	if carry != null and carry.is_holding() and accepts(carry.held_kind):
		return "Fit the burner into the lamp"
	return prompt


func interact(player: Node3D) -> void:
	super.interact(player)
	if item != null and not fitted:
		_on_fitted()


func _on_fitted() -> void:
	fitted = true
	enabled = false
	var gs := get_node_or_null("/root/GameState")
	if gs:
		gs.emit_event("BURNER_FITTED")
	else:
		push_warning("lamp_socket: no GameState autoload; BURNER_FITTED not reported")
	var beacon := get_node_or_null(beacon_path)
	if beacon and beacon.has_method("relight"):
		beacon.relight()
	_win_after_delay()


func _win_after_delay() -> void:
	await get_tree().create_timer(win_delay_s).timeout
	var gs := get_node_or_null("/root/GameState")
	if gs and is_inside_tree() and gs.outcome == gs.Outcome.NONE:
		gs.emit_event("SHIP_WIN")
