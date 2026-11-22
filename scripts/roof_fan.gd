class_name RoofFan
extends Area3D
## A giant fan on a factory roof. When it is blowing, it fires a column of wind straight up and
## anyone flying in it is shoved skywards. It winds up (blades speeding up) before it blows,
## so you can see it coming. Fly over it while it is off, or ride the wind on purpose!
## Stand this at the roof: its origin is the middle of the fan, at roof height.

## Sent each time it starts or stops blowing.
signal switched(now_on: bool)

## Seconds blowing, seconds resting, and the wind-up just before it blows.
@export var on_time: float = 3.0
@export var off_time: float = 1.6
@export var warn_time: float = 0.8
## Where in the cycle it starts (0 to 1).
@export var phase: float = 0.0
## How hard the wind shoves, in metres per second per second (the same units as an up-draught).
@export var strength: float = 50.0
## How tall the column of wind is, in metres above the fan.
@export var column_height: float = 20.0
## How wide the fan and the wind are, in metres.
@export var width: float = 5.0
## The whoosh when it switches on.
@export var switch_sound: AudioStream

var is_on: bool = false
var _age: float = 0.0
var _blades: Node3D
var _wind: Node3D
var _speed: float = 0.0


func _ready() -> void:
	_age = phase * (on_time + off_time)
	_build()


func _physics_process(delta: float) -> void:
	_age = fmod(_age + delta, on_time + off_time)
	var was_on: bool = is_on
	is_on = _age >= off_time
	if is_on != was_on:
		switched.emit(is_on)
		if is_on:
			Sfx.play(self, switch_sound)
	# Blades: slow while resting, speeding up in the warning, a blur while blowing.
	var wanted: float = 2.0
	if is_on:
		wanted = 22.0
	elif _age >= off_time - warn_time:
		wanted = 10.0
	_speed = move_toward(_speed, wanted, 30.0 * delta)
	if _blades != null:
		_blades.rotation.y += _speed * delta
	if _wind != null:
		_wind.visible = is_on
		# The wind rings slide upwards.
		for ring: Node in _wind.get_children():
			var r := ring as Node3D
			r.position.y = fmod(r.position.y + 14.0 * delta, column_height)
	if not is_on:
		return
	for body: Node3D in get_overlapping_bodies():
		var player := body as Player
		if player != null and player.is_flying():
			player.flight.updraft = maxf(player.flight.updraft, strength)


func _build() -> void:
	# The base: a steel drum on the roof.
	var drum := CylinderMesh.new()
	drum.top_radius = width * 0.5
	drum.bottom_radius = width * 0.55
	drum.height = 1.2
	drum.material = _paint(Color(0.5, 0.53, 0.58))
	var base := MeshInstance3D.new()
	base.mesh = drum
	add_child(base)
	# Four big orange blades.
	_blades = Node3D.new()
	_blades.position = Vector3(0, 0.8, 0)
	add_child(_blades)
	for i in 4:
		var blade := BoxMesh.new()
		blade.size = Vector3(width * 0.5, 0.12, 0.9)
		blade.material = _paint(Color(0.95, 0.5, 0.15))
		var blade_mesh := MeshInstance3D.new()
		blade_mesh.mesh = blade
		blade_mesh.rotation.y = PI * 0.5 * i
		blade_mesh.position = Vector3(cos(PI * 0.5 * i), 0, -sin(PI * 0.5 * i)) * width * 0.25
		_blades.add_child(blade_mesh)
	# Wind: a few pale rings that slide up the column while it blows.
	_wind = Node3D.new()
	add_child(_wind)
	for i in 5:
		var puff := CylinderMesh.new()
		puff.top_radius = width * 0.45
		puff.bottom_radius = width * 0.45
		puff.height = 0.1
		var pale := _paint(Color(0.9, 0.95, 1.0, 0.35))
		pale.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		puff.material = pale
		var puff_mesh := MeshInstance3D.new()
		puff_mesh.mesh = puff
		puff_mesh.position = Vector3(0, column_height * float(i) / 5.0, 0)
		_wind.add_child(puff_mesh)
	# The zone: the whole column of wind.
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(width, column_height, 3.0)
	shape.shape = box
	shape.position = Vector3(0, column_height * 0.5, 0)
	add_child(shape)


func _paint(color: Color) -> StandardMaterial3D:
	var paint := StandardMaterial3D.new()
	paint.albedo_color = color
	return paint
