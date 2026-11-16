extends Area3D
## Rocket Burrito power-up. Touch it and Fart Man takes off: fart-powered flight!
## It never gets used up, so if he comes back here he can always take off again.

## He can't fly lower or higher than these heights during the flight.
@export var lowest_y: float = 3.0
@export var highest_y: float = 16.0
## Points for the first time he grabs it.
@export var points: int = 25
## How fast it spins.
@export var spin_speed: float = 3.0
## What Fart Man shouts on take-off. Leave empty for nothing.
@export var grab_words: String = "BLAST OFF!"

var points_given: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	rotate_y(spin_speed * delta)


func _on_body_entered(body: Node3D) -> void:
	var player := body as Player
	if player == null or player.flight == null or player.is_flying():
		return
	player.start_flying(lowest_y, highest_y)
	player.say(grab_words, 1.5)
	if not points_given:
		points_given = true
		Stage.award(self, points)
