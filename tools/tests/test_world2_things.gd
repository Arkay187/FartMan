extends SceneTree
# Checks the World 2 (Bean Factory) building blocks one at a time, built with the factory kit:
# conveyor belts, stamping press, crumbling biscuit, red/blue switch, warp pipe, fan,
# steam vent, Cork Bot and Fizz Bat.

var failures: int = 0
var kit: RefCounted
var stage: Node3D
var player: Player


func _initialize() -> void:
	_run()


func _wait(seconds: float) -> void:
	for i in int(seconds * 60.0):
		await physics_frame


func _check(label: String, ok: bool) -> void:
	print("%s: %s" % [label, "ok" if ok else "FAIL"])
	if not ok:
		failures += 1


## A fresh little stage made with the factory kit. Add things to it with kit.xxx(), then _go().
func _fresh(at: Vector3 = Vector3(0, 1.2, 0)) -> void:
	Input.action_release(&"ui_right")
	Input.action_release(&"ui_left")
	if stage != null:
		stage.free()
	kit = load("res://tools/kit_factory.gd").new()
	kit.begin("test", "", at, Color(0.4, 0.4, 0.45))
	stage = kit.root
	player = kit.player


func _go() -> void:
	root.add_child(stage)


func _hearts() -> int:
	return (player.get_node("Hearts") as Hearts).hearts


func _run() -> void:
	# --- Conveyor belts carry him: right, left, and against him. ---
	_fresh()
	kit.belt(-20, 40, 0, 3.0, false)
	_go()
	await _wait(2.0)
	_check("belt carries him right while he stands still (x=%.1f)" % player.position.x, player.position.x > 4.0 and player.is_on_floor())
	_fresh()
	kit.belt(-40, 20, 0, -3.0, false)
	_go()
	await _wait(2.0)
	_check("backwards belt carries him left (x=%.1f)" % player.position.x, player.position.x < -4.0)
	_fresh()
	kit.belt(-40, 40, 0, -3.0, false)
	_go()
	Input.action_press(&"ui_right")
	await _wait(2.0)
	Input.action_release(&"ui_right")
	_check("running against the belt still gets him along, slowly (x=%.1f, 12 without a belt)" % player.position.x, player.position.x > 3.0 and player.position.x < 9.0)
	_check("belt stripes exist and slide", (stage.find_children("*", "Conveyor", true, false)[0] as Conveyor).stripes.get_child_count() > 3)

	# --- Stamping press: hurts only while slamming, safe on top. ---
	_fresh()
	kit.ground(-40, 80, 0, kit.STEEL, false)
	var press: StampPress = kit.stamp(0, 0, {"wait_time": 1.0, "warn_time": 0.5})
	_go()
	await _wait(0.8)
	_check("press waiting up: standing under it is safe (hearts %d, state %d)" % [_hearts(), press.state], _hearts() == 3 and press.state == StampPress.State.WAIT)
	await _wait(0.5)
	_check("press shakes and shows its shadow first (state %d, shadow %s)" % [press.state, str(press.shadow.visible)], press.state == StampPress.State.WARN and press.shadow.visible)
	await _wait(1.0)
	_check("press slammed on him (hearts %d)" % _hearts(), _hearts() < 3)
	_fresh(Vector3(0, 5.8, 0))
	kit.ground(-40, 80, 0, kit.STEEL, false)
	press = kit.stamp(0, 0, {"wait_time": 1.0, "warn_time": 0.5})
	_go()
	var slams: int = 0
	var was_danger: bool = false
	for i in 480:
		await physics_frame
		if press.is_dangerous() and not was_danger:
			slams += 1
		was_danger = press.is_dangerous()
	_check("standing on top of the press is safe through %d slams (hearts %d)" % [slams, _hearts()], slams >= 2 and _hearts() == 3)

	# --- Crumbling biscuit: shakes, falls, comes back. ---
	_fresh()
	var biscuit: CrumblePlatform = kit.biscuit(0, 0, 3.0, {"crumble_delay": 0.5, "return_after": 2.0})
	kit.ground(25, 40, 0, kit.STEEL, false)
	_go()
	await _wait(0.3)
	_check("biscuit holds him at first (y=%.2f, state %d)" % [player.position.y, biscuit.state], player.position.y > 0.9 and not biscuit.is_fallen())
	await _wait(0.6)
	_check("biscuit has crumbled (fallen %s)" % str(biscuit.is_fallen()), biscuit.is_fallen())
	await _wait(0.5)
	_check("he fell through (y=%.1f)" % player.position.y, player.position.y < 0.0)
	player.position = Vector3(30, 1.2, 0)
	player.velocity = Vector3.ZERO
	await _wait(2.6)
	_check("biscuit came back (solid %s, shape on %s)" % [str(not biscuit.is_fallen()), str(not biscuit.shape.disabled)], not biscuit.is_fallen() and not biscuit.shape.disabled)

	# --- Switch blocks: red solid / blue ghost, button swaps them, respawn resets. ---
	_fresh()
	kit.ground(-20, 20, 0, kit.STEEL, false)
	var red: SwitchBlock = kit.switch_block(30, 33, 0, true, false)
	var blue: SwitchBlock = kit.switch_block(36, 39, 0, false, false)
	var button: SwitchButton = kit.switch_button(4, 0)
	_go()
	await _wait(0.2)
	_check("red starts solid, blue starts ghost", not red.shape.disabled and blue.shape.disabled)
	Input.action_press(&"ui_right")
	await _wait(1.0)
	Input.action_release(&"ui_right")
	_check("walking onto the button swapped them (red ghost %s, blue solid %s)" % [str(red.shape.disabled), str(not blue.shape.disabled)], red.shape.disabled and not blue.shape.disabled)
	await _wait(1.0)
	button.press()
	await _wait(0.2)
	_check("pressing again swaps back", not red.shape.disabled and blue.shape.disabled)
	button.press()
	await _wait(1.0)
	button.press()
	await _wait(0.2)
	player.respawned.emit()
	await _wait(0.2)
	_check("respawning puts the blocks back how they started", not red.shape.disabled and blue.shape.disabled)

	# --- Warp pipe: walking in sends him away, walking the wrong way does not. ---
	_fresh()
	kit.ground(-20, 90, 0, kit.STEEL, false)
	kit.warp_pipe(5, 0, 1.0, Vector3(60, 3.0, 0))
	_go()
	await _wait(0.3)
	Input.action_press(&"ui_right")
	await _wait(1.5)
	Input.action_release(&"ui_right")
	_check("walking into the pipe pops him out far away (x=%.0f)" % player.position.x, player.position.x > 55.0)
	await _wait(1.5)
	_fresh()
	kit.ground(-20, 90, 0, kit.STEEL, false)
	kit.warp_pipe(5, 0, -1.0, Vector3(60, 3.0, 0))
	_go()
	await _wait(0.3)
	Input.action_press(&"ui_right")
	await _wait(1.5)
	Input.action_release(&"ui_right")
	_check("walking past the back of a pipe does nothing (x=%.0f)" % player.position.x, player.position.x < 30.0)

	# --- Fan: pushes him in the air, not on the floor. ---
	_fresh(Vector3(0, 6, 0))
	kit.fan(-10, 10, -5, 12, 1.0)
	_go()
	await _wait(0.5)
	var pushed: float = player.position.x
	_fresh(Vector3(0, 6, 0))
	_go()
	await _wait(0.5)
	_check("fan pushes him along in the air (x=%.1f, %.1f without)" % [pushed, player.position.x], pushed > 1.2 and absf(player.position.x) < 0.1)
	_fresh()
	kit.ground(-30, 30, 0, kit.STEEL, false)
	kit.fan(-10, 10, -1, 6, 1.0)
	_go()
	await _wait(1.0)
	_check("fan does not push him on the floor (x=%.2f)" % player.position.x, absf(player.position.x) < 0.2)

	# --- Steam vent: quiet at first, then a puff launches him high. ---
	_fresh()
	kit.ground(-20, 20, 0, kit.STEEL, false)
	var vent: SteamVent = kit.vent(0, 0, {"off_time": 1.0, "warn_time": 0.4, "puff_time": 0.6})
	_go()
	await _wait(0.5)
	_check("vent is quiet at first (y=%.2f)" % player.position.y, player.position.y < 1.5 and not vent.is_puffing)
	var peak: float = 0.0
	for i in 150:
		await physics_frame
		peak = maxf(peak, player.position.y)
	_check("vent puff launches him high (peak %.1f m) and does not hurt (hearts %d)" % [peak, _hearts()], peak > 7.0 and _hearts() == 3)

	# --- Cork Bot: rolls along, hurts from the side, stompable from above. ---
	_fresh()
	kit.ground(-40, 80, 0, kit.STEEL, false)
	var bot: CorkBot = kit.enemy("cork_bot", 20, 0, {"patrol_distance": 4.0})
	_go()
	var left: float = 99.0
	var right: float = -99.0
	for i in 180:
		await physics_frame
		left = minf(left, bot.position.x)
		right = maxf(right, bot.position.x)
	_check("cork bot rolls to and fro (x from %.1f to %.1f) and its cork spins (%.1f)" % [left, right, bot.roller.rotation.z], right - left > 3.0 and absf(bot.roller.rotation.z) > 0.5)
	_fresh(Vector3(-3, 1.2, 0))
	kit.ground(-40, 80, 0, kit.STEEL, false)
	bot = kit.enemy("cork_bot", 3, 0, {"walk_speed": 0.0})
	_go()
	Input.action_press(&"ui_right")
	await _wait(1.2)
	Input.action_release(&"ui_right")
	_check("walking into a cork bot hurts (hearts %d)" % _hearts(), _hearts() < 3)
	_fresh(Vector3(0, 6, 0))
	kit.ground(-40, 80, 0, kit.STEEL, false)
	bot = kit.enemy("cork_bot", 0, 0, {"walk_speed": 0.0})
	var squashed: Array[bool] = [false]
	bot.connect("squashed", func() -> void: squashed[0] = true)
	_go()
	await _wait(1.5)
	_check("cork bot stomped from above, hearts %d" % _hearts(), squashed[0] and _hearts() == 3)

	# --- Fizz Bat: flies in a wave, stompable from above. ---
	_fresh()
	kit.ground(-40, 80, 0, kit.STEEL, false)
	var bat: FizzBat = kit.enemy("fizz_bat", 20, 4.0, {"wave_height": 1.2})
	_go()
	var low: float = 99.0
	var high: float = -99.0
	for i in 180:
		await physics_frame
		low = minf(low, bat.position.y)
		high = maxf(high, bat.position.y)
	_check("fizz bat flies in a wave (y from %.1f to %.1f)" % [low, high], high - low > 1.5)
	_fresh(Vector3(0, 8, 0))
	kit.ground(-40, 80, 0, kit.STEEL, false)
	bat = kit.enemy("fizz_bat", 0, 2.5, {"walk_speed": 0.0, "wave_height": 0.6})
	squashed[0] = false
	bat.connect("squashed", func() -> void: squashed[0] = true)
	_go()
	await _wait(1.5)
	_check("fizz bat stomped from above, hearts %d" % _hearts(), squashed[0] and _hearts() == 3)

	Input.action_release(&"ui_right")
	print("world 2 things failures: %d" % failures)
	quit()
