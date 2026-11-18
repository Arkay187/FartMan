class_name ModelTurn
extends Node3D
## Holds Fart Man's 3D model and turns it to face the way he is running,
## angled a little toward the camera so we can see his face.
## The model file faces the camera; the game's "facing right" is along +X.

## How far to turn him toward the camera, in degrees. 0 = fully side on.
@export var turn_degrees: float = 30.0


func _process(_delta: float) -> void:
	face(_parent_faces_right())


## Snaps the model to face right (true) or left (false).
func face(right: bool) -> void:
	var turn: float = deg_to_rad(turn_degrees)
	rotation.y = PI / 2.0 - turn if right else PI / 2.0 + turn


## The Visual node above spins 180 degrees when he runs left.
func _parent_faces_right() -> bool:
	var parent := get_parent() as Node3D
	return parent == null or cos(parent.rotation.y) > 0.0
