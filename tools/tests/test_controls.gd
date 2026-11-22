extends SceneTree
# Two buttons: jump = instant small hop, fart = charge. Fart also works in the air.

var farts: Array[String] = []
var fizzles: int = 0
var failures: int = 0


func _initialize() -> void:
	var level: Node = load("res://scenes/test_level.tscn").instantiate()
	root.add_child(level)
	_run(level)


func _wait(seconds: float) -> void:
	for i in int(seconds * 60.0):
		await physics_frame


func _check(label: String, ok: bool) -> void:
	print("%s: %s" % [label, "ok" if ok else "FAIL"])
	if not ok:
		failures += 1


func _run(level: Node) -> void:
	# This test is about the CLASSIC charge-fart controls (SIMPLE is the default now).
	(root.get_node("DebugOptions") as DebugOptionsData).set_simple_controls(false)
	var player: Player = level.get_node("Player")
	var tank: GasTank = player.get_node("GasTank")
	for enemy: Node in level.get_node("Enemies").get_children():
		enemy.free()
	player.farted.connect(func(n: String) -> void: farts.append(n))
	player.fizzled.connect(func() -> void: fizzles += 1)
	await _wait(1.0)
	var rest_y: float = player.position.y

	# 1. Jump button: lifts off within 2 frames, free.
	Input.action_press(&"jump")
	await physics_frame
	await physics_frame
	var rise_after_2_frames: float = player.velocity.y
	_check("jump button lifts off at once (vel y=%.1f)" % rise_after_2_frames, rise_after_2_frames > 5.0 and farts == ["Toot"])
	Input.action_release(&"jump")
	var peak: float = rest_y
	for i in 120:
		await physics_frame
		peak = maxf(peak, player.position.y)
	_check("hop is small (%.2f m) and free (gas %.0f)" % [peak - rest_y, tank.gas], peak - rest_y < 1.5 and tank.gas == 100.0)
	await _wait(0.5)

	# 2. Jump in the air does nothing.
	Input.action_press(&"jump")
	await physics_frame
	Input.action_release(&"jump")
	await _wait(0.3)
	farts.clear()
	Input.action_press(&"jump")
	await physics_frame
	Input.action_release(&"jump")
	await _wait(0.1)
	_check("jump in the air does nothing", farts.is_empty())
	await _wait(1.5)

	# 3. A quick tap of the fart button does nothing.
	farts.clear()
	Input.action_press(&"fart")
	await _wait(0.05)
	Input.action_release(&"fart")
	await _wait(0.3)
	_check("fart tap: no jump, fizzled (%d)" % fizzles, farts.is_empty() and fizzles == 1)

	# 4. Fart on the ground still works.
	farts.clear()
	Input.action_press(&"fart")
	await _wait(0.3)
	Input.action_release(&"fart")
	await _wait(0.1)
	_check("fart on the ground: Trump", farts == ["Trump"])
	await _wait(2.0)

	# 5. Double jump: hop, then charge a fart in the air and let go near the top.
	tank.refill(100.0)
	farts.clear()
	rest_y = player.position.y
	Input.action_press(&"jump")
	await physics_frame
	Input.action_release(&"jump")
	Input.action_press(&"fart")
	await _wait(0.2)
	_check("charging in the air", player.is_charging and not player.is_on_floor())
	var vel_before: float = player.velocity.y
	Input.action_release(&"fart")
	await physics_frame
	await physics_frame
	var vel_after: float = player.velocity.y
	peak = rest_y
	for i in 150:
		await physics_frame
		peak = maxf(peak, player.position.y)
	_check("air fart is a double jump: %s, vel %.1f -> %.1f, peak %.2f m" % [str(farts), vel_before, vel_after, peak - rest_y],
		farts == ["Toot", "Trump"] and vel_after > vel_before + 5.0 and peak - rest_y > 2.0)
	await _wait(2.0)

	# 6. No gas: an air fart fizzles instead of giving a free jump.
	tank.drain(1000.0)
	farts.clear()
	fizzles = 0
	Input.action_press(&"jump")
	await physics_frame
	Input.action_release(&"jump")
	await _wait(0.2)
	Input.action_press(&"fart")
	await _wait(0.3)
	Input.action_release(&"fart")
	await _wait(0.1)
	_check("no gas in the air: fizzles (%s, fizzles %d)" % [str(farts), fizzles], farts == ["Toot"] and fizzles == 1)

	print("controls failures: %d" % failures)
	quit()
