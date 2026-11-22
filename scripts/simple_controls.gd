class_name SimpleControls
extends Node
## The SIMPLE control scheme's jumping. Lives as a child of the Player.
## Just a normal platformer: one jump, and a free double jump in the air that is a Thunder fart.
## (Hovering on gas is in fart_hover.gd.) Only runs when the scheme is SIMPLE.

## Height of the first jump, as upward speed. 11.5 is the same as a Trump.
@export var simple_jump_power: float = 11.5
## Let go of jump while still rising and the upward speed is multiplied by this.
## Smaller = a tap makes a smaller hop. 1 = no short hops.
@export var jump_cut: float = 0.5
## He can still jump this many seconds after walking off a ledge.
@export var coyote_time: float = 0.1
## A jump pressed this many seconds before landing still counts.
@export var jump_buffer_time: float = 0.1
## How many extra jumps he gets in the air (the automatic Thunder fart).
@export var air_jumps: int = 1

var _player: Player
var _coyote_left: float = 0.0
var _buffer_left: float = 0.0
var _air_jumps_left: int = 0
## True while a jump is going up and letting go should cut it short.
var _cuttable: bool = false
var _jump_speed: float = 0.0


func _ready() -> void:
	_player = get_parent() as Player
	_air_jumps_left = air_jumps


## Air jumps he has left right now.
func air_jumps_left() -> int:
	return _air_jumps_left


## Landing and stomping give the air jump back.
func refill_air_jumps() -> void:
	_air_jumps_left = air_jumps


## Used by the hover: leaving the ground to hover must not leave a ground jump to spend.
func cancel_coyote() -> void:
	_coyote_left = 0.0
	_buffer_left = 0.0


## Called by the Player every physics frame, before it moves.
func update(delta: float) -> void:
	if _player == null:
		return
	var p: Player = _player
	if p.is_on_floor():
		_coyote_left = coyote_time
		_air_jumps_left = air_jumps
	else:
		_coyote_left = maxf(_coyote_left - delta, 0.0)

	# Jump and fart buttons both jump here.
	if Input.is_action_just_pressed(p.jump_action) or p.fart_just_pressed():
		_buffer_left = jump_buffer_time
	else:
		_buffer_left = maxf(_buffer_left - delta, 0.0)

	if _buffer_left > 0.0:
		if _coyote_left > 0.0:
			_ground_jump()
		elif _air_jumps_left > 0 and not _wall_wants_the_jump():
			_air_jump()

	_cut_short()


func _ground_jump() -> void:
	_buffer_left = 0.0
	_coyote_left = 0.0
	_player.velocity.y = simple_jump_power * _boost()
	_jump_speed = _player.velocity.y
	_cuttable = true
	_player.farted.emit("Toot")
	if _player.print_farts:
		print("Toot!")


## The automatic Thunder fart. Free, and cannot be cut short.
func _air_jump() -> void:
	_buffer_left = 0.0
	_air_jumps_left -= 1
	_player.velocity.y = _player.thunder_power * _boost()
	_cuttable = false
	_player.farted.emit("Thunder")
	if _player.print_farts:
		print("Thunder!")


## Letting go of jump while still rising makes the hop shorter.
func _cut_short() -> void:
	if not _cuttable:
		return
	var vy: float = _player.velocity.y
	if vy <= 0.0 or vy > _jump_speed + 0.01:
		_cuttable = false  # peaked, or something else (a spring, a cannon) launched him
		return
	if not (Input.is_action_pressed(_player.jump_action) or _player.fart_held()):
		_player.velocity.y = vy * jump_cut
		_cuttable = false


func _boost() -> float:
	return _player.chilli.jump_boost() if _player.chilli != null else 1.0


## On a wall in a test level the wall kick takes the jump instead.
func _wall_wants_the_jump() -> bool:
	return _player.wall_jump_enabled and _player.is_on_wall() and not _player.is_on_floor()
