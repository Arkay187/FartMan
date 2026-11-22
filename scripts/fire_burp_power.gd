class_name FireBurpPower
extends Node
## The Fire Burp power. Lives on Fart Man and switches on when he grabs Hot Sauce.
## From then on, for the rest of the stage, the fire button (C / pad B) burps a rolling
## fireball instead of farting. A little orange flame on his head shows he has it.

## Sent when he gets the power, and when he loses it.
signal gained
signal lost

## The fireball scene to shoot (set by the scene builder).
@export var fireball_scene: PackedScene
## Most fireballs that can be alive at once.
@export var max_fireballs: int = 3
## How big each new fireball is (1 = normal). The Big Fireballs upgrade raises this.
@export var fireball_size: float = 1.0
## Do new fireballs hop over small gaps and roll longer? The Bouncy Fireballs upgrade.
@export var bouncy_fireballs: bool = false
## Seconds to wait between shots.
@export var cooldown: float = 0.2
## Lose the power when he gets hurt? Off: a little kid should not be punished.
@export var lost_when_hurt: bool = false
## Where the fireball starts: in front of him and up at mouth height (his middle is 0).
@export var mouth_offset: Vector3 = Vector3(0.9, 0.5, 0.0)
## The flame on his head.
@export var flame_height: float = 1.25
@export var flame_color: Color = Color(1.0, 0.55, 0.1)

var has_power: bool = false
var _cooldown_left: float = 0.0
var _player: Player
var _flame: MeshInstance3D
var _time: float = 0.0


func _ready() -> void:
	_player = get_parent() as Player
	if _player != null:
		_player.got_hurt.connect(_on_hurt)


## Hot Sauce calls this.
func collect() -> void:
	give(false)


## Gives him the power. quiet = true says nothing and shows no hint (Spicy Start uses that).
func give(quiet: bool) -> void:
	if _player == null:
		return
	var first_time: bool = not has_power
	has_power = true
	_show_flame(true)
	if first_time:
		gained.emit()
	if quiet:
		return
	_player.say("FIRE BURP!")
	HintBanner.show_hint(_player, "PRESS B TO FIRE BURP!", 3.0)


## Takes the power away (when hurt, if lost_when_hurt is on).
func lose() -> void:
	if not has_power:
		return
	has_power = false
	_show_flame(false)
	lost.emit()


func _on_hurt() -> void:
	if lost_when_hurt:
		lose()


func _physics_process(delta: float) -> void:
	_cooldown_left = maxf(_cooldown_left - delta, 0.0)
	if not has_power or _player == null:
		return
	if Input.is_action_just_pressed(_player.fire_action):
		shoot()


## How many fireballs are alive right now.
func fireballs_alive() -> int:
	var count: int = 0
	for ball: Node in get_tree().get_nodes_in_group(&"fireballs"):
		if not (ball as Fireball).is_popped:
			count += 1
	return count


## Burps a fireball the way he faces. Does nothing if he can't right now.
func shoot() -> bool:
	if not has_power or _player == null or fireball_scene == null:
		return false
	if _cooldown_left > 0.0 or fireballs_alive() >= max_fireballs:
		return false
	if _player.is_flying() or _player.input_locked or _player.is_dying or _player.frozen:
		return false
	var facing: float = 1.0
	if _player.visual != null and absf(_player.visual.rotation.y) > 1.0:
		facing = -1.0
	var ball := fireball_scene.instantiate() as Fireball
	ball.direction = facing
	ball.size = fireball_size
	ball.bouncy = bouncy_fireballs
	# Join the level (not the player) so the fireball does not move with him.
	_player.get_parent().add_child(ball)
	ball.global_position = _player.global_position + Vector3(mouth_offset.x * facing, mouth_offset.y, 0.0)
	_cooldown_left = cooldown
	_player.fire_burped.emit()
	return true


func _process(delta: float) -> void:
	if _flame == null or not _flame.visible:
		return
	_time += delta
	_flame.position.y = flame_height + sin(_time * 8.0) * 0.06
	_flame.scale = Vector3(1.0 + sin(_time * 11.0) * 0.1, 1.0 + sin(_time * 9.0) * 0.15, 1.0)


## A small orange cone on his head. Made the first time he needs it.
func _show_flame(on: bool) -> void:
	if on and _flame == null:
		_flame = MeshInstance3D.new()
		_flame.name = "FireFlame"
		var cone := CylinderMesh.new()
		cone.top_radius = 0.0
		cone.bottom_radius = 0.18
		cone.height = 0.45
		var paint := StandardMaterial3D.new()
		paint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		paint.albedo_color = flame_color
		cone.material = paint
		_flame.mesh = cone
		_flame.position = Vector3(0.0, flame_height, 0.0)
		_player.add_child(_flame)
	if _flame != null:
		_flame.visible = on
