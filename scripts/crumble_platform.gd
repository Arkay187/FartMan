class_name CrumblePlatform
extends StaticBody3D
## A crumbly biscuit platform. Stand on it and it shakes, then falls away.
## A few seconds later a fresh biscuit pops back.

## Seconds of shaking before it falls.
@export var crumble_delay: float = 0.6
## Seconds before it comes back.
@export var return_after: float = 3.0
## How far it drops while falling.
@export var fall_distance: float = 5.0
## How hard it shakes.
@export var shake_amount: float = 0.06
## A thin zone on top that notices him standing there.
@export var sensor: Area3D
## The picture (shakes and falls; the solid part switches off when it falls).
@export var visual: Node3D
## The solid part's shape, switched off while it is gone.
@export var shape: CollisionShape3D
## The crack when it gives way.
@export var crack_sound: AudioStream

enum State { SOLID, SHAKING, FALLEN }

var state: State = State.SOLID
var _timer: float = 0.0


func is_fallen() -> bool:
	return state == State.FALLEN


func _physics_process(delta: float) -> void:
	match state:
		State.SOLID:
			if _someone_on_top():
				state = State.SHAKING
				_timer = crumble_delay
		State.SHAKING:
			_timer -= delta
			if visual != null:
				visual.position.x = sin(_timer * 80.0) * shake_amount
			if _timer <= 0.0:
				state = State.FALLEN
				_timer = return_after
				Sfx.play(self, crack_sound)
				if shape != null:
					shape.set_deferred("disabled", true)
		State.FALLEN:
			_timer -= delta
			if visual != null:
				var drop_time: float = minf(return_after, 1.0)
				var fell: float = clampf((return_after - _timer) / drop_time, 0.0, 1.0)
				visual.position = Vector3(0.0, -fall_distance * fell * fell, 0.0)
				visual.visible = fell < 1.0
			if _timer <= 0.0:
				_come_back()


func _someone_on_top() -> bool:
	if sensor == null:
		return false
	for body: Node3D in sensor.get_overlapping_bodies():
		var player := body as Player
		if player != null and not player.is_flying() and player.velocity.y <= 1.0:
			return true
	return false


func _come_back() -> void:
	state = State.SOLID
	if shape != null:
		shape.set_deferred("disabled", false)
	if visual != null:
		visual.position = Vector3.ZERO
		visual.visible = true
