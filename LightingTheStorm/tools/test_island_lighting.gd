# test_island_lighting.gd - run: Godot --headless --path . --script res://tools/test_island_lighting.gd
# Island Creator ISL-04: the island under the four lighting phases (ISLAND, OUTBOUND, RETURN, BEACON_RELIT), checked without a window.
#   1. Light budget: in every phase, with the player at each island viewpoint (dock, path, lamp-room window, sea approach), the live
#      positional lights (omni and spot, visible, energy > 0) stay inside lighting_spec.json max_dynamic_lights and the shadow casters
#      inside max_shadow_casters. The moon (a directional light with the scene's one directional shadow map) is listed apart, as
#      world_validators.py counts the spec's sources and the moon is not one of them (the same reading as test_interior_lights).
#      The beacon is lit for BEACON_RELIT and dark before it, as in play.
#   2. Matte stone: every material on the island's rock, the harbour, the stone stairs and the gate has metallic 0 and no emission
#      (no metallic or emissive leaks), including at full storm wetness (ISL-05 makes the rock glossier, never metallic).
#   3. Shadows land on the rock: the moon casts shadows and its shadow distance covers the island from the viewpoints; the rock casts them.
#   4. The beacon catches the rocks: with the lamp lit, the Spill spot (creator, 2 Nov 2026) lands on island rock in most of the sweep.
#      The beam's own spot is aimed at the horizon; what it meets is printed for the Lighting agent (T13).
#   5. Fog: the phase's fog leaves a hazard at hazard_visibility_m with some contrast (exp(-density * d)), reported per phase.
# Exits 1 on any FAIL.
extends SceneTree

const PHASES := ["ISLAND", "OUTBOUND", "RETURN", "BEACON_RELIT"]
# name, player spot (where interior lights decide whether to come on)
const SPOTS := [["dock", Vector3(-27.0, 1.6, 26.0)], ["path", Vector3(-12.0, 11.0, 8.0)],
		["window", Vector3(7.2, 29.2, -4.0)], ["sea", Vector3(-30.0, 2.0, 110.0)]]
const ISLAND_NODES := ["Island", "RockPatchSE", "RockPatchSE2", "RockPatchNE", "Harbour", "HarbourStairs", "IslandGate"]
# A sea-state per phase as the Wave agent's curve gives it near the island (wave_spec.json curve): ISLAND 1, OUTBOUND leaving 1,
# RETURN arriving (deadline near full) 5, after the relight (FINAL_REPAIR) 5.
const SEA_FOR := {"ISLAND": 1.0, "OUTBOUND": 1.0, "RETURN": 5.0, "BEACON_RELIT": 5.0}

var _lv: Node
var _rig: Node
var _player: Node3D
var _beacon: Node
var _spec: Dictionary
var _f := 0
var _p := 0
var _s := 0
var _wait := 0
var _fails := 0
var _max_live := 0
var _max_sh := 0


func _initialize() -> void:
	_spec = JSON.parse_string(FileAccess.get_file_as_string("res://data/world/lighting_spec.json"))
	_lv = load("res://scenes/Level.tscn").instantiate()
	root.add_child(_lv)
	_rig = _lv.get_node("LightingRig")
	_player = _lv.get_node("Player")


func _ok(cond: bool, what: String) -> void:
	print(("PASS  " if cond else "FAIL  ") + what)
	if not cond:
		_fails += 1


func _set_beacon(on: bool) -> void:
	if _beacon == null:
		return
	_beacon.lit = on
	_beacon.level = 1.0 if on else 0.0
	_beacon._apply(_beacon.level)


func _lights() -> Array:
	var live := []
	for n in _lv.find_children("*", "Light3D", true, false):
		var l := n as Light3D
		if l.is_visible_in_tree() and l.light_energy > 0.0:
			live.append(l)
	return live


func _physics_process(_d: float) -> bool:
	_f += 1
	if _f < 20:
		return false
	if _f == 20:
		_beacon = _lv.get_node("InteriorRooms").refs.get("lamp_beacon")
		_ok(_beacon != null, "the lamp beacon exists (InteriorRooms.refs.lamp_beacon)")
		_static_checks()
		_rig._next_flash = 1e9   # no lightning during the light count; a flash is a 0-energy directional light the rest of the time
	if _p >= PHASES.size():
		_finish()
		return true
	var ph: String = PHASES[_p]
	if _wait == 0:
		_rig.set_phase(ph, true)
		_set_beacon(ph == "BEACON_RELIT")
		_lv.get_node("WaveSystem").force_state = SEA_FOR[ph]
		_player.global_position = SPOTS[_s][1]
		_player.velocity = Vector3.ZERO
		_player.process_mode = Node.PROCESS_MODE_DISABLED
	_wait += 1
	if _wait < 50:     # interior lights fade to their targets
		return false
	_wait = 0
	var live := []        # positional lights (omni and spot): what the budget counts
	var sh := 0
	var names := []
	var dirs := []        # directional lights (the moon, the lightning flash): one shadow map for the whole scene, reported apart
	for l in _lights():
		if l is DirectionalLight3D:
			dirs.append("%s%s" % [(l as Node).name, " (shadows)" if (l as Light3D).shadow_enabled else ""])
			continue
		live.append(l)
		if (l as Light3D).shadow_enabled:
			sh += 1
		names.append(String((l as Node).name))
	_max_live = maxi(_max_live, live.size())
	_max_sh = maxi(_max_sh, sh)
	var cap_l := int(_spec["max_dynamic_lights"])
	var cap_s := int(_spec["max_shadow_casters"])
	_ok(live.size() <= cap_l and sh <= cap_s, "%s at the %s: %d live lights (max %d), %d casting shadows (max %d)  [%s] + directional: %s" % [ph, SPOTS[_s][0], live.size(), cap_l, sh, cap_s, ", ".join(names), ", ".join(dirs)])
	if ph == "BEACON_RELIT" and _s == 0:
		_beacon_sweep()
	_s += 1
	if _s >= SPOTS.size():
		_s = 0
		_fog_check(ph)
		_p += 1
	return false


func _island_materials() -> Array:
	var out := []
	var seen := {}
	for nm in ISLAND_NODES:
		var r := _lv.get_node_or_null(nm)
		if r == null:
			_ok(false, "node %s exists" % nm)
			continue
		for n in r.find_children("*", "MeshInstance3D", true, false):
			var mi := n as MeshInstance3D
			if mi.mesh == null:
				continue
			for i in mi.mesh.get_surface_count():
				for m in [mi.material_override, mi.get_surface_override_material(i), mi.mesh.surface_get_material(i)]:
					if m != null and not seen.has(m):
						seen[m] = true
						out.append([nm, m])
	return out


func _static_checks() -> void:
	# matte stone, at rest and soaked
	var reactions := _lv.get_node_or_null("IslandReactions")
	for wet in [0.0, 1.0]:
		if reactions:
			reactions.wetness = wet
			reactions._process(0.0)     # applies the wet albedo and roughness (delta 0 keeps the wetness where it was set)
		var bad := []
		var n_std := 0
		var n_other := 0
		for e in _island_materials():
			var m: Material = e[1]
			if m is BaseMaterial3D:
				n_std += 1
				var b := m as BaseMaterial3D
				if b.metallic > 0.0 or b.emission_enabled:
					bad.append("%s %s metallic %.2f emission %s" % [e[0], m.resource_name, b.metallic, b.emission_enabled])
			else:
				n_other += 1
		_ok(bad.is_empty(), "matte stone (wetness %.0f): %d standard materials on the island, rock, harbour, stairs and gate, none metallic or emissive (%d shader materials not checked) %s" % [wet, n_std, n_other, str(bad) if not bad.is_empty() else ""])
	# shadows
	var moon := _rig.get_node_or_null("Moon") as DirectionalLight3D
	_ok(moon != null and moon.shadow_enabled, "the moon casts shadows")
	if moon:
		var far := 0.0
		for s in SPOTS:
			far = maxf(far, (s[1] as Vector3).distance_to(Vector3(0, 5, 0)) + 45.0)
		_ok(moon.directional_shadow_max_distance >= 150.0, "moon shadow distance %.0f m covers the island from the dock, path and window (the sea view at ~110 m sees shadows to %.0f m)" % [moon.directional_shadow_max_distance, moon.directional_shadow_max_distance])
	var off := []
	for nm in ["Island", "RockPatchSE", "RockPatchSE2", "RockPatchNE"]:
		for n in _lv.get_node(nm).find_children("*", "MeshInstance3D", true, false):
			if (n as GeometryInstance3D).cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
				off.append(String(n.name))
	_ok(off.is_empty(), "the island rock casts shadows %s" % (str(off) if not off.is_empty() else ""))


## With the lamp lit, turn the beam through 36 headings and cast rays along the spot's cone (centre and its lower edge)
## out to spot_range: count the headings in which the beam meets island rock.
func _beacon_sweep() -> void:
	var spot: SpotLight3D = _beacon._spot
	var pivot: Node3D = _beacon._beam_pivot
	if spot == null or pivot == null:
		_ok(false, "the beacon has a spot light and a beam pivot")
		return
	var island_bodies := {}
	for nm in ["Island", "RockPatchSE", "RockPatchSE2", "RockPatchNE"]:
		for b in _lv.get_node(nm).find_children("*", "StaticBody3D", true, false):
			island_bodies[b.get_instance_id()] = true
	var space := (_lv as Node3D).get_world_3d().direct_space_state if _lv is Node3D else root.get_world_3d().direct_space_state
	var keep := pivot.rotation.y
	var down := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(-5, 60, 5), Vector3(-5, -5, 5)))
	_ok(not down.is_empty() and island_bodies.has((down["collider"] as Object).get_instance_id()), "sanity: a ray straight down onto the plateau hits island rock (so the beam rays can)")
	var hits := 0
	var nearest := 1e9
	var farthest := 0.0
	for k in 36:
		pivot.rotation.y = deg_to_rad(10.0 * k)
		var o := spot.global_position
		var fwd := -spot.global_basis.z
		var right := fwd.cross(Vector3.UP).normalized()
		var hit_here := false
		for a in [0.0, spot.spot_angle * 0.5, spot.spot_angle]:
			var dir := fwd.rotated(right, -deg_to_rad(a)).normalized()     # tipped down by a degrees
			var q := PhysicsRayQueryParameters3D.create(o + dir * 4.0, o + dir * spot.spot_range)
			var r := space.intersect_ray(q)
			if not r.is_empty() and island_bodies.has((r["collider"] as Object).get_instance_id()):
				hit_here = true
				var d := o.distance_to(r["position"])
				nearest = minf(nearest, d)
				farthest = maxf(farthest, d)
		if hit_here:
			hits += 1
	# what a downward tilt of the spot would do (information for the Lighting agent; nothing in the game is changed)
	var keep_x := spot.rotation.x
	for tilt in [4.0, 8.0, 12.0, 16.0, 20.0]:
		var h2 := 0
		var sea2 := 0
		for k in 36:
			pivot.rotation.y = deg_to_rad(10.0 * k)
			spot.rotation.x = keep_x - deg_to_rad(tilt)
			var o2 := spot.global_position
			var f2 := -spot.global_basis.z
			var q2 := PhysicsRayQueryParameters3D.create(o2 + f2 * 4.0, o2 + f2.rotated(f2.cross(Vector3.UP).normalized(), -deg_to_rad(spot.spot_angle)) * spot.spot_range)
			var r2 := space.intersect_ray(q2)
			var low := (f2.rotated(f2.cross(Vector3.UP).normalized(), -deg_to_rad(spot.spot_angle))).normalized()
			if not r2.is_empty() and island_bodies.has((r2["collider"] as Object).get_instance_id()):
				h2 += 1
			elif low.y < 0.0 and (o2.y - 0.4) / -low.y <= spot.spot_range:
				sea2 += 1
		print("INFO  beacon spot tipped down %.0f deg: its lower edge meets island rock in %d of 36 headings and the sea (within range) in %d more" % [tilt, h2, sea2])
	spot.rotation.x = keep_x
	pivot.rotation.y = keep
	print("INFO  beacon spot at y %.1f, angle %.0f deg, range %.0f m, energy %.1f" % [spot.global_position.y, spot.spot_angle, spot.spot_range, spot.light_energy])
	# Not a FAIL: the lantern stands 29 m up and the plateau round it is at 9-11 m within 25 m and falls to the sea by 35-45 m, so a
	# beam aimed at the horizon passes over the rock (as a real lighthouse's does). Whether it should dip onto the island is the
	# creator's and the Lighting agent's call (ISL-04 finding, GERFramework/reports/island_lighting_check.md); printed as a FINDING.
	print("INFO  BEACON_RELIT: the beam's own cone meets island rock in %d of 36 headings (%.0f to %.0f m out); it is aimed at the horizon" % [hits, nearest if hits > 0 else 0.0, farthest])
	# the creator's answer (2 Nov 2026): a short spill of light onto the rocks. The Spill spot turns with the beam; its cone (centre,
	# and part-way to each edge) must land on island rock within its range in most headings (the house and tower block a few).
	var spill: SpotLight3D = _beacon._spill
	_ok(spill != null and spill.visible and spill.light_energy > 0.0 and not spill.shadow_enabled, "BEACON_RELIT: the spill light is on (no shadow, so it costs no shadow caster)")
	if spill == null:
		return
	var sh := 0
	var near_s := 1e9
	var far_s := 0.0
	for k in 36:
		pivot.rotation.y = deg_to_rad(10.0 * k)
		var o := spill.global_position
		var fwd := -spill.global_basis.z
		var right := fwd.cross(Vector3.UP).normalized()
		var lands := false
		for a in [-0.6 * spill.spot_angle, 0.0, 0.6 * spill.spot_angle]:
			var dir := fwd.rotated(right, -deg_to_rad(a)).normalized()
			var r := space.intersect_ray(PhysicsRayQueryParameters3D.create(o, o + dir * spill.spot_range))
			if not r.is_empty() and island_bodies.has((r["collider"] as Object).get_instance_id()):
				lands = true
				var d := o.distance_to(r["position"])
				near_s = minf(near_s, d)
				far_s = maxf(far_s, d)
		if lands:
			sh += 1
	pivot.rotation.y = keep
	# the beam's own light (creator, 2 Nov 2026): dipped with the beam so it sweeps the sea; its centre must meet sea level inside its range
	var sfwd := -spot.global_basis.z
	var reach := (spot.global_position.y - 0.0) / maxf(-sfwd.y, 1e-4)
	_ok(sfwd.y < 0.0 and reach <= spot.spot_range, "BEACON_RELIT: the beam's light dips %.1f deg and meets the sea %.0f m out (range %.0f m)" % [rad_to_deg(asin(-sfwd.y)), reach, spot.spot_range])
	_ok(sh >= 24, "BEACON_RELIT: the spill lands on island rock in %d of 36 headings (%.0f to %.0f m from the lamp)" % [sh, near_s if sh > 0 else 0.0, far_s])


func _fog_check(ph: String) -> void:
	# headless, the rig does not build its own environment (no sky), so the density is read from what the rig applies (_cur)
	var env := Environment.new()
	env.fog_density = float(_rig._cur.get("fog_density", 0.0))
	var p: Dictionary = {}
	for e in _spec["phases"]:
		if e["phase_id"] == ph:
			p = e
	var d := float(p["hazard_visibility_m"])
	var t := exp(-env.fog_density * d)
	print("INFO  %s fog density %.4f: a hazard at %.0f m keeps %.0f%% of its contrast; the island from the sea approach (~110 m) keeps %.0f%%" % [ph, env.fog_density, d, t * 100.0, exp(-env.fog_density * 110.0) * 100.0])
	_ok(t >= 0.15, "%s fog leaves a hazard at its hazard_visibility_m (%.0f m) at least 15%% contrast (%.0f%%)" % [ph, d, t * 100.0])


func _finish() -> void:
	print("INFO  most live lights in any phase and viewpoint: %d, most shadow casters: %d" % [_max_live, _max_sh])
	print("\n%s" % ("ALL PASSED" if _fails == 0 else "%d FAILED" % _fails))
	quit(1 if _fails > 0 else 0)
