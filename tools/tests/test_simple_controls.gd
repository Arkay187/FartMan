extends SceneTree
# Checks the SIMPLE control scheme: a normal jump (tap = hop, hold = full), coyote time, the
# jump buffer, the free automatic Thunder double jump (once per time in the air), no belly,
# no gas used by jumps, the fart hover (uses gas, stops when empty, free-gas time limit), the
# fart cloud squashing enemies but not bosses or hazards, and CLASSIC still charging.

var failures: int = 0
## The test world sits away from the real levels.
const OFF: float = 300.0

var options: DebugOptionsData
var world: Node3D
var p: Player
var farts: Array[String] = []
var fizzles: int = 0


func _initialize() -> void:
	_run()


func _wait(seconds: float) -> void:
	for i in int(seconds * 60.0):
		await physics_frame


func _check(label: String, ok: bool) -> void:
	print("%s: %s" % [label, "ok" if ok else "FAILED"])
	if not ok:
		failures += 1


func _press(action: StringName, seconds: float = 0.1) -> void:
	Input.action_press(action)
	await _wait(seconds)
	Input.action_release(action)
	await _wait(0.05)


## A floor whose right-hand end is at x = OFF + 10 (a ledge to walk off). Its top is at y = 0.
func _make_world() -> void:
	world = Node3D.new()
	root.add_child(world)
	var body := StaticBody3D.new()
	body.position = Vector3(OFF - 10.0, -0.5, 0)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(40, 1, 4)
	col.shape = shape
	body.add_child(col)
	world.add_child(body)
	p = load("res://scenes/player.tscn").instantiate()
	p.position = Vector3(OFF, 1.0, 0)
	world.add_child(p)
	p.flashing_left = 100000.0  # nothing hurts him in this test
	p.farted.connect(func(n: String) -> void: farts.append(n))
	p.fizzled.connect(func() -> void: fizzles += 1)


## Puts him back on the ground in the middle, standing still, with a full tank.
func _reset(at_x: float = 0.0) -> void:
	p.global_position = Vector3(OFF + at_x, 1.0, 0)
	p.velocity = Vector3.ZERO
	p.gas_tank.gas = p.gas_tank.max_gas
	farts.clear()
	fizzles = 0


func _run() -> void:
	var save: Node = root.get_node_or_null("SaveGame")
	if save != null:
		save.use_file("user://test_simple_controls_save.json")
		save.reset()
	await _wait(0.2)  # let the autoloads start
	options = root.get_node("DebugOptions")
	options.set_simple_controls(false)
	options.set_gas_mode(DebugOptionsData.GasMode.NORMAL)
	_make_world()
	await _wait(0.5)
	var tank: GasTank = p.gas_tank

	# ---------------------------------------------------------------- CLASSIC is unchanged
	_check("starts on CLASSIC in a test run", not options.simple_controls and not p.is_simple())
	Input.action_press(&"fart")
	await _wait(0.3)
	_check("CLASSIC: holding fart charges and shows the belly", p.is_charging and p.belly.visible)
	Input.action_release(&"fart")
	await _wait(0.1)
	_check("CLASSIC: letting go launches a fart jump and uses gas", farts.size() == 1 and farts[0] == "Trump" and tank.gas < 100.0)
	await _wait(2.0)
	Input.action_press(&"hover")
	await _wait(0.1)
	_check("CLASSIC: the hover button does nothing", not p.is_hovering())
	Input.action_release(&"hover")

	# ---------------------------------------------------------------- switch to SIMPLE
	options.set_simple_controls(true)
	_reset()
	await _wait(0.3)
	_check("SIMPLE is on", p.is_simple())

	# Held jump: full height. v = 11.5, g = 25: 2.65 m.
	var start_y: float = p.global_position.y
	Input.action_press(&"jump")
	var peak: float = 0.0
	for i in 60:
		await physics_frame
		peak = maxf(peak, p.global_position.y - start_y)
	Input.action_release(&"jump")
	_check("jump: first jump is a Toot (%s)" % str(farts), farts.size() >= 1 and farts[0] == "Toot")
	_check("jump: held jump goes a full jump (%.2f m, about 2.6)" % peak, peak > 2.3 and peak < 2.9)
	_check("jump: no belly, no charging", not p.is_charging and not p.belly.visible)
	_check("jump: free (gas %.0f)" % tank.gas, tank.gas >= 99.9)
	await _wait(1.0)
	_check("jump: back on the ground", p.is_on_floor())

	# Tap: a small hop.
	_reset()
	await _wait(0.2)
	start_y = p.global_position.y
	Input.action_press(&"jump")
	await physics_frame
	await physics_frame
	Input.action_release(&"jump")
	var tap_peak: float = 0.0
	for i in 60:
		await physics_frame
		tap_peak = maxf(tap_peak, p.global_position.y - start_y)
	_check("jump: a tap is a small hop (%.2f m, under 1.0)" % tap_peak, tap_peak > 0.2 and tap_peak < 1.0)
	await _wait(1.0)

	# The fart button jumps too.
	_reset()
	await _wait(0.2)
	await _press(&"fart", 0.5)
	_check("jump: the fart button also jumps, with no charging (%s)" % str(farts), farts.size() == 1 and farts[0] == "Toot" and not p.belly.visible)
	await _wait(1.2)

	# ---------------------------------------------------------------- double jump
	_reset()
	await _wait(0.2)
	await _press(&"jump", 0.4)
	var before_y: float = p.global_position.y
	await _press(&"jump", 0.4)
	_check("double jump: the air press is a free Thunder (%s)" % str(farts), farts == ["Toot", "Thunder"])
	_check("double jump: Thunder speed (vy %.1f)" % p.velocity.y, p.velocity.y > 5.0 or p.global_position.y > before_y + 1.0)
	_check("double jump: no gas used (%.0f)" % tank.gas, tank.gas >= 99.9)
	await _press(&"jump", 0.1)
	_check("double jump: only once in the air (%s)" % str(farts), farts.size() == 2)
	await _wait(2.0)
	_check("double jump: landed", p.is_on_floor())
	farts.clear()
	await _press(&"jump", 0.3)
	await _press(&"jump", 0.1)
	_check("double jump: back after landing (%s)" % str(farts), farts == ["Toot", "Thunder"])
	# The Thunder is not cut short when the button is let go.
	await _wait(0.1)
	_check("double jump: Thunder keeps its speed after letting go (vy %.1f)" % p.velocity.y, p.velocity.y > 8.0)
	await _wait(2.0)

	# A stomp gives the air jump back.
	_reset()
	await _wait(0.2)
	await _press(&"jump", 0.3)
	await _press(&"jump", 0.1)
	var used_up: bool = p.simple_helper.air_jumps_left() == 0
	p.stomp_bounce()
	_check("stomp: the air jump comes back after a stomp bounce", used_up and p.simple_helper.air_jumps_left() == 1)
	await _wait(2.0)

	# ---------------------------------------------------------------- coyote time
	_reset(8.0)
	await _wait(0.4)
	Input.action_press(&"ui_right")
	var left_ground: bool = false
	for i in 120:
		await physics_frame
		if not p.is_on_floor():
			left_ground = true
			break
	farts.clear()
	await _wait(0.04)  # still inside the coyote time
	Input.action_release(&"ui_right")
	await _press(&"jump", 0.1)
	_check("coyote: a jump just after the ledge is a ground jump (%s)" % str(farts), left_ground and farts == ["Toot"])
	await _wait(2.5)
	_reset(8.0)
	await _wait(0.4)
	Input.action_press(&"ui_right")
	for i in 120:
		await physics_frame
		if not p.is_on_floor():
			break
	farts.clear()
	await _wait(0.25)  # too late for coyote
	Input.action_release(&"ui_right")
	await _press(&"jump", 0.1)
	_check("coyote: much later it is the air jump (%s)" % str(farts), farts == ["Thunder"])
	await _wait(2.5)

	# ---------------------------------------------------------------- jump buffer
	_reset()
	await _wait(0.2)
	await _press(&"jump", 0.3)
	await _press(&"jump", 0.1)  # air jump used up
	farts.clear()
	var pressed: bool = false
	for i in 200:
		await physics_frame
		if not pressed and p.velocity.y < 0.0 and p.get_feet_y() < 0.45:
			Input.action_press(&"jump")
			pressed = true
		if pressed and p.is_on_floor():
			break
	await _wait(0.1)
	Input.action_release(&"jump")
	_check("buffer: a jump pressed just before landing jumps on landing (%s, vy %.1f)" % [str(farts), p.velocity.y], pressed and farts == ["Toot"])
	await _wait(2.0)

	# ---------------------------------------------------------------- hover
	_reset()
	await _wait(0.2)
	var hovered: Array[int] = [0, 0]
	p.hover_started.connect(func() -> void: hovered[0] += 1)
	p.hover_stopped.connect(func() -> void: hovered[1] += 1)
	p.global_position = Vector3(OFF, 10.0, 0)
	var cloud: HoverCloud = p.hover_helper.cloud
	_check("hover: the cloud is hidden and harmless until he hovers", cloud != null and not cloud.visible and not cloud.is_active())
	Input.action_press(&"hover")
	await _wait(1.0)
	_check("hover: he floats (y %.1f, started with 10)" % p.global_position.y, p.is_hovering() and absf(p.global_position.y - 10.0) < 0.5)
	_check("hover: the cloud shows", cloud.visible and cloud.is_active())
	_check("hover: it uses gas (%.0f, about 75)" % tank.gas, tank.gas < 85.0 and tank.gas > 60.0)
	_check("hover: signals sent (%d started)" % hovered[0], hovered[0] == 1)
	# He can still steer.
	Input.action_press(&"ui_right")
	await _wait(0.5)
	Input.action_release(&"ui_right")
	_check("hover: steering still works (x %.1f)" % (p.global_position.x - OFF), p.global_position.x - OFF > 1.0)
	# Hold until empty.
	for i in 360:
		await physics_frame
		if fizzles > 0:
			break
	await _wait(0.3)
	_check("hover: out of gas he stops and falls (vy %.1f, gas %.1f)" % [p.velocity.y, tank.gas], not p.is_hovering() and p.velocity.y < -2.0 and tank.gas < 8.0)
	_check("hover: one fizzle when it runs out (%d)" % fizzles, fizzles == 1)
	_check("hover: cloud hidden again", not cloud.visible and hovered[1] >= 1)
	Input.action_release(&"hover")
	await _wait(2.0)

	# Jumping while holding hover still gives the full jump, then he hovers at the top.
	_reset()
	await _wait(0.2)
	start_y = p.global_position.y
	Input.action_press(&"hover")
	Input.action_press(&"jump")
	peak = 0.0
	for i in 40:
		await physics_frame
		peak = maxf(peak, p.global_position.y - start_y)
	_check("hover: hold both and the jump goes up fully first (%.2f m)" % peak, peak > 2.3)
	await _wait(0.8)
	var top_y: float = p.global_position.y
	await _wait(0.4)
	_check("hover: then he floats at the top (%.2f -> %.2f)" % [top_y, p.global_position.y], p.is_hovering() and absf(p.global_position.y - top_y) < 0.3)
	Input.action_release(&"hover")
	Input.action_release(&"jump")
	await _wait(2.0)

	# Free gas test modes: limited time, no gas used.
	options.set_gas_mode(DebugOptionsData.GasMode.NO_GAS)
	_reset()
	await _wait(0.2)
	p.global_position = Vector3(OFF, 10.0, 0)
	Input.action_press(&"hover")
	await _wait(2.0)
	_check("hover: NO GAS mode floats for a while at no cost (y %.1f gas %.0f)" % [p.global_position.y, tank.gas], p.is_hovering() and tank.gas >= 99.9)
	await _wait(1.5)
	_check("hover: NO GAS mode runs out after about 3 s (y %.1f)" % p.global_position.y, not p.is_hovering() and p.global_position.y < 9.0)
	Input.action_release(&"hover")
	await _wait(2.0)
	options.set_gas_mode(DebugOptionsData.GasMode.NORMAL)

	# ---------------------------------------------------------------- the cloud squashes enemies
	_reset()
	await _wait(0.2)
	var blob: Burpling = load("res://scenes/burpling.tscn").instantiate()
	blob.walk_speed = 0.0
	blob.position = Vector3(OFF + 5.0, 0.5, 0)
	world.add_child(blob)
	var popped: Array[int] = [0]
	blob.squashed.connect(func() -> void: popped[0] += 1)
	await _wait(0.3)
	_check("cloud: an enemy far from a not-hovering Fart Man is fine", not blob.is_squashed)
	p.global_position = Vector3(OFF + 5.0, 6.0, 0)  # his feet are 5 m up: out of reach
	p.velocity = Vector3.ZERO
	Input.action_press(&"hover")
	await _wait(0.5)
	_check("cloud: out of reach (feet %.1f m up) leaves it alone" % p.get_feet_y(), p.is_hovering() and not blob.is_squashed)
	p.global_position = Vector3(OFF + 5.0, 3.0, 0)  # feet 2 m up, enemy 0.5 m up: in the cloud
	p.velocity = Vector3.ZERO
	await _wait(0.4)
	_check("cloud: hovering over an enemy squashes it (%d)" % popped[0], popped[0] == 1)
	Input.action_release(&"hover")
	await _wait(1.5)

	# A hazard under the cloud is not touched, and a squashed-already enemy is not squashed twice.
	var spikes: Node3D = load("res://scenes/spiky_ball.tscn").instantiate()
	spikes.position = Vector3(OFF + 2.0, 0.5, 0)
	world.add_child(spikes)
	_reset(2.0)
	p.global_position = Vector3(OFF + 2.0, 3.0, 0)
	Input.action_press(&"hover")
	await _wait(0.6)
	_check("cloud: a spiky hazard is not squashed", is_instance_valid(spikes) and p.is_hovering())
	Input.action_release(&"hover")
	await _wait(1.5)
	spikes.queue_free()

	# A boss under the cloud takes no damage.
	var stage: Stage = load("res://scenes/stage_1_4.tscn").instantiate()
	stage.position = Vector3(0, 0, 0)
	root.add_child(stage)
	await _wait(0.4)
	var boss: Node = stage.find_child("SneezyWeezy", true, false)
	var hits_before: int = boss.hits
	var bp: Player = stage.player
	bp.flashing_left = 100000.0
	bp.gas_tank.gas = bp.gas_tank.max_gas
	options.set_simple_controls(true)
	bp.global_position = boss.global_position + Vector3(0, 3.0, 0)
	bp.velocity = Vector3.ZERO
	Input.action_press(&"hover")
	await _wait(0.6)
	var touching: bool = bp.hover_helper.cloud.area.get_overlapping_areas().has(boss)
	_check("cloud: it really overlaps the boss (hovering %s)" % str(bp.is_hovering()), touching)
	_check("cloud: the boss takes no damage and is still there", is_instance_valid(boss) and boss.hits == hits_before)
	Input.action_release(&"hover")
	stage.queue_free()
	await _wait(0.3)

	# ---------------------------------------------------------------- back to CLASSIC mid-hover
	options.set_simple_controls(true)
	_reset()
	await _wait(0.2)
	p.global_position = Vector3(OFF, 10.0, 0)
	Input.action_press(&"hover")
	await _wait(0.4)
	options.set_simple_controls(false)
	await _wait(0.2)
	_check("switching to CLASSIC stops the hover", not p.is_hovering() and not cloud.visible)
	Input.action_release(&"hover")
	await _wait(2.0)
	_reset()
	await _wait(0.2)
	Input.action_press(&"fart")
	await _wait(0.3)
	_check("CLASSIC again: the fart button charges", p.is_charging)
	Input.action_release(&"fart")
	await _wait(0.2)

	options.set_simple_controls(false)
	options.set_gas_mode(DebugOptionsData.GasMode.NORMAL)
	print("simple controls failures: %d" % failures)
	quit()
