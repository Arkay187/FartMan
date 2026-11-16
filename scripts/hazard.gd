class_name Hazard
extends Area3D
## Something that hurts to touch and can't be squashed, like a spiky ball.
## Fart Man loses a heart and bounces off. Jump or fly around it.


func _physics_process(_delta: float) -> void:
	for body: Node3D in get_overlapping_bodies():
		var player := body as Player
		if player != null:
			# hurt() already ignores this while he is blinking or chilli-hot.
			player.hurt(global_position.x)
