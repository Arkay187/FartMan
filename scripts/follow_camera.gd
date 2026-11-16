extends Camera3D
## Side-on camera that follows Fart Man around the level.
## It pulls right back while he is flying, to show off the landscape.

## Who to follow.
@export var target: Node3D
## Where the camera sits compared to him: x = ahead/behind, y = above, z = how far back.
@export var offset: Vector3 = Vector3(0.0, 3.0, 16.0)
## Where it sits while he is flying: further back, and looking ahead.
@export var flight_offset: Vector3 = Vector3(9.0, 1.0, 34.0)
## How tightly it follows. Bigger = sticks closer, smaller = lazier and smoother.
@export var follow_speed: float = 6.0
## How quickly it pulls back and comes in again when a flight starts or ends.
@export var zoom_speed: float = 2.0

var current_offset: Vector3


func _ready() -> void:
	# Start already in the right place, no swooping in.
	current_offset = offset
	if target != null:
		global_position = target.global_position + current_offset


func _physics_process(delta: float) -> void:
	if target == null:
		return
	var player := target as Player
	var wanted: Vector3 = flight_offset if player != null and player.is_flying() else offset
	current_offset = current_offset.lerp(wanted, 1.0 - exp(-zoom_speed * delta))
	var goal: Vector3 = target.global_position + current_offset
	global_position = global_position.lerp(goal, 1.0 - exp(-follow_speed * delta))
