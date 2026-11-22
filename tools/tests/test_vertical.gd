extends SceneTree
# Checks the tall test levels and the new gadgets: one-way ledges, barrel cannons, wall jump
# (off unless switched on), the rising soup, the spring, both levels (parts, climb check),
# the camera when high up and falling, and the TEST LEVELS list.

var failures: int = 0
## The little test worlds sit this far to the right, away from the real levels.
const OFF: float = 300.0


func _initialize() -> void:
	_run()


func _wait(seconds: float) -> void:
	for i in int(seconds * 60.0):
		await physics_frame


func _check(label: String, ok: bool) -> void:
	print("%s: %s" % [label, "ok" if ok else "FAIL"])
	if not ok:
		failures += 1


func _press(action: StringName, seconds: float = 0.1) -> void:
	Input.action_press(action)
	await _wait(seconds)
	Input.action_release(action)
	await _wait(0.05)


## Holds the fart button for a full belly, then lets go (a Thunder).
func _thunder() -> void:
	await _press(&"fart", 0.55)


func _stage(path: String) -> Stage:
	var stage: Stage = load(path).instantiate()
	root.add_child(stage)
	await _wait(0.4)
	return stage


## Puts him somewhere new, standing still, with the camera already there.
func _put(stage: Stage, spot: Vector3) -> void:
	stage.player.global_position = spot
	stage.player.velocity = Vector3.ZERO
	stage.player.flashing_left = 0.0
	var cam: Camera3D = stage.get_node("Camera3D")
	cam.global_position = spot + cam.get("offset")


func _on_screen(camera: Camera3D, point: Vector3) -> bool:
	var size: Vector2 = camera.get_viewport().get_visible_rect().size
	var p: Vector2 = camera.unproject_position(point)
	return not camera.is_position_behind(point) and p.x >= 0.0 and p.x <= size.x and p.y >= 0.0 and p.y <= size.y


## A little flat world for one gadget at a time: a floor, optionally walls.
func _world() -> Node3D:
	var world := Node3D.new()
	root.add_child(world)
	_box(world, Vector3(OFF, -0.5, 0), Vector3(60, 1, 4))
	return world


func _box(parent: Node, centre: Vector3, size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = centre
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)
	parent.add_child(body)
	return body


func _run() -> void:
	# This test is about the CLASSIC charge-fart controls (SIMPLE is the default now).
	(root.get_node("DebugOptions") as DebugOptionsData).set_simple_controls(false)
	var save: Node = root.get_node_or_null("SaveGame")
	if save != null:
		save.use_file("user://test_vertical_save.json")
		save.reset()
	var options: DebugOptionsData = root.get_node_or_null("DebugOptions")

	# ---------------------------------------------------------------- one-way ledges
	var t1: Stage = await _stage("res://scenes/stage_t_1.tscn")
	var p: Player = t1.player
	_put(t1, Vector3(4, 1.2, 0))
	await _wait(0.3)
	await _thunder()
	await _wait(1.6)
	_check("one-way: a Thunder from below goes up through the leaf and lands on it (feet %.2f, floor %s)" % [p.get_feet_y(), str(p.is_on_floor())],
		absf(p.get_feet_y() - 3.6) < 0.1 and p.is_on_floor())
	await _wait(0.5)
	_check("one-way: he can stand on it (feet %.2f)" % p.get_feet_y(), absf(p.get_feet_y() - 3.6) < 0.1)
	await _press(&"ui_down", 0.2)
	await _wait(1.0)
	_check("one-way: holding down drops him through to the ground (feet %.2f)" % p.get_feet_y(), p.get_feet_y() < 0.2)
	# A small hop from the ground can't reach the leaf, and head bumps don't stick him.
	await _press(&"jump", 0.1)
	await _wait(1.0)
	_check("one-way: a little hop stays under the leaf", p.get_feet_y() < 0.2)

	# ---------------------------------------------------------------- the spring
	var world: Node3D = _world()
	var spring: Spring = load("res://scenes/spring.tscn").instantiate()
	spring.position = Vector3(OFF + 20, 0, 0)
	world.add_child(spring)
	var tester: Player = load("res://scenes/player.tscn").instantiate()
	tester.position = Vector3(OFF + 20, 6.0, 0)
	world.add_child(tester)
	tester.flashing_left = 1000.0
	await _wait(0.2)
	var peak: float = 0.0
	var bounces: Array[bool] = []
	spring.bounced.connect(func(mega: bool) -> void: bounces.append(mega))
	for i in 150:
		await physics_frame
		peak = maxf(peak, tester.global_position.y)
		if i > 40 and tester.velocity.y < 0.0 and peak > 4.0:
			break
	var plain_peak: float = peak
	_check("spring: a plain landing bounces (mega=%s) about 8 m up (peak y %.1f)" % [str(bounces), plain_peak],
		bounces.size() >= 1 and not bounces[0] and plain_peak > 9.0 and plain_peak < 12.5)
	await _wait(3.0)
	# Now drop him again and press jump just before he lands: a MEGA boing.
	bounces.clear()
	tester.global_position = Vector3(OFF + 20, 6.0, 0)
	tester.velocity = Vector3.ZERO
	var fell: int = 0
	while tester.global_position.y > 2.6 and fell < 200:
		await physics_frame
		fell += 1
	Input.action_press(&"jump")
	await physics_frame
	Input.action_release(&"jump")
	peak = 0.0
	for i in 150:
		await physics_frame
		peak = maxf(peak, tester.global_position.y)
	_check("spring: pressing jump just before landing is a MEGA boing (%s), higher (peak y %.1f vs %.1f)" % [str(bounces), peak, plain_peak],
		bounces.size() >= 1 and bounces[0] and peak > plain_peak + 4.0)
	world.queue_free()
	await _wait(0.2)

	# ---------------------------------------------------------------- wall jump
	world = _world()
	_box(world, Vector3(OFF - 0.5, 15, 0), Vector3(1, 30, 4))   # left wall, face at x = 0
	_box(world, Vector3(OFF + 4.5, 15, 0), Vector3(1, 30, 4))    # right wall, face at x = 4
	var plain: Player = load("res://scenes/player.tscn").instantiate()
	plain.position = Vector3(OFF + 2, 20.0, 0)
	world.add_child(plain)
	_check("wall jump: the normal player has it OFF and no WallJump node", not plain.wall_jump_enabled and plain.get_node_or_null("WallJump") == null)
	Input.action_press(&"ui_right")
	var fastest_plain: float = 0.0
	for i in 40:
		await physics_frame
		fastest_plain = minf(fastest_plain, plain.velocity.y)
	Input.action_release(&"ui_right")
	_check("wall jump off: he falls past the wall at full speed (%.1f m/s)" % fastest_plain, fastest_plain < -8.0)
	plain.queue_free()
	await _wait(0.2)

	var climber: Player = load("res://scenes/player.tscn").instantiate()
	climber.wall_jump_enabled = true
	climber.position = Vector3(OFF + 2, 25.0, 0)
	climber.flashing_left = 1000.0
	world.add_child(climber)
	await _wait(0.1)
	var helper: WallJump = climber.get_node_or_null("WallJump")
	_check("wall jump on: the WallJump node appears", helper != null)
	var kicks: Array[int] = [0]
	helper.wall_jumped.connect(func() -> void: kicks[0] += 1)
	Input.action_press(&"ui_right")
	var sliding_seen: bool = false
	for i in 50:
		await physics_frame
		if climber.is_on_wall():
			sliding_seen = sliding_seen or helper.is_sliding
	_check("wall slide: pushing at the wall slows his fall to %.1f m/s or less (now %.1f)" % [helper.slide_speed, climber.velocity.y],
		sliding_seen and climber.velocity.y >= -helper.slide_speed - 0.1)
	# Wall jumps up the shaft: kick off the right wall, cross, kick off the left wall, and so on.
	var start_y: float = climber.global_position.y
	var toward: StringName = &"ui_right"
	for hop in 4:
		var waited: int = 0
		while not climber.is_on_wall() and waited < 90:
			await physics_frame
			waited += 1
		var away: StringName = &"ui_left" if toward == &"ui_right" else &"ui_right"
		Input.action_release(toward)
		Input.action_press(away)
		Input.action_press(&"jump")
		await physics_frame
		Input.action_release(&"jump")
		await _wait(0.04)
		if hop == 0:
			_check("wall jump: the kick sends him up and away (vy %.1f, vx %.1f)" % [climber.velocity.y, climber.velocity.x],
				climber.velocity.y > 8.0 and climber.velocity.x < -4.0)
		await _wait(0.12)
		toward = away
	Input.action_release(&"ui_left")
	Input.action_release(&"ui_right")
	_check("wall jump: %d kicks climbed the shaft (%.1f m up from the slide start)" % [kicks[0], climber.global_position.y - start_y],
		kicks[0] >= 3 and climber.global_position.y > start_y - 2.0)
	world.queue_free()
	await _wait(0.2)

	# ---------------------------------------------------------------- free gas: Thunder, then Thunder in the air
	for mode in [DebugOptionsData.GasMode.FILL_ON_LAND, DebugOptionsData.GasMode.ALWAYS_FULL]:
		options.set_gas_mode(mode)
		_put(t1, Vector3(-3, 1.2, 0))
		await _wait(0.8)
		Input.action_press(&"fart")
		await _wait(0.55)
		Input.action_release(&"fart")
		await physics_frame
		Input.action_press(&"fart")
		await _wait(0.52)
		Input.action_release(&"fart")
		await _wait(1.8)
		_check("%s: Thunder then an air Thunder gets up a 7.2 m step (feet %.2f, floor %s)" % [DebugOptionsData.MODE_NAMES[mode], p.get_feet_y(), str(p.is_on_floor())],
			absf(p.get_feet_y() - 7.2) < 0.15 and p.is_on_floor())
	options.set_gas_mode(DebugOptionsData.GasMode.NORMAL)

	# ---------------------------------------------------------------- barrel cannons (in T-1)
	var barrel_a: BarrelCannon = t1.get_node("Barrels").get_child(0)
	var barrel_b: BarrelCannon = t1.get_node("Barrels").get_child(1)
	_put(t1, Vector3(-4, 53.4, 0))
	await _wait(0.5)
	_check("barrel: he hops in and it holds him (held %s, frozen %s)" % [str(barrel_a.held == p), str(p.frozen)], barrel_a.held == p and p.frozen)
	var hold_y: float = p.global_position.y
	var hearts_before: int = p.hearts.hearts
	p.hurt(p.global_position.x)
	await _wait(0.5)
	_check("barrel: he does not fall or get hurt while inside (y %.2f -> %.2f, hearts %d -> %d)" % [hold_y, p.global_position.y, hearts_before, p.hearts.hearts],
		absf(p.global_position.y - hold_y) < 0.05 and p.hearts.hearts == hearts_before)
	await _press(&"jump", 0.05)
	_check("barrel: jump fires him straight up (vy %.1f)" % p.velocity.y, p.velocity.y > 18.0 and not p.frozen)
	await _wait(0.5)
	_check("barrel: the shot reaches the next barrel and it catches him (held %s)" % str(barrel_b.held == p), barrel_b.held == p)
	_check("barrel: the next one swings (aim %.0f is between 30 and 60)" % barrel_b.current_aim, barrel_b.current_aim >= 29.9 and barrel_b.current_aim <= 60.1)
	await _wait(0.5)
	await _press(&"fart", 0.05)
	_check("barrel: fart fires it too, up and to the right (v = %s)" % str(p.velocity.snapped(Vector3.ONE * 0.1)), p.velocity.x > 8.0 and p.velocity.y > 8.0)
	await _wait(3.0)
	_check("barrel: the shot lands on the top ledge (x %.1f, feet %.1f, floor %s)" % [p.global_position.x, p.get_feet_y(), str(p.is_on_floor())],
		p.is_on_floor() and absf(p.get_feet_y() - 57.5) < 0.2 and p.global_position.x > 8.5)
	# A barrel releases him if he dies inside (no stuck player).
	_put(t1, Vector3(-4, 54.0, 0))
	await _wait(0.4)
	var held_then: bool = barrel_a.held == p
	p.respawned.emit()
	p.is_dying = true
	await _wait(0.2)
	p.is_dying = false
	_check("barrel: if he starts dying inside it lets him go (was held %s, now frozen %s)" % [str(held_then), str(p.frozen)], held_then and not p.frozen)

	# ---------------------------------------------------------------- camera when high up
	_put(t1, Vector3(0, 50.6, 0))
	await _wait(1.5)
	var camera: Camera3D = t1.get_node("Camera3D")
	_check("camera: standing at 50 m high he is on screen", _on_screen(camera, p.global_position + Vector3.UP) and _on_screen(camera, p.global_position + Vector3.DOWN))
	var worst_up: bool = true
	var lean_up: float = 0.0
	await _thunder()
	for i in 45:
		await physics_frame
		worst_up = worst_up and _on_screen(camera, p.global_position + Vector3.UP) and _on_screen(camera, p.global_position + Vector3.DOWN)
		lean_up = maxf(lean_up, camera.get("vertical_lean"))
	_check("camera: climbing a Thunder up there keeps him on screen and leans up (%.1f m)" % lean_up, worst_up and lean_up > 0.8)
	await _wait(2.0)
	# Falling a long way: drop from the top ledge onto shelf 3, then from the shelf to the leaves below.
	_put(t1, Vector3(-4, 50.6, 0))
	await _wait(0.5)
	p.global_position = Vector3(3.0, 70.0, 0)
	p.velocity = Vector3.ZERO
	var fall_ok: bool = true
	var lean_down: float = 0.0
	for i in 70:
		await physics_frame
		fall_ok = fall_ok and _on_screen(camera, p.global_position + Vector3.UP) and _on_screen(camera, p.global_position + Vector3.DOWN)
		lean_down = minf(lean_down, camera.get("vertical_lean"))
	_check("camera: falling keeps him on screen and leans down (%.1f m)" % lean_down, fall_ok and lean_down < -0.8)
	var old_stage: Node = load("res://scenes/stage_1_1.tscn").instantiate()
	_check("camera: it leans only in the test levels (stage 1-1 camera lean setting is 0)",
		float(old_stage.get_node("Camera3D").get("vertical_look_ahead")) == 0.0 and not bool(old_stage.get("player").get("wall_jump_enabled")))
	old_stage.free()
	t1.queue_free()
	await _wait(0.3)

	# ---------------------------------------------------------------- both levels: parts and climb check
	for id in ["t_1", "t_2"]:
		var stage: Stage = await _stage("res://scenes/stage_%s.tscn" % id)
		var toilets: int = stage.find_children("*", "Toilet", true, false).size()
		var cans: int = get_nodes_in_group(&"bean_cans").size()
		_check("%s: 3 golden beans (%d), 1 can (%d), 3+ toilets (%d)" % [id, stage.golden_total, cans, toilets],
			stage.golden_total == 3 and cans == 1 and toilets >= 3)
		_check("%s: saves nothing (id '%s') and returns to the test list (%s)" % [id, stage.stage_id, stage.map_scene],
			stage.stage_id == "" and stage.map_scene == "res://scenes/test_levels.tscn")
		var top: float = 0.0
		for b: Node in stage.find_children("*", "OneWayPlatform", true, false):
			top = maxf(top, (b as Node3D).position.y)
		_check("%s: it is tall (highest ledge %.0f m)" % [id, top], top > 45.0)
		_check("%s: wall jump is switched on for him" % id, stage.player.wall_jump_enabled)
		var kit: RefCounted = load("res://tools/kit_vertical.gd").new()
		kit.set("dry_run", true)
		var problems: Array = load("res://tools/stages/stage_%s.gd" % id).new().build(kit)
		_check("%s: climb check finds no problems (%s)" % [id, str(problems)], problems.is_empty())
		stage.queue_free()
		await _wait(0.3)
	# The climb check really does catch a too-high step.
	var bad: RefCounted = load("res://tools/kit_vertical.gd").new()
	bad.set("dry_run", true)
	bad.call("begin_test", "X", "", Vector3(0, 1, 0), Color.WHITE)
	bad.call("base", -5, 5, 0.0)
	bad.call("oneway", 0.0, 12.0, 4.0)
	var bad_problems: Array = bad.call("finish", "res://scenes/never_saved.tscn")
	_check("climb check: a 12 m step is caught (%d problem)" % bad_problems.size(), bad_problems.size() == 1)

	# ---------------------------------------------------------------- the rising soup (T-2)
	var t2: Stage = await _stage("res://scenes/stage_t_2.tscn")
	var soup: RisingSoup = t2.get_node("Hazards/BeanSoup")
	var q: Player = t2.player
	soup.start_delay = 0.1
	soup._wait_left = 0.1
	var soup_start: float = soup.surface_y
	q.flashing_left = 0.0
	await _wait(3.1)
	_check("soup: it rises (%.2f -> %.2f, about %.1f m in 3 s)" % [soup_start, soup.surface_y, soup.rise_speed * 3.0],
		absf((soup.surface_y - soup_start) - soup.rise_speed * 3.0) < 0.4)
	# A toilet flush makes it rest.
	var toilet: Toilet = t2.find_children("*", "Toilet", true, false)[0]
	toilet.flushed.emit()
	var before_rest: float = soup.surface_y
	await _wait(2.0)
	_check("soup: it rests after a toilet is flushed (%.2f -> %.2f)" % [before_rest, soup.surface_y], absf(soup.surface_y - before_rest) < 0.05)
	# Catching him: lose a heart, back to the checkpoint, soup drops below.
	_put(t2, Vector3(-3, 4.6, 0))
	await _wait(0.3)
	q.set_checkpoint(Vector3(-8, 1.5, 0))
	var hearts_were: int = q.hearts.hearts
	soup.surface_y = 8.0
	await _wait(0.2)
	_check("soup: it hurts (hearts %d -> %d)" % [hearts_were, q.hearts.hearts], q.hearts.hearts == hearts_were - 1)
	_check("soup: it pops him back to the checkpoint (%s)" % str(q.global_position.snapped(Vector3.ONE * 0.1)),
		q.global_position.distance_to(Vector3(-8, 1.5, 0)) < 1.0)
	_check("soup: it drops below him afterwards (soup %.1f, his feet %.1f)" % [soup.surface_y, q.get_feet_y()], soup.surface_y < q.get_feet_y() - 3.0)
	# Last heart: he lies down and comes back as usual, soup not stuck above him.
	await _wait(2.0)
	q.flashing_left = 0.0
	soup.surface_y = 8.0
	for i in 3:
		q.flashing_left = 0.0
		soup.surface_y = 8.0
		await _wait(0.1)
	await _wait(q.death_time + 0.5)
	_check("soup: three catches in a row still end with him safe and standing (feet %.1f, soup %.1f, hearts %d)" % [q.get_feet_y(), soup.surface_y, q.hearts.hearts],
		q.get_feet_y() > soup.surface_y and not q.is_dying)
	t2.queue_free()
	await _wait(0.3)

	# ---------------------------------------------------------------- the test levels list
	if options != null:
		options.set_gas_mode(DebugOptionsData.GasMode.NORMAL)
	var menu: StartMenu = load("res://scenes/start_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	await _wait(0.5)
	_check("menu: TEST LEVELS is shown", menu.test_levels_label != null and menu.test_levels_label.visible)
	await _press(&"ui_down", 0.1)
	_check("menu: down from NEW GAME picks TEST LEVELS (choice %d)" % menu.choice, menu.choice == 2)
	await _press(&"ui_up", 0.1)
	_check("menu: up goes back to NEW GAME (choice %d)" % menu.choice, menu.choice == 1)
	await _press(&"ui_down", 0.1)
	await _press(&"ui_accept", 0.1)
	await _wait(0.5)
	var scene_name: String = current_scene.name if current_scene != null else "none"
	_check("menu: choosing TEST LEVELS opens the list (now '%s')" % scene_name, scene_name == "TestLevels")
	var list: TestLevels = current_scene as TestLevels
	await _wait(0.4)
	await _press(&"ui_down", 0.1)
	_check("list: down picks the second row (%d)" % list.choice, list.choice == 1)
	await _press(&"ui_up", 0.1)
	await _press(&"ui_accept", 0.1)
	await _wait(0.8)
	scene_name = current_scene.name if current_scene != null else "none"
	_check("list: choosing T-1 opens it (now '%s')" % scene_name, scene_name == "StageT_1")
	# Clearing it goes back to the list and saves nothing.
	var level: Stage = current_scene as Stage
	await _wait(0.5)
	level.return_delay = 0.3
	if save != null:
		save.reset()
	level._on_bean_can_opened()
	await _wait(1.0)
	scene_name = current_scene.name if current_scene != null else "none"
	_check("list: clearing a test level returns to the list (now '%s'), nothing saved" % scene_name,
		scene_name == "TestLevels" and (save == null or not save.has_progress()))
	list = current_scene as TestLevels
	await _wait(0.4)
	await _press(&"ui_down", 0.1)
	await _press(&"ui_down", 0.1)
	_check("list: BACK is the last row (%d)" % list.choice, list.choice == 2)
	await _press(&"ui_accept", 0.1)
	await _wait(0.8)
	scene_name = current_scene.name if current_scene != null else "none"
	_check("list: BACK returns to the start menu (now '%s')" % scene_name, scene_name == "StartMenu")

	if save != null:
		save.reset()
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://test_vertical_save.json"))
	print("vertical failures: %d" % failures)
	quit()
