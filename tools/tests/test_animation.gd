extends SceneTree
# Checks the animation hooks: the right clip plays for what Fart Man and a Burpling do,
# the grey-box squash and stretch moves the shape, and missing clips are reported.

var clips: Array[StringName] = []
var failures: int = 0


func _initialize() -> void:
	var level: Node = load("res://scenes/test_level.tscn").instantiate()
	root.add_child(level)
	_run(level)


func _wait(seconds: float) -> void:
	for i in int(seconds * 60.0):
		await physics_frame


func _check(label: String, ok: bool) -> void:
	print("%s: %s" % [label, "ok" if ok else "FAIL"])
	if not ok:
		failures += 1


func _run(level: Node) -> void:
	# This test is about the CLASSIC charge-fart controls (SIMPLE is the default now).
	(root.get_node("DebugOptions") as DebugOptionsData).set_simple_controls(false)
	var player: Player = level.get_node("Player")
	var anim: PlayerAnimator = player.get_node("Animator")
	anim.clip_played.connect(func(c: StringName) -> void: clips.append(c))
	# Clear the level's enemies so they can't interrupt the test.
	for enemy: Node in level.get_node("Enemies").get_children():
		enemy.free()
	await _wait(1.0)
	_check("idle when standing", anim.loop_clip == &"idle")

	# Running.
	Input.action_press(&"ui_right")
	await _wait(0.4)
	_check("run when walking", anim.loop_clip == &"run")
	Input.action_release(&"ui_right")
	await _wait(0.5)

	# Charging, then the squeak.
	clips.clear()
	Input.action_press(&"fart")
	await _wait(0.3)
	_check("charge while holding", anim.loop_clip == &"charge")
	var squashed_scale: float = player.visual.scale.y
	if anim.has_clip(&"charge"):
		# Real model: the crouch clip does the acting, so the code must leave his shape alone.
		_check("charge plays the real crouch, no code squash (y=%.2f)" % squashed_scale, absf(squashed_scale - 1.0) < 0.01)
	else:
		_check("charge squashes the shape in code (y=%.2f)" % squashed_scale, absf(squashed_scale - 1.0) > 0.01)
	await _wait(1.5)
	_check("squeak when held too long", anim.loop_clip == &"squeak")
	Input.action_release(&"fart")
	await _wait(0.1)
	_check("jump one-shot on launch", &"jump" in clips)

	# In the air, then landing.
	await _wait(0.2)
	var in_air: StringName = anim.loop_clip
	_check("rising or falling in the air (%s)" % in_air, in_air == &"jump" or in_air == &"fall")
	clips.clear()
	await _wait(1.5)
	_check("land one-shot on touchdown", &"land" in clips)
	await _wait(0.5)
	_check("back to idle after landing", anim.loop_clip == &"idle" and anim.shot_clip == &"")
	_check("shape back to normal size", absf(player.visual.scale.y - 1.0) < 0.1)

	# Hurt.
	clips.clear()
	player.hurt(player.global_position.x + 1.0)
	await _wait(0.05)
	_check("hurt one-shot", &"hurt" in clips)
	await _wait(2.0)
	_check("hurt ends by itself, back on the ground", anim.shot_clip == &"" and anim.loop_clip == &"idle")

	# Flight.
	player.start_flying(-5.0, 50.0)
	await _wait(0.2)
	_check("flight clip while flying", anim.loop_clip == &"flight")
	player.stop_flying()
	await _wait(0.2)

	# A Burpling walks, then squashes flat.
	var burp: Burpling = load("res://scenes/burpling.tscn").instantiate()
	root.add_child(burp)
	burp.position = Vector3(50, 5, 0)
	var enemy_anim: EnemyAnimator = burp.get_node("Animator")
	await _wait(0.2)
	_check("burpling walks", enemy_anim.loop_clip == &"walk")
	burp._get_squashed()
	await _wait(0.05)
	_check("burpling squash clip", enemy_anim.shot_clip == &"squash")
	await _wait(0.1)
	_check("burpling flat in code (y=%.2f)" % burp.visual.scale.y, burp.visual.scale.y < 0.2)
	await _wait(0.5)
	_check("burpling removed after squash", not is_instance_valid(burp))

	# Real models: the clip checker. A model missing "hurt" must be reported, not crash.
	var fake := AnimationPlayer.new()
	var library := AnimationLibrary.new()
	for c: StringName in CharacterAnimator.PLAYER_CLIPS:
		if c != &"hurt":
			library.add_animation(c, Animation.new())
	fake.add_animation_library(&"", library)
	root.add_child(fake)
	var checker := CharacterAnimator.new()
	checker.animation_player = fake
	root.add_child(checker)
	var missing: Array[StringName] = checker.missing_clips(CharacterAnimator.PLAYER_CLIPS)
	_check("missing clip reported (%s)" % str(missing), missing == [&"hurt"])
	# A clip it does have plays for real, and one it lacks falls back without errors.
	checker.play(&"idle")
	checker.play_once(&"hurt")
	_check("fake model plays real idle", fake.current_animation == &"idle")

	print("animation failures: %d" % failures)
	quit()
