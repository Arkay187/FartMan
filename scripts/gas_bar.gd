extends ProgressBar
## The gas bar on screen. Shows how full Fart Man's tank is.

## Whose gas tank to show.
@export var player: Player


func _ready() -> void:
	if player == null or player.gas_tank == null:
		return
	var tank: GasTank = player.gas_tank
	tank.gas_changed.connect(_on_gas_changed)
	_on_gas_changed(tank.gas, tank.max_gas)


func _on_gas_changed(gas: float, max_gas: float) -> void:
	max_value = max_gas
	value = gas
