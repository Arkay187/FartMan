class_name GoldenBean
extends Area3D
## A Golden Bean. Three are hidden in every stage. Finding them is optional.

## Sent when Fart Man picks it up. The Stage counts these.
signal collected

## How fast it spins.
@export var spin_speed: float = 4.0
## What Fart Man says when he finds one. Leave empty for nothing.
@export var found_words: String = "GOLDEN BEAN!"


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
	player.say(found_words)
	queue_free()
