# test_toon_look.gd - run: Godot --headless --path . --script res://tools/test_toon_look.gd
# LHF-10: the cel-shaded sample is scoped to the basement. Basement meshes get toon materials, the ground floor and above do not,
# switching it off restores the original materials, and the outline quad is built. (The look itself is checked with a shot.)
extends SceneTree

var _lv: Node
var _f := 0


func _initialize() -> void:
	_lv = load("res://scenes/Level.tscn").instantiate()
	root.add_child(_lv)


func _is_toon(mi: MeshInstance3D) -> bool:
	var mats: Array = [mi.material_override]
	for i in mi.mesh.get_surface_count():
		mats.append(mi.get_surface_override_material(i))
		mats.append(mi.mesh.surface_get_material(i))
	for m in mats:
		if m is StandardMaterial3D and (m as StandardMaterial3D).diffuse_mode == BaseMaterial3D.DIFFUSE_TOON:
			return true
	return false


func _physics_process(_d: float) -> bool:
	_f += 1
	if _f < 10:
		return false
	var tl = _lv.get_node("ToonLook")
	var fails := 0
	var ok: bool = tl.toon_count > 25 and tl.mesh_count > 100
	print(("PASS  " if ok else "FAIL  ") + "materials switched to toon: %d (over %d meshes)" % [tl.toon_count, tl.mesh_count])
	fails += int(not ok)
	var rooms := _lv.get_node("InteriorRooms")
	var samples := {"B_FireFrame_L": "basement", "Poster_Storms": "ground floor", "Step_50": "tower step", "L2_TowerRing": "L2 ring"}
	var mis := {}
	for nm in samples:
		var mi := rooms.find_child(nm, true, false) as MeshInstance3D
		mis[nm] = mi
		var good := mi != null and _is_toon(mi)
		print(("PASS  " if good else "FAIL  ") + "%s mesh (%s) is toon" % [samples[nm], nm])
		fails += int(not good)
	var ext = _lv.get_node("LighthouseWallDetail")
	var e_ok: bool = ext.toon and ext.swapped > 0
	print(("PASS  " if e_ok else "FAIL  ") + "the exterior wall shader is on toon (%d surfaces)" % ext.swapped)
	fails += int(not e_ok)
	var q_ok: bool = tl._outline != null and tl._outline.mesh is QuadMesh
	print(("PASS  " if q_ok else "FAIL  ") + "outline quad built")
	fails += int(not q_ok)
	tl.set_enabled(false)
	var off_ok := true
	for nm in mis:
		if mis[nm] != null and _is_toon(mis[nm]):
			off_ok = false
	off_ok = off_ok and not ext.toon
	print(("PASS  " if off_ok else "FAIL  ") + "switched off: every sample is back to its original look")
	fails += int(not off_ok)
	tl.set_enabled(true)
	var again: bool = _is_toon(mis["Step_50"]) and ext.toon
	print(("PASS  " if again else "FAIL  ") + "switched on again")
	fails += int(not again)
	# the interior fill: a wall material gives off some of its own colour (so a wall beyond the nearest lamp keeps its colour) and no fog touches it;
	# the arc lamp's lens stays dark; switching the look off restores both
	var wall := rooms.find_child("G_Panel_West", true, false) as MeshInstance3D
	var wm: StandardMaterial3D = null
	if wall:
		wm = (wall.material_override as StandardMaterial3D) if wall.material_override is StandardMaterial3D else (wall.mesh.surface_get_material(0) as StandardMaterial3D)
	var fill_ok: bool = wm != null and wm.emission_enabled and wm.disable_fog and wm.emission_energy_multiplier > 0.05
	print(("PASS  " if fill_ok else "FAIL  ") + "an interior wall material carries the fill and ignores the distance fog")
	fails += int(not fill_ok)
	var lens_dark := true
	for lm in rooms.find_children("*", "MeshInstance3D", true, false):
		var lmi := lm as MeshInstance3D
		if lmi.mesh == null or lmi.mesh.get_surface_count() == 0:
			continue
		var lmm := lmi.get_surface_override_material(0) as StandardMaterial3D
		if lmm != null and lmm.has_meta("base_albedo") and lmm.emission_enabled:
			lens_dark = false
	print(("PASS  " if lens_dark else "FAIL  ") + "the arc lamp's lens is not filled (it stays dark until the burner is fitted)")
	fails += int(not lens_dark)
	tl.set_enabled(false)
	var restored: bool = wm != null and not wm.emission_enabled and not wm.disable_fog
	print(("PASS  " if restored else "FAIL  ") + "switched off: the wall material is back to unlit and fogged")
	fails += int(not restored)
	tl.set_enabled(true)
	print("
%s" % ("ALL PASSED" if fails == 0 else "%d FAILED" % fails))
	quit(1 if fails > 0 else 0)
	return false
