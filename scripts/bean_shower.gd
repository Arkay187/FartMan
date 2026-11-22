class_name BeanShower
extends Node
## A shower of beans raining down over a stretch of the level. A beaten boss does this.
## It drops a few beans every frame for a couple of seconds, then tidies itself away.

## Sent when the last bean has been dropped.
signal finished

## How many beans fall in all.
@export var count: int = 44
## How many seconds the rain lasts.
@export var seconds: float = 2.0
## How high above the floor the beans start.
@export var height: float = 13.0

var _left_x: float = 0.0
var _right_x: float = 0.0
var _floor_y: float = 0.0
var _dropped: int = 0
var _time: float = 0.0
var _marker: Node3D


## Starts a shower in "parent" (the level), between left_x and right_x, above a floor at floor_y.
static func rain(parent: Node, left_x: float, right_x: float, floor_y: float, bean_count: int = 44, rain_seconds: float = 2.0) -> BeanShower:
	var shower := BeanShower.new()
	shower.count = bean_count
	shower.seconds = rain_seconds
	shower._left_x = left_x
	shower._right_x = right_x
	shower._floor_y = floor_y
	parent.add_child(shower)
	return shower


func _ready() -> void:
	# Beans are thrown "from" a spot, so we use an invisible marker that we move around.
	_marker = Node3D.new()
	get_parent().add_child.call_deferred(_marker)
	set_physics_process(false)
	_start.call_deferred()


func _start() -> void:
	set_physics_process(true)


func _physics_process(delta: float) -> void:
	if not is_instance_valid(_marker) or not _marker.is_inside_tree():
		return
	_time += delta
	# By now, this many beans should have fallen.
	var due: int = mini(count, int(ceilf(count * _time / maxf(seconds, 0.01))))
	while _dropped < due:
		_marker.global_position = Vector3(randf_range(_left_x, _right_x), _floor_y + height + randf_range(0.0, 3.0), 0.0)
		Loot.beans(_marker, 1, 0.0, 0.0)
		_dropped += 1
	if _dropped >= count:
		finished.emit()
		_marker.queue_free()
		queue_free()
