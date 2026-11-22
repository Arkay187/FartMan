extends SceneTree
# Sends real controller events (buttons, D-pad, thumbstick, trigger) and checks the
# game's actions react: walk, jump, fart, and menu "go".

var failures: int = 0


func _initialize() -> void:
	_run()


func _wait(frames: int = 3) -> void:
	for i in frames:
		await process_frame


func _check(label: String, ok: bool) -> void:
	print("%s: %s" % [label, "ok" if ok else "FAIL"])
	if not ok:
		failures += 1


func _button(index: JoyButton, down: bool) -> void:
	var e := InputEventJoypadButton.new()
	e.button_index = index
	e.pressed = down
	Input.parse_input_event(e)


func _axis(axis: JoyAxis, value: float) -> void:
	var e := InputEventJoypadMotion.new()
	e.axis = axis
	e.axis_value = value
	Input.parse_input_event(e)


## Presses a button, checks the action is held, lets go and checks it let go.
func _try_button(label: String, index: JoyButton, action: StringName) -> void:
	_button(index, true)
	await _wait()
	var held: bool = Input.is_action_pressed(action)
	_button(index, false)
	await _wait()
	_check("%s -> %s" % [label, action], held and not Input.is_action_pressed(action))


func _run() -> void:
	await _wait()
	await _try_button("pad A", JOY_BUTTON_A, &"jump")
	await _try_button("pad Y", JOY_BUTTON_Y, &"jump")
	await _try_button("pad X", JOY_BUTTON_X, &"fart")
	await _try_button("pad B", JOY_BUTTON_B, &"fire")
	# Pad B must only fire: never fart or jump too (or every fireball would jump).
	DebugOptionsData.ensure_input_actions()
	_button(JOY_BUTTON_B, true)
	await _wait()
	var b_extra: bool = Input.is_action_pressed(&"fart") or Input.is_action_pressed(&"jump")
	_button(JOY_BUTTON_B, false)
	await _wait()
	_check("pad B does not fart or jump", not b_extra)
	await _try_button("right bumper", JOY_BUTTON_RIGHT_SHOULDER, &"fart")
	await _try_button("D-pad left", JOY_BUTTON_DPAD_LEFT, &"ui_left")
	await _try_button("D-pad right", JOY_BUTTON_DPAD_RIGHT, &"ui_right")
	await _try_button("pad A (menus)", JOY_BUTTON_A, &"ui_accept")
	await _try_button("Start (menus)", JOY_BUTTON_START, &"ui_accept")

	# Left trigger pulled in and let go.
	_axis(JOY_AXIS_TRIGGER_LEFT, 1.0)
	await _wait()
	var trigger_held: bool = Input.is_action_pressed(&"fart")
	_axis(JOY_AXIS_TRIGGER_LEFT, 0.0)
	await _wait()
	_check("left trigger -> fart", trigger_held and not Input.is_action_pressed(&"fart"))
	# The right trigger no longer farts.
	_axis(JOY_AXIS_TRIGGER_RIGHT, 1.0)
	await _wait()
	var right_trigger_quiet: bool = not Input.is_action_pressed(&"fart")
	_axis(JOY_AXIS_TRIGGER_RIGHT, 0.0)
	_check("right trigger does nothing", right_trigger_quiet)

	# Pulling the left trigger slowly charges the belly; letting go launches him.
	var world0 := Node3D.new()
	root.add_child(world0)
	var floor0 := StaticBody3D.new()
	floor0.position = Vector3(0, -0.5, 0)
	var col0 := CollisionShape3D.new()
	var shape0 := BoxShape3D.new()
	shape0.size = Vector3(200, 1, 4)
	col0.shape = shape0
	floor0.add_child(col0)
	world0.add_child(floor0)
	var p0: Player = (load("res://scenes/player.tscn") as PackedScene).instantiate()
	p0.position = Vector3(0, 1.2, 0)
	world0.add_child(p0)
	for i in 30:
		await physics_frame
	_axis(JOY_AXIS_TRIGGER_LEFT, 1.0)
	for i in 40:
		await physics_frame
	_axis(JOY_AXIS_TRIGGER_LEFT, 0.0)
	var top0: float = 0.0
	for i in 60:
		await physics_frame
		top0 = maxf(top0, p0.position.y)
	_check("hold left trigger then release launches him (peak y=%.1f)" % top0, top0 > 3.0)
	world0.queue_free()

	# Left thumbstick: a firm push walks, a light wobble (stick drift) does not.
	_axis(JOY_AXIS_LEFT_X, 0.9)
	await _wait()
	var right: bool = Input.is_action_pressed(&"ui_right")
	_axis(JOY_AXIS_LEFT_X, -0.9)
	await _wait()
	var left: bool = Input.is_action_pressed(&"ui_left") and not Input.is_action_pressed(&"ui_right")
	_axis(JOY_AXIS_LEFT_X, 0.2)
	await _wait()
	var drift_ignored: bool = not Input.is_action_pressed(&"ui_left") and not Input.is_action_pressed(&"ui_right")
	_axis(JOY_AXIS_LEFT_X, 0.0)
	_check("stick right / left walks, drift ignored", right and left and drift_ignored)

	# Fart Man really walks and hops when the pad drives him.
	var world := Node3D.new()
	root.add_child(world)
	var floor_body := StaticBody3D.new()
	floor_body.position = Vector3(0, -0.5, 0)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(200, 1, 4)
	col.shape = shape
	floor_body.add_child(col)
	world.add_child(floor_body)
	var player: Player = (load("res://scenes/player.tscn") as PackedScene).instantiate()
	player.position = Vector3(0, 1.2, 0)
	world.add_child(player)
	for i in 30:
		await physics_frame
	_axis(JOY_AXIS_LEFT_X, 1.0)
	for i in 60:
		await physics_frame
	var walked: float = player.position.x
	_axis(JOY_AXIS_LEFT_X, 0.0)
	_button(JOY_BUTTON_A, true)
	var peak: float = 0.0
	for i in 40:
		await physics_frame
		peak = maxf(peak, player.position.y)
	_button(JOY_BUTTON_A, false)
	_check("stick walks him (x=%.1f) and pad A hops him (peak y=%.1f)" % [walked, peak], walked > 3.0 and peak > 1.8)

	print("gamepad failures: %d" % failures)
	quit()
