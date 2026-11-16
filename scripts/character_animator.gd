class_name CharacterAnimator
extends Node
## Plays named animation clips on any character (Fart Man, enemies, bosses).
##
## Real model with an AnimationPlayer? It plays the clip with that name.
## Grey box, or a clip that is missing? It squashes and stretches the shape in code instead,
## so a half-finished character is never broken.
##
## Two ways to play something:
##   play(clip)       a looping clip, like "idle" or "run". It stays until changed.
##   play_once(clip)  a short one, like "hurt" or "squash". Then back to the loop.

## Clip names every character shares. A new model must have these (a test checks).
const PLAYER_CLIPS: Array[StringName] = [
	&"idle", &"run", &"jump", &"fall", &"land", &"charge", &"squeak",
	&"hurt", &"stomp", &"flight", &"victory", &"talk"]
const ENEMY_CLIPS: Array[StringName] = [&"walk", &"squash"]
const BOSS_CLIPS: Array[StringName] = [&"idle", &"attack", &"hurt", &"dizzy", &"defeat"]

## The code-made look for each clip, used when there is no real animation.
## wobble = how much it breathes in and out, speed = how fast.
## For one-shots: shot_scale is the squashed look at the start, then it eases back
## over seconds. offset moves the shape (the squashed Burpling drops to the floor).
const FALLBACKS: Dictionary = {
	&"idle": {"wobble": 0.03, "speed": 3.0},
	&"walk": {"wobble": 0.06, "speed": 10.0},
	&"run": {"wobble": 0.07, "speed": 16.0},
	&"charge": {"scale": Vector3(1.1, 0.9, 1.1), "wobble": 0.04, "speed": 24.0},
	&"squeak": {"scale": Vector3(1.05, 0.95, 1.05), "wobble": 0.09, "speed": 34.0},
	&"fall": {"scale": Vector3(0.9, 1.15, 0.9)},
	&"flight": {},
	&"talk": {"wobble": 0.06, "speed": 12.0},
	&"jump": {"shot_scale": Vector3(0.8, 1.3, 0.8), "seconds": 0.25},
	&"land": {"shot_scale": Vector3(1.25, 0.7, 1.25), "seconds": 0.2},
	&"hurt": {"shot_scale": Vector3(1.25, 0.75, 1.25), "seconds": 0.4},
	&"stomp": {"shot_scale": Vector3(0.8, 1.3, 0.8), "seconds": 0.25},
	&"victory": {"shot_scale": Vector3(0.8, 1.35, 0.8), "seconds": 0.8},
	&"attack": {"shot_scale": Vector3(1.3, 0.8, 1.3), "seconds": 0.4},
	&"dizzy": {"wobble": 0.1, "speed": 8.0},
	&"defeat": {"shot_scale": Vector3(1.5, 0.3, 1.5), "seconds": 0.6},
	# A squashed enemy goes flat and stays flat.
	&"squash": {"shot_scale": Vector3(1.4, 0.1, 1.4), "seconds": 0.0, "offset": Vector3(0, -0.35, 0)},
}

## Sent every time a clip starts. Handy for tests, and later for sounds.
signal clip_played(clip: StringName)

## The real model's animations. Leave empty for grey boxes.
@export var animation_player: AnimationPlayer
## The shape to squash and stretch when there is no real clip.
@export var squash_target: Node3D
## Turn off to freeze the code-made squash and stretch.
@export var fallback_enabled: bool = true

## The looping clip we are on, and the one-shot on top of it (empty when none).
var loop_clip: StringName = &""
var shot_clip: StringName = &""
var shot_age: float = 0.0
var _time: float = 0.0
var _rest_scale: Vector3 = Vector3.ONE
var _rest_position: Vector3 = Vector3.ZERO


func _ready() -> void:
	if squash_target != null:
		_rest_scale = squash_target.scale
		_rest_position = squash_target.position
	if animation_player != null:
		animation_player.animation_finished.connect(_on_clip_finished)


## True when the real model has a clip with this name.
func has_clip(clip: StringName) -> bool:
	return animation_player != null and animation_player.has_animation(clip)


## Which clips from a list the model is missing? Empty means all there.
func missing_clips(wanted: Array[StringName]) -> Array[StringName]:
	var missing: Array[StringName] = []
	for clip: StringName in wanted:
		if not has_clip(clip):
			missing.append(clip)
	return missing


## Start a looping clip. Does nothing if it is already playing.
func play(clip: StringName) -> void:
	if clip == loop_clip:
		return
	loop_clip = clip
	# A one-shot in progress finishes first, then this loop takes over.
	if shot_clip == &"":
		_start(clip)


## Play a short clip once, then go back to the loop.
func play_once(clip: StringName) -> void:
	shot_clip = clip
	shot_age = 0.0
	_start(clip)


func _start(clip: StringName) -> void:
	clip_played.emit(clip)
	if has_clip(clip):
		animation_player.play(clip)


## The real animation for a one-shot ended: back to the loop.
func _on_clip_finished(clip: StringName) -> void:
	if clip == shot_clip:
		_end_shot()


func _end_shot() -> void:
	shot_clip = &""
	if loop_clip != &"":
		_start(loop_clip)


func _process(delta: float) -> void:
	_time += delta
	if shot_clip != &"":
		shot_age += delta
		# Code-made one-shots end by themselves (real ones end when the clip finishes).
		var seconds: float = float(FALLBACKS.get(shot_clip, {}).get("seconds", 0.25))
		if not has_clip(shot_clip) and seconds > 0.0 and shot_age >= seconds:
			_end_shot()
	if fallback_enabled and squash_target != null:
		_apply_fallback()


## Squash and stretch in code, for any clip with no real animation.
func _apply_fallback() -> void:
	var running: StringName = shot_clip if shot_clip != &"" else loop_clip
	if has_clip(running) or running == &"":
		return
	var look: Dictionary = FALLBACKS.get(running, {})
	var scale_now: Vector3 = look.get("scale", Vector3.ONE)
	var offset: Vector3 = Vector3.ZERO
	var wobble: float = look.get("wobble", 0.0)
	if wobble > 0.0:
		# Breathes in and out: taller and thinner, then shorter and wider.
		var beat: float = sin(_time * float(look.get("speed", 1.0))) * wobble
		scale_now *= Vector3(1.0 - beat, 1.0 + beat, 1.0 - beat)
	if shot_clip != &"":
		var seconds: float = float(look.get("seconds", 0.25))
		var fade: float = clampf(shot_age / seconds, 0.0, 1.0) if seconds > 0.0 else 0.0
		var from_scale: Vector3 = look.get("shot_scale", Vector3.ONE)
		# Eases from the squashed look back to normal (a zero-second one stays squashed).
		scale_now = from_scale.lerp(scale_now, fade * fade)
		offset = Vector3(look.get("offset", Vector3.ZERO)) * (1.0 - fade * fade)
	squash_target.scale = _rest_scale * scale_now
	squash_target.position = _rest_position + offset
