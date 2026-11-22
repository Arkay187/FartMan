class_name DebugOptionsData
extends CanvasLayer
## Test switches for trying out ideas. Always running (autoload named DebugOptions).
##
## F1 (or the pad's Back / Select button) changes how gas works:
##   NORMAL       - the gas tank as designed: farts cost gas, it creeps back, beans fill it.
##   NO GAS       - no gas at all. The gas bar is hidden. Farts are free.
##   ALWAYS FULL  - the tank never goes down. The bar stays full.
##   FILL ON LAND - the tank fills right up every time his feet touch the ground.
## In NO GAS and ALWAYS FULL he gets only `air_farts_free_gas` farts per jump (see Player),
## otherwise he could fart his way up to the sky forever.
## F11 switches full screen on and off.
## The choice is remembered between games (not in headless test runs).

## Sent when the gas mode changes. The gas bar listens to this.
signal gas_mode_changed(mode: int)

## Sent when the control scheme changes (pause menu). true = SIMPLE, false = CLASSIC.
signal controls_changed(simple: bool)

## Sent when the music is switched on or off (pause menu). true = music on.
signal music_changed(on: bool)

## Sent when the UPGRADES setting changes (start menu). true = upgrades work in the stages.
signal upgrades_changed(on: bool)

enum GasMode { NORMAL, NO_GAS, ALWAYS_FULL, FILL_ON_LAND }
const MODE_NAMES: Array[String] = ["NORMAL", "NO GAS", "ALWAYS FULL", "FILL ON LAND"]

## Bumped when a setting's default changes. Saves without this number get the new default once.
## 2 = SIMPLE became the default control scheme.
const SETTINGS_VERSION: int = 2

## Where the switches are remembered.
@export var save_path: String = "user://debug_options.json"
## How long the "GAS: ..." message stays on screen after pressing F1.
@export var message_time: float = 2.0

var gas_mode: int = GasMode.NORMAL
## CLASSIC (false): hold fart to charge. SIMPLE (true, the default): double jump, and hover on gas.
var simple_controls: bool = true
## Music on (true) or off (false). The pause menu's MUSIC choice.
var music_on: bool = true
## UPGRADES ON (true) or OFF (false), the start menu's choice, for Dad. OFF = upgrades bought
## aboard the Complex2000 do nothing in the stages (the shop still works and keeps them).
var upgrades_on: bool = true
## Only the music test sets this, to try saving and loading with a throw-away file.
var test_saving: bool = false
var _message: Label
var _corner: Label
var _message_left: float = 0.0


func _ready() -> void:
	ensure_input_actions()
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_message = _make_label(48, Control.PRESET_CENTER)
	_corner = _make_label(18, Control.PRESET_BOTTOM_LEFT)
	_corner.position = Vector2(12, -36)
	_load()
	_refresh()


func _process(delta: float) -> void:
	if _message_left > 0.0:
		_message_left -= delta
		_message.modulate.a = clampf(_message_left / 0.4, 0.0, 1.0)


func _input(event: InputEvent) -> void:
	var cycle: bool = false
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_F1:
			cycle = true
		elif event.physical_keycode == KEY_F11:
			_toggle_fullscreen()
	elif event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_BACK:
		cycle = true
	if cycle:
		set_gas_mode((gas_mode + 1) % MODE_NAMES.size())


## Changes the gas mode, shows it on screen and remembers it.
func set_gas_mode(mode: int) -> void:
	gas_mode = mode
	_message.text = "GAS: " + MODE_NAMES[mode]
	_message_left = message_time
	_refresh()
	_store()
	gas_mode_changed.emit(mode)


## Switches between CLASSIC (false) and SIMPLE (true) controls and remembers it.
func set_simple_controls(on: bool) -> void:
	simple_controls = on
	_store()
	controls_changed.emit(on)


## Turns the music on (true) or off (false) and remembers it.
func set_music(on: bool) -> void:
	music_on = on
	_store()
	music_changed.emit(on)


## Turns the upgrades on (true) or off (false) and remembers it.
func set_upgrades_on(on: bool) -> void:
	upgrades_on = on
	_store()
	upgrades_changed.emit(on)


## Makes sure the `pause`, `hover` and `fire` buttons exist, even if project.godot lost them
## (the editor can rewrite that file). Safe to call any time.
static func ensure_input_actions() -> void:
	_ensure_action(&"pause", [_key(KEY_ESCAPE), _key(KEY_P), _pad(JOY_BUTTON_START)])
	_ensure_action(&"hover", [_key(KEY_SHIFT), _key(KEY_X), _pad(JOY_BUTTON_LEFT_SHOULDER)])
	_ensure_action(&"fire", [_key(KEY_C), _pad(JOY_BUTTON_B)])
	# Pad B is only the fire button: it must never fart or jump as well (or every fireball
	# would jump too). Older copies of project.godot had B on fart.
	_take_pad_button_off(&"fart", JOY_BUTTON_B)
	_take_pad_button_off(&"jump", JOY_BUTTON_B)


static func _take_pad_button_off(action: StringName, button: JoyButton) -> void:
	if not InputMap.has_action(action):
		return
	for event: InputEvent in InputMap.action_get_events(action):
		var pad := event as InputEventJoypadButton
		if pad != null and pad.button_index == button:
			InputMap.action_erase_event(action, event)


static func _ensure_action(action: StringName, events: Array[InputEvent]) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action)
	for event: InputEvent in events:
		InputMap.action_add_event(action, event)


static func _key(code: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = code
	return event


static func _pad(button: JoyButton) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.button_index = button
	return event


## True in any mode that changes the normal gas rules.
func gas_is_free() -> bool:
	return gas_mode != GasMode.NORMAL


## True when farts never use up gas at all (NO GAS and ALWAYS FULL).
## FILL ON LAND still spends gas in the air, so the tank itself limits air farts there.
func farts_are_free() -> bool:
	return gas_mode == GasMode.NO_GAS or gas_mode == GasMode.ALWAYS_FULL


func _refresh() -> void:
	_corner.text = "" if gas_mode == GasMode.NORMAL else "GAS: %s  (F1 to change)" % MODE_NAMES[gas_mode]


func _toggle_fullscreen() -> void:
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


func _make_label(font_size: int, preset: Control.LayoutPreset) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 8)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.set_anchors_and_offsets_preset(preset)
	label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	label.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(label)
	return label


# Headless test runs never read or write the file, so tests always start on NORMAL.
func _headless() -> bool:
	return DisplayServer.get_name() == "headless" and not test_saving


func _load() -> void:
	if _headless() or not FileAccess.file_exists(save_path):
		return
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(save_path))
	if data is Dictionary:
		gas_mode = clampi(int(data.get("gas_mode", 0)), 0, MODE_NAMES.size() - 1)
		music_on = bool(data.get("music_on", true))
		upgrades_on = bool(data.get("upgrades_on", true))
		if int(data.get("settings_version", 1)) < SETTINGS_VERSION:
			# An old save: its "CLASSIC" only meant "the old default". Switch to SIMPLE once.
			simple_controls = true
			_store()
		else:
			simple_controls = bool(data.get("simple_controls", true))


func _store() -> void:
	if _headless():
		return
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({"settings_version": SETTINGS_VERSION, "gas_mode": gas_mode, "simple_controls": simple_controls, "music_on": music_on,
			"upgrades_on": upgrades_on}))
