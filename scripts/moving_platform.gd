class_name MovingPlatform
extends AnimatableBody3D
## A platform that glides back and forth, like a wheelbarrow or a lift.
## It rests for a moment at each end, so you have time to hop on or off.

## How far it moves from where it was placed (it goes there and back).
@export var travel: Vector3 = Vector3(8, 0, 0)
## How fast it glides, in metres per second.
@export var speed: float = 3.0
## How long it rests at each end, in seconds.
@export var pause: float = 1.0
## Where in the trip it starts (0 to 1).
@export var phase: float = 0.0

var _origin: Vector3
var _age: float = 0.0


func _ready() -> void:
	sync_to_physics = true
	_origin = position
	_age = phase * _cycle()


## Seconds for a full there-and-back trip including the rests.
func _cycle() -> float:
	return 2.0 * (travel.length() / speed + pause)


func _physics_process(delta: float) -> void:
	_age = fmod(_age + delta, _cycle())
	position = _origin + travel * _progress()


## 0 = at the start, 1 = at the far end.
func _progress() -> float:
	var run: float = travel.length() / speed
	var t: float = _age
	if t < run:
		return t / run
	t -= run
	if t < pause:
		return 1.0
	t -= pause
	if t < run:
		return 1.0 - t / run
	return 0.0
