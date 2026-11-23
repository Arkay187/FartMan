class_name Storybook
extends Control
## Full-screen picture-book pages. Jump turns the page, the back button (pad B) turns back a page.
## After the last page it says "finished" and goes to the next scene. Hold jump for about a second
## to skip it all.
## The pages live in story_pages.gd.

## Sent after the last page (or a skip).
signal finished

## The big coloured card (a stand-in for a drawing).
@export var card: Control
## Shown instead of the colour if the page has an image file that exists.
@export var picture: TextureRect
## The one line of words under the card.
@export var caption: Label
## Which story to show (a name from story_pages.gd).
@export var story_name: String = "opening"
## Where to go afterwards. Leave empty to just stay put.
@export_file("*.tscn") var next_scene: String = ""
@export var jump_action: StringName = &"ui_accept"
## Turns back one page (pad B, Esc or Backspace). Does nothing on the first page.
@export var back_action: StringName = &"back"
## Hold jump this long to skip the whole story.
@export var skip_hold_time: float = 1.0
## Ignore buttons for this long at the start.
@export var input_delay: float = 0.3
## How much the card wobbles (degrees), how fast, and how much it slowly zooms.
@export var wobble_degrees: float = 1.5
@export var wobble_speed: float = 2.0
@export var zoom_amount: float = 0.03
## How long the little pop at the start of each page takes.
@export var pop_time: float = 0.25
## The song that plays here (empty = none), and the sound of turning a page.
@export var music_song: String = "theme"
@export var page_sound: AudioStream

var pages: Array[Dictionary] = []
var page_index: int = 0
var is_finished: bool = false
var _age: float = 0.0
var _page_age: float = 0.0
var _held: float = 0.0


func _ready() -> void:
	DebugOptionsData.ensure_input_actions()
	if music_song != "":
		MusicPlayer.play_song(self, music_song)
	pages = StoryPages.get_story(story_name)
	if pages.is_empty():
		_finish()
		return
	_show_page(0)


func _process(delta: float) -> void:
	_age += delta
	_page_age += delta
	if is_finished:
		return
	_wobble()
	if _age < input_delay:
		return
	# Hold jump to skip everything.
	if Input.is_action_pressed(jump_action):
		_held += delta
		if _held >= skip_hold_time:
			_finish()
			return
	else:
		_held = 0.0
	if Input.is_action_just_pressed(jump_action):
		next_page()
	elif InputMap.has_action(back_action) and Input.is_action_just_pressed(back_action):
		previous_page()


## Turn back one page. Does nothing on the first page.
func previous_page() -> void:
	if is_finished or page_index <= 0:
		return
	_show_page(page_index - 1)


## Turn the page, or finish if that was the last one.
func next_page() -> void:
	if is_finished:
		return
	if page_index + 1 >= pages.size():
		_finish()
	else:
		_show_page(page_index + 1)


func _show_page(number: int) -> void:
	# The page-turn sound, whenever the page changes (not for the very first page).
	if number != page_index:
		Sfx.play(self, page_sound)
	page_index = number
	_page_age = 0.0
	var page: Dictionary = pages[number]
	caption.text = page["text"]
	var image_path: String = page.get("image", "")
	var texture: Texture2D = null
	if image_path != "" and ResourceLoader.exists(image_path):
		texture = load(image_path) as Texture2D
	picture.texture = texture
	picture.visible = texture != null
	var color: Color = page.get("color", Color.GRAY)
	card.set("color", color)


## Gentle wobble and slow zoom, plus a pop when the page is new.
func _wobble() -> void:
	card.pivot_offset = card.size * 0.5
	card.rotation_degrees = sin(_page_age * wobble_speed) * wobble_degrees
	var pop: float = clampf(_page_age / pop_time, 0.0, 1.0)
	var zoom: float = 1.0 + zoom_amount * (0.5 + 0.5 * sin(_page_age * wobble_speed * 0.5))
	card.scale = Vector2.ONE * zoom * lerpf(0.85, 1.0, pop)


func _finish() -> void:
	if is_finished:
		return
	is_finished = true
	finished.emit()
	if next_scene != "":
		get_tree().change_scene_to_file.call_deferred(next_scene)
