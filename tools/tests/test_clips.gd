extends SceneTree
# Checks Fart Man's animation clips: the library is complete, every clip stays in place
# and has its feet on the floor, and the right clip plays for what he does in a level.
# Tests can't see the screen: the contact sheets from tools/snapshot_player.gd are for that.

const Clips: GDScript = preload("res://tools/fart_man_clips.gd")

var failures: int = 0
var played: Array[StringName] = []


func _initialize() -> void:
	var save: Node = root.get_node_or_null("SaveGame")
	if save != null:
		save.use_file("user://test_clips_save.json")  # never touch the real save
		save.reset()
	var level: Node = load("res://scenes/test_level.tscn").instantiate()
	root.add_child(level)
	_run(level)


func _wait(seconds: float) -> void:
	for i in int(seconds * 60.0):
		await physics_frame


func _check(label: String, ok: bool) -> void:
	print("%s: %s" % [label, "ok" if ok else "FAILED"])
	if not ok:
		failures += 1


func _run(level: Node) -> void:
	# This test is about the CLASSIC charge-fart controls (SIMPLE is the default now).
	(root.get_node("DebugOptions") as DebugOptionsData).set_simple_controls(false)
	var player: Player = level.get_node("Player")
	var anim: PlayerAnimator = player.get_node("Animator")
	var tank: Node = player.get_node("GasTank")
	var hearts: Hearts = player.get_node("Hearts")
	var clips: AnimationPlayer = player.get_node("Visual/ModelTurn/Model/Clips")
	var model: Node3D = player.get_node("Visual/ModelTurn/Model")
	var skeleton: Skeleton3D = model.find_children("*", "Skeleton3D", true, false)[0]
	anim.clip_played.connect(func(c: StringName) -> void: played.append(c))
	for enemy: Node in level.get_node("Enemies").get_children():
		enemy.free()

	# --- The library itself ---
	var wanted: Array[StringName] = []
	wanted.append_array(CharacterAnimator.PLAYER_CLIPS)
	wanted.append_array([&"walk", &"sprint", &"hop", &"hop_run", &"big_jump", &"big_land", &"roll", &"death", &"death_2"])
	_check("model has every wanted clip", anim.missing_clips(wanted).is_empty())
	var library: AnimationLibrary = clips.get_animation_library(&"")
	var scale_to_game: float = model.scale.x
	var bad_loop: int = 0
	var moving_hips: int = 0
	var floating_feet: int = 0
	for row: Array in Clips.RECIPE:
		var clip: Animation = library.get_animation(StringName(row[0]))
		if clip.loop_mode != row[4]:
			bad_loop += 1
		var hips: int = -1
		for t in clip.get_track_count():
			if clip.track_get_type(t) == Animation.TYPE_POSITION_3D and str(clip.track_get_path(t)).ends_with("mixamorig_Hips"):
				hips = t
		var first: Vector3 = clip.track_get_key_value(hips, 0)
		for k in clip.track_get_key_count(hips):
			var p: Vector3 = clip.track_get_key_value(hips, k)
			if absf(p.x - first.x) > 0.000001 or absf(p.z - first.z) > 0.000001:
				moving_hips += 1
				break
		if row[5] == "floor":
			var toe: float = Clips.lowest_toe_with(skeleton, clip) * scale_to_game
			if absf(toe) > 0.02:
				floating_feet += 1
				print("  %s lowest toe %.3f m" % [row[0], toe])
	_check("loop modes match the recipe (%d wrong)" % bad_loop, bad_loop == 0)
	_check("every clip is in place: hips x and z constant (%d moving)" % moving_hips, moving_hips == 0)
	_check("floor clips: lowest toe on the floor within 2 cm (%d off)" % floating_feet, floating_feet == 0)

	# --- Playing in a level ---
	await _wait(1.0)
	_check("standing -> idle (%s)" % anim.loop_clip, anim.loop_clip == &"idle")
	var standing_belly_y: float = player.belly.global_position.y

	Input.action_press(&"ui_right")
	await _wait(0.5)
	_check("running right -> run (%s)" % anim.loop_clip, anim.loop_clip == &"run")
	var vx: float = player.velocity.x
	_check("run speed matches ground speed (%.2f vs %.2f)" % [clips.speed_scale, vx / 5.1],
		absf(clips.speed_scale - vx / 5.1) < 0.05 and absf(vx - 6.0) < 0.2)
	var belly_dx: float = player.belly.global_position.x - player.global_position.x
	_check("belly in front of him when facing right (%.2f)" % belly_dx, belly_dx > 0.1)
	# Toot while running.
	played.clear()
	Input.action_press(&"jump")
	await _wait(0.05)
	Input.action_release(&"jump")
	_check("a Toot while running -> hop_run (%s)" % str(played), &"hop_run" in played)
	await _wait(1.2)
	# Turning left puts the belly on his left.
	Input.action_release(&"ui_right")
	Input.action_press(&"ui_left")
	await _wait(0.4)
	belly_dx = player.belly.global_position.x - player.global_position.x
	_check("belly follows the model when he turns left (%.2f)" % belly_dx, belly_dx < -0.1)
	Input.action_release(&"ui_left")
	await _wait(0.6)
	player.position = Vector3(-6, 1.5, 0)  # clear floor, away from the Toot ledge at x=0.5
	player.velocity = Vector3.ZERO
	await _wait(0.8)

	# Slow walking: the stick pushed only a third of the way (2 m/s).
	Input.action_press(&"ui_right", 0.33)
	await _wait(0.4)
	var slow: float = player.velocity.x
	_check("slow (%.1f m/s) -> walk (%s)" % [slow, anim.loop_clip], anim.loop_clip == &"walk")
	_check("walk speed matches (%.2f vs %.2f)" % [clips.speed_scale, slow / 1.72], absf(clips.speed_scale - slow / 1.72) < 0.05)
	Input.action_release(&"ui_right")
	await _wait(0.5)
	player.position = Vector3(-6, 1.5, 0)  # clear floor, away from the Toot ledge at x=0.5
	player.velocity = Vector3.ZERO
	await _wait(0.5)

	# Chilli hot and running -> sprint.
	player.chilli.start()
	Input.action_press(&"ui_right")
	await _wait(0.5)
	_check("hot and running -> sprint (%s at %.1f m/s)" % [anim.loop_clip, player.velocity.x], anim.loop_clip == &"sprint")
	Input.action_release(&"ui_right")
	player.chilli.time_left = 0.0
	await _wait(0.8)
	player.position = Vector3(-6, 1.5, 0)  # clear floor, away from the Toot ledge at x=0.5
	player.velocity = Vector3.ZERO
	await _wait(1.0)

	# Toot standing.
	played.clear()
	Input.action_press(&"jump")
	await _wait(0.05)
	Input.action_release(&"jump")
	_check("a Toot standing -> hop (%s)" % str(played), &"hop" in played and not &"hop_run" in played)
	await _wait(1.5)

	# Charging standing: crouch, belly sinks with the spine.
	tank.refill(100.0)
	Input.action_press(&"fart")
	await _wait(0.3)
	_check("charging while standing -> charge (%s)" % anim.loop_clip, anim.loop_clip == &"charge")
	var charge_belly_y: float = player.belly.global_position.y
	_check("belly sinks with the crouch (%.2f -> %.2f)" % [standing_belly_y, charge_belly_y], charge_belly_y < standing_belly_y - 0.02)
	await _wait(0.5)
	# Thunder standing, then landing -> big_jump, then big_land.
	played.clear()
	Input.action_release(&"fart")
	await _wait(0.1)
	_check("a Thunder standing -> big_jump (%s)" % str(played), &"big_jump" in played)
	await _wait(2.2)
	_check("then landing -> big_land (%s)" % str(played), &"big_land" in played and not &"land" in played)
	await _wait(1.2)

	# Thunder while running, then landing -> roll.
	tank.refill(100.0)
	player.position = Vector3(-10, 1.5, 0)
	player.velocity = Vector3.ZERO
	await _wait(0.8)
	Input.action_press(&"ui_right")
	Input.action_press(&"fart")
	await _wait(0.6)
	played.clear()
	Input.action_release(&"fart")
	await _wait(0.1)
	_check("a Thunder while running -> big_jump (%s)" % str(played), &"big_jump" in played)
	await _wait(1.9)
	Input.action_release(&"ui_right")
	_check("a Thunder while running, landing -> roll (%s)" % str(played), &"roll" in played)
	await _wait(2.0)
	player.position = Vector3(-6, 1.5, 0)  # clear floor, away from the Toot ledge at x=0.5
	player.velocity = Vector3.ZERO
	await _wait(1.0)

	# Hurt.
	played.clear()
	player.flashing_left = 0.0
	player.hurt(player.global_position.x + 1.0)
	await _wait(0.05)
	_check("hurt -> hurt clip (%s)" % str(played), &"hurt" in played)
	await _wait(2.0)

	# Last heart lost: dies on the floor, then pops back.
	var died_count: Array[int] = [0]
	var respawn_count: Array[int] = [0]
	player.died.connect(func() -> void: died_count[0] += 1)
	player.respawned.connect(func() -> void: respawn_count[0] += 1)
	player.flashing_left = 0.0
	played.clear()
	hearts.hearts = 1
	player.hurt(player.global_position.x + 1.0)
	await _wait(0.3)
	_check("last heart lost -> death clip (%s)" % str(played), &"death" in played or &"death_2" in played)
	_check("lying there: not yet back (respawns=%d dying=%s)" % [respawn_count[0], player.is_dying], respawn_count[0] == 0 and player.is_dying)
	player.hurt(player.global_position.x + 1.0)
	await _wait(player.death_time + 0.5)
	_check("back after death_time (respawns=%d, died=%d, hearts=%d)" % [respawn_count[0], died_count[0], hearts.hearts],
		respawn_count[0] == 1 and died_count[0] == 1 and hearts.hearts == 3 and not player.is_dying)
	await _wait(0.5)
	_check("standing again (%s)" % anim.loop_clip, anim.loop_clip == &"idle" and anim.shot_clip == &"")

	# Last heart lost in mid-air: landing must not swap the death clip for "land".
	player.flashing_left = 0.0
	hearts.hearts = 1
	player.velocity.y = 6.0
	await _wait(0.1)
	player.hurt(player.global_position.x + 1.0)
	await _wait(1.0)
	_check("last heart lost in the air: still the death clip after landing (%s, on floor %s)" % [anim.shot_clip, player.is_on_floor()],
		anim.shot_clip in [&"death", &"death_2"] and player.is_on_floor())
	await _wait(player.death_time + 1.0)

	# Talking while standing.
	anim.talk_for(1.0)
	await _wait(0.3)
	_check("talking -> talk (%s)" % anim.loop_clip, anim.loop_clip == &"talk")
	await _wait(1.0)
	_check("talk ends (%s)" % anim.loop_clip, anim.loop_clip == &"idle")

	# Victory.
	played.clear()
	player.celebrate()
	await _wait(0.1)
	_check("celebrate -> victory (%s)" % str(played), &"victory" in played)
	Input.action_press(&"ui_right")
	await _wait(0.3)
	_check("victory stops when he runs (%s)" % anim.shot_clip, anim.shot_clip == &"")
	Input.action_release(&"ui_right")

	print("clips failures: %d" % failures)
	quit()
