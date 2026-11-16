extends Area3D
## Chilli Pepper power-up. Touch it for hot farts: super speed for a few seconds.

## How many points it is worth.
@export var points: int = 25
## How fast it spins.
@export var spin_speed: float = 3.0
## What Fart Man says when he grabs it. Leave empty for nothing.
@export var grab_words: String = "HOT HOT HOT!"


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	rotate_y(spin_speed * delta)


func _on_body_entered(body: Node3D) -> void:
	var player := body as Player
	if player == null or player.chilli == null:
		return
	player.chilli.start()
	Stage.award(self, points)
	player.say(grab_words, 1.2)
	queue_free()
