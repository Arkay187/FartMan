class_name CorkBot
extends Burpling
## A Cork Bot: a rolling cork on wheels that zooms along the floor.
## Faster than a Burpling. Stomp it from above, or hop over it.

## The cork that spins as it rolls (the eyes stay still).
@export var roller: Node3D
## How big the cork is, so the spin matches the speed.
@export var roll_radius: float = 0.5


func _move(delta: float) -> void:
	super._move(delta)
	if roller != null:
		roller.rotation.z -= walk_speed * direction * delta / roll_radius
