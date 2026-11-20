class_name Conveyor
extends StaticBody3D
## A conveyor belt floor. Stand on it and it carries you along.
## Plus speed carries you right, minus speed carries you left.
## Dark stripes slide along the top so you can see which way it goes.

## How fast it carries, in metres per second. Negative = carries to the left.
@export var speed: float = 3.0
## How long the belt is (the stripes need to know).
@export var length: float = 10.0
## How many stripes are drawn on it.
@export var stripe_count: int = 8
## The holder of the stripes. The level kit makes it.
@export var stripes: Node3D

var _travel: float = 0.0


func _ready() -> void:
	# The engine does the carrying for us: anything standing on it is moved along.
	constant_linear_velocity = Vector3(speed, 0.0, 0.0)


func _process(delta: float) -> void:
	if stripes == null:
		return
	_travel += speed * delta
	var gap: float = length / float(maxi(stripe_count, 1))
	var index: int = 0
	for stripe: Node in stripes.get_children():
		(stripe as Node3D).position.x = fposmod(float(index) * gap + _travel, length) - length * 0.5
		index += 1
