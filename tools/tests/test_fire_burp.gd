extends SceneTree
# Checks the FIRE BURP power: the Hot Sauce pickup, the fire button (C / pad B), the rolling
# fireball (floor, slopes, ledges, walls, bowling through Burplings, max 3 alive), that it never
# touches Fart Man, that without the power fire acts like fart (CLASSIC and SIMPLE), that the
# power survives a respawn, and that stage 1-2 and test level T-1 have the Hot Sauce and crowds.

var failures: int = 0
## The test worlds sit away from the real levels.
const OFF: float = 300.0
const OFF2: float = 700.0

var options: DebugOptionsData
var world: Node3D
var p: Player
var farts: Array[String] = []
var burps: int = 0
## x positions of the test Burplings that got squashed (they are freed afterwards).
var popped: Dictionary = {}


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


func _box(parent: Node, center: Vector3, size: Vector3, rot_z: float = 0.0) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = center
	body.rotation.z = rot_z
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)
	parent.add_child(body)
	return body


func _fireballs() -> Array[Fireball]:
	var found: Array[Fireball] = []
	for node: Node in get_nodes_in_group(&"fireballs"):
		found.append(node as Fireball)
	return found


func _burpling(x: float) -> Burpling:
	var b: Burpling = load("res://scenes/burpling.tscn").instantiate()
	b.position = Vector3(x, 0.45, 0)
	b.walk_speed = 0.0
	world.add_child(b)
	b.squashed.connect(func() -> void: popped[x] = true)
	return b


func _clear_fireballs() -> void:
	for ball: Fireball in _fireballs():
		ball.pop()


## Flat floor (top at y = 0) from OFF-20 to OFF+60, a tall wall at OFF+50, and Fart Man at OFF.
func _make_world() -> void:
	world = Node3D.new()
	root.add_child(world)
	_box(world, Vector3(OFF + 20.0, -0.5, 0), Vector3(80, 1, 4))
	_box(world, Vector3(OFF + 50.5, 2.0, 0), Vector3(1, 4, 4))
	p = load("res://scenes/player.tscn").instantiate()
	p.position = Vector3(OFF, 1.0, 0)
	world.add_child(p)
	p.farted.connect(func(n: String) -> void: farts.append(n))
	p.fire_burped.connect(func() -> void: burps += 1)


func _reset() -> void:
	p.global_position = Vector3(OFF, 1.0, 0)
	p.velocity = Vector3.ZERO
	p.gas_tank.gas = p.gas_tank.max_gas
	p.flashing_left = 0.0
	farts.clear()


func _run() -> void:
	var save: Node = root.get_node_or_null("SaveGame")
	if save != null:
		save.use_file("user://test_fire_burp_save.json")
		save.reset()
	await _wait(0.2)  # let the autoloads start
	options = root.get_node("DebugOptions")
	options.set_simple_controls(false)
	options.set_gas_mode(DebugOptionsData.GasMode.NORMAL)
	_make_world()
	await _wait(0.5)
	var power: FireBurpPower = p.fire_burp
	_check("the player carries a FireBurpPower, not yet active", power != null and not p.has_fire_burp())
	_check("fire is not lost when hurt by default", not power.lost_when_hurt)

	# ---------------------------------------------------------------- no power: fire does nothing
	Input.action_press(&"fire")
	await _wait(0.3)
	Input.action_release(&"fire")
	await _wait(0.1)
	_check("CLASSIC, no power: fire does not fart or charge (%s)" % str(farts), farts.is_empty() and not p.is_charging)
	_check("CLASSIC, no power: no fireball", _fireballs().is_empty() and burps == 0)

	options.set_simple_controls(true)
	_reset()
	await _wait(0.3)
	var y_before: float = p.global_position.y
	await _press(&"fire", 0.5)
	_check("SIMPLE, no power: fire does not jump (%s, rose %.2f m)" % [str(farts), p.global_position.y - y_before],
		farts.is_empty() and p.global_position.y - y_before < 0.1)
	_check("SIMPLE, no power: no fireball", _fireballs().is_empty())
	options.set_simple_controls(false)
	_reset()
	await _wait(0.3)

	# ---------------------------------------------------------------- the pickup
	var sauce: Node3D = load("res://scenes/hot_sauce.tscn").instantiate()
	sauce.position = p.global_position
	world.add_child(sauce)
	await _wait(0.3)
	_check("Hot Sauce gives the power", p.has_fire_burp())
	_check("Hot Sauce is used up", not is_instance_valid(sauce) or sauce.is_queued_for_deletion())
	_check("he wears a flame so you can see it", p.get_node_or_null("FireFlame") != null and p.get_node("FireFlame").visible)

	# ---------------------------------------------------------------- with power: fire shoots, does not fart
	_reset()
	await _wait(0.4)
	var hearts_before: int = p.hearts.hearts
	var x_before: float = p.global_position.x
	Input.action_press(&"fire")
	await _wait(0.1)
	_check("fire shoots a fireball (%d alive, %d burps)" % [_fireballs().size(), burps], _fireballs().size() == 1 and burps == 1)
	_check("fire does not charge a fart", not p.is_charging and farts.is_empty())
	Input.action_release(&"fire")
	await _wait(0.5)
	var ball: Fireball = _fireballs()[0] if not _fireballs().is_empty() else null
	_check("the fireball is still alive and rolling right of him", ball != null and ball.global_position.x > p.global_position.x + 3.0)
	if ball != null:
		_check("the fireball is on the floor, rolling at floor height (y %.2f)" % ball.global_position.y, absf(ball.global_position.y - 0.35) < 0.15 and ball.is_on_floor())
		var bx: float = ball.global_position.x
		await _wait(0.3)
		_check("it keeps rolling forward at a steady pace (%.1f m in 0.3 s)" % (ball.global_position.x - bx), absf((ball.global_position.x - bx) - ball.roll_speed * 0.3) < 0.8)
		_check("it is faster than his run speed", ball.roll_speed > p.move_speed)
		_check("it spins", absf(ball.ball.rotation.z) > 0.5)
	_check("it did not push or hurt him (x %.2f, hearts %d)" % [p.global_position.x, p.hearts.hearts], absf(p.global_position.x - x_before) < 0.05 and p.hearts.hearts == hearts_before)
	_clear_fireballs()
	await _wait(0.2)

	# It goes the way he faces.
	p.visual.rotation.y = PI
	await _press(&"fire", 0.1)
	await _wait(0.3)
	var lefty: Array[Fireball] = _fireballs()
	_check("facing left, the fireball rolls left", lefty.size() == 1 and lefty[0].global_position.x < p.global_position.x - 1.0)
	_clear_fireballs()
	p.visual.rotation.y = 0.0
	await _wait(0.2)

	# ---------------------------------------------------------------- bowling through Burplings
	var b1: Burpling = _burpling(OFF + 10.0)
	var b2: Burpling = _burpling(OFF + 13.0)
	var b3: Burpling = _burpling(OFF + 16.0)
	await _wait(0.2)
	await _press(&"fire", 0.1)
	await _wait(1.7)
	var rolling: Array[Fireball] = _fireballs()
	_check("the fireball squashed the first Burpling", popped.has(OFF + 10.0))
	_check("and the second and third: it bowls through the line", popped.has(OFF + 13.0) and popped.has(OFF + 16.0))
	_check("and it keeps rolling past them (x %.1f)" % (rolling[0].global_position.x if not rolling.is_empty() else -1.0), not rolling.is_empty() and rolling[0].global_position.x > OFF + 17.0)
	_check("he was not hurt on the way", p.hearts.hearts == hearts_before)
	_clear_fireballs()
	await _wait(0.5)

	# ---------------------------------------------------------------- never more than 3 alive
	var peak_alive: int = 0
	for i in 6:
		await _press(&"fire", 0.05)
		await _wait(0.2)
		peak_alive = maxi(peak_alive, _fireballs().size())
	_check("never more than 3 fireballs at once (peak %d)" % peak_alive, peak_alive == 3)
	_clear_fireballs()
	await _wait(0.3)

	# ---------------------------------------------------------------- cooldown
	burps = 0
	Input.action_press(&"fire")
	await physics_frame
	Input.action_release(&"fire")
	await physics_frame
	Input.action_press(&"fire")
	await physics_frame
	Input.action_release(&"fire")
	await physics_frame
	_check("two presses 2 frames apart: the cooldown allows only one (%d)" % burps, burps == 1)
	_clear_fireballs()
	await _wait(0.4)

	# ---------------------------------------------------------------- works in the air
	_reset()
	p.global_position = Vector3(OFF, 5.0, 0)
	await _wait(0.1)
	burps = 0
	await _press(&"fire", 0.05)
	_check("fire works while he is in the air", burps == 1 and not p.is_on_floor())
	await _wait(1.2)
	var air_ball: Array[Fireball] = _fireballs()
	_check("an air-shot fireball lands and rolls on the floor", not air_ball.is_empty() and absf(air_ball[0].global_position.y - 0.35) < 0.15)
	_clear_fireballs()
	await _wait(0.3)

	# ---------------------------------------------------------------- walls and the clock
	_reset()
	p.global_position = Vector3(OFF + 35.0, 1.0, 0)
	await _wait(0.4)
	await _press(&"fire", 0.05)
	await _wait(1.6)
	_check("the fireball pops when it hits a wall", _fireballs().is_empty())
	_clear_fireballs()
	var timed: Fireball = load("res://scenes/fireball.tscn").instantiate()
	timed.lifetime = 0.5
	timed.roll_speed = 1.0
	world.add_child(timed)
	timed.global_position = Vector3(OFF + 5.0, 0.5, 0)
	await _wait(0.8)
	_check("the fireball pops when its lifetime is up", not is_instance_valid(timed) or timed.is_popped)

	# ---------------------------------------------------------------- slope and ledge (a second world)
	var world2 := Node3D.new()
	root.add_child(world2)
	var a: float = deg_to_rad(15.0)
	_box(world2, Vector3(OFF2 - 20.0, -0.5, 0), Vector3(40, 1, 4))
	# A ramp going down from x = OFF2 (its top surface starts at y = 0) for 20 m of run.
	var run: float = 20.0
	var slope_mid := Vector3(OFF2 + run * 0.5, -run * 0.5 * tan(a), 0) - Vector3(sin(a), cos(a), 0) * 0.5
	_box(world2, slope_mid, Vector3(run / cos(a), 1, 4), -a)
	# Flat floor at the bottom of the ramp, ending in a ledge at OFF2 + 45.
	var low: float = -run * tan(a)
	_box(world2, Vector3(OFF2 + run + 12.5, low - 0.5, 0), Vector3(25, 1, 4))
	var roller: Fireball = load("res://scenes/fireball.tscn").instantiate()
	roller.lifetime = 10.0
	world2.add_child(roller)
	roller.global_position = Vector3(OFF2 - 6.0, 0.4, 0)
	await _wait(0.5)
	_check("on flat ground before the slope (y %.2f)" % roller.global_position.y, absf(roller.global_position.y - 0.35) < 0.15)
	var worst: float = 0.0
	var samples: int = 0
	for i in 70:
		await physics_frame
		if not is_instance_valid(roller) or roller.is_popped:
			break
		var rx: float = roller.global_position.x
		if rx > OFF2 + 1.0 and rx < OFF2 + run - 1.0:
			var surface: float = -(rx - OFF2) * tan(a)
			worst = maxf(worst, absf(roller.global_position.y - (surface + 0.35 / cos(a))))
			samples += 1
	_check("it follows the slope down, hugging it (%d samples, worst gap %.2f m)" % [samples, worst], samples > 10 and worst < 0.25)
	await _wait(1.0)
	_check("it is still rolling at the bottom (x %.1f)" % roller.global_position.x, is_instance_valid(roller) and roller.global_position.x > OFF2 + run + 2.0)
	# Off the ledge into the pit: it drops, then pops, and nothing is left alive.
	await _wait(2.5)
	_check("it rolls off the ledge, falls and pops (alive: %d)" % _fireballs().size(), _fireballs().is_empty())
	world2.queue_free()

	# ---------------------------------------------------------------- hurt, flying, respawn
	_reset()
	await _wait(0.3)
	p.hurt(p.global_position.x - 1.0)
	_check("getting hurt does not take the power away (lost_when_hurt is off)", p.has_fire_burp())
	p._respawn()
	await _wait(0.2)
	_check("the power survives a respawn", p.has_fire_burp())
	_check("and the flame is still on", p.get_node("FireFlame").visible)
	await _wait(1.0)
	burps = 0
	_check("he can still shoot after respawning", power.shoot())
	_clear_fireballs()
	await _wait(0.5)

	power.lost_when_hurt = true
	p.flashing_left = 0.0
	p.hurt(p.global_position.x - 1.0)
	_check("with lost_when_hurt on, getting hurt takes it away", not p.has_fire_burp() and not p.get_node("FireFlame").visible)
	power.lost_when_hurt = false

	# ---------------------------------------------------------------- sounds (it can't hear: checks the file names)
	var heard: Array[String] = []
	for s: Node in p.get_children():
		if s is PlayerSounds:
			heard.append_array((s as PlayerSounds).played)
	_check("each shot plays the fire burp sound", heard.has("fire_burp.wav"))
	_check("popping fireballs play the pop sound", Sfx.played.has("fireball_pop.wav"))
	_check("Hot Sauce plays a grab sound", Sfx.played.has("chilli_sizzle.wav"))

	world.queue_free()
	await _wait(0.3)

	# ---------------------------------------------------------------- not in flying stages
	var fly_stage: Stage = load("res://scenes/stage_1_3.tscn").instantiate()
	root.add_child(fly_stage)
	await _wait(0.5)
	var fp: Player = fly_stage.player
	fp.fire_burp.has_power = true
	_check("in a flying stage he is flying", fp.is_flying())
	_check("a fire burp does nothing while flying", not fp.fire_burp.shoot() and _fireballs().is_empty())
	fly_stage.queue_free()
	await _wait(0.3)

	# ---------------------------------------------------------------- stage 1-2's FIRE BURP PARTY
	var s12: Stage = load("res://scenes/stage_1_2.tscn").instantiate()
	root.add_child(s12)
	await _wait(0.5)
	var sauces: Array[Node] = s12.find_children("*", "Area3D", true, false).filter(func(n: Node) -> bool: return n.get_script() != null and n.get_script().resource_path.ends_with("hot_sauce.gd"))
	_check("stage 1-2 has a Hot Sauce (%d)" % sauces.size(), sauces.size() == 1)
	var sauce_x: float = (sauces[0] as Node3D).position.x if not sauces.is_empty() else 0.0
	var kinds: Dictionary = {}
	var party: int = 0
	var ground_walkers: int = 0
	for e: Node in s12.find_children("*", "Burpling", true, false):
		var ex: float = (e as Node3D).position.x
		if ex > sauce_x + 10.0 and ex < sauce_x + 120.0:
			party += 1
			var kind: String = e.get_script().resource_path.get_file().get_basename()
			kinds[kind] = int(kinds.get(kind, 0)) + 1
			if kind == "burpling" or kind == "hiccup":
				ground_walkers += 1
	print("party enemies after the Hot Sauce (x %.0f to %.0f): %d  %s" % [sauce_x + 10.0, sauce_x + 120.0, party, str(kinds)])
	_check("the party has at least 20 enemies (%d)" % party, party >= 20)
	_check("most are ground walkers (%d of %d)" % [ground_walkers, party], ground_walkers >= 20 and ground_walkers * 10 >= party * 8)
	_check("stage 1-2 still has 3 golden beans and 1 bean can", s12.golden_total == 3 and get_nodes_in_group(&"bean_cans").size() == 1)
	# Real play: take the sauce, burp down the party floor, count how many are bowled over.
	var sp: Player = s12.player
	sp.flashing_left = 100000.0
	sp.global_position = Vector3(sauce_x, -6.6, 0)
	await _wait(0.4)
	_check("walking into the stage's Hot Sauce gives the power", sp.has_fire_burp())
	sp.global_position = Vector3(sauce_x + 18.0, -6.5, 0)
	sp.velocity = Vector3.ZERO
	await _wait(0.5)
	var tally: Array[int] = [0]  # (a list, because a lambda cannot change a plain number)
	for e: Node in s12.find_children("*", "Burpling", true, false):
		(e as Burpling).squashed.connect(func() -> void: tally[0] += 1)
	for i in 8:
		await _press(&"fire", 0.05)
		await _wait(0.35)
	await _wait(1.0)
	var bowled: int = tally[0]
	print("bowled over by fireballs from the first spot of the party: %d" % bowled)
	_check("fireballs bowl over many of them (%d)" % bowled, bowled >= 8)
	s12.queue_free()
	await _wait(0.3)

	# ---------------------------------------------------------------- the test level
	var t1: Stage = load("res://scenes/stage_t_1.tscn").instantiate()
	root.add_child(t1)
	await _wait(0.5)
	var t1_sauce: Array[Node] = t1.find_children("HotSauce", "Area3D", true, false)
	var t1_crowd: int = 0
	for e: Node in t1.find_children("*", "Burpling", true, false):
		if absf((e as Node3D).position.x) < 16.0 and (e as Node3D).position.y < 1.0:
			t1_crowd += 1
	_check("test level T-1 has a Hot Sauce and a crowd of about 12 (%d, %d)" % [t1_sauce.size(), t1_crowd], t1_sauce.size() == 1 and t1_crowd >= 12)
	t1.queue_free()
	await _wait(0.3)

	options.set_simple_controls(false)
	print("fire burp failures: %d" % failures)
	quit()
