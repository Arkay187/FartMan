extends ProgressBar
## The gas bar on screen. Shows how full Fart Man's tank is.
## While he hovers it also shows how much hover is left: the tank in NORMAL mode, or the
## time left in the free-gas test modes (where the bar is shown just for the hover).

## Whose gas tank to show.
@export var player: Player

## The bar's normal visibility for the current gas mode (hidden in NO GAS).
var _mode_shows_bar: bool = true
## True while the bar is showing hover time instead of the tank.
var _showing_time: bool = false


func _ready() -> void:
	if player == null or player.gas_tank == null:
		return
	var tank: GasTank = player.gas_tank
	tank.gas_changed.connect(_on_gas_changed)
	_on_gas_changed(tank.gas, tank.max_gas)
	# NO GAS test mode (F1) hides the bar and its label.
	var options := get_node_or_null("/root/DebugOptions") as DebugOptionsData
	if options != null:
		options.gas_mode_changed.connect(_on_mode_changed)
		_on_mode_changed(options.gas_mode)
	_connect_hover.call_deferred()


## The player builds its hover helper in its own _ready, so look for it a moment later.
func _connect_hover() -> void:
	if player != null and player.hover_helper != null:
		player.hover_helper.fuel_changed.connect(_on_hover_fuel)


func _on_mode_changed(mode: int) -> void:
	_mode_shows_bar = mode != DebugOptionsData.GasMode.NO_GAS
	_show(_mode_shows_bar or _showing_time)


func _show(shown: bool) -> void:
	visible = shown
	var label := get_parent().get_node_or_null("GasLabel") as CanvasItem
	if label != null:
		label.visible = shown


func _on_gas_changed(gas: float, max_gas: float) -> void:
	max_value = max_gas
	if not _showing_time:
		value = gas


## The hover reports how much is left. In the timed modes the bar shows that time.
func _on_hover_fuel(fraction: float, active: bool, timed: bool) -> void:
	if active and timed:
		_showing_time = true
		value = fraction * max_value
		_show(true)
	elif _showing_time:
		# The hover is over: back to the tank, and hidden again if the mode hides the bar.
		_showing_time = false
		value = player.gas_tank.gas
		_show(_mode_shows_bar)
