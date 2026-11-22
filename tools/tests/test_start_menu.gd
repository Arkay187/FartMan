extends SceneTree
# Checks the start menu: no save = only NEW GAME; a save = CONTINUE first, switch with
# down/up, NEW GAME asks twice before erasing, CONTINUE goes to the map.

var failures: int = 0


func _initialize() -> void:
	_run()


func _wait(seconds: float) -> void:
	for i in int(seconds * 60.0):
		await process_frame


func _check(label: String, ok: bool) -> void:
	print("%s: %s" % [label, "ok" if ok else "FAIL"])
	if not ok:
		failures += 1


func _press(action: StringName) -> void:
	Input.action_press(action)
	await _wait(0.1)
	Input.action_release(action)
	await _wait(0.2)


func _menu() -> StartMenu:
	var menu: StartMenu = load("res://scenes/start_menu.tscn").instantiate()
	root.add_child(menu)
	await _wait(0.5)
	return menu


func _run() -> void:
	var save: Node = root.get_node_or_null("SaveGame")
	if save == null:
		save = SaveData.new()
		save.name = "SaveGame"
		root.add_child(save)
	save.use_file("user://test_start_menu_save.json")
	save.reset()

	# No saved game: CONTINUE is hidden, NEW GAME is picked.
	var menu: StartMenu = await _menu()
	_check("fresh start: CONTINUE hidden, NEW GAME picked", not menu.continue_label.visible and menu.choice == 1)
	menu.queue_free()
	await _wait(0.2)

	# With a save: CONTINUE shows and is picked first.
	save.record_stage("1-1", 1, 500)
	menu = await _menu()
	_check("with a save: CONTINUE shown and picked", menu.continue_label.visible and menu.choice == 0)
	await _press(&"ui_down")
	_check("down picks NEW GAME", menu.choice == 1)
	await _press(&"ui_up")
	_check("up picks CONTINUE again", menu.choice == 0)

	# UPGRADES: ON / OFF sits between NEW GAME and TEST LEVELS.
	var options: DebugOptionsData = root.get_node("DebugOptions")
	options.set_upgrades_on(true)
	menu._refresh()
	_check("the menu has an UPGRADES row ('%s')" % menu.upgrades_label.text, menu.upgrades_label != null and menu.upgrades_label.visible)
	await _press(&"ui_down")
	await _press(&"ui_down")
	_check("down twice picks UPGRADES (after NEW GAME)", menu.choice == 3 and menu.upgrades_label.text == "> UPGRADES: ON <")
	await _press(&"ui_accept")
	_check("jump flips it OFF ('%s'), remembered by the options" % menu.upgrades_label.text,
		not options.upgrades_on and menu.upgrades_label.text == "> UPGRADES: OFF <" and menu.choice == 3)
	await _press(&"ui_right")
	_check("right flips it back ON", options.upgrades_on and menu.upgrades_label.text == "> UPGRADES: ON <")
	await _press(&"ui_left")
	_check("left flips it OFF", not options.upgrades_on)
	_check("flipping does not leave the menu or touch the save", menu.is_inside_tree() and save.is_cleared("1-1"))
	await _press(&"ui_down")
	_check("down from UPGRADES picks TEST LEVELS", menu.choice == 2)
	await _press(&"ui_up")
	await _press(&"ui_up")
	_check("up twice is NEW GAME again", menu.choice == 1)
	await _press(&"ui_up")
	options.set_upgrades_on(true)
	_check("and up once more is CONTINUE", menu.choice == 0)

	# NEW GAME asks twice and keeps the save after the first press.
	await _press(&"ui_down")
	await _press(&"ui_accept")
	_check("first NEW GAME press only warns (hint '%s'), save kept" % menu.hint_label.text,
		menu.hint_label.text != "" and save.is_cleared("1-1"))
	menu.queue_free()
	await _wait(0.2)

	# CONTINUE heads for the world map and keeps the save.
	menu = await _menu()
	await _press(&"ui_accept")
	await _wait(0.5)
	var scene_name: String = current_scene.name if current_scene != null else "none"
	_check("CONTINUE opens the world map (now '%s'), save kept" % scene_name, scene_name == "WorldMap" and save.is_cleared("1-1"))

	# A second press on NEW GAME erases and starts the story.
	if current_scene != null:
		current_scene.queue_free()
		current_scene = null
	await _wait(0.2)
	menu = await _menu()
	await _press(&"ui_down")
	await _press(&"ui_accept")
	await _press(&"ui_accept")
	await _wait(0.5)
	scene_name = current_scene.name if current_scene != null else "none"
	_check("second NEW GAME press erases and opens the story (now '%s', cleared %s)" % [scene_name, str(save.is_cleared("1-1"))],
		scene_name == "Storybook" and not save.is_cleared("1-1"))

	save.reset()
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://test_start_menu_save.json"))
	print("start menu failures: %d" % failures)
	quit()
