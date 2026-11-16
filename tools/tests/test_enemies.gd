extends SceneTree
# Checks stomping, getting hurt, hearts and respawn.

var respawns: int = 0


func _initialize() -> void:
	var level: Node = load("res://scenes/test_level.tscn").instantiate()
	root.add_child(level)
	_run(level)


func _wait(seconds: float) -> void:
	for i in int(seconds * 60.0):
		await physics_frame


func _bar_text(bar: Node) -> String:
	var s: String = ""
	for c: ColorRect in bar.get_children():
		s += "R" if c.color.r > 0.6 else "-"
	return s


func _run(level: Node) -> void:
	var player: CharacterBody3D = level.get_node("Player")
	var hearts: Node = player.get_node("Hearts")
	var tank: Node = player.get_node("GasTank")
	var enemies: Node = level.get_node("Enemies")
	var bar: Node = level.get_node("HUD/HeartsBar")
	player.respawned.connect(func() -> void: respawns += 1)
	await _wait(1.0)
	print("start: hearts=%d bar=%s enemies=%d" % [hearts.hearts, _bar_text(bar), enemies.get_child_count()])

	# 1. Walk into the first Burpling from the side.
	Input.action_press(&"ui_right")
	for i in 240:
		await physics_frame
		if hearts.hearts < 3:
			break
	Input.action_release(&"ui_right")
	print("walked into one: hearts=%d bar=%s flashing=%s vel=%s enemies=%d" % [
		hearts.hearts, _bar_text(bar), player.flashing_left > 0.0, player.velocity.snapped(Vector3.ONE * 0.1), enemies.get_child_count()])

	# Still touching it while flashing should not hurt again.
	Input.action_press(&"ui_right")
	await _wait(1.0)
	Input.action_release(&"ui_right")
	print("while flashing: hearts=%d" % hearts.hearts)
	await _wait(1.5)
	print("after flashing: visible=%s flashing=%s" % [player.get_node("Visual").visible, player.flashing_left > 0.0])

	# 2. Drop onto a Burpling from above: plain bounce.
	tank.drain(50.0)
	var target: Node3D = enemies.get_node("Burpling2")
	player.global_position = target.global_position + Vector3(0, 3, 0)
	player.velocity = Vector3.ZERO
	var peak: float = -100.0
	var land_y: float = 0.0
	var squashed: bool = false
	for i in 180:
		await physics_frame
		if not squashed and target.is_squashed:
			squashed = true
			land_y = player.global_position.y
			peak = land_y
		if squashed:
			peak = maxf(peak, player.global_position.y)
	print("dropped on one: squashed=%s bounce height=%.2f m, gas=%.0f (was 50), hearts=%d, enemies=%d" % [
		squashed, peak - land_y, tank.gas, hearts.hearts, enemies.get_child_count()])

	# 3. Drop onto another while holding jump: higher bounce.
	target = enemies.get_node("Burpling3")
	player.global_position = target.global_position + Vector3(0, 3, 0)
	player.velocity = Vector3.ZERO
	Input.action_press(&"ui_accept")
	squashed = false
	for i in 180:
		await physics_frame
		if not squashed and target.is_squashed:
			squashed = true
			land_y = player.global_position.y
			peak = land_y
		if squashed:
			peak = maxf(peak, player.global_position.y)
	Input.action_release(&"ui_accept")
	await _wait(1.0)
	print("dropped holding jump: squashed=%s bounce height=%.2f m, enemies=%d" % [squashed, peak - land_y, enemies.get_child_count()])

	# 4. Get hurt until no hearts are left: should respawn with full hearts.
	target = enemies.get_node("Burpling4")
	for n in 3:
		await _wait(2.0)
		if respawns > 0:
			break
		player.global_position = Vector3(target.global_position.x - 0.6, 1.5, 0)
		player.velocity = Vector3.ZERO
		await _wait(0.3)
		print("  hit %d: hearts=%d bar=%s respawns=%d" % [n + 1, hearts.hearts, _bar_text(bar), respawns])
	await _wait(1.0)
	print("end: hearts=%d bar=%s respawns=%d at start=%s enemies=%d" % [
		hearts.hearts, _bar_text(bar), respawns, player.global_position.distance_to(Vector3(-6, 1.5, 0)) < 0.6, enemies.get_child_count()])
	quit()
