extends SceneTree
# Checks the Complex2000 hub: Fart Man walks past four counters with fake key presses, Grandma pops up,
# the shop opens (and he does not hop), buying spends exactly the price through the save, OWNED and
# NOT ENOUGH, back closes it, the hatch leads to the map over the stop he boarded from, and the real
# map's Y button goes aboard.

const SAVE_FILE: String = "user://test_ship_hub_save.json"
var failures: int = 0
var save: SaveData
var options: DebugOptionsData
var hub: ShipHub
var p: Player
var panel: ShopPanel
var lowest_jar: int = 0


func _initialize() -> void:
	_run()


func _wait(seconds: float) -> void:
	for i in int(seconds * 60.0):
		await physics_frame


func _check(label: String, ok: bool) -> void:
	print("%s: %s" % [label, "ok" if ok else "FAILED"])
	if not ok:
		failures += 1


# Press a button for a moment, then let go and wait a little.
func _press(action: StringName, hold: float = 0.1) -> void:
	Input.action_press(action)
	await _wait(hold)
	Input.action_release(action)
	await _wait(0.2)
	lowest_jar = mini(lowest_jar, save.bean_jar)


func _fake_key(code: Key) -> void:
	for down: bool in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = down
		Input.parse_input_event(event)
		await _wait(0.1)


# Walk right until he stands at this counter, then stop.
func _walk_to(counter: ShopCounter) -> void:
	Input.action_press(&"ui_right")
	var waited: float = 0.0
	while counter.player != p and waited < 12.0:
		await _wait(0.1)
		waited += 0.1
	Input.action_release(&"ui_right")
	await _wait(0.6)


func _load_hub() -> void:
	hub = (load("res://scenes/ship_hub.tscn") as PackedScene).instantiate() as ShipHub
	root.add_child(hub)
	current_scene = hub
	p = hub.player
	panel = hub.panel
	await _wait(0.6)


# The text of a row's price ("150", "OWNED").
func _price(row: int) -> String:
	return (panel.rows[row]["price_label"] as Label).text


func _run() -> void:
	save = root.get_node_or_null("SaveGame") as SaveData
	if save == null:
		save = SaveData.new()
		save.name = "SaveGame"
		root.add_child(save)
	save.use_file(SAVE_FILE)
	save.reset()
	options = root.get_node("DebugOptions")
	options.set_simple_controls(true)
	save.set_last_stop("1-3")

	# ---------------------------------------------------------------- the hub loads
	await _load_hub()
	_check("the hub loads with Fart Man and a camera that follows him", p != null and hub.camera != null and hub.camera.get("target") == p)
	var counters: Array[ShopCounter] = hub.counters()
	var in_order: bool = counters.size() == UpgradeTable.ROOMS.size()
	for i in counters.size():
		in_order = in_order and counters[i].room_id == UpgradeTable.ROOMS[i]["id"] and (i == 0 or counters[i].position.x > counters[i - 1].position.x)
	_check("four counters, in room order (kitchen, gym, lab, garage)", in_order)
	var grandmas_ok: bool = true
	for counter: ShopCounter in counters:
		grandmas_ok = grandmas_ok and counter.grandma != null and counter.grandma.is_hidden_away() and counter.panel == panel
	_check("a Grandma hides behind every counter", grandmas_ok)
	_check("there is an airlock hatch at the left end", hub.hatch != null and hub.hatch.global_position.x < counters[0].global_position.x)
	_check("the Bean Jar total is on screen ('%s')" % hub.jar_label.label.text, hub.jar_label.label.text == "BEAN JAR 0")
	var song: MusicPlayer = MusicPlayer.current(hub)
	_check("calm, slower music", song != null and absf(song.speed - hub.music_speed) < 0.001 and hub.music_speed < 1.0)
	_check("the shop is closed to begin with", not panel.is_open and not p.input_locked)
	_check("solid walls at both ends", hub.get_node("WallLeft") is StaticBody3D and hub.get_node("WallRight") is StaticBody3D)

	# ---------------------------------------------------------------- the Kitchen (SIMPLE controls)
	var kitchen: ShopCounter = hub.counter_for("kitchen")
	await _walk_to(kitchen)
	_check("he is at the kitchen counter and the hint shows", kitchen.player == p and kitchen.hint.visible)
	var y0: float = p.global_position.y
	Input.action_press(&"jump")
	await _wait(0.12)
	var hop: float = p.global_position.y - y0
	Input.action_release(&"jump")
	_check("jump opens the shop", panel.is_open and kitchen.is_open and panel.room_id == "kitchen")
	_check("he did not hop (rose %.2f m)" % hop, hop < 0.1 and p.is_on_floor())
	_check("he is input-locked", p.input_locked)
	_check("the kitchen shows its 4 upgrades", panel.ids() == ["bigger_belly", "extra_heart", "big_hearts", "sticky_beans"])
	await _wait(0.6)
	_check("Grandma popped up", kitchen.grandma.is_fully_up())
	_check("the hint is hidden while shopping", not kitchen.hint.visible)
	_check("the camera slid to make room for the shop", (hub.camera.get("offset") as Vector3).x > 1.0)
	_check("Grandma says OOOH! 150 BEANS? ('%s')" % panel.grandma_label.text, panel.grandma_label.text == "OOOH! 150 BEANS?")

	# Empty jar.
	_check("empty jar: NEED 150 MORE ('%s')" % panel.need_label.text, panel.need_box.visible and panel.need_label.text == "NEED 150 MORE")
	_check("the jar picture is empty", panel.jar_picture.fill == 0.0)
	await _press(&"jump")
	_check("jump with an empty jar buys nothing, the jar stays 0 (%d)" % save.bean_jar, save.bean_jar == 0 and save.upgrade_level("bigger_belly") == 0)
	_check("Grandma says NOT ENOUGH! ('%s')" % panel.grandma_label.text, panel.grandma_label.text == "NOT ENOUGH!")

	# Buying.
	save.bank_beans(1000)
	await _wait(0.2)
	_check("the jar total follows the save ('%s')" % hub.jar_label.label.text, hub.jar_label.label.text == "BEAN JAR 1,000")
	_check("the need line is gone, the jar is full towards the price", not panel.need_box.visible and panel.jar_picture.fill == 1.0)
	Sfx.played.clear()
	await _press(&"jump")
	_check("jump bought Bigger Belly 1: jar dropped by exactly 150 (%d)" % save.bean_jar, save.bean_jar == 850 and save.upgrade_level("bigger_belly") == 1)
	_check("one dot is filled", panel.filled_dots(0) == 1)
	_check("cha-ching and a toot played", Sfx.played.has("cha_ching.wav") and Sfx.played.has("fart_1.wav"))
	_check("Grandma says YUM! ('%s')" % panel.grandma_label.text, panel.grandma_label.text == "YUM!")
	_check("the jar total went down ('%s')" % hub.jar_label.label.text, hub.jar_label.label.text == "BEAN JAR 850")
	await _press(&"ui_down")
	_check("down picks the next row", panel.selected == 1 and panel.grandma_label.text == "OOOH! 250 BEANS?")
	await _press(&"jump")
	_check("bought Extra Heart: jar 600, level 1", save.bean_jar == 600 and save.upgrade_level("extra_heart") == 1 and panel.filled_dots(1) == 1)
	await _press(&"ui_down")
	await _press(&"jump")
	_check("bought Big Hearts (300): jar 300", save.bean_jar == 300 and save.upgrade_level("big_hearts") == 1)
	_check("it now says OWNED ('%s')" % _price(2), _price(2) == "OWNED" and panel.grandma_label.text == "YUM!")
	await _press(&"jump")
	_check("buying a fully bought one spends nothing (jar %d)" % save.bean_jar, save.bean_jar == 300 and save.upgrade_level("big_hearts") == 1)
	_check("Grandma says OWNED! ('%s')" % panel.grandma_label.text, panel.grandma_label.text == "OWNED!")
	await _press(&"ui_down")
	await _press(&"jump")
	_check("bought Sticky Beans (250): jar 50", save.bean_jar == 50 and save.upgrade_level("sticky_beans") == 1)
	await _press(&"ui_down")
	_check("down from the last row wraps to the first", panel.selected == 0)
	_check("Bigger Belly 2 costs 400: NEED 350 MORE ('%s'), jar shows how full" % panel.need_label.text,
		panel.need_label.text == "NEED 350 MORE" and absf(panel.jar_picture.fill - 50.0 / 400.0) < 0.001)
	await _press(&"jump")
	_check("too poor: nothing spent (jar %d), level still 1" % save.bean_jar, save.bean_jar == 50 and save.upgrade_level("bigger_belly") == 1)
	await _press(&"ui_up")
	_check("up from the first row wraps to the last", panel.selected == 3)

	# Back.
	await _press(&"pause")
	_check("back closes the shop", not panel.is_open and not kitchen.is_open)
	await _wait(0.6)
	_check("Grandma ducked", kitchen.grandma.is_hidden_away())
	_check("he can move again", not p.input_locked)
	var x0: float = p.global_position.x
	Input.action_press(&"ui_right")
	await _wait(0.4)
	Input.action_release(&"ui_right")
	_check("and walk (%.1f m)" % (p.global_position.x - x0), p.global_position.x > x0 + 0.5)
	_check("the camera came back", absf((hub.camera.get("offset") as Vector3).x) < 0.01)

	# ---------------------------------------------------------------- saved upgrades survive a reload
	save.load_game()
	_check("bought upgrades are still there after reloading the save",
		save.upgrade_level("bigger_belly") == 1 and save.upgrade_level("extra_heart") == 1 and save.upgrade_level("big_hearts") == 1
		and save.upgrade_level("sticky_beans") == 1 and save.bean_jar == 50)

	# ---------------------------------------------------------------- the other rooms (CLASSIC controls)
	options.set_simple_controls(false)
	var rooms: Array[String] = ["gym", "lab", "garage"]
	var opens: Array[StringName] = [&"jump", &"ui_up", &"jump"]
	var backs: Array[StringName] = [&"ui_cancel", &"pause", &"pause"]
	for i in rooms.size():
		var counter: ShopCounter = hub.counter_for(rooms[i])
		await _walk_to(counter)
		y0 = p.global_position.y
		Input.action_press(opens[i])
		await _wait(0.12)
		hop = p.global_position.y - y0
		Input.action_release(opens[i])
		await _wait(0.2)
		var wanted: Array[String] = []
		for upgrade: Dictionary in UpgradeTable.in_room(rooms[i]):
			wanted.append(upgrade["id"])
		_check("%s: %s opens the shop with its %d upgrades" % [rooms[i], opens[i], wanted.size()],
			panel.is_open and panel.room_id == rooms[i] and panel.ids() == wanted)
		_check("%s: no hop (%.2f m) and he is locked" % [rooms[i], hop], hop < 0.1 and p.input_locked)
		await _wait(0.5)
		_check("%s: Grandma popped up" % rooms[i], counter.grandma.is_fully_up())
		await _press(backs[i])
		await _wait(0.5)
		_check("%s: %s closes it, Grandma ducks, he is free" % [rooms[i], backs[i]],
			not panel.is_open and counter.grandma.is_hidden_away() and not p.input_locked)
	_check("only buying ever spent beans (jar %d, lowest %d)" % [save.bean_jar, lowest_jar], save.bean_jar == 50 and lowest_jar >= 0)

	# ---------------------------------------------------------------- the hatch leads back to the map
	p.global_position = Vector3(9.0, 1.2, 0.0)
	p.velocity = Vector3.ZERO
	await _wait(0.5)
	Input.action_press(&"ui_left")
	var waited: float = 0.0
	while current_scene == hub and waited < 8.0:
		await _wait(0.1)
		waited += 0.1
	Input.action_release(&"ui_left")
	await _wait(0.5)
	var map := current_scene as WorldMap
	_check("walking into the hatch goes back to the world map", map != null and map.scene_file_path == "res://scenes/world_map.tscn")
	_check("over the stop he boarded from (1-3)", map != null and MapStops.STOPS[map.index]["id"] == "1-3")

	# ---------------------------------------------------------------- the real map: Y goes aboard
	_check("the GO ABOARD hint shows on the map", map.hub_hint.visible)
	map.move(1)
	await _wait(2.0)
	var stop_id: String = MapStops.STOPS[map.index]["id"]
	await _fake_key(KEY_Y)
	await _wait(0.5)
	hub = current_scene as ShipHub
	_check("a fake Y press goes aboard: the scene is the hub", hub != null and save.last_stop == stop_id)
	p = hub.player
	p.global_position = Vector3(9.0, 1.2, 0.0)
	await _wait(0.5)
	Input.action_press(&"ui_left")
	waited = 0.0
	while current_scene == hub and waited < 8.0:
		await _wait(0.1)
		waited += 0.1
	Input.action_release(&"ui_left")
	await _wait(0.5)
	map = current_scene as WorldMap
	_check("leaving comes back to the same stop (%s)" % stop_id, map != null and MapStops.STOPS[map.index]["id"] == stop_id)

	options.set_simple_controls(true)
	save.reset()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_FILE))
	print("ship hub failures: %d" % failures)
	quit()
