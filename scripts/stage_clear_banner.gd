class_name StageClearBanner
extends Label
## The big "STAGE CLEAR!" words. Hidden until the Bean Can is opened.
## Under them the beans of the stage count up ("+312 BEANS!") and pour into a jar,
## then a cha-ching shows what the Bean Jar holds now. It all takes about two seconds.

## The stage to watch.
@export var stage: Stage
@export_group("Bean pour")
## How long to wait before the beans start to pour, and how long the counting takes.
@export var pour_delay: float = 0.4
@export var count_time: float = 1.3
## The jar looks full at this many beans (so a normal stage fills most of it).
@export var jar_full_beans: int = 400
## Where the pour sits: pixels down from the top of the screen.
@export var pour_top: float = 385.0
## The cha-ching when the jar total appears.
@export var ching_sound: AudioStream

## What the pour shows (the tests read these).
var pour_label: Label
var jar_label: BeanJarLabel
var jar_picture: BeanJarPicture
var pour_done: bool = false
var _pour: Control


func _ready() -> void:
	hide()
	ching_sound = ching_sound if ching_sound != null else Sfx.named("cha_ching")
	if stage != null:
		stage.stage_cleared.connect(_on_stage_cleared)


func _on_stage_cleared() -> void:
	text = "STAGE CLEAR!\nGOLDEN BEANS %d / %d\nSCORE %d" % [stage.golden_found, stage.golden_total, stage.score]
	show()
	if stage.beans_this_stage > 0:
		_start_pour(stage.beans_this_stage)
	else:
		pour_done = true


# Builds the jar and the words under the banner, then counts the beans up into the jar.
func _start_pour(beans: int) -> void:
	_pour = HBoxContainer.new()
	_pour.name = "BeanPour"
	_pour.add_theme_constant_override("separation", 24)
	_pour.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pour.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_pour.position.y = pour_top
	_pour.grow_horizontal = Control.GROW_DIRECTION_BOTH
	get_parent().add_child(_pour)
	jar_picture = BeanJarPicture.new()
	jar_picture.custom_minimum_size = Vector2(150, 190)
	_pour.add_child(jar_picture)
	var words := VBoxContainer.new()
	words.alignment = BoxContainer.ALIGNMENT_CENTER
	_pour.add_child(words)
	pour_label = _make_label(54, Color(1.0, 0.85, 0.1))
	pour_label.text = "+0 BEANS!"
	words.add_child(pour_label)
	jar_label = BeanJarLabel.new()
	jar_label.font_size = 38
	jar_label.modulate.a = 0.0  # appears with the cha-ching
	words.add_child(jar_label)
	jar_picture.pouring = true
	var tween: Tween = create_tween()
	tween.tween_interval(pour_delay)
	tween.tween_method(_count.bind(beans), 0.0, 1.0, count_time)
	tween.tween_callback(_finish_pour)


# Shows the count part of the way to "beans" (progress 0 to 1).
func _count(progress: float, beans: int) -> void:
	var shown: int = roundi(float(beans) * progress)
	pour_label.text = "+%s BEANS!" % Stage.with_commas(shown)
	jar_picture.fill = float(shown) / float(maxi(jar_full_beans, 1))


# The pour is over: cha-ching, and the jar's new total pops up.
func _finish_pour() -> void:
	jar_picture.pouring = false
	jar_label.modulate.a = 1.0
	jar_label.refresh()
	Sfx.play(self, ching_sound, 0.0, 1.0, 0.0)
	pour_done = true


func _make_label(font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 10)
	return label
