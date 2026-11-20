extends ProgressBar
## The gas bar on screen. Shows how full Fart Man's tank is.

## Whose gas tank to show.
@export var player: Player


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


func _on_mode_changed(mode: int) -> void:
	var shown: bool = mode != DebugOptionsData.GasMode.NO_GAS
	visible = shown
	var label := get_parent().get_node_or_null("GasLabel") as CanvasItem
	if label != null:
		label.visible = shown


func _on_gas_changed(gas: float, max_gas: float) -> void:
	max_value = max_gas
	value = gas
