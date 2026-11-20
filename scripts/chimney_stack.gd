class_name ChimneyStack
extends Area3D
## A factory chimney sticking up from a roof (or hanging down from the sky, as a pipe).
## Touching it costs a heart. A standing chimney also puffs a column of warm smoke from its top
## every few seconds: the smoke gives a gentle lift, so you can float over the next chimney.
## Its origin is the middle of its base (or, for a hanging pipe, the middle of its top).

## Sent each time it starts puffing.
signal puffed

## How tall it is, in metres, and how wide.
@export var height: float = 14.0
@export var width: float = 3.0
## Tick for a pipe hanging down from above. It does not puff.
@export var hanging: bool = false
@export_group("Smoke")
## Seconds between puffs, and how long a puff lasts.
@export var puff_every: float = 3.0
@export var puff_time: float = 1.6
## Where in the cycle it starts (0 to 1).
@export var phase: float = 0.0
## How tall the smoke column is above the chimney top, and how gentle its lift is.
@export var smoke_height: float = 8.0
@export var smoke_lift: float = 30.0

var is_puffing: bool = false
var _age: float = 0.0
var _smoke_zone: Area3D
var _smoke: Node3D


func _ready() -> void:
	_age = phase * puff_every
	_build()


func _physics_process(delta: float) -> void:
	# The chimney itself hurts.
	for body: Node3D in get_overlapping_bodies():
		var player := body as Player
		if player != null:
			player.hurt(global_position.x)
	if hanging:
		return
	_age = fmod(_age + delta, puff_every)
	var was_puffing: bool = is_puffing
	is_puffing = _age < puff_time
	if is_puffing and not was_puffing:
		puffed.emit()
	if _smoke != null:
		_smoke.visible = is_puffing
		_smoke.position.y = height + smoke_height * 0.5 + sin(_age * 6.0) * 0.3
	if is_puffing and _smoke_zone != null:
		for body: Node3D in _smoke_zone.get_overlapping_bodies():
			var player := body as Player
			if player != null and player.is_flying():
				player.flight.updraft = maxf(player.flight.updraft, smoke_lift)


func _build() -> void:
	# Brick stack, centred on its base (or hanging below its top).
	var centre_y: float = -height * 0.5 if hanging else height * 0.5
	var stack := CylinderMesh.new()
	stack.top_radius = width * 0.45
	stack.bottom_radius = width * 0.5
	stack.height = height
	stack.material = _paint(Color(0.7, 0.3, 0.22))
	var stack_mesh := MeshInstance3D.new()
	stack_mesh.mesh = stack
	stack_mesh.position = Vector3(0, centre_y, 0)
	add_child(stack_mesh)
	# An orange and white warning band near the open end, and a dark rim.
	var band_y: float = -height + 1.2 if hanging else height - 1.2
	var band := CylinderMesh.new()
	band.top_radius = width * 0.47
	band.bottom_radius = width * 0.47
	band.height = 0.8
	band.material = _paint(Color(1.0, 0.6, 0.15))
	var band_mesh := MeshInstance3D.new()
	band_mesh.mesh = band
	band_mesh.position = Vector3(0, band_y, 0)
	add_child(band_mesh)
	var rim := CylinderMesh.new()
	rim.top_radius = width * 0.55
	rim.bottom_radius = width * 0.55
	rim.height = 0.4
	rim.material = _paint(Color(0.2, 0.2, 0.22))
	var rim_mesh := MeshInstance3D.new()
	rim_mesh.mesh = rim
	rim_mesh.position = Vector3(0, -height if hanging else height, 0)
	add_child(rim_mesh)
	# What hurts: the stack, slightly thinner than it looks.
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(width * 0.8, height, 2.5)
	shape.shape = box
	shape.position = Vector3(0, centre_y, 0)
	add_child(shape)
	if hanging:
		return
	# The smoke: a few dark puffs stacked above the top, and a zone that lifts.
	_smoke = Node3D.new()
	add_child(_smoke)
	for i in 3:
		var ball := SphereMesh.new()
		var r: float = width * (0.55 + 0.2 * float(i))
		ball.radius = r
		ball.height = r * 2.0
		var grey := _paint(Color(0.35, 0.33, 0.33, 0.7))
		grey.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		ball.material = grey
		var puff := MeshInstance3D.new()
		puff.mesh = ball
		puff.position = Vector3(0, (float(i) - 1.0) * smoke_height * 0.3, 0)
		_smoke.add_child(puff)
	_smoke.visible = false
	_smoke_zone = Area3D.new()
	var smoke_shape := CollisionShape3D.new()
	var smoke_box := BoxShape3D.new()
	smoke_box.size = Vector3(width * 1.6, smoke_height, 3.0)
	smoke_shape.shape = smoke_box
	_smoke_zone.add_child(smoke_shape)
	_smoke_zone.position = Vector3(0, height + smoke_height * 0.5, 0)
	add_child(_smoke_zone)


func _paint(color: Color) -> StandardMaterial3D:
	var paint := StandardMaterial3D.new()
	paint.albedo_color = color
	return paint
