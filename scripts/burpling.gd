class_name Burpling
extends Area3D
## A Burpling: a small blob that waddles back and forth.
## Land on top of it to squash it. Touch it any other way and it hurts.
## Other enemies (Hiccup, Gnome, Crow...) are Burplings that move differently:
## they replace _move() and keep all the stomping rules.

## Sent when it gets squashed. Use this later for the "pop" sound.
signal squashed

## How fast it waddles.
@export var walk_speed: float = 1.5
## How far it walks each way from where it was placed.
@export var patrol_distance: float = 2.0
## How long the squashed pancake stays before it disappears.
@export var squash_time: float = 0.25
## How close to its middle he must be to squash it when landing low. Bigger = easier.
@export var stomp_width: float = 0.6
## How many points squashing it is worth.
@export var points: int = 50
## What it says when squashed. Leave empty for nothing.
@export var squash_words: String = "POP!"
## The blob model, so it can be flattened when squashed.
@export var visual: Node3D
## Plays its walk and squash clips. Leave empty for the plain flatten-and-vanish.
@export var animator: EnemyAnimator
## The sound when it gets squashed.
@export var squash_sound: AudioStream
## A sound it makes now and then while alive (a caw, a flap, a rumble). Leave empty for quiet.
@export var idle_sound: AudioStream
## About how many seconds between those sounds.
@export var idle_every: float = 3.0
## How loud that sound is, in decibels (0 = full, -6 = half).
@export var idle_volume_db: float = -4.0

var is_squashed: bool = false
var direction: float = 1.0
var start_x: float = 0.0
var _idle_left: float = 0.0


func _ready() -> void:
	start_x = position.x
	_idle_left = randf_range(0.2, idle_every)


func _physics_process(delta: float) -> void:
	if is_squashed:
		return
	_move(delta)
	_make_idle_noise(delta)

	# Is Fart Man touching us?
	for body: Node3D in get_overlapping_bodies():
		var player := body as Player
		if player == null:
			continue
		if player.is_hot():
			# Chilli power: he just runs straight through us.
			_get_squashed()
		elif player.can_stomp() and _is_on_top(player):
			player.stomp_bounce()
			_get_squashed()
		else:
			player.hurt(global_position.x)
		return


## Now and then it makes its own little noise (only if it has an idle_sound).
func _make_idle_noise(delta: float) -> void:
	if idle_sound == null:
		return
	_idle_left -= delta
	if _idle_left <= 0.0:
		_idle_left = idle_every * randf_range(0.75, 1.25)
		Sfx.play(self, idle_sound, idle_volume_db)


## How this enemy moves each frame. Burplings waddle; other enemies replace this.
func _move(delta: float) -> void:
	position.x += walk_speed * direction * delta
	if absf(position.x - start_x) >= patrol_distance:
		direction = -signf(position.x - start_x)


## Is he above us (feet higher than our middle), or right over the top of us?
func _is_on_top(player: Player) -> bool:
	var feet_above: bool = player.get_feet_y() > global_position.y - 0.1
	var right_over: bool = absf(player.global_position.x - global_position.x) < stomp_width
	return feet_above or right_over


## Squashes it from outside (the fart cloud does this). Does nothing if already squashed.
func squash() -> void:
	if not is_squashed:
		_get_squashed()


func _get_squashed() -> void:
	is_squashed = true
	Stage.award(self, points)
	SpeechBubble.say(self, squash_words, 0.6, 1.0)
	squashed.emit()
	Sfx.play(self, squash_sound)
	if animator != null:
		# The animator does the flattening, we just wait for it.
		var wait: float = maxf(animator.squash(), squash_time)
		get_tree().create_timer(wait).timeout.connect(queue_free)
		return
	if visual == null:
		queue_free()
		return
	# Flatten into a pancake on the floor, then disappear.
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(visual, "scale", Vector3(1.4, 0.1, 1.4), squash_time * 0.4)
	tween.tween_property(visual, "position:y", -0.35, squash_time * 0.4)
	tween.chain().tween_interval(squash_time * 0.6)
	tween.chain().tween_callback(queue_free)
