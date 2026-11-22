class_name Grandma
extends Node3D
## Grandma, who runs the shop aboard the Complex2000. She hides behind the counter
## and pops up with a bounce when Fart Man wants to shop, then ducks back down.
## She builds her own low-poly body (purple dress, white apron, grey hair bun, glasses).
## Put her where she stands when she is popped up: she hides by sinking `hidden_drop` metres.

## How far she sinks behind the counter when hidden, in metres.
@export var hidden_drop: float = 3.2
## How long the pop up and the duck down take, in seconds.
@export var pop_time: float = 0.45
@export var duck_time: float = 0.3

@export_group("Colours")
@export var dress_color: Color = Color(0.55, 0.3, 0.75)
@export var apron_color: Color = Color(0.97, 0.97, 0.95)
@export var skin_color: Color = Color(0.98, 0.78, 0.65)
@export var hair_color: Color = Color(0.78, 0.78, 0.82)

## True from the moment she is told to pop up until she is told to duck.
var is_up: bool = false
var _stand_y: float = 0.0
var _tween: Tween


func _ready() -> void:
	_stand_y = position.y
	position.y = _stand_y - hidden_drop
	_build_body()


## Bounces up from behind the counter.
func pop_up() -> void:
	is_up = true
	_start_tween()
	_tween.tween_property(self, "position:y", _stand_y, pop_time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# A little squash and stretch as she lands.
	_tween.parallel().tween_property(self, "scale", Vector3(0.85, 1.2, 0.85), pop_time * 0.5)
	_tween.tween_property(self, "scale", Vector3.ONE, pop_time * 0.5).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)


## Ducks back down out of sight.
func duck() -> void:
	is_up = false
	_start_tween()
	_tween.tween_property(self, "position:y", _stand_y - hidden_drop, duck_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_tween.parallel().tween_property(self, "scale", Vector3.ONE, duck_time)


## True once she is all the way up (not still bouncing).
func is_fully_up() -> bool:
	return is_up and absf(position.y - _stand_y) < 0.01


## True once she is completely hidden.
func is_hidden_away() -> bool:
	return not is_up and absf(position.y - (_stand_y - hidden_drop)) < 0.01


func _start_tween() -> void:
	if _tween != null:
		_tween.kill()
	_tween = create_tween()


# ---------------------------------------------------------------- her looks

func _build_body() -> void:
	var dress := CylinderMesh.new()
	dress.top_radius = 0.38
	dress.bottom_radius = 0.8
	dress.height = 1.4
	_part("Dress", dress, dress_color, Vector3(0, 0.7, 0))
	var apron := BoxMesh.new()
	apron.size = Vector3(0.62, 0.95, 0.1)
	_part("Apron", apron, apron_color, Vector3(0, 0.75, 0.5))
	var head := SphereMesh.new()
	head.radius = 0.42
	head.height = 0.84
	_part("Head", head, skin_color, Vector3(0, 1.75, 0))
	# Hair: a cap on the back of her head and a bun on top.
	var hair := SphereMesh.new()
	hair.radius = 0.44
	hair.height = 0.88
	_part("Hair", hair, hair_color, Vector3(0, 1.82, -0.12))
	var bun := SphereMesh.new()
	bun.radius = 0.22
	bun.height = 0.44
	_part("Bun", bun, hair_color, Vector3(0, 2.28, -0.1))
	# Round glasses, eyes, a little smile and pink cheeks.
	for side: float in [-1.0, 1.0]:
		var lens := TorusMesh.new()
		lens.inner_radius = 0.09
		lens.outer_radius = 0.14
		var ring: MeshInstance3D = _part("Glasses", lens, Color(0.2, 0.15, 0.1), Vector3(side * 0.18, 1.8, 0.38))
		ring.rotation_degrees = Vector3(90, 0, 0)
		var eye := SphereMesh.new()
		eye.radius = 0.05
		eye.height = 0.1
		_part("Eye", eye, Color.BLACK, Vector3(side * 0.18, 1.8, 0.4))
		var cheek := SphereMesh.new()
		cheek.radius = 0.08
		cheek.height = 0.1
		_part("Cheek", cheek, Color(1.0, 0.6, 0.6), Vector3(side * 0.28, 1.62, 0.34))
		# Hands up beside her, ready to wave.
		var hand := SphereMesh.new()
		hand.radius = 0.16
		hand.height = 0.32
		_part("Hand", hand, skin_color, Vector3(side * 0.75, 1.25, 0.25))
		var sleeve := CapsuleMesh.new()
		sleeve.radius = 0.14
		sleeve.height = 0.7
		var arm: MeshInstance3D = _part("Sleeve", sleeve, dress_color, Vector3(side * 0.58, 1.0, 0.12))
		arm.rotation_degrees = Vector3(0, 0, -side * 25.0)
	var bridge := BoxMesh.new()
	bridge.size = Vector3(0.1, 0.03, 0.03)
	_part("Bridge", bridge, Color(0.2, 0.15, 0.1), Vector3(0, 1.82, 0.4))
	var smile := BoxMesh.new()
	smile.size = Vector3(0.2, 0.04, 0.04)
	_part("Smile", smile, Color(0.8, 0.25, 0.3), Vector3(0, 1.55, 0.4))


func _part(part_name: String, shape: Mesh, color: Color, pos: Vector3) -> MeshInstance3D:
	var paint := StandardMaterial3D.new()
	paint.albedo_color = color
	shape.set("material", paint)
	var mesh := MeshInstance3D.new()
	mesh.name = part_name
	mesh.mesh = shape
	mesh.position = pos
	add_child(mesh)
	return mesh
