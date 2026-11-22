class_name GasCloud
extends AnimatableBody3D
## A squishy gas cloud you can stand on. It sinks a little when you stand on it, and if you
## LAND on it from a height it squashes and bounces you back up (hold jump for a bigger bounce).
## Walking onto it gently does not bounce, so it is still easy to run across.
## The kit builds the looks ("Visual") and a thin zone just above the top ("Sensor").

## Sent on every bounce.
signal bounced

## Launch speed after a landing. 15 = about 4.5 metres high.
@export var bounce_power: float = 15.0
## Launch speed when jump or fart is held on landing. 19 = about 7 metres high.
@export var high_bounce_power: float = 19.0
## He must land at least this fast (metres per second) for a bounce. 7 = a drop of about 1 m.
@export var min_impact: float = 7.0
## How far the cloud sinks while he stands on it, and how fast it sinks and comes back up.
@export var dip_depth: float = 0.5
@export var dip_speed: float = 5.0
@export var return_speed: float = 2.5
## Seconds before it can bounce him again.
@export var cooldown: float = 0.25
## The pictures of the cloud, so they can squash when it bounces.
@export var visual: Node3D
## A thin zone just above the top that notices him landing.
@export var sensor: Area3D
## The boing.
@export var boing_sound: AudioStream

var _rest_y: float = 0.0
var _cooldown_left: float = 0.0
var _fall_speed: float = 0.0


func _ready() -> void:
	_rest_y = position.y


func _physics_process(delta: float) -> void:
	_cooldown_left = maxf(_cooldown_left - delta, 0.0)
	var standing: bool = false
	var found: bool = false
	if sensor != null:
		for body: Node3D in sensor.get_overlapping_bodies():
			var player := body as Player
			if player == null or player.is_flying() or player.frozen:
				continue
			found = true
			if not player.is_on_floor():
				# Remember how fast he was falling just before landing.
				if player.velocity.y < 0.0:
					_fall_speed = maxf(_fall_speed, -player.velocity.y)
				continue
			if _fall_speed >= min_impact and _cooldown_left <= 0.0:
				_bounce(player)
			else:
				standing = true
			_fall_speed = 0.0
	if not found:
		_fall_speed = 0.0
	# Sink while he stands on it, rise back when he leaves.
	var target: float = _rest_y - dip_depth if standing else _rest_y
	var speed: float = dip_speed if standing else return_speed
	position.y = move_toward(position.y, target, speed * delta)


func _bounce(player: Player) -> void:
	var holding: bool = Input.is_action_pressed(player.jump_action) or player.fart_held()
	player.velocity.y = high_bounce_power if holding else bounce_power
	player.air_farts_used = 0
	if player.simple_helper != null:
		player.simple_helper.refill_air_jumps()
	_cooldown_left = cooldown
	Sfx.play(self, boing_sound)
	bounced.emit()
	if visual == null:
		return
	var tween: Tween = create_tween()
	tween.tween_property(visual, "scale", Vector3(1.1, 0.55, 1.1), 0.06)
	tween.tween_property(visual, "scale", Vector3(0.95, 1.2, 0.95), 0.1)
	tween.tween_property(visual, "scale", Vector3.ONE, 0.15)
