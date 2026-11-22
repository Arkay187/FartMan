extends SceneTree
# Checks the pause menu: opens and closes with the pause button, freezes the game, flips the
# control scheme and the gas mode, ignores the press that opened it, and BACK TO MENU goes to
# the start menu and leaves the game unpaused.

var failures: int = 0


func _initialize() -> void:
	_run()


# Counts screen frames (they keep ticking while the game is paused).
func _wait(seconds: float) -> void:
	for i in int(seconds * 60.0):
		await process_frame


func _check(label: String, ok: bool) -> void:
	print("%s: %s" % [label, "ok" if ok else "FAILED"])
	if not ok:
		failures += 1


func _press(action: StringName) -> void:
	Input.action_press(action)
	await _wait(0.1)
	Input.action_release(action)
	await _wait(0.1)


func _run() -> void:
	await _wait(0.1)  # let the autoloads start
	var save := root.get_node_or_null("SaveGame") as SaveData
	if save == null:
		save = SaveData.new()
		save.name = "SaveGame"
		root.add_child(save)
	save.use_file("user://test_pause_menu_save.json")
	save.reset()
	var options: DebugOptionsData = root.get_node("DebugOptions")
	options.set_simple_controls(false)
	options.set_gas_mode(DebugOptionsData.GasMode.NORMAL)

	_check("the pause button exists (Esc, P, Start)", InputMap.has_action(&"pause") and InputMap.action_get_events(&"pause").size() >= 3)
	_check("the hover button exists", InputMap.has_action(&"hover"))

	var stage: Stage = load("res://scenes/stage_1_1.tscn").instantiate()
	root.add_child(stage)
	await _wait(0.4)
	var menu: PauseMenu = null
	for child: Node in stage.get_children():
		if child is PauseMenu:
			menu = child
	_check("every stage has a pause menu", menu != null)
	if menu == null:
		quit()
		return
	_check("starts closed and running", not menu.is_open and not paused)

	await _press(&"pause")
	_check("pause opens it and freezes the game", menu.is_open and paused)
	_check("the menu keeps working while paused", menu.process_mode == Node.PROCESS_MODE_ALWAYS)

	# Jump right after opening must not pick RESUME (pad Start is also accept).
	await _press(&"jump")
	_check("jump straight after opening is ignored", menu.is_open and paused)

	await _press(&"pause")
	_check("pause again closes it and unfreezes", not menu.is_open and not paused)

	# Up and down.
	await _press(&"pause")
	await _wait(0.3)
	_check("opens on RESUME", menu.choice == PauseMenu.RESUME)
	await _press(&"ui_down")
	_check("down goes to CONTROLS", menu.choice == PauseMenu.CONTROLS)
	_check("it reads CONTROLS: CLASSIC", menu.choice_text(PauseMenu.CONTROLS) == "CONTROLS: CLASSIC")
	await _press(&"ui_up")
	await _press(&"ui_up")
	_check("up from RESUME wraps to BACK TO MENU", menu.choice == PauseMenu.BACK)
	await _press(&"ui_down")
	_check("down from BACK wraps to RESUME", menu.choice == PauseMenu.RESUME)

	# RESUME with the jump button.
	await _press(&"jump")
	_check("jump on RESUME closes it", not menu.is_open and not paused)

	# Controls toggle.
	await _press(&"pause")
	await _wait(0.3)
	menu.select(PauseMenu.CONTROLS)
	await _press(&"jump")
	_check("choosing CONTROLS switches to SIMPLE at once", options.simple_controls and menu.choice_text(PauseMenu.CONTROLS) == "CONTROLS: SIMPLE")
	await _press(&"ui_left")
	_check("left flips it back to CLASSIC", not options.simple_controls)
	await _press(&"ui_right")
	_check("right flips it to SIMPLE again", options.simple_controls)
	var heard: Array[bool] = []
	options.controls_changed.connect(func(s: bool) -> void: heard.append(s))
	menu.flip(1)
	_check("the change is announced (controls_changed)", heard == [false])
	options.set_simple_controls(false)

	# Gas cycle.
	menu.select(PauseMenu.GAS)
	await _press(&"jump")
	_check("choosing GAS cycles the gas mode (now %s)" % DebugOptionsData.MODE_NAMES[options.gas_mode], options.gas_mode == DebugOptionsData.GasMode.NO_GAS)
	await _press(&"ui_right")
	_check("right goes on to ALWAYS FULL", options.gas_mode == DebugOptionsData.GasMode.ALWAYS_FULL and menu.choice_text(PauseMenu.GAS) == "GAS: ALWAYS FULL")
	await _press(&"ui_left")
	await _press(&"ui_left")
	_check("left goes back round to NORMAL", options.gas_mode == DebugOptionsData.GasMode.NORMAL)

	# Not once the stage is cleared.
	menu.close()
	stage.is_cleared = true
	await _press(&"pause")
	_check("it does not open after the stage is cleared", not menu.is_open and not paused)
	stage.is_cleared = false

	# Back to the menu.
	await _press(&"pause")
	await _wait(0.3)
	menu.select(PauseMenu.BACK)
	await _press(&"jump")
	await _wait(0.5)
	var now: Node = current_scene
	_check("BACK TO MENU shows the start menu", now != null and now.scene_file_path == "res://scenes/start_menu.tscn")
	_check("and the game is not left paused", not paused)

	# Leaving the tree while open also unpauses.
	var stage2: Stage = load("res://scenes/stage_1_1.tscn").instantiate()
	root.add_child(stage2)
	await _wait(0.3)
	var menu2: PauseMenu = null
	for child: Node in stage2.get_children():
		if child is PauseMenu:
			menu2 = child
	menu2.open()
	_check("open() works from code", menu2.is_open and paused)
	stage2.queue_free()
	await _wait(0.3)
	_check("freeing a stage with the menu open unpauses", not paused)

	options.set_simple_controls(false)
	options.set_gas_mode(DebugOptionsData.GasMode.NORMAL)
	print("pause menu failures: %d" % failures)
	quit()
