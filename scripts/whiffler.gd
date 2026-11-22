class_name Whiffler
extends Burpling
## A Whiffler: a little alien that stands still and now and then PUFFS out a stink cloud.
## Its cycle: rest (safe to stomp), swell up and wobble (WARNING, still safe), PUFF (the stink
## cloud hurts, even from above), then rest again. Stomp it between puffs.

enum Mood { REST, TELL, PUFF }

## Seconds it rests, seconds it swells before the puff (the warning), and seconds the cloud stays.
@export var rest_time: float = 2.4
@export var tell_time: float = 0.9
@export var puff_time: float = 1.4
## Where in the cycle it starts (0 to 1), so a row of Whifflers does not all puff together.
@export var phase: float = 0.0
## The stink cloud (an Area3D with a round shape). Only switched on while puffing.
@export var cloud_zone: Area3D
## The green puffs inside the cloud zone, shown while puffing.
@export var cloud_visual: Node3D
## The puff.
@export var puff_sound: AudioStream

var mood: Mood = Mood.REST
var _clock: float = 0.0


func _ready() -> void:
	super._ready()
	_clock = phase * (rest_time + tell_time + puff_time)
	_set_mood(Mood.REST)
	# Start part-way round the cycle if asked.
	_update_mood()


func _physics_process(delta: float) -> void:
	if is_squashed:
		return
	if mood == Mood.PUFF:
		# While the cloud is out, touching it (even from above) hurts. No stomping now.
		_move(delta)
		if cloud_zone != null and mood == Mood.PUFF:
			for body: Node3D in cloud_zone.get_overlapping_bodies():
				var player := body as Player
				if player != null:
					player.hurt(global_position.x)
		return
	super._physics_process(delta)


func _move(delta: float) -> void:
	_clock = fmod(_clock + delta, rest_time + tell_time + puff_time)
	_update_mood()
	# Swell and wobble during the warning.
	if visual != null:
		if mood == Mood.TELL:
			var t: float = (_clock - rest_time) / maxf(tell_time, 0.01)
			var swell: float = 1.0 + 0.45 * t
			visual.scale = Vector3(swell, swell, swell) * (1.0 + 0.06 * sin(_clock * 40.0))
		elif mood == Mood.REST:
			visual.scale = Vector3.ONE


func _update_mood() -> void:
	var now: Mood = Mood.REST
	if _clock >= rest_time + tell_time:
		now = Mood.PUFF
	elif _clock >= rest_time:
		now = Mood.TELL
	if now != mood:
		_set_mood(now)


func _set_mood(now: Mood) -> void:
	mood = now
	var puffing: bool = now == Mood.PUFF
	if cloud_zone != null:
		cloud_zone.monitoring = puffing
	if cloud_visual != null:
		cloud_visual.visible = puffing
	if puffing:
		Sfx.play(self, puff_sound)
		if visual != null:
			visual.scale = Vector3.ONE
