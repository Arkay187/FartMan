class_name Chaser
extends Area3D
## A giant rolling cabbage that chases Fart Man. It sets off when he passes the start line,
## rolls along at a steady speed, and crashes at the finish line.
## It is a little slower than his running, so it only catches him if he stops or trips.
## Touching it costs a heart. If he pops back to a toilet, it goes back to the start.

## Sent when it crashes at the end.
signal crashed

## How fast it rolls, in metres per second. His running speed is 6.
@export var speed: float = 5.4
## It starts rolling when he gets past this x. It crashes when it reaches end_x.
@export var trigger_x: float = 0.0
@export var end_x: float = 100.0
## What it says when it starts and when it crashes.
@export var start_words: String = "RUN!"
@export var crash_words: String = "CRASH!"
## The big cabbage model. It spins as it rolls.
@export var visual: Node3D

var is_rolling: bool = false
var _start_position: Vector3
var _player: Player


func _ready() -> void:
	_start_position = position
	_player = get_tree().get_first_node_in_group(&"player") as Player
	if _player != null:
		_player.respawned.connect(reset)
	reset()


## Back to the start line, waiting.
func reset() -> void:
	position = _start_position
	is_rolling = false
	visible = true
	monitoring = true


func _physics_process(delta: float) -> void:
	if not is_rolling:
		if _player != null and _player.global_position.x > trigger_x and _player.global_position.x < end_x:
			is_rolling = true
			SpeechBubble.say(self, start_words, 1.5, 2.6)
		return
	position.x += speed * delta
	if visual != null:
		visual.rotation.z -= speed * delta / 1.2
	if position.x >= end_x:
		_crash()
		return
	for body: Node3D in get_overlapping_bodies():
		var player := body as Player
		if player != null:
			player.hurt(global_position.x)


func _crash() -> void:
	is_rolling = false
	SpeechBubble.say(self, crash_words, 1.5, 2.6)
	monitoring = false
	hide()
	crashed.emit()
