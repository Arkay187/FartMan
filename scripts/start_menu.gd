class_name StartMenu
extends Control
## The start menu: CONTINUE (only if there is a saved game), NEW GAME, UPGRADES: ON / OFF and TEST LEVELS.
## Up/down picks, jump (or Start) chooses. NEW GAME asks twice if it would erase a save.

## The two choices, in the scene.
@export var continue_label: Label
@export var new_game_label: Label
## The TEST LEVELS choice (leave empty to hide it).
@export var test_levels_label: Label
## The "UPGRADES: ON / OFF" choice (leave empty to hide it). Jump or left/right flips it. It is for
## Dad: OFF means upgrades bought aboard the Complex2000 do nothing in the stages.
@export var upgrades_label: Label
## Small line at the bottom, used for "press again to erase".
@export var hint_label: Label
@export_file("*.tscn") var story_scene: String = "res://scenes/storybook.tscn"
@export_file("*.tscn") var map_scene: String = "res://scenes/world_map.tscn"
@export_file("*.tscn") var test_levels_scene: String = "res://scenes/test_levels.tscn"
## The song that plays here (empty = none). Menu sounds: moving the highlight, choosing.
@export var music_song: String = "theme"
@export var move_sound: AudioStream
@export var accept_sound: AudioStream
## The "seen it" flag for the opening story.
@export var seen_flag: String = "intro_story"
## Ignore buttons for this long after the menu appears.
@export var input_delay: float = 0.3
@export var up_action: StringName = &"ui_up"
@export var left_action: StringName = &"ui_left"
@export var right_action: StringName = &"ui_right"
@export var down_action: StringName = &"ui_down"
@export var accept_action: StringName = &"ui_accept"
@export var selected_color: Color = Color(1.0, 0.85, 0.1)
@export var plain_color: Color = Color(1.0, 1.0, 1.0)

## 0 = CONTINUE, 1 = NEW GAME, 2 = TEST LEVELS, 3 = UPGRADES (shown between NEW GAME and TEST LEVELS).
var choice: int = 0
var has_save: bool = false
var _age: float = 0.0
var _armed: bool = false
var _save: SaveData
var _options: DebugOptionsData


func _ready() -> void:
	_save = SaveLookup.find(self)
	_options = get_node_or_null("/root/DebugOptions") as DebugOptionsData
	has_save = _save != null and _save.has_progress()
	continue_label.visible = has_save
	if test_levels_label != null:
		test_levels_label.visible = true
	if upgrades_label != null:
		upgrades_label.visible = true
	choice = 0 if has_save else 1
	hint_label.text = ""
	_refresh()
	if music_song != "":
		MusicPlayer.play_song(self, music_song)


func _process(delta: float) -> void:
	_age += delta
	if _age < input_delay:
		return
	var step: int = 0
	if Input.is_action_just_pressed(down_action):
		step = 1
	elif Input.is_action_just_pressed(up_action):
		step = -1
	if step != 0:
		_move(step)
	elif choice == 3 and (Input.is_action_just_pressed(left_action) or Input.is_action_just_pressed(right_action)):
		flip_upgrades()
	elif Input.is_action_just_pressed(accept_action):
		accept()


## The choices that are on screen, top to bottom.
func _choices() -> Array[int]:
	var list: Array[int] = []
	if has_save:
		list.append(0)
	list.append(1)
	if upgrades_label != null:
		list.append(3)
	if test_levels_label != null:
		list.append(2)
	return list


## Moves the highlight up (-1) or down (1), wrapping round.
func _move(step: int) -> void:
	var list: Array[int] = _choices()
	if list.size() < 2:
		return
	var at: int = maxi(list.find(choice), 0)
	choice = list[(at + step + list.size()) % list.size()]
	_armed = false
	hint_label.text = ""
	_refresh()
	Sfx.play(self, move_sound)


## Does what the highlighted choice says.
func accept() -> void:
	if choice == 3 and upgrades_label != null:
		flip_upgrades()
		return
	Sfx.play(self, accept_sound)
	if choice == 2 and test_levels_label != null:
		get_tree().change_scene_to_file(test_levels_scene)
		return
	if choice == 0 and has_save:
		get_tree().change_scene_to_file(map_scene)
		return
	# NEW GAME. If a save exists, ask once more before erasing it.
	if has_save and not _armed:
		_armed = true
		hint_label.text = "THIS ERASES YOUR GAME! PRESS AGAIN"
		return
	if _save != null:
		_save.reset()
		_save.mark_seen(seen_flag)
	get_tree().change_scene_to_file(story_scene)


## Flips UPGRADES between ON and OFF (and so remembers it with the other options).
func flip_upgrades() -> void:
	if _options == null:
		return
	_options.set_upgrades_on(not _options.upgrades_on)
	Sfx.play(self, accept_sound)
	_refresh()


## True when upgrades are on (they are if the options are missing).
func upgrades_on() -> bool:
	return _options == null or _options.upgrades_on


func _refresh() -> void:
	_style(continue_label, "CONTINUE", choice == 0)
	_style(new_game_label, "NEW GAME", choice == 1)
	if test_levels_label != null:
		_style(test_levels_label, "TEST LEVELS", choice == 2)
	if upgrades_label != null:
		_style(upgrades_label, "UPGRADES: ON" if upgrades_on() else "UPGRADES: OFF", choice == 3)


func _style(label: Label, text: String, selected: bool) -> void:
	label.text = "> %s <" % text if selected else text
	label.add_theme_color_override("font_color", selected_color if selected else plain_color)
