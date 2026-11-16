extends Camera3D
## Camera that follows Fart Man around the level.
## Normally it looks at him from the side. While he is flying it swings round to sit
## behind his shoulder, so flying feels like a third-person game.

## Who to follow.
@export var target: Node3D

@export_group("Walking view (side on)")
## Where the camera sits compared to him: x = ahead/behind, y = above, z = how far back.
@export var offset: Vector3 = Vector3(0.0, 3.0, 16.0)

@export_group("Flying view (behind his shoulder)")
## Where the camera sits while he is flying. Minus x = behind him, z = off to the side.
## Make z smaller to sit more directly behind, bigger to see him more from the side.
@export var flight_offset: Vector3 = Vector3(-13.0, 5.0, 9.0)
## The camera looks at a spot this far in front of him while flying.
@export var flight_look_ahead: Vector3 = Vector3(10.0, 0.0, 0.0)

@export_group("Smoothness")
## How tightly it follows. Bigger = sticks closer, smaller = lazier and smoother.
@export var follow_speed: float = 6.0
## How quickly it swings between the two views when a flight starts or ends.
@export var swing_speed: float = 2.0

## 0 = walking view, 1 = flying view, in between while swinging round.
var flying_amount: float = 0.0


func _ready() -> void:
	# Start already in the right place, no swooping in.
	if target != null:
		global_position = target.global_position + offset


func _physics_process(delta: float) -> void:
	if target == null:
		return
	var player := target as Player
	var wanted: float = 1.0 if player != null and player.is_flying() else 0.0
	flying_amount = lerpf(flying_amount, wanted, 1.0 - exp(-swing_speed * delta))

	# Move to a spot between the two views.
	var current_offset: Vector3 = offset.lerp(flight_offset, flying_amount)
	var goal: Vector3 = target.global_position + current_offset
	global_position = global_position.lerp(goal, 1.0 - exp(-follow_speed * delta))

	# Walking: look straight ahead, side on. Flying: look past him at where he is going.
	var side_on_point: Vector3 = Vector3(global_position.x, global_position.y, 0.0)
	var flying_point: Vector3 = target.global_position + flight_look_ahead
	look_at(side_on_point.lerp(flying_point, flying_amount), Vector3.UP)
