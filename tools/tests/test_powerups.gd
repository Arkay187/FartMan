extends SceneTree
# Checks the Mega Bean Can and the Chilli Pepper.


func _initialize() -> void:
	var level: Node = load("res://scenes/test_level.tscn").instantiate()
	root.add_child(level)
	_run(level)


func _wait(seconds: float) -> void:
	for i in int(seconds * 60.0):
		await physics_frame


func _puffs() -> int:
	var n: int = 0
	for child: Node in root.get_children():
		if child is MeshInstance3D:
			n += 1
	return n


func _run(level: Node) -> void:
	var player: CharacterBody3D = level.get_node("Player")
	var tank: Node = player.get_node("GasTank")
	var hearts: Node = player.get_node("Hearts")
	var chilli: Node = player.get_node("ChilliPower")
	# The glow goes on the real model's mesh, as a see-through coat.
	var body: GeometryInstance3D = player.get_node("Visual/ModelTurn/Model").find_children("*", "MeshInstance3D", true, false)[0]
	var enemies: Node = level.get_node("Enemies")
	await _wait(0.5)

	# Normal walking speed and Thunder height, for comparison.
	player.global_position = Vector3(-16, 1.5, 0)
	await _wait(0.3)
	var x0: float = player.global_position.x
	Input.action_press(&"ui_right")
	await _wait(0.5)
	Input.action_release(&"ui_right")
	var normal_dist: float = player.global_position.x - x0
	await _wait(0.5)

	# Mega Bean Can.
	tank.drain(1000.0)
	var score_before: int = level.score
	player.global_position = level.get_node("PowerUps/MegaBeanCan").global_position
	player.velocity = Vector3.ZERO
	await _wait(0.3)
	print("mega bean can: gas=%.0f score +%d, can gone=%s" % [tank.gas, level.score - score_before, not level.has_node("PowerUps/MegaBeanCan")])

	# Chilli.
	score_before = level.score
	player.global_position = level.get_node("PowerUps/Chilli").global_position
	player.velocity = Vector3.ZERO
	await _wait(0.3)
	print("chilli: hot=%s glowing=%s puffs=%d score +%d enemies=%d hearts=%d" % [
		player.is_hot(), body.material_overlay != null, _puffs(), level.score - score_before, enemies.get_child_count(), hearts.hearts])

	# Run right through the row of Burplings.
	x0 = player.global_position.x
	Input.action_press(&"ui_right")
	await _wait(0.5)
	var hot_dist: float = player.global_position.x - x0
	await _wait(0.6)
	Input.action_release(&"ui_right")
	await _wait(0.5)
	print("ran through them: speed x%.2f, x=%.1f enemies=%d hearts=%d score +%d" % [
		hot_dist / normal_dist, player.global_position.x, enemies.get_child_count(), hearts.hearts, level.score - score_before])

	# Hot Thunder jump.
	player.global_position = Vector3(-16, 1.5, 0)
	player.velocity = Vector3.ZERO
	await _wait(0.4)
	var rest_y: float = player.global_position.y
	Input.action_press(&"fart")
	await _wait(0.6)
	Input.action_release(&"fart")
	var peak: float = rest_y
	for i in 150:
		await physics_frame
		peak = maxf(peak, player.global_position.y)
	print("hot thunder: height %.2f m (normal is 5.25), still hot=%s time_left=%.1f" % [peak - rest_y, player.is_hot(), chilli.time_left])

	await _wait(chilli.time_left + 0.8)
	print("after it wears off: hot=%s glowing=%s puffs=%d" % [player.is_hot(), body.material_overlay != null, _puffs()])
	quit()
