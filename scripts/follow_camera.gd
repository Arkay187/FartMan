extends Camera3D
## Side-on camera that follows Fart Man around the level.

## Who to follow.
@export var target: Node3D
## Where the camera sits compared to him: x = ahead/behind, y = above, z = how far back.
@export var offset: Vector3 = Vector3(0.0, 3.0, 16.0)
## How tightly it follows. Bigger = sticks closer, smaller = lazier and smoother.
@export var follow_speed: float = 6.0


func _ready() -> void:
	# Start already in the right place, no swooping in.
	if target != null:
		global_position = target.global_position + offset


func _physics_process(delta: float) -> void:
	if target == null:
		return
	var goal: Vector3 = target.global_position + offset
	global_position = global_position.lerp(goal, 1.0 - exp(-follow_speed * delta))
