extends SceneTree
# Checks the slow gas refill and the score.


func _initialize() -> void:
	var level: Node = load("res://scenes/test_level.tscn").instantiate()
	root.add_child(level)
	_run(level)


func _wait(seconds: float) -> void:
	for i in int(seconds * 60.0):
		await physics_frame


func _run(level: Node) -> void:
	var player: CharacterBody3D = level.get_node("Player")
	var tank: Node = player.get_node("GasTank")
	var label: Label = level.get_node("HUD/ScoreLabel")
	await _wait(0.5)
	print("start: gas=%.0f score=%d label='%s' anchors right=%s" % [tank.gas, level.score, label.text, label.anchor_left == 1.0])

	# Empty the tank and watch it come back.
	tank.drain(1000.0)
	await _wait(0.5)
	print("0.5s after emptying (still in the delay): gas=%.1f" % tank.gas)
	await _wait(2.0)
	print("2.5s after emptying: gas=%.1f" % tank.gas)
	await _wait(5.0)
	print("7.5s after emptying: gas=%.1f" % tank.gas)

	# No refill while holding a charge in.
	var before: float = tank.gas
	Input.action_press(&"fart")
	await _wait(0.7)
	print("held jump 0.7s: gas change=%.1f (should be 0)" % (tank.gas - before))
	await _wait(1.0)
	Input.action_release(&"fart")
	await _wait(2.5)

	# Thunder costs gas, then it creeps back.
	tank.refill(100.0)
	Input.action_press(&"fart")
	await _wait(0.6)
	Input.action_release(&"fart")
	await _wait(0.2)
	var after_thunder: float = tank.gas
	await _wait(3.0)
	print("thunder: gas right after=%.0f, 3s later=%.0f" % [after_thunder, tank.gas])

	# Score: bean, Burpling, Golden Bean.
	player.global_position = level.get_node("Beans/Bean2").global_position + Vector3(0, 2.5, 0)
	player.velocity = Vector3.ZERO
	await _wait(1.5)
	print("after dropping on bean 2 and the Burpling under it: score=%d label='%s'" % [level.score, label.text])
	player.global_position = level.get_node("GoldenBeans/GoldenBean1").global_position
	player.velocity = Vector3.ZERO
	await _wait(0.5)
	print("after a Golden Bean: score=%d label='%s'" % [level.score, label.text])
	level.get_node("BeanCan/LidSensor").body_entered.emit(player)
	await _wait(0.3)
	print("after the can: score=%d banner='%s'" % [level.score, level.get_node("HUD/StageClearBanner").text.replace("\n", " | ")])
	quit()
