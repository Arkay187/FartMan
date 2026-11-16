class_name Burpling
extends Area3D
## A Burpling: a small blob that waddles back and forth.
## Land on top of it to squash it. Touch it any other way and it hurts.

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

var is_squashed: bool = false
var direction: float = 1.0
var start_x: float = 0.0


func _ready() -> void:
	start_x = position.x


func _physics_process(delta: float) -> void:
	if is_squashed:
		return

	# Waddle, and turn around at each end.
	position.x += walk_speed * direction * delta
	if absf(position.x - start_x) >= patrol_distance:
		direction = -signf(position.x - start_x)

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


## Is he above us (feet higher than our middle), or right over the top of us?
func _is_on_top(player: Player) -> bool:
	var feet_above: bool = player.get_feet_y() > global_position.y - 0.1
	var right_over: bool = absf(player.global_position.x - global_position.x) < stomp_width
	return feet_above or right_over


func _get_squashed() -> void:
	is_squashed = true
	Stage.award(self, points)
	SpeechBubble.say(self, squash_words, 0.6, 1.0)
	squashed.emit()
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
