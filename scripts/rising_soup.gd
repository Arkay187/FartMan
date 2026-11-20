class_name RisingSoup
extends Node3D
## Hot bean soup that slowly rises from below. Stay above it!
## It stops rising for a while every time Fart Man flushes a toilet, so there is always a
## breather. If it catches him he loses a heart and is popped back to the last toilet (or
## the start), and the soup drops down below him to give him time.
##
## The mesh child should have its TOP at this node's origin (the soup surface).

## Sent when the soup catches him.
signal caught_him

## Where the surface starts (height in metres).
@export var start_y: float = -7.0
## How fast it rises, in metres per second. Fart Man climbs much faster than this.
@export var rise_speed: float = 0.8
## How long to wait at the start before it begins to rise, in seconds.
@export var start_delay: float = 8.0
## How long it stops rising after he flushes a toilet, in seconds.
@export var pause_after_toilet: float = 10.0
## After catching him, the soup drops to this far below his new spot.
@export var drop_below_checkpoint: float = 5.0
## The soup never rises above this height (so it can't flood the top).
@export var max_y: float = 1000.0
## The soup surface wobbles a little, this many metres.
@export var wobble: float = 0.15

var surface_y: float = 0.0
var _wait_left: float = 0.0
var _player: Player
var _time: float = 0.0


func _ready() -> void:
	surface_y = start_y
	_wait_left = start_delay
	position.y = surface_y
	# Listen for every toilet in the level.
	# The level is the scene this soup was placed in.
	var top: Node = owner if owner != null else get_tree().current_scene
	if top != null:
		for toilet: Node in top.find_children("*", "Toilet", true, false):
			(toilet as Toilet).flushed.connect(_on_toilet_flushed)


func _physics_process(delta: float) -> void:
	_time += delta
	if _player == null or not is_instance_valid(_player):
		var found: Node = get_tree().get_first_node_in_group(&"player")
		_player = found as Player
		if _player != null:
			_player.respawned.connect(_drop_below_him)
	# Wait, then rise.
	if _wait_left > 0.0:
		_wait_left -= delta
	elif surface_y < max_y:
		surface_y = minf(surface_y + rise_speed * delta, max_y)
	# Follow him sideways so the soup is always wide enough to fill the screen.
	if _player != null:
		position.x = _player.global_position.x
	position.y = surface_y + sin(_time * 2.0) * wobble
	if _player != null:
		_check_player()


func _check_player() -> void:
	if _player.is_dying or _player.frozen:
		return
	if _player.get_feet_y() >= surface_y:
		return
	# Caught! Lose a heart (if he is not blinking), then back to safety.
	_player.hurt(_player.global_position.x, false)
	if _player.is_dying:
		return  # that was his last heart: the usual "lie down, then pop back" takes over
	_player.global_position = _player.checkpoint_position
	_player.velocity = Vector3.ZERO
	_drop_below_him()
	caught_him.emit()


## Lowers the soup to a safe depth under his checkpoint, with a short rest.
func _drop_below_him() -> void:
	if _player == null:
		return
	surface_y = _player.checkpoint_position.y - drop_below_checkpoint
	position.y = surface_y
	_wait_left = maxf(_wait_left, pause_after_toilet * 0.5)


func _on_toilet_flushed() -> void:
	_wait_left = maxf(_wait_left, pause_after_toilet)
