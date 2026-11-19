class_name BeanCan
extends StaticBody3D
## The giant Bean Can at the end of a stage.
## It is too tall for a Toot or a Trump: Thunder-jump onto the lid to pop it open.

## Sent when the lid pops. The Stage uses this to finish the stage.
signal opened

## The lid model. It flies off when the can opens.
@export var lid: Node3D
## The invisible zone just above the lid that notices Fart Man landing.
@export var lid_sensor: Area3D
## How many points opening it is worth.
@export var points: int = 500
## What Fart Man shouts when it opens. Leave empty for nothing.
@export var open_words: String = "BEANS! TOOT TOOT!"
## How high the lid flies, and how long it takes.
@export var lid_fly_height: float = 8.0
@export var lid_fly_time: float = 0.7

var is_open: bool = false


func _ready() -> void:
	add_to_group(&"bean_cans")
	if lid_sensor != null:
		lid_sensor.body_entered.connect(_on_lid_touched)


func _on_lid_touched(body: Node3D) -> void:
	var player := body as Player
	if player == null or is_open:
		return
	is_open = true
	Stage.award(self, points)
	player.say(open_words, 3.0)
	player.celebrate()
	_pop_lid()
	opened.emit()


func _pop_lid() -> void:
	if lid == null:
		return
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(lid, "position:y", lid.position.y + lid_fly_height, lid_fly_time)
	tween.tween_property(lid, "rotation:z", TAU * 2.0, lid_fly_time)
	tween.chain().tween_callback(lid.hide)
