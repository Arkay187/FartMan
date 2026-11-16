class_name EnemyAnimator
extends CharacterAnimator
## Plays an enemy's clips: "walk" all the time, "squash" when it gets stomped.
## Works with a real model, or squashes and stretches the grey shape.


func _ready() -> void:
	super._ready()
	play(&"walk")


## Enemies call this when they get squashed. Returns how long to wait before removing
## the enemy: the real clip's length, or the code-made one's.
func squash() -> float:
	play_once(&"squash")
	if has_clip(&"squash"):
		return animation_player.get_animation(&"squash").length
	return 0.25
