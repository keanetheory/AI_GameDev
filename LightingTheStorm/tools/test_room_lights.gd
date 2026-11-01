# test_room_lights.gd - run: Godot --headless --path . --script res://tools/test_room_lights.gd
# LHF-14: the per-room light cards (room_light_cards.gd) add NO dynamic light (the budget is untouched), cover the lamps and windows, the
# window light follows the phase (brighter in ISLAND than in RETURN, brighter in a lightning flash), the rooms have their own colours,
# and the real-light budget (6 live, 2 shadows) still holds with the player standing in a lamp-rich room.
extends SceneTree

var _lv: Node
var _f := 0
var _lights_before := 0


func _initialize() -> void:
	_lv = load("res://scenes/Level.tscn").instantiate()
	root.add_child(_lv)


func _count_lights(n: Node) -> int:
	var c := 0
	for x in n.find_children("*", "Light3D", true, false):
		c += 1
	return c


var _fails := 0
var _step := 0
var _wait := 0
var _bright := 0.0
var _dim := 0.0
var _rc
var _mgr
var _rig


func _ok(cond: bool, what: String) -> void:
	print(("PASS  " if cond else "FAIL  ") + what)
	if not cond:
		_fails += 1


func _physics_process(_d: float) -> bool:
	_f += 1
	if _f < 20:
		return false
	if _wait > 0:
		_wait -= 1
		return false
	match _step:
		0:
			_rc = _lv.get_node("RoomLightCards")
			_mgr = _lv.get_node("LighthouseInteriorLights")
			_rig = get_first_node_in_group("lighting_rig")
			_ok(_rc.built, "light cards built: %d pools, %d halos, %d window pools" % [_rc.pools.size(), _rc.halos.size(), _rc.window_pools.size()])
			var n: int = _mgr._lights.size()
			_ok(_rc.pools.size() >= int(n * 0.55), "most interior lamps have a floor pool (a lamp hung over the stairwell hole has none: the pool would float over the hole) (%d lamps)" % n)
			# T46: a halo sits on a lamp's own bulb. A bare light with no fixture (the Spiral lights on the stairs) has none, and none hangs in the air
			var floating := 0
			var bare_with_halo := 0
			for hl in _rc.halos:
				var bulb: Node3D = _rc._bulb(hl)
				if bulb == null:
					bare_with_halo += 1
				elif bulb.global_position.distance_to((_rc.halos[hl] as Node3D).global_position) > 0.05:
					floating += 1
			_ok(_rc.halos.size() >= 5 and floating == 0 and bare_with_halo == 0, "every halo sits on its lamp's bulb: %d halos, %d floating, %d on a bare light" % [_rc.halos.size(), floating, bare_with_halo])
			var spiral_halos := 0
			for hl2 in _rc.halos:
				if String((hl2 as Node).name).begins_with("Spiral"):
					spiral_halos += 1
			_ok(spiral_halos == 0, "the stair lights (Spiral1 to 8) have no halo, so no orb floats in the stairwell")
			_ok(_rc.window_pools.size() == 9, "all 9 windows have window light (%d)" % _rc.window_pools.size())
			var own := _count_lights(_rc)
			_ok(own == 0, "the cards add no Light3D nodes (%d)" % own)
			_rig.set_phase("ISLAND", true)
			_wait = 20
			_step = 1
		1:
			_bright = _rc.sky_light()
			_rig.set_phase("RETURN", true)
			_wait = 20
			_step = 2
		2:
			_dim = _rc.sky_light()
			_ok(_bright > _dim and _bright > 0.2, "window light follows the phase: ISLAND %.2f, RETURN %.2f" % [_bright, _dim])
			_rig._bolt.light_energy = 1.6
			var flash: float = _rc.sky_light()
			_rig._bolt.light_energy = 0.0
			_ok(flash > _dim + 0.3, "lightning flashes the windows: %.2f against %.2f" % [flash, _dim])
			var boiler_c := Color.BLACK
			var wash_c := Color.BLACK
			for l in _mgr._lights:
				if String(l.name).begins_with("B_FireLight"):
					boiler_c = l.light_color
				elif String(l.name).begins_with("L1_WashLamp"):
					wash_c = l.light_color
			_ok(boiler_c.r > 0.9 and boiler_c.b < 0.3 and wash_c.b > boiler_c.b + 0.4, "room colours: boiler %s, wash room %s" % [boiler_c, wash_c])
			# stand on a real floor inside the building (the interior lights only come on for a player inside; (5.2, 16, -9) has no floor and the player fell outside)
			(_lv.get_node("Player") as Node3D).global_position = (_lv.get_node("InteriorAnchors").anchors["l1_ring"] as Node3D).global_position + Vector3(0, 0.05, 0)
			_wait = 70
			_step = 3
		3:
			var live: int = _mgr.live_count()
			var sh: int = _mgr.shadow_count()
			_ok(live <= 6 and sh <= 2 and live >= 1, "real lights still within budget: %d live, %d shadowed" % [live, sh])
			print("
%s" % ("ALL PASSED" if _fails == 0 else "%d FAILED" % _fails))
			quit(1 if _fails > 0 else 0)
	return false
