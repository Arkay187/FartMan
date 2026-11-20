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

enum GasMode { NORMAL, NO_GAS, ALWAYS_FULL, FILL_ON_LAND }
const MODE_NAMES: Array[String] = ["NORMAL", "NO GAS", "ALWAYS FULL", "FILL ON LAND"]

## Where the switches are remembered.
@export var save_path: String = "user://debug_options.json"
## How long the "GAS: ..." message stays on screen after pressing F1.
@export var message_time: float = 2.0

var gas_mode: int = GasMode.NORMAL
var _message: Label
var _corner: Label
var _message_left: float = 0.0


func _ready() -> void:
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
	return DisplayServer.get_name() == "headless"


func _load() -> void:
	if _headless() or not FileAccess.file_exists(save_path):
		return
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(save_path))
	if data is Dictionary:
		gas_mode = clampi(int(data.get("gas_mode", 0)), 0, MODE_NAMES.size() - 1)


func _store() -> void:
	if _headless():
		return
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({"gas_mode": gas_mode}))
