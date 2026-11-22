class_name BouncePad
extends Area3D
## A bouncy mushroom. Land or walk onto it and it boing-launches Fart Man high into the air.
## Hold jump or fart as you land for an even bigger bounce.

## Sent on every bounce. Use this later for the "boing" sound.
signal bounced

## Launch speed. 17 = about 5.8 metres high.
@export var bounce_power: float = 17.0
## Launch speed when holding a button as he lands.
@export var high_bounce_power: float = 21.0
## Seconds before it can bounce him again.
@export var cooldown: float = 0.25
## The mushroom cap, so it can squash when it bounces.
@export var cap: Node3D

var _cooldown_left: float = 0.0


func _physics_process(delta: float) -> void:
	_cooldown_left = maxf(_cooldown_left - delta, 0.0)
	if _cooldown_left > 0.0:
		return
	for body: Node3D in get_overlapping_bodies():
		var player := body as Player
		if player == null or player.velocity.y > 1.0 or player.is_flying():
			continue
		var holding: bool = Input.is_action_pressed(player.jump_action) or player.fart_held()
		player.velocity.y = high_bounce_power if holding else bounce_power
		_cooldown_left = cooldown
		_squash()
		bounced.emit()
		return


func _squash() -> void:
	if cap == null:
		return
	var tween: Tween = create_tween()
	tween.tween_property(cap, "scale", Vector3(1.3, 0.6, 1.3), 0.06)
	tween.tween_property(cap, "scale", Vector3(0.85, 1.25, 0.85), 0.1)
	tween.tween_property(cap, "scale", Vector3.ONE, 0.15)
