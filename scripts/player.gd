extends CharacterBody3D
## Fart Man himself. Walks left and right and does a normal jump.
## The fart charge jump comes later and will replace the simple jump.

## How fast he walks, in metres per second.
@export var move_speed: float = 6.0
## How quickly he gets up to speed on the ground. Bigger = snappier.
@export var ground_acceleration: float = 60.0
## How quickly he can change direction in the air. Smaller = floatier.
@export var air_acceleration: float = 25.0
## How hard he pushes off the ground when jumping.
@export var jump_velocity: float = 9.0
## How strongly he is pulled down.
@export var gravity: float = 25.0

## Keys used. These are built into Godot: arrow keys and Space.
@export var left_action: StringName = &"ui_left"
@export var right_action: StringName = &"ui_right"
@export var jump_action: StringName = &"ui_accept"


func _physics_process(delta: float) -> void:
	# Fall when in the air.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Jump only when standing on something.
	if is_on_floor() and Input.is_action_just_pressed(jump_action):
		velocity.y = jump_velocity

	# Left / right. direction is -1, 0 or 1.
	var direction: float = Input.get_axis(left_action, right_action)
	var acceleration: float = ground_acceleration if is_on_floor() else air_acceleration
	velocity.x = move_toward(velocity.x, direction * move_speed, acceleration * delta)

	# 2.5D: never move towards or away from the camera.
	velocity.z = 0.0
	move_and_slide()
	position.z = 0.0
