extends Label
## The score on screen.

## The stage that is keeping score.
@export var stage: Stage


func _ready() -> void:
	_on_score_changed(0)
	if stage != null:
		stage.score_changed.connect(_on_score_changed)


func _on_score_changed(score: int) -> void:
	text = "SCORE %d" % score
