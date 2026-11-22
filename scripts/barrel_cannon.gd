class_name BarrelCannon
extends Area3D
## A barrel cannon. Hop in and it holds you. Press JUMP or FART and BOOM, you are
## fired out the way the barrel is pointing.
## The barrel can point one fixed way, or swing back and forth so you have to pick your moment.

## Sent when he climbs in, and when he is fired out.
signal loaded
signal fired

## The way it points, in degrees: 0 = right, 90 = straight up, 180 = left.
@export var aim_degrees: float = 90.0
## If bigger than 0, the barrel swings between aim_degrees and this angle.
@export var swing_to_degrees: float = 0.0
## How many seconds one full swing there and back takes.
@export var swing_time: float = 2.4
## How fast he leaves the barrel, in metres per second. 22 = about 9.7 m straight up.
@export var launch_speed: float = 22.0
## He can't steer for this long after the blast (or until he lands), so he keeps
## flying the way it pointed.
@export var no_steer_time: float = 1.5
## The wait after climbing in before a button fires it, in seconds.
@export var hold_time: float = 0.25
## Fire by itself after this long. 0 = wait for a button forever.
@export var auto_fire_after: float = 0.0
## Rest time after firing before it catches anyone again.
@export var cooldown: float = 0.6
## The part that turns to point the way. Leave empty and nothing turns.
@export var barrel: Node3D

var held: Player = null
var current_aim: float = 90.0
var _held_for: float = 0.0
var _cooldown_left: float = 0.0
var _age: float = 0.0


func _ready() -> void:
	current_aim = aim_degrees
	# Run after the player moves, so he stays put inside.
	process_physics_priority = 5


func _physics_process(delta: float) -> void:
	_age += delta
	_cooldown_left = maxf(_cooldown_left - delta, 0.0)
	_update_aim()
	if held == null:
		_look_for_player()
		return
	if not is_instance_valid(held) or held.is_dying:
		_release_without_firing()
		return
	_held_for += delta
	held.global_position = global_position
	held.velocity = Vector3.ZERO
	var pressed: bool = Input.is_action_just_pressed(held.jump_action) or held.fart_just_pressed()
	var late: bool = auto_fire_after > 0.0 and _held_for >= auto_fire_after
	if _held_for >= hold_time and (pressed or late):
		fire()


## The barrel's direction as a unit vector.
func aim_vector() -> Vector3:
	var a: float = deg_to_rad(current_aim)
	return Vector3(cos(a), sin(a), 0.0)


func _update_aim() -> void:
	if swing_to_degrees != 0.0 and swing_time > 0.0:
		# 0 -> 1 -> 0 smoothly, over swing_time seconds.
		var t: float = 0.5 - 0.5 * cos(TAU * _age / swing_time)
		current_aim = lerpf(aim_degrees, swing_to_degrees, t)
	if barrel != null:
		# The barrel model points along its own up axis: tilt it to match.
		barrel.rotation = Vector3(0.0, 0.0, deg_to_rad(current_aim - 90.0))


func _look_for_player() -> void:
	if _cooldown_left > 0.0:
		return
	for body: Node3D in get_overlapping_bodies():
		var player := body as Player
		if player == null or player.is_dying or player.is_flying() or player.frozen:
			continue
		held = player
		held.frozen = true
		held.push_left = 0.0
		held.global_position = global_position
		_held_for = 0.0
		SpeechBubble.say(self, "READY!", 0.8, 2.0)
		loaded.emit()
		return


## Blast the held player out. (Buttons call this; tests can too.)
func fire() -> void:
	if held == null:
		return
	var player: Player = held
	held = null
	player.frozen = false
	player.global_position = global_position + aim_vector() * 1.0
	player.velocity = aim_vector() * launch_speed
	player.push_left = no_steer_time
	_cooldown_left = cooldown
	fired.emit()


func _release_without_firing() -> void:
	if is_instance_valid(held):
		held.frozen = false
	held = null
	_cooldown_left = cooldown
