extends SceneTree
# Stage 2-3 (Up the Chimney): the stage is put together right, the flight works from the inside
# of the chimney (climbing, steering, walls, bursting out), then right across the roofs to the
# landing. Then each new flying gadget on its own: spark cable, smoke ring (and chains), rooftop
# fan, steam cloud, puffing chimney, speed-up tunnel, lane change, and the sky toilets.

var failures: int = 0
var world: Node3D
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


func _hearts() -> int:
	return (player.get_node("Hearts") as Hearts).hearts


## A fresh empty sky with Fart Man flying in it, hovering (no forward speed) so we can measure.
func _sky(at: Vector3, hover: bool = true) -> void:
	if world != null:
		world.free()
	world = Node3D.new()
	root.add_child(world)
	player = (load("res://scenes/player.tscn") as PackedScene).instantiate()
	player.position = at
	world.add_child(player)
	var camera := Camera3D.new()
	world.add_child(camera)
	camera.position = at + Vector3(0, 3, 16)
	SmokeRing.reset_chain()
	player.start_flying(0.0, 200.0)
	if hover:
		player.flight.forward_speed = 0.0


func _add(scene_name: String, pos: Vector3, props: Dictionary = {}) -> Node3D:
	var thing: Node3D = (load("res://scenes/%s.tscn" % scene_name) as PackedScene).instantiate()
	for key: String in props:
		thing.set(key, props[key])
	world.add_child(thing)
	thing.global_position = pos
	return thing


func _run() -> void:
	var save: Node = root.get_node_or_null("SaveGame")
	if save != null:
		save.use_file("user://test_chimney_save.json")
		save.reset()
	SmokeRing.reset_chain()

	# ------------------------------------------------------------------ the stage
	var stage: Stage = load("res://scenes/stage_2_3.tscn").instantiate()
	root.add_child(stage)
	await _wait(0.5)
	var p: Player = stage.player
	player = p
	var toilets: Array[Node] = stage.find_children("*", "Toilet", true, false)
	var cans: int = get_nodes_in_group(&"bean_cans").size()
	print("stage 2-3: golden=%d cans=%d toilets=%d stage_id=%s" % [stage.golden_total, cans, toilets.size(), stage.stage_id])
	_check("2-3 has 3 golden beans, 1 can, 4+ toilets", stage.golden_total == 3 and cans == 1 and toilets.size() >= 4)
	_check("2-3 has its stage id", stage.stage_id == "2-3")
	_check("2-3 starts flying, inside the chimney", p.is_flying() and p.position.x > 0.0 and p.position.x < 16.0)
	var sky_toilets: int = 0
	for t: Node in toilets:
		if (t as Toilet).flight_range != Vector2.ZERO:
			sky_toilets += 1
	_check("most toilets are sky toilets that keep him flying (%d)" % sky_toilets, sky_toilets >= 4)

	# ------------------------------------------------------------------ inside the chimney
	p.flashing_left = 1000.0
	await _wait(1.0)
	_check("in the chimney he does not zoom forward (x=%.1f)" % p.position.x, absf(p.position.x - 8.0) < 0.5)
	_check("let go and he sinks to the floor (y=%.1f)" % p.position.y, p.position.y < 2.0)
	Input.action_press(&"jump")
	await _wait(1.5)
	_check("hold jump and he climbs (y=%.1f)" % p.position.y, p.position.y > 10.0)
	Input.action_press(&"ui_right")
	await _wait(2.0)
	_check("arrow keys steer him sideways, up to the wall (x=%.1f)" % p.position.x, p.position.x > 12.0 and p.position.x < 16.0)
	Input.action_release(&"ui_right")
	Input.action_press(&"ui_left")
	await _wait(3.0)
	_check("and the other wall (x=%.1f)" % p.position.x, p.position.x > 0.0 and p.position.x < 4.0)
	Input.action_release(&"ui_left")
	_check("still in the chimney while steering (y=%.1f)" % p.position.y, p.position.y > 10.0)

	# Half way up there is a toilet. He remembers it and comes back flying inside the chimney.
	p.position = Vector3(8.0, 50.0, 0)
	p.velocity = Vector3.ZERO
	await _wait(0.4)
	_check("shaft toilet remembered (y=%.1f)" % p.checkpoint_position.y, p.checkpoint_flight != Vector2.ZERO and absf(p.checkpoint_position.y - 50.0) < 1.0)
	Input.action_release(&"jump")
	p.flashing_left = 0.0
	for i in 3:
		p.flashing_left = 0.0
		p.hurt(p.global_position.x + 1.0)
	await _wait(p.death_time + 0.4)
	_check("after losing all hearts he is back in the chimney, flying (x=%.1f, y=%.1f)" % [p.position.x, p.position.y],
		p.is_flying() and p.position.y > 30.0 and p.position.x < 16.0)

	# Bursting out of the top: forward flight again, and the lane over the roofs applies.
	p.flashing_left = 1000.0
	p.position = Vector3(8.0, 83.0, 0)
	p.velocity = Vector3.ZERO
	Input.action_press(&"jump")
	await _wait(0.8)
	var out_x: float = p.position.x
	await _wait(1.5)
	_check("he bursts out of the top and zooms forward (x %.1f -> %.1f)" % [out_x, p.position.x], p.position.x > 30.0)
	_check("the sky lane is now the one over the roofs (low %.0f, high %.0f)" % [p.flight.lowest_y, p.flight.highest_y],
		is_equal_approx(p.flight.lowest_y, 73.0) and is_equal_approx(p.flight.highest_y, 92.0))
	Input.action_release(&"jump")

	# ------------------------------------------------------------------ across the roofs, all the way
	# A very simple pilot keeps him at the middle of the lane (he can't be hurt in this run).
	p.position = Vector3(26.0, 82.0, 0)
	p.velocity = Vector3.ZERO
	p.flashing_left = 100000.0
	var score0: int = stage.score
	var frames: int = 0
	var fastest: float = 0.0
	var last_x: float = p.position.x
	var seen_toilets: int = 0
	while p.is_flying() and frames < 60 * 160:
		if p.position.y < 82.5:
			Input.action_press(&"jump")
		else:
			Input.action_release(&"jump")
		await physics_frame
		fastest = maxf(fastest, (p.position.x - last_x) * 60.0)
		last_x = p.position.x
		frames += 1
	Input.action_release(&"jump")
	await _wait(1.5)
	seen_toilets = 0
	for t: Node in toilets:
		if (t as Toilet).is_flushed:
			seen_toilets += 1
	print("roof flight took %.0f s of flying from x=26 (+ about 10 s in the chimney)" % (frames / 60.0))
	_check("he reaches the end and lands safely on the roof (x=%.0f, y=%.1f, flying %s, on floor %s)" % [p.position.x, p.position.y, str(p.is_flying()), str(p.is_on_floor())],
		not p.is_flying() and p.is_on_floor() and p.position.x > 1195.0 and absf(p.position.y - 67.0) < 1.0)
	_check("the speed-up tunnel made him faster (fastest %.0f m/s, normal 14)" % fastest, fastest > 20.0)
	_check("he collected beans and ring bonuses on the way (score +%d)" % (stage.score - score0), stage.score - score0 > 500)
	_check("he flushed the sky toilets as he passed (%d)" % seen_toilets, seen_toilets >= 6)
	stage.queue_free()
	await _wait(0.3)

	# ------------------------------------------------------------------ gadget: spark cable
	_sky(Vector3(10, 1.2, 0))
	player.stop_flying()
	var floor_body := StaticBody3D.new()
	floor_body.position = Vector3(0, -0.5, 0)
	var floor_col := CollisionShape3D.new()
	var floor_shape := BoxShape3D.new()
	floor_shape.size = Vector3(400, 1, 4)
	floor_col.shape = floor_shape
	floor_body.add_child(floor_col)
	world.add_child(floor_body)
	var cable := _add("spark_cable", Vector3(10, 1.0, 0), {"length": 8.0, "on_time": 1.5, "off_time": 1.5, "warn_time": 0.7}) as SparkCable
	var switches: Array[int] = [0]
	cable.switched.connect(func(_now_on: bool) -> void: switches[0] += 1)
	player.flashing_left = 0.0
	player.velocity = Vector3.ZERO
	# While it is off (the first 1.5 s) he can stand in it.
	await _wait(0.5)
	_check("cable is off at first (is_on %s)" % str(cable.is_on), not cable.is_on)
	var hearts_cable: int = _hearts()
	await _wait(0.5)
	_check("standing in an OFF cable is safe (hearts %d)" % _hearts(), _hearts() == hearts_cable)
	_check("it flickers before it switches on (warning %s)" % str(cable.is_warning()), cable.is_warning())
	await _wait(0.8)
	_check("then it switches on (is_on %s)" % str(cable.is_on), cable.is_on)
	_check("an ON cable zaps him (hearts %d -> %d)" % [hearts_cable, _hearts()], _hearts() == hearts_cable - 1)
	await _wait(3.5)
	_check("it keeps switching (%d times)" % switches[0], switches[0] >= 3)

	# ------------------------------------------------------------------ gadget: smoke rings and chains
	_sky(Vector3(0, 10, 0), false)
	var passes: Array[int] = []
	var ring1 := _add("smoke_ring", Vector3(10, 10, 0)) as SmokeRing
	var ring2 := _add("smoke_ring", Vector3(40, 10, 0)) as SmokeRing
	var ring3 := _add("smoke_ring", Vector3(70, 10, 0), {"flat": false}) as SmokeRing
	for r: SmokeRing in [ring1, ring2, ring3]:
		r.passed.connect(func(chain: int) -> void: passes.append(chain))
	var beans_born: Array[int] = [0]
	world.child_entered_tree.connect(func(node: Node) -> void:
		if node.scene_file_path == "res://scenes/bean.tscn":
			beans_born[0] += 1)
	player.flashing_left = 1000.0
	for i in 400:
		# Keep him level at y=10.
		if player.position.y < 10.0:
			Input.action_press(&"jump")
		else:
			Input.action_release(&"jump")
		await physics_frame
	Input.action_release(&"jump")
	_check("flying through rings in a row builds a chain %s" % str(passes), passes.size() >= 3 and passes[0] == 1 and passes[1] == 2 and passes[2] == 3)
	_check("each ring pops out 3 bonus beans (%d in all)" % beans_born[0], beans_born[0] == 9)
	SmokeRing.reset_chain()
	_check("the chain can be reset (count %d)" % SmokeRing._chain_count, SmokeRing._chain_count == 0)

	# ------------------------------------------------------------------ gadget: rooftop fan
	_sky(Vector3(10, 20, 0))
	var fan_off := _add("roof_fan", Vector3(10, 0, 0), {"phase": 0.0, "column_height": 40.0}) as RoofFan
	await _wait(0.6)
	var y_off: float = player.position.y
	_check("fan is resting at first (is_on %s)" % str(fan_off.is_on), not fan_off.is_on)
	_check("without wind he sinks (y 20 -> %.1f)" % y_off, y_off < 17.0)
	_sky(Vector3(10, 20, 0))
	var fan_on := _add("roof_fan", Vector3(10, 0, 0), {"phase": 0.55, "column_height": 40.0}) as RoofFan
	await _wait(0.6)
	_check("fan is blowing (is_on %s)" % str(fan_on.is_on), fan_on.is_on)
	_check("in the wind he is shoved up (y 20 -> %.1f)" % player.position.y, player.position.y > 21.0)

	# ------------------------------------------------------------------ gadget: steam cloud
	_sky(Vector3(10, 20, 0))
	var cloud := _add("steam_cloud", Vector3(10, 20, 0), {"size": Vector2(10, 8)}) as SteamCloud
	var entered: Array[bool] = [false]
	cloud.entered.connect(func() -> void: entered[0] = true)
	await _wait(0.4)
	_check("steam cloud notices him inside (inside %s, entered %s)" % [str(cloud.player_inside), str(entered[0])], cloud.player_inside and entered[0])
	var hearts_steam: int = _hearts()
	await _wait(0.4)
	_check("the cloud is harmless (hearts %d)" % _hearts(), _hearts() == hearts_steam)

	# ------------------------------------------------------------------ gadget: puffing chimney
	_sky(Vector3(10, 20, 0))
	var stack := _add("chimney_stack", Vector3(10, 0, 0), {"height": 10.0, "phase": 0.0, "puff_every": 3.0, "puff_time": 1.6}) as ChimneyStack
	player.position = Vector3(10, 16.0, 0)
	var puffs: Array[int] = [0]
	stack.puffed.connect(func() -> void: puffs[0] += 1)
	await _wait(0.5)
	_check("smoke puffs from the top (is_puffing %s)" % str(stack.is_puffing), stack.is_puffing)
	_check("smoke gives lift: he sinks slowly in it (y 16 -> %.1f)" % player.position.y, player.position.y > 13.9)
	_sky(Vector3(10, 20, 0))
	_add("chimney_stack", Vector3(10, 0, 0), {"height": 10.0, "phase": 0.6})
	player.position = Vector3(10, 16.0, 0)
	await _wait(0.5)
	_check("without smoke he sinks fast (y 16 -> %.1f)" % player.position.y, player.position.y < 13.2)
	_sky(Vector3(10, 8, 0))
	_add("chimney_stack", Vector3(10, 0, 0), {"height": 10.0})
	var hearts_stack: int = _hearts()
	await _wait(0.5)
	_check("the chimney itself costs a heart (%d -> %d)" % [hearts_stack, _hearts()], _hearts() == hearts_stack - 1)
	_sky(Vector3(10, 8, 0))
	_add("chimney_stack", Vector3(10, 14, 0), {"height": 10.0, "hanging": true})
	player.position = Vector3(10, 10.0, 0)
	var hearts_pipe: int = _hearts()
	await _wait(0.4)
	_check("a hanging pipe costs a heart too (%d -> %d)" % [hearts_pipe, _hearts()], _hearts() == hearts_pipe - 1)

	# ------------------------------------------------------------------ gadget: speed tunnel, lane change
	_sky(Vector3(0, 20, 0), false)
	var tunnel := Area3D.new()
	tunnel.set_script(load("res://scripts/chimney_speed.gd"))
	tunnel.set("length", 100.0)
	tunnel.set("height", 20.0)
	tunnel.set("speed_up", 1.5)
	world.add_child(tunnel)
	tunnel.global_position = Vector3(70, 20, 0)
	player.position = Vector3(30, 20, 0)
	await _wait(0.5)
	var xa: float = player.position.x
	await _wait(0.5)
	var speed_in: float = (player.position.x - xa) / 0.5
	_check("flying speed in the tunnel is 1.5 x 14 = 21 (measured %.1f)" % speed_in, absf(speed_in - 21.0) < 1.0)
	player.position = Vector3(130, 20, 0)
	await _wait(0.2)
	var xb: float = player.position.x
	await _wait(0.5)
	var speed_out: float = (player.position.x - xb) / 0.5
	_check("and back to normal speed outside it (measured %.1f)" % speed_out, absf(speed_out - 14.0) < 1.0)

	_sky(Vector3(0, 20, 0), false)
	var lane := Area3D.new()
	lane.set_script(load("res://scripts/chimney_lane.gd"))
	lane.set("lane_low", 15.0)
	lane.set("lane_high", 30.0)
	var lane_shape := CollisionShape3D.new()
	var lane_box := BoxShape3D.new()
	lane_box.size = Vector3(2, 100, 4)
	lane_shape.shape = lane_box
	lane.add_child(lane_shape)
	world.add_child(lane)
	lane.global_position = Vector3(20, 20, 0)
	await _wait(1.5)
	_check("a lane zone changes the sky he can fly in (low %.0f, high %.0f)" % [player.flight.lowest_y, player.flight.highest_y],
		is_equal_approx(player.flight.lowest_y, 15.0) and is_equal_approx(player.flight.highest_y, 30.0))

	# ------------------------------------------------------------------ normal flight is unchanged
	_sky(Vector3(0, 10, 0), false)
	var xn: float = player.position.x
	await _wait(1.0)
	_check("normal flight outside a shaft still zooms forward at 14 m/s (%.1f)" % (player.position.x - xn), absf((player.position.x - xn) - 14.0) < 1.0)

	if save != null:
		save.reset()
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://test_chimney_save.json"))
	print("chimney failures: %d" % failures)
	quit()
