class_name PlayerAnimator
extends CharacterAnimator
## Watches Fart Man and plays the matching clip: run, jump, charge, hurt and so on.
## Needs no art: with grey boxes it squashes and stretches instead.

## Fart Man. Leave empty to use this node's parent.
@export var player: Player
## He counts as running when he moves faster than this, in metres per second.
@export var run_speed_threshold: float = 0.5

var _was_on_floor: bool = true


func _ready() -> void:
	super._ready()
	if player == null:
		player = get_parent() as Player
	if player == null:
		return
	# One-shots: things that happen at a moment.
	player.farted.connect(func(_tier: String) -> void: play_once(&"jump"))
	player.stomped.connect(func() -> void: play_once(&"stomp"))
	player.got_hurt.connect(func() -> void: play_once(&"hurt"))
	player.respawned.connect(func() -> void: shot_clip = &"")
	play(&"idle")


func _physics_process(_delta: float) -> void:
	if player == null:
		return
	var on_floor: bool = player.is_on_floor()
	# Just touched the ground after being in the air.
	if on_floor and not _was_on_floor and not player.is_flying():
		play_once(&"land")
	_was_on_floor = on_floor
	play(_loop_for_now(on_floor))


## Picks the looping clip that matches what he is doing right now.
func _loop_for_now(on_floor: bool) -> StringName:
	if player.is_flying():
		return &"flight"
	if player.is_squeaking:
		return &"squeak"
	if player.is_charging:
		return &"charge"
	if not on_floor:
		return &"fall" if player.velocity.y <= 0.0 else &"jump"
	if absf(player.velocity.x) > run_speed_threshold:
		return &"run"
	return &"idle"
