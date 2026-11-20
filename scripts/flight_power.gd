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
## How fast he steers sideways inside a chimney shaft, in metres per second.
@export var steer_speed: float = 7.0


func start(lowest: float, highest: float) -> void:
	lowest_y = lowest
	highest_y = highest
	if is_flying:
		return
	is_flying = true
	if trail != null:
		trail.emitting = true
	started.emit()


func stop(player: Player) -> void:
	if not is_flying:
		return
	is_flying = false
	if trail != null:
		trail.emitting = false
	if player.visual != null:
		player.visual.rotation.z = 0.0
	ended.emit()


## Fart Man calls this every physics frame instead of his normal walking and jumping.
func fly(player: Player, delta: float) -> void:
	var holding: bool = Input.is_action_pressed(player.jump_action) or Input.is_action_pressed(player.fart_action)
	var wanted: float = rise_speed if holding else -fall_speed
	var in_shaft: bool = shaft
	if in_shaft:
		player.velocity.x = Input.get_axis(player.left_action, player.right_action) * steer_speed
	else:
		player.velocity.x = forward_speed * speed_scale
	shaft = false
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

	# Lean forward like a superhero, nose up when climbing and down when sinking.
	if player.visual != null:
		player.visual.rotation.y = 0.0
		# Inside a chimney he flies nearly upright, like a rocket.
		var lean: float = tilt_degrees * (0.2 if in_shaft else 1.0)
		player.visual.rotation.z = deg_to_rad(-lean) + player.velocity.y * 0.03
