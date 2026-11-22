extends Area3D
## A hoop in the sky. Fly through it for points. It changes colour once done.

## Sent when Fart Man goes through. Use this later for a "ding" sound.
signal passed

## How many points it is worth.
@export var points: int = 50
## The ring model, so it can change colour.
@export var ring: MeshInstance3D
@export var done_color: Color = Color(0.3, 0.9, 0.4)
## The ding when he flies through.
@export var ding_sound: AudioStream

var is_done: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if is_done or not (body is Player):
		return
	is_done = true
	Stage.award(self, points)
	Sfx.play(self, ding_sound)
	if ring != null:
		var paint := StandardMaterial3D.new()
		paint.albedo_color = done_color
		ring.material_override = paint
	passed.emit()
