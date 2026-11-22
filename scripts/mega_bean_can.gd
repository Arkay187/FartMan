extends Area3D
## Mega Bean Can power-up. Touch it and the gas tank is completely full, right now.

## How many points it is worth.
@export var points: int = 25
## How fast it spins.
@export var spin_speed: float = 3.0
## What Fart Man says when he grabs it. Leave empty for nothing.
@export var grab_words: String = "FULL TANK!"
## The glug-glug when he grabs it.
@export var grab_sound: AudioStream


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	rotate_y(spin_speed * delta)


func _on_body_entered(body: Node3D) -> void:
	var player := body as Player
	if player == null or player.gas_tank == null:
		return
	player.gas_tank.refill(player.gas_tank.max_gas)
	Stage.award(self, points)
	player.say(grab_words, 1.2)
	Sfx.play(self, grab_sound)
	queue_free()
