class_name Pollen
extends Area3D
## A cloud of pollen sneezed along the ground. It rolls towards Fart Man.
## Jump over it. It hurts if it touches him.

## Metres per second, to the left.
var speed: float = 4.5
## It vanishes when it gets this far left.
var left_x: float = -10.0
var _age: float = 0.0


## Makes a cloud at "from" that rolls left at "speed" until it reaches left_x.
static func launch(parent: Node, from: Vector3, speed_now: float, left_edge: float) -> Pollen:
	var cloud := Pollen.new()
	cloud.speed = speed_now
	cloud.left_x = left_edge
	parent.add_child(cloud)
	cloud.global_position = from
	return cloud


func _init() -> void:
	add_to_group(&"boss_shots")
	# The part that hurts is smaller than the puffy picture, so it feels fair.
	var shape := CollisionShape3D.new()
	var ball := SphereShape3D.new()
	ball.radius = 0.4
	shape.shape = ball
	add_child(shape)
	var puff := MeshInstance3D.new()
	var fluff := SphereMesh.new()
	fluff.radius = 0.6
	fluff.height = 1.2
	var yellow := StandardMaterial3D.new()
	yellow.albedo_color = Color(1.0, 0.9, 0.3, 0.85)
	yellow.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fluff.material = yellow
	puff.mesh = fluff
	puff.name = "Puff"
	add_child(puff)


func _physics_process(delta: float) -> void:
	_age += delta
	position.x -= speed * delta
	# Wobbles like a puffy cloud.
	var wobble: float = 1.0 + 0.12 * sin(_age * 14.0)
	get_node("Puff").scale = Vector3(wobble, 2.0 - wobble, wobble)
	if position.x < left_x:
		queue_free()
		return
	for body: Node3D in get_overlapping_bodies():
		var player := body as Player
		if player != null:
			player.hurt(global_position.x)
