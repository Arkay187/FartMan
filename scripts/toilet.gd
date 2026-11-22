class_name Toilet
extends Area3D
## A toilet checkpoint. Run past it and it flushes.
## After that, this is where Fart Man comes back if things go wrong.

## Sent when it flushes. Use this later for the flush sound.
signal flushed

## What the toilet says when it flushes. Leave empty for nothing.
@export var flush_words: String = "FLUSH!"
## How far above the toilet's base he reappears.
@export var respawn_height: float = 1.5
## The toilet model. It turns this colour once flushed, so you can tell it is used.
@export var visual: Node3D
## For a toilet floating in a flying stage: the lowest and highest height of the flight.
## He comes back flying. Leave at (0, 0) for a normal toilet.
@export var flight_range: Vector2 = Vector2.ZERO
@export var flushed_color: Color = Color(0.45, 0.75, 1.0)
## The flush.
@export var flush_sound: AudioStream

var is_flushed: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	var player := body as Player
	if player == null or is_flushed:
		return
	is_flushed = true
	player.set_checkpoint(global_position + Vector3.UP * respawn_height, flight_range)
	Stage.bank(self)  # the beans he is carrying go safely into the Bean Jar
	_show_flushed()
	SpeechBubble.say(self, flush_words, 1.5, 2.6)
	Sfx.play(self, flush_sound)
	flushed.emit()


func _show_flushed() -> void:
	if visual == null:
		return
	var paint := StandardMaterial3D.new()
	paint.albedo_color = flushed_color
	for part: Node in visual.get_children():
		if part is MeshInstance3D:
			(part as MeshInstance3D).material_override = paint
	# A little wobble.
	var tween: Tween = create_tween()
	tween.tween_property(visual, "scale", Vector3(1.2, 0.8, 1.2), 0.1)
	tween.tween_property(visual, "scale", Vector3.ONE, 0.2)
