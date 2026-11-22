extends Area3D
## Hot Sauce bottle power-up. Touch it to get the FIRE BURP for the rest of the stage:
## press the fire button (C / pad B) to burp a rolling fireball.

## How many points it is worth.
@export var points: int = 25
## How fast it spins.
@export var spin_speed: float = 2.5
## How high it bobs up and down, in metres.
@export var bob_height: float = 0.12
## How fast it bobs.
@export var bob_speed: float = 3.0
## Plays when he grabs it.
@export var grab_sound: AudioStream

var _time: float = 0.0
var _home_y: float = 0.0


func _ready() -> void:
	_home_y = position.y
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_time += delta
	rotate_y(spin_speed * delta)
	# A thrown bottle (from an enemy) is moved by its LootBounce: don't bob until it is resting.
	if get_node_or_null("LootBounce") == null:
		position.y = _home_y + sin(_time * bob_speed) * bob_height


func _on_body_entered(body: Node3D) -> void:
	var player := body as Player
	if player == null or player.fire_burp == null:
		return
	player.fire_burp.collect()
	Stage.award(self, points)
	Sfx.play(self, grab_sound)
	queue_free()
