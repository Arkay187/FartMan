class_name MapShip
extends Node3D
## Fart Man's ship on the world map: the Bean Blimp. The ship's own position is the
## hover spot (smooth, no wobble). Everything you see sits on the "Rig" under it, which
## bobs and sways. Flying leans the ship into the move and turns it to face the way it goes.

## Sent when the ship has settled above a stop after fly_to().
signal landed
## Sent when Fart Man has jumped out and fallen out of sight.
signal dropped

## Everything you see (the bean, gondola, propeller), so it can bob without moving the ship.
@export var rig: Node3D
## Fart Man in his gondola.
@export var pilot: Node3D
@export_group("Hovering")
## How far it bobs up and down, in metres, and how fast.
@export var bob_height: float = 0.3
@export var bob_speed: float = 1.7
## How far it rocks from side to side, in degrees, and how fast.
@export var sway_degrees: float = 3.0
@export var sway_speed: float = 1.1
@export_group("Flying")
## How high it rises in the middle of a flight, in metres.
@export var arc_height: float = 1.5
## How far it leans into a sideways move and nose up/down on a climb, in degrees.
@export var bank_degrees: float = 20.0
@export var pitch_degrees: float = 12.0
## How quickly it swings round to face the way it is going.
@export var turn_speed: float = 4.0
@export_group("Dropping in")
## How far the ship dips when Fart Man jumps out, in metres.
@export var dip_depth: float = 1.0
## How high he hops out of the gondola, and how far he then falls, in metres.
@export var hop_height: float = 1.4
@export var fall_distance: float = 8.0
## How long the hop and the fall take, in seconds.
@export var hop_time: float = 0.3
@export var fall_time: float = 0.5

## True while the ship is on its way between stops.
var is_flying: bool = false
## True from the moment Fart Man jumps until the map leaves.
var is_dropping: bool = false
## How far the rig is dipped down right now (used by the drop animation).
var dip: float = 0.0

var _time: float = 0.0
var _from: Vector3 = Vector3.ZERO
var _to: Vector3 = Vector3.ZERO
var _tween: Tween
var _yaw: float = 0.0
var _target_yaw: float = 0.0
var _last_position: Vector3 = Vector3.ZERO
var _velocity: Vector3 = Vector3.ZERO
var _pilot_rest: Vector3 = Vector3.ZERO


func _ready() -> void:
	_last_position = position
	if pilot != null:
		_pilot_rest = pilot.position


## Put the ship right above a spot (no flying).
func snap_to(spot: Vector3) -> void:
	position = spot
	_last_position = spot
	_velocity = Vector3.ZERO


## Fly smoothly to a spot (slow, then fast, then slow again) and settle there.
func fly_to(spot: Vector3, time: float) -> void:
	if _tween != null:
		_tween.kill()
	_from = position
	_to = spot
	is_flying = true
	_tween = create_tween()
	_tween.tween_method(_fly_step, 0.0, 1.0, time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_callback(_land)


## Fart Man jumps out of the gondola and drops down to the stop. The ship dips as he leaves.
func drop_pilot() -> void:
	if is_dropping or pilot == null:
		return
	is_dropping = true
	var dip_tween: Tween = create_tween()
	dip_tween.tween_property(self, "dip", dip_depth, hop_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	var hop: Tween = create_tween()
	hop.tween_property(pilot, "position:y", _pilot_rest.y + hop_height, hop_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	hop.tween_property(pilot, "position:y", _pilot_rest.y - fall_distance, fall_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	hop.tween_callback(_finish_drop)


func _fly_step(progress: float) -> void:
	position = _from.lerp(_to, progress) + Vector3.UP * sin(progress * PI) * arc_height


func _land() -> void:
	position = _to
	is_flying = false
	landed.emit()


func _finish_drop() -> void:
	pilot.visible = false
	dropped.emit()


func _process(delta: float) -> void:
	_time += delta
	if delta > 0.0:
		var speed: Vector3 = (position - _last_position) / delta
		_velocity = _velocity.lerp(speed, 1.0 - exp(-8.0 * delta))
	_last_position = position
	# Face the way it is flying (the bean is seen from the side).
	if absf(_velocity.x) > 0.5:
		_target_yaw = 0.0 if _velocity.x > 0.0 else PI
	_yaw = lerp_angle(_yaw, _target_yaw, 1.0 - exp(-turn_speed * delta))
	# Lean into the sideways move and nose up when climbing.
	var roll: float = clampf(_velocity.z * 0.08, -1.0, 1.0) * deg_to_rad(bank_degrees) * cos(_yaw)
	var pitch: float = clampf(_velocity.y * 0.08, -1.0, 1.0) * deg_to_rad(pitch_degrees)
	basis = Basis(Vector3.UP, _yaw) * Basis(Vector3.RIGHT, roll) * Basis(Vector3.BACK, pitch)
	# Gentle bobbing and swaying on the rig.
	if rig != null:
		rig.position = Vector3(0.0, sin(_time * bob_speed) * bob_height - dip, 0.0)
		rig.rotation_degrees = Vector3(sin(_time * sway_speed * 1.3) * sway_degrees * 0.6, 0.0, sin(_time * sway_speed) * sway_degrees)
