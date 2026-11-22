extends SceneTree
# Checks the four World 3 stages: no impossible steps on the main path, every stage has its
# 3 Golden Beans, toilets, a Bean Can (or a boss), a safe start; the geysers and bubbles really
# carry him up the route; the secret bean rooms in 3-1 and 3-2 have loads of beans and things to
# bounce on, and the pipes in and out work; the Stink Storm has its two boosts; the TEST LEVELS
# list has the four stages.


## A level kit that does everything the real one does but does not save the scene file.
class NoSaveKit extends "res://tools/kit_whiff.gd":
	func finish(_path: String) -> Array[String]:
		var problems: Array[String] = check_route()
		root.free()
		return problems


var failures: int = 0
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


func _count(stage: Node, class_name_text: String) -> int:
	return stage.find_children("*", class_name_text, true, false).size()


func _scene_path(id: String) -> String:
	return "res://scenes/stage_%s.tscn" % id.replace("-", "_")


func _load(id: String) -> Stage:
	var stage: Stage = load(_scene_path(id)).instantiate()
	root.add_child(stage)
	return stage


## How many beans (plain) are inside a box of the stage.
func _beans_in(stage: Node, x0: float, x1: float, y0: float, y1: float) -> int:
	var found: int = 0
	for bean: Node in stage.find_children("*", "Area3D", true, false):
		var script: Script = bean.get_script()
		if script != null and script.resource_path == "res://scripts/bean.gd":
			var p: Vector3 = (bean as Node3D).global_position
			if p.x >= x0 and p.x <= x1 and p.y >= y0 and p.y <= y1:
				found += 1
	return found


## Things to bounce on (springs, geysers, bubbles) inside a box.
func _bouncers_in(stage: Node, x0: float, x1: float, y0: float, y1: float) -> int:
	var found: int = 0
	for kind in ["Spring", "GasGeyser", "BurpBubble"]:
		for thing: Node in stage.find_children("*", kind, true, false):
			var p: Vector3 = (thing as Node3D).global_position
			if p.x >= x0 and p.x <= x1 and p.y >= y0 and p.y <= y1:
				found += 1
	return found


## Stands him on a geyser that is about to blast, holds right, and says whether he lands on the
## target (x range and top height) within a few seconds.
func _geyser_hop(stage: Stage, geyser_x: float, geyser_top: float, x0: float, x1: float, top: float) -> bool:
	var player: Player = stage.player
	player.flashing_left = 1000.0
	player.position = Vector3(geyser_x, geyser_top + 1.0, 0)
	player.velocity = Vector3.ZERO
	for g: Node in stage.find_children("*", "GasGeyser", true, false):
		if absf((g as Node3D).position.x - geyser_x) < 0.1 and absf((g as Node3D).position.y - geyser_top) < 0.1:
			(g as GasGeyser)._age = (g as GasGeyser).off_time - 0.02
	Input.action_press(&"ui_right")
	var landed: bool = false
	for i in 300:
		await physics_frame
		if player.is_on_floor() and player.position.x >= x0 and player.position.x <= x1 and absf(player.position.y - (top + 1.0)) < 0.3:
			landed = true
			break
	Input.action_release(&"ui_right")
	return landed


## Checks a secret bean room: its pipe in takes him up, there are loads of beans and bouncers,
## and the pipe out takes him back down.
func _check_room(stage: Stage, label: String, room_x: float) -> void:
	var x0: float = room_x - 19.0
	var x1: float = room_x + 19.0
	var beans: int = _beans_in(stage, x0, x1, 55.0, 90.0)
	var bouncers: int = _bouncers_in(stage, x0, x1, 55.0, 90.0)
	_check("%s has loads of beans (%d, want 60 or more)" % [label, beans], beans >= 60)
	_check("%s has things to bounce on (%d, want 2 or more)" % [label, bouncers], bouncers >= 2)
	var pipe_in: WarpPipe = null
	var pipe_out: WarpPipe = null
	for node: Node in stage.find_children("*", "WarpPipe", true, false):
		var pipe: WarpPipe = node as WarpPipe
		if pipe.destination.y > 55.0 and absf(pipe.destination.x - (x0 + 3.0)) < 2.0:
			pipe_in = pipe
		elif pipe.global_position.y > 55.0 and absf(pipe.global_position.x - room_x) < 19.0:
			pipe_out = pipe
	_check("%s has a pipe in and a pipe out" % label, pipe_in != null and pipe_out != null)
	if pipe_in == null or pipe_out == null:
		return
	var player: Player = stage.player
	player.flashing_left = 1000.0
	WarpPipe._blocked_until = 0.0
	player.position = pipe_in.global_position + Vector3(-1.4, 0.8, 0)
	player.velocity = Vector3.ZERO
	await _wait(0.4)
	Input.action_press(&"ui_right")
	var got_in: bool = false
	for i in 120:
		await physics_frame
		if player.position.y > 55.0:
			got_in = true
			break
	Input.action_release(&"ui_right")
	_check("%s: walking into the entrance pipe puts him in the room (y %.1f)" % [label, player.position.y], got_in)
	# The way out is obvious: walk into the pipe at the right end.
	WarpPipe._blocked_until = 0.0
	await _wait(1.2)
	player.position = pipe_out.global_position + Vector3(-1.4, 0.8, 0)
	player.velocity = Vector3.ZERO
	await _wait(0.4)
	Input.action_press(&"ui_right")
	var got_out: bool = false
	for i in 120:
		await physics_frame
		if player.position.y < 50.0:
			got_out = true
			break
	Input.action_release(&"ui_right")
	_check("%s: the way out takes him back to the stage (y %.1f)" % [label, player.position.y], got_out)
	await _wait(1.2)


func _run() -> void:
	var save: Node = root.get_node_or_null("SaveGame")
	if save != null:
		save.use_file("user://test_world3_stages_save.json")
		save.reset()
	(root.get_node("DebugOptions") as DebugOptionsData).set_simple_controls(simple)

	# --- The main path of every stage has no impossible gaps or steps, and reaches the Bean Can. ---
	for id in ["3-1", "3-2", "3-3", "3-4"]:
		var script: GDScript = load("res://tools/stages/stage_%s.gd" % id.replace("-", "_"))
		var kit: RefCounted = NoSaveKit.new()
		var problems: Array[String] = script.new().build(kit)
		_check("stage %s has no route problems %s" % [id, str(problems)], problems.is_empty())
		var furthest: float = 0.0
		for piece: Array in kit.routes:
			furthest = maxf(furthest, float(piece[1]))
		print("%s: main path pieces %d, helped stretches %d, reaches x=%.0f" % [id, kit.routes.size(), kit.assists.size(), furthest])

	# --- Every stage loads, starts safe, has 3 Golden Beans and toilets. ---
	var info: Dictionary = {
		"3-1": {"toilets": 8, "bean_can": true}, "3-2": {"toilets": 12, "bean_can": true},
		"3-3": {"toilets": 8, "bean_can": true}, "3-4": {"toilets": 8, "bean_can": false},
	}
	for id: String in info:
		var stage: Stage = _load(id)
		await _wait(1.0)
		var toilets: int = _count(stage, "Toilet") + _count(stage, "SkyToilet")
		toilets = 0
		for node: Node in stage.find_children("*", "Area3D", true, false):
			if node is Toilet:
				toilets += 1
		var cans: int = get_nodes_in_group(&"bean_cans").size()
		print("%s: golden beans %d, toilets %d, bean cans %d, hearts %d" % [id, stage.golden_total, toilets, cans, (stage.player.get_node("Hearts") as Hearts).hearts])
		_check("%s has 3 Golden Beans" % id, stage.golden_total == 3)
		_check("%s has toilets (%d, want %d or more)" % [id, toilets, info[id]["toilets"]], toilets >= int(info[id]["toilets"]))
		_check("%s has a Bean Can" % id if info[id]["bean_can"] else "%s ends with the boss, not a can" % id, (cans == 1) == bool(info[id]["bean_can"]))
		# A safe start: nothing nasty within 12 m of where he starts, and he is standing or flying.
		var start: Vector3 = stage.player.global_position
		var nasty: int = 0
		for node: Node in stage.find_children("*", "Area3D", true, false):
			if node is Burpling or node is LightningBolt or node is SparkCable or node is Hazard:
				if absf((node as Node3D).global_position.x - start.x) < 12.0:
					nasty += 1
		_check("%s starts safe (%d nasty things near, on floor or flying %s)" % [id, nasty, str(stage.player.is_on_floor() or stage.player.is_flying())],
			nasty == 0 and (stage.player.is_on_floor() or stage.player.is_flying()))
		stage.free()
		await _wait(0.2)

	# --- 3-1: clouds, bubbles, geysers, Whifflers. ---
	var s1: Stage = _load("3-1")
	await _wait(0.5)
	print("3-1: clouds %d, bubbles %d, geysers %d, whifflers %d, fizz bats %d" % [
		_count(s1, "GasCloud"), _count(s1, "BurpBubble"), _count(s1, "GasGeyser"), _count(s1, "Whiffler"), _count(s1, "FizzBat")])
	_check("3-1 has clouds, bubbles, geysers, whifflers and bats",
		_count(s1, "GasCloud") >= 6 and _count(s1, "BurpBubble") >= 8 and _count(s1, "GasGeyser") >= 8
		and _count(s1, "Whiffler") >= 8 and _count(s1, "FizzBat") >= 3)
	var tower_a: bool = await _geyser_hop(s1, 122.0, 0.0, 131.0, 139.0, 9.5)
	_check("3-1 first geyser lands him on the first tower rock", tower_a)
	var tower_b: bool = await _geyser_hop(s1, 137.0, 9.5, 143.5, 150.5, 19.0)
	_check("3-1 second geyser lands him on the second rock", tower_b)
	var tower_c: bool = await _geyser_hop(s1, 148.0, 19.0, 154.0, 162.0, 28.5)
	_check("3-1 third geyser lands him on the top rock", tower_c)
	var sky_a: bool = await _geyser_hop(s1, 344.0, 0.0, 354.0, 360.0, 10.0)
	_check("3-1 sky climb geyser lands him on the rock", sky_a)
	# A bubble ride up to the ledge with Golden Bean 1 (the bubble is held still for the test).
	var player: Player = s1.player
	player.flashing_left = 1000.0
	for b: Node in s1.find_children("*", "BurpBubble", true, false):
		if absf((b as Node3D).position.x - 99.5) < 0.1:
			var bubble: BurpBubble = b as BurpBubble
			bubble.rise_speed = 0.0
			bubble.position.y = 4.0
			player.position = Vector3(99.5, 9.0, 0)
			player.velocity = Vector3(0, -3, 0)
			Input.action_press(&"ui_right")
			var on_ledge: bool = false
			for i in 240:
				await physics_frame
				if player.is_on_floor() and player.position.x > 103.0 and player.position.x < 112.0 and player.position.y > 14.5:
					on_ledge = true
					break
			Input.action_release(&"ui_right")
			_check("3-1 a bubble bounce carries him up to the Golden Bean ledge (x %.1f y %.1f)" % [player.position.x, player.position.y], on_ledge)
	# The squishy cloud net at the bottom of the pit bounces him back up.
	player.position = Vector3(86.0, -1.0, 0)
	player.velocity = Vector3(0, -8, 0)
	var net_peak: float = -100.0
	for i in 150:
		await physics_frame
		net_peak = maxf(net_peak, player.position.y)
	_check("3-1 the cloud net under the bubble pit bounces him back up (peak y %.1f)" % net_peak, net_peak > -1.0)
	await _check_room(s1, "3-1 bean room 1", 250.0)
	await _check_room(s1, "3-1 bean room 2", 330.0)
	s1.free()
	await _wait(0.2)

	# --- 3-2: the fortress. ---
	var s2: Stage = _load("3-2")
	await _wait(0.5)
	print("3-2: belts %d, presses %d, springs %d, barrels %d, fans %d, biscuits %d, switch blocks %d, pipes %d, vents %d, geysers %d, bubbles %d, whifflers %d, cork bots %d, gnomes %d, hot sauce %d, chilli %d" % [
		_count(s2, "Conveyor"), _count(s2, "StampPress"), _count(s2, "Spring"), _count(s2, "BarrelCannon"), _count(s2, "Fan"), _count(s2, "CrumblePlatform"),
		_count(s2, "SwitchBlock"), _count(s2, "WarpPipe"), _count(s2, "SteamVent"), _count(s2, "GasGeyser"), _count(s2, "BurpBubble"), _count(s2, "Whiffler"),
		_count(s2, "CorkBot"), _count(s2, "Gnome"), s2.find_children("HotSauce*", "Area3D", true, false).size(), s2.find_children("Chilli*", "Area3D", true, false).size()])
	_check("3-2 remixes the whole game (belts, presses, springs, a barrel, a fan, biscuits, switches, pipes, vents, geysers, bubbles)",
		_count(s2, "Conveyor") >= 2 and _count(s2, "StampPress") >= 3 and _count(s2, "Spring") >= 3 and _count(s2, "BarrelCannon") >= 1
		and _count(s2, "Fan") >= 1 and _count(s2, "CrumblePlatform") >= 5 and _count(s2, "SwitchBlock") >= 4 and _count(s2, "WarpPipe") >= 4
		and _count(s2, "SteamVent") >= 1 and _count(s2, "GasGeyser") >= 8 and _count(s2, "BurpBubble") >= 8)
	_check("3-2 has enemies from all three worlds, a chilli dash and a Hot Sauce party",
		_count(s2, "Burpling") >= 40 and _count(s2, "Whiffler") >= 8 and _count(s2, "CorkBot") >= 6 and _count(s2, "Hiccup") >= 4
		and s2.find_children("HotSauce*", "Area3D", true, false).size() == 1 and s2.find_children("Chilli*", "Area3D", true, false).size() >= 1)
	var t2a: bool = await _geyser_hop(s2, 609.0, 7.5, 616.0, 622.0, 16.5)
	_check("3-2 tower geyser 1 lands him on the next rock", t2a)
	var t2b: bool = await _geyser_hop(s2, 620.0, 16.5, 627.0, 633.0, 25.5)
	_check("3-2 tower geyser 2 lands him on the top rock", t2b)
	# The barrel cannon at 60 degrees throws him across the gap to the far rock.
	var player2: Player = s2.player
	player2.flashing_left = 1000.0
	player2.position = Vector3(206.0, 7.2, 0)
	player2.velocity = Vector3.ZERO
	await _wait(0.5)
	Input.action_press(&"jump")
	await _wait(0.1)
	Input.action_release(&"jump")
	var across: bool = false
	for i in 240:
		await physics_frame
		if player2.is_on_floor() and player2.position.x > 219.0 and player2.position.x < 227.0 and player2.position.y > 6.5:
			across = true
			break
	_check("3-2 the barrel cannon shoots him across to the far rock (x %.1f y %.1f)" % [player2.position.x, player2.position.y], across)
	await _check_room(s2, "3-2 bean room 1", 300.0)
	await _check_room(s2, "3-2 bean room 2", 380.0)
	s2.free()
	await _wait(0.2)

	# --- 3-3: the Stink Storm. ---
	var s3: Stage = _load("3-3")
	await _wait(0.5)
	var zones: Array[Node] = s3.find_children("*", "SuperBoost", true, false)
	print("3-3: boosts %d, jellyfish %d, lightning %d, rings %d" % [zones.size(), _count(s3, "Jellyfish"), _count(s3, "LightningBolt"), _count(s3, "SmokeRing")])
	_check("3-3 is a flying stage with 2 or more fast boosts", s3.start_flight != Vector2.ZERO and zones.size() >= 2)
	var fast_enough: bool = true
	var clear_of_hazards: bool = true
	for z: Node in zones:
		var zone: SuperBoost = z as SuperBoost
		fast_enough = fast_enough and zone.speed_multiplier >= 3.0
		for hazard: Node in s3.find_children("*", "Area3D", true, false):
			if hazard is Jellyfish or hazard is LightningBolt:
				if absf((hazard as Node3D).global_position.x - zone.global_position.x) < zone.length * 0.5:
					clear_of_hazards = false
	_check("the boosts are SUPER BOOSTs (3x or more)", fast_enough)
	_check("the boosts have nothing nasty in them", clear_of_hazards)
	_check("3-3 has jellyfish, lightning and big rings", _count(s3, "Jellyfish") >= 8 and _count(s3, "LightningBolt") >= 8 and _count(s3, "SmokeRing") >= 15)
	var p3: Player = s3.player
	p3.flashing_left = 1000.0
	var x_a: float = p3.position.x
	await _wait(1.0)
	var normal_speed: float = p3.position.x - x_a
	p3.position = Vector3(250.0, 12.0, 0)
	x_a = p3.position.x
	await _wait(1.0)
	var boost_speed: float = p3.position.x - x_a
	_check("flying is %.0f m/s normally and %.0f m/s inside a boost" % [normal_speed, boost_speed], normal_speed > 12.0 and boost_speed > normal_speed * 2.5)
	s3.free()
	await _wait(0.2)

	# --- 3-4 the boss stage loads with the boss and its parts. ---
	var s4: Stage = _load("3-4")
	await _wait(0.5)
	var boss: BigBadBurp = s4.find_child("BigBadBurp", true, false) as BigBadBurp
	_check("3-4 has Big Bad Burp with a trigger, door, gate and a burrito",
		boss != null and boss.trigger != null and boss.door != null and boss.gate != null and boss.burrito != null and boss.head != null)
	s4.free()
	await _wait(0.2)

	# --- The TEST LEVELS list has the four World 3 stages. ---
	var list: TestLevels = load("res://scenes/test_levels.tscn").instantiate()
	root.add_child(list)
	await _wait(0.4)
	var found: int = 0
	for scene_path in list.scenes:
		if scene_path.contains("stage_3_"):
			found += 1
	_check("the TEST LEVELS list has 3-1 to 3-4 (%d), BACK is still last (%s)" % [found, list.titles[list.titles.size() - 1]],
		found == 4 and list.titles[list.titles.size() - 1] == "BACK" and list.rows.size() == list.titles.size())
	list.free()

	# --- Saving works for World 3 stops. ---
	if save != null:
		save.record_stage("3-1", 2, 900)
		save.record_stage("3-4", 3, 5000)
		_check("progress saves for 3-1 and 3-4", save.is_cleared("3-1") and save.best_golden("3-1") == 2 and save.best_score("3-4") == 5000)
		save.reset()
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://test_world3_stages_save.json"))
	print("world 3 stages failures: %d" % failures)
	quit()
