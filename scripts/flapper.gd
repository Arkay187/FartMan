class_name Flapper
extends Burpling
## A Crow: flies back and forth, bobbing up and down. Stomp it from above.
## It also works in flying stages: bump it from above.

## How high it bobs, in metres, and how fast.
@export var bob_height: float = 1.2
@export var bob_speed: float = 3.0

var _base_y: float = 0.0
var _age: float = 0.0


func _ready() -> void:
	super._ready()
	_base_y = position.y


func _move(delta: float) -> void:
	super._move(delta)
	_age += delta
	position.y = _base_y + sin(_age * bob_speed + start_x) * bob_height
