class_name FartHover
extends Node
## Fart hover for the SIMPLE controls. Lives as a child of the Player.
## Hold the HOVER button (Left Shift / X / left bumper) in the air and he floats on a fart cloud,
## like a hover pack. It uses gas. The cloud under his feet squashes enemies.

## Sent when the hover starts and stops.
signal started
signal stopped

## Rising slower than this (m/s) counts as "done jumping": then the hover takes hold.
## 0 = he floats level. A bit above 0 = he drifts slowly upwards.
@export var hover_rise_speed: float = 0.0
## How hard the hover pushes his up/down speed towards the hover speed (m/s per second).
@export var hover_lift: float = 60.0
## Gas used each second while hovering. 25 means a full tank lasts 4 seconds.
@export var hover_gas_per_second: float = 25.0
## In the NO GAS / ALWAYS FULL test modes: how many seconds of hover per time in the air.
@export var hover_time_free_gas: float = 3.0

var is_hovering: bool = false
var cloud: HoverCloud
var _player: Player
var _free_time_left: float = 0.0
## Out of gas: no more hover until he lets go or lands.
var _spent: bool = false


func _ready() -> void:
	_player = get_parent() as Player
	_free_time_left = hover_time_free_gas
	cloud = HoverCloud.new()
	cloud.name = "HoverCloud"
	# The Player is still busy setting up its children, so add the cloud a moment later.
	_player.add_child.call_deferred(cloud)
	# Run after the player has moved, to tidy up if the hover has to stop.
	process_physics_priority = 10


## Called by the Player every physics frame, before it moves.
func update(delta: float) -> void:
	if _player == null:
		return
	var p: Player = _player
	if p.is_on_floor():
		_free_time_left = hover_time_free_gas
		_spent = false
		_stop()
		return
	if not Input.is_action_pressed(&"hover"):
		_spent = false
		_stop()
		return
	if _spent:
		return
	if p.velocity.y > hover_rise_speed:
		# Still going up from the jump: hold on, the hover takes over at the top.
		_stop()
		return
	if not _pay(delta):
		_spent = true
		_stop()
		p.fizzled.emit()
		if p.print_farts:
			print("Pfft...")
		return
	p.velocity.y = move_toward(p.velocity.y, hover_rise_speed, hover_lift * delta)
	_start()


## Uses a little gas (or a little of the free time). False when there is none left.
func _pay(delta: float) -> bool:
	var tank: GasTank = _player.gas_tank
	if tank == null:
		return true
	var options := get_node_or_null("/root/DebugOptions") as DebugOptionsData
	if options != null and options.farts_are_free():
		_free_time_left -= delta
		return _free_time_left > 0.0
	if tank.gas <= 0.0:
		return false
	tank.drain(hover_gas_per_second * delta)
	return true


func _start() -> void:
	if is_hovering:
		return
	is_hovering = true
	if cloud != null:
		cloud.set_active(true)
	started.emit()
	_player.hover_started.emit()


func _stop() -> void:
	if not is_hovering:
		return
	is_hovering = false
	if cloud != null:
		cloud.set_active(false)
	stopped.emit()
	_player.hover_stopped.emit()


## Safety net after the player has moved: stop if anything took over.
func _physics_process(_delta: float) -> void:
	if not is_hovering:
		return
	if not _player.is_simple() or _player.is_flying() or _player.frozen or _player.is_dying \
			or _player.input_locked or _player.is_on_floor():
		_stop()
