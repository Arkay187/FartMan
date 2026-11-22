class_name GoldenBean
extends Area3D
## A Golden Bean. Three are hidden in every stage. Finding them is optional.

## Sent when Fart Man picks it up. The Stage counts these.
signal collected

## How fast it spins.
@export var spin_speed: float = 4.0
## How many points it is worth.
@export var points: int = 100
## What Fart Man says when he finds one. Leave empty for nothing.
@export var found_words: String = "GOLDEN BEAN!"
## The little fanfare when it is found.
@export var found_sound: AudioStream


func _ready() -> void:
	add_to_group(&"golden_beans")
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	rotate_y(spin_speed * delta)


func _on_body_entered(body: Node3D) -> void:
	var player := body as Player
	if player == null:
		return
	collected.emit()
	Stage.award(self, points)
	player.say(found_words)
	Sfx.play(self, found_sound)
	queue_free()
