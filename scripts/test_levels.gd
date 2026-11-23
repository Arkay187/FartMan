class_name TestLevels
extends Control
## A tiny list of test levels (reached from TEST LEVELS on the start menu).
## Up/down picks a row, jump (or Start) opens it. The last row, BACK, goes to the start menu,
## and so does the back button (pad B, Esc or Backspace).

## One label per row. The last one is BACK.
@export var rows: Array[Label] = []
## The scene each row opens. The BACK row has no scene (use back_scene).
@export var scenes: Array[String] = []
## The words shown for each row (without the arrows).
@export var titles: Array[String] = []
## A line about the highlighted row, shown near the bottom.
@export var descriptions: Array[String] = []
@export var description_label: Label
@export_file("*.tscn") var back_scene: String = "res://scenes/start_menu.tscn"
## The song that plays here (empty = none), and the sounds for moving and choosing.
@export var music_song: String = "theme"
@export var move_sound: AudioStream
@export var accept_sound: AudioStream
## Ignore buttons for this long after the list appears.
@export var input_delay: float = 0.3
@export var up_action: StringName = &"ui_up"
@export var down_action: StringName = &"ui_down"
@export var accept_action: StringName = &"ui_accept"
## Goes back to the start menu. "back" is pad B, Esc and Backspace (see DebugOptionsData).
@export var cancel_action: StringName = &"back"
@export var selected_color: Color = Color(1.0, 0.85, 0.1)
@export var plain_color: Color = Color(1.0, 1.0, 1.0)

## The World 3 stages, added to the list in code (title, scene, a line about it).
const WORLD3: Array[Array] = [
	["3-1  THE CLOUD TOPS", "res://scenes/stage_3_1.tscn", "Planet Whiff: squishy clouds, Burp Bubbles, gas geysers and Whifflers."],
	["3-2  THE FIZZY FORTRESS", "res://scenes/stage_3_2.tscn", "Everything from the whole game, mixed up. The hardest running stage."],
	["3-3  THE STINK STORM", "res://scenes/stage_3_3.tscn", "A short flight through lightning, jellyfish and two big speed boosts."],
	["3-4  BIG BAD BURP", "res://scenes/stage_3_4.tscn", "The final boss, in two parts, and then the ending story."],
]

var choice: int = 0
var _age: float = 0.0


func _tick(sound: AudioStream) -> void:
	Sfx.play(self, sound)


func _ready() -> void:
	DebugOptionsData.ensure_input_actions()
	if music_song != "":
		MusicPlayer.play_song(self, music_song)
	_add_world3_rows()
	_refresh()


## Puts the four World 3 stages in the list, just before BACK, and squeezes the rows to fit.
func _add_world3_rows() -> void:
	if rows.is_empty() or scenes.has(WORLD3[0][1]):
		return
	var back_at: int = rows.size() - 1
	for i in WORLD3.size():
		var row: Label = rows[0].duplicate() as Label
		row.name = "World3Row%d" % i
		rows[0].get_parent().add_child(row)
		rows.insert(back_at + i, row)
		titles.insert(back_at + i, WORLD3[i][0])
		scenes.insert(back_at + i, WORLD3[i][1])
		descriptions.insert(back_at + i, WORLD3[i][2])
	for i in rows.size():
		rows[i].add_theme_font_size_override("font_size", 44)
		rows[i].offset_top = -150.0 + float(i) * 56.0
		rows[i].offset_bottom = rows[i].offset_top + 56.0


func _process(delta: float) -> void:
	_age += delta
	if _age < input_delay:
		return
	if Input.is_action_just_pressed(down_action):
		choice = (choice + 1) % rows.size()
		_refresh()
		_tick(move_sound)
	elif Input.is_action_just_pressed(up_action):
		choice = (choice + rows.size() - 1) % rows.size()
		_refresh()
		_tick(move_sound)
	elif Input.is_action_just_pressed(accept_action):
		accept()
	elif InputMap.has_action(cancel_action) and Input.is_action_just_pressed(cancel_action):
		get_tree().change_scene_to_file(back_scene)


## Opens the highlighted row (or goes back if it is the last one).
func accept() -> void:
	_tick(accept_sound)
	if choice >= scenes.size() or scenes[choice] == "":
		get_tree().change_scene_to_file(back_scene)
	else:
		get_tree().change_scene_to_file(scenes[choice])


func _refresh() -> void:
	for i in rows.size():
		var selected: bool = i == choice
		var words: String = titles[i] if i < titles.size() else "?"
		rows[i].text = "> %s <" % words if selected else words
		rows[i].add_theme_color_override("font_color", selected_color if selected else plain_color)
	if description_label != null:
		description_label.text = descriptions[choice] if choice < descriptions.size() else ""
