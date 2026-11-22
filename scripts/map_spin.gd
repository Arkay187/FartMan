class_name MapSpin
extends Node3D
## Spins a thing round and round: the ship's propeller, the swirly rings of Planet Whiff,
## the ring of Golden Beans over a stop.

## Turning speed round each axis (x, y, z), in degrees per second.
@export var degrees_per_second: Vector3 = Vector3(0.0, 90.0, 0.0)


func _process(delta: float) -> void:
	rotation_degrees += degrees_per_second * delta
