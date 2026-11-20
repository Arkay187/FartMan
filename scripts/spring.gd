class_name Spring
extends Area3D
## A big coil spring for tall levels. Land on it and it boings you up.
## Press JUMP (or FART) just as you land, or a moment before, for a MEGA boing.

## Sent on every bounce.
signal bounced(mega: bool)

## Launch speed for a plain landing. 21 = about 8.8 m high.
@export var bounce_power: float = 21.0
## Launch speed for a well-timed press. 28 = about 15.7 m high.
@export var mega_power: float = 28.0
## A press this many seconds BEFORE landing still counts as a mega boing.
@export var early_press_window: float = 0.25
## Seconds before it can bounce him again.
@export var cooldown: float = 0.3
## The coil part that squashes when it bounces.
@export var coil: Node3D

var _cooldown_left: float = 0.0
var _since_press: float = 100.0


func _physics_process(delta: float) -> void:
	_cooldown_left = maxf(_cooldown_left - delta, 0.0)
	_since_press += delta
	if Input.is_action_just_pressed(&"jump") or Input.is_action_just_pressed(&"fart"):
		_since_press = 0.0
	if _cooldown_left > 0.0:
		return
	for body: Node3D in get_overlapping_bodies():
		var player := body as Player
		if player == null or player.velocity.y > 1.0 or player.is_flying() or player.frozen:
			continue
		var mega: bool = _since_press <= early_press_window \
			or Input.is_action_pressed(player.jump_action) or Input.is_action_pressed(player.fart_action)
		player.velocity.y = mega_power if mega else bounce_power
		player.air_farts_used = 0  # a fresh jump: air farts are back
		_cooldown_left = cooldown
		_since_press = 100.0
		_squash(mega)
		bounced.emit(mega)
		return


func _squash(mega: bool) -> void:
	if coil == null:
		return
	var tween: Tween = create_tween()
	tween.tween_property(coil, "scale", Vector3(1.25, 0.5, 1.25), 0.06)
	tween.tween_property(coil, "scale", Vector3(0.85, 1.35 if mega else 1.15, 0.85), 0.1)
	tween.tween_property(coil, "scale", Vector3.ONE, 0.15)
