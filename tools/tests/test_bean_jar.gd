extends SceneTree
# Checks the Bean Jar: beans count into the pot and the stage total, toilets / clearing the stage /
# quitting from the pause menu / losing all hearts bank the pot into the jar (and save), spills take
# up to 6 from the pot (and no gas), grabbing them back refills the pot, the jar only goes down with
# spend_beans, it survives a reload, the HUD counter, the end-of-stage pour, the map's BEAN JAR
# total and the Complex2000 on the map.

const SAVE_FILE: String = "user://test_bean_jar_save.json"
var failures: int = 0
var save: SaveData
var options: DebugOptionsData
var world: Node3D
var p: Player
var stage_node: Stage


func _initialize() -> void:
	_run()


func _wait(seconds: float) -> void:
	for i in int(seconds * 60.0):
		await physics_frame


func _check(label: String, ok: bool) -> void:
	print("%s: %s" % [label, "ok" if ok else "FAILED"])
	if not ok:
		failures += 1


## A real stage, added to the tree and settled.
func _load_stage(path: String) -> Stage:
	var level := (load(path) as PackedScene).instantiate() as Stage
	root.add_child(level)
	await _wait(0.4)
	return level


## Puts a bean on Fart Man so he eats it, and waits for it.
func _feed(level: Stage, player: Player, count: int) -> void:
	for i in count:
		var bean := (load("res://scenes/bean.tscn") as PackedScene).instantiate() as Node3D
		level.add_child(bean)
		bean.global_position = player.global_position
		await _wait(0.1)


func _saved_jar() -> int:
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(SAVE_FILE)) != OK:
		return -1
	return int((json.data as Dictionary).get("bean_jar", -1))


func _beans_thrown(parent: Node) -> Array[Node3D]:
	var found: Array[Node3D] = []
	for child: Node in parent.get_children():
		if child.scene_file_path == "res://scenes/bean.tscn" and child.get_node_or_null("LootBounce") != null:
			found.append(child as Node3D)
	return found


func _reset_player() -> void:
	p.global_position = Vector3(100, 1.0, 0)
	p.velocity = Vector3.ZERO
	p.flashing_left = 0.0
	p.hearts.hearts = p.hearts.max_hearts
	p.gas_tank.gas = p.gas_tank.max_gas


func _run() -> void:
	save = root.get_node_or_null("SaveGame") as SaveData
	if save == null:
		save = SaveData.new()
		save.name = "SaveGame"
		root.add_child(save)
	save.use_file(SAVE_FILE)
	save.reset()
	await _wait(0.2)
	options = root.get_node("DebugOptions")
	options.set_simple_controls(false)
	options.set_gas_mode(DebugOptionsData.GasMode.NORMAL)
	_check("headless runs never touch the real save (%s)" % save.save_path, save.save_path == SAVE_FILE)

	# ---------------------------------------------------------------- the jar itself
	_check("a new jar is empty", save.bean_jar == 0)
	save.bank_beans(5)
	_check("bank_beans adds to the jar (%d)" % save.bean_jar, save.bean_jar == 5)
	save.bank_beans(0)
	save.bank_beans(-3)
	_check("banking zero or a negative number changes nothing (%d)" % save.bean_jar, save.bean_jar == 5)
	_check("spend_beans refuses when short and changes nothing", not save.spend_beans(6) and save.bean_jar == 5)
	_check("spend_beans refuses a negative number", not save.spend_beans(-1) and save.bean_jar == 5)
	_check("spend_beans takes beans out (%d)" % save.bean_jar, save.spend_beans(2) and save.bean_jar == 3)
	_check("the jar was saved to the file (%d)" % _saved_jar(), _saved_jar() == 3)
	save.stages["1-1"] = {"cleared": true, "golden": 1, "score": 10}
	save.load_game()
	_check("reloading the file brings the jar back (%d)" % save.bean_jar, save.bean_jar == 3)
	save.record_stage("1-2", 1, 5)
	save.mark_seen("hello")
	save.set_last_stop("1-2")
	_check("other saves never lower the jar", save.bean_jar == 3)
	var fresh := SaveData.new()
	fresh.use_file(SAVE_FILE)
	_check("a second SaveData reading the file sees the same jar (%d)" % fresh.bean_jar, fresh.bean_jar == 3)
	fresh.free()
	save.reset()
	_check("reset empties the jar", save.bean_jar == 0 and _saved_jar() == 0)

	# ---------------------------------------------------------------- eating beans, the HUD, a toilet
	var level: Stage = await _load_stage("res://scenes/stage_1_1.tscn")
	var player := level.get_node("Player") as Player
	var counter := level.get_node("HUD/BeanCounter") as BeanCounter
	_check("the HUD has a bean counter, away from the hint (top middle) and score (top right)",
		counter != null and counter.position.x < 100.0 and counter.position.y > 100.0)
	var before: int = level.beans_this_stage
	var jar_before: int = save.bean_jar
	await _feed(level, player, 3)
	_check("3 beans eaten: stage total +3 (%d -> %d)" % [before, level.beans_this_stage], level.beans_this_stage == before + 3)
	_check("they are in the pot (%d)" % level.beans_pot, level.beans_pot == level.beans_this_stage)
	_check("not banked yet (jar %d)" % save.bean_jar, save.bean_jar == jar_before)
	_check("the HUD counter shows the stage total ('%s')" % counter.label.text,
		counter.label.text == "BEANS %d" % level.beans_this_stage)
	_check("the number has a bean icon beside it", counter.get_child(0) is BeanIcon)
	var pot: int = level.beans_pot
	var toilet: Toilet = level.find_children("*", "Area3D", true, false).filter(func(n: Node) -> bool: return n is Toilet)[0] as Toilet
	player.global_position = toilet.global_position + Vector3(0, 0.5, 0)
	await _wait(0.3)
	_check("the toilet flushed", toilet.is_flushed)
	_check("the toilet banked the pot into the jar (%d)" % save.bean_jar, save.bean_jar == jar_before + pot and level.beans_pot == 0)
	_check("and saved it (%d in the file)" % _saved_jar(), _saved_jar() == save.bean_jar)
	_check("the stage total is not lowered by banking", level.beans_this_stage == before + 3)

	# ---------------------------------------------------------------- clearing the stage banks, and the pour
	jar_before = save.bean_jar
	await _feed(level, player, 2)
	var stage_total: int = level.beans_this_stage
	_check("2 more beans in the pot (%d)" % level.beans_pot, level.beans_pot == 2)
	var can: Node = level.get_tree().get_first_node_in_group(&"bean_cans")
	player.global_position = can.get_node("LidSensor").global_position
	player.velocity = Vector3.ZERO
	await _wait(0.3)
	_check("the stage is cleared", level.is_cleared)
	_check("clearing banked the pot (jar %d -> %d)" % [jar_before, save.bean_jar], save.bean_jar == jar_before + 2 and level.beans_pot == 0)
	_check("and saved it (%d in the file)" % _saved_jar(), _saved_jar() == save.bean_jar)
	var banner := level.get_node("HUD/StageClearBanner") as StageClearBanner
	_check("the banner has the cha-ching sound", banner.ching_sound != null)
	_check("the pour starts with the jar picture and +0", banner.jar_picture != null and banner.pour_label.text.begins_with("+"))
	_check("the jar total is hidden until the pour ends", not banner.pour_done and banner.jar_label.modulate.a < 0.5)
	await _wait(0.9)
	_check("mid-pour the count is part way ('%s', jar %.2f full)" % [banner.pour_label.text, banner.jar_picture.fill],
		not banner.pour_done and banner.jar_picture.fill > 0.0 and banner.jar_picture.fill < float(stage_total) / float(banner.jar_full_beans))
	await _wait(1.6)
	_check("the pour is over within about 2.5 s", banner.pour_done)
	_check("it shows +%d BEANS! ('%s')" % [stage_total, banner.pour_label.text], banner.pour_label.text == "+%d BEANS!" % stage_total)
	_check("the jar fills to match (%.2f)" % banner.jar_picture.fill,
		absf(banner.jar_picture.fill - minf(float(stage_total) / float(banner.jar_full_beans), 1.0)) < 0.001)
	_check("then BEAN JAR shows the new total ('%s')" % banner.jar_label.label.text,
		banner.jar_label.label.text == "BEAN JAR %s" % Stage.with_commas(save.bean_jar) and banner.jar_label.modulate.a > 0.9)
	_check("the cha-ching played", Sfx.played.has("cha_ching.wav"))
	_check("the stage has not left for the map yet (return delay %.1f s)" % level.return_delay, root.get_node_or_null("WorldMap") == null)
	level.queue_free()
	await _wait(0.3)

	# ---------------------------------------------------------------- quitting from the pause menu banks
	save.reset()
	level = await _load_stage("res://scenes/stage_1_1.tscn")
	player = level.get_node("Player") as Player
	await _feed(level, player, 4)
	var carried: int = level.beans_pot
	_check("carrying %d beans, none in the jar" % carried, carried >= 4 and save.bean_jar == 0)
	var menu: PauseMenu = null
	for child: Node in level.get_children():
		if child is PauseMenu:
			menu = child
	menu.open()
	menu.select(PauseMenu.BACK)
	menu._since_open = 1.0
	menu.choose()
	await _wait(0.3)
	_check("BACK TO MENU banked the pot (jar %d)" % save.bean_jar, save.bean_jar == carried)
	_check("and saved it", _saved_jar() == carried)
	paused = false
	for child: Node in root.get_children():
		if child != save and child.name != "DebugOptions" and not child is Window:
			child.queue_free()
	await _wait(0.3)

	# ---------------------------------------------------------------- losing all hearts banks, spills
	save.reset()
	world = Node3D.new()
	root.add_child(world)
	var floor_body := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(400, 1, 4)
	col.shape = shape
	floor_body.add_child(col)
	floor_body.position = Vector3(0, -0.5, 0)
	world.add_child(floor_body)
	p = (load("res://scenes/player.tscn") as PackedScene).instantiate() as Player
	p.position = Vector3(100, 1.0, 0)
	world.add_child(p)
	stage_node = Stage.new()
	stage_node.player = p
	root.add_child(stage_node)
	await _wait(0.5)

	stage_node.add_beans(10)
	_check("10 beans in the pot", stage_node.beans_pot == 10 and stage_node.beans_this_stage == 10)
	p.hearts.hearts = 1
	p.hurt(p.global_position.x + 1.0)
	await _wait(0.1)
	_check("losing the last heart banked the pot (jar %d)" % save.bean_jar, save.bean_jar == 10 and stage_node.beans_pot == 0)
	_check("and saved it", _saved_jar() == 10)
	_check("a death does not spill (nothing in the pot)", _beans_thrown(world).is_empty())
	await _wait(2.5)  # he gets up again at the checkpoint
	_reset_player()

	# A spill takes up to 6 from the pot, and no gas.
	var spill := p.get_node("BeanSpill") as BeanSpill
	_check("BeanSpill spills 6 at most by default", spill.spill_count == 6)
	_check("BeanSpill has no gas setting any more", spill.get("gas_per_bean") == null)
	save.reset()
	stage_node.beans_pot = 0
	stage_node.beans_this_stage = 0
	stage_node.add_beans(10)
	_reset_player()
	var gas: float = p.gas_tank.gas
	p.hurt(p.global_position.x + 1.0)
	await _wait(0.1)
	var spilled: Array[Node3D] = _beans_thrown(world)
	_check("hurt with 10 in the pot: 6 spilled (%d)" % spilled.size(), spilled.size() == 6)
	_check("they came out of the pot (%d) and the stage total (%d)" % [stage_node.beans_pot, stage_node.beans_this_stage],
		stage_node.beans_pot == 4 and stage_node.beans_this_stage == 4)
	_check("the jar is not touched by a spill (%d)" % save.bean_jar, save.bean_jar == 0)
	_check("no gas taken (%.0f -> %.0f)" % [gas, p.gas_tank.gas], p.gas_tank.gas >= gas)
	_check("they vanish after 5 s (%.1f)" % (spilled[0].get_node("LootBounce") as LootBounce).lifetime,
		(spilled[0].get_node("LootBounce") as LootBounce).lifetime == 5.0)
	for node: Node3D in spilled:
		node.free()
	_reset_player()
	p.hurt(p.global_position.x + 1.0)
	await _wait(0.1)
	spilled = _beans_thrown(world)
	_check("hurt with 4 in the pot: only 4 spilled (%d)" % spilled.size(), spilled.size() == 4 and stage_node.beans_pot == 0)
	for node: Node3D in spilled:
		node.free()
	_reset_player()
	p.hurt(p.global_position.x + 1.0)
	await _wait(0.1)
	_check("hurt with an empty pot: nothing spills (%d)" % _beans_thrown(world).size(), _beans_thrown(world).is_empty())
	_check("and the stage total is still 0 (%d)" % stage_node.beans_this_stage, stage_node.beans_this_stage == 0)

	# Grabbing a spilled bean puts it back in the pot.
	stage_node.add_beans(3)
	_reset_player()
	p.hurt(p.global_position.x + 1.0)
	await _wait(0.1)
	spilled = _beans_thrown(world)
	_check("3 spilled, pot empty (%d, pot %d)" % [spilled.size(), stage_node.beans_pot], spilled.size() == 3 and stage_node.beans_pot == 0)
	await _wait(1.0)
	p.global_position = spilled[0].global_position
	p.velocity = Vector3.ZERO
	await _wait(0.3)
	_check("grabbing one puts it back (pot %d, stage %d)" % [stage_node.beans_pot, stage_node.beans_this_stage],
		stage_node.beans_pot >= 1 and stage_node.beans_pot == stage_node.beans_this_stage and not is_instance_valid(spilled[0]))
	p.global_position = Vector3(150, 1.0, 0)
	await _wait(4.8)
	_check("the rest vanish after 5 s and are gone for good (pot %d)" % stage_node.beans_pot, stage_node.beans_pot <= 3 and not is_instance_valid(spilled[1]))

	# No spilling in flying stages (the bare stage must go first: spills look at the first stage).
	stage_node.free()
	world.free()
	await _wait(0.2)
	var flight: Stage = await _load_stage("res://scenes/stage_1_3.tscn")
	flight.add_beans(8)
	var fp := flight.get_node("Player") as Player
	fp.flashing_left = 0.0
	fp.hurt(fp.global_position.x + 1.0)
	await _wait(0.1)
	_check("a flying stage spills nothing and keeps the pot (%d)" % flight.beans_pot, flight.beans_pot == 8 and _beans_thrown(flight).is_empty())
	flight.free()
	await _wait(0.2)

	# ---------------------------------------------------------------- the map: BEAN JAR and the Complex2000
	save.reset()
	save.bank_beans(2345)
	var map := (load("res://scenes/world_map.tscn") as PackedScene).instantiate() as WorldMap
	root.add_child(map)
	await _wait(0.5)
	var jar_label := map.get_node("BeanJarLabel") as BeanJarLabel
	_check("the map shows 'BEAN JAR 2,345' ('%s')" % jar_label.label.text, jar_label.label.text == "BEAN JAR 2,345")
	_check("with a bean icon", jar_label.get_child(0) is BeanIcon)
	save.bank_beans(5)
	await _wait(0.2)
	_check("it follows the jar ('%s')" % jar_label.label.text, jar_label.label.text == "BEAN JAR 2,350")
	var name_front := map.ship.get_node_or_null("Rig/NameLabelFront") as Label3D
	var name_back := map.ship.get_node_or_null("Rig/NameLabelBack") as Label3D
	_check("the ship is the Complex2000 (name on both sides)",
		name_front != null and name_back != null and name_front.text == "COMPLEX2000" and name_back.text == "COMPLEX2000")
	_check("it has a cockpit dome with Fart Man, fins, legs and flames",
		map.ship.get_node_or_null("Rig/Dome") != null and map.ship.get_node_or_null("Rig/Pilot/GoggleL") != null
		and map.ship.get_node_or_null("Rig/FinTop") != null and map.ship.get_node_or_null("Rig/Leg_-16_-7") != null
		and map.ship.flames != null and map.ship.flames.get_child_count() >= 1)
	_check("the old bean blimp bits are gone", map.ship.get_node_or_null("Rig/Propeller") == null and map.ship.get_node_or_null("Rig/GondolaFloor") == null)
	_check("it still hovers over the current stop",
		map.ship.position.distance_to(map.stop_hover_position(map.index)) < 0.1 and map.ship.position.y > MapStops.STOPS[map.index]["pos"].y + 3.0)
	var flame := map.ship.flames.get_child(0) as ThrusterFlame
	await _wait(0.5)
	var hover_flame: float = flame.scale.x
	map.ship.fly_to(map.stop_hover_position(1), 1.0)
	await _wait(0.5)
	_check("flames are bigger while flying (%.2f -> %.2f)" % [hover_flame, flame.scale.x], flame.scale.x > hover_flame * 1.5)
	await _wait(1.2)
	_check("and the ship lands over the next stop", map.ship.position.distance_to(map.stop_hover_position(1)) < 0.1 and not map.ship.is_flying)
	_check("the map goes aboard the ship hub by default", map.ship_hub_scene == "res://scenes/ship_hub.tscn" and map.hub_hint.visible)
	map.ship_hub_scene = ""
	_check("board_ship does nothing with no hub", not map.board_ship())

	save.reset()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_FILE))
	print("bean jar failures: %d" % failures)
	quit()
