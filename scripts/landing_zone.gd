extends Area3D
## The end of a flight. When Fart Man flies into this, the flight stops and he drops
## back onto his feet. Put solid ground just after it.

## What he says when he lands. Leave empty for nothing.
@export var landing_words: String = "PHEW!"
## The ta-daa when he lands.
@export var landing_sound: AudioStream


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	var player := body as Player
	if player == null or not player.is_flying():
		return
	player.stop_flying()
	player.say(landing_words, 1.2)
	Sfx.play(self, landing_sound)
