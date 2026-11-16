class_name UpDraft
extends Area3D
## A warm up-draught in a flying stage. Fly into it and you get shoved upwards.

## How hard it shoves, in metres per second per second.
@export var strength: float = 55.0


func _physics_process(_delta: float) -> void:
	for body: Node3D in get_overlapping_bodies():
		var player := body as Player
		if player != null and player.is_flying():
			player.flight.updraft = strength
