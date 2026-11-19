class_name PlayerAnimator
extends CharacterAnimator
## Watches Fart Man and plays the matching clip: run, jump, charge, hurt and so on.
## Needs no art: with grey boxes it squashes and stretches instead.
##
## Loops (picked every frame): flight, fall, walk / run / sprint, and while standing
## still: squeak, charge, talk or idle.
## One-shots (a moment): hops and jumps, landings, stomp, hurt, death, victory.

## Fart Man. Leave empty to use this node's parent.
@export var player: Player
## He counts as running when he moves faster than this, in metres per second.
@export var run_speed_threshold: float = 0.5
## Slower than this he walks instead of runs, in metres per second.
@export var walk_speed_limit: float = 3.0
## How fast each clip really travels (measured from the animation), in metres per second.
## We speed the clip up or slow it down to match his real speed so his feet don't slide.
@export var walk_native_speed: float = 1.72
@export var run_native_speed: float = 5.1
@export var sprint_native_speed: float = 7.34
## Falling further than this (metres) makes a big landing, even after a small jump.
@export var big_drop_height: float = 4.0

var _was_on_floor: bool = true
## True if the last take-off was a Thunder.
var _big_takeoff: bool = false
## His highest point since he left the ground.
var _peak_y: float = 0.0
## Seconds of talking left (see talk_for).
var _talk_left: float = 0.0


func _ready() -> void:
	super._ready()
	if player == null:
		player = get_parent() as Player
	if player == null:
		return
	_peak_y = player.global_position.y
	# One-shots: things that happen at a moment.
	player.farted.connect(_on_farted)
	player.stomped.connect(func() -> void: play_once(&"stomp"))
	player.got_hurt.connect(func() -> void: play_once(&"hurt"))
	player.died.connect(_on_died)
	player.celebrated.connect(func() -> void: play_once(&"victory"))
	player.respawned.connect(_on_respawned)
	play(&"idle")


## Makes the "talk" clip play while he stands still, for this many seconds.
func talk_for(seconds: float) -> void:
	_talk_left = seconds


func _physics_process(delta: float) -> void:
	if player == null:
		return
	_talk_left = maxf(_talk_left - delta, 0.0)
	var on_floor: bool = player.is_on_floor()
	# Lying down after the last heart: let the death clip play out, nothing interrupts it.
	if player.is_dying:
		_was_on_floor = on_floor
		_peak_y = player.global_position.y
		return
	var flying: bool = player.is_flying()
	var moving: bool = absf(player.velocity.x) > run_speed_threshold
	if on_floor or flying:
		_peak_y = player.global_position.y
	else:
		_peak_y = maxf(_peak_y, player.global_position.y)
	# Just touched the ground after being in the air.
	if on_floor and not _was_on_floor and not flying:
		_landed(moving)
	_was_on_floor = on_floor
	# Starting to move cuts short the clips that only make sense standing still.
	if moving and on_floor and shot_clip in [&"land", &"big_land", &"victory", &"talk"]:
		stop_shot()
	play(_loop_for_now(on_floor, moving))
	_match_speed(moving)


## He just landed. A big drop (or a Thunder jump) is a roll or a crouch; small ones just a bounce.
func _landed(moving: bool) -> void:
	var drop: float = _peak_y - player.global_position.y
	if not has_clip(&"land"):
		play_once(&"land")  # grey box: squash on every landing
	elif _big_takeoff or drop > big_drop_height:
		play_once(_first_clip([&"roll", &"land"]) if moving else _first_clip([&"big_land", &"land"]))
	elif not moving:
		play_once(&"land")
	_big_takeoff = false
	_peak_y = player.global_position.y


func _on_farted(tier: String) -> void:
	_big_takeoff = tier == "Thunder"
	var moving: bool = absf(player.velocity.x) > run_speed_threshold
	match tier:
		"Toot":
			play_once(_first_clip([&"hop_run", &"jump"]) if moving else _first_clip([&"hop", &"jump"]))
		"Thunder":
			play_once(_first_clip([&"big_jump", &"jump"]))
		_:
			play_once(&"jump")


func _on_died() -> void:
	var options: Array[StringName] = []
	for clip: StringName in [&"death", &"death_2"]:
		if has_clip(clip):
			options.append(clip)
	if not options.is_empty():
		play_once(options.pick_random())


func _on_respawned() -> void:
	_peak_y = player.global_position.y
	_big_takeoff = false
	stop_shot()


## The first clip in the list the model has (the last one is the fallback if none).
func _first_clip(options: Array[StringName]) -> StringName:
	for clip: StringName in options:
		if has_clip(clip):
			return clip
	return options[-1]


## Picks the looping clip that matches what he is doing right now.
func _loop_for_now(on_floor: bool, moving: bool) -> StringName:
	if player.is_flying():
		return &"flight"
	if not on_floor:
		return &"fall" if has_clip(&"fall") else &"jump"
	if moving:
		if player.is_hot() and has_clip(&"sprint"):
			return &"sprint"
		if absf(player.velocity.x) < walk_speed_limit and has_clip(&"walk"):
			return &"walk"
		return &"run"
	if player.is_squeaking:
		return &"squeak"
	if player.is_charging:
		return &"charge"
	if _talk_left > 0.0:
		return &"talk"
	return &"idle"


## Runs the walk, run and sprint clips faster or slower so his feet match the ground.
func _match_speed(moving: bool) -> void:
	if animation_player == null:
		return
	var native: float = 0.0
	if shot_clip == &"" and moving:
		match loop_clip:
			&"walk":
				native = walk_native_speed
			&"run":
				native = run_native_speed
			&"sprint":
				native = sprint_native_speed
	if native > 0.0:
		animation_player.speed_scale = clampf(absf(player.velocity.x) / native, 0.5, 2.0)
	else:
		animation_player.speed_scale = 1.0
