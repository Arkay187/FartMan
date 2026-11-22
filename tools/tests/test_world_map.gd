extends SceneTree
# Checks the 3D world map: the ship hovers over a stop and flies to the next, where Fart Man
# may go, flags / Golden Bean pips / padlocks, the camera, COMING SOON, entering a stage.

const TEST_FILE: String = "user://test_world_map.json"
var _fails: int = 0


func _initialize() -> void:
	_run()


func _wait(seconds: float) -> void:
	for i in int(seconds * 60.0):
		await process_frame


# Fake a button press, then wait for the ship to settle.
func _press(action: StringName) -> void:
	Input.action_press(action)
	await _wait(0.1)
	Input.action_release(action)
	await _wait(1.6)


func _check(what: String, ok: bool) -> void:
	print("%s: %s" % ["ok  " if ok else "FAIL", what])
	if not ok:
		_fails += 1


func _id(map: WorldMap) -> String:
	return MapStops.STOPS[map.index]["id"]


# Is the ship straight above the middle of stop number i (to within a hand's width)?
func _above(map: WorldMap, i: int) -> bool:
	return map.ship.position.distance_to(map.stop_hover_position(i)) < 0.1


# Is a point on screen? Headless windows are square, so work out a 16:9 screen by hand.
func _in_view(cam: Camera3D, point: Vector3) -> bool:
	var local: Vector3 = cam.global_transform.affine_inverse() * point
	var depth: float = -local.z
	if depth <= 0.1:
		return false
	var half_h: float = depth * tan(deg_to_rad(cam.fov) * 0.5)
	var half_w: float = half_h * 16.0 / 9.0
	return absf(local.x) < half_w and absf(local.y) < half_h


func _flag_on(map: WorldMap, i: int) -> bool:
	return map.stop_node(i).get_node("Flag").visible


func _lock_on(map: WorldMap, i: int) -> bool:
	return map.stop_node(i).get_node("Lock").visible


func _run() -> void:
	# The test gets its own save, whether or not the autoload exists in this run.
	var save := root.get_node_or_null("SaveGame") as SaveData
	if save == null:
		save = SaveData.new()
		save.name = "SaveGame"
		root.add_child(save)
	save.use_file(TEST_FILE)
	save.reset()

	var map: WorldMap = load("res://scenes/world_map.tscn").instantiate()
	_check("map opens with every stop unlocked by default", map.unlock_all)
	map.unlock_all = false  # these checks are about the locked behaviour
	root.add_child(map)
	await _wait(0.5)

	# The 3D set: a camera, the ship, all 12 stops with their parts.
	_check("map has a Camera3D that is the current one", map.camera is Camera3D and map.camera.current)
	_check("map has the Complex2000 with a dome and Fart Man", map.ship != null and map.ship.get_node_or_null("Rig/Pilot") != null and map.ship.get_node_or_null("Rig/Dome") != null)
	var parts_ok: bool = true
	for i in MapStops.STOPS.size():
		var node: Node3D = map.stop_node(i)
		parts_ok = parts_ok and node != null and node.get_node_or_null("Look") != null and node.get_node_or_null("Flag") != null \
			and node.get_node_or_null("Lock") != null and node.get_node_or_null("Pips") != null and node.get_node("Pips").get_child_count() == 3
	_check("all %d stops have a landmark, flag, padlock and 3 Golden Bean pips" % MapStops.STOPS.size(), parts_ok)
	_check("start: on %s name='%s' info='%s'" % [_id(map), map.name_label.text, map.info_label.text], map.index == 0 and map.name_label.text == "THE VEG PATCH" and map.info_label.text == "")
	_check("the ship hovers above the start stop", _above(map, 0) and map.ship.position.y > MapStops.STOPS[0]["pos"].y + 3.0)
	_check("the world's name shows on arrival: '%s'" % map.world_label.text, map.world_label.visible and map.world_label.text == "GRANDMA'S GARDEN")
	_check("hub hint hidden while there is no hub", not map.hub_hint.visible and not map.board_ship())

	# Camera keeps the ship, the stop under it and a bit of what is next in view.
	_check("camera sees the ship and its stop", _in_view(map.camera, map.ship.global_position) and _in_view(map.camera, MapStops.STOPS[0]["pos"]))
	_check("camera also sees a bit of the next stop", _in_view(map.camera, MapStops.STOPS[1]["pos"]))
	_check("camera looks down from above and in front", map.camera.global_position.y > map.ship.global_position.y and map.camera.global_position.z > map.ship.global_position.z)

	# Nothing cleared yet: right must not move him.
	await _press(&"ui_right")
	_check("1-1 not cleared, press right: stays on %s" % _id(map), map.index == 0 and _above(map, 0))
	await _press(&"ui_left")
	_check("press left at the first stop: stays on %s" % _id(map), map.index == 0 and _above(map, 0))
	_check("1-2 is locked, 1-1 is not", map.is_stop_locked(1) and not map.is_stop_locked(0) and _lock_on(map, 1) and not _lock_on(map, 0))

	# Clear 1-1 with 2 golden beans and 1234 points. Now he can go to 1-2 but no further.
	save.record_stage("1-1", 2, 1234)
	await _wait(0.4)
	_check("1-1 cleared: flag up, 2 of 3 pips lit, info '%s'" % map.info_label.text,
		_flag_on(map, 0) and map.stop_node(0).get_node("Pips").visible and map.pips_lit(0) == 2 and map.info_label.text == "GOLDEN BEANS 2/3   BEST 1234")
	_check("a stop not cleared has no flag and hides its pips", not _flag_on(map, 1) and not map.stop_node(1).get_node("Pips").visible)
	_check("1-2 is open now (no padlock)", not _lock_on(map, 1) and _lock_on(map, 2))
	# Watch the flight: after a moment the ship is between the two stops, above the ground.
	Input.action_press(&"ui_right")
	await _wait(0.1)
	Input.action_release(&"ui_right")
	await _wait(slide_half(map))
	var mid: Vector3 = map.ship.position
	var a: Vector3 = map.stop_hover_position(0)
	var b: Vector3 = map.stop_hover_position(1)
	_check("press right: the ship is flying (index %d, flying=%s)" % [map.index, map.ship.is_flying], map.index == 1 and map.ship.is_flying)
	_check("halfway there it is between the stops and a bit higher than the hover line", mid.x > a.x + 1.0 and mid.x < b.x - 1.0 and mid.y > a.y + 0.5)
	_check("it leans into the turn (banked, not level)", absf(map.ship.rotation.x) > 0.01 or absf(map.ship.rotation.z) > 0.01)
	_check("the camera still has the ship in view mid-flight", _in_view(map.camera, map.ship.global_position))
	await _wait(1.6)
	_check("1-1 cleared, press right: on %s name='%s', ship settled above it" % [_id(map), map.name_label.text], map.index == 1 and _above(map, 1) and not map.ship.is_flying and map.name_label.text == "THE GREENHOUSE")
	await _wait(1.0)
	_check("camera settled and keeps ship in view", _in_view(map.camera, map.ship.global_position) and _in_view(map.camera, MapStops.STOPS[1]["pos"]) and _in_view(map.camera, MapStops.STOPS[2]["pos"]))
	await _press(&"ui_right")
	_check("1-2 not cleared, press right: stays on %s" % _id(map), map.index == 1 and _above(map, 1))

	# World 3 (Planet Whiff) is locked until 2-4 is cleared: fly on with everything before it cleared.
	for stop_id in ["1-2", "1-3", "1-4", "2-1", "2-2", "2-3"]:
		save.record_stage(stop_id, 0, 1)
	for i in 10:
		await _press(&"ui_right")
	_check("2-4 not cleared, 10 presses right: stays on %s (World 3 is locked)" % _id(map), _id(map) == "2-4" and _above(map, 7))
	_check("World 3 looks locked: padlocks on 3-1..3-4, none on 2-4", _lock_on(map, 8) and _lock_on(map, 11) and not _lock_on(map, 7))
	_check("a cleared stop in World 1 has its flag, 2-4 does not", _flag_on(map, 3) and not _flag_on(map, 7))
	save.record_stage("2-4", 0, 1)
	await _press(&"ui_right")
	var sky: float = MapStops.SKY_HEIGHT
	_check("2-4 cleared, press right: on %s name='%s' (World 3 is open, up in the sky)" % [_id(map), map.name_label.text],
		_id(map) == "3-1" and _above(map, 8) and map.ship.position.y > sky)
	_check("arriving in World 3 shows its name: '%s'" % map.world_label.text, map.world_label.visible and map.world_label.text == "PLANET WHIFF")
	_check("camera follows it up there", _in_view(map.camera, map.ship.global_position) and _in_view(map.camera, MapStops.STOPS[8]["pos"]))
	await _press(&"ui_right")
	_check("3-1 not cleared, press right: stays on %s" % _id(map), _id(map) == "3-1")
	for stop_id in ["3-1", "3-2", "3-3"]:
		save.record_stage(stop_id, 1, 1)
	for i in 4:
		await _press(&"ui_right")
	_check("World 3 cleared up to 3-3, 4 presses right: on %s name='%s'" % [_id(map), map.name_label.text], _id(map) == "3-4" and _above(map, 11) and map.name_label.text == "BIG BAD BURP")
	var all_have_scenes: bool = true
	for stop: Dictionary in MapStops.STOPS:
		all_have_scenes = all_have_scenes and ResourceLoader.exists(stop["scene"])
	_check("all 12 stops have a stage", all_have_scenes)

	# A stop with no stage would say COMING SOON (all 12 have one now, so ask for it directly).
	_check("coming soon hidden before", not map.soon_label.visible)
	map._show_soon()
	_check("coming soon shows: visible=%s text='%s' still on the map=%s" % [map.soon_label.visible, map.soon_label.text, map.is_inside_tree()],
		map.soon_label.visible and map.soon_label.text == "COMING SOON!" and map.is_inside_tree())
	await _wait(map.soon_time + 0.3)
	_check("coming soon fades", not map.soon_label.visible)

	# Back on the first stop: it shows beans and the best score.
	for i in 12:
		await _press(&"ui_left")
	_check("back on %s: info='%s' golden=%d score=%d ship above it" % [_id(map), map.info_label.text, map.stop_golden(0), map.stop_score(0)],
		map.index == 0 and map.stop_golden(0) == 2 and map.stop_score(0) == 1234 and _above(map, 0) and map.info_label.text == "GOLDEN BEANS 2/3   BEST 1234")
	_check("the Golden Bean pips match the save: 3-1 has 1 lit, 1-1 has 2", map.pips_lit(8) == 1 and map.pips_lit(0) == 2)
	var gold_ok: bool = true
	for pip: MeshInstance3D in map.stop_node(0).get_node("Pips").get_children():
		gold_ok = gold_ok and (pip.material_override as StandardMaterial3D).albedo_color in [map.found_color, map.missing_color]
	_check("every pip is gold or dim", gold_ok)

	# A new map (like returning from a stage) puts him on the stop he came from.
	save.set_last_stop("1-1")
	map.queue_free()
	await _wait(0.2)
	var again: WorldMap = load("res://scenes/world_map.tscn").instantiate()
	again.unlock_all = false
	root.add_child(again)
	await _wait(0.5)
	_check("map reopened: on %s (last stop was %s), ship already above it" % [_id(again), save.last_stop], _id(again) == "1-1" and _above(again, 0))
	save.set_last_stop("1-3")
	again.queue_free()
	await _wait(0.2)
	var third: WorldMap = load("res://scenes/world_map.tscn").instantiate()
	third.unlock_all = false
	root.add_child(third)
	await _wait(0.5)
	_check("map reopened after 1-3: ship hovers above %s" % _id(third), _id(third) == "1-3" and _above(third, 2))
	third.queue_free()

	# Unlocked map: with nothing cleared he can still fly to any stop.
	await _wait(0.2)
	save.reset()
	var open: WorldMap = load("res://scenes/world_map.tscn").instantiate()
	root.add_child(open)
	await _wait(0.5)
	for i in 3:
		await _press(&"ui_right")
	_check("unlocked map, nothing cleared, 3 presses right: on %s (want 1-4), no padlocks" % _id(open), _id(open) == "1-4" and _above(open, 3) and not _lock_on(open, 11))

	# The hub hook: with a hub scene set the hint shows and Y goes aboard (here a missing
	# scene, so it stays put); with none it does nothing.
	open.ship_hub_scene = "res://scenes/does_not_exist.tscn"
	open.refresh_hub_hint()
	_check("with a hub scene set the GO ABOARD hint shows (text '%s')" % open.hub_hint.text, open.hub_hint.visible and open.hub_hint.text == "Y: GO ABOARD")
	_check("board_ship() with a hub that is not there does nothing", not open.board_ship())
	open.ship_hub_scene = ""
	open.refresh_hub_hint()
	_check("and no hub scene hides the hint again", not open.hub_hint.visible)

	# Accept: Fart Man jumps out of the gondola, the ship dips, then the stage loads.
	await _wait(0.5)
	open.index = 0
	open.ship.snap_to(open.stop_hover_position(0))
	var rest_y: float = open.ship.get_node("Rig/Pilot").position.y
	Input.action_press(&"ui_accept")
	await _wait(0.1)
	Input.action_release(&"ui_accept")
	await _wait(0.3)
	_check("accept: Fart Man is jumping out (dropping=%s), the ship is dipping" % open.ship.is_dropping, open.ship.is_dropping and open.ship.dip > 0.1 and open.ship.get_node("Rig/Pilot").position.y > rest_y)
	_check("the map stayed on screen while he drops, and the last stop is saved", open.is_inside_tree() and save.last_stop == "1-1")
	await _wait(1.5)
	var now: Node = current_scene
	_check("then the right stage loads: '%s'" % (now.scene_file_path if now != null else "none"), now != null and now.scene_file_path == "res://scenes/stage_1_1.tscn")

	save.reset()
	DirAccess.remove_absolute(TEST_FILE)
	print("world map test: %s" % ("ALL OK" if _fails == 0 else "%d FAILED" % _fails))
	quit()


# Half way through the flight (the press already used 0.1 s).
func slide_half(map: WorldMap) -> float:
	return map.slide_time * 0.5 - 0.1
