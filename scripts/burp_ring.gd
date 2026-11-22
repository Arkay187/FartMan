class_name BurpRing
extends Area3D
## A big ring that Big Bad Burp burps in the flying chase. Fly THROUGH THE HOLE in the middle.
## The top and bottom of the ring hurt. It drifts slowly and pops by itself after a while.

## How tall the hole is (metres). Bigger = easier.
@export var gap_height: float = 8.0
## How thick the ring wall is above and below the hole.
@export var wall_height: float = 14.0
## Sideways speed, metres per second (negative = drifts left, towards him).
@export var speed: float = -2.0
## It pops by itself after this many seconds.
@export var lifetime: float = 10.0

var _age: float = 0.0


func _ready() -> void:
	add_to_group(&"boss_shots")
	var paint := StandardMaterial3D.new()
	paint.albedo_color = Color(1.0, 0.45, 0.85, 0.8)
	paint.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	paint.emission_enabled = true
	paint.emission = Color(0.6, 0.15, 0.4)
	for side in [-1.0, 1.0]:
		var wall := BoxMesh.new()
		wall.size = Vector3(1.6, wall_height, 1.6)
		wall.material = paint
		var shape_pos := Vector3(0, side * (gap_height * 0.5 + wall_height * 0.5), 0)
		var look := MeshInstance3D.new()
		look.mesh = wall
		look.position = shape_pos
		add_child(look)
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(1.4, wall_height, 2.4)
		shape.shape = box
		shape.position = shape_pos
		add_child(shape)
		# Bright knobs on the edges of the hole, so the gap is easy to see.
		var knob := SphereMesh.new()
		knob.radius = 0.9
		knob.height = 1.8
		var glow := StandardMaterial3D.new()
		glow.albedo_color = Color(1.0, 0.9, 0.3)
		glow.emission_enabled = true
		glow.emission = Color(1.0, 0.8, 0.2)
		knob.material = glow
		var knob_look := MeshInstance3D.new()
		knob_look.mesh = knob
		knob_look.position = Vector3(0, side * gap_height * 0.5, 0)
		add_child(knob_look)


func _physics_process(delta: float) -> void:
	_age += delta
	position.x += speed * delta
	if _age >= lifetime:
		queue_free()
		return
	for body: Node3D in get_overlapping_bodies():
		var player := body as Player
		if player != null:
			player.hurt(global_position.x)
