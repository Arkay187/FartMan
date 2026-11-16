class_name PulseHazard
extends Area3D
## A sprinkler jet that switches on and off. It flickers for a moment before it
## switches on, so you can see it coming. Run through while it is off.

## Seconds it is on, seconds it is off, and the warning flicker just before it is on.
@export var on_time: float = 1.3
@export var off_time: float = 2.0
@export var warn_time: float = 0.7
## Where in the cycle it starts (0 to 1), so a row of jets does not all go off together.
@export var phase: float = 0.0
## The water column. It grows tall while on, and shrinks to a drip while off.
@export var jet: Node3D

var is_on: bool = false
var _age: float = 0.0


func _ready() -> void:
	_age = phase * (on_time + off_time)


func _physics_process(delta: float) -> void:
	_age = fmod(_age + delta, on_time + off_time)
	# The cycle: off, then a warning flicker, then on.
	var off_part: float = off_time - warn_time
	is_on = _age >= off_time
	var warning: bool = not is_on and _age >= off_part
	if jet != null:
		if is_on:
			jet.scale = Vector3.ONE
		elif warning:
			var flicker: float = 0.25 + 0.15 * sin(_age * 60.0)
			jet.scale = Vector3(1.0, flicker, 1.0)
		else:
			jet.scale = Vector3(1.0, 0.05, 1.0)
	if not is_on:
		return
	for body: Node3D in get_overlapping_bodies():
		var player := body as Player
		if player != null:
			player.hurt(global_position.x)
