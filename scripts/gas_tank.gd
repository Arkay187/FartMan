class_name GasTank
extends Node
## Fart Man's gas tank. Farts use gas up, beans fill it back up.

## Sent every time the amount of gas changes. The gas bar listens to this.
signal gas_changed(gas: float, max_gas: float)

## How much gas a full tank holds.
@export var max_gas: float = 100.0
## How much gas he starts the level with.
@export var start_gas: float = 100.0

var gas: float = 0.0


func _ready() -> void:
	gas = minf(start_gas, max_gas)
	gas_changed.emit(gas, max_gas)


## Tries to use some gas. Returns false (and uses nothing) if there is not enough.
func use(amount: float) -> bool:
	if amount > gas:
		return false
	gas -= amount
	gas_changed.emit(gas, max_gas)
	return true


## Adds gas, but never more than a full tank.
func refill(amount: float) -> void:
	gas = minf(gas + amount, max_gas)
	gas_changed.emit(gas, max_gas)
