extends SceneTree
# Checks the new hover rules and the new SIMPLE default: SIMPLE is the default, an old save with
# no version marker becomes SIMPLE once (a later CLASSIC choice sticks), hover pressed on the
# ground rises to about 2.5 m and holds, hover pressed in the air holds that height, the gas
# bar shows the hover fuel (also in NO GAS, hidden again afterwards) and out of gas = fizzle.

var failures: int = 0
const OFF: float = 300.0
var options: DebugOptionsData
var world: Node3D
var p: Player
var bar: ProgressBar
var label: Label
var fizzles: int = 0


func _initialize() -> void:
	_run()


func _wait(seconds: float) -> void:
	for i in int(seconds * 60.0):
		await physics_frame


func _check(text: String, ok: bool) -> void:
	print("%s: %s" % [text, "ok" if ok else "FAILED"])
	if not ok:
		failures += 1


func _make_world() -> void:
	world = Node3D.new()
	root.add_child(world)
	var body := StaticBody3D.new()
	body.position = Vector3(OFF, -0.5, 0)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(60, 1, 4)
	col.shape = shape
	body.add_child(col)
	world.add_child(body)
	p = load("res://scenes/player.tscn").instantiate()
	p.position = Vector3(OFF, 1.0, 0)
	world.add_child(p)
	p.flashing_left = 100000.0
	p.fizzled.connect(func() -> void: fizzles += 1)
	# A gas bar and label like the real HUD has.
	var hud := Control.new()
	world.add_child(hud)
	label = Label.new()
	label.name = "GasLabel"
	hud.add_child(label)
	bar = ProgressBar.new()
	bar.set_script(load("res://scripts/gas_bar.gd"))
	bar.name = "GasBar"
	bar.set("player", p)
	hud.add_child(bar)


func _reset() -> void:
	p.global_position = Vector3(OFF, 1.0, 0)
	p.velocity = Vector3.ZERO
	p.gas_tank.gas = p.gas_tank.max_gas
	fizzles = 0


## Writes an options file, loads it into a fresh DebugOptionsData, and returns it.
func _load_file(path: String, content: String) -> DebugOptionsData:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(content)
	f.close()
	var o := DebugOptionsData.new()
	o.test_saving = true
	o.save_path = path
	root.add_child(o)  # _ready loads the file
	return o


func _run() -> void:
	await _wait(0.2)
	options = root.get_node("DebugOptions")

	# ---------------------------------------------------------------- settings
	_check("default: SIMPLE controls in a fresh run", options.simple_controls)
	var path: String = "user://test_hover_options.json"
	var old: DebugOptionsData = _load_file(path, '{"gas_mode": 1, "simple_controls": false, "music_on": false}')
	_check("old save (no version): becomes SIMPLE once", old.simple_controls and old.gas_mode == 1 and not old.music_on)
	old.set_simple_controls(false)
	old.queue_free()
	await _wait(0.1)
	var again: DebugOptionsData = _load_file(path, FileAccess.get_file_as_string(path))
	_check("saved CLASSIC choice with the marker stays CLASSIC", not again.simple_controls)
	again.queue_free()
	var fresh: DebugOptionsData = _load_file(path, '{"settings_version": 2, "simple_controls": true}')
	_check("saved SIMPLE with the marker stays SIMPLE", fresh.simple_controls)
	fresh.queue_free()
	DirAccess.remove_absolute(path)
	options.set_simple_controls(true)
	options.set_gas_mode(DebugOptionsData.GasMode.NORMAL)

	_make_world()
	await _wait(0.5)
	var tank: GasTank = p.gas_tank
	var cloud: HoverCloud = p.hover_helper.cloud
	_check("bar visible with the label at the start", bar.visible and label.visible)

	# ---------------------------------------------------------------- ground hover
	_reset()
	await _wait(0.2)
	var start_y: float = p.global_position.y
	var peak: float = 0.0
	Input.action_press(&"hover")
	for i in 90:
		await physics_frame
		peak = maxf(peak, p.global_position.y - start_y)
	_check("ground hover: rises to about 2.5 m (%.2f)" % (p.global_position.y - start_y), absf(p.global_position.y - start_y - 2.5) < 0.2)
	_check("ground hover: no overshoot (peak %.2f)" % peak, peak < 2.65)
	_check("ground hover: hovering with the cloud", p.is_hovering() and cloud.is_active())
	var y_a: float = p.global_position.y
	await _wait(0.5)
	_check("ground hover: holds the height (%.2f -> %.2f)" % [y_a, p.global_position.y], absf(p.global_position.y - y_a) < 0.1)
	_check("ground hover: the bar is visible and shows less gas (%.0f)" % bar.value, bar.visible and label.visible and bar.value < 95.0 and absf(bar.value - tank.gas) < 0.5)
	Input.action_release(&"hover")
	await _wait(0.3)
	_check("ground hover: let go and he drops", not p.is_hovering() and p.velocity.y < -2.0)
	await _wait(1.5)
	_check("ground hover: lands", p.is_on_floor())
	_check("ground hover: no double jump spent by it", p.simple_helper.air_jumps_left() == 1)

	# ---------------------------------------------------------------- air hover at two heights
	for height: float in [4.0, 9.0]:
		_reset()
		p.global_position = Vector3(OFF, height, 0)
		await _wait(0.2)
		var before: float = p.global_position.y
		Input.action_press(&"hover")
		await _wait(0.4)
		var held: float = p.global_position.y
		await _wait(0.5)
		_check("air hover at %.0f: holds where it was pressed (pressed at %.2f, %.2f, now %.2f)" % [height, before, held, p.global_position.y], p.is_hovering() and absf(p.global_position.y - held) < 0.1 and before - held < 2.0 and held < before + 0.1)
		Input.action_release(&"hover")
		await _wait(0.5)
		_check("air hover at %.0f: letting go drops him" % height, not p.is_hovering() and p.global_position.y < held - 0.3)
		await _wait(2.0)

	# Pressed while rising: stops rising and holds.
	_reset()
	await _wait(0.2)
	Input.action_press(&"jump")
	await _wait(0.1)
	Input.action_release(&"jump")
	await _wait(0.1)
	Input.action_press(&"hover")
	await _wait(0.3)
	var up_y: float = p.global_position.y
	await _wait(0.4)
	_check("air hover while rising: holds (%.2f -> %.2f)" % [up_y, p.global_position.y], p.is_hovering() and absf(p.global_position.y - up_y) < 0.1)
	Input.action_release(&"hover")
	await _wait(2.0)

	# ---------------------------------------------------------------- double jump not given back
	_reset()
	await _wait(0.2)
	Input.action_press(&"jump")
	await _wait(0.1)
	Input.action_release(&"jump")
	await _wait(0.2)
	Input.action_press(&"jump")  # uses the air jump
	await _wait(0.1)
	Input.action_release(&"jump")
	await _wait(0.3)
	Input.action_press(&"hover")
	await _wait(0.6)
	Input.action_release(&"hover")
	await _wait(0.2)
	_check("after a hover in the air the double jump stays used", p.simple_helper.air_jumps_left() == 0)
	await _wait(2.0)

	# ---------------------------------------------------------------- out of gas
	_reset()
	tank.gas = 12.0
	await _wait(0.2)
	Input.action_press(&"hover")
	for i in 240:
		await physics_frame
		if fizzles > 0:
			break
	await _wait(0.3)
	_check("out of gas: one fizzle and he drops (fizzles %d, vy %.1f)" % [fizzles, p.velocity.y], fizzles == 1 and not p.is_hovering() and p.velocity.y < -2.0)
	Input.action_release(&"hover")
	await _wait(2.0)

	# ---------------------------------------------------------------- NO GAS: bar only during hover
	options.set_gas_mode(DebugOptionsData.GasMode.NO_GAS)
	_reset()
	await _wait(0.3)
	_check("NO GAS: bar and label hidden normally", not bar.visible and not label.visible)
	Input.action_press(&"hover")
	await _wait(0.6)
	var v1: float = bar.value
	_check("NO GAS: bar and label show during the hover (%.0f)" % v1, bar.visible and label.visible and v1 < 95.0 and v1 > 40.0)
	await _wait(1.0)
	_check("NO GAS: the bar drains (%.0f -> %.0f)" % [v1, bar.value], bar.value < v1 - 10.0)
	for i in 300:
		await physics_frame
		if not p.is_hovering():
			break
	await _wait(0.2)
	_check("NO GAS: hover over, bar and label hidden again", not bar.visible and not label.visible)
	Input.action_release(&"hover")
	await _wait(2.0)
	# Letting go early also hides it.
	_reset()
	await _wait(0.2)
	Input.action_press(&"hover")
	await _wait(0.5)
	Input.action_release(&"hover")
	await _wait(0.2)
	_check("NO GAS: letting go early hides the bar again", not bar.visible)
	await _wait(1.5)

	# ALWAYS FULL: the bar is there anyway, and shows the hover time during the hover.
	options.set_gas_mode(DebugOptionsData.GasMode.ALWAYS_FULL)
	_reset()
	await _wait(0.3)
	Input.action_press(&"hover")
	await _wait(1.5)
	_check("ALWAYS FULL: bar shows the time left (%.0f)" % bar.value, bar.visible and bar.value < 80.0)
	Input.action_release(&"hover")
	await _wait(0.3)
	_check("ALWAYS FULL: bar shows the full tank again (%.0f)" % bar.value, bar.visible and bar.value > 95.0)
	await _wait(1.5)

	options.set_simple_controls(true)
	options.set_gas_mode(DebugOptionsData.GasMode.NORMAL)
	print("hover failures: %d" % failures)
	quit()
