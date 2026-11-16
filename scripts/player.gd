class_name Player
extends CharacterBody3D
## Fart Man himself. Walks left and right, and jumps by farting.
##
## Tap jump: small jump (Toot).
## Hold jump: his belly grows. Let go for a medium jump (Trump).
## Let go when the belly is full: big jump (Thunder).
## Hold too long: a long squeaky fart leaks out, the belly slowly goes down
## and gas drains away. Let go any time and he jumps with whatever belly is left.

## Sent when he starts charging.
signal charge_started
## Sent when he launches. Use this later for sounds and gas clouds.
signal farted(tier_name: String)
## Sent when the long squeaky leak starts and stops. Use these later for the sound.
signal squeak_started
signal squeak_stopped
## Sent when he falls off the level and pops back to the start.
signal respawned

enum Tier { TOOT, TRUMP, THUNDER }
const TIER_NAMES: Array[String] = ["Toot", "Trump", "Thunder"]

@export_group("Walking")
## How fast he walks, in metres per second.
@export var move_speed: float = 6.0
## How quickly he gets up to speed on the ground. Bigger = snappier.
@export var ground_acceleration: float = 60.0
## How quickly he can change direction in the air. Smaller = floatier.
@export var air_acceleration: float = 25.0
## How strongly he is pulled down.
@export var gravity: float = 25.0
## Fall below this height and he pops back to where he started.
@export var fall_limit_y: float = -10.0

@export_group("Charge times (seconds)")
## Let go before this and it counts as a tap: small jump.
@export var tap_time: float = 0.15
## How long to hold until the belly is full.
@export var full_charge_time: float = 0.5
## How long the belly stays full before it starts to leak.
@export var full_hold_time: float = 0.35
## How long a full belly takes to leak away completely.
@export var squeak_time: float = 1.5

@export_group("Jump power")
## Small jump (tap).
@export var toot_power: float = 7.5
## Medium jump (belly partly full).
@export var trump_power: float = 11.5
## Big jump (belly full).
@export var thunder_power: float = 16.0

@export_group("Gas")
## His gas tank. Leave empty for unlimited gas.
@export var gas_tank: GasTank
## Gas each jump uses. The small tap jump is free so he can never get stuck.
@export var trump_cost: float = 20.0
@export var thunder_cost: float = 35.0
## Gas wasted each second while the squeaky leak is going.
@export var squeak_gas_per_second: float = 10.0

@export_group("Looks")
## The part of him that turns to face the way he walks.
@export var visual: Node3D
## The belly model. It grows while charging and hides the rest of the time.
@export var belly: Node3D
## How big the belly is when completely full.
@export var belly_full_scale: float = 1.1

@export_group("Controls")
## These are built into Godot: arrow keys and Space.
@export var left_action: StringName = &"ui_left"
@export var right_action: StringName = &"ui_right"
@export var jump_action: StringName = &"ui_accept"

@export_group("Testing")
## Prints the fart name in the Output panel so we can test without sounds.
@export var print_farts: bool = true

var is_charging: bool = false
var is_squeaking: bool = false
var charge_time: float = 0.0
## How full the belly is: 0 = empty, 1 = full.
var belly_fill: float = 0.0
## Where he started the level. He comes back here if he falls off.
var start_position: Vector3


func _ready() -> void:
	start_position = global_position
	_show_belly()


func _physics_process(delta: float) -> void:
	# Fell off the level? Pop back to the start.
	if global_position.y < fall_limit_y:
		_respawn()
		return

	# Fall when in the air.
	if not is_on_floor():
		velocity.y -= gravity * delta

	_update_charge(delta)

	# Left / right. direction is -1, 0 or 1.
	var direction: float = Input.get_axis(left_action, right_action)
	var acceleration: float = ground_acceleration if is_on_floor() else air_acceleration
	velocity.x = move_toward(velocity.x, direction * move_speed, acceleration * delta)

	# Turn to face the way he is walking.
	if visual != null and direction != 0.0:
		visual.rotation.y = 0.0 if direction > 0.0 else PI

	# 2.5D: never move towards or away from the camera.
	velocity.z = 0.0
	move_and_slide()
	position.z = 0.0


## Handles holding, charging and letting go of the jump button.
func _update_charge(delta: float) -> void:
	# You can only charge with your feet on the ground.
	if not is_on_floor():
		if is_charging:
			_stop_charging()
		return

	if Input.is_action_just_pressed(jump_action):
		is_charging = true
		charge_time = 0.0
		belly_fill = 0.0
		charge_started.emit()

	if not is_charging:
		return

	# Letting go always launches, with whatever is in the belly right now.
	if not Input.is_action_pressed(jump_action):
		_launch(_tier_now())
		return

	charge_time += delta
	if charge_time < full_charge_time:
		# Belly growing.
		belly_fill = charge_time / full_charge_time
	elif charge_time < full_charge_time + full_hold_time:
		# Belly full: the moment to let go for a Thunder.
		belly_fill = 1.0
	else:
		# Held too long: it leaks out as a long squeak until the belly is empty.
		_leak(delta)
	_show_belly()


## The long squeaky fart: the belly goes down slowly and gas is wasted.
func _leak(delta: float) -> void:
	if belly_fill <= 0.0:
		_set_squeaking(false)
		return
	_set_squeaking(true)
	belly_fill = maxf(belly_fill - delta / squeak_time, 0.0)
	if gas_tank != null:
		gas_tank.drain(squeak_gas_per_second * delta)


## Which jump do you get if you let go right now?
func _tier_now() -> Tier:
	if belly_fill >= 1.0:
		return Tier.THUNDER
	if charge_time >= tap_time and belly_fill > 0.0:
		return Tier.TRUMP
	return Tier.TOOT


func _power_for(tier: Tier) -> float:
	match tier:
		Tier.TRUMP:
			return trump_power
		Tier.THUNDER:
			return thunder_power
	return toot_power


func _cost_for(tier: Tier) -> float:
	match tier:
		Tier.TRUMP:
			return trump_cost
		Tier.THUNDER:
			return thunder_cost
	return 0.0


func _can_pay_for(tier: Tier) -> bool:
	var cost: float = _cost_for(tier)
	return gas_tank == null or cost <= 0.0 or gas_tank.use(cost)


func _launch(tier: Tier) -> void:
	# Not enough gas? Drop down to the biggest jump he can afford.
	if tier == Tier.THUNDER and not _can_pay_for(Tier.THUNDER):
		tier = Tier.TRUMP
	if tier == Tier.TRUMP and not _can_pay_for(Tier.TRUMP):
		tier = Tier.TOOT

	velocity.y = _power_for(tier)
	_stop_charging()
	farted.emit(TIER_NAMES[tier])
	if print_farts:
		print(TIER_NAMES[tier], "!")


func _respawn() -> void:
	global_position = start_position
	velocity = Vector3.ZERO
	_stop_charging()
	respawned.emit()


func _stop_charging() -> void:
	is_charging = false
	charge_time = 0.0
	belly_fill = 0.0
	_set_squeaking(false)
	_show_belly()


func _set_squeaking(on: bool) -> void:
	if on == is_squeaking:
		return
	is_squeaking = on
	if on:
		squeak_started.emit()
		if print_farts:
			print("Squeeeeak...")
	else:
		squeak_stopped.emit()


## Grows or hides the belly model to match belly_fill.
func _show_belly() -> void:
	if belly == null:
		return
	belly.visible = belly_fill > 0.0
	belly.scale = Vector3.ONE * maxf(belly_fill * belly_full_scale, 0.01)
