extends SceneTree
# Checks how big Fart Man looks on screen: about 1/5 of the screen tall, like Mario in
# Mario Wonder. Also that all of him stays on screen in a Thunder jump and a long drop,
# and that the camera zooms out in the boss fight so Sneezy Weezy is in the shot too.
# Tests can't see the screen: this works it out from where the camera points.

var failures: int = 0


func _initialize() -> void:
	_run()


func _wait(seconds: float) -> void:
	for i in int(seconds * 60.0):
		await physics_frame


func _check(what: String, ok: bool) -> void:
	print("%s: %s" % [what, "ok" if ok else "FAILED"])
	if not ok:
		failures += 1


## Where his head and feet are on the screen: 0 = top edge, 1 = bottom edge.
func _head_and_feet(camera: Camera3D, player: Player) -> Vector2:
	var tall: float = camera.get_viewport().get_visible_rect().size.y
	var head: float = camera.unproject_position(player.global_position + Vector3.UP).y / tall
	var feet: float = camera.unproject_position(player.global_position + Vector3.DOWN).y / tall
	return Vector2(head, feet)


func _on_screen(camera: Camera3D, point: Vector3) -> bool:
	var size: Vector2 = camera.get_viewport().get_visible_rect().size
	var p: Vector2 = camera.unproject_position(point)
	return not camera.is_position_behind(point) and p.x >= 0.0 and p.x <= size.x and p.y >= 0.0 and p.y <= size.y


## Watches his head and feet for a while. Returns (highest head, lowest feet) on screen.
func _watch(camera: Camera3D, player: Player, seconds: float) -> Vector2:
	var worst := Vector2(1.0, 0.0)
	for i in int(seconds * 60.0):
		await physics_frame
		var hf: Vector2 = _head_and_feet(camera, player)
		worst = Vector2(minf(worst.x, hf.x), maxf(worst.y, hf.y))
	return worst


func _run() -> void:
	var save: Node = root.get_node_or_null("SaveGame")
	if save != null:
		save.use_file("user://test_screen_size_save.json")
		save.reset()

	# --- Stage 1-1: standing still. ---------------------------------------------------
	var stage: Node = load("res://scenes/stage_1_1.tscn").instantiate()
	root.add_child(stage)
	var player: Player = stage.get("player")
	var camera: Camera3D = stage.get_node("Camera3D")
	await _wait(1.5)
	print("screen %s, camera angle %.0f deg" % [camera.get_viewport().get_visible_rect().size, camera.fov])
	var hf: Vector2 = _head_and_feet(camera, player)
	_check("he is about 1/5 of the screen tall (%.2f)" % (hf.y - hf.x), hf.y - hf.x > 0.18 and hf.y - hf.x < 0.23)
	_check("his feet are low on the screen, like Mario's (%.2f of the way down)" % hf.y, hf.y > 0.78 and hf.y < 0.9)

	# --- A Thunder jump, watched all the way up and down. ------------------------------
	var ground_y: float = player.global_position.y
	Input.action_press(&"fart")
	await _wait(player.full_charge_time + 0.05)
	Input.action_release(&"fart")
	var peak: float = ground_y
	var worst := Vector2(1.0, 0.0)
	for i in 150:
		await physics_frame
		peak = maxf(peak, player.global_position.y)
		hf = _head_and_feet(camera, player)
		worst = Vector2(minf(worst.x, hf.x), maxf(worst.y, hf.y))
	_check("full-belly jump %.1f m high: head stays below the top (%.2f), feet above the bottom (%.2f)" % [
		peak - ground_y, worst.x, worst.y], peak - ground_y > 4.0 and worst.x > 0.0 and worst.y < 1.0)

	# --- A long drop: put him 8 m up and let him fall. ---------------------------------
	player.global_position.y += 8.0
	player.velocity = Vector3.ZERO
	await _wait(2.0 / 60.0)
	worst = await _watch(camera, player, 2.0)
	_check("8 m drop: head stays below the top (%.2f), feet above the bottom (%.2f)" % [worst.x, worst.y],
		worst.x > 0.0 and worst.y < 1.0)
	stage.queue_free()
	await process_frame

	# --- Stage 1-4: the camera zooms out to show Sneezy Weezy as well. ----------------
	stage = load("res://scenes/stage_1_4.tscn").instantiate()
	root.add_child(stage)
	player = stage.get("player")
	camera = stage.get_node("Camera3D")
	var boss: SneezyWeezy = stage.find_child("SneezyWeezy", true, false)
	await _wait(0.5)
	player.position = Vector3(9.0, 1.2, 0)  # walks through the door: the hello scene starts
	await _wait(2.5)
	_check("boss hello: her face is on screen (camera angle %.0f deg)" % camera.fov,
		_on_screen(camera, boss.head.global_position))
	_check("boss hello: he is on screen too", _on_screen(camera, player.global_position))
	boss.call("_reset")  # as if he lost and went back to the toilet
	_check("after the fight the camera stops showing her", camera.get("also_show").is_empty())

	print("screen size failures: %d" % failures)
	quit()
