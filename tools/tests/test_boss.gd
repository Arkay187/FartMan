extends SceneTree
# Plays the Sneezy Weezy fight with fake moves: the hello scene (skipped by holding jump), then
# six stomps in three phases of two:
#   phase 1: pollen along the floor, after a wind-up
#   phase 2: she tips her head back first, then puffs hop through the air, and petals fall
#   phase 3: she calls Burpling friends, then sneezes three times in a row
# Every hit sends beans flying, the phase changes have a shout, and beating her rains beans.
# Then the goodbye and the gate opening.

var failures: int = 0
var stage: Stage
var boss: SneezyWeezy
var player: Player
## How many beans came out of the boss's level, in all (counted as they appear).
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


func _is_stompable() -> bool:
	return boss.state in [SneezyWeezy.State.IDLE, SneezyWeezy.State.WINDUP, SneezyWeezy.State.TIRED, SneezyWeezy.State.SUMMON]


## Waits until the boss is in a state (or the time runs out).
func _until(state: SneezyWeezy.State, seconds: float) -> bool:
	var left: float = seconds
	while boss.state != state and left > 0.0:
		await physics_frame
		left -= 1.0 / 60.0
	return boss.state == state


func _until_stompable(seconds: float) -> bool:
	var left: float = seconds
	while not _is_stompable() and left > 0.0:
		await physics_frame
		left -= 1.0 / 60.0
	return _is_stompable()


## Lets Fart Man fall onto her head (any time she is fighting). Tries again if she was moving.
func _stomp_head() -> bool:
	var target: int = boss.hits + 1
	for attempt in 4:
		await _until_stompable(30.0)
		player.flashing_left = 1000.0
		player.velocity = Vector3(0, -6, 0)
		player.global_position = boss.head.global_position + Vector3(0.6, 2.5, 0)
		await _wait(0.6)
		if boss.hits >= target:
			break
	player.global_position = Vector3(8.0, 1.2, 0)
	player.velocity = Vector3.ZERO
	return boss.hits >= target


func _count_beans(node: Node) -> void:
	if node.scene_file_path == "res://scenes/bean.tscn":
		beans_made += 1


## The pollen clouds that exist right now.
func _clouds() -> Array[Pollen]:
	var found: Array[Pollen] = []
	for node: Node in get_nodes_in_group(&"boss_shots"):
		if node is Pollen:
			found.append(node as Pollen)
	return found


func _petals() -> int:
	var n: int = 0
	for node: Node in get_nodes_in_group(&"boss_shots"):
		if node is FallingPetal:
			n += 1
	return n


func _run() -> void:
	var save: Node = root.get_node_or_null("SaveGame")
	if save != null:
		save.use_file("user://test_boss_save.json")
		save.reset()
	stage = load("res://scenes/stage_1_4.tscn").instantiate()
	root.add_child(stage)
	player = stage.player
	boss = stage.find_child("SneezyWeezy", true, false)
	boss.get_parent().child_entered_tree.connect(_count_beans)
	boss.phase_changed.connect(func(n: int) -> void: phases_seen.append(n))
	await _wait(0.5)
	_check("boss waits until he walks in", boss.state == SneezyWeezy.State.WAITING)
	_check("it takes 6 stomps in 3 phases of 2 (%d, %d)" % [boss.hits_to_win, boss.hits_per_phase],
		boss.hits_to_win == 6 and boss.hits_per_phase == 2)
	_check("she has a Burpling to call (friend_scene)", boss.friend_scene != null)
	var gate: Node = stage.find_child("Gate", true, false)

	# Walk through the door. The hello scene starts and takes over his buttons.
	player.position = Vector3(9.0, 1.2, 0)
	await _wait(0.5)
	_check("hello scene runs, buttons locked (state %s, locked %s)" % [str(boss.state), str(player.input_locked)],
		boss.state == SneezyWeezy.State.INTRO and player.input_locked)
	# Hold jump to skip it.
	Input.action_press(&"jump")
	await _wait(1.3)
	Input.action_release(&"jump")
	await _wait(0.3)
	_check("held jump skips the hello (state %s, locked %s)" % [str(boss.state), str(player.input_locked)],
		boss.state != SneezyWeezy.State.INTRO and not player.input_locked)
	_check("hello is remembered as seen", save == null or save.has_seen("sneezy_hello"))

	# Keep him safe while we watch: blinking and untouchable.
	player.flashing_left = 1000.0
	player.position = Vector3(8.0, 1.2, 0)

	# ------------------------------------------------------------------ PHASE 1
	_check("phase 1 to start with", boss.phase_now() == 0)
	# The wind-up comes first (face puffs up), then pollen on the floor rolling left.
	var cloud: Pollen = null
	var saw_windup: bool = false
	var saw_puff: bool = false
	for i in 900:
		await physics_frame
		if boss.state == SneezyWeezy.State.WINDUP:
			saw_windup = true
			saw_puff = saw_puff or boss.face.scale.x > 1.1
		cloud = get_first_node_in_group(&"boss_shots") as Pollen
		if cloud != null:
			break
	_check("a wind-up (state and puffed-up face) comes before the first pollen (%s, %s)" % [str(saw_windup), str(saw_puff)],
		cloud != null and saw_windup and saw_puff)
	if cloud != null:
		var x0: float = cloud.position.x
		await _wait(0.5)
		_check("pollen rolls left along the floor (%.1f -> %.1f, y=%.2f)" % [x0, cloud.position.x, cloud.position.y],
			cloud.position.x < x0 - 1.5 and cloud.position.y < 1.0 and cloud.hop_height == 0.0)

	# Stomp 1: her head is up and she is sneezing. A jump on the head counts anyway.
	var beans_before: int = beans_made
	var state_then: SneezyWeezy.State = boss.state
	player.velocity = Vector3(0, -6, 0)
	player.global_position = boss.head.global_position + Vector3(0.6, 2.5, 0)
	await _wait(0.5)
	_check("a stomp counts even when she isn't drooping (state was %s, hits %d)" % [str(state_then), boss.hits],
		boss.hits == 1 and state_then != SneezyWeezy.State.TIRED)
	_check("a hit sends a burst of about 8 beans (%d)" % (beans_made - beans_before), beans_made - beans_before >= boss.hit_beans)
	# Bouncing straight back onto her head must not count as a second hit.
	await _wait(1.0)
	_check("bouncing back onto her head doesn't count twice (hits %d)" % boss.hits, boss.hits == 1)
	player.global_position = Vector3(8.0, 1.2, 0)

	# Stomp 2 while she droops after her sneezes.
	_check("she gets tired after the sneezes", await _until(SneezyWeezy.State.TIRED, 25.0))
	_check("stomp 2 lands", await _stomp_head() and boss.hits == 2)

	# ------------------------------------------------------------------ phase change 1
	_check("a phase change moment follows (shout and shake)", await _until(SneezyWeezy.State.PHASE, 5.0))
	_check("it announced phase 2 (%s)" % str(phases_seen), phases_seen == [1] and boss.phase_now() == 1)
	_check("stomps don't count during the phase change", boss.state == SneezyWeezy.State.PHASE)

	# ------------------------------------------------------------------ PHASE 2
	# She tips her head back (the tell), then a puff hops through the air; petals fall too.
	player.global_position = Vector3(8.0, 1.2, 0)
	var saw_tilt: bool = false
	var hop: Pollen = null
	var petal_seen: bool = false
	for i in 1800:
		await physics_frame
		if boss.state == SneezyWeezy.State.WINDUP and boss.face.rotation.z > 0.2:
			saw_tilt = true
		petal_seen = petal_seen or _petals() > 0
		for c: Pollen in _clouds():
			if c.hop_height > 0.0:
				hop = c
		if hop != null and petal_seen:
			break
	_check("she tips her head back before the air puff (%s)" % str(saw_tilt), saw_tilt and hop != null)
	if hop != null:
		var ys: Array[float] = []
		for i in 30:
			await _wait(0.05)
			if is_instance_valid(hop):
				ys.append(hop.global_position.y)
		_check("the puff hops through the air (height %.1f to %.1f)" % [ys.min(), ys.max()], ys.size() > 5 and ys.max() - ys.min() > 1.0)
	_check("petals fall from above in phase 2", petal_seen)
	_check("stomp 3 lands", await _stomp_head() and boss.hits == 3)
	await _wait(3.0)
	_check("stomp 4 lands", await _stomp_head() and boss.hits == 4)

	# ------------------------------------------------------------------ phase change 2, PHASE 3
	_check("second phase change", await _until(SneezyWeezy.State.PHASE, 5.0))
	_check("it announced phase 3 (%s)" % str(phases_seen), phases_seen == [1, 2] and boss.phase_now() == 2)
	_check("she calls her friends first", await _until(SneezyWeezy.State.SUMMON, 15.0))
	var friends_before: int = get_nodes_in_group(&"boss_minions").size()
	_check("none are out yet while she is shouting (%d)" % friends_before, friends_before == 0)
	await _wait(boss.summon_time + 0.9)
	var friends: Array[Node] = get_nodes_in_group(&"boss_minions")
	_check("two Burpling friends pop out (%d)" % friends.size(), friends.size() == 2)
	if friends.size() > 0:
		var friend := friends[0] as Burpling
		var before_friend: int = beans_made
		friend.drop_chance = 0.0
		friend.squash()
		await _wait(0.2)
		_check("a friend can be squashed and drops beans (%d)" % (beans_made - before_friend), beans_made - before_friend >= 2)

	# The triple sneeze: at least three clouds in one round, ground and air.
	var ids: Dictionary = {}
	var any_air: bool = false
	var left: float = 30.0
	while boss.state != SneezyWeezy.State.TIRED and left > 0.0:
		await physics_frame
		left -= 1.0 / 60.0
		for c: Pollen in _clouds():
			ids[c.get_instance_id()] = true
			any_air = any_air or c.hop_height > 0.0
	_check("three sneezes in a row, ground and air (%d clouds, air %s)" % [ids.size(), str(any_air)], ids.size() >= 3 and any_air)

	# Stomp 5, then the last one, with the beans counted.
	_check("stomp 5 lands", await _stomp_head() and boss.hits == 5)
	_check("her friends are still around, she doesn't summon more than the limit", get_nodes_in_group(&"boss_minions").size() <= boss.max_friends)
	_check("she is stompable again after the shout", await _until_stompable(30.0))
	var shower_before: int = beans_made
	var last: bool = await _stomp_head()
	_check("six stomps defeat her (hits %d, last %s)" % [boss.hits, str(last)], boss.state == SneezyWeezy.State.DEFEATED)
	await _wait(0.4)
	var early: int = beans_made - shower_before
	_check("the shower has only just begun (%d beans so far)" % early, early < 40)
	await _wait(2.4)
	var total: int = beans_made - shower_before
	_check("a huge shower of beans rains down (%d)" % total, total >= 44 + boss.hit_beans)
	_check("no pollen left", get_nodes_in_group(&"boss_shots").is_empty())
	_check("her friends are gone", get_nodes_in_group(&"boss_minions").is_empty())

	# Goodbye scene, then the gate opens (hold jump to skip it).
	_check("gate still shut during the goodbye", is_instance_valid(gate))
	Input.action_press(&"jump")
	await _wait(1.5)
	Input.action_release(&"jump")
	await _wait(0.5)
	_check("gate opens (gone: %s), buttons free again (%s)" % [str(not is_instance_valid(gate) or gate.is_queued_for_deletion()), str(not player.input_locked)],
		(not is_instance_valid(gate) or gate.is_queued_for_deletion()) and not player.input_locked)

	if save != null:
		save.reset()
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://test_boss_save.json"))
	print("boss failures: %d" % failures)
	quit()
