class_name MudPie
extends Area3D
## A mud pie thrown by a Gnome. It flies in an arc, hurts if it hits Fart Man
## and splats on anything else.

@export var fall_gravity: float = 15.0
@export var radius: float = 0.3
## It goes away after this many seconds whatever happens.
@export var lifetime: float = 5.0

var velocity: Vector3 = Vector3.ZERO


## Makes a pie and sends it from "from" so that it lands on "target" after "flight_time" seconds.
static func throw(parent: Node, from: Vector3, target: Vector3, flight_time: float = 1.1) -> MudPie:
	var pie := MudPie.new()
	parent.add_child(pie)
	pie.global_position = from
	var g: float = pie.fall_gravity
	pie.velocity = Vector3(
		(target.x - from.x) / flight_time,
		(target.y - from.y + 0.5 * g * flight_time * flight_time) / flight_time,
		0.0)
	return pie


func _init() -> void:
	var shape := CollisionShape3D.new()
	var ball := SphereShape3D.new()
	ball.radius = radius
	shape.shape = ball
	add_child(shape)
	var mesh := MeshInstance3D.new()
	var blob := SphereMesh.new()
	blob.radius = radius
	blob.height = radius * 2.0
	var brown := StandardMaterial3D.new()
	brown.albedo_color = Color(0.4, 0.25, 0.12)
	blob.material = brown
	mesh.mesh = blob
	add_child(mesh)


func _physics_process(delta: float) -> void:
	velocity.y -= fall_gravity * delta
	position += velocity * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return
	for body: Node3D in get_overlapping_bodies():
		var player := body as Player
		if player != null:
			player.hurt(global_position.x)
		# Splat on whoever or whatever it hit.
		queue_free()
		return
