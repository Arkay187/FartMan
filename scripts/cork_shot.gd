class_name CorkShot
extends Area3D
## A cork shot out of Colonel Cork's hat. It lobs slowly up and over, and comes down where
## Fart Man was standing. A red flashing patch on the floor shows where it will land, the
## moment it is fired, so there is plenty of time to step away. It only hurts while it flies
## and in the instant it lands. Then it pops into crumbs.
## A BOUNCING cork does not pop at once: it hops on along the floor a few more times, and a
## new red patch shows each next landing spot.

## How slowly it flies, in seconds (set by the boss for each round).
var flight_time: float = 2.2
## How high the lob goes above the line from hat to floor, in metres.
var arc_height: float = 5.0
## How many more times it bounces after landing (0 = pops straight away).
var bounces_left: int = 0
## How far each bounce goes, in metres.
var bounce_distance: float = 4.0
var _from: Vector3
var _target_x: float = 0.0
var _floor_y: float = 0.0
var _age: float = 0.0
var _landed: bool = false
var _marker: MeshInstance3D
var _cork: MeshInstance3D


## Fires a cork from "from" that will land at x on the floor whose top is floor_y.
## arc = how high it lobs. bounces = how many extra hops it makes after landing.
static func launch(parent: Node, from: Vector3, target_x: float, floor_y: float, seconds: float, arc: float = 5.0, bounces: int = 0) -> CorkShot:
	var shot := CorkShot.new()
	shot.flight_time = seconds
	shot.arc_height = arc
	shot.bounces_left = bounces
	shot._from = from
	shot._target_x = target_x
	shot._floor_y = floor_y
	parent.add_child(shot)
	shot.global_position = from
	shot._make_marker(parent)
	return shot


func _init() -> void:
	add_to_group(&"boss_shots")
	# The part that hurts is smaller than the picture, so it feels fair.
	var shape := CollisionShape3D.new()
	var ball := SphereShape3D.new()
	ball.radius = 0.4
	shape.shape = ball
	add_child(shape)
	_cork = MeshInstance3D.new()
	var plug := CylinderMesh.new()
	plug.top_radius = 0.4
	plug.bottom_radius = 0.3
	plug.height = 0.8
	var brown := StandardMaterial3D.new()
	brown.albedo_color = Color(0.78, 0.58, 0.32)
	plug.material = brown
	_cork.mesh = plug
	add_child(_cork)


## The flashing red patch on the floor, separate from the cork itself.
func _make_marker(parent: Node) -> void:
	_marker = MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = 1.0
	disc.bottom_radius = 1.0
	disc.height = 0.05
	var red := StandardMaterial3D.new()
	red.albedo_color = Color(1.0, 0.2, 0.2)
	disc.material = red
	_marker.mesh = disc
	parent.add_child(_marker)
	_marker.global_position = Vector3(_target_x, _floor_y + 0.05, 0.0)
	_marker.add_to_group(&"boss_shots")


func _physics_process(delta: float) -> void:
	if _landed:
		return
	_age += delta
	var u: float = clampf(_age / flight_time, 0.0, 1.0)
	var land_y: float = _floor_y + 0.4
	global_position = Vector3(
		lerpf(_from.x, _target_x, u),
		lerpf(_from.y, land_y, u) + arc_height * 4.0 * u * (1.0 - u),
		0.0)
	_cork.rotation.z += 6.0 * delta
	# The red patch flashes faster the closer the cork gets.
	if is_instance_valid(_marker):
		_marker.visible = int(_age * (6.0 + 8.0 * u)) % 2 == 0
	_hurt_whoever_is_touching()
	if u >= 1.0:
		_land()


func _hurt_whoever_is_touching() -> void:
	for body: Node3D in get_overlapping_bodies():
		var player := body as Player
		if player != null:
			player.hurt(global_position.x)


## Lands with a thud, and pops into crumbs (or hops on, if it still has bounces left).
func _land() -> void:
	if bounces_left > 0:
		_bounce_on()
		return
	_landed = true
	if is_instance_valid(_marker):
		_marker.queue_free()
	_cork.visible = false
	for i in 6:
		var crumb := MeshInstance3D.new()
		var bit := BoxMesh.new()
		bit.size = Vector3(0.2, 0.2, 0.2)
		var brown := StandardMaterial3D.new()
		brown.albedo_color = Color(0.78, 0.58, 0.32)
		bit.material = brown
		crumb.mesh = bit
		get_parent().add_child(crumb)
		crumb.global_position = global_position
		var angle: float = PI * (float(i) / 5.0)
		var goal: Vector3 = crumb.global_position + Vector3(cos(angle) * 1.5, 1.0 + sin(angle), 0.0)
		var tween: Tween = crumb.create_tween()
		tween.tween_property(crumb, "global_position", goal, 0.35)
		tween.tween_callback(crumb.queue_free)
	queue_free()


func _exit_tree() -> void:
	if is_instance_valid(_marker):
		_marker.queue_free()


## A smaller hop further on in the direction it was going, with a new warning patch.
func _bounce_on() -> void:
	bounces_left -= 1
	var heading: float = signf(_target_x - _from.x)
	if heading == 0.0:
		heading = -1.0
	_from = Vector3(_target_x, _floor_y + 0.4, 0.0)
	_target_x += heading * bounce_distance
	flight_time = maxf(flight_time * 0.7, 0.8)
	arc_height *= 0.6
	_age = 0.0
	if is_instance_valid(_marker):
		_marker.global_position = Vector3(_target_x, _floor_y + 0.05, 0.0)
