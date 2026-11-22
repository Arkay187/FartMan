class_name ThrusterFlame
extends Node3D
## A rocket flame that flickers. It grows longer and fatter while the ship is flying.
## The flame points along -X from where this node sits, so stretch it by scaling X.

## True while the ship is flying between stops (the map ship sets this).
var boosting: bool = false
## How big the flame is when hovering and when flying (1 = as built).
@export var hover_size: float = 1.0
@export var flying_size: float = 2.2
## How much it flickers (0.2 = a fifth bigger or smaller) and how fast.
@export var flicker_amount: float = 0.2
@export var flicker_speed: float = 28.0
## How quickly it grows and shrinks when the ship starts or stops flying.
@export var grow_speed: float = 6.0

var _size: float = 1.0
var _time: float = 0.0


func _ready() -> void:
	_time = randf() * 10.0
	_size = hover_size


func _process(delta: float) -> void:
	_time += delta
	var target: float = flying_size if boosting else hover_size
	_size = lerpf(_size, target, 1.0 - exp(-grow_speed * delta))
	# Two wobbles at different speeds look like a real flicker.
	var flicker: float = 1.0 + flicker_amount * (sin(_time * flicker_speed) * 0.6 + sin(_time * flicker_speed * 1.7 + 1.3) * 0.4)
	scale = Vector3(_size * flicker, _size * (1.0 + (flicker - 1.0) * 0.5), _size * (1.0 + (flicker - 1.0) * 0.5))
