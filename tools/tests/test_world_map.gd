extends SceneTree
# Checks the world map: where Fart Man may walk, what cleared stops show, COMING SOON.

const TEST_FILE: String = "user://test_world_map.json"


func _initialize() -> void:
	_run()


func _wait(seconds: float) -> void:
	for i in int(seconds * 60.0):
		await process_frame


# Fake a button press for a few frames.
func _press(action: StringName) -> void:
	Input.action_press(action)
	await _wait(0.1)
	Input.action_release(action)
	await _wait(0.6)


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
	print("map opens with every stop unlocked by default: %s" % map.unlock_all)
	map.unlock_all = false  # these checks are about the locked behaviour
	root.add_child(map)
	await _wait(0.5)
	print("stops on map: %d (3 worlds of 4)" % MapStops.STOPS.size())
	print("start: on %s name='%s' info='%s'" % [MapStops.STOPS[map.index]["id"], map.name_label.text, map.info_label.text])

	# Nothing cleared yet: right must not move him.
	await _press(&"ui_right")
	print("1-1 not cleared, press right: stays on %s" % MapStops.STOPS[map.index]["id"])
	await _press(&"ui_left")
	print("press left at the first stop: stays on %s" % MapStops.STOPS[map.index]["id"])

	# Clear 1-1 with 2 golden beans and 1234 points. Now he can go to 1-2 but no further.
	save.record_stage("1-1", 2, 1234)
	await _press(&"ui_right")
	print("1-1 cleared, press right: on %s name='%s'" % [MapStops.STOPS[map.index]["id"], map.name_label.text])
	await _press(&"ui_right")
	print("1-2 not cleared, press right: stays on %s" % MapStops.STOPS[map.index]["id"])
	print("marker is at the 1-2 spot: %s" % (map.marker.position.distance_to(map.stop_marker_position(1)) < 1.0))

	# World 3 (Planet Whiff) is locked until 2-4 is cleared: walk on with everything before it cleared.
	for stop_id in ["1-2", "1-3", "1-4", "2-1", "2-2", "2-3"]:
		save.record_stage(stop_id, 0, 1)
	for i in 10:
		await _press(&"ui_right")
	print("2-4 not cleared, 10 presses right: stays on %s (World 3 is locked)" % MapStops.STOPS[map.index]["id"])
	save.record_stage("2-4", 0, 1)
	await _press(&"ui_right")
	print("2-4 cleared, press right: on %s name='%s' (World 3 is open)" % [MapStops.STOPS[map.index]["id"], map.name_label.text])
	await _press(&"ui_right")
	print("3-1 not cleared, press right: stays on %s" % MapStops.STOPS[map.index]["id"])
	for stop_id in ["3-1", "3-2", "3-3"]:
		save.record_stage(stop_id, 1, 1)
	for i in 4:
		await _press(&"ui_right")
	print("World 3 cleared up to 3-3, 4 presses right: on %s name='%s'" % [MapStops.STOPS[map.index]["id"], map.name_label.text])
	var all_have_scenes: bool = true
	for stop: Dictionary in MapStops.STOPS:
		all_have_scenes = all_have_scenes and ResourceLoader.exists(stop["scene"])
	print("all 12 stops have a stage: %s" % all_have_scenes)

	# A stop with no stage would say COMING SOON (all 12 have one now, so ask for it directly).
	print("coming soon before: %s" % map.soon_label.visible)
	map._show_soon()
	print("coming soon shows: visible=%s text='%s' still on the map=%s" % [map.soon_label.visible, map.soon_label.text, map.is_inside_tree()])
	await _wait(map.soon_time + 0.3)
	print("coming soon fades: visible=%s" % map.soon_label.visible)

	# Back on the cleared stop: it shows beans and the best score.
	for i in 12:
		await _press(&"ui_left")
	print("back on %s: info='%s' golden=%d score=%d" % [MapStops.STOPS[map.index]["id"], map.info_label.text, map.stop_golden(0), map.stop_score(0)])

	# A new map (like returning from a stage) puts him on the stop he came from.
	save.set_last_stop("1-1")
	map.queue_free()
	await _wait(0.2)
	var again: WorldMap = load("res://scenes/world_map.tscn").instantiate()
	again.unlock_all = false
	root.add_child(again)
	await _wait(0.5)
	print("map reopened: on %s (last stop was %s)" % [MapStops.STOPS[again.index]["id"], save.last_stop])

	# Unlocked map: with nothing cleared he can still walk to any stop.
	again.queue_free()
	await _wait(0.2)
	save.reset()
	var open: WorldMap = load("res://scenes/world_map.tscn").instantiate()
	root.add_child(open)
	await _wait(0.5)
	for i in 3:
		await _press(&"ui_right")
	print("unlocked map, nothing cleared, 3 presses right: on %s (want 1-4)" % MapStops.STOPS[open.index]["id"])
	open.queue_free()

	save.reset()
	DirAccess.remove_absolute(TEST_FILE)
	quit()
