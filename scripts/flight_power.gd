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
## He can't go below or above these heights during this flight.
var lowest_y: float = 0.0
var highest_y: float = 100.0


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
	player.velocity.x = forward_speed
	player.velocity.y = move_toward(player.velocity.y, wanted, lift * delta)
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
		player.visual.rotation.z = deg_to_rad(-tilt_degrees) + player.velocity.y * 0.03
