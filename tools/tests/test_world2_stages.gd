extends SceneTree
# Checks the two World 2 running stages (2-1 and 2-2): no impossible steps on the main path,
# every gadget is in the stage, the steam vents really land him on the next ledge, and the
# warp pipe takes him to the secret bean room and back.


## A level kit that does everything the real one does but does not save the scene file.
class NoSaveKit extends "res://tools/kit_factory.gd":
	func finish(_path: String) -> Array[String]:
		var problems: Array[String] = check_route()
		root.free()
		return problems


var failures: int = 0


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


## How many nodes in the stage use a given script (for things with no class name).
func _count_script(stage: Node, script_path: String) -> int:
	var found: int = 0
	for node: Node in stage.find_children("*", "Area3D", true, false):
		var script: Script = node.get_script()
		if script != null and script.resource_path == script_path:
			found += 1
	return found


## Stands him on a vent that is about to puff, holds right, and says whether he lands on
## the target ledge (x range and top height) within a few seconds.
func _vent_hop(stage: Stage, vent_x: float, vent_top: float, x0: float, x1: float, top: float) -> bool:
	var player: Player = stage.player
	player.flashing_left = 1000.0
	player.position = Vector3(vent_x, vent_top + 1.0, 0)
	player.velocity = Vector3.ZERO
	for v: Node in stage.find_children("*", "SteamVent", true, false):
		if absf((v as Node3D).position.x - vent_x) < 0.1:
			(v as SteamVent)._age = (v as SteamVent).off_time - 0.02
	Input.action_press(&"ui_right")
	var landed: bool = false
	for i in 240:
		await physics_frame
		if player.is_on_floor() and player.position.x >= x0 and player.position.x <= x1 and absf(player.position.y - (top + 1.0)) < 0.3:
			landed = true
			break
	Input.action_release(&"ui_right")
	return landed


func _run() -> void:
	var save: Node = root.get_node_or_null("SaveGame")
	if save != null:
		save.use_file("user://test_world2_stages_save.json")
		save.reset()

	# --- The main path has no impossible gaps or steps. ---
	for id in ["2-1", "2-2"]:
		var script: GDScript = load("res://tools/stages/stage_%s.gd" % id.replace("-", "_"))
		var problems: Array[String] = script.new().build(NoSaveKit.new())
		_check("stage %s has no route problems %s" % [id, str(problems)], problems.is_empty())

	# --- Stage 2-1: THE CONVEYOR BELTS. ---
	var s1: Stage = load("res://scenes/stage_2_1.tscn").instantiate()
	root.add_child(s1)
	await _wait(0.3)
	var belts: Array[Node] = s1.find_children("*", "Conveyor", true, false)
	var forward: int = 0
	var backward: int = 0
	for b: Node in belts:
		if (b as Conveyor).speed > 0.0:
			forward += 1
		else:
			backward += 1
	print("2-1: belts %d (%d forward, %d backward), presses %d, biscuits %d, cork bots %d" % [
		belts.size(), forward, backward, _count(s1, "StampPress"), _count(s1, "CrumblePlatform"), _count(s1, "CorkBot")])
	_check("2-1 has belts both ways, 4 presses, 7+ biscuits, 4+ cork bots, 2 mega cans",
		forward >= 2 and backward >= 2 and _count(s1, "StampPress") >= 4 and _count(s1, "CrumblePlatform") >= 7
		and _count(s1, "CorkBot") >= 4 and _count_script(s1, "res://scripts/mega_bean_can.gd") >= 2)
	# Standing on the long backwards belt carries him back.
	var p1: Player = s1.player
	p1.flashing_left = 1000.0
	p1.position = Vector3(290, 6.0, 0)
	p1.velocity = Vector3.ZERO
	await _wait(1.5)
	_check("2-1 long backwards belt pushes him back (x=%.1f from 290)" % p1.position.x, p1.position.x < 287.0 and p1.is_on_floor())
	s1.queue_free()
	await _wait(0.2)

	# --- Stage 2-2: THE PIPE MAZE. ---
	var s2: Stage = load("res://scenes/stage_2_2.tscn").instantiate()
	root.add_child(s2)
	await _wait(0.3)
	var fans: Array[Node] = s2.find_children("*", "Fan", true, false)
	var tail: int = 0
	var head: int = 0
	for f: Node in fans:
		if (f as Fan).direction > 0.0:
			tail += 1
		else:
			head += 1
	print("2-2: vents %d, fizz bats %d, fans %d (%d tail, %d head), switch blocks %d, buttons %d, pipes %d" % [
		_count(s2, "SteamVent"), _count(s2, "FizzBat"), fans.size(), tail, head, _count(s2, "SwitchBlock"), _count(s2, "SwitchButton"), _count(s2, "WarpPipe")])
	_check("2-2 has 6+ vents, 5+ fizz bats, a tail and a head wind fan, 4 switch blocks and a button, 2 pipes",
		_count(s2, "SteamVent") >= 6 and _count(s2, "FizzBat") >= 5 and tail >= 1 and head >= 1
		and _count(s2, "SwitchBlock") >= 4 and _count(s2, "SwitchButton") == 1 and _count(s2, "WarpPipe") == 2)
	# Steam vents land him on the next ledge when he just holds right.
	var wall_hop: bool = await _vent_hop(s2, 13.0, 0.0, 20.0, 30.0, 5.0)
	_check("2-2 first vent puts him over the wall onto the plateau", wall_hop)
	var tower_one: bool = await _vent_hop(s2, 270.0, 5.0, 276.0, 284.0, 11.0)
	_check("2-2 tower vent 1 lands him on the first ledge", tower_one)
	var tower_two: bool = await _vent_hop(s2, 283.5, 11.0, 288.0, 296.0, 17.0)
	_check("2-2 tower vent 2 lands him on the second ledge", tower_two)
	var tower_three: bool = await _vent_hop(s2, 294.5, 17.0, 300.0, 330.0, 23.0)
	_check("2-2 tower vent 3 lands him on the top floor", tower_three)
	var gold_vent: bool = await _vent_hop(s2, 40.0, 5.0, 45.0, 50.0, 12.5)
	_check("2-2 golden bean vent lands him on the high ledge", gold_vent)

	# The secret pipe: vent up to the ledge, walk into the pipe, collect the bean, walk home.
	var player: Player = s2.player
	var on_ledge: bool = await _vent_hop(s2, 238.0, 5.0, 241.5, 250.5, 10.0)
	_check("2-2 secret ledge vent lands him on the ledge", on_ledge)
	Input.action_press(&"ui_right")
	var reached_room: bool = false
	var home: bool = false
	for i in 900:
		await physics_frame
		if player.position.y > 38.0:
			reached_room = true
		if reached_room and player.position.y < 20.0:
			home = true
			break
	Input.action_release(&"ui_right")
	_check("2-2 the warp pipe took him to the secret room (y>38: %s)" % str(reached_room), reached_room)
	_check("2-2 the room's pipe sent him home (x=%.0f y=%.1f), golden beans found %d" % [player.position.x, player.position.y, s2.golden_found],
		home and player.position.x > 255.0 and s2.golden_found >= 1)
	s2.queue_free()
	await _wait(0.2)

	if save != null:
		save.reset()
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://test_world2_stages_save.json"))
	print("world 2 stages failures: %d" % failures)
	quit()
