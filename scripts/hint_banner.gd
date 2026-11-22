class_name HintBanner
extends CanvasLayer
## Hints from signs show up here: big words at the top middle of the screen, out of the way
## of the game, instead of a bubble over the sign. Only one hint at a time: a new one
## replaces the old one.
##
## Use it from any script, in one line:
##     HintBanner.show_hint(self, "HOLD FART TO CHARGE!")

const FONT_SIZE: int = 32
const FADE_TIME: float = 0.25
const BUBBLE_COLOR: Color = Color.WHITE
const INK_COLOR: Color = Color.BLACK
## Gap between the hint and the top of the screen, in pixels.
const TOP_GAP: float = 14.0
## The gas bar, hearts and Golden Beans sit in the top left corner, this wide.
## If the hint would cover them (a narrow screen), it drops below them instead.
const LEFT_HUD_WIDTH: float = 410.0
## How far down it drops when it has to, in pixels.
const BELOW_HUD: float = 150.0

var panel: PanelContainer
var label: Label


## from = anything in the game (used to find the screen). words = the hint.
## seconds = how long it stays before fading.
static func show_hint(from: Node, words: String, seconds: float = 3.0) -> HintBanner:
	if words == "" or from == null or not from.is_inside_tree():
		return null
	var screen_root: Window = from.get_tree().root

	# Only one hint at a time: a new one replaces the old one.
	if screen_root.has_meta(&"hint_banner"):
		var old: Variant = screen_root.get_meta(&"hint_banner")
		if is_instance_valid(old):
			(old as Node).queue_free()

	var banner := HintBanner.new()
	banner.name = "HintBanner"
	banner.layer = 5
	banner._build(words)
	screen_root.set_meta(&"hint_banner", banner)
	screen_root.add_child.call_deferred(banner)
	banner._fade_out_after.call_deferred(seconds)
	return banner


## Makes the white rounded box and the words inside it (it looks like a speech bubble).
func _build(words: String) -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = BUBBLE_COLOR
	box.border_color = INK_COLOR
	box.set_border_width_all(4)
	box.set_corner_radius_all(18)
	box.content_margin_left = 20.0
	box.content_margin_right = 20.0
	box.content_margin_top = 8.0
	box.content_margin_bottom = 8.0

	panel = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", box)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)

	label = Label.new()
	label.text = words
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	label.add_theme_color_override("font_color", INK_COLOR)
	panel.add_child(label)


func _process(_delta: float) -> void:
	# Keep it in the middle at the top, even if the window changes size.
	var screen: Vector2 = get_viewport().get_visible_rect().size
	var x: float = (screen.x - panel.size.x) * 0.5
	var y: float = TOP_GAP if x >= LEFT_HUD_WIDTH else BELOW_HUD
	panel.position = Vector2(maxf(x, TOP_GAP), y)


func _fade_out_after(seconds: float) -> void:
	var tween: Tween = create_tween()
	tween.tween_interval(seconds)
	tween.tween_property(panel, "modulate:a", 0.0, FADE_TIME)
	tween.tween_callback(queue_free)
