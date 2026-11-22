class_name BeanJarLabel
extends HBoxContainer
## "BEAN JAR 2,345" with a bean picture: how many beans are in the jar. Follows the save file.

## The words on screen and their size.
@export var font_size: int = 44

## The text label (the tests read it).
var label: Label
var _save: SaveData


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override("separation", 10)
	add_child(BeanIcon.new())
	label = Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 8)
	add_child(label)
	_save = SaveLookup.find(self)
	if _save != null:
		_save.changed.connect(refresh)
	refresh()


func refresh() -> void:
	label.text = "BEAN JAR %s" % Stage.with_commas(0 if _save == null else _save.bean_jar)
