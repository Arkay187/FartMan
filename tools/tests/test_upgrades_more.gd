extends "res://tools/tests/upgrade_test_base.gd"
# Checks the second half of the shop upgrades in a real stage: fireballs, chilli, spicy start, bean magnet,
# lucky beans, the secret sniffer, everything at once, and UPGRADES OFF changing nothing.


func _run() -> void:
	await _setup()

	# The baseline: no upgrades.
	await _stage({})
	var base: Dictionary = _numbers()
	var base_run: float = await _run_distance()

	# ---------------------------------------------------------------- fireballs
	for lvl: int in [0, 1, 2]:
		await _stage({"more_fireballs": lvl} if lvl > 0 else {})
		p.fire_burp.give(true)
		for i in 7:
			p.fire_burp.shoot()
			await _wait(0.25)
		var alive: int = p.fire_burp.fireballs_alive()
		_check("more fireballs %d: %d alive at once (wanted %d)" % [lvl, alive, 3 + lvl], alive == 3 + lvl)
		for ball: Node in get_nodes_in_group(&"fireballs"):
			(ball as Fireball).pop()

	for lvl: int in [0, 1]:
		await _stage({"big_fireballs": 1} if lvl == 1 else {})
		p.fire_burp.give(true)
		var floaty: Burpling = _enemy(OFF + 6.0, 1.55)  # floats 1.1 m above where a normal ball reaches
		p.fire_burp.shoot()
		await _wait(0.2)
		var ball := get_nodes_in_group(&"fireballs")[0] as Fireball
		var spare: Node = (load("res://scenes/fireball.tscn") as PackedScene).instantiate()
		var scene_shape := spare.get_node("CollisionShape3D") as CollisionShape3D
		var want_r: float = 0.35 * (1.6 if lvl == 1 else 1.0)
		var own_shape := ball.get_node("CollisionShape3D") as CollisionShape3D
		_check("big fireballs %d: ball radius %.2f, shape %.2f, picture x%.1f" % [lvl, ball.radius, (own_shape.shape as SphereShape3D).radius, ball.ball.scale.x],
			is_equal_approx(ball.radius, want_r) and is_equal_approx((own_shape.shape as SphereShape3D).radius, want_r)
			and is_equal_approx(ball.ball.scale.x, 1.6 if lvl == 1 else 1.0))
		_check("big fireballs: the scene's own shape is left alone (%.2f)" % (scene_shape.shape as SphereShape3D).radius,
			is_equal_approx((scene_shape.shape as SphereShape3D).radius, 0.35))
		spare.free()
		await _wait(0.8)
		if lvl == 1:
			_check("big fireballs: squashes an enemy a normal ball rolls under", _gone(floaty))
			_check("big fireballs: the big ball still rolls along the floor (y %.2f, x %.1f)" % [ball.global_position.y, ball.global_position.x],
				is_instance_valid(ball) and ball.global_position.y > 0.3 and ball.global_position.y < 1.0 and ball.global_position.x > OFF + 8.0)
		else:
			_check("normal fireball rolls under the same floating enemy", not _gone(floaty))
		for stray: Node in get_nodes_in_group(&"fireballs"):
			(stray as Fireball).pop()

	# Bouncy: two platforms with a 4 m gap between them.
	for lvl: int in [0, 1]:
		await _stage({"bouncy_fireballs": 1} if lvl == 1 else {}, true, false)
		_box(Vector3(OFF - 17.0, -0.5, 0), Vector3(50, 1, 4))   # left platform, ends at x = OFF + 8
		_box(Vector3(OFF + 30.0, -0.5, 0), Vector3(36, 1, 4))   # right platform, starts at x = OFF + 12
		p.global_position = Vector3(OFF - 30.0, 1.0, 0)
		p.fire_burp.give(true)
		var shot: bool = p.fire_burp.shoot()
		await _wait(0.3)
		var rolling := get_nodes_in_group(&"fireballs")[0] as Fireball if shot and get_nodes_in_group(&"fireballs").size() > 0 else null
		_check("bouncy %d: the ball exists and is set up (%s, life %.1f s)" % [lvl, str(rolling != null), rolling.lifetime if rolling != null else 0.0],
			rolling != null and rolling.bouncy == (lvl == 1) and is_equal_approx(rolling.lifetime, 4.8 if lvl == 1 else 3.0))
		# Start it right at the ledge so the test is short.
		rolling.global_position = Vector3(OFF + 5.0, 0.4, 0)
		var hopped_y: float = 0.0
		for i in 60:
			await physics_frame
			if is_instance_valid(rolling) and not rolling.is_popped and rolling.global_position.x > OFF + 8.2:
				hopped_y = maxf(hopped_y, rolling.global_position.y)
		await _wait(0.3)
		var made_it: bool = is_instance_valid(rolling) and not rolling.is_popped and rolling.global_position.x > OFF + 13.0 and rolling.global_position.y > 0.2
		if lvl == 1:
			_check("bouncy: pops up off the ledge (up to %.2f m) and clears the gap" % hopped_y, hopped_y > 0.8 and made_it)
		else:
			_check("normal fireball falls into the same gap and pops", not made_it)
		for stray: Node in get_nodes_in_group(&"fireballs"):
			(stray as Fireball).pop()

	# ---------------------------------------------------------------- chilli
	for lvl: int in [0, 1, 2]:
		await _stage({"long_chilli": lvl} if lvl > 0 else {})
		p.chilli.start()
		var want_s: float = [6.0, 9.0, 12.0][lvl]
		_check("long chilli %d: lasts %.0f s (%.0f)" % [lvl, want_s, p.chilli.time_left], p.chilli.time_left == want_s)

	# ---------------------------------------------------------------- spicy start
	await _stage({"spicy_start": 1})
	var hint: Variant = root.get_meta(&"hint_banner") if root.has_meta(&"hint_banner") else null
	_check("spicy start: starts with the Fire Burp", p.has_fire_burp())
	var hint_words: String = ""
	if hint != null and is_instance_valid(hint):
		for label: Node in (hint as Node).find_children("*", "Label", true, false):
			hint_words += (label as Label).text
	_check("spicy start: no FIRE BURP hint at the start (hint says '%s')" % hint_words, not hint_words.contains("FIRE BURP"))
	var words: String = ""
	if p.has_meta(&"speech_bubble") and is_instance_valid(p.get_meta(&"speech_bubble")):
		for label: Node in (p.get_meta(&"speech_bubble") as Node).find_children("*", "Label", true, false):
			words += (label as Label).text
	_check("spicy start: he says no FIRE BURP! (says '%s')" % words, words != "FIRE BURP!")
	p.fire_burp.lose()
	p.fire_burp.collect()
	hint = root.get_meta(&"hint_banner") if root.has_meta(&"hint_banner") else null
	hint_words = ""
	if hint != null and is_instance_valid(hint):
		for label: Node in (hint as Node).find_children("*", "Label", true, false):
			hint_words += (label as Label).text
	_check("a Hot Sauce pickup still shows its hint ('%s')" % hint_words, hint_words.contains("FIRE BURP"))
	await _stage({})
	_check("no spicy start: no Fire Burp at the start", not p.has_fire_burp())

	# ---------------------------------------------------------------- bean magnet
	for lvl: int in [0, 1, 2]:
		await _stage({"bean_magnet": lvl} if lvl > 0 else {})
		var eaten_before: int = level.beans_this_stage
		var plain := (load("res://scenes/bean.tscn") as PackedScene).instantiate() as Node3D
		level.add_child(plain)
		plain.global_position = Vector3(OFF + 3.0, 1.0, 0)
		var golden := (load("res://scenes/golden_bean.tscn") as PackedScene).instantiate() as Node3D
		level.add_child(golden)
		golden.global_position = Vector3(OFF - 3.0, 1.0, 0)
		var marker := Node3D.new()
		level.add_child(marker)
		marker.global_position = Vector3(OFF + 3.5, 0.5, 0)
		var tossed: Node3D = Loot.thing(marker, "res://scenes/bean.tscn", Vector3.ZERO)
		await _wait(1.2)
		var plain_gone: bool = not is_instance_valid(plain)
		var tossed_gone: bool = not is_instance_valid(tossed)
		if lvl == 2:
			_check("magnet 2 (4 m): a bean 3 m away flew to him and was eaten (beans %d -> %d)" % [eaten_before, level.beans_this_stage], plain_gone)
			_check("magnet 2: a thrown bean (it has a bounce) is pulled too", tossed_gone)
			_check("magnet 2: the Golden Bean is not pulled", is_instance_valid(golden) and golden.global_position.x == OFF - 3.0)
			_check("magnet 2: both beans counted for the stage (%d)" % (level.beans_this_stage - eaten_before), level.beans_this_stage - eaten_before == 2)
		else:
			_check("magnet %d: a bean 3 m away stays put" % lvl, not plain_gone and plain.global_position.x == OFF + 3.0)
			_check("magnet %d: the thrown bean 3.5 m away stays too" % lvl, not tossed_gone)

	# ---------------------------------------------------------------- lucky beans
	for lvl: int in [0, 1]:
		await _stage({"lucky_beans": 1} if lvl == 1 else {})
		_check("lucky beans %d: stage drop numbers (%d, x%.1f)" % [lvl, level.extra_drop_beans, level.drop_chance_multiplier],
			level.extra_drop_beans == 2 * lvl and is_equal_approx(level.drop_chance_multiplier, 1.0 + lvl))
		var squashed_one: Burpling = _enemy(OFF + 40.0)
		squashed_one.drop_beans_min = 2
		squashed_one.drop_beans_max = 2
		squashed_one.drop_chance = 0.0
		squashed_one.squash()
		await physics_frame
		_check("lucky beans %d: a squashed enemy throws %d beans" % [lvl, _count_scene("res://scenes/bean.tscn")], _count_scene("res://scenes/bean.tscn") == 2 + 2 * lvl)
		# Many enemies at a 25% pickup chance, with a fixed random seed so the count is repeatable.
		seed(4242)
		for i in 200:
			var e: Burpling = _enemy(OFF - 190.0 + i * 1.9)
			e.drop_beans_min = 0
			e.drop_beans_max = 0
			e.drop_chance = 0.25
			e.squash()
		await physics_frame
		var pickups: int = _count_scene("res://scenes/heart.tscn") + _count_scene("res://scenes/chilli.tscn") + _count_scene("res://scenes/hot_sauce.tscn")
		if lvl == 0:
			_check("normal: 200 enemies at 25%% drop about 50 pickups (%d)" % pickups, pickups > 35 and pickups < 65)
			base["pickups"] = pickups
		else:
			_check("lucky beans: pickups drop twice as often (%d vs %d)" % [pickups, base["pickups"] as int], pickups > 1.5 * (base["pickups"] as int) and pickups > 75)

	# ---------------------------------------------------------------- secret sniffer
	for variant: String in ["off", "near", "far", "secret"]:
		await _stage({"secret_sniffer": 1} if variant != "off" else {})
		var nose := p.get_node("SecretSniffer") as SecretSniffer
		var sniffs: Array[int] = [0]
		nose.sniffed.connect(func() -> void: sniffs[0] += 1)
		var near_bean := (load("res://scenes/golden_bean.tscn") as PackedScene).instantiate() as Node3D
		level.add_child(near_bean)
		near_bean.global_position = Vector3(OFF + (30.0 if variant == "far" else 6.0), 3.0, 0)
		if variant == "secret":
			near_bean.queue_free()
			var wall := Node3D.new()
			wall.add_to_group(&"secrets")
			level.add_child(wall)
			wall.global_position = Vector3(OFF + 5.0, 1.0, 0)
		Sfx.played.clear()
		await _wait(2.0)
		match variant:
			"off":
				_check("sniffer not bought: quiet near a Golden Bean", sniffs[0] == 0 and not nose.enabled)
			"near":
				_check("sniffer: sniffs near a Golden Bean, once (%d sniffs)" % sniffs[0], sniffs[0] == 1)
				_check("sniffer: has the sniff sound (%s)" % str(nose.sniff_sound), nose.sniff_sound != null and nose.sniff_sound.resource_path.ends_with("ring_ding.wav"))
				await _wait(1.5)
				_check("sniffer: stays quiet during its cooldown (%d)" % sniffs[0], sniffs[0] == 1)
				await _wait(2.0)
				_check("sniffer: sniffs again after the cooldown (%d)" % sniffs[0], sniffs[0] == 2)
			"far":
				_check("sniffer: quiet when the Golden Bean is 30 m away", sniffs[0] == 0)
			"secret":
				_check("sniffer: also sniffs out a secret (%d)" % sniffs[0], sniffs[0] == 1)

	# ---------------------------------------------------------------- everything at once, applied once
	var all: Dictionary = {}
	for upgrade: Dictionary in UpgradeTable.UPGRADES:
		all[upgrade["id"]] = UpgradeTable.max_level(upgrade["id"])
	await _stage(all, true)
	var maxed: Dictionary = _numbers()
	_check("all at max: 200 gas, 5 hearts, heal 2, 3 spills for 10 s",
		maxed["max_gas"] == 200.0 and maxed["max_hearts"] == 5 and maxed["heal"] == 2 and maxed["spill_count"] == 3 and maxed["spill_life"] == 10.0)
	_check("all at max: 5 fireballs, size 1.6, bouncy, chilli 12 s, burp at start",
		maxed["max_fireballs"] == 5 and is_equal_approx(maxed["ball_size"] as float, 1.6) and maxed["bouncy"] and maxed["chilli"] == 12.0 and maxed["has_burp"])
	_check("all at max: magnet 6 m, stomp on, sniffer on, lucky beans",
		maxed["magnet"] == 6.0 and maxed["stomp"] and maxed["sniffer"] and maxed["extra_beans"] == 2 and maxed["drop_x"] == 2.0)
	UpgradeApplier.apply(p, level)
	_check("applying twice changes nothing", _numbers() == maxed)
	_check("applying upgrades never touches the jar (%d)" % save.bean_jar, save.bean_jar == 321)
	_check("level() reads the save (sneakers %d)" % UpgradeApplier.level(p, "speedy_sneakers"), UpgradeApplier.level(p, "speedy_sneakers") == 2)

	# ---------------------------------------------------------------- UPGRADES OFF: nothing changes
	options.set_upgrades_on(false)
	await _stage(all, true)
	var off_numbers: Dictionary = _numbers()
	var same: bool = true
	for key: String in base:
		if key == "pickups" or key == "gas":
			continue
		if off_numbers[key] != base[key]:
			same = false
			print("  differs: %s  off=%s  baseline=%s" % [key, str(off_numbers[key]), str(base[key])])
	_check("UPGRADES OFF: every number matches the baseline even with everything bought", same)
	_check("UPGRADES OFF: level() says 0 and the save still remembers (%d, %d)" % [UpgradeApplier.level(p, "speedy_sneakers"), save.upgrade_level("speedy_sneakers")],
		UpgradeApplier.level(p, "speedy_sneakers") == 0 and save.upgrade_level("speedy_sneakers") == 2)
	var off_run: float = await _run_distance()
	_check("UPGRADES OFF: he runs the baseline distance (%.1f vs %.1f)" % [off_run, base_run], absf(off_run - base_run) < 0.2)
	_check("UPGRADES OFF: the jar is untouched (%d)" % save.bean_jar, save.bean_jar == 321)
	options.set_upgrades_on(true)

	await _finish("upgrades more")
