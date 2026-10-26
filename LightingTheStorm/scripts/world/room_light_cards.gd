# room_light_cards.gd - per-room light plans as cheap fake light (Lighthouse Finisher Agent, LHF-14).
# The interior may have 6 live lights at once (interior_lights.gd; the spec allows 8 dynamic lights for the whole scene), so most of
# the building's lamps are not real lights at any moment. This makes every lamp READ as lit anyway, with no extra dynamic light:
#   - a stepped (cel) pool of warm light on the floor under every lamp, brighter while the real light is not live and settling to a
#     faint painted edge when it is (the real light does the work then, so nothing is doubled);
#   - a soft halo round every bulb, so a lamp is a glowing thing and not a white disc;
#   - cold moon-and-storm light on the floor in front of every window, keyed to the lighting rig: the moon's strength, the cloud
#     darkness of the phase (ISLAND bright, RETURN dim) and a white flash with each lightning bolt;
#   - the window panes glow a cold sky colour by the same measure;
#   - per-room light colours: deep orange in the basement, amber in the hall and office, a paler lamp in the wash room, a green-grey
#     instrument glow on the control landing, silver in the lamp room.
# Everything is unshaded additive quads that share one material each (per-instance colour and alpha), no shadows, no depth writes.
# Put one node in Level.tscn after InteriorRooms, ExteriorOpenings and LighthouseInteriorLights.
extends Node

const POOL_SHADER := """shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, fog_disabled;
instance uniform vec4 tint : source_color = vec4(1.0, 0.7, 0.4, 1.0);
instance uniform float alpha = 0.4;
void fragment() {
	vec2 c = UV * 2.0 - 1.0;
	float r = length(c * vec2(1.0, 1.0));
	float f = clamp(1.0 - r, 0.0, 1.0);
	// cel steps: three hard-edged rings of light, the way the style guide draws light
	float b = smoothstep(0.10, 0.14, f) * 0.35 + smoothstep(0.38, 0.42, f) * 0.35 + smoothstep(0.70, 0.74, f) * 0.30;
	ALBEDO = tint.rgb * alpha * b;
}
"""

const HALO_SHADER := """shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, fog_disabled;
instance uniform vec4 tint : source_color = vec4(1.0, 0.7, 0.4, 1.0);
instance uniform float alpha = 0.5;
void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
}
void fragment() {
	vec2 c = UV * 2.0 - 1.0;
	float r = length(c);
	float core = smoothstep(0.34, 0.0, r);
	float glow = pow(clamp(1.0 - r, 0.0, 1.0), 2.6);
	ALBEDO = tint.rgb * alpha * (core * 0.5 + glow * 0.6);
}
"""

const WINDOW_TINT := Color(0.5, 0.62, 0.82)
const MOON_REF := 0.6                      # the spec's full-moon light energy

## Light colour by node-name prefix; the first match wins. Applied to the real light as well as its fake pool.
const ROOM_COLOURS := [
	["B_Fire", Color(1.0, 0.5, 0.2)], ["B_", Color(1.0, 0.62, 0.3)], ["Basement", Color(1.0, 0.62, 0.3)],
	["L2_", Color(0.78, 0.95, 0.85)], ["Lamp_", Color(0.86, 0.9, 0.98)], ["Lantern", Color(0.86, 0.9, 0.98)],
	["L1_Wash", Color(0.92, 0.92, 0.84)], ["L1_Stove", Color(1.0, 0.52, 0.2)], ["L1_Radio", Color(0.7, 0.88, 0.62)],
	["Office", Color(1.0, 0.72, 0.4)], ["Store_", Color(1.0, 0.7, 0.4)],
]

@export var mgr_path := NodePath("../LighthouseInteriorLights")
@export var rooms_path := NodePath("../InteriorRooms")
@export var openings_path := NodePath("../ExteriorOpenings")
@export var rig_group := "lighting_rig"

var pools := {}                 # OmniLight3D -> MeshInstance3D (the floor pool)
var halos := {}                 # OmniLight3D -> MeshInstance3D
var window_pools := {}          # window id -> MeshInstance3D
var window_alpha := 0.0         # the current window-light strength (for tests)
var built := false

var _mgr: Node
var _rig: Node
var _glass: StandardMaterial3D
var _pool_mat: ShaderMaterial
var _halo_mat: ShaderMaterial


func _ready() -> void:
	_build.call_deferred()


func _build() -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().physics_frame
	_mgr = get_node_or_null(mgr_path)
	_rig = get_tree().get_first_node_in_group(rig_group)
	var rooms := get_node_or_null(rooms_path)
	if rooms and rooms.get("kit") != null:
		_glass = rooms.kit.mats.get("glass") as StandardMaterial3D
	var ps := Shader.new()
	ps.code = POOL_SHADER
	_pool_mat = ShaderMaterial.new()
	_pool_mat.shader = ps
	var hs := Shader.new()
	hs.code = HALO_SHADER
	_halo_mat = ShaderMaterial.new()
	_halo_mat.shader = hs
	var space := get_viewport().world_3d.direct_space_state
	if _mgr:
		for l in _mgr.get("_lights"):
			_recolour(l)
			_add_lamp(space, l)
	_add_windows(space)
	if _glass:
		_glass.emission_enabled = false      # the panes used to glow blue (every window, from outside too: creator, 2026-10-25); the window light is the floor pool only
	built = true


func _recolour(l: OmniLight3D) -> void:
	var nm := String(l.name)
	for rc in ROOM_COLOURS:
		if nm.begins_with(rc[0]):
			l.light_color = rc[1]
			return


func _floor_below(space: PhysicsDirectSpaceState3D, p: Vector3, reach := 5.0) -> float:
	var q := PhysicsRayQueryParameters3D.create(p + Vector3(0, 0.05, 0), p - Vector3(0, reach, 0))
	q.collision_mask = 1
	var r := space.intersect_ray(q)
	return NAN if r.is_empty() else (r["position"] as Vector3).y


## Keeps a floor pool of radius `rad` centred at `c` (world) inside the room it is in: the house levels by their wall planes, the tower by its
## inner radius. A pool is a flat additive quad; one that crossed a wall showed on the outside as a pale disc (creator, 2026-10-25). Returns [centre, radius].
func _fit_inside(c: Vector3, rad: float) -> Array:
	var rooms := get_node_or_null(rooms_path)
	var frame: Node3D = rooms.get("frame") if rooms else null
	if frame == null:
		return [c, rad]
	var ty := c.y - 9.61
	if ty < 0.9:
		return [c, rad]                                     # the basement is inside the rock
	var tower_d := Vector2(c.x - 8.5, c.z + 4.9).length()
	if tower_d < 3.6 and ty > 4.0:                          # the tower (L2 ring and up): inner radius about 2.9
		var r := minf(rad, 1.1)
		var dir := Vector2(c.x - 8.5, c.z + 4.9)
		var dn := minf(tower_d, 2.9 - r)
		if tower_d > 0.001:
			dir = dir / tower_d * dn
		return [Vector3(8.5 + dir.x, c.y, -4.9 + dir.y), r]
	var p := frame.to_local(c)
	var u := p.x
	var v := -p.z
	var lo := Vector2(-2.1, 0.4) if ty < 4.0 else Vector2(-3.0, 0.95)
	var hi := Vector2(5.5, 6.7) if ty < 4.0 else Vector2(5.4, 8.7)
	var r2 := minf(rad, minf((hi.x - lo.x), (hi.y - lo.y)) * 0.5 - 0.05)
	u = clampf(u, lo.x + r2, hi.x - r2)
	v = clampf(v, lo.y + r2, hi.y - r2)
	return [frame.to_global(Vector3(u, p.y, -v)), r2]


## The largest radius (<= rad) at which the square pool quad centred at `c` has solid floor under all of its corners and edge middles. A pool is a flat additive
## card: over a stairwell hole it hung in the air above the stairs and washed the basement out (creator, 2026-10-26). Returns 0 if even a small card hangs over a hole.
func _shrink_over_floor(space: PhysicsDirectSpaceState3D, c: Vector3, fy: float, rad: float) -> float:
	var r := rad
	while r >= 0.5:
		var ok := true
		for off in [Vector2(0.7, 0), Vector2(-0.7, 0), Vector2(0, 0.7), Vector2(0, -0.7), Vector2(0, 0)]:
			var p := Vector3(c.x + off.x * r, fy, c.z + off.y * r)
			var y := _floor_below(space, p, 5.0)
			if not is_nan(y) and y < fy - 0.3:      # (furniture above the floor is fine; a floor far below is a hole; nothing below is the edge of the room)
				ok = false
				if OS.get_environment("CARD_DEBUG") == "1":
					print("pool miss r %.2f at %s: floor %s vs %.2f" % [r, str(p), str(y), fy])
				break
		if ok:
			return r
		r -= 0.15
	return 0.0


func _quad(parent: Node, nm: String, size: Vector2, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nm
	var q := QuadMesh.new()
	q.size = size
	mi.mesh = q
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi


func _add_lamp(space: PhysicsDirectSpaceState3D, l: OmniLight3D) -> void:
	var pos := l.global_position
	var fy := _floor_below(space, pos)
	var col := l.light_color
	var fit: Array = []
	var rad := 0.0
	if not is_nan(fy):
		rad = clampf(l.omni_range * 0.42, 1.0, 2.6)
		fit = _fit_inside(Vector3(pos.x, fy, pos.z), rad)
		rad = _shrink_over_floor(space, Vector3(fit[0].x, fy, fit[0].z), fy, fit[1])
		if rad <= 0.0:
			fy = NAN
	if not is_nan(fy):
		var holder := Node3D.new()
		holder.name = "Pool_" + String(l.name)
		add_child(holder)
		holder.global_position = Vector3(fit[0].x, fy + 0.025, fit[0].z)
		var mi := _quad(holder, "Quad", Vector2(rad * 2.0, rad * 2.0), _pool_mat)
		mi.rotation.x = -PI * 0.5
		mi.set_instance_shader_parameter("tint", col)
		mi.set_instance_shader_parameter("alpha", 0.3)
		pools[l] = mi
	var h := Node3D.new()
	h.name = "Halo_" + String(l.name)
	add_child(h)
	h.global_position = pos
	var hm := _quad(h, "Quad", Vector2(0.75, 0.75), _halo_mat)
	hm.set_instance_shader_parameter("tint", col)
	hm.set_instance_shader_parameter("alpha", 0.5)
	halos[l] = hm


func _add_windows(space: PhysicsDirectSpaceState3D) -> void:
	var eo := get_node_or_null(openings_path)
	if eo == null:
		return
	for id in eo.surrounds:
		if id == "door":
			continue
		var holder := (eo.surrounds[id] as Node3D).get_parent() as Node3D
		var out := holder.global_transform.basis.z
		out.y = 0.0
		out = out.normalized()
		var inner := holder.global_position - out * 1.7
		var fy := _floor_below(space, inner, 5.0)
		if is_nan(fy):
			continue
		var h := Node3D.new()
		h.name = "WindowPool_" + String(id)
		add_child(h)
		h.global_position = Vector3(inner.x, fy + 0.03, inner.z)
		h.rotation.y = atan2(out.x, out.z)
		var mi := _quad(h, "Quad", Vector2(1.2, 1.9), _pool_mat)
		mi.rotation.x = -PI * 0.5
		mi.set_instance_shader_parameter("tint", WINDOW_TINT)
		mi.set_instance_shader_parameter("alpha", 0.2)
		window_pools[id] = mi


## 0..1: how much sky light there is to come through a window right now (the moon, how clouded the phase is, a lightning flash).
func sky_light() -> float:
	if _rig == null:
		return 0.5
	var moon: float = 0.0
	var m = _rig.get("_moon")
	if m != null:
		moon = clampf((m as DirectionalLight3D).light_energy / MOON_REF, 0.0, 1.0)
	var dark: float = 0.5
	var cur = _rig.get("_cur")
	if cur is Dictionary and (cur as Dictionary).has("darkness"):
		dark = float((cur as Dictionary)["darkness"])
	var flash := 0.0
	var b = _rig.get("_bolt")
	if b != null:
		flash = clampf((b as DirectionalLight3D).light_energy * 0.5, 0.0, 1.0)
	return clampf(moon * (1.0 - 0.55 * dark) + flash, 0.0, 1.0)


func _process(_d: float) -> void:
	if not built:
		return
	var t := Time.get_ticks_msec() * 0.001
	for l in pools:
		var lvl: float = _mgr._level.get(l, 0.0) if _mgr else 0.0
		var e: float = _mgr._base.get(l, 1.0) if _mgr else 1.0
		var far := clampf(0.07 + 0.04 * e, 0.08, 0.16)
		var a := lerpf(far, 0.025, lvl)
		var fl: float = l.get_meta("flicker", 0.0)
		if fl > 0.0:
			a *= 1.0 + fl * (sin(t * 4.0 + float(l.get_instance_id() % 7)) * 0.5 + sin(t * 9.0) * 0.3)
		(pools[l] as MeshInstance3D).set_instance_shader_parameter("alpha", a)
	for l in halos:
		var lvl2: float = _mgr._level.get(l, 0.0) if _mgr else 0.0
		(halos[l] as MeshInstance3D).set_instance_shader_parameter("alpha", lerpf(0.4, 0.22, lvl2))
	window_alpha = 0.05 + 0.22 * sky_light()
	for id in window_pools:
		(window_pools[id] as MeshInstance3D).set_instance_shader_parameter("alpha", window_alpha)

