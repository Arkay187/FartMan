class_name Jellyfish
extends Burpling
## A floating alien jellyfish for the Stink Storm. It bobs up and down and drifts about.
## Fly into it from the side and it hurts. Bump it from above (dive onto it) and it pops.

## How far it bobs up and down (metres) and how fast.
@export var bob_height: float = 2.5
@export var bob_speed: float = 1.4
## How far it drifts left and right.
@export var drift: float = 1.5
## The wobbly jelly body, so it can pulse.
@export var pulse_target: Node3D

var _base_y: float = 0.0
var _age: float = 0.0


func _ready() -> void:
	super._ready()
	_base_y = position.y
	_age = start_x * 0.37


func _move(delta: float) -> void:
	_age += delta
	position.y = _base_y + sin(_age * bob_speed) * bob_height
	position.x = start_x + sin(_age * bob_speed * 0.6) * drift
	if pulse_target != null:
		var pulse: float = 1.0 + 0.12 * sin(_age * bob_speed * 4.0)
		pulse_target.scale = Vector3(pulse, 2.0 - pulse, pulse)
