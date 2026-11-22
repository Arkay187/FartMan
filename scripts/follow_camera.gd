extends Camera3D
## Camera that follows Fart Man around the level.
## Normally it looks at him from the side, far enough out to see what's coming (he is
## about 1/9 of the screen tall). While he is flying it swings round to sit behind his
## shoulder, so flying feels like a third-person game.

## Who to follow.
@export var target: Node3D

@export_group("Walking view (side on)")
## Where the camera sits compared to him: x = ahead/behind, y = above, z = how far back.
@export var offset: Vector3 = Vector3(0.0, 3.5, 16.0)
## How zoomed in it is: the view angle, top to bottom, in degrees. Smaller = he looks bigger.
## 60 makes him about 1/9 of the screen tall and shows about 16 m ahead of him.
## (34 = Mario Wonder size, 1/5 of the screen, but you can't see obstacles coming.)
@export_range(10.0, 90.0) var walk_fov: float = 60.0
## Keeps all of him on screen during big jumps and drops: this many metres above and
## below his middle always stay in view (he is 2 m tall).
@export var keep_in_view: float = 1.5
## When it also shows someone else (a boss), the room left round the edges, in metres.
@export var show_too_margin: float = 3.0

@export_group("Climbing and falling (tall levels)")
## How much the view leans the way he is going up or down: metres of lean for every
## metre per second of speed. 0 = off, like the normal worlds. Tall levels use about 0.35,
## so there is more room to see what is above when climbing, and below when falling.
@export var vertical_look_ahead: float = 0.0
## The most the view ever leans up or down, in metres.
@export var vertical_look_max: float = 5.0
## How smoothly the lean changes. Smaller = lazier.
@export var vertical_look_smooth: float = 3.0
## The same lean, but only while he climbs up inside a chimney (side on view). It looks up
## ahead so he can see what is coming above. 0 = no lean.
@export var climbing_look_ahead: float = 0.5

@export_group("Flying view (behind his shoulder)")
## Where the camera sits while he is flying. Minus x = behind him, z = off to the side.
## Make z smaller to sit more directly behind, bigger to see him more from the side.
@export var flight_offset: Vector3 = Vector3(-17.0, 6.0, 10.0)
## The camera looks at a spot this far in front of him while flying.
@export var flight_look_ahead: Vector3 = Vector3(10.0, 0.0, 0.0)
## View angle while flying, wider so he can see the hoops coming.
@export_range(10.0, 90.0) var flight_fov: float = 75.0

@export_group("Smoothness")
## How tightly it follows. Bigger = sticks closer, smaller = lazier and smoother.
@export var follow_speed: float = 6.0
## How quickly it swings between the two views when a flight starts or ends.
@export var swing_speed: float = 2.0

## 0 = walking view, 1 = flying view, in between while swinging round.
var flying_amount: float = 0.0
## Things to keep in the shot as well as him, like a boss. It zooms out to fit them.
var also_show: Array[Node3D] = []
## The lean up (plus) or down (minus) at the moment, in metres.
var vertical_lean: float = 0.0


func _ready() -> void:
	fov = walk_fov
	# Start already in the right place, no swooping in.
	if target != null:
		global_position = target.global_position + offset


## Keep this in the shot too (a boss calls this when the fight starts).
func show_too(thing: Node3D) -> void:
	if not also_show.has(thing):
		also_show.append(thing)


func stop_showing(thing: Node3D) -> void:
	also_show.erase(thing)


func _physics_process(delta: float) -> void:
	if target == null:
		return
	var player := target as Player
	# Flying view, except while climbing a chimney: then it stays side on, and swings round
	# as he turns flat and bursts out of the top.
	var wanted: float = 0.0
	var climbing: bool = false
	if player != null and player.is_flying():
		var climb: float = player.flight.climb_amount
		wanted = 1.0 - climb
		climbing = climb > 0.5
	flying_amount = lerpf(flying_amount, wanted, 1.0 - exp(-swing_speed * delta))
	var smooth: float = 1.0 - exp(-follow_speed * delta)

	# Walking: aim at him (or between him and a boss), and zoom out if they don't both fit.
	var aim: Vector3 = target.global_position
	var walk_angle: float = walk_fov
	var left: float = aim.x
	var right: float = aim.x
	for thing: Node3D in also_show:
		if is_instance_valid(thing) and thing.is_inside_tree():
			left = minf(left, thing.global_position.x)
			right = maxf(right, thing.global_position.x)
	if right > left:
		aim.x = (left + right) * 0.5
		var half_height: float = ((right - left) * 0.5 + show_too_margin) / _aspect()
		walk_angle = maxf(walk_fov, rad_to_deg(2.0 * atan(half_height / offset.z)))
	fov = lerpf(fov, lerpf(walk_angle, flight_fov, flying_amount), smooth)

	# Move to a spot between the two views. When zoomed out it sits higher too, so the
	# ground stays near the bottom of the screen instead of filling half of it.
	var zoom: float = tan(deg_to_rad(fov) * 0.5) / tan(deg_to_rad(walk_fov) * 0.5)
	var walk_offset := Vector3(offset.x, offset.y * zoom, offset.z)
	var current_offset: Vector3 = walk_offset.lerp(flight_offset, flying_amount)
	var goal: Vector3 = aim.lerp(target.global_position, flying_amount) + current_offset
	var look: float = maxf(vertical_look_ahead, climbing_look_ahead) if climbing else vertical_look_ahead
	var lean_goal: float = 0.0
	if look > 0.0 and flying_amount < 0.5:
		var speed_y: float = (target as CharacterBody3D).velocity.y if target is CharacterBody3D else 0.0
		lean_goal = clampf(speed_y * look, -vertical_look_max, vertical_look_max)
	if lean_goal != 0.0 or absf(vertical_lean) > 0.001:
		vertical_lean = lerpf(vertical_lean, lean_goal, 1.0 - exp(-vertical_look_smooth * delta))
		goal.y += vertical_lean
	global_position = global_position.lerp(goal, smooth)
	if flying_amount < 0.05:
		_keep_him_in_view()

	# Walking: look straight ahead, side on. Flying: look past him at where he is going.
	var side_on_point: Vector3 = Vector3(global_position.x, global_position.y, 0.0)
	var flying_point: Vector3 = target.global_position + flight_look_ahead
	look_at(side_on_point.lerp(flying_point, flying_amount), Vector3.UP)


## Big jumps and drops: slide up or down so his head and feet never leave the screen.
func _keep_him_in_view() -> void:
	var distance: float = global_position.z - target.global_position.z
	var half_height: float = tan(deg_to_rad(fov) * 0.5) * distance
	var room: float = maxf(half_height - keep_in_view, 0.0)
	var y: float = target.global_position.y
	global_position.y = clampf(global_position.y, y - room, y + room)


## Screen width divided by height (16:9 is about 1.78).
func _aspect() -> float:
	var size: Vector2 = get_viewport().get_visible_rect().size
	return size.x / size.y if size.y > 0.0 else 16.0 / 9.0
