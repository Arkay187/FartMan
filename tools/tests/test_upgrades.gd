extends "res://tools/tests/upgrade_test_base.gd"
# Checks the first half of the shop upgrades in a real stage: belly, hearts, big hearts, sticky beans,
# sneakers, springy pants, super stomp, triple jump. (test_upgrades_more has the rest.)


func _run() -> void:
	await _setup()

	# ---------------------------------------------------------------- the baseline: no upgrades
	await _stage({})
	var base: Dictionary = _numbers()
	_check("baseline: 100 gas, 3 hearts, speed 6, nothing switched on",
		base["max_gas"] == 100.0 and base["max_hearts"] == 3 and base["move_speed"] == 6.0 and not base["stomp"]
		and not base["sniffer"] and base["magnet"] == 0.0 and not base["has_burp"] and base["extra_beans"] == 0)
	var base_simple_peak: float = await _peak(&"jump", 0.5)
	var base_double_peak: float = await _double_peak()
	var base_run: float = await _run_distance()
	await _stage({}, false)
	var base_hop_peak: float = await _peak(&"jump", 0.5)
	var base_hover_ok: bool = (_numbers()["hover_free"] as float) == 3.0
	print("baseline: simple peak %.2f, double peak %.2f, classic hop %.2f, run %.2f" % [base_simple_peak, base_double_peak, base_hop_peak, base_run])

	# ---------------------------------------------------------------- bigger belly
	await _stage({"bigger_belly": 2})
	var gas_bar: ProgressBar = level.get_node("HUD/GasBar") as ProgressBar
	_check("bigger belly 2: tank holds 150 and starts full (%.0f/%.0f)" % [p.gas_tank.gas, p.gas_tank.max_gas],
		p.gas_tank.max_gas == 150.0 and p.gas_tank.start_gas == 150.0 and p.gas_tank.gas == 150.0)
	_check("bigger belly 2: the gas bar shows it (%.0f of %.0f)" % [gas_bar.value, gas_bar.max_value],
		gas_bar.max_value == 150.0 and gas_bar.value == 150.0)
	_check("bigger belly 2: hover time in the free-gas modes grows by 1.5 (%.2f)" % (_numbers()["hover_free"] as float),
		is_equal_approx(_numbers()["hover_free"] as float, 4.5) and base_hover_ok)
	p.gas_tank.use(40.0)
	_check("bigger belly: a Trump still costs normal gas (%.0f left)" % p.gas_tank.gas, is_equal_approx(p.gas_tank.gas, 110.0))

	# ---------------------------------------------------------------- hearts
	await _stage({"extra_heart": 2})
	var hearts_bar: SquareBar = level.get_node("HUD/HeartsBar") as SquareBar
	_check("extra heart 2: 5 hearts, all full (%d/%d)" % [p.hearts.hearts, p.hearts.max_hearts], p.hearts.max_hearts == 5 and p.hearts.hearts == 5)
	_check("extra heart 2: the hearts bar shows 5 squares (%d)" % _squares_shown(hearts_bar), _squares_shown(hearts_bar) == 5)
	await _stage({"extra_heart": 1})
	_check("extra heart 1: 4 hearts and 4 squares", p.hearts.max_hearts == 4 and _squares_shown(level.get_node("HUD/HeartsBar") as SquareBar) == 4)

	await _stage({})
	p.hearts.hearts = 1
	var heart := (load("res://scenes/heart.tscn") as PackedScene).instantiate() as Node3D
	level.add_child(heart)
	heart.global_position = p.global_position
	await _wait(0.2)
	_check("no big hearts: a Heart gives 1 (1 -> %d)" % p.hearts.hearts, p.hearts.hearts == 2)
	await _stage({"big_hearts": 1})
	p.hearts.hearts = 1
	heart = (load("res://scenes/heart.tscn") as PackedScene).instantiate() as Node3D
	level.add_child(heart)
	heart.global_position = p.global_position
	await _wait(0.2)
	_check("big hearts: a Heart gives 2 (1 -> %d)" % p.hearts.hearts, p.hearts.hearts == 3)
	p.hearts.hearts = 3
	heart = (load("res://scenes/heart.tscn") as PackedScene).instantiate() as Node3D
	level.add_child(heart)
	heart.global_position = p.global_position
	await _wait(0.2)
	_check("big hearts: with full hearts the Heart stays put", is_instance_valid(heart) and not heart.is_queued_for_deletion())

	# ---------------------------------------------------------------- sticky beans
	for levels: Dictionary in [{}, {"sticky_beans": 1}]:
		await _stage(levels, true, true, false)
		level.add_beans(10)
		p.flashing_left = 0.0
		p.hurt(p.global_position.x + 1.0)
		await _wait(0.1)
		var thrown: int = 0
		var lifetime: float = 0.0
		for child: Node in level.get_children():
			var bounce := child.get_node_or_null("LootBounce") as LootBounce
			if bounce != null and child.scene_file_path == "res://scenes/bean.tscn":
				thrown += 1
				lifetime = bounce.lifetime
		if levels.is_empty():
			_check("normal: a hit spills 6 beans for 5 s (%d, %.0f s)" % [thrown, lifetime], thrown == 6 and lifetime == 5.0)
		else:
			_check("sticky beans: a hit spills only 3 beans for 10 s (%d, %.0f s), 7 stay in the pot (%d)" % [thrown, lifetime, level.beans_pot],
				thrown == 3 and lifetime == 10.0 and level.beans_pot == 7)

	# ---------------------------------------------------------------- speedy sneakers
	for lvl: int in [1, 2]:
		await _stage({"speedy_sneakers": lvl})
		var dist: float = await _run_distance()
		var ratio: float = dist / base_run
		var want: float = 1.15 if lvl == 1 else 1.30
		_check("sneakers %d: runs further in 1 s (%.1f m vs %.1f, x%.2f)" % [lvl, dist, base_run, ratio],
			ratio > want - 0.03 and ratio < want + 0.08 and is_equal_approx(p.move_speed, 6.0 * want))

	# ---------------------------------------------------------------- springy pants
	for lvl: int in [1, 2]:
		var want_h: float = 1.10 if lvl == 1 else 1.20
		await _stage({"springy_pants": lvl})
		var simple_peak: float = await _peak(&"jump", 0.5)
		var double_peak: float = await _double_peak()
		var r1: float = simple_peak / base_simple_peak
		var r2: float = double_peak / base_double_peak
		_check("springy pants %d: SIMPLE jump x%.3f higher (%.2f vs %.2f, wanted %.2f)" % [lvl, r1, simple_peak, base_simple_peak, want_h],
			absf(r1 - want_h) < 0.03)
		_check("springy pants %d: SIMPLE double jump higher too (x%.3f)" % [lvl, r2], r2 > 1.0 + (want_h - 1.0) * 0.5 and r2 < want_h + 0.06)
		await _stage({"springy_pants": lvl}, false)
		var hop_peak: float = await _peak(&"jump", 0.5)
		var r3: float = hop_peak / base_hop_peak
		_check("springy pants %d: CLASSIC hop x%.3f higher (%.2f vs %.2f)" % [lvl, r3, hop_peak, base_hop_peak], absf(r3 - want_h) < 0.03)
		var num: Dictionary = _numbers()
		_check("springy pants %d: Trump and Thunder scaled by sqrt(%.2f)" % [lvl, want_h],
			is_equal_approx(num["trump"] as float, 11.5 * sqrt(want_h)) and is_equal_approx(num["thunder"] as float, 16.0 * sqrt(want_h)))

	# ---------------------------------------------------------------- super stomp
	for owned: bool in [false, true]:
		await _stage({"super_stomp": 1} if owned else {})
		var under: Burpling = _enemy(OFF)
		var near: Burpling = _enemy(OFF + 3.0)
		var far: Burpling = _enemy(OFF + 8.0)
		p.global_position = Vector3(OFF, 3.5, 0)
		p.velocity = Vector3(0, -6, 0)
		await _wait(0.5)
		_check("stomp: the enemy he lands on is squashed (%s)" % ("with the upgrade" if owned else "no upgrade"), _gone(under))
		if owned:
			_check("super stomp: a second enemy 3 m away is squashed too", _gone(near))
			_check("super stomp: an enemy 8 m away is not", not _gone(far))
			Sfx.played.clear()
			p.global_position = Vector3(OFF + 20.0, 3.5, 0)
			p.velocity = Vector3(0, -6, 0)
			var under2: Burpling = _enemy(OFF + 20.0)
			await _wait(0.5)
			_check("super stomp: the thump sound plays (%s)" % str(Sfx.played), Sfx.played.has("stamp_thump.wav"))
		else:
			_check("no upgrade: a second enemy 3 m away is NOT squashed", not _gone(near))

	# ---------------------------------------------------------------- triple jump (SIMPLE air jumps)
	for lvl: int in [0, 1]:
		await _stage({"triple_jump": 1} if lvl == 1 else {})
		var want_jumps: int = 2 if lvl == 1 else 1
		_check("triple jump %d: SIMPLE has %d air jump(s) (%d)" % [lvl, want_jumps, p.simple_helper.air_jumps], p.simple_helper.air_jumps == want_jumps)
		await _tap(&"jump")
		await _wait(0.1)
		await _tap(&"jump")
		await _wait(0.1)
		if lvl == 1:
			_check("triple jump: after jump + 1 air jump one is left (%d)" % p.simple_helper.air_jumps_left(), p.simple_helper.air_jumps_left() == 1)
			await _tap(&"jump")
			_check("triple jump: the second air jump works (rising %.1f)" % p.velocity.y, p.velocity.y > 5.0 and p.simple_helper.air_jumps_left() == 0)
		for i in 150:
			if p.velocity.y < -1.0:
				break
			await physics_frame
		var falling_before: float = p.velocity.y
		await _tap(&"jump")
		_check("a press with no air jumps left does nothing (vy %.1f -> %.1f)" % [falling_before, p.velocity.y], p.velocity.y < 0.0 and not p.is_on_floor())
	await _stage({"triple_jump": 1}, false)
	_check("triple jump: CLASSIC free-gas air farts 1 -> 2 (%d)" % p.air_farts_free_gas, p.air_farts_free_gas == 2)

	await _finish("upgrades")
