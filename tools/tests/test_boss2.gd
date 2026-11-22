extends SceneTree
# Plays the whole Colonel Cork fight with fake moves: the hello scene (skipped by holding jump),
# then six stomps in three phases of two:
#   phase 1: the snort and red warning, the charge (hurts), the bonk, the stars, stomps
#   phase 2: "BOTS, ATTACK!" (Cork Bots), "CORKS!" then bouncing corks (red patches), faster charge
#   phase 3: "CORK RAIN!" then corks fall all around, then a charge there and back ("AGAIN!")
# Every hit sends beans flying, each phase change has a shout, and beating him rains beans.
# Then the pop and the gate opening, losing and starting over, and dodging his charge.

var failures: int = 0
var stage: Stage
var boss: ColonelCork
var player: Player
var door: Node3D
var gate: Node
var lost_count: int = 0
## How many beans appeared in the level, in all (counted as they appear).
var beans_made: int = 0
var phases_seen: Array[int] = []


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


func _is_fighting() -> bool:
	return boss.state in [ColonelCork.State.IDLE, ColonelCork.State.CORKS, ColonelCork.State.SUMMON, ColonelCork.State.RAIN,
		ColonelCork.State.WINDUP, ColonelCork.State.TURN, ColonelCork.State.CHARGE, ColonelCork.State.DIZZY]


func _until_fighting(seconds: float) -> bool:
	var left: float = seconds
	while not _is_fighting() and left > 0.0:
		await physics_frame
		left -= 1.0 / 60.0
	return _is_fighting()


func _hearts() -> int:
	return (player.get_node("Hearts") as Hearts).hearts


func _corks() -> Array[CorkShot]:
	var found: Array[CorkShot] = []
	for node: Node in get_nodes_in_group(&"boss_shots"):
		if node is CorkShot:
			found.append(node as CorkShot)
	return found


func _count_beans(node: Node) -> void:
	if node.scene_file_path == "res://scenes/bean.tscn":
		beans_made += 1


## Drops Fart Man onto the boss's head, falling.
func _stomp_head() -> void:
	player.flashing_left = 1000.0
	player.velocity = Vector3(0, -6, 0)
	player.global_position = boss.head.global_position + Vector3(0.5, 3.0, 0)
	await _wait(0.5)


## Stomps (waiting until he is in a fighting mood, trying again if he was moving).
## Returns true when the stomp counted. Fart Man goes back to a safe spot afterwards.
func _stomp_counts() -> bool:
	var target: int = boss.hits + 1
	for attempt in 4:
		await _until_fighting(30.0)
		await _stomp_head()
		if boss.hits >= target:
			break
	player.position = Vector3(30.0, 1.2, 0)
	player.velocity = Vector3.ZERO
	return boss.hits >= target


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
	boss.get_parent().child_entered_tree.connect(_count_beans)


func _run() -> void:
	var save: Node = root.get_node_or_null("SaveGame")
	if save != null:
		save.use_file("user://test_boss2_save.json")
		save.reset()
	_load_stage()
	boss.phase_changed.connect(func(n: int) -> void: phases_seen.append(n))
	await _wait(0.5)
	_check("he is a boss (group 'bosses')", boss.is_in_group(&"bosses"))
	_check("boss waits until he walks in", boss.state == ColonelCork.State.WAITING)
	_check("it takes 6 stomps in 3 phases of 2 (%d, %d)" % [boss.hits_to_win, boss.hits_per_phase],
		boss.hits_to_win == 6 and boss.hits_per_phase == 2)
	_check("he has a Cork Bot to call (bot_scene)", boss.bot_scene != null)
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

	# ------------------------------------------------------------------ PHASE 1
	# He snorts (red warning), then charges at the player standing in his way.
	_check("phase 1 to start with", boss.phase_now() == 0)
	_check("he starts at the right side", boss.position.x > 40.0)
	_check("snort and stamp first", await _until(ColonelCork.State.WINDUP, 5.0))
	player.position = Vector3(25.0, 1.2, 0)
	player.velocity = Vector3.ZERO
	player.flashing_left = 0.0
	_check("red warning shows while he winds up", boss.warning.visible)
	_check("no corks and no bots in phase 1", _corks().is_empty() and get_nodes_in_group(&"boss_minions").is_empty())
	var hearts_before: int = _hearts()
	_check("then he charges", await _until(ColonelCork.State.CHARGE, 5.0))
	var x0: float = boss.position.x
	await _wait(0.3)
	var speed1: float = (x0 - boss.position.x) / 0.3
	_check("phase 1 charge speed is about %.1f m/s (measured %.1f)" % [boss.charge_speed[0], speed1], absf(speed1 - boss.charge_speed[0]) < 1.0)
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
	var beans_before: int = beans_made
	await _stomp_head()
	_check("stomp 1 counts while dizzy (hits %d, state %s)" % [boss.hits, str(boss.state)], boss.hits == 1)
	_check("a hit sends a burst of about 8 beans (%d)" % (beans_made - beans_before), beans_made - beans_before >= boss.hit_beans)
	await _wait(1.0)
	player.flashing_left = 1000.0
	_check("bouncing back onto his head doesn't count twice (hits %d)" % boss.hits, boss.hits == 1)
	_check("stars gone after a stomp", not boss.stars.visible)
	player.position = Vector3(30.0, 1.2, 0)
	player.velocity = Vector3.ZERO

	# Stomp 2: even mid-charge, landing on his hat counts (a Thunder jump over him can do it).
	_check("he charges again, still phase 1", await _until(ColonelCork.State.CHARGE, 12.0) and boss.phase_now() == 0)
	var counted: bool = await _stomp_counts()
	_check("stomp 2 counts mid-charge (hits %d)" % boss.hits, counted and boss.hits == 2)
	_check("he stops charging after a stomp (state %s)" % str(boss.state), boss.state == ColonelCork.State.HIT)

	# ------------------------------------------------------------------ phase change 1
	_check("a phase change moment follows (shout and shake)", await _until(ColonelCork.State.PHASE, 5.0))
	_check("it announced phase 2 (%s)" % str(phases_seen), phases_seen == [1] and boss.phase_now() == 1)

	# ------------------------------------------------------------------ PHASE 2
	player.flashing_left = 1000.0
	player.position = Vector3(30.0, 1.2, 0)
	player.velocity = Vector3.ZERO
	# First he calls Cork Bots: a shout, a pause, then two roll out.
	_check("he calls Cork Bots", await _until(ColonelCork.State.SUMMON, 10.0))
	_check("no bots yet while he shouts", get_nodes_in_group(&"boss_minions").is_empty())
	await _wait(boss.summon_time + 0.15)
	var bots: Array[Node] = get_nodes_in_group(&"boss_minions")
	_check("two Cork Bots roll out (%d)" % bots.size(), bots.size() == 2 and bots[0] is CorkBot)
	if bots.size() > 0:
		var bean_count: int = beans_made
		(bots[0] as Burpling).drop_chance = 0.0
		(bots[0] as Burpling).squash()
		await _wait(0.2)
		_check("a Cork Bot can be squashed and drops beans (%d)" % (beans_made - bean_count), beans_made - bean_count >= 2)

	# Then "CORKS!" and a hat hop (the warning), then bouncing corks at where Fart Man stands.
	_check("then the corks", await _until(ColonelCork.State.CORKS, 8.0))
	await _wait(0.3)
	_check("no cork has flown yet while he warns", _corks().is_empty())
	await _wait(0.7)
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
	var shot: CorkShot = corks[0] if not corks.is_empty() else null
	if shot != null:
		_check("it is a bouncing cork (%d bounces)" % shot.bounces_left, shot.bounces_left == boss.cork_bounces)
		var y0: float = shot.global_position.y
		await _wait(0.5)
		_check("the cork lobs up and over slowly (y %.1f -> %.1f)" % [y0, shot.global_position.y], shot.global_position.y > y0 + 1.0)
	# Standing on the patch costs a heart when it lands.
	player.flashing_left = 0.0
	player.position = Vector3(marker_x, 1.0, 0)
	player.velocity = Vector3.ZERO
	var hearts_cork: int = _hearts()
	await _wait(2.2)
	_check("a cork landing on him costs a heart (%d -> %d)" % [hearts_cork, _hearts()], _hearts() == hearts_cork - 1)
	player.flashing_left = 1000.0
	player.position = Vector3(30.0, 1.2, 0)
	_check("after landing it bounces on instead of popping (%s)" % (str(shot.bounces_left) if is_instance_valid(shot) else "gone"),
		shot != null and is_instance_valid(shot) and shot.bounces_left < boss.cork_bounces)
	var gone: bool = false
	for i in 900:
		await physics_frame
		if _corks().is_empty():
			gone = true
			break
	_check("the bouncing corks finally pop into crumbs and disappear", gone or boss.state != ColonelCork.State.CORKS)

	# Phase 2 charges faster.
	_check("phase 2 is faster (%.1f -> %.1f)" % [boss.charge_speed[0], boss.charge_speed_now()], boss.charge_speed_now() > boss.charge_speed[0])
	_check("he charges again", await _until(ColonelCork.State.CHARGE, 12.0))
	var x1: float = boss.position.x
	var dir1: float = boss._dir
	await _wait(0.3)
	var speed2: float = absf(boss.position.x - x1) / 0.3
	_check("phase 2 charge speed is about %.1f m/s (measured %.1f)" % [boss.charge_speed[1], speed2], absf(speed2 - boss.charge_speed[1]) < 1.0)
	beans_before = beans_made
	counted = await _stomp_counts()
	_check("stomp 3 counts mid-charge (hits %d)" % boss.hits, counted and boss.hits == 3)
	_check("a hit sends beans (%d)" % (beans_made - beans_before), beans_made - beans_before >= boss.hit_beans)
	counted = await _stomp_counts()
	_check("stomp 4 lands (hits %d)" % boss.hits, counted and boss.hits == 4)

	# ------------------------------------------------------------------ phase change 2, PHASE 3
	_check("second phase change", await _until(ColonelCork.State.PHASE, 5.0))
	_check("it announced phase 3 (%s)" % str(phases_seen), phases_seen == [1, 2] and boss.phase_now() == 2)
	player.flashing_left = 1000.0
	# "CORK RAIN!" first (a warning with no corks), then corks fall all around Fart Man.
	_check("then the cork rain", await _until(ColonelCork.State.RAIN, 10.0))
	await _wait(0.5)
	_check("no corks yet while he warns", _corks().is_empty())
	var rain_ids: Dictionary = {}
	var rain_ok: bool = true
	var left: float = 12.0
	while boss.state == ColonelCork.State.RAIN and left > 0.0:
		await physics_frame
		left -= 1.0 / 60.0
		player.flashing_left = 1000.0
		for c: CorkShot in _corks():
			rain_ids[c.get_instance_id()] = true
			rain_ok = rain_ok and c.bounces_left == 0
	_check("corks rain down from his hat (%d corks, none bouncing)" % rain_ids.size(), rain_ids.size() >= 5 and rain_ok)

	# Then he charges there and straight back.
	var charges: int = 0
	var turns: int = 0
	var dirs: Array[float] = []
	var speeds: Array[float] = []
	var prev: ColonelCork.State = boss.state
	var last_x: float = boss.position.x
	left = 40.0
	while boss.state != ColonelCork.State.DIZZY and left > 0.0:
		await physics_frame
		left -= 1.0 / 60.0
		player.flashing_left = 1000.0
		if boss.state == ColonelCork.State.CHARGE:
			if prev != ColonelCork.State.CHARGE:
				charges += 1
				dirs.append(boss._dir)
			speeds.append(absf(boss.position.x - last_x) * 60.0)
		if boss.state == ColonelCork.State.TURN:
			turns += 1
		prev = boss.state
		last_x = boss.position.x
	_check("he charges twice, turning round at the wall (charges %d, turned %d)" % [charges, turns], charges == 2 and turns >= 1)
	_check("the second charge goes back the other way (%s)" % str(dirs), dirs.size() == 2 and dirs[0] == -dirs[1])
	var avg_speed: float = 0.0
	for v: float in speeds:
		avg_speed += v
	avg_speed /= maxf(float(speeds.size()), 1.0)
	_check("phase 3 charges fastest (%.1f m/s, setting %.1f)" % [avg_speed, boss.charge_speed[2]], absf(avg_speed - boss.charge_speed[2]) < 1.0)
	_check("then he crashes and gets dizzy", boss.state == ColonelCork.State.DIZZY)
	await _wait(0.4)

	# Stomp 5 while dizzy, then the last one.
	counted = await _stomp_counts()
	_check("stomp 5 lands (hits %d)" % boss.hits, counted and boss.hits == 5)
	var shower_before: int = beans_made
	var gate_before: bool = is_instance_valid(gate)
	var finished: bool = await _stomp_counts()
	_check("six stomps defeat him (hits %d, state %s, last %s)" % [boss.hits, str(boss.state), str(finished)], boss.state == ColonelCork.State.DEFEATED)
	await _wait(0.4)
	var early: int = beans_made - shower_before
	_check("the shower has only just begun (%d beans so far)" % early, early < 40)
	await _wait(2.4)
	var total: int = beans_made - shower_before
	_check("a huge shower of beans rains down (%d)" % total, total >= 44 + boss.hit_beans)
	_check("no corks left", _corks().is_empty())
	_check("his helpers are gone", get_nodes_in_group(&"boss_minions").is_empty())

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
