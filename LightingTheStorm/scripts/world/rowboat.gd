# rowboat.gd - Arthur and Daniel's rowboat (backlog T04): the FAL model (Assets/Models/boat/rowboat.glb, 4.2 m, bow -Z), rowed in along a
# path to its berth and moored there, bobbing. It carries two seats (local offsets) where the capsule sailors sit while it arrives.
# Spawned at run time by scripts/world/sailors_sequence.gd, so Level.tscn does not hold it. It is a visual only: no collision, no
# player boarding (the steam launch is the player's boat; the two must stay visibly distinct, Exec Summary "Two boats").
extends Node3D

const Route := preload("res://scripts/world/ship_route.gd")

signal moored

var seat_arthur := Vector3(0.0, 0.2, 0.7)
var seat_daniel := Vector3(0.0, 0.2, -0.9)

var _pts := PackedVector2Array()
var _i := 0
var _speed := 1.9
var _keel_y := 0.3
var _bob := 0.06
var _t := 0.0
var _rowing := false
var _model: Node3D
var _hull: Node3D
var _dir := Vector2(1, 0)


func setup(cfg: Dictionary) -> void:
	_pts = Route.points(cfg["path"])
	_speed = float(cfg["speed_mps"])
	_keel_y = float(cfg["keel_y"])
	_bob = float(cfg["bob_m"])
	seat_arthur = Vector3(float(cfg["seat_arthur"][0]), float(cfg["seat_arthur"][1]), float(cfg["seat_arthur"][2]))
	seat_daniel = Vector3(float(cfg["seat_daniel"][0]), float(cfg["seat_daniel"][1]), float(cfg["seat_daniel"][2]))
	name = "Rowboat"
	_hull = Node3D.new()
	_hull.name = "Hull"
	add_child(_hull)
	var packed := load(String(cfg["model"])) as PackedScene
	if packed:
		_model = packed.instantiate()
		_hull.add_child(_model)
	else:
		push_warning("rowboat: model %s did not load" % cfg["model"])
	_dir = (_pts[1] - _pts[0]).normalized() if _pts.size() > 1 else Vector2(1, 0)
	_place(_pts[0])


func row() -> void:
	_i = 1
	_rowing = true


func is_moored() -> bool:
	return not _rowing and _i >= _pts.size()


func berth() -> Vector2:
	return _pts[_pts.size() - 1]


func _process(delta: float) -> void:
	_t += delta
	if _rowing:
		var here := Vector2(position.x, position.z)
		var target: Vector2 = _pts[_i]
		var d := here.distance_to(target)
		var step := _speed * delta
		if d <= step:
			_place(target)
			_i += 1
			if _i >= _pts.size():
				_rowing = false
				moored.emit()
		else:
			_dir = (target - here).normalized()
			_place(here + _dir * step)
	_hull.rotation = Vector3(sin(_t * 0.9) * 0.025, 0.0, sin(_t * 0.7 + 1.0) * 0.04)
	_hull.position.y = sin(_t * 0.8) * _bob


func _place(p: Vector2) -> void:
	position = Vector3(p.x, _keel_y, p.y)
	rotation = Vector3(0.0, Route.yaw_for(_dir), 0.0)
