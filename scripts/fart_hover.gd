class_name FartHover
extends Node
## Fart hover for the SIMPLE controls. Lives as a child of the Player.
## Hold the HOVER button (Left Shift / X / left bumper) in the air and he floats on a fart cloud,
## like a hover pack. It uses gas. The cloud under his feet squashes enemies.

## Sent when the hover starts and stops.
signal started
signal stopped

## How high above the ground he floats when hover is pressed on the ground, in metres.
@export var hover_height: float = 2.5
## How quickly he rises to that height. Higher = snappier. It eases in, so no bounce past it.
@export var rise_gain: float = 9.0
## The fastest he ever rises on the way up (m/s).
@export var rise_max_speed: float = 12.0
## Pressed in the air: rising slower than this (m/s) counts as "done jumping" when the button
## was already held, so a held button takes over at the top of a jump.
@export var hover_rise_speed: float = 0.0
## How hard the hover pushes his up/down speed towards where it wants him (m/s per second).
@export var hover_lift: float = 60.0
## Gas used each second while hovering. 25 means a full tank lasts 4 seconds.
@export var hover_gas_per_second: float = 25.0
## In the NO GAS / ALWAYS FULL test modes: how many seconds of hover per time in the air.
@export var hover_time_free_gas: float = 3.0
## Right after leaving the ground he is not "landed" for this long (seconds).
@export var liftoff_grace: float = 0.15

## Sent while hovering with how much hover is left (0 to 1), and once more when it ends.
## `timed` is true in the free-gas test modes, where the fuel is time and not the gas tank.
signal fuel_changed(fraction: float, active: bool, timed: bool)

var is_hovering: bool = false
var cloud: HoverCloud
var _player: Player
var _free_time_left: float = 0.0
## Out of gas: no more hover until he lets go or lands.
var _spent: bool = false
## The height (the Player's y) he is floating at.
var _target_y: float = 0.0
## The up/down speed the hover set last frame, to notice a jump pushing him up.
var _set_vy: float = 0.0
var _grace_left: float = 0.0


func _ready() -> void:
	_player = get_parent() as Player
	_free_time_left = hover_time_free_gas
	cloud = HoverCloud.new()
	cloud.name = "HoverCloud"
	# The Player is still busy setting up its children, so add the cloud a moment later.
	_player.add_child.call_deferred(cloud)
	# Run after the player has moved, to tidy up if the hover has to stop.
	process_physics_priority = 10


## Called by the Player every physics frame, before it moves.
func update(delta: float) -> void:
	if _player == null:
		return
	var p: Player = _player
	var pressed: bool = Input.is_action_just_pressed(&"hover")
	var from_ground: bool = false
	_grace_left = maxf(_grace_left - delta, 0.0)
	if p.is_on_floor() and _grace_left <= 0.0:
		_free_time_left = hover_time_free_gas
		_spent = false
		_stop()
		# Hover pressed on the ground: jump up to the standard hover height (unless the jump
		# button is jumping this very moment).
		if pressed and not _jump_pressed(p):
			_target_y = p.global_position.y + hover_height
			from_ground = true
			_leave_ground(p)
		else:
			return
	elif not Input.is_action_pressed(&"hover"):
		_spent = false
		_stop()
		return
	if _spent:
		return
	if from_ground:
		pass  # the target is already set
	elif not is_hovering:
		if pressed:
			_target_y = p.global_position.y  # pressed in the air: stay at this height
		elif p.velocity.y > hover_rise_speed:
			return  # button was already held, still going up from a jump: wait for the top
		else:
			_target_y = p.global_position.y
	elif p.velocity.y > _set_vy + 1.0:
		# Something pushed him up (the double jump, a spring): let it, hover again at the top.
		_stop()
		return
	if p.is_on_ceiling() and _target_y > p.global_position.y:
		_target_y = p.global_position.y  # bumped his head: float here
	if not _pay(delta):
		_spent = true
		_stop()
		p.fizzled.emit()
		if p.print_farts:
			print("Pfft...")
		return
	# Ease towards the hover height: quick at first, gentle at the end, no overshoot.
	var want: float = clampf((_target_y - p.global_position.y) * rise_gain, -rise_max_speed, rise_max_speed)
	p.velocity.y = move_toward(p.velocity.y, want, hover_lift * delta)
	_set_vy = p.velocity.y
	_start()
	_send_fuel(true)


## Leaves the ground for a ground hover.
func _leave_ground(p: Player) -> void:
	_grace_left = liftoff_grace
	if p.simple_helper != null:
		p.simple_helper.cancel_coyote()
	_set_vy = 0.0


func _jump_pressed(p: Player) -> bool:
	return Input.is_action_just_pressed(p.jump_action) or p.fart_just_pressed()


## How much hover he has left, 0 to 1.
func fuel_fraction() -> float:
	var tank: GasTank = _player.gas_tank
	if _time_limited():
		return clampf(_free_time_left / hover_time_free_gas, 0.0, 1.0)
	if tank == null or tank.max_gas <= 0.0:
		return 1.0
	return clampf(tank.gas / tank.max_gas, 0.0, 1.0)


## True in the free-gas test modes, where hover is limited by time, not by the tank.
func _time_limited() -> bool:
	var options := get_node_or_null("/root/DebugOptions") as DebugOptionsData
	return options != null and options.farts_are_free()


func _send_fuel(active: bool) -> void:
	fuel_changed.emit(fuel_fraction(), active, _time_limited())


## Uses a little gas (or a little of the free time). False when there is none left.
func _pay(delta: float) -> bool:
	var tank: GasTank = _player.gas_tank
	if tank == null:
		return true
	if _time_limited():
		_free_time_left -= delta
		return _free_time_left > 0.0
	if tank.gas <= 0.0:
		return false
	tank.drain(hover_gas_per_second * delta)
	return true


func _start() -> void:
	if is_hovering:
		return
	is_hovering = true
	if cloud != null:
		cloud.set_active(true)
	started.emit()
	_player.hover_started.emit()


func _stop() -> void:
	if not is_hovering:
		return
	is_hovering = false
	if cloud != null:
		cloud.set_active(false)
	_send_fuel(false)
	stopped.emit()
	_player.hover_stopped.emit()


## Safety net after the player has moved: stop if anything took over.
func _physics_process(_delta: float) -> void:
	if not is_hovering:
		return
	if not _player.is_simple() or _player.is_flying() or _player.frozen or _player.is_dying \
			or _player.input_locked or _player.is_on_floor():
		_stop()
