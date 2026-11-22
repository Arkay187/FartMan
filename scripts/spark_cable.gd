class_name SparkCable
extends Area3D
## An electric cable between two poles. It switches on and off. Before it switches on it
## flickers, so you can see it coming. Fly (or run) past while it is off. ZAP means a lost heart.
## The looks (poles, cable, sparks) are made here in code, from the settings below.

## Sent each time the cable switches on or off.
signal switched(now_on: bool)

## How long the cable is, in metres.
@export var length: float = 8.0
## Tick for a cable that hangs up and down instead of across.
@export var vertical: bool = false
## Seconds it is on, seconds it is off, and the flicker just before it is on.
@export var on_time: float = 1.5
@export var off_time: float = 1.5
@export var warn_time: float = 0.7
## Where in the cycle it starts (0 to 1), so a row of cables does not all go off together.
@export var phase: float = 0.0
## The zap when it switches on.
@export var zap_sound: AudioStream

var is_on: bool = false
var _age: float = 0.0
var _glow: MeshInstance3D
var _sparks: Array[MeshInstance3D] = []
var _was_on: bool = false


func _ready() -> void:
	_age = phase * (on_time + off_time)
	_build()
	_update_look()


func _physics_process(delta: float) -> void:
	_age = fmod(_age + delta, on_time + off_time)
	# The cycle: off, then a warning flicker, then on.
	is_on = _age >= off_time
	if is_on != _was_on:
		_was_on = is_on
		switched.emit(is_on)
		if is_on:
			Sfx.play(self, zap_sound)
	_update_look()
	if not is_on:
		return
	for body: Node3D in get_overlapping_bodies():
		var player := body as Player
		if player != null:
			player.hurt(global_position.x)


## True during the flicker just before it switches on.
func is_warning() -> bool:
	return not is_on and _age >= off_time - warn_time


## Cable glows while on, flickers thinly during the warning, and is a dull wire otherwise.
func _update_look() -> void:
	if _glow == null:
		return
	var thin: float = 0.12
	if is_on:
		_glow.visible = true
		_glow.scale = Vector3.ONE
	elif is_warning():
		_glow.visible = int(_age * 24.0) % 2 == 0
		_glow.scale = Vector3(1.0, thin, thin) if not vertical else Vector3(thin, 1.0, thin)
	else:
		_glow.visible = false
	for spark in _sparks:
		spark.visible = is_on and randf() < 0.6
		if spark.visible:
			var along: float = randf_range(-0.5, 0.5) * length
			var across: float = randf_range(-0.5, 0.5)
			spark.position = Vector3(across, along, 0.2) if vertical else Vector3(along, across, 0.2)


func _build() -> void:
	var axis := Vector3(0, length, 0) if vertical else Vector3(length, 0, 0)
	var half: Vector3 = axis * 0.5
	# Two steel poles, one at each end.
	for end in [-1.0, 1.0]:
		var pole := MeshInstance3D.new()
		var post := BoxMesh.new()
		post.size = Vector3(0.7, 0.7, 0.7)
		post.material = _paint(Color(0.45, 0.48, 0.52))
		pole.mesh = post
		pole.position = half * end
		add_child(pole)
	# The wire itself.
	var wire := MeshInstance3D.new()
	var line := BoxMesh.new()
	line.size = Vector3(0.12, length, 0.12) if vertical else Vector3(length, 0.12, 0.12)
	line.material = _paint(Color(0.15, 0.15, 0.18))
	wire.mesh = line
	add_child(wire)
	# The electric glow, a fatter bright tube.
	_glow = MeshInstance3D.new()
	var tube := BoxMesh.new()
	tube.size = Vector3(0.5, length, 0.5) if vertical else Vector3(length, 0.5, 0.5)
	var bright := _paint(Color(0.5, 0.95, 1.0, 0.8))
	bright.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bright.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	tube.material = bright
	_glow.mesh = tube
	add_child(_glow)
	# Little yellow sparks that jump about along the cable while it is on.
	for i in 5:
		var spark := MeshInstance3D.new()
		var bit := SphereMesh.new()
		bit.radius = 0.18
		bit.height = 0.36
		var yellow := _paint(Color(1.0, 0.95, 0.3))
		yellow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		bit.material = yellow
		spark.mesh = bit
		add_child(spark)
		_sparks.append(spark)
	# The part that hurts: a little fatter than the wire, a little thinner than the glow.
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.8, length, 2.5) if vertical else Vector3(length, 0.8, 2.5)
	shape.shape = box
	add_child(shape)


func _paint(color: Color) -> StandardMaterial3D:
	var paint := StandardMaterial3D.new()
	paint.albedo_color = color
	return paint
