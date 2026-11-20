extends SceneTree
# Plays the whole Colonel Cork fight with fake moves: the hello scene (skipped by holding jump),
# the snort and red warning, the charge (hurts, and gets faster each round), the bonk and the
# stars, stomps (while dizzy and mid-charge), the hit pause, corks after each stomp (with a
# warning patch on the floor), the pop and the gate opening. Then losing and starting over.

var failures: int = 0
var stage: Stage
var boss: ColonelCork
var player: Player
var door: Node3D
var gate: Node
var lost_count: int = 0


func _initialize() -> void:
	_run()


func _wait(seconds: float) -> void:
	for i in int(seconds * 60.0):
		await physics_frame


func _check(label: String, ok: bool) -> void:
	print("%s: %s" % [label, "ok" if ok else "FAIL"])
	if not ok:
		failures += 1


## Waits until the boss is in a state (or the time runs out).
func _until(state: ColonelCork.State, seconds: float) -> bool:
	var left: float = seconds
	while boss.state != state and left > 0.0:
		await physics_frame
		left -= 1.0 / 60.0
	return boss.state == state


func _hearts() -> int:
	return (player.get_node("Hearts") as Hearts).hearts


func _corks() -> Array[CorkShot]:
	var found: Array[CorkShot] = []
	for node: Node in get_nodes_in_group(&"boss_shots"):
		if node is CorkShot:
			found.append(node as CorkShot)
	return found


## Drops Fart Man onto the boss's head, falling.
func _stomp_head() -> void:
	player.flashing_left = 1000.0
	player.velocity = Vector3(0, -6, 0)
	player.global_position = boss.head.global_position + Vector3(0.5, 3.0, 0)
	await _wait(0.5)


## Ends a fight politely (like losing it) and waits for his pending pauses to run out,
## so the stage can be thrown away without his timers waking up afterwards.
func _end_fight() -> void:
	player.respawned.emit()
	await _wait(2.5)


func _load_stage() -> void:
	if stage != null:
		stage.free()
	stage = load("res://scenes/stage_2_4.tscn").instantiate()
	root.add_child(stage)
	player = stage.player
	boss = stage.find_child("ColonelCork", true, false) as ColonelCork
	door = stage.find_child("Door", true, false)
	gate = stage.find_child("Gate", true, false)


func _run() -> void:
	var save: Node = root.get_node_or_null("SaveGame")
	if save != null:
		save.use_file("user://test_boss2_save.json")
		save.reset()
	_load_stage()
	await _wait(0.5)
	_check("he is a boss (group 'bosses')", boss.is_in_group(&"bosses"))
	_check("boss waits until he walks in", boss.state == ColonelCork.State.WAITING)
	_check("the door starts open (y=%.1f)" % door.position.y, door.position.y < 0.0)

	# Walk through the door: the hello scene starts, buttons lock, the door slams shut.
	player.position = Vector3(11.5, 1.2, 0)
	await _wait(0.8)
	_check("hello scene runs, buttons locked (state %s, locked %s)" % [str(boss.state), str(player.input_locked)],
		boss.state == ColonelCork.State.INTRO and player.input_locked)
	_check("door shuts behind him (y=%.1f)" % door.position.y, door.position.y > 5.0)
	var camera: Camera3D = get_root().get_camera_3d()
	_check("camera keeps the Colonel in the shot", camera != null and camera.get("also_show").has(boss))
	Input.action_press(&"jump")
	await _wait(1.3)
	Input.action_release(&"jump")
	await _wait(0.3)
	_check("held jump skips the hello (state %s, locked %s)" % [str(boss.state), str(player.input_locked)],
		boss.state != ColonelCork.State.INTRO and not player.input_locked)
	_check("hello is remembered as seen", save == null or save.has_seen("cork_hello"))

	# Round 1: he snorts (red warning), then charges at the player standing in his way.
	_check("he starts at the right side", boss.position.x > 40.0)
	_check("snort and stamp first", await _until(ColonelCork.State.WINDUP, 5.0))
	player.position = Vector3(25.0, 1.2, 0)
	player.velocity = Vector3.ZERO
	player.flashing_left = 0.0
	_check("red warning shows while he winds up", boss.warning.visible)
	var hearts_before: int = _hearts()
	_check("then he charges", await _until(ColonelCork.State.CHARGE, 5.0))
	var x0: float = boss.position.x
	await _wait(0.3)
	var speed1: float = (x0 - boss.position.x) / 0.3
	_check("round 1 charge speed is about %.1f m/s (measured %.1f)" % [boss.charge_speed[0], speed1], absf(speed1 - boss.charge_speed[0]) < 1.0)
	await _wait(2.0)
	_check("the charge hurts when it runs into him (hearts %d -> %d)" % [hearts_before, _hearts()], _hearts() == hearts_before - 1)
	player.flashing_left = 1000.0
	player.position = Vector3(30.0, 1.2, 0)

	# Crash into the wall: bonk, stars, a sunk head.
	_check("he bonks into the left wall and gets dizzy", await _until(ColonelCork.State.DIZZY, 8.0))
	await _wait(0.6)
	_check("stars circle his head (visible %s)" % str(boss.stars.visible), boss.stars.visible)
	_check("his head sinks when dizzy (y=%.1f)" % boss.head.position.y, boss.head.position.y < boss.head_up.y - 0.5)
	_check("he stopped at the wall (x=%.1f)" % boss.position.x, absf(boss.position.x - boss.arena_left_x) < 0.2)

	# Stomp 1 while dizzy. The bounce back onto his head must not count twice (hit pause).
	await _stomp_head()
	_check("stomp 1 counts while dizzy (hits %d, state %s)" % [boss.hits, str(boss.state)], boss.hits == 1)
	await _wait(1.0)
	player.flashing_left = 1000.0
	_check("bouncing back onto his head doesn't count twice (hits %d)" % boss.hits, boss.hits == 1)
	_check("stars gone after a stomp", not boss.stars.visible)
	player.position = Vector3(30.0, 1.2, 0)
	player.velocity = Vector3.ZERO

	# After the stomp he lobs corks at where Fart Man stands, with a red patch on the floor.
	_check("he lobs corks after the first stomp", await _until(ColonelCork.State.CORKS, 8.0))
	await _wait(0.3)
	var corks: Array[CorkShot] = _corks()
	_check("a cork is flying (%d)" % corks.size(), corks.size() >= 1)
	var markers: int = 0
	var marker_x: float = 0.0
	for node: Node in get_nodes_in_group(&"boss_shots"):
		if node is MeshInstance3D:
			markers += 1
			marker_x = (node as Node3D).global_position.x
	_check("a red warning patch is on the floor where it will land (x=%.1f, player at %.1f)" % [marker_x, player.global_position.x],
		markers >= 1 and absf(marker_x - player.global_position.x) < 0.6)
	if not corks.is_empty():
		var y0: float = corks[0].global_position.y
		await _wait(0.8)
		_check("the cork lobs up and over slowly (y %.1f -> %.1f)" % [y0, corks[0].global_position.y], corks[0].global_position.y > y0 + 1.0)
	# Standing on the patch costs a heart when it lands.
	player.flashing_left = 0.0
	player.position = Vector3(marker_x, 1.0, 0)
	player.velocity = Vector3.ZERO
	var hearts_cork: int = _hearts()
	await _wait(2.0)
	_check("a cork landing on him costs a heart (%d -> %d)" % [hearts_cork, _hearts()], _hearts() == hearts_cork - 1)
	player.flashing_left = 1000.0
	player.position = Vector3(30.0, 1.2, 0)
	var gone: bool = false
	for i in 600:
		await physics_frame
		if _corks().is_empty():
			gone = true
			break
	_check("corks pop into crumbs and disappear", gone or boss.state != ColonelCork.State.CORKS)

	# Round 2 charges faster, towards the right wall.
	_check("round 2 is faster (%.1f -> %.1f)" % [boss.charge_speed[0], boss.charge_speed_now()], boss.charge_speed_now() > boss.charge_speed[0])
	_check("he charges again", await _until(ColonelCork.State.CHARGE, 10.0))
	_check("the second charge starts from the left wall (x=%.1f)" % boss.position.x, boss.position.x < 12.0)
	var x1: float = boss.position.x
	await _wait(0.3)
	var speed2: float = (boss.position.x - x1) / 0.3
	_check("round 2 charge speed is about %.1f m/s (measured %.1f)" % [boss.charge_speed[1], speed2], absf(speed2 - boss.charge_speed[1]) < 1.0)

	# Stomp 2: even mid-charge, landing on his hat counts (a Thunder jump over him can do it).
	await _stomp_head()
	_check("stomp 2 counts mid-charge (hits %d)" % boss.hits, boss.hits == 2)
	_check("he stops charging after a stomp (state %s)" % str(boss.state), boss.state == ColonelCork.State.HIT)
	player.position = Vector3(30.0, 1.2, 0)
	player.velocity = Vector3.ZERO

	# Round 3: more corks, faster again, then the last stomp.
	_check("he lobs a bigger volley", await _until(ColonelCork.State.CORKS, 8.0))
	await _wait(0.2)
	_check("round 3 is even faster (%.1f)" % boss.charge_speed_now(), boss.charge_speed_now() > boss.charge_speed[1])
	_check("he charges and bonks again", await _until(ColonelCork.State.DIZZY, 20.0))
	await _wait(0.6)
	var gate_before: bool = is_instance_valid(gate)
	await _stomp_head()
	_check("three stomps defeat him (hits %d, state %s)" % [boss.hits, str(boss.state)], boss.state == ColonelCork.State.DEFEATED)
	_check("no corks left", _corks().is_empty())

	# Goodbye: he pops like a champagne cork, then the gate opens (hold jump to skip).
	await _wait(0.3)
	_check("gate still shut during the goodbye", gate_before and is_instance_valid(gate) and not gate.is_queued_for_deletion())
	Input.action_press(&"jump")
	await _wait(1.5)
	Input.action_release(&"jump")
	await _wait(0.8)
	var gate_gone: bool = not is_instance_valid(gate) or gate.is_queued_for_deletion()
	_check("gate opens (gone: %s), buttons free again (%s)" % [str(gate_gone), str(not player.input_locked)], gate_gone and not player.input_locked)
	_check("he popped away (visible %s, height %.1f)" % [str(boss.visual.visible), boss.visual.position.y], not boss.visual.visible or boss.visual.position.y > 10.0)
	_check("the door opens again", door.position.y < 0.0)
	_check("camera lets go of him", not camera.get("also_show").has(boss))
	_check("goodbye is remembered as seen", save == null or save.has_seen("cork_goodbye"))

	# Losing: he starts over and the door opens.
	_load_stage()
	boss.fight_lost.connect(func() -> void: lost_count += 1)
	await _wait(0.5)
	player.position = Vector3(11.5, 1.2, 0)
	await _wait(0.5)
	_check("fight restarts straight away the second time (hello already seen, state %s)" % str(boss.state),
		boss.state == ColonelCork.State.IDLE or boss.state == ColonelCork.State.WINDUP)
	var hearts: Hearts = player.get_node("Hearts") as Hearts
	hearts.hearts = 1
	player.flashing_left = 0.0
	player.hurt(player.global_position.x + 1.0)
	await _wait(player.death_time + 0.5)
	_check("losing sends fight_lost (%d)" % lost_count, lost_count == 1)
	_check("he goes back to waiting at his start (state %s, x=%.1f)" % [str(boss.state), boss.position.x],
		boss.state == ColonelCork.State.WAITING and absf(boss.position.x - 40.5) < 0.1)
	_check("the door is open again so he can go back to the toilet", door.position.y < 0.0)
	_check("no corks left", _corks().is_empty())
	player.position = Vector3(11.5, 1.2, 0)
	await _wait(0.5)
	_check("walking in again starts the fight again (state %s)" % str(boss.state), boss.state != ColonelCork.State.WAITING)

	await _end_fight()

	# Dodging: a Thunder jump (power 16) at the right moment clears his charge. How early or late can it be?
	for gap in [5.9, 4.8, 3.7]:
		_load_stage()
		await _wait(0.5)
		player.position = Vector3(11.5, 1.2, 0)
		await _wait(0.3)
		await _until(ColonelCork.State.WINDUP, 5.0)
		player.position = Vector3(25.0, 1.2, 0)
		player.velocity = Vector3.ZERO
		player.flashing_left = 0.0
		await _until(ColonelCork.State.CHARGE, 5.0)
		var start_hearts: int = _hearts()
		var jumped: bool = false
		for i in 600:
			await physics_frame
			if not jumped and boss.position.x - player.global_position.x <= gap and player.is_on_floor():
				player.velocity.y = player.thunder_power
				jumped = true
			if boss.state != ColonelCork.State.CHARGE:
				break
		var safe: bool = jumped and _hearts() == start_hearts and (boss.state == ColonelCork.State.DIZZY or boss.state == ColonelCork.State.HIT)
		_check("dodge: jumping %.1f m before he arrives is safe, or even lands a stomp (hearts %d -> %d, jumped %s)" % [gap, start_hearts, _hearts(), str(jumped)], safe)
		await _end_fight()

	if save != null:
		save.reset()
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://test_boss2_save.json"))
	print("boss2 failures: %d" % failures)
	quit()
