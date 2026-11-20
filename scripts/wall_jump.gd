class_name WallJump
extends Node
## Wall slide and wall jump for Fart Man. Lives as a child of the Player.
## Only works when the Player's `wall_jump_enabled` box is ticked (off in the normal worlds).
##
## In the air, push towards a wall: he slides down it slowly.
## Press jump while on the wall: he kicks off it, away and up.

## Sent when he kicks off a wall. Use this later for a sound.
signal wall_jumped

## The slowest he is allowed to fall while sliding on a wall, in metres per second.
@export var slide_speed: float = 3.0
## How hard he kicks up off the wall (about 2.9 m high at 12).
@export var jump_power: float = 12.5
## How fast he is thrown away from the wall.
@export var kick_speed: float = 8.0
## How long he can't steer after a kick, so he really leaves the wall.
@export var kick_time: float = 0.22
## Grace time: a jump pressed just after leaving a wall still counts.
@export var coyote_time: float = 0.1

var is_sliding: bool = false
var _player: Player
var _wall_side: float = 0.0   # which way the wall pushes him: -1 wall on the right, 1 on the left
var _on_wall_left: float = 0.0


func _ready() -> void:
	_player = get_parent() as Player
	# Run after the player has moved, so the wall contact is fresh.
	process_physics_priority = 10


func _physics_process(delta: float) -> void:
	is_sliding = false
	if _player == null or not _player.wall_jump_enabled:
		return
	if _player.is_on_floor() or _player.is_flying() or _player.frozen or _player.is_dying:
		_on_wall_left = 0.0
		return

	# Touching a wall while pushing into it?
	if _player.is_on_wall():
		var normal: Vector3 = _player.get_wall_normal()
		var push: float = Input.get_axis(_player.left_action, _player.right_action)
		if absf(normal.x) > 0.5:
			_wall_side = signf(normal.x)
			_on_wall_left = coyote_time
			if push * _wall_side < 0.0 and _player.velocity.y < -slide_speed:
				_player.velocity.y = -slide_speed
				is_sliding = true
	else:
		_on_wall_left = maxf(_on_wall_left - delta, 0.0)

	# The kick.
	if _on_wall_left > 0.0 and not _player.input_locked and Input.is_action_just_pressed(_player.jump_action):
		_player.velocity = Vector3(_wall_side * kick_speed, jump_power, 0.0)
		_player.push_left = kick_time
		_on_wall_left = 0.0
		if _player.visual != null:
			_player.visual.rotation.y = 0.0 if _wall_side > 0.0 else PI
		wall_jumped.emit()
