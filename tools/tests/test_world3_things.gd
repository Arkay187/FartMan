extends SceneTree
# Checks the World 3 (Planet Whiff) building blocks one at a time, built with the Whiff kit:
# squishy gas clouds, Burp Bubbles (and stinky ones), gas geysers, Whifflers, the Jellyfish and
# the lightning bolt.

var failures: int = 0
var kit: RefCounted
var stage: Node3D
var player: Player
var simple: bool = true


func _initialize() -> void:
	_run()


func _wait(seconds: float) -> void:
	for i in int(seconds * 60.0):
		await physics_frame


func _check(label: String, ok: bool) -> void:
	print("%s: %s" % [label, "ok" if ok else "FAIL"])
	if not ok:
		failures += 1


## A fresh little stage made with the Whiff kit. Add things to it with kit.xxx(), then _go().
func _fresh(at: Vector3 = Vector3(0, 1.2, 0)) -> void:
	Input.action_release(&"ui_right")
	Input.action_release(&"ui_left")
	Input.action_release(&"jump")
	if stage != null:
		stage.free()
	kit = load("res://tools/kit_whiff.gd").new()
	kit.begin("test", "", at, Color(0.4, 0.3, 0.5))
	stage = kit.root
	player = kit.player
	(root.get_node("DebugOptions") as DebugOptionsData).set_simple_controls(simple)


func _go() -> void:
	root.add_child(stage)


func _hearts() -> int:
	return (player.get_node("Hearts") as Hearts).hearts


## Highest his feet get in the next few seconds.
func _peak(seconds: float) -> float:
	var top: float = -1000.0
	for i in int(seconds * 60.0):
		await physics_frame
		top = maxf(top, player.get_feet_y())
	return top


func _run() -> void:
	# --- Gas cloud: walking on is calm, landing from a height bounces, it sinks a little. ---
	_fresh()
	var cloud: GasCloud = kit.cloud(-20, 20, 0, {}, false)
	_go()
	await _wait(1.0)
	_check("a cloud holds him up (feet %.2f)" % player.get_feet_y(), player.is_on_floor() and absf(player.get_feet_y() - (0.0 - cloud.dip_depth)) < 0.3)
	_check("it sank a little under him (cloud y %.2f, rest %.2f)" % [cloud.position.y, -0.6], cloud.position.y < -0.6 - 0.2)
	player.global_position = Vector3(5, 6.0, 0)
	player.velocity = Vector3.ZERO
	var peak: float = await _peak(2.0)
	_check("dropping 6 m onto a cloud bounces him back up (peak feet %.1f)" % peak, peak > 3.0)
	_fresh(Vector3(0, 0.5, 0))
	kit.cloud(-20, 20, 0, {}, false)
	_go()
	await _wait(1.0)
	player.global_position = Vector3(5, 0.5, 0)
	player.velocity = Vector3.ZERO
	var calm: float = await _peak(1.0)
	_check("just walking onto a cloud does not bounce (peak feet %.2f)" % calm, calm < 0.9)

	# --- Burp Bubble: land on top and bounce very high; side touches do nothing; it comes back. ---
	_fresh(Vector3(-20, 1.2, 0))
	kit.ground(-40, 40, 0, kit.CLOUD_TEAL, false)
	var bubble: BurpBubble = kit.bubble(0, 6.0, {"rise_speed": 0.0, "rise_height": 0.0, "respawn_delay": 1.0}) as BurpBubble
	_go()
	await _wait(0.3)
	player.global_position = Vector3(-1.5, 6.0, 0)
	player.velocity = Vector3.ZERO
	await _wait(0.1)
	_check("touching a bubble from the side does nothing (alive %s)" % str(bubble.is_alive), bubble.is_alive)
	player.global_position = Vector3(0.0, 9.6, 0)
	player.velocity = Vector3(0, -3, 0)
	var vy: float = -100.0
	for i in 40:
		await physics_frame
		vy = maxf(vy, player.velocity.y)
	_check("landing on a bubble pops it and bounces him (best speed %.1f, bubble power %.0f)" % [vy, bubble.bounce_power], vy >= bubble.bounce_power - 1.0 and not bubble.is_alive)
	_check("a bubble bounce is higher than a spring-less double jump (power %.0f > 17)" % bubble.bounce_power, bubble.bounce_power > 17.0)
	player.global_position = Vector3(-30, 1.2, 0)
	player.velocity = Vector3.ZERO
	await _wait(1.5)
	_check("the bubble comes back", bubble.is_alive)
	_fresh()
	var rising: BurpBubble = kit.bubble(30, 0.0, {"rise_speed": 2.0, "rise_height": 4.0}) as BurpBubble
	_go()
	await _wait(1.0)
	_check("bubbles float upwards (y %.1f)" % rising.position.y, rising.position.y > 1.5)
	_fresh(Vector3(-20, 1.2, 0))
	kit.ground(-40, 40, 0, kit.CLOUD_TEAL, false)
	var stinker: BurpBubble = kit.bubble(0, 1.2, {"rise_speed": 0.0, "rise_height": 0.0, "stinky": true}) as BurpBubble
	_go()
	await _wait(0.3)
	player.global_position = Vector3(0, 1.2, 0)
	await _wait(0.3)
	_check("a stinky bubble hurts and cannot be stomped (hearts %d, alive %s)" % [_hearts(), str(stinker.is_alive)], _hearts() < 3 and stinker.is_alive)

	# --- Gas geyser: fills the tank, blasts him up, safe, and it is a launcher for the route check. ---
	_fresh()
	kit.ground(-30, 30, 0, kit.CLOUD_TEAL, false)
	var geyser: GasGeyser = kit.geyser(0, 0, {"off_time": 1.0, "puff_time": 1.0, "warn_time": 0.5}) as GasGeyser
	_go()
	await _wait(0.3)
	player.gas_tank.gas = 5.0
	player.global_position = Vector3(0, 1.2, 0)
	player.velocity = Vector3.ZERO
	geyser._age = geyser.off_time - 0.02
	var top: float = await _peak(2.0)
	_check("a geyser blasts him high (peak feet %.1f, want over 6)" % top, top > 6.0)
	_check("and fills his tank (gas %.0f)" % player.gas_tank.gas, player.gas_tank.gas > 60.0)
	_check("geysers never hurt (hearts %d)" % _hearts(), _hearts() == 3)
	_check("the kit remembers geysers as lifts for the route check", kit.vents.size() == 1)

	# --- Whiffler: rest, swell (warning), puff (hurts, even from above), rest again. ---
	_fresh(Vector3(-8, 1.2, 0))
	kit.ground(-30, 30, 0, kit.CLOUD_TEAL, false)
	var whiffler: Whiffler = kit.enemy("whiffler", 0, 0) as Whiffler
	whiffler.rest_time = 1.0
	whiffler.tell_time = 0.6
	whiffler.puff_time = 1.0
	_go()
	await _wait(0.2)
	_check("it starts resting", whiffler.mood == Whiffler.Mood.REST)
	var moods: Array[int] = []
	for i in 400:
		await physics_frame
		if moods.is_empty() or moods[moods.size() - 1] != whiffler.mood:
			moods.append(whiffler.mood)
	_check("it cycles rest > swell > puff > rest (%s)" % str(moods), moods.size() >= 4 and moods[0] == Whiffler.Mood.REST
		and moods[1] == Whiffler.Mood.TELL and moods[2] == Whiffler.Mood.PUFF and moods[3] == Whiffler.Mood.REST)
	_check("the stink cloud is only on while puffing", not whiffler.cloud_zone.monitoring or whiffler.mood == Whiffler.Mood.PUFF)
	# Waiting for a puff, then landing on it from above: the cloud hurts.
	while whiffler.mood != Whiffler.Mood.PUFF:
		await physics_frame
	await _wait(0.1)
	player.global_position = Vector3(0, 2.6, 0)
	player.velocity = Vector3(0, -4, 0)
	var hearts_before: int = _hearts()
	await _wait(0.4)
	_check("landing on it during a puff hurts (hearts %d -> %d) and it is not squashed" % [hearts_before, _hearts()],
		_hearts() < hearts_before and not whiffler.is_squashed)
	# Between puffs: stomping squashes it.
	player.flashing_left = 0.0
	player.global_position = Vector3(-8, 1.2, 0)
	player.velocity = Vector3.ZERO
	while whiffler.mood != Whiffler.Mood.REST:
		await physics_frame
	player.global_position = Vector3(0, 2.0, 0)
	player.velocity = Vector3(0, -6, 0)
	await _wait(0.3)
	_check("stomping it while it rests squashes it (squashed %s)" % str(not is_instance_valid(whiffler) or whiffler.is_squashed), not is_instance_valid(whiffler) or whiffler.is_squashed)

	# --- Jellyfish: bobs, hurts from the side, pops when you land on it. ---
	_fresh(Vector3(-8, 1.2, 0))
	kit.ground(-30, 30, 0, kit.CLOUD_TEAL, false)
	var jelly: Jellyfish = kit.jelly(0, 3.0, {"bob_height": 1.0}) as Jellyfish
	_go()
	await _wait(1.0)
	_check("it bobs (y %.2f)" % jelly.position.y, absf(jelly.position.y - 3.0) > 0.05)
	jelly.set_physics_process(false)
	jelly.position.y = 3.0
	player.global_position = Vector3(0, 3.0, 0)
	jelly.set_physics_process(true)
	await _wait(0.2)
	_check("touching it from the side hurts (hearts %d)" % _hearts(), _hearts() < 3)
	player.flashing_left = 0.0
	jelly.set("bob_height", 0.0)
	jelly.set("drift", 0.0)
	jelly.position.x = 0.0
	player.global_position = Vector3(0, 6.0, 0)
	player.velocity = Vector3(0, -8, 0)
	await _wait(0.5)
	_check("landing on it from above pops it", not is_instance_valid(jelly) or jelly.is_squashed)

	# --- Lightning: a warning flicker, then it strikes and hurts. ---
	_fresh(Vector3(-8, 1.2, 0))
	kit.ground(-30, 30, 0, kit.CLOUD_TEAL, false)
	var bolt: LightningBolt = kit.lightning(0, 0, 8, 0.0, {"off_time": 1.0, "warn_time": 0.5, "on_time": 0.4}) as LightningBolt
	_go()
	var saw_warning: bool = false
	var saw_strike: bool = false
	for i in 90:
		await physics_frame
		saw_warning = saw_warning or bolt.is_warning
		saw_strike = saw_strike or bolt.is_on
	_check("lightning flickers a warning before it strikes (warning %s, strike %s)" % [str(saw_warning), str(saw_strike)], saw_warning and saw_strike)
	player.flashing_left = 0.0
	player.global_position = Vector3(0, 1.2, 0)
	var hurt: bool = false
	for i in 120:
		await physics_frame
		if _hearts() < 3:
			hurt = true
			break
	_check("standing in the bolt when it strikes hurts", hurt)

	if stage != null:
		stage.free()
	print("world 3 things failures: %d" % failures)
	quit()
