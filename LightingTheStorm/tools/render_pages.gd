# render_pages.gd - one clean, flat, evenly lit picture of every printed page in the lighthouse (posters, notices, charts, logs,
# signs), for sending to an image generator. Each page is a quad with a Label3D "Text" child (kit.gd sheet()). Run WINDOWED (it
# needs the renderer):  Godot --path . --resolution 1200x1200 --quit-after 400 --script res://tools/render_pages.gd -- <out dir>
# Writes <name>.png (the page filling the picture, unshaded, no fog) and pages.json (name, size in metres, text, room, where).
extends SceneTree

const POSTERS := ["Poster_Storms", "Poster_Seasons", "Poster_Moon"]
var _pages: Array = []
var _i := -1
var _f := 0
var _cam: Camera3D
var _out := "res://../GERFramework/pages"
var _manifest: Array = []
var _lv: Node


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() > 0:
		_out = a[0]
	DirAccess.make_dir_recursive_absolute(_out)
	_lv = load("res://scenes/Level.tscn").instantiate()
	root.add_child(_lv)


func _process(_d: float) -> bool:
	_f += 1
	if _f == 5:
		_setup()
		return false
	if _f < 8 or _pages.is_empty():
		return false
	# two frames per page: aim, then capture the frame after
	var step := (_f - 8)
	var idx := step / 3
	var phase := step % 3
	if idx >= _pages.size():
		FileAccess.open(_out.path_join("pages.json"), FileAccess.WRITE).store_string(JSON.stringify(_manifest, "  "))
		print("rendered %d pages to %s" % [_pages.size(), _out])
		quit()
		return false
	var p: MeshInstance3D = _pages[idx]
	if phase == 0:
		_aim(p)
	elif phase == 2:
		_capture(p)
	return false


func _setup() -> void:
	var pl := _lv.get_node_or_null("Player")
	if pl:
		pl.process_mode = Node.PROCESS_MODE_DISABLED
		pl.global_position = Vector3(0, -500, 0)
		for c in pl.find_children("*", "Camera3D", true, false):
			(c as Camera3D).current = false
	for c in root.find_children("*", "CanvasLayer", true, false):      # the HUD, subtitles and prompts (autoloads too)
		(c as CanvasLayer).visible = false
	var we := _lv.get_node_or_null("WorldEnvironment") as WorldEnvironment
	if we and we.environment:
		we.environment.fog_enabled = false
		we.environment.volumetric_fog_enabled = false
		we.environment.background_mode = Environment.BG_COLOR
		we.environment.background_color = Color(0.5, 0.5, 0.5)
	_cam = Camera3D.new()
	_cam.fov = 30.0
	root.add_child(_cam)
	_cam.current = true
	var rooms := _lv.get_node("InteriorRooms")
	for n in rooms.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if not (mi.mesh is QuadMesh):
			continue
		var has_text := mi.get_node_or_null("Text") != null
		if not has_text:
			continue
		if POSTERS.has(String(mi.name)) or mi.visible:
			if not (String(mi.name).begins_with("Poster_") and String(mi.name).ends_with("_Strip")):
				_pages.append(mi)
	# flat, unshaded, fog-free materials on the pages and the poster art
	for p in _pages:
		var mi := p as MeshInstance3D
		mi.visible = true
		var m := (mi.material_override as StandardMaterial3D).duplicate() as StandardMaterial3D
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mi.material_override = m
		(mi.get_node("Text") as Label3D).shaded = false
		(mi.get_node("Text") as Label3D).no_depth_test = false
	for g in rooms.find_children("Poster_*_Art", "Node3D", true, false):
		for gi in g.find_children("*", "MeshInstance3D", true, false):
			var gm := gi as MeshInstance3D
			for s in gm.mesh.get_surface_count():
				var sm := gm.get_active_material(s) as StandardMaterial3D
				if sm:
					var d := sm.duplicate() as StandardMaterial3D
					d.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
					gm.set_surface_override_material(s, d)
	for st in rooms.find_children("Poster_*_Strip", "MeshInstance3D", true, false):
		var sm2 := (st as MeshInstance3D).material_override as StandardMaterial3D
		var d2 := sm2.duplicate() as StandardMaterial3D
		d2.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		(st as MeshInstance3D).material_override = d2
		((st as MeshInstance3D).get_node("Text") as Label3D).shaded = false
	# hide every light's effect: the pages are unshaded, but the lighthouse's props around them should not intrude
	# draw ONLY the pages: they go on visual layer 2 and the camera sees only layer 2, so nothing in the room blocks or lights them
	_cam.cull_mask = 2
	for p in _pages:
		_to_layer2(p)
	for g in rooms.find_children("Poster_*", "Node3D", true, false):
		_to_layer2(g)
	print("pages: %d" % _pages.size())


func _to_layer2(n: Node) -> void:
	if n is VisualInstance3D:
		(n as VisualInstance3D).layers = 2
	for c in n.get_children():
		_to_layer2(c)


func _aim(p: MeshInstance3D) -> void:
	var q := p.mesh as QuadMesh
	var h := maxf(q.size.x, q.size.y)      # the picture is square: fit the longer side
	var d := (h * 0.5) / tan(deg_to_rad(15.0)) * 1.1
	var basis := p.global_transform.basis.orthonormalized()
	_cam.global_position = p.global_position + basis.z * d
	_cam.look_at(p.global_position, basis.y)


func _capture(p: MeshInstance3D) -> void:
	var img := get_root().get_viewport().get_texture().get_image()
	var q := p.mesh as QuadMesh
	var H := img.get_height()
	var longer := maxf(q.size.x, q.size.y)
	var page_h := int(H / 1.1 * q.size.y / longer)
	var page_w := int(H / 1.1 * q.size.x / longer)
	var x0 := (img.get_width() - page_w) / 2
	var y0 := (H - page_h) / 2
	var crop := img.get_region(Rect2i(x0, y0, page_w, page_h))
	var nm := String(p.name)
	crop.save_png(_out.path_join(nm + ".png"))
	var lb := p.get_node("Text") as Label3D
	var room := "ground floor"
	var pos := p.global_position - Vector3(5, 9.61, -8.5)
	if pos.y < -1.0:
		room = "basement"
	elif pos.y > 4.0 and pos.y < 8.0:
		room = "first floor"
	elif pos.y >= 8.0:
		room = "tower"
	_manifest.append({"name": nm, "size_m": [q.size.x, q.size.y], "text": lb.text, "room": room, "image": nm + ".png", "pixels": [page_w, page_h]})
