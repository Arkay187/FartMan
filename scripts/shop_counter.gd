class_name ShopCounter
extends Area3D
## A shop counter aboard the Complex2000. Walk up, press jump (or up) and Grandma pops up
## from behind it and the shop opens. A bouncing arrow shows him where to press.
## It runs BEFORE the player each frame and locks the player the same frame, so in the SIMPLE
## controls the jump that opens the shop does not also make him hop.

## Sent when the shop opens and when it closes again.
signal opened(room_id: String)
signal closed(room_id: String)

## Which room this counter sells for: kitchen, gym, lab or garage (see upgrade_table.gd).
@export var room_id: String = "kitchen"
## Grandma, hiding behind the counter.
@export var grandma: Grandma
## The shop that opens (one for the whole ship).
@export var panel: ShopPanel
## The bouncing "press jump" picture over the counter.
@export var hint: Node3D
## Any of these buttons opens the shop.
@export var open_actions: Array[StringName] = [&"jump", &"ui_up"]
## What Grandma says when she pops up, and for how long.
@export var greeting: String = "OOOH!"
@export var greeting_seconds: float = 1.4
## After the shop closes, wait this long before he can move again (so the button that closed it
## does nothing else), in seconds.
@export var unlock_delay: float = 0.25
## How far the hint bounces, in metres, and how fast.
@export var hint_bounce: float = 0.25
@export var hint_speed: float = 6.0

## The player standing at the counter, or null.
var player: Player
var is_open: bool = false
var _hint_base_y: float = 0.0
var _time: float = 0.0
var _cooldown: float = 0.0
## Counts down after the shop closes; at zero the player is let go. Negative = nothing to do.
var _unlock_left: float = -1.0
var _locked_player: Player


func _init() -> void:
	# Lower numbers run first: before the player, so we can lock him before he reads the button.
	process_physics_priority = -10


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	if hint != null:
		_hint_base_y = hint.position.y
		hint.visible = false


func _physics_process(delta: float) -> void:
	_time += delta
	_cooldown = maxf(_cooldown - delta, 0.0)
	if _unlock_left >= 0.0:
		_unlock_left -= delta
		if _unlock_left < 0.0 and is_instance_valid(_locked_player) and not is_open:
			_locked_player.input_locked = false
	if hint != null:
		hint.visible = player != null and not is_open
		hint.position.y = _hint_base_y + absf(sin(_time * hint_speed)) * hint_bounce
	if player == null or is_open or _cooldown > 0.0 or panel == null or panel.is_open:
		return
	if player.input_locked or not player.is_on_floor():
		return
	for action: StringName in open_actions:
		if Input.is_action_just_pressed(action):
			open()
			return


## Opens the shop: lock the player, pop Grandma up, show the panel.
func open() -> void:
	if is_open or player == null or panel == null:
		return
	is_open = true
	_unlock_left = -1.0
	_locked_player = player
	player.input_locked = true
	player.velocity.x = 0.0
	if grandma != null:
		grandma.pop_up()
		SpeechBubble.say(grandma, greeting, greeting_seconds, 3.0)
	panel.closed.connect(_on_panel_closed, CONNECT_ONE_SHOT)
	panel.open_room(room_id)
	opened.emit(room_id)


func _on_panel_closed() -> void:
	is_open = false
	_cooldown = unlock_delay + 0.1
	if grandma != null:
		grandma.duck()
	closed.emit(room_id)
	# Let him walk again a moment later (see _physics_process).
	_unlock_left = unlock_delay


func _on_body_entered(body: Node3D) -> void:
	if body is Player:
		player = body as Player


func _on_body_exited(body: Node3D) -> void:
	if body == player:
		player = null
