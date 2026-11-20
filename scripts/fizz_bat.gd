class_name FizzBat
extends Burpling
## A Fizz Bat: a fizzy bat that flies along in a wave, up and down.
## Stomp it from above (you bounce!) or use it as a stepping stone.

## How high the wave goes, in metres, and how fast it wobbles.
@export var wave_height: float = 1.2
@export var wave_speed: float = 2.5
## How fast the wings flap.
@export var flap_speed: float = 14.0
## The two wings.
@export var left_wing: Node3D
@export var right_wing: Node3D

var _base_y: float = 0.0
var _age: float = 0.0


func _ready() -> void:
	super._ready()
	_base_y = position.y


func _move(delta: float) -> void:
	super._move(delta)
	_age += delta
	position.y = _base_y + sin(_age * wave_speed + start_x) * wave_height
	var flap: float = sin(_age * flap_speed) * 0.6
	if left_wing != null:
		left_wing.rotation.z = flap
	if right_wing != null:
		right_wing.rotation.z = -flap
