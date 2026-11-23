extends SceneTree
# Checks the back button: a real pad B press (as a gamepad sends it) leaves the menus.
#   pause menu   B closes it and the game carries on, and B does not also shoot a fireball
#   TEST LEVELS  B goes back to the start menu (Esc too)
#   storybook    B turns back a page, and does nothing on the first page
# (Grandma's shop is checked in test_ship_hub.)

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
	await _wait(0.2)


# A real gamepad button press and release (as if from the first pad).
func _fake_pad(button: JoyButton) -> void:
	for down: bool in [true, false]:
		var event := InputEventJoypadButton.new()
		event.device = 0
		event.button_index = button
		event.pressed = down
		Input.parse_input_event(event)
		await _wait(0.1)
	await _wait(0.2)


func _fake_key(code: Key) -> void:
	for down: bool in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = down
		Input.parse_input_event(event)
		await _wait(0.1)
	await _wait(0.2)


func _run() -> void:
	await _wait(0.1)  # let the autoloads start
	var save := root.get_node_or_null("SaveGame") as SaveData
	if save == null:
		save = SaveData.new()
		save.name = "SaveGame"
		root.add_child(save)
	save.use_file("user://test_back_button_save.json")
	save.reset()

	_check("the back button exists and pad B is on it", InputMap.has_action(&"back") and _pad_b_is_back())

	# ---------------------------------------------------------------- the pause menu
	var stage: Stage = load("res://scenes/stage_1_1.tscn").instantiate()
	root.add_child(stage)
	current_scene = stage
	await _wait(0.5)
	var menu: PauseMenu = null
	for child: Node in stage.get_children():
		if child is PauseMenu:
			menu = child
	# He has the Fire Burp, so pad B would shoot a fireball while playing.
	stage.player.fire_burp.give(true)
	await _press(&"pause")
	_check("the pause menu is open and the game is frozen", menu != null and menu.is_open and paused)
	await _wait(0.3)
	await _fake_pad(JOY_BUTTON_B)
	await _wait(0.3)
	_check("pad B closes the pause menu and the game carries on", not menu.is_open and not paused)
	_check("and pad B did not shoot a fireball as well (%d)" % get_nodes_in_group(&"fireballs").size(),
		get_nodes_in_group(&"fireballs").is_empty())
	# Pad B still fires while playing (it is the fire button).
	await _fake_pad(JOY_BUTTON_B)
	_check("while playing, pad B is still the fire button (%d fireball)" % get_nodes_in_group(&"fireballs").size(),
		get_nodes_in_group(&"fireballs").size() == 1)
	stage.queue_free()
	await _wait(0.3)

	# ---------------------------------------------------------------- the TEST LEVELS list
	for way: String in ["pad B", "Esc"]:
		var list: TestLevels = load("res://scenes/test_levels.tscn").instantiate()
		root.add_child(list)
		current_scene = list
		await _wait(0.5)
		if way == "pad B":
			await _fake_pad(JOY_BUTTON_B)
		else:
			await _fake_key(KEY_ESCAPE)
		await _wait(0.3)
		var now: Node = current_scene
		_check("TEST LEVELS: %s goes back to the start menu (now '%s')" % [way, now.scene_file_path if now != null else "nothing"],
			now != null and now.scene_file_path == "res://scenes/start_menu.tscn")
		if now != null:
			now.queue_free()
		await _wait(0.2)

	# ---------------------------------------------------------------- the storybook
	var book: Storybook = load("res://scenes/storybook.tscn").instantiate()
	book.next_scene = ""  # stay put so the test can look around
	root.add_child(book)
	await _wait(0.5)
	var first: String = book.caption.text
	await _fake_pad(JOY_BUTTON_B)
	_check("storybook: pad B on the first page does nothing", book.page_index == 0 and not book.is_finished)
	await _press(&"ui_accept")
	await _press(&"ui_accept")
	_check("storybook: jump turns two pages (page %d)" % (book.page_index + 1), book.page_index == 2)
	await _fake_pad(JOY_BUTTON_B)
	_check("storybook: pad B turns back a page (page %d)" % (book.page_index + 1), book.page_index == 1)
	await _fake_pad(JOY_BUTTON_B)
	_check("storybook: and again, back to the first page ('%s')" % book.caption.text,
		book.page_index == 0 and book.caption.text == first and not book.is_finished)
	book.queue_free()
	await _wait(0.2)

	save.reset()
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://test_back_button_save.json"))
	print("back button failures: %d" % failures)
	quit()


func _pad_b_is_back() -> bool:
	var pad_b := InputEventJoypadButton.new()
	pad_b.button_index = JOY_BUTTON_B
	pad_b.pressed = true
	return InputMap.event_is_action(pad_b, &"back")
