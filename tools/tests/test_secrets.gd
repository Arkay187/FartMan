extends SceneTree
# Checks the secrets in the four running stages (1-1, 1-2, 2-1, 2-2):
#  - a fake wall lets him walk through and turns see-through while he is inside
#  - every stage has 3+ secrets and 2+ bean rooms, each with 60+ beans and 2+ bouncers
#  - every bean room can be entered by its pipe and left again by the pipe home
#  - hint signs show simple_words in SIMPLE and words in CLASSIC
#  - high secret ledges are within what SIMPLE (and, where not simple-only, CLASSIC) can reach
#  - the main paths of all four stages have no impossible gaps; the tutorial's first part has no pit
#  - a real SIMPLE double jump gets onto 1-1's high Golden Bean crate

const Secrets := preload("res://tools/kit_secrets.gd")


## A level kit that does everything the real one does but does not save the scene file.
class NoSaveKit extends "res://tools/kit_factory.gd":
	func finish(_path: String) -> Array[String]:
		var problems: Array[String] = check_route()
		root.free()
		return problems


var failures: int = 0
var options: DebugOptionsData


func _initialize() -> void:
	_run()


func _wait(seconds: float) -> void:
	for i in int(seconds * 60.0):
		await physics_frame


func _check(label: String, ok: bool) -> void:
	print("%s: %s" % [label, "ok" if ok else "FAIL"])
	if not ok:
		failures += 1


## Beans, bouncers and pipes whose position is inside the room's box.
func _inside(stage: Node, room: Node3D, group_name: String) -> Array[Node3D]:
	var size: Vector2 = room.get_meta("room_size")
	var found: Array[Node3D] = []
	for node: Node in stage.get_node(group_name).get_children():
		var n := node as Node3D
		if n != null and absf(n.position.x - room.position.x) <= size.x * 0.5 + 2.0 and absf(n.position.y - room.position.y) <= size.y * 0.5 + 1.0:
			found.append(n)
	return found


func _run() -> void:
	var save: Node = root.get_node_or_null("SaveGame")
	if save != null:
		save.use_file("user://test_secrets_save.json")
		save.reset()
	options = root.get_node("DebugOptions") as DebugOptionsData
	var original_simple: bool = options.simple_controls

	# --- A fake wall: he walks through it and it turns see-through. ---
	options.set_simple_controls(true)
	var kit := NoSaveKit.new()
	kit.begin("t", "", Vector3(0, 1.2, 0), Color.WHITE)
	kit.ground(-12, 60)
	var wall: FakeWall = Secrets.fake_wall(kit, 10, 14, 0.0, 3.0, Color(0.5, 0.4, 0.3))
	var world: Node3D = kit.root
	root.add_child(world)
	var player: Player = kit.player
	player.flashing_left = 1000.0
	await _wait(0.3)
	_check("fake wall starts solid-looking (alpha %.2f)" % wall.current_alpha, wall.current_alpha > 0.99)
	var min_alpha: float = 1.0
	Input.action_press(&"ui_right")
	for i in 220:
		await physics_frame
		min_alpha = minf(min_alpha, wall.current_alpha)
	Input.action_release(&"ui_right")
	_check("he walked straight through the fake wall (x=%.1f)" % player.position.x, player.position.x > 16.0)
	_check("it turned see-through while he was inside (alpha %.2f)" % min_alpha, min_alpha < 0.4)
	await _wait(0.5)
	_check("and solid-looking again after he left (alpha %.2f)" % wall.current_alpha, wall.current_alpha > 0.99)
	_check("a fake wall is in the group secrets", wall.is_in_group(&"secrets"))
	world.free()
	await _wait(0.1)

	# --- No impossible gaps on the main path of any of the four stages. ---
	for id in ["1-1", "1-2", "2-1", "2-2"]:
		var script: GDScript = load("res://tools/stages/stage_%s.gd" % id.replace("-", "_"))
		var problems: Array[String] = script.new().build(NoSaveKit.new())
		_check("stage %s has no route problems %s" % [id, str(problems)], problems.is_empty())

	# --- Each stage in turn. ---
	for id in ["1-1", "1-2", "2-1", "2-2"]:
		var stage: Stage = load("res://scenes/stage_%s.tscn" % id.replace("-", "_")).instantiate()
		root.add_child(stage)
		await _wait(0.4)
		var pl: Player = stage.player
		pl.flashing_left = 1000000.0

		# Secrets: 3 or more.
		var secrets: Array[Node] = get_nodes_in_group(&"secrets")
		_check("%s has 3+ secrets (%d)" % [id, secrets.size()], secrets.size() >= 3)
		var walls: int = stage.find_children("*", "FakeWall", true, false).size()
		_check("%s has fake walls (%d)" % [id, walls], walls >= 1)

		# Ledges are reachable.
		var ledges_ok: bool = true
		var simple_only: int = 0
		for s: Node in secrets:
			if String(s.name).begins_with("Secret_Ledge"):
				var rise: float = float(s.get_meta("rise"))
				var only: bool = bool(s.get_meta("simple_only"))
				simple_only += 1 if only else 0
				if rise > Secrets.SIMPLE_MAX_RISE or (not only and rise > Secrets.CLASSIC_MAX_RISE):
					ledges_ok = false
					print("  ledge at x=%.0f rise %.1f too high (simple only: %s)" % [(s as Node3D).position.x, rise, str(only)])
		_check("%s secret ledges are within reach (%d need SIMPLE only)" % [id, simple_only], ledges_ok)

		# Exactly three Golden Beans.
		_check("%s has exactly 3 golden beans (%d)" % [id, stage.golden_total], stage.golden_total == 3)

		# Bean rooms.
		var rooms: Array[Node] = get_nodes_in_group(&"bean_rooms")
		_check("%s has 2+ bean rooms (%d)" % [id, rooms.size()], rooms.size() >= 2)
		var pipes: Array[Node] = stage.find_children("*", "WarpPipe", true, false)
		for r: Node in rooms:
			var room := r as Node3D
			var beans: int = _inside(stage, room, "Beans").size()
			var bouncers: int = _inside(stage, room, "Pads").size()
			print("%s room at x=%.0f y=%.0f: %d beans, %d bouncers" % [id, room.position.x, room.position.y, beans, bouncers])
			_check("%s room x=%.0f has 60+ beans and 2+ bouncers" % [id, room.position.x], beans >= 60 and bouncers >= 2)
			# Which pipe goes in, which comes out.
			var size: Vector2 = room.get_meta("room_size")
			var in_pipe: WarpPipe = null
			var home_pipe: WarpPipe = null
			for pp: Node in pipes:
				var wp := pp as WarpPipe
				var dest_in_room: bool = absf(wp.destination.x - room.position.x) <= size.x * 0.5 and absf(wp.destination.y - room.position.y) <= size.y * 0.5
				var pipe_in_room: bool = absf(wp.position.y - room.position.y) <= size.y * 0.5
				if dest_in_room and not pipe_in_room:
					in_pipe = wp
				elif pipe_in_room and not dest_in_room:
					home_pipe = wp
			_check("%s room x=%.0f has a way in and a way home" % [id, room.position.x], in_pipe != null and home_pipe != null)
			if in_pipe == null or home_pipe == null:
				continue
			# Walk into the entrance pipe.
			pl.position = Vector3(in_pipe.position.x - 2.0, in_pipe.position.y + 1.2, 0)
			pl.velocity = Vector3.ZERO
			Input.action_press(&"ui_right")
			var arrived: bool = false
			for i in 240:
				await physics_frame
				if absf(pl.position.y - room.position.y) < size.y * 0.5 and pl.position.y > in_pipe.position.y + 10.0:
					arrived = true
					break
			Input.action_release(&"ui_right")
			_check("%s room x=%.0f: the entrance pipe takes him in" % [id, room.position.x], arrived)
			# Walk to the pipe home (it is on the floor, to the right).
			await _wait(1.2)
			pl.position = Vector3(home_pipe.position.x - 2.5, home_pipe.position.y + 1.2, 0)
			pl.velocity = Vector3.ZERO
			Input.action_press(&"ui_right")
			var home: bool = false
			for i in 240:
				await physics_frame
				if pl.position.distance_to(home_pipe.destination) < 6.0:
					home = true
					break
			Input.action_release(&"ui_right")
			_check("%s room x=%.0f: the pipe home brings him back (x=%.1f y=%.1f)" % [id, room.position.x, pl.position.x, pl.position.y], home)
			await _wait(1.5)

		# Hints: both texts exist, and the right one shows.
		var hints: Array[Node] = stage.get_node("Hints").get_children()
		var with_simple: int = 0
		var right_text: bool = true
		for h: Node in hints:
			var talker := h as Chatterbox
			if talker.simple_words != "":
				with_simple += 1
				options.set_simple_controls(true)
				var simple_text: String = talker.what_to_say(pl)
				options.set_simple_controls(false)
				var classic_text: String = talker.what_to_say(pl)
				if simple_text != talker.simple_words or classic_text != talker.words:
					right_text = false
		options.set_simple_controls(true)
		_check("%s has hints with their own SIMPLE words (%d of %d) and each scheme gets its own text" % [id, with_simple, hints.size()], with_simple >= 3 and right_text)

		# The tutorial: no pit in the first part, and a real SIMPLE double jump onto the Golden Bean crate.
		if id == "1-1":
			var space: PhysicsDirectSpaceState3D = stage.get_world_3d().direct_space_state
			var gaps: Array[float] = []
			for gx in range(-10, 108):
				var query := PhysicsRayQueryParameters3D.create(Vector3(gx, 3.0, 0), Vector3(gx, -2.0, 0))
				if space.intersect_ray(query).is_empty():
					gaps.append(float(gx))
			_check("1-1: no pit in the first part, x=-10 to 108 (gaps at %s)" % str(gaps), gaps.is_empty())
			# Stand still, jump (hold to the top), jump again in the air, drift right over the crate and drop onto it.
			pl.position = Vector3(79.5, 1.2, 0)
			pl.velocity = Vector3.ZERO
			await _wait(0.5)
			Input.action_press(&"jump")
			await _wait(0.45)
			Input.action_release(&"jump")
			await physics_frame
			Input.action_press(&"jump")
			Input.action_press(&"ui_right")
			await _wait(0.15)
			Input.action_release(&"jump")
			await _wait(0.7)
			Input.action_release(&"ui_right")
			await _wait(2.5)
			_check("1-1: SIMPLE double jump gets onto the Golden Bean crate (x=%.1f y=%.1f, on floor %s)" % [pl.position.x, pl.position.y, str(pl.is_on_floor())],
				pl.position.y > 4.0 and pl.is_on_floor())
			# The ditch: just holding right walks down and up the slope (CLASSIC, no hover).
			options.set_simple_controls(false)
			pl.position = Vector3(104, 1.2, 0)
			pl.velocity = Vector3.ZERO
			Input.action_press(&"ui_right")
			await _wait(8.0)
			Input.action_release(&"ui_right")
			_check("1-1: the ditch cannot trap him, holding right crosses it (x=%.1f y=%.1f)" % [pl.position.x, pl.position.y], pl.position.x > 130.0 and pl.position.y > -1.0)
			options.set_simple_controls(true)

		stage.queue_free()
		await _wait(0.3)

	options.set_simple_controls(original_simple)
	if save != null:
		save.reset()
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://test_secrets_save.json"))
	print("secrets failures: %d" % failures)
	quit()
