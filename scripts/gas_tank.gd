class_name GasTank
extends Node
## Fart Man's gas tank. Farts use gas up.
## It slowly fills back up by itself, so he can never run out for good.
## Beans give a big chunk straight away.

## Sent every time the amount of gas changes. The gas bar listens to this.
signal gas_changed(gas: float, max_gas: float)

## How much gas a full tank holds.
@export var max_gas: float = 100.0
## How much gas he starts the level with.
@export var start_gas: float = 100.0
## How much gas comes back by itself each second. 0 = never refills.
@export var refill_per_second: float = 8.0
## After using gas, how long before it starts coming back, in seconds.
@export var refill_delay: float = 0.6

var gas: float = 0.0
## Set to true to stop the slow refill for now (Fart Man does this while charging).
var refill_paused: bool = false
var delay_left: float = 0.0


func _ready() -> void:
	gas = minf(start_gas, max_gas)
	gas_changed.emit(gas, max_gas)


func _physics_process(delta: float) -> void:
	if refill_paused or gas >= max_gas or refill_per_second <= 0.0:
		return
	if delay_left > 0.0:
		delay_left -= delta
		return
	gas = minf(gas + refill_per_second * delta, max_gas)
	gas_changed.emit(gas, max_gas)


## Tries to use some gas. Returns false (and uses nothing) if there is not enough.
func use(amount: float) -> bool:
	if amount > gas:
		return false
	gas -= amount
	delay_left = refill_delay
	gas_changed.emit(gas, max_gas)
	return true


## Lets some gas leak away. Takes whatever is left if there is not enough.
func drain(amount: float) -> void:
	delay_left = refill_delay
	if gas <= 0.0:
		return
	gas = maxf(gas - amount, 0.0)
	gas_changed.emit(gas, max_gas)


## Adds gas straight away, but never more than a full tank.
func refill(amount: float) -> void:
	gas = minf(gas + amount, max_gas)
	gas_changed.emit(gas, max_gas)
