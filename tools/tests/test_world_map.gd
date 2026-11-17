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

	# World 1 has stages now, so walk on to 2-1, which has no stage yet.
	save.record_stage("1-2", 0, 1)
	save.record_stage("1-3", 0, 1)
	save.record_stage("1-4", 0, 1)
	for i in 3:
		await _press(&"ui_right")

	# Entering a stop with no stage shows COMING SOON.
	print("coming soon before jump: %s" % map.soon_label.visible)
	Input.action_press(&"ui_accept")
	await _wait(0.1)
	Input.action_release(&"ui_accept")
	await _wait(0.2)
	print("jump on 1-2: coming soon visible=%s text='%s' still on the map=%s" % [map.soon_label.visible, map.soon_label.text, map.is_inside_tree()])
	await _wait(map.soon_time + 0.3)
	print("coming soon fades: visible=%s" % map.soon_label.visible)

	# Back on the cleared stop: it shows beans and the best score.
	for i in 4:
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
