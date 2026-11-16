extends Area3D
## A bean. Touch it to refill some gas.

## How much gas one bean gives.
@export var gas_amount: float = 25.0
## How fast it spins, just so it is easy to spot.
@export var spin_speed: float = 3.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	rotate_y(spin_speed * delta)


func _on_body_entered(body: Node3D) -> void:
	# Only Fart Man can eat beans.
	var player := body as Player
	if player == null or player.gas_tank == null:
		return
	player.gas_tank.refill(gas_amount)
	queue_free()
