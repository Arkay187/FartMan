class_name PauseMenu
extends CanvasLayer
## The pause menu. Every stage gets one (Stage adds it). Built entirely in code.
## Esc, P or pad Start opens and closes it. Up/down picks, jump chooses.
## Left/right flips CONTROLS, GAS and MUSIC.

## Which choice is which.
const RESUME: int = 0
const CONTROLS: int = 1
const GAS: int = 2
const MUSIC: int = 3
const BACK: int = 4
## How many choices there are.
const CHOICES: int = 5

## Where BACK TO MENU goes (NEW GAME and TEST LEVELS live there).
@export_file("*.tscn") var menu_scene: String = "res://scenes/start_menu.tscn"
## Ignore accept / jump for this long after opening (pad Start is also "accept").
@export var input_delay: float = 0.25
@export var selected_color: Color = Color(1.0, 0.85, 0.1)
@export var plain_color: Color = Color(1.0, 1.0, 1.0)
## How dark the see-through backdrop is, 0 to 1.
@export var backdrop_darkness: float = 0.65
## Sounds for the menu (tick as you move, a ding when you choose, whoosh when it opens and closes).
## The Stage makes this menu in code, so empty ones are filled in from res://audio/sfx.
@export var move_sound: AudioStream
@export var accept_sound: AudioStream
@export var open_sound: AudioStream
@export var close_sound: AudioStream

var is_open: bool = false
var choice: int = 0
var _since_open: float = 0.0
var _root: Control
var _labels: Array[Label] = []
var _hint: Label
var _stage: Stage


func _ready() -> void:
	DebugOptionsData.ensure_input_actions()
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS
	_stage = get_parent() as Stage
	move_sound = move_sound if move_sound != null else Sfx.named("menu_move")
	accept_sound = accept_sound if accept_sound != null else Sfx.named("menu_accept")
	open_sound = open_sound if open_sound != null else Sfx.named("pause_open")
	close_sound = close_sound if close_sound != null else Sfx.named("pause_close")
	_build()
	_root.visible = false


## If the menu leaves the tree while open (scene change), never leave the game frozen.
func _exit_tree() -> void:
	if is_open and get_tree() != null:
		get_tree().paused = false
	is_open = false


func _process(delta: float) -> void:
	if Input.is_action_just_pressed(&"pause"):
		if is_open:
			close()
		else:
			open()
		return
	if not is_open:
		return
	_since_open += delta
	if Input.is_action_just_pressed(&"ui_down"):
		select((choice + 1) % CHOICES)
	elif Input.is_action_just_pressed(&"ui_up"):
		select((choice + CHOICES - 1) % CHOICES)
	elif Input.is_action_just_pressed(&"ui_left"):
		flip(-1)
	elif Input.is_action_just_pressed(&"ui_right"):
		flip(1)
	elif _since_open >= input_delay and (Input.is_action_just_pressed(&"jump") or Input.is_action_just_pressed(&"ui_accept")):
		choose()


## Shows the menu and freezes the game. Does nothing once the stage is cleared.
func open() -> void:
	if is_open or (_stage != null and _stage.is_cleared):
		return
	is_open = true
	_since_open = 0.0
	choice = RESUME
	get_tree().paused = true
	_root.visible = true
	_refresh()
	_tick(open_sound)


## Hides the menu and carries on.
func close() -> void:
	if not is_open:
		return
	is_open = false
	_root.visible = false
	get_tree().paused = false
	_tick(close_sound)


## Moves the highlight to this choice (0 RESUME, 1 CONTROLS, 2 GAS, 3 MUSIC, 4 BACK TO MENU).
func select(index: int) -> void:
	choice = clampi(index, 0, CHOICES - 1)
	_refresh()
	_tick(move_sound)


## Does what the highlighted choice says.
func choose() -> void:
	match choice:
		RESUME:
			close()
		CONTROLS, GAS, MUSIC:
			flip(1)
		BACK:
			_back_to_menu()


## Changes the highlighted setting (CONTROLS, GAS or MUSIC). Does nothing on the other choices.
func flip(step: int) -> void:
	var options := _options()
	if options == null:
		return
	if choice == CONTROLS:
		options.set_simple_controls(not options.simple_controls)
	elif choice == GAS:
		var count: int = DebugOptionsData.MODE_NAMES.size()
		options.set_gas_mode((options.gas_mode + step + count) % count)
	elif choice == MUSIC:
		options.set_music(not options.music_on)
	else:
		return
	_tick(accept_sound)
	_refresh()


func _tick(sound: AudioStream) -> void:
	Sfx.play(self, sound)


func _back_to_menu() -> void:
	var tree := get_tree()
	close()
	tree.change_scene_to_file(menu_scene)


func _options() -> DebugOptionsData:
	return get_node_or_null("/root/DebugOptions") as DebugOptionsData


## The text a choice shows right now (without the > < arrows).
func choice_text(index: int) -> String:
	var options := _options()
	match index:
		RESUME:
			return "RESUME"
		CONTROLS:
			var simple: bool = options != null and options.simple_controls
			return "CONTROLS: " + ("SIMPLE" if simple else "CLASSIC")
		GAS:
			var mode: int = options.gas_mode if options != null else 0
			return "GAS: " + DebugOptionsData.MODE_NAMES[mode]
		MUSIC:
			var on: bool = options == null or options.music_on
			return "MUSIC: " + ("ON" if on else "OFF")
	return "BACK TO MENU"


func _describe_controls() -> String:
	var options := _options()
	if options != null and options.simple_controls:
		return "JUMP TWICE TO FART-JUMP. HOLD HOVER (LB) TO FLOAT UP"
	return "HOLD FART, LET GO TO JUMP"


func _refresh() -> void:
	for i in _labels.size():
		var selected: bool = i == choice
		_labels[i].text = ("> %s <" if selected else "%s") % choice_text(i)
		_labels[i].add_theme_color_override("font_color", selected_color if selected else plain_color)
	_hint.text = _describe_controls()


func _build() -> void:
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.0, 0.0, 0.0, backdrop_darkness)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(backdrop)
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BOTH
	box.add_theme_constant_override("separation", 12)
	_root.add_child(box)
	box.add_child(_make_label(72, "PAUSED"))
	for i in CHOICES:
		var label := _make_label(52, "")
		box.add_child(label)
		_labels.append(label)
		if i == CONTROLS:
			_hint = _make_label(26, "")
			_hint.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
			box.add_child(_hint)


func _make_label(font_size: int, text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 8)
	return label
