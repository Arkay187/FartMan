extends SceneTree
# Checks the F1 test switches for gas: NORMAL, NO GAS, ALWAYS FULL, FILL ON LAND,
# and the one-fart-per-jump limit when gas is free.


func _initialize() -> void:
	var level: Node = load("res://scenes/test_level.tscn").instantiate()
	root.add_child(level)
	_run(level)


func _wait(seconds: float) -> void:
	for i in int(seconds * 60.0):
		await physics_frame


func _fart(hold: float) -> void:
	Input.action_press(&"fart")
	await _wait(hold)
	Input.action_release(&"fart")
	await _wait(0.05)


func _run(level: Node) -> void:
	var options: DebugOptionsData = root.get_node_or_null("DebugOptions")
	print("debug options autoload found: %s, starts on %s" % [options != null, DebugOptionsData.MODE_NAMES[options.gas_mode]])
	var player: Player = level.get_node("Player")
	var tank: GasTank = player.get_node("GasTank")
	var bar: Control = level.get_node("HUD/GasBar")
	var farts: Array[String] = []
	player.farted.connect(func(n: String) -> void: farts.append(n))
	var fizzles: Array[int] = [0]
	player.fizzled.connect(func() -> void: fizzles[0] += 1)
	await _wait(0.5)

	# NORMAL: a Thunder costs gas.
	await _fart(0.6)
	print("NORMAL: thunder -> gas=%.0f (should be 65)" % tank.gas)
	await _wait(2.0)

	# ALWAYS FULL: Thunder costs nothing, the bar stays full.
	options.set_gas_mode(DebugOptionsData.GasMode.ALWAYS_FULL)
	tank.drain(50.0)
	await _wait(0.1)
	print("ALWAYS FULL: after draining 50 -> gas=%.0f (should be 100)" % tank.gas)
	await _fart(0.6)
	print("ALWAYS FULL: thunder -> gas=%.0f (should be 100), bar visible=%s" % [tank.gas, bar.visible])
	# In the air: one fart allowed, the second fizzles. Air fart from a fresh jump.
	await _wait(2.5)
	farts.clear()
	fizzles[0] = 0
	Input.action_press(&"jump")
	await _wait(0.1)
	Input.action_release(&"jump")
	await _fart(0.3)
	await _fart(0.3)
	print("ALWAYS FULL: hop then two air farts -> farts=%s fizzles=%d (should be [Toot, Trump] and 1)" % [str(farts), fizzles[0]])
	await _wait(2.5)
	print("ALWAYS FULL: landed again, air farts used reset to %d" % player.air_farts_used)

	# NO GAS: bar and label hidden.
	options.set_gas_mode(DebugOptionsData.GasMode.NO_GAS)
	await _wait(0.1)
	print("NO GAS: bar visible=%s label visible=%s (both false)" % [bar.visible, level.get_node("HUD/GasLabel").visible])

	# FILL ON LAND: costs gas in the air, fills up again on the ground.
	options.set_gas_mode(DebugOptionsData.GasMode.FILL_ON_LAND)
	await _wait(0.1)
	print("FILL ON LAND: bar visible=%s (true)" % bar.visible)
	await _fart(0.6)
	await _wait(0.2)
	var in_air: float = tank.gas
	var air_y: float = player.global_position.y
	await _wait(2.5)
	print("FILL ON LAND: thunder in the air gas=%.0f at y=%.1f, after landing gas=%.0f on floor=%s (65, then 100)" % [in_air, air_y, tank.gas, player.is_on_floor()])
	# Two Thunders in the air are allowed here: the tank is the limit.
	farts.clear()
	Input.action_press(&"jump")
	await _wait(0.1)
	Input.action_release(&"jump")
	await _fart(0.6)
	await _fart(0.6)
	print("FILL ON LAND: hop + two air Thunders -> farts=%s gas=%.0f (Toot, Thunder, Thunder; 30)" % [str(farts), tank.gas])
	await _wait(3.0)
	print("FILL ON LAND: landed -> gas=%.0f (100)" % tank.gas)

	options.set_gas_mode(DebugOptionsData.GasMode.NORMAL)
	await _wait(0.1)
	print("back to NORMAL: bar visible=%s corner text='%s'" % [bar.visible, options._corner.text])
	quit()
