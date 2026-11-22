class_name SteamVent
extends Area3D
## A steam vent in the floor. It hisses a little (WARNING), then PUFFS a column of steam.
## If he is standing in the puff he is launched high up, and gets another air fart.
## Steam never hurts.

## Sent at the start of each puff. Use this later for the "PSSHT" sound.
signal puffed

## Seconds it is quiet (the last part of this is the warning hiss), and seconds it puffs.
@export var off_time: float = 2.2
@export var puff_time: float = 0.7
## The warning hiss at the end of the quiet time.
@export var warn_time: float = 0.8
## How fast it launches him. 19 = about 10 metres up from the vent.
@export var launch_speed: float = 19.0
## Where in the cycle it starts (0 to 1).
@export var phase: float = 0.0
## The steam column. Its origin is at the bottom, so scaling it makes it grow upwards.
@export var column: Node3D
## The hiss when it puffs.
@export var puff_sound: AudioStream

var is_puffing: bool = false
var _age: float = 0.0


func _ready() -> void:
	_age = phase * (off_time + puff_time)


func _physics_process(delta: float) -> void:
	var was_puffing: bool = is_puffing
	_age = fmod(_age + delta, off_time + puff_time)
	is_puffing = _age >= off_time
	var warning: bool = not is_puffing and _age >= off_time - warn_time
	if is_puffing and not was_puffing:
		puffed.emit()
		Sfx.play(self, puff_sound)
	if column != null:
		if is_puffing:
			column.scale = Vector3.ONE
		elif warning:
			column.scale = Vector3(0.35, 0.18 + 0.1 * sin(_age * 50.0), 0.35)
		else:
			column.scale = Vector3(0.01, 0.01, 0.01)
	if not is_puffing:
		return
	for body: Node3D in get_overlapping_bodies():
		var player := body as Player
		if player == null or player.is_flying() or player.is_dying:
			continue
		if player.velocity.y < launch_speed:
			player.velocity.y = launch_speed
		player.air_farts_used = 0
