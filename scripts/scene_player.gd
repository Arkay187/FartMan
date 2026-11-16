class_name ScenePlayer
extends Node
## Plays a little puppet-show scene: a list of steps read top to bottom.
## The lists live in scripts/puppet/. Each step is a short list, first word says what to do:
##
##   ["say", "boss", "ACHOO!", 1.5]    someone says something, then we wait that long
##   ["wait", 0.5]                     pause
##   ["shake", 0.3, 0.6]               shake the screen: how hard, for how long
##   ["walk", "player", 4.0]           walk to this x position
##   ["face", "player", 1]             look right (1) or left (-1)
##   ["clip", "boss", "attack"]        play an animation clip
##   ["call", "boss", "open_gate"]     run a function on someone (this always runs, even if skipped)
##
## Names like "boss" and "player" are looked up in the actors list given to play().
## Holding the skip button for a moment skips the rest. Scenes show only the first time.

## Sent when the scene ends. skipped is true if it was skipped or already seen.
signal finished(skipped: bool)

## Hold this button to skip.
@export var skip_action: StringName = &"jump"
## How long to hold it, in seconds.
@export var skip_hold_time: float = 1.0
## How fast characters walk in a scene, metres per second.
@export var walk_speed: float = 4.0

var is_playing: bool = false
var _skipped: bool = false
var _held: float = 0.0


## Plays the steps. Use:  await scene_player.play(steps, {"boss": boss, "player": player}, "boss1_hello")
## If seen_flag is not empty, the scene is only shown once (it is saved with the game).
func play(steps: Array, actors: Dictionary, seen_flag: String = "") -> void:
	var save: SaveData = SaveLookup.find(self)
	if seen_flag != "" and save != null and save.has_seen(seen_flag):
		finished.emit(true)
		return
	is_playing = true
	_skipped = false
	_held = 0.0
	var player := actors.get("player") as Player
	if player != null:
		player.input_locked = true
	for step: Array in steps:
		if _skipped and step[0] != "call":
			continue
		await _do_step(step, actors)
	if player != null:
		player.input_locked = false
	is_playing = false
	if seen_flag != "" and save != null:
		save.mark_seen(seen_flag)
	finished.emit(_skipped)


func _process(delta: float) -> void:
	if not is_playing:
		return
	_held = _held + delta if Input.is_action_pressed(skip_action) else 0.0
	if _held >= skip_hold_time:
		_skipped = true


func _do_step(step: Array, actors: Dictionary) -> void:
	match step[0]:
		"say":
			var who := actors.get(step[1]) as Node3D
			var seconds: float = step[3] if step.size() > 3 else 1.6
			var height: float = step[4] if step.size() > 4 else 2.0
			SpeechBubble.say(who, step[2], seconds, height)
			await _sleep(seconds)
		"wait":
			await _sleep(step[1])
		"shake":
			await _shake(step[1], step[2])
		"walk":
			var who := actors.get(step[1]) as Node3D
			if who != null:
				var tween: Tween = create_tween()
				tween.tween_property(who, "position:x", float(step[2]), absf(float(step[2]) - who.position.x) / walk_speed)
				while tween.is_running() and not _skipped:
					await get_tree().process_frame
				tween.kill()
		"face":
			var who := actors.get(step[1]) as Node3D
			if who != null and who.get("visual") != null:
				(who.get("visual") as Node3D).rotation.y = 0.0 if float(step[2]) > 0.0 else PI
		"clip":
			var who: Node = actors.get(step[1])
			var animator: Node = who.get_node_or_null("Animator") if who != null else null
			if animator != null:
				animator.call("play_once", StringName(step[2]))
		"call":
			var who: Node = actors.get(step[1])
			if who != null:
				who.call(step[2])


## Waits, but stops early if the scene is skipped.
func _sleep(seconds: float) -> void:
	var waited: float = 0.0
	while waited < seconds and not _skipped:
		await get_tree().process_frame
		waited += get_process_delta_time()


func _shake(strength: float, seconds: float) -> void:
	var camera: Camera3D = get_viewport().get_camera_3d()
	var waited: float = 0.0
	while waited < seconds and not _skipped:
		if camera != null:
			camera.h_offset = randf_range(-strength, strength)
			camera.v_offset = randf_range(-strength, strength)
		await get_tree().process_frame
		waited += get_process_delta_time()
	if camera != null:
		camera.h_offset = 0.0
		camera.v_offset = 0.0
