class_name SpeechBubble
extends CanvasLayer
## A speech bubble that floats over someone's head for a moment, then fades away.
##
## Use it from any script, in one line:
##     SpeechBubble.say(self, "HELLO!")
## Keep the words short and LOUD. About six words at most.

const FONT_SIZE: int = 28
const FADE_TIME: float = 0.25
const BUBBLE_COLOR: Color = Color.WHITE
const INK_COLOR: Color = Color.BLACK
## Gap kept between a bubble and the edge of the screen, in pixels.
const EDGE_GAP: float = 12.0

var speaker: Node3D
var height_above: float = 2.0
## Where the bubble points. Remembered so it stays put if the speaker disappears.
var point: Vector3
var panel: PanelContainer


## who = the one talking. words = what they say. seconds = how long it stays.
## height_above = how far above their middle the bubble floats, in metres.
static func say(who: Node3D, words: String, seconds: float = 2.0, height_above: float = 2.0) -> SpeechBubble:
	if words == "" or who == null or not who.is_inside_tree():
		return null

	# Only one bubble per speaker: a new one replaces the old one.
	if who.has_meta(&"speech_bubble"):
		var old: Variant = who.get_meta(&"speech_bubble")
		if is_instance_valid(old):
			(old as Node).queue_free()

	var bubble := SpeechBubble.new()
	bubble.speaker = who
	bubble.height_above = height_above
	bubble.point = who.global_position + Vector3.UP * height_above
	bubble._build(words)
	who.set_meta(&"speech_bubble", bubble)
	who.get_tree().root.add_child.call_deferred(bubble)
	bubble._fade_out_after.call_deferred(seconds)
	return bubble


## Makes the white rounded box and the words inside it.
func _build(words: String) -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = BUBBLE_COLOR
	box.border_color = INK_COLOR
	box.set_border_width_all(3)
	box.set_corner_radius_all(16)
	box.content_margin_left = 16.0
	box.content_margin_right = 16.0
	box.content_margin_top = 8.0
	box.content_margin_bottom = 8.0

	panel = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", box)
	panel.visible = false
	add_child(panel)

	var label := Label.new()
	label.text = words
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	label.add_theme_color_override("font_color", INK_COLOR)
	panel.add_child(label)


func _process(_delta: float) -> void:
	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera == null:
		return
	# Follow the speaker for as long as they exist.
	if is_instance_valid(speaker) and speaker.is_inside_tree():
		point = speaker.global_position + Vector3.UP * height_above
	panel.visible = not camera.is_position_behind(point)
	var on_screen: Vector2 = camera.unproject_position(point)
	panel.position = on_screen - Vector2(panel.size.x * 0.5, panel.size.y)
	# Never let the words run off the edge of the screen.
	var screen: Vector2 = get_viewport().get_visible_rect().size
	panel.position = panel.position.clamp(Vector2(EDGE_GAP, EDGE_GAP), screen - panel.size - Vector2(EDGE_GAP, EDGE_GAP))


func _fade_out_after(seconds: float) -> void:
	var tween: Tween = create_tween()
	tween.tween_interval(seconds)
	tween.tween_property(panel, "modulate:a", 0.0, FADE_TIME)
	tween.tween_callback(queue_free)
