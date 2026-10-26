# profile_ready.gd - where the level's load time goes, node by node, headless.
#   Godot --headless --path . --script res://tools/profile_ready.gd [-- NodeName ...]   (names given are left out)
# Loads Level.tscn, adds it to the tree (its _ready calls run in the first frame), and timestamps every node's `ready` signal (a node is ready after its children),
# so the gap before each top-level node's ready is roughly what that node and its children cost. Then it times the
# first frames, where the deferred builders (exterior openings, culling, light cards, roof liner, toon scan) run.
# Headless, so this is CPU time only (no GPU upload).
extends SceneTree

const TOP := 15
const FRAMES := 6

var _t0 := 0
var _tf := 0
var _f := 0
var _top: Array = []        # [usec at ready, name] for each top-level node, in ready order
var _last := 0
var _level_ready := 0
var _probe_log: Array = []  # [usec, "first" | "last"] for each physics pass
const PhysProbe := preload("res://tools/profile_phys_probe.gd")
var _steps: Array = []      # usec at each physics step (frame 1 can run several when it is long)


func _initialize() -> void:
	_t0 = Time.get_ticks_usec()
	var lv: Node = (load("res://scenes/Level.tscn") as PackedScene).instantiate()
	var t1 := Time.get_ticks_usec()
	print("PROFILE load+instantiate %6d ms" % ((t1 - _t0) / 1000))
	var drop := OS.get_cmdline_user_args()     # optional: top-level node names to leave out, to see what they cost
	if "nophys" in drop:                        # pause the physics server: is the gap after the first step the step itself?
		PhysicsServer3D.set_active(false)
	for c in lv.get_children():
		if str(c.name) in drop:
			c.free()
	for c in lv.get_children():
		c.ready.connect(_on_ready.bind(str(c.name)))
	lv.ready.connect(func(): _level_ready = Time.get_ticks_usec())
	if "nozones" in drop:                       # stop the interior's zone triggers monitoring: are they the slow first step?
		lv.ready.connect(func():
			for z in get_nodes_in_group("lhi_zone"):
				z.monitoring = false)
	physics_frame.connect(func(): _steps.append(Time.get_ticks_usec()))
	for pri in [-100000, 100000]:               # bracket every node's _physics_process: the rest of a step is the server's
		var probe := Node.new()
		probe.set_script(PhysProbe)
		probe.process_physics_priority = pri
		probe.name = "PhysProbe%d" % pri
		probe.set_meta("log", _probe_log)
		root.add_child(probe)
	_last = Time.get_ticks_usec()
	root.add_child(lv)
	_tf = Time.get_ticks_usec()


func _on_ready(n: String) -> void:
	var now := Time.get_ticks_usec()
	_top.append([now - _last, n])
	_last = now


func _process(_d: float) -> bool:
	_f += 1
	var now := Time.get_ticks_usec()
	print("PROFILE frame %d         %6d ms" % [_f, (now - _tf) / 1000])
	_tf = now
	if _f == 1:         # the scene enters the tree, and every _ready runs, in the first frame
		var sum := 0
		for r in _top:
			sum += r[0]
		_top.sort_custom(func(a, b): return a[0] > b[0])
		print("PROFILE   of which _ready %6d ms" % (sum / 1000))
		print("PROFILE   after _ready (deferred calls, first physics step) %d ms" % ((now - _level_ready) / 1000))
		for e in _probe_log:
			print("PROFILE     node physics pass %-5s at +%d ms" % [e[1], (e[0] - _level_ready) / 1000])
		var prev := _level_ready
		for st in _steps:
			print("PROFILE     physics step at +%d ms (gap %d ms)" % [(st - _level_ready) / 1000, (st - prev) / 1000])
			prev = st
		for i in mini(TOP, _top.size()):
			print("PROFILE     %6d ms  %s" % [_top[i][0] / 1000, _top[i][1]])
		var census := {}                       # body class under each top-level node -> [bodies, shapes]
		for c in root.get_child(root.get_child_count() - 1).get_children():
			for b in c.find_children("*", "CollisionObject3D", true, false):
				var k := "%s %s" % [c.name, b.get_class()]
				if not census.has(k):
					census[k] = [0, 0]
				census[k][0] += 1
				census[k][1] += b.get_shape_owners().size()
		var ks := census.keys()
		ks.sort_custom(func(x, y): return census[x][0] > census[y][0])
		for k in ks.slice(0, 12):
			print("PROFILE   bodies %5d (%d shapes)  %s" % [census[k][0], census[k][1], k])
		print("PROFILE   physics: %d active objects, %d collision pairs, %d islands" % [
				Performance.get_monitor(Performance.PHYSICS_3D_ACTIVE_OBJECTS),
				Performance.get_monitor(Performance.PHYSICS_3D_COLLISION_PAIRS),
				Performance.get_monitor(Performance.PHYSICS_3D_ISLAND_COUNT)])
	if _f == FRAMES:
		print("PROFILE total            %6d ms" % ((now - _t0) / 1000))
		quit()
	return false
