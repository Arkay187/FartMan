extends SceneTree
# SUPER BOOST: flying into one makes the scroll 3-4 times faster, eased in and out (no jolt),
# and nothing is skipped at that speed (beans, a Golden Bean, a hoop, a toilet, the landing).
# Then both flying stages are flown start to finish by a simple pilot: each has 3+ boosts,
# 3 Golden Beans, ends at its landing, and takes about the target time. The camera stretches
# its view in a boost. It can't see or hear anything: only numbers.

var failures: int = 0
var world: Node3D
var player: Player


func _initialize() -> void:
	_run()


func _wait(seconds: float) -> void:
	for i in int(seconds * 60.0):
		await physics_frame


func _check(label: String, ok: bool) -> void:
	print("%s: %s" % [label, "ok" if ok else "FAILED"])
	if not ok:
		failures += 1


## A bare sky with Fart Man flying level at height 20, from x = 150, and a boost from 200 to 400
## (flat out from 225 to 375) at "multiplier" times normal speed.
func _sky(multiplier: float) -> SuperBoost:
	if world != null:
		world.free()
	world = Node3D.new()
	root.add_child(world)
	player = (load("res://scenes/player.tscn") as PackedScene).instantiate()
	player.position = Vector3(150, 20, 0)
	world.add_child(player)
	var camera := Camera3D.new()
	world.add_child(camera)
	camera.position = Vector3(150, 23, 16)
	player.start_flying(0.0, 100.0)
	player.flashing_left = 100000.0
	var boost := SuperBoost.new()
	boost.length = 200.0
	boost.height = 40.0
	boost.speed_multiplier = multiplier
	world.add_child(boost)
	boost.global_position = Vector3(300, 20, 0)
	return boost


func _thing(scene_name: String, pos: Vector3) -> Node3D:
	var thing: Node3D = (load("res://scenes/%s.tscn" % scene_name) as PackedScene).instantiate()
	world.add_child(thing)
	thing.global_position = pos
	return thing


## One physics frame with the pilot keeping him level at height 20.
func _level_frame() -> void:
	player.position.y = 20.0
	player.velocity.y = 0.0
	await physics_frame


func _run() -> void:
	await physics_frame
	var options: DebugOptionsData = root.get_node("DebugOptions")
	options.set_simple_controls(false)
	var save: Node = root.get_node_or_null("SaveGame")
	if save != null:
		save.use_file("user://test_super_boost_save.json")
		save.reset()
	SmokeRing.reset_chain()

	# ------------------------------------------------------------------ speed, easing, 4x
	_sky(4.0)
	var beans: Array[Node3D] = []
	for x in range(226, 372, 4):
		beans.append(_thing("bean", Vector3(x, 20, 0)))
	var golden: Node3D = _thing("golden_bean", Vector3(300, 20, 0))
	var hoop: Node3D = _thing("hoop", Vector3(330, 20, 0))
	var toilet: Node3D = _thing("toilet", Vector3(350, 20, 0))
	var before: float = 0.0
	var fastest: float = 0.0
	var biggest_jump: float = 0.0
	var last_v: float = 14.0
	var frames_in: int = 0
	for i in 6:
		await _level_frame()  # let him get up to speed first
	var after_v: float = 0.0
	while player.position.x < 430.0 and frames_in < 60 * 20:
		await _level_frame()
		var v: float = player.velocity.x
		if player.position.x < 190.0:
			before = v
		fastest = maxf(fastest, v)
		biggest_jump = maxf(biggest_jump, absf(v - last_v))
		last_v = v
		after_v = v
		frames_in += 1
	var eaten: int = 0
	for b in beans:
		if not is_instance_valid(b):
			eaten += 1
	print("4x boost: before %.1f m/s, fastest %.1f, biggest change in one frame %.2f, after %.1f; beans %d/%d, golden gone %s, hoop %s, toilet %s" % [
		before, fastest, biggest_jump, after_v, eaten, beans.size(), str(not is_instance_valid(golden)), str(hoop.get("is_done")), str(toilet.get("is_flushed"))])
	_check("normal speed before the boost (%.1f)" % before, absf(before - 14.0) < 0.5)
	_check("the boost makes him 4 times faster (%.1f vs %.1f)" % [fastest, 4.0 * 14.0], absf(fastest - 56.0) < 1.5)
	_check("it eases in and out: no frame changes his speed by more than 2 m/s (%.2f)" % biggest_jump, biggest_jump < 2.0)
	_check("and he is back to normal speed after it (%.1f)" % after_v, absf(after_v - 14.0) < 0.5)
	_check("no beans skipped at 4x speed (%d of %d)" % [eaten, beans.size()], eaten == beans.size())
	_check("Golden Bean in the boost is still picked up", not is_instance_valid(golden))
	_check("hoop in the boost still counts", hoop.get("is_done") == true)
	_check("toilet in the boost still flushes", toilet.get("is_flushed") == true)

	# The same at 3x (the stages use 3.5x), and the landing curtain ends the flight at speed.
	var boost: SuperBoost = _sky(3.0)
	var landing: Node3D = _thing("landing_zone", Vector3(372, 0, 0))
	var big_golden: Node3D = _thing("golden_bean", Vector3(340, 20, 0))
	var frames: int = 0
	while player.is_flying() and frames < 60 * 10:
		await _level_frame()
		frames += 1
	_check("3x: scale in the middle is 3.0 (%.2f), at the very start 1.0 (%.2f)" % [boost.scale_at(300.0), boost.scale_at(200.0)],
		is_equal_approx(boost.scale_at(300.0), 3.0) and is_equal_approx(boost.scale_at(200.0), 1.0))
	_check("flying at speed into the landing curtain still lands him (x=%.0f, flying %s)" % [player.position.x, str(player.is_flying())],
		not player.is_flying() and player.position.x > 365.0 and player.position.x < 385.0)
	_check("Golden Bean right before the landing was picked up", not is_instance_valid(big_golden))
	landing.queue_free()

	# ------------------------------------------------------------------ whole stages
	await _fly_stage("1-3", 3, 33.0, 50.0, 9.5)
	await _fly_stage("2-3", 3, 40.0, 70.0, 82.5)

	if save != null:
		save.reset()
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://test_super_boost_save.json"))
	print("test_super_boost failures: %d" % failures)
	quit()


## Flies a whole flying stage with a simple pilot (keeps level at "mid"; in the chimney he
## climbs out of the top first) and checks what happened.
func _fly_stage(id: String, want_boosts: int, min_s: float, max_s: float, mid: float) -> void:
	if world != null:
		world.free()
		world = null
	var stage: Stage = load("res://scenes/stage_%s.tscn" % id.replace("-", "_")).instantiate()
	root.add_child(stage)
	await _wait(0.5)
	var p: Player = stage.player
	player = p
	p.flashing_left = 100000.0
	var camera: Camera3D = stage.find_child("Camera3D", true, false)
	var boosts: Array[Node] = stage.find_children("*", "SuperBoost", true, false)
	var landing: Node3D = stage.find_child("LandingZone", true, false)
	var last_end: float = 0.0
	var boost_beans: Array[Node] = []
	var rows: Array[Vector2] = []
	for b: Node in boosts:
		var zone := b as SuperBoost
		rows.append(Vector2(zone.global_position.x - zone.length * 0.5, zone.global_position.x + zone.length * 0.5))
		last_end = maxf(last_end, zone.global_position.x + zone.length * 0.5)
		_check("%s boost speed is 3-4x (%.1f)" % [id, zone.speed_multiplier], zone.speed_multiplier >= 3.0 and zone.speed_multiplier <= 4.0)
	for bean: Node in stage.find_child("Beans", true, false).get_children():
		var x: float = (bean as Node3D).global_position.x
		for r in rows:
			if x > r.x and x < r.y:
				boost_beans.append(bean)
				break
	print("%s: %d boosts at %s, %d beans inside them, landing at x=%.0f, golden beans %d" % [id, boosts.size(), str(rows), boost_beans.size(), landing.global_position.x, stage.golden_total])
	_check("%s has at least %d SUPER BOOSTs (%d)" % [id, want_boosts, boosts.size()], boosts.size() >= want_boosts)
	_check("%s has 3 Golden Beans" % id, stage.golden_total == 3)
	_check("%s ends at its landing, well after the last boost (%.0f after %.0f)" % [id, landing.global_position.x, last_end], landing.global_position.x >= last_end + 25.0)

	var frames: int = 0
	var widest: float = 0.0
	var fastest: float = 0.0
	var last_x: float = p.position.x
	while p.is_flying() and frames < 60 * 150:
		var target: float = mid
		if id == "2-3" and p.position.x < 20.0:
			target = 90.0  # climb out of the top of the chimney first
		if p.position.y < target:
			Input.action_press(&"jump")
		else:
			Input.action_release(&"jump")
		await physics_frame
		fastest = maxf(fastest, (p.position.x - last_x) * 60.0)
		last_x = p.position.x
		widest = maxf(widest, camera.fov)
		frames += 1
	Input.action_release(&"jump")
	await _wait(1.0)
	var seconds: float = frames / 60.0
	var eaten: int = 0
	for bean in boost_beans:
		if not is_instance_valid(bean):
			eaten += 1
	var toilets: int = 0
	for t: Node in stage.find_children("*", "Toilet", true, false):
		if (t as Toilet).is_flushed:
			toilets += 1
	print("%s: flew for %.0f s, fastest %.0f m/s, widest view %.0f deg, beans in boosts %d/%d, toilets flushed %d, ended x=%.0f" % [
		id, seconds, fastest, widest, eaten, boost_beans.size(), toilets, p.position.x])
	_check("%s flying time %.0f s is between %.0f and %.0f" % [id, seconds, min_s, max_s], seconds >= min_s and seconds <= max_s)
	_check("%s he landed at the end (x=%.0f, flying %s)" % [id, p.position.x, str(p.is_flying())], not p.is_flying() and p.position.x > landing.global_position.x - 2.0)
	_check("%s the boosts really sped him up (%.0f m/s)" % [id, fastest], fastest > 14.0 * 3.2)
	_check("%s the camera stretched its view in a boost (%.0f deg)" % [id, widest], widest > 75.0 + 12.0)
	_check("%s a pilot who just holds level gets plenty of boost beans (%d of %d)" % [id, eaten, boost_beans.size()], eaten >= boost_beans.size() / 10)
	_check("%s sky toilets were flushed on the way (%d)" % [id, toilets], toilets >= 3)
	stage.queue_free()
	await _wait(0.3)
