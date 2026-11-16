class_name FallingPetal
extends Area3D
## A big petal that drops from the sky. A pink flashing patch on the ground shows
## where it will land, and it falls a moment later. Step out of the pink!

## Seconds the pink warning shows before the petal falls.
var warn_time: float = 0.9
## How fast it falls, in metres per second.
var fall_speed: float = 15.0
## How high it starts above the ground.
var drop_height: float = 12.0
var _age: float = 0.0
var _ground_y: float = 0.0
var _marker: MeshInstance3D
var _petal: MeshInstance3D


## Drops a petal that will land at x on the floor whose top is ground_y.
static func drop(parent: Node, x: float, ground_y: float) -> FallingPetal:
	var petal := FallingPetal.new()
	petal._ground_y = ground_y
	petal.position = Vector3(x, ground_y + petal.drop_height, 0.0)
	parent.add_child(petal)
	petal._make_marker(parent)
	return petal


func _init() -> void:
	add_to_group(&"boss_shots")
	monitoring = false
	var shape := CollisionShape3D.new()
	var ball := SphereShape3D.new()
	ball.radius = 0.7
	shape.shape = ball
	add_child(shape)
	_petal = MeshInstance3D.new()
	var blob := SphereMesh.new()
	blob.radius = 0.7
	blob.height = 0.5
	var pink := StandardMaterial3D.new()
	pink.albedo_color = Color(1.0, 0.45, 0.7)
	blob.material = pink
	_petal.mesh = blob
	add_child(_petal)


## The flashing patch sits on the ground, separate from the falling petal.
func _make_marker(parent: Node) -> void:
	_marker = MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = 0.9
	disc.bottom_radius = 0.9
	disc.height = 0.05
	var flash := StandardMaterial3D.new()
	flash.albedo_color = Color(1.0, 0.3, 0.6)
	disc.material = flash
	_marker.mesh = disc
	parent.add_child(_marker)
	_marker.global_position = Vector3(global_position.x, _ground_y + 0.05, 0.0)
	_marker.add_to_group(&"boss_shots")
	_petal.visible = false


func _physics_process(delta: float) -> void:
	_age += delta
	if _age < warn_time:
		_marker.visible = int(_age * 12.0) % 2 == 0
		return
	_petal.visible = true
	monitoring = true
	position.y -= fall_speed * delta
	if position.y <= _ground_y + 0.7:
		_marker.queue_free()
		queue_free()
		return
	for body: Node3D in get_overlapping_bodies():
		var player := body as Player
		if player != null:
			player.hurt(global_position.x)


func _exit_tree() -> void:
	if is_instance_valid(_marker):
		_marker.queue_free()
