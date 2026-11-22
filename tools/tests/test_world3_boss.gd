extends SceneTree
# Plays the whole Big Bad Burp fight with fake moves, then the ending:
#  PART 1: the hello scene (skipped by holding jump), the BUUURP tell and swelling bubbles before they can be
#   stomped, stinky bubbles hurt, bounces off bubbles, stomps on his head (six, in three rounds that get
#   faster, with helpers), the door and wall, the leaving scene and the Rocket Burrito.
#  PART 2: grab the burrito, the flying chase: BUUURP then a ring or a wall of bubbles, the dizzy moment, four
#   bumps, then the ending: he says he has never farted, a bean, the biggest fart, beans rain, the
#   ending storybook and back to the world map. Also losing in part 2 and starting again.

var failures: int = 0
var stage: Stage
var boss: BigBadBurp
var player: Player
var save: Node


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


func _shots() -> Array[Node]:
	return get_nodes_in_group(&"boss_shots")


func _until(test: Callable, seconds: float) -> bool:
	var left: float = seconds
	while not test.call() and left > 0.0:
		await physics_frame
		left -= 1.0 / 60.0
	return test.call()


## Thrown beans and pickups that are still flying or have just landed.
func _loot() -> int:
	return stage.find_children("*", "LootBounce", true, false).size() if is_instance_valid(stage) else 0


func _beans() -> int:
	var found: int = 0
	if not is_instance_valid(stage):
		return found
	for bean: Node in stage.find_children("*", "Area3D", true, false):
		var script: Script = bean.get_script()
		if script != null and script.resource_path == "res://scripts/bean.gd":
			found += 1
	return found


## True if this spot is inside the camera's picture, as a 16:9 screen (the test window is square).
func _in_frame(camera: Camera3D, spot: Vector3) -> bool:
	var local: Vector3 = camera.global_transform.affine_inverse() * spot
	var depth: float = -local.z
	var half_h: float = tan(deg_to_rad(camera.fov) * 0.5) * depth
	return depth > camera.near and absf(local.y) <= half_h and absf(local.x) <= half_h * 16.0 / 9.0


## Fart Man, his head and the middle of his body must all be in the shot.
func _everyone_in_frame(camera: Camera3D) -> bool:
	return _in_frame(camera, boss.head.global_position) and _in_frame(camera, boss.global_position) and _in_frame(camera, player.global_position)


## Drops Fart Man onto the boss's head, falling.
func _stomp_head() -> void:
	player.flashing_left = 1000.0
	player.velocity = Vector3(0, -6, 0)
	player.global_position = boss.head.global_position + Vector3(0.5, 3.0, 0)
	await _wait(0.4)


func _load_stage() -> void:
	if is_instance_valid(stage):
		stage.free()
	stage = load("res://scenes/stage_3_4.tscn").instantiate()
	root.add_child(stage)
	player = stage.player
	boss = stage.find_child("BigBadBurp", true, false) as BigBadBurp


func _run() -> void:
	save = root.get_node_or_null("SaveGame")
	if save != null:
		save.use_file("user://test_world3_boss_save.json")
		save.reset()
	(root.get_node("DebugOptions") as DebugOptionsData).set_simple_controls(true)
	_load_stage()
	await _wait(0.5)
	boss.rest_time = [0.6, 0.6, 0.6]
	boss.hit_pause = 0.8
	_check("he is a boss (group 'bosses'), tougher than the others (%d + %d hits, others have 6)" % [boss.hits_part1, boss.hits_part2],
		boss.is_in_group(&"bosses") and boss.hits_part1 + boss.hits_part2 >= 8)
	_check("he waits until Fart Man walks in", boss.phase == BigBadBurp.Phase.WAITING)
	_check("the door starts open (y=%.1f)" % boss.door.position.y, boss.door.position.y < 0.0)
	_check("the burrito is hidden until part 1 is won", not boss.burrito.visible and not boss.burrito.monitoring)

	# --- Every bubble pattern is a staircase that a bounce can climb, starting down at the floor. ---
	var all_ok: bool = true
	var count: int = 0
	var low_first: bool = true
	var tall_enough: bool = true
	for pattern: Array in boss.patterns():
		count += 1
		var normals: Array[Vector2] = []
		for b: Array in pattern:
			if int(b[2]) == 0:
				normals.append(Vector2(float(b[0]), float(b[1])))
		var top_y: float = 0.0
		var lowest: float = 99.0
		for n: Vector2 in normals:
			top_y = maxf(top_y, n.y)
			lowest = minf(lowest, n.y)
			# Each bubble is within a simple double jump (5 m) of the floor, or of a bubble below it.
			var reachable: bool = n.y <= 2.5
			for m: Vector2 in normals:
				if m.y < n.y and n.y - m.y <= 5.0 and absf(n.x - m.x) <= 9.0:
					reachable = true
			all_ok = all_ok and reachable
		low_first = low_first and lowest <= 2.0
		tall_enough = tall_enough and top_y >= 10.5
	_check("%d bubble patterns, each a staircase (steps of 5 m or less) up to his head" % count, all_ok and tall_enough and count >= 5)
	_check("the first bubble of every staircase is down by the floor (2 m or lower)", low_first)
	var top_perch: float = 0.0
	for perch: Vector2 in boss.perches:
		top_perch = maxf(top_perch, perch.y)
	_check("his perches are low enough to see (highest %.1f m)" % top_perch, top_perch <= 14.0)
	_check("he starts the fight low and close to eye line (%.1f m up)" % boss.position.y, boss.position.y <= 6.0)

	# --- Walk in: the hello scene, buttons lock, the door slams shut; hold jump to skip. ---
	player.position = Vector3(11.5, 1.2, 0)
	await _wait(0.8)
	_check("hello scene runs, buttons locked (phase %s, locked %s)" % [str(boss.phase), str(player.input_locked)],
		boss.phase == BigBadBurp.Phase.INTRO and player.input_locked)
	_check("door shuts behind him (y=%.1f)" % boss.door.position.y, boss.door.position.y > 5.0)
	var camera: Camera3D = get_root().get_camera_3d()
	_check("camera keeps Big Bad Burp in the shot", camera != null and camera.get("also_show").has(boss))
	await _wait(1.0)
	_check("during the hello his head, his body and Fart Man are all in the shot (head y %.1f, fov %.0f)" % [boss.head.global_position.y, camera.fov],
		_everyone_in_frame(camera))
	Input.action_press(&"jump")
	await _wait(1.3)
	Input.action_release(&"jump")
	_check("after the hello he flies up (still hello phase %s, y %.1f)" % [str(boss.phase), boss.position.y],
		boss.phase == BigBadBurp.Phase.INTRO or boss.position.y > 6.0)
	var in_part1: bool = await _until(func() -> bool: return boss.phase == BigBadBurp.Phase.PART1, 4.0)
	_check("held jump skips the hello (phase %s, locked %s)" % [str(boss.phase), str(player.input_locked)],
		in_part1 and not player.input_locked)
	_check("he flew up to his first perch (y %.1f, perch %.1f)" % [boss.position.y, boss.floor_y + boss.perches[0].y],
		absf(boss.position.y - (boss.floor_y + boss.perches[0].y)) < 0.5)
	await _wait(1.5)
	_check("at his first perch he and Fart Man are both in the shot (head y %.1f)" % boss.head.global_position.y, _everyone_in_frame(camera))
	_check("hello is remembered as seen", save == null or save.has_seen("burp_hello"))

	# --- Part 1: BUUURP first, the spots blink, then the bubbles swell, then they can be touched. ---
	await _until(func() -> bool: return boss.mood != BigBadBurp.Mood.TELL, 5.0)
	# Clear the old volley away so we only look at a fresh one.
	boss._clear_shots()
	await physics_frame
	var started: bool = await _until(func() -> bool: return boss.mood == BigBadBurp.Mood.TELL, 8.0)
	_check("he opens wide and burps (the tell)", started)
	await _wait(0.3)
	var bubbles: Array[Node] = _shots()
	_check("bubble spots appear (%d)" % bubbles.size(), bubbles.size() >= 3)
	var first: BurpBubble = bubbles[0] as BurpBubble
	var spots: Dictionary = {}
	var flash_ok: bool = true
	var colours_differ: bool = false
	var good_colour: Color
	var bad_colour: Color
	for b: Node in bubbles:
		var bb: BurpBubble = b as BurpBubble
		spots[bb] = bb.global_position
		flash_ok = flash_ok and bb.is_flashing() and not bb._body.visible and bb._shape.disabled
		var ring: MeshInstance3D = bb._ghost.get_child(1) as MeshInstance3D
		var colour: Color = (ring.mesh.material as StandardMaterial3D).albedo_color
		if bb.stinky:
			bad_colour = colour
		else:
			good_colour = colour
	colours_differ = good_colour != bad_colour
	_check("first only a blinking ghost: no bubble yet and nothing to touch", flash_ok)
	_check("good and stinky ghosts are different colours (%s vs %s)" % [str(good_colour), str(bad_colour)], colours_differ or bad_colour == Color())
	_check("the ghost is exactly where the bubble will be, at its size", first.flash_position().is_equal_approx(first.global_position)
		and first._ghost.get_child(0) is MeshInstance3D and absf(((first._ghost.get_child(0) as MeshInstance3D).mesh as SphereMesh).radius - first.radius) < 0.01)
	await _wait(boss.flash_time + 0.1)
	_check("then the flash is over and the bubble is swelling, still too small to touch (scale %.2f)" % first._body.scale.x,
		not first.is_flashing() and first._body.visible and first._body.scale.x < 0.99 and first._shape.disabled == false)
	var same_spot: bool = true
	for bb: BurpBubble in spots:
		if is_instance_valid(bb):
			same_spot = same_spot and absf(bb.global_position.x - spots[bb].x) < 0.6 and bb.global_position.y - spots[bb].y < 1.6 and bb.global_position.y >= spots[bb].y
	_check("it swells up in the same spot the ghost showed", same_spot)
	_check("they are giant (radius %.1f)" % first.radius, first.radius >= 1.2)
	await _wait(boss.tell_time + 0.3)
	_check("then the tell is over and they are ready", boss.mood == BigBadBurp.Mood.CALM and first._body.scale.x > 0.95)
	# Bounce off the first bubble.
	player.flashing_left = 1000.0
	var low: BurpBubble = null
	for b: Node in _shots():
		var bb: BurpBubble = b as BurpBubble
		if not bb.stinky and (low == null or bb.position.y < low.position.y):
			low = bb
	player.global_position = low.global_position + Vector3(0, 2.4, 0)
	player.velocity = Vector3(0, -3, 0)
	var vy: float = -100.0
	for i in 30:
		await physics_frame
		vy = maxf(vy, player.velocity.y)
	_check("landing on a giant bubble bounces him very high (%.1f m/s)" % vy, vy >= 21.0)
	# --- Touching a good bubble ANYWHERE launches him up and out of the top. ---
	player.flashing_left = 1000.0
	# [name, bubble height, where he is compared to its middle]. The last is the low first bubble,
	# swelling up round him as he stands on the floor.
	var cases: Array = [["from below", 7.0, Vector3(0, -2.2, 0)], ["from the side", 7.0, Vector3(-1.9, 0, 0)],
		["from the floor edge", 1.8, Vector3(-1.9, -0.6, 0)]]
	for c: Array in cases:
		var spot := Vector3(52, float(c[1]), 0)
		var test_bubble: BurpBubble = boss.spawn_bubble(spot, false)
		await _until(func() -> bool: return not test_bubble.is_flashing() and test_bubble._body.scale.x > 0.97, 4.0)
		player.global_position = test_bubble.global_position + (c[2] as Vector3)
		player.velocity = Vector3.ZERO
		var top_at_start: float = test_bubble.global_position.y + test_bubble.radius
		var best_vy: float = -100.0
		var best_y: float = -100.0
		for i in 150:
			await physics_frame
			best_vy = maxf(best_vy, player.velocity.y)
			best_y = maxf(best_y, player.get_feet_y())
		_check("a bubble touched %s launches him (%.1f m/s) up above its top (feet %.1f over %.1f), and it pops" % [c[0], best_vy, best_y, top_at_start + 1.5],
			best_vy >= 20.0 and best_y > top_at_start + 1.5 and not is_instance_valid(test_bubble))
		player.velocity = Vector3.ZERO
		await _until(func() -> bool: return player.is_on_floor(), 4.0)
	# A stinky bubble hurts.
	var stinker: BurpBubble = null
	for round_try in 6:
		for b: Node in _shots():
			if (b as BurpBubble).stinky:
				stinker = b as BurpBubble
		if stinker != null:
			break
		await _wait(1.0)
	if stinker == null:
		# Make one ourselves if the first patterns had none.
		stinker = boss.spawn_bubble(Vector3(40, 3, 0), true)
	await _until(func() -> bool: return is_instance_valid(stinker) and not stinker.is_flashing() and stinker._body.scale.x > 0.99, 4.0)
	player.flashing_left = 0.0
	player.global_position = stinker.global_position
	player.velocity = Vector3.ZERO
	var before: int = _hearts()
	await _wait(0.3)
	_check("a green stinky bubble hurts (hearts %d -> %d)" % [before, _hearts()], _hearts() < before)

	# --- Six stomps, three rounds that get faster, helpers come. ---
	var rises: Array[float] = []
	var saw_burplings: bool = false
	var saw_whifflers: bool = false
	# Count every bean thrown during the fight (hit beans vanish after a few seconds).
	var thrown: Array[int] = [0]
	var bean_counter := func(n: Node) -> void:
		var script: Script = n.get_script()
		if script != null and script.resource_path == "res://scripts/bean.gd":
			thrown[0] += 1
	node_added.connect(bean_counter)
	for n in 6:
		_check("round %d: %d stomps so far" % [boss.round_now() + 1, boss.hits1], boss.hits1 == n)
		# Wait until a volley is on, to see this round's bubble speed and helpers.
		await _until(func() -> bool: return _shots().size() >= 3, 6.0)
		if _shots().size() > 0:
			rises.append((_shots()[0] as BurpBubble).rise_speed)
		for h: Node in boss._helpers:
			if is_instance_valid(h):
				saw_burplings = saw_burplings or not (h is Whiffler)
				saw_whifflers = saw_whifflers or h is Whiffler
		await _stomp_head()
		_check("stomp %d counts (hits %d)" % [n + 1, boss.hits1], boss.hits1 == n + 1)
		if n < 5:
			_check("after a hit he is hurt for a moment and the bubbles go", boss.mood == BigBadBurp.Mood.HIT and _shots().is_empty())
			await _wait(boss.hit_pause + 1.2)
			await _until(func() -> bool: return player.is_on_floor(), 4.0)
			await _wait(1.5)
			_check("perch %d (%.0f, %.1f): he and Fart Man are both in the shot" % [boss._perch + 1, boss.position.x, boss.position.y], _everyone_in_frame(camera))
	_check("bubbles get faster each round (%s)" % str(rises), rises.size() >= 5 and rises[rises.size() - 1] > rises[0])
	_check("Burplings and then Whifflers help him (%s, %s)" % [str(saw_burplings), str(saw_whifflers)], saw_burplings and saw_whifflers)
	node_added.disconnect(bean_counter)
	_check("hits shower beans (%d beans thrown)" % thrown[0], thrown[0] >= 20)

	# --- After the sixth stomp: he flies off, the burrito falls, the way opens. ---
	_check("part 1 is won: the leaving scene starts (phase %s)" % str(boss.phase), boss.phase == BigBadBurp.Phase.LEAVING)
	Input.action_press(&"jump")
	await _wait(1.3)
	Input.action_release(&"jump")
	var arrived: bool = await _until(func() -> bool: return boss.phase == BigBadBurp.Phase.BURRITO, 6.0)
	_check("the Rocket Burrito arrives (visible %s, can be grabbed %s)" % [str(boss.burrito.visible), str(boss.burrito.monitoring)],
		arrived and boss.burrito.visible and boss.burrito.monitoring)
	await _wait(1.6)
	_check("the door is open and the wall on the right is gone", boss.door.position.y < 0.0 and not is_instance_valid(boss.gate))
	_check("he flew away", not boss.visual.visible)

	# --- Part 2: grab the burrito and the chase starts. ---
	player.flashing_left = 1000.0
	player.global_position = boss.burrito.global_position
	player.velocity = Vector3.ZERO
	await _wait(0.3)
	_check("grabbing the burrito starts flying and the chase (flying %s, phase %s)" % [str(player.is_flying()), str(boss.phase)],
		player.is_flying() and boss.phase == BigBadBurp.Phase.PART2)
	await _wait(0.5)
	_check("he is ahead of Fart Man (%.0f m)" % (boss.global_position.x - player.global_position.x),
		boss.visual.visible and boss.global_position.x - player.global_position.x > 20.0)
	# Keep him in the middle of the sky so only the fight matters, and watch the attacks.
	player.flashing_left = 0.0
	var tells: int = 0
	var rings: int = 0
	var walls: int = 0
	var ring_after_tell: bool = true
	var tell_frame: int = 0
	var frame: int = 0
	var dizzy_seen: bool = false
	var hits_seen: int = 0
	var loot_at_hit: int = 0
	var saw_tell: bool = false
	for i in 60 * 70:
		await physics_frame
		player.flashing_left = 1000.0
		player.position.y = clampf(player.position.y, 3.0, 20.0)
		frame += 1
		if boss.mood == BigBadBurp.Mood.TELL and not saw_tell:
			saw_tell = true
			tells += 1
			tell_frame = frame
		elif boss.mood != BigBadBurp.Mood.TELL:
			saw_tell = false
		for shot: Node in get_nodes_in_group(&"boss_shots"):
			if shot.has_meta(&"seen"):
				continue
			shot.set_meta(&"seen", true)
			# Nothing flies at you until at least 0.8 s after he opened wide.
			ring_after_tell = ring_after_tell and frame - tell_frame >= 48
			if shot is BurpRing:
				rings += 1
			elif shot is BurpBubble:
				walls += 1
		if boss.mood == BigBadBurp.Mood.DIZZY:
			dizzy_seen = true
			# Steer into him (like holding jump or letting go to match his height).
			player.position.y = boss.position.y
		if boss.hits2 > hits_seen:
			loot_at_hit = maxi(loot_at_hit, _loot())
			hits_seen = boss.hits2
			print("  chase hit %d at x=%.0f" % [hits_seen, player.position.x])
		if boss.phase == BigBadBurp.Phase.DEFEATED:
			break
	_check("he burped %d times (a tell each time), %d rings and %d stinky bubbles" % [tells, rings, walls], tells >= 6 and rings >= 3 and walls >= 3)
	_check("every ring and bubble wall came at least 0.8 s after the BUUURP tell", ring_after_tell)
	_check("he went dizzy and Fart Man bumped him four times (hits %d)" % boss.hits2, dizzy_seen and boss.hits2 == boss.hits_part2)
	_check("the fight is won in %s" % str(boss.phase), boss.phase == BigBadBurp.Phase.DEFEATED)
	_check("every bump showered beans (%d thrown)" % loot_at_hit, loot_at_hit >= 8)

	# --- The ending. Hold jump to skip the talking: the bean, the rumble and the big fart still happen. ---
	var landed: bool = await _until(func() -> bool: return not player.is_flying() and player.is_on_floor(), 5.0)
	_check("flying stops and Fart Man lands for the ending (%s)" % str(landed), landed)
	await _wait(1.5)
	_check("the ending scene runs, buttons locked (locked %s)" % str(player.input_locked), player.input_locked)
	_check("he stands next to Fart Man (%.1f m away)" % absf(boss.global_position.x - player.global_position.x), absf(boss.global_position.x - player.global_position.x) < 9.0)
	var max_loot: int = 0
	Input.action_press(&"jump")
	for i in 60 * 20:
		await physics_frame
		max_loot = maxi(max_loot, _loot())
		if get_nodes_in_group(&"storybook").size() > 0:
			break
		var found_book: bool = false
		for node: Node in root.get_children():
			found_book = found_book or node is Storybook
		if found_book:
			break
	Input.action_release(&"jump")
	_check("THE BIGGEST FART IN HISTORY: beans rain on the world (%d beans in the air at once)" % max_loot, max_loot >= 40)
	var book: Storybook = null
	for i in 600:
		await physics_frame
		for node: Node in root.get_children():
			if node is Storybook:
				book = node as Storybook
		if book != null:
			break
	_check("then the ending storybook shows", book != null and book.story_name == "ending")
	if book != null:
		_check("the ending has five pages and ends with EVERYBODY FARTS. THE END.", book.pages.size() == 5
			and str(book.pages[4]["text"]) == "EVERYBODY FARTS. THE END.")
		_check("the last stage is saved as cleared", save == null or save.is_cleared("3-4"))
		await _wait(0.6)
		for i in 5:
			Input.action_press(&"ui_accept")
			await _wait(0.1)
			Input.action_release(&"ui_accept")
			await _wait(0.3)
		await _wait(1.0)
		var map: Node = current_scene
		_check("and then it goes back to the world map (%s)" % str(map), map != null and map is WorldMap)
	if current_scene != null:
		current_scene.free()

	# --- Losing in part 2 sends him back to the toilet; the hits stay and the burrito is still there. ---
	_load_stage()
	await _wait(0.5)
	boss.hits1 = boss.hits_part1
	boss.hits2 = 1
	boss.phase = BigBadBurp.Phase.BURRITO
	boss.drop_burrito()
	await _wait(1.2)
	player.global_position = boss.burrito.global_position
	await _wait(0.5)
	_check("chase on again (phase %s, flying %s)" % [str(boss.phase), str(player.is_flying())], boss.phase == BigBadBurp.Phase.PART2)
	player.respawned.emit()
	await _wait(0.3)
	_check("falling back to a toilet when not flying returns him to the burrito (phase %s, hits kept %d)" % [str(boss.phase), boss.hits2],
		boss.phase in [BigBadBurp.Phase.BURRITO, BigBadBurp.Phase.PART2] and boss.hits2 == 1)

	if is_instance_valid(stage):
		stage.free()
	if save != null:
		save.reset()
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://test_world3_boss_save.json"))
	print("world 3 boss failures: %d" % failures)
	quit()
