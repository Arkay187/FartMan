class_name LootBounce
extends Node
## Makes a thrown pickup (its parent) fly up, fall, bounce once and settle on the ground.
## Loot adds this for you. It can't be picked up for a moment at first, so beans he spills
## don't jump straight back into him.

## Starting speed, in metres per second (set by Loot).
var velocity: Vector3 = Vector3.ZERO
## More than 0 = blink and vanish after this many seconds. 0 = stay forever.
var lifetime: float = 0.0

## How hard it falls.
@export var gravity: float = 22.0
## How much speed is kept after bouncing off the floor (0 = no bounce).
@export var bounce_keep: float = 0.35
## Can't be picked up for this long after being thrown.
@export var pickup_delay: float = 0.5
## It blinks for this long before vanishing.
@export var blink_time: float = 1.5
## How high above the floor it rests (beans are about 0.7 m tall).
@export var rest_height: float = 0.45

var _age: float = 0.0
var _settled: bool = false
var _item: Node3D


func _ready() -> void:
	_item = get_parent() as Node3D
	_set_collectable(false)


func _physics_process(delta: float) -> void:
	if _item == null:
		return
	_age += delta
	if _age >= pickup_delay:
		_set_collectable(true)
	if lifetime > 0.0:
		var left: float = lifetime - _age
		if left <= 0.0:
			_item.queue_free()
			return
		if left < blink_time:
			_item.visible = fmod(left, 0.2) > 0.1
	if not _settled:
		_fly(delta)


## One step of flying: fall, and stop or bounce on whatever it hits.
func _fly(delta: float) -> void:
	velocity.y -= gravity * delta
	var start: Vector3 = _item.global_position
	var step: Vector3 = velocity * delta
	var space := _item.get_world_3d().direct_space_state
	# Look a little past the step, from its middle to its bottom.
	var reach := Vector3(step.x, step.y - (rest_height if velocity.y < 0.0 else 0.0), 0.0)
	var ask := PhysicsRayQueryParameters3D.create(start, start + reach, 1)
	ask.exclude = _players()
	var hit: Dictionary = space.intersect_ray(ask)
	if hit.is_empty():
		_item.global_position = Vector3(start.x + step.x, start.y + step.y, 0.0)
		# Fell out of the world: tidy up.
		if _item.global_position.y < -60.0:
			_item.queue_free()
		return
	var normal: Vector3 = hit["normal"]
	var point: Vector3 = hit["position"]
	if normal.y > 0.6:
		# The floor: bounce once, then rest on it.
		_item.global_position = Vector3(point.x, point.y + rest_height, 0.0)
		if absf(velocity.y) > 3.0 and bounce_keep > 0.0:
			velocity = Vector3(velocity.x * 0.6, -velocity.y * bounce_keep, 0.0)
		else:
			velocity = Vector3.ZERO
			_settled = true
	else:
		# A wall or ceiling: stop going that way.
		if absf(normal.x) > 0.5:
			velocity.x = -velocity.x * 0.3
		if normal.y < -0.5:
			velocity.y = minf(velocity.y, 0.0)


func _players() -> Array[RID]:
	var rids: Array[RID] = []
	for body: Node in _item.get_tree().get_nodes_in_group(&"player"):
		if body is CollisionObject3D:
			rids.append((body as CollisionObject3D).get_rid())
	return rids


func _set_collectable(on: bool) -> void:
	var area := _item as Area3D
	if area != null and area.monitoring != on:
		area.set_deferred("monitoring", on)


## True once it has landed and stopped.
func is_settled() -> bool:
	return _settled
