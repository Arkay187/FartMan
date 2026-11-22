class_name MapCamera
extends Camera3D
## The map camera. It looks down at the ship from above and in front, glides after it,
## and leans a little towards the next stop so you can see where you are going.

## Who to follow (the ship).
@export var target: Node3D
## Where the camera sits compared to what it looks at: x = sideways, y = above, z = in front.
@export var offset: Vector3 = Vector3(0.0, 11.0, 16.0)
## The camera looks this far below the ship, so the stop under it is in the picture too.
@export var look_below: float = 3.5
## How far it leans towards the next stop: 0 = not at all, 1 = looks right at it.
@export_range(0.0, 1.0) var peek_amount: float = 0.25
## How quickly it catches up with the ship. Smaller = lazier.
@export var follow_speed: float = 3.0
## Which way the ship is heading (the next stop's hover spot). Set by the map.
var peek_point: Vector3 = Vector3.ZERO
var has_peek: bool = false
var _focus: Vector3 = Vector3.ZERO


func _ready() -> void:
	current = true
	snap()


## Jump straight to the right place (no gliding).
func snap() -> void:
	_focus = _wanted_focus()
	_place()


func _process(delta: float) -> void:
	_focus = _focus.lerp(_wanted_focus(), 1.0 - exp(-follow_speed * delta))
	_place()


func _wanted_focus() -> Vector3:
	if target == null:
		return _focus
	var spot: Vector3 = target.global_position
	if has_peek:
		spot = spot.lerp(peek_point, peek_amount)
	return spot + Vector3(0.0, -look_below, 0.0)


func _place() -> void:
	if not is_inside_tree():
		return
	global_position = _focus + offset
	look_at(_focus, Vector3.UP)
