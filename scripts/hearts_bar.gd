extends SquareBar
## The hearts on screen: one red square per heart, grey when it is lost.

## Whose hearts to show.
@export var player: Player


func _ready() -> void:
	if player == null or player.hearts == null:
		return
	player.hearts.hearts_changed.connect(show_squares)
	show_squares(player.hearts.hearts, player.hearts.max_hearts)
