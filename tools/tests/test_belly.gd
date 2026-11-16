extends SceneTree
# Plays the test level with fake key presses: belly, three jumps and the squeak.

var farts: Array[String] = []
var squeaks: int = 0


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
	var belly: Node3D = player.get_node("Visual/Belly")
	player.farted.connect(func(n: String) -> void: farts.append(n))
	player.squeak_started.connect(func() -> void: squeaks += 1)
	await _wait(1.0)
	var rest_y: float = player.position.y
	print("start: gas=%.0f belly_visible=%s" % [tank.gas, belly.visible])

	for hold: float in [0.05, 0.3, 0.6, 1.6, 4.0]:
		tank.refill(100.0)
		farts.clear()
		squeaks = 0
		Input.action_press(&"ui_accept")
		var held: float = 0.0
		var biggest_belly: float = 0.0
		while held < hold:
			await physics_frame
			held += 1.0 / 60.0
			if belly.visible:
				biggest_belly = maxf(biggest_belly, belly.scale.x)
		var belly_at_release: float = belly.scale.x if belly.visible else 0.0
		var gas_before_release: float = tank.gas
		var jumped_while_held: int = farts.size()
		Input.action_release(&"ui_accept")
		var peak: float = rest_y
		for i in 200:
			await physics_frame
			peak = maxf(peak, player.position.y)
		print("hold %.2fs: belly max %.2f, at release %.2f | squeaks %d, gas leaked %.0f, jumps while held %d | -> %s, height %.2f m, gas now %.0f, belly_visible=%s" % [
			hold, biggest_belly, belly_at_release, squeaks, 100.0 - gas_before_release,
			jumped_while_held, str(farts), peak - rest_y, tank.gas, belly.visible])

	# Out of gas: a full charge should still jump (small), never fail.
	tank.drain(1000.0)
	farts.clear()
	Input.action_press(&"ui_accept")
	await _wait(0.6)
	Input.action_release(&"ui_accept")
	await _wait(2.0)
	print("empty tank, full charge -> %s, gas=%.0f" % [str(farts), tank.gas])

	# Facing.
	Input.action_press(&"ui_left")
	await _wait(0.3)
	Input.action_release(&"ui_left")
	print("facing left: visual rot y=%.2f" % player.get_node("Visual").rotation.y)
	quit()
