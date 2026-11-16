extends SceneTree
# Checks that clearing the test level saves the result and goes back to the world map.

const TEST_FILE: String = "user://test_stage_return.json"


func _initialize() -> void:
	_run()


func _wait(seconds: float) -> void:
	for i in int(seconds * 60.0):
		await physics_frame


# Starts the level, then drops Fart Man onto the can's lid (that opens it).
func _clear_level(delay: float) -> Node:
	var level: Node = load("res://scenes/test_level.tscn").instantiate()
	level.set("return_delay", delay)
	root.add_child(level)
	await _wait(0.3)
	var player: CharacterBody3D = level.get_node("Player")
	var can: Node3D = level.get_node("BeanCan")
	player.global_position = can.get_node("LidSensor").global_position
	player.velocity = Vector3.ZERO
	return level


func _run() -> void:
	var save := root.get_node_or_null("SaveGame") as SaveData
	if save == null:
		save = SaveData.new()
		save.name = "SaveGame"
		root.add_child(save)
	save.use_file(TEST_FILE)
	save.reset()

	# Case 1: wait for the timer.
	var level: Node = await _clear_level(1.0)
	print("stage id: '%s'" % level.get("stage_id"))
	await _wait(0.4)
	print("just cleared: cleared=%s recorded=%s score=%d banner=%s map_yet=%s" % [
		level.get("is_cleared"), save.is_cleared("1-1"), save.best_score("1-1"),
		level.get_node("HUD/StageClearBanner").visible, root.get_node_or_null("WorldMap") != null])
	await _wait(1.5)
	var map := root.get_node_or_null("WorldMap") as WorldMap
	print("after the delay: world map showing=%s" % (map != null))
	if map != null:
		await _wait(0.4)
		print("marker on %s, info='%s'" % [MapStops.STOPS[map.index]["id"], map.info_label.text])
		map.queue_free()
	level.queue_free()
	await _wait(0.3)

	# Case 2: press jump to skip the wait (a long timer, so only the button can do it).
	save.reset()
	var level2: Node = await _clear_level(30.0)
	await _wait(1.0)
	print("2nd run, waiting: map_yet=%s" % (root.get_node_or_null("WorldMap") != null))
	Input.action_press(&"ui_accept")
	await _wait(0.2)
	Input.action_release(&"ui_accept")
	await _wait(0.4)
	print("2nd run, after jump: world map showing=%s recorded=%s" % [root.get_node_or_null("WorldMap") != null, save.is_cleared("1-1")])
	level2.queue_free()

	save.reset()
	DirAccess.remove_absolute(TEST_FILE)
	quit()
