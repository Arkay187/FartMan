class_name FlightPower
extends Node
## Fart-powered flight. Lives on Fart Man and switches on when he grabs a Rocket Burrito.
## While flying he zooms forward by himself. Hold jump to rise, let go to sink.
## Gas never runs out while flying.

## Sent when a flight starts and ends. Use these later for music and sounds.
signal started
signal ended

## How fast he zooms forward, in metres per second.
@export var forward_speed: float = 14.0
## Fastest he can climb while holding jump.
@export var rise_speed: float = 9.0
## Fastest he sinks when not holding jump.
@export var fall_speed: float = 9.0
## How quickly he swaps between rising and sinking. Bigger = snappier.
@export var lift: float = 35.0
## How far he leans forward while flying, in degrees.
@export var tilt_degrees: float = 65.0
## The rainbow gas trail behind him.
@export var trail: FlameTrail

var is_flying: bool = false
## Added up each frame by up-draught zones (metres per second per second), then used.
var updraft: float = 0.0
## He can't go below or above these heights during this flight.
var lowest_y: float = 0.0
var highest_y: float = 100.0
## Set each frame by a chimney-shaft zone: while true he does not zoom forward, he steers
## left and right with the arrow keys instead (climbing up inside a chimney).
var shaft: bool = false
## Added by speed-up zones: forward speed is multiplied by this, then it goes back to 1.
var speed_scale: float = 1.0
## The speed multiplier he actually flew with last frame (the camera reads this to widen the view).
var speed_applied: float = 1.0
## How fast he steers sideways inside a chimney shaft, in metres per second.
@export var steer_speed: float = 7.0

@export_group("Climbing a chimney")
## How long, in seconds, he takes to swing from standing upright (climbing) to flat (flying
## forward), and back. Happens when he bursts out of the top of a chimney.
@export var climb_turn_time: float = 1.0
## Angle of his body while climbing. 90 = head straight up, like a rocket taking off.
@export var climb_upright_degrees: float = 90.0
## How far he leans sideways while steering left or right in the chimney, in degrees.
@export var climb_lean_degrees: float = 12.0
## How fast he spins round to face the way he steers, in seconds for a half turn.
@export var climb_face_time: float = 0.3

## 1 = upright and climbing inside a chimney, 0 = flat and flying forward. Eases in between
## while he turns. The camera and his pose both read this.
var climb_amount: float = 0.0
## Which way he faces while climbing: true = right, false = left.
var _faces_right: bool = true
## True until the first flying frame, so a start or a respawn inside a chimney is upright at once.
var _fresh: bool = true


func start(lowest: float, highest: float) -> void:
	lowest_y = lowest
	highest_y = highest
	if is_flying:
		return
	is_flying = true
	if trail != null:
		trail.emitting = true
	started.emit()


## True while he is climbing inside a chimney (upright, steering) or still turning flat.
func is_climbing() -> bool:
	return is_flying and climb_amount > 0.0


func stop(player: Player) -> void:
	if not is_flying:
		return
	is_flying = false
	climb_amount = 0.0
	_fresh = true
	if trail != null:
		trail.emitting = false
	if player.visual != null:
		player.visual.rotation.z = 0.0
	ended.emit()


## Fart Man calls this every physics frame instead of his normal walking and jumping.
func fly(player: Player, delta: float) -> void:
	var holding: bool = Input.is_action_pressed(player.jump_action) or player.fart_held()
	var wanted: float = rise_speed if holding else -fall_speed
	if _fresh:
		_fresh = false
		# Starting (or coming back from a toilet) inside a chimney: upright straight away.
		for zone: Node in player.get_tree().get_nodes_in_group(&"chimney_shafts"):
			if (zone as ChimneyShaft).contains(player.global_position):
				shaft = true
				climb_amount = 1.0
	var in_shaft: bool = shaft
	if in_shaft:
		player.velocity.x = Input.get_axis(player.left_action, player.right_action) * steer_speed
	else:
		player.velocity.x = forward_speed * speed_scale
	shaft = false
	speed_applied = speed_scale
	speed_scale = 1.0
	player.velocity.y = move_toward(player.velocity.y, wanted, lift * delta)
	# Up-draughts shove him upwards for as long as he is inside one.
	player.velocity.y += updraft * delta
	updraft = 0.0
	player.velocity.z = 0.0
	player.move_and_slide()
	player.position.z = 0.0

	# Keep him inside the sky.
	if player.position.y < lowest_y:
		player.position.y = lowest_y
		player.velocity.y = maxf(player.velocity.y, 0.0)
	elif player.position.y > highest_y:
		player.position.y = highest_y
		player.velocity.y = minf(player.velocity.y, 0.0)

	# Upright in a chimney, turning flat once he bursts out of the top.
	climb_amount = move_toward(climb_amount, 1.0 if in_shaft else 0.0, delta / maxf(climb_turn_time, 0.01))
	if player.visual != null:
		var steer: float = clampf(player.velocity.x / maxf(steer_speed, 0.01), -1.0, 1.0) if in_shaft else 0.0
		if in_shaft and absf(steer) > 0.1:
			_faces_right = steer > 0.0
		# Face the way he steers while climbing; flat flying always faces right.
		var yaw_wanted: float = 0.0 if (_faces_right or not in_shaft) else PI
		var yaw: float = player.visual.rotation.y
		if climb_amount <= 0.0 and not in_shaft:
			player.visual.rotation.y = 0.0  # normal flying: always facing right
		else:
			player.visual.rotation.y = move_toward(yaw, yaw_wanted, PI * delta / maxf(climb_face_time, 0.01))
		# Flat flying: lean forward like a superhero, nose up when climbing and down when sinking.
		var flat_z: float = deg_to_rad(-tilt_degrees) + player.velocity.y * 0.03
		# Upright: head up, leaning a little the way he steers (mirrored when he faces left).
		var side: float = 1.0 if cos(player.visual.rotation.y) >= 0.0 else -1.0
		var up_z: float = deg_to_rad(climb_upright_degrees - steer * climb_lean_degrees * side)
		player.visual.rotation.z = lerpf(flat_z, up_z, smoothstep(0.0, 1.0, climb_amount))
