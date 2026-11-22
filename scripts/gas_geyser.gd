class_name GasGeyser
extends SteamVent
## A gas geyser in the planet's floor. It rumbles (warning), then BLASTS a column of gas.
## Stand in it and it FILLS YOUR GAS TANK and shoots you high into the air. Never hurts.
## It is a steam vent with a bigger launch and a tank refill, so it has the same settings.

## How much gas it pours into the tank each second while he is in the column.
@export var refill_per_second: float = 220.0


func _init() -> void:
	off_time = 1.8
	puff_time = 1.1
	warn_time = 0.9
	launch_speed = 24.0


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if not is_puffing:
		return
	for body: Node3D in get_overlapping_bodies():
		var player := body as Player
		if player != null and not player.is_flying() and player.gas_tank != null:
			player.gas_tank.refill(refill_per_second * delta)
