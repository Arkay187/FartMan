extends CharacterBody3D
## Fart Man himself. Walks left and right, and jumps by farting.
## Tap jump for a small hop. Hold jump to charge a fart, let go to launch.
## Hold too long and it fizzles out as a weak "pfft".

## Sent when he starts charging.
signal charge_started
## Sent while charging, each time the charge reaches a new tier ("Toot", "Trump"...).
signal tier_changed(tier_name: String)
## Sent when he launches. Use this later for sounds and gas clouds.
signal farted(tier_name: String)

enum Tier { HOP, TOOT, TRUMP, THUNDER, PFFT }
const TIER_NAMES: Array[String] = ["Hop", "Toot", "Trump", "Thunder", "Pfft"]

@export_group("Walking")
## How fast he walks, in metres per second.
@export var move_speed: float = 6.0
## How quickly he gets up to speed on the ground. Bigger = snappier.
@export var ground_acceleration: float = 60.0
## How quickly he can change direction in the air. Smaller = floatier.
@export var air_acceleration: float = 25.0
## How strongly he is pulled down.
@export var gravity: float = 25.0
## Walking speed while charging. 0.5 = half speed, 0 = stands still.
@export_range(0.0, 1.0) var charge_move_multiplier: float = 0.5

@export_group("Charge times (seconds held)")
## Let go before this and it is just a hop.
@export var toot_time: float = 0.1
## Hold this long for a Trump.
@export var trump_time: float = 0.25
## Hold this long for a Thunder.
@export var thunder_time: float = 0.5
## Hold this long and it goes off by itself as a weak pfft.
@export var pfft_time: float = 0.85

@export_group("Launch power")
@export var hop_power: float = 6.0
@export var toot_power: float = 9.0
@export var trump_power: float = 12.5
@export var thunder_power: float = 16.0
@export var pfft_power: float = 4.0

@export_group("Charge squash")
## Optional: drag the player's MeshInstance3D here and he squats while charging.
@export var squash_target: Node3D
## How flat he gets at full charge. 0.6 = 60% of normal height.
@export_range(0.2, 1.0) var squash_amount: float = 0.6

@export_group("Controls")
## These are built into Godot: arrow keys and Space.
@export var left_action: StringName = &"ui_left"
@export var right_action: StringName = &"ui_right"
@export var jump_action: StringName = &"ui_accept"

@export_group("Testing")
## Prints the fart name in the Output panel so we can test without sounds.
@export var print_farts: bool = true

var is_charging: bool = false
var charge_time: float = 0.0
var current_tier: Tier = Tier.HOP


func _physics_process(delta: float) -> void:
	# Fall when in the air.
	if not is_on_floor():
		velocity.y -= gravity * delta

	_update_charge(delta)

	# Left / right. direction is -1, 0 or 1.
	var direction: float = Input.get_axis(left_action, right_action)
	var speed: float = move_speed * (charge_move_multiplier if is_charging else 1.0)
	var acceleration: float = ground_acceleration if is_on_floor() else air_acceleration
	velocity.x = move_toward(velocity.x, direction * speed, acceleration * delta)

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
		current_tier = Tier.HOP
		charge_started.emit()

	if not is_charging:
		return

	charge_time += delta
	_squash(charge_time / pfft_time)

	var tier: Tier = _tier_for(charge_time)
	if tier != current_tier:
		current_tier = tier
		tier_changed.emit(TIER_NAMES[tier])

	# Launch when the button is let go, or when it has been held too long.
	if tier == Tier.PFFT or not Input.is_action_pressed(jump_action):
		_launch(tier)


## Which fart do you get for holding this long?
func _tier_for(held: float) -> Tier:
	if held >= pfft_time:
		return Tier.PFFT
	if held >= thunder_time:
		return Tier.THUNDER
	if held >= trump_time:
		return Tier.TRUMP
	if held >= toot_time:
		return Tier.TOOT
	return Tier.HOP


func _power_for(tier: Tier) -> float:
	match tier:
		Tier.TOOT:
			return toot_power
		Tier.TRUMP:
			return trump_power
		Tier.THUNDER:
			return thunder_power
		Tier.PFFT:
			return pfft_power
	return hop_power


func _launch(tier: Tier) -> void:
	velocity.y = _power_for(tier)
	_stop_charging()
	farted.emit(TIER_NAMES[tier])
	if print_farts:
		print(TIER_NAMES[tier], "!")


func _stop_charging() -> void:
	is_charging = false
	charge_time = 0.0
	_squash(0.0)


## amount is 0 (standing normally) to 1 (fully squashed).
func _squash(amount: float) -> void:
	if squash_target == null:
		return
	var height: float = lerpf(1.0, squash_amount, clampf(amount, 0.0, 1.0))
	squash_target.scale = Vector3(1.0, height, 1.0)
