extends Label
## The big "STAGE CLEAR!" words. Hidden until the Bean Can is opened.

## The stage to watch.
@export var stage: Stage


func _ready() -> void:
	hide()
	if stage != null:
		stage.stage_cleared.connect(_on_stage_cleared)


func _on_stage_cleared() -> void:
	text = "STAGE CLEAR!\nGOLDEN BEANS %d / %d" % [stage.golden_found, stage.golden_total]
	show()
