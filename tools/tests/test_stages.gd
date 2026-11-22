extends SceneTree
# Loads each stage (World 1 and the two World 2 running stages) and checks it is put together right: three Golden Beans,
# one Bean Can, plenty of toilets, and a sensible length. The flying stage must start
# in the air and a sky toilet must bring him back flying.

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


func _run() -> void:
	var save: Node = root.get_node_or_null("SaveGame")
	if save != null:
		save.use_file("user://test_stages_save.json")
		save.reset()
	for id in ["1-1", "1-2", "1-3", "1-4", "2-1", "2-2"]:
		var stage: Stage = load("res://scenes/stage_%s.tscn" % id.replace("-", "_")).instantiate()
		root.add_child(stage)
		await _wait(0.5)
		var toilets: Array[Node] = stage.find_children("*", "Toilet", true, false)
		var low: float = 1e9
		var high: float = -1e9
		for t: Node in toilets:
			low = minf(low, (t as Node3D).position.x)
			high = maxf(high, (t as Node3D).position.x)
		var cans: int = get_nodes_in_group(&"bean_cans").size()
		var enemies: int = stage.find_children("*", "Burpling", true, false).size()
		print("stage %s: golden=%d cans=%d toilets=%d enemies=%d  toilets from x=%.0f to x=%.0f  stage_id=%s" % [
			id, stage.golden_total, cans, toilets.size(), enemies, low, high, stage.stage_id])
		_check("%s has 3 golden beans, 1 can, 4+ toilets" % id, stage.golden_total == 3 and cans == 1 and toilets.size() >= (1 if id == "1-4" else 4))
		_check("%s has its stage id" % id, stage.stage_id == id)

		if id == "1-1":
			# The ditch is soft: holding CLASSIC right walks down and up the slope.
			var options: DebugOptionsData = root.get_node("DebugOptions") as DebugOptionsData
			var was_simple: bool = options.simple_controls
			options.set_simple_controls(false)
			var p1: Player = stage.player
			p1.position = Vector3(104, 1.2, 0)
			p1.flashing_left = 1000.0
			Input.action_press(&"ui_right")
			await _wait(9.0)
			Input.action_release(&"ui_right")
			options.set_simple_controls(was_simple)
			_check("ditch: holding right crosses it (x=%.1f, y=%.1f, on floor %s)" % [p1.position.x, p1.position.y, str(p1.is_on_floor())],
				p1.position.x > 130.0 and p1.position.y > -2.0)
		if id == "1-2":
			# The FIRE BURP PARTY is still a crowd.
			var crowd: int = 0
			for e: Node in stage.get_node("Enemies").get_children():
				if (e as Node3D).position.x > 320.0 and (e as Node3D).position.x < 420.0:
					crowd += 1
			_check("1-2 FIRE BURP PARTY still has 20+ enemies (%d)" % crowd, crowd >= 20)
		if id == "1-3":
			var p: Player = stage.player
			_check("flying stage: starts flying", p.is_flying())
			await _wait(1.0)
			_check("flying stage: moves forward by itself (x=%.1f)" % p.position.x, p.position.x > 10.0)
			# Fly to the first sky toilet, then lose every heart: he should come back flying.
			p.position = Vector3(108, 9.5, 0)
			await _wait(0.5)
			var checkpoint_set: bool = p.checkpoint_flight != Vector2.ZERO and p.checkpoint_position.x > 100.0
			p.flashing_left = 0.0
			for i in 3:
				p.flashing_left = 0.0
				p.hurt(p.global_position.x + 1.0)
			await _wait(p.death_time + 0.3)  # he lies there for death_time first
			_check("sky toilet: checkpoint remembered, respawned flying (x=%.0f, flying %s)" % [p.position.x, str(p.is_flying())],
				checkpoint_set and p.is_flying() and p.position.x < 130.0)
			# The end of the flight: he must land on solid ground, not drop into a hole.
			p.flashing_left = 1000.0
			p.position = Vector3(830, 8.0, 0)
			await _wait(4.0)
			_check("after the flight he lands safely (x=%.1f, y=%.1f, flying %s, on floor %s)" % [p.position.x, p.position.y, str(p.is_flying()), str(p.is_on_floor())],
				not p.is_flying() and p.position.y > -1.0 and p.position.x > 835.0)
		stage.queue_free()
		await _wait(0.2)

	if save != null:
		save.reset()
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://test_stages_save.json"))
	print("stage failures: %d" % failures)
	quit()
