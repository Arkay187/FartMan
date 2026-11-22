class_name WarpPipe
extends Area3D
## A sideways warp pipe. Walk into the open end and PLOP! you pop out somewhere else.
## Put a second pipe at the other place so he can walk back.

## Which way he must be walking to go in: 1 = walking right, -1 = walking left.
@export var enter_dir: float = 1.0
## Where he pops out (a world position). Leave a little space from the other pipe.
@export var destination: Vector3 = Vector3.ZERO
## What he says when he pops out.
@export var exit_words: String = "PLOP!"
## Seconds before any pipe will take him again, so he does not bounce back and forth.
@export var cooldown: float = 1.0
## The bloop as he goes in.
@export var warp_sound: AudioStream

## The time (in seconds of game physics) before which no pipe takes anyone.
static var _blocked_until: float = 0.0


func _physics_process(_delta: float) -> void:
	var now: float = float(Engine.get_physics_frames()) / float(Engine.physics_ticks_per_second)
	if now < _blocked_until:
		return
	for body: Node3D in get_overlapping_bodies():
		var player := body as Player
		if player == null or player.is_flying() or player.is_dying:
			continue
		# He must really be walking into the mouth.
		if player.velocity.x * enter_dir < 1.0:
			continue
		_blocked_until = now + cooldown
		Sfx.play(self, warp_sound)
		player.global_position = destination
		player.velocity = Vector3.ZERO
		player.say(exit_words, 1.0)
		return
