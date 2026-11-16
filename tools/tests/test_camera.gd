extends SceneTree
# Checks the camera follows and that falling off the level respawns.

var respawns: int = 0


func _initialize() -> void:
	var level: Node = load("res://scenes/test_level.tscn").instantiate()
	root.add_child(level)
	_run(level)


func _wait(seconds: float) -> void:
	for i in int(seconds * 60.0):
		await physics_frame


func _run(level: Node) -> void:
	var player: CharacterBody3D = level.get_node("Player")
	var camera: Camera3D = level.get_node("Camera3D")
	player.respawned.connect(func() -> void: respawns += 1)
	await _wait(1.0)
	var start: Vector3 = player.position
	print("start: player=%s camera=%s" % [player.position.snapped(Vector3.ONE * 0.01), camera.position.snapped(Vector3.ONE * 0.01)])

	Input.action_press(&"ui_right")
	await _wait(1.5)
	print("walking right: player x=%.2f camera x=%.2f (lag %.2f)" % [player.position.x, camera.position.x, player.position.x - camera.position.x])
	Input.action_release(&"ui_right")
	await _wait(1.5)
	print("stopped: player x=%.2f camera x=%.2f y=%.2f z=%.2f" % [player.position.x, camera.position.x, camera.position.y, camera.position.z])

	# Walk left off the end of the floor.
	Input.action_press(&"ui_left")
	var lowest: float = 0.0
	for i in 60 * 8:
		await physics_frame
		lowest = minf(lowest, player.position.y)
		if respawns > 0:
			break
	Input.action_release(&"ui_left")
	await _wait(1.0)
	print("fell to y=%.1f, respawns=%d, back at start=%s, on_floor=%s, camera x=%.2f" % [
		lowest, respawns, player.position.distance_to(start) < 0.6, player.is_on_floor(), camera.position.x])
	quit()
