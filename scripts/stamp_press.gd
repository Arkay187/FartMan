class_name StampPress
extends Node3D
## A stamping press: a heavy block that slams down on a beat.
## 1) it waits up high, 2) it shakes and a shadow grows on the floor (WARNING!),
## 3) it SLAMS down (this is the only moment it hurts), 4) it rests, 5) it rises.
## It is always safe to stand on top of it. The origin of this node is the floor.

## The block (solid, so you can stand on it).
@export var block: AnimatableBody3D
## The box that hurts, just under the block.
@export var hurt_zone: Area3D
## The picture of the block, so it can shake without shaking the solid part.
@export var visual: Node3D
## The dark patch on the floor that warns you.
@export var shadow: Node3D
## How tall the block is.
@export var thickness: float = 1.2
## How high the gap under the raised block is. He is 2 m tall.
@export var drop: float = 3.4
## Seconds it waits up high.
@export var wait_time: float = 1.6
## Seconds of shaking before the slam.
@export var warn_time: float = 0.6
## How fast it slams down, and how fast it rises again.
@export var slam_speed: float = 22.0
@export var rise_speed: float = 4.0
## Seconds it stays down.
@export var down_time: float = 0.5
## Where in the beat it starts (0 to 1), so presses next to each other go out of step.
@export var phase: float = 0.0

enum State { WAIT, WARN, SLAM, DOWN, RISE }

var state: State = State.WAIT
var _timer: float = 0.0
var _y: float = 0.0


func _ready() -> void:
	if block != null:
		block.sync_to_physics = true
	_y = _top_y()
	_timer = wait_time * (1.0 - phase)
	_apply()


## True only while the block is coming down or lying on the floor.
func is_dangerous() -> bool:
	return state == State.SLAM or state == State.DOWN


func _top_y() -> float:
	return thickness * 0.5 + drop


func _bottom_y() -> float:
	return thickness * 0.5


func _physics_process(delta: float) -> void:
	_timer -= delta
	match state:
		State.WAIT:
			if _timer <= 0.0:
				state = State.WARN
				_timer = warn_time
		State.WARN:
			if _timer <= 0.0:
				state = State.SLAM
		State.SLAM:
			_y = maxf(_y - slam_speed * delta, _bottom_y())
			if _y <= _bottom_y():
				state = State.DOWN
				_timer = down_time
		State.DOWN:
			if _timer <= 0.0:
				state = State.RISE
		State.RISE:
			_y = minf(_y + rise_speed * delta, _top_y())
			if _y >= _top_y():
				state = State.WAIT
				_timer = wait_time
	_apply()
	if is_dangerous() and hurt_zone != null:
		for body: Node3D in hurt_zone.get_overlapping_bodies():
			var player := body as Player
			if player != null:
				player.hurt(global_position.x)


func _apply() -> void:
	if block != null:
		block.position.y = _y
	if visual != null:
		# Shake while warning.
		var shake: float = sin(_timer * 90.0) * 0.07 if state == State.WARN else 0.0
		visual.position.x = shake
	if shadow != null:
		var warning: bool = state == State.WARN
		shadow.visible = warning or is_dangerous()
		var grow: float = 1.0 - clampf(_timer / maxf(warn_time, 0.01), 0.0, 1.0)
		shadow.scale = Vector3(0.4 + 0.6 * grow, 1.0, 1.0) if warning else Vector3.ONE
