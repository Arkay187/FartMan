extends SquareBar
## The Golden Beans on screen: one gold square for each one found in this stage.

## The stage that is keeping count.
@export var stage: Stage


func _ready() -> void:
	if stage == null:
		return
	stage.golden_beans_changed.connect(show_squares)
	show_squares(stage.golden_found, stage.golden_total)
