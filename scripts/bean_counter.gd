class_name BeanCounter
extends HBoxContainer
## The bean counter on screen: a bean picture and how many beans he has grabbed in this stage.

## The stage that is keeping count.
@export var stage: Stage
## The words on screen and their size.
@export var font_size: int = 40

## The number label (the tests read it).
var label: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override("separation", 10)
	add_child(BeanIcon.new())
	label = Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 8)
	add_child(label)
	_show(0)
	if stage != null:
		stage.beans_changed.connect(_show)
		_show(stage.beans_this_stage)


func _show(beans: int) -> void:
	label.text = "BEANS %s" % Stage.with_commas(beans)
