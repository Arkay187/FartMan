extends SceneTree
# Checks the right home-made sound starts for each moment: hop, Trump, Thunder (plus the
# "wahoo"), the long squeak, flying, a bump, a spike ("yow"), and losing the last heart.
# It can't hear anything: it only checks which sound file was started.

var failures: int = 0
var world: Node3D
var player: Player
var sounds: PlayerSounds


func _initialize() -> void:
	_run()


func _wait(seconds: float) -> void:
	for i in int(seconds * 60.0):
		await physics_frame


func _check(label: String, ok: bool) -> void:
	print("%s: %s" % [label, "ok" if ok else "FAIL"])
	if not ok:
		failures += 1


func _fresh() -> void:
	if world != null:
		world.free()
	world = Node3D.new()
	root.add_child(world)
	var body := StaticBody3D.new()
	body.position = Vector3(0, -0.5, 0)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(200, 1, 4)
	col.shape = shape
	body.add_child(col)
	world.add_child(body)
	player = (load("res://scenes/player.tscn") as PackedScene).instantiate()
	player.position = Vector3(0, 1.2, 0)
	world.add_child(player)
	sounds = player.get_node("Sounds") as PlayerSounds


## Sounds started since the last call.
func _heard() -> Array[String]:
	var list: Array[String] = sounds.played.duplicate()
	sounds.played.clear()
	return list


func _hold(action: StringName, seconds: float) -> void:
	Input.action_press(action)
	await _wait(seconds)
	Input.action_release(action)
	await _wait(0.1)  # he launches on the frame after letting go


func _run() -> void:
	# This test is about the CLASSIC charge-fart controls (SIMPLE is the default now).
	(root.get_node("DebugOptions") as DebugOptionsData).set_simple_controls(false)
	_fresh()
	await _wait(0.5)
	_heard()

	await _hold(&"jump", 0.1)
	var hop: Array[String] = _heard()
	_check("hop plays a jump sound %s" % str(hop), hop.size() == 1 and hop[0] in ["jump_1.wav", "jump_2.wav"])
	await _wait(1.0)

	await _hold(&"fart", 0.3)
	var trump: Array[String] = _heard()
	var short_farts: Array[String] = ["fart_1.wav", "flying_bit_2.wav", "flying_bit_4.wav", "long_bit_1.wav"]
	var big_farts: Array[String] = ["long_fart_2.wav", "flying_bit_1.wav", "flying_bit_3.wav", "flying_bit_5.wav"]
	_check("medium fart plays one short fart %s" % str(trump), trump.size() == 1 and trump[0] in short_farts)
	await _wait(1.5)

	await _hold(&"fart", 0.7)
	var thunder: Array[String] = _heard()
	_check("big fart plays just one big fart, no shout %s" % str(thunder), thunder.size() == 1 and thunder[0] in big_farts)
	await _wait(2.0)

	# Lots of medium farts: more than one different sound turns up.
	var kinds: Dictionary = {}
	for i in 12:
		await _hold(&"fart", 0.3)
		for s: String in _heard():
			kinds[s] = true
		await _wait(1.3)
	_check("medium farts vary (%d different sounds)" % kinds.size(), kinds.size() >= 2)
	await _wait(2.0)

	# Hold far too long: the squeak starts.
	Input.action_press(&"fart")
	await _wait(1.6)
	var squeak: Array[String] = _heard()
	Input.action_release(&"fart")
	_check("holding too long plays long_fart %s" % str(squeak), squeak == ["long_fart.wav"])
	await _wait(1.5)
	_heard()

	# Bumped by an ordinary thing, then by a spike.
	player.hurt(player.global_position.x + 1.0)
	var bump: Array[String] = _heard()
	_check("ordinary hurt plays small_hit %s" % str(bump), bump == ["small_hit.wav"])
	player.flashing_left = 0.0
	player.hurt(player.global_position.x + 1.0, true)
	var spike: Array[String] = _heard()
	_check("spike hurt plays yow %s" % str(spike), spike == ["yow.wav"])

	# A real prickle says yow too.
	_fresh()
	await _wait(0.3)
	_heard()
	var prickle: Node3D = (load("res://scenes/prickle.tscn") as PackedScene).instantiate()
	prickle.position = Vector3(0, 0.3, 0)
	world.add_child(prickle)
	await _wait(0.3)
	var touched: Array[String] = _heard()
	_check("touching a prickle plays yow %s" % str(touched), "yow.wav" in touched)

	# Last heart gone: oh noo.
	_fresh()
	await _wait(0.3)
	_heard()
	for i in 3:
		player.flashing_left = 0.0
		player.hurt(player.global_position.x + 1.0)
	var died: Array[String] = _heard()
	_check("losing the last heart plays oh_noo %s" % str(died), not died.is_empty() and died[-1] == "oh_noo.wav")

	# Flying: the flying fart starts, and stops when he lands.
	_fresh()
	await _wait(0.3)
	_heard()
	player.start_flying(3.0, 16.0)
	await _wait(0.2)
	var flying: Array[String] = _heard()
	var was_playing: bool = sounds.flying_on
	player.stop_flying()
	await _wait(0.2)
	_check("flying plays flying_fart %s, stops after (%s -> %s)" % [str(flying), was_playing, sounds.flying_on],
		flying == ["flying_fart.wav"] and was_playing and not sounds.flying_on)

	world.free()
	world = null
	await _wait(0.2)

	# Losing to the boss: "oh noo", then "game over", and the fight starts again.
	var save: Node = root.get_node_or_null("SaveGame")
	if save != null:
		save.use_file("user://test_sounds_save.json")
		save.reset()
		save.mark_seen("sneezy_hello")  # skip the hello scene
	var stage: Stage = load("res://scenes/stage_1_4.tscn").instantiate()
	root.add_child(stage)
	player = stage.player
	sounds = player.get_node("Sounds") as PlayerSounds
	var boss: SneezyWeezy = stage.find_child("SneezyWeezy", true, false)
	await _wait(0.5)
	player.position = Vector3(9.0, 1.2, 0)
	await _wait(1.0)
	var fighting: bool = boss.state != SneezyWeezy.State.WAITING
	_heard()
	for i in 3:
		player.flashing_left = 0.0
		player.hurt(player.global_position.x + 1.0)
	await _wait(player.death_time + 2.0)  # he lies there for death_time first
	var lost: Array[String] = _heard()
	_check("losing the boss fight (fight was on: %s) plays oh_noo then game_over %s" % [fighting, str(lost)],
		fighting and lost.find("oh_noo.wav") >= 0 and lost.find("game_over.wav") > lost.find("oh_noo.wav"))
	stage.queue_free()
	await _wait(0.2)
	if save != null:
		save.reset()
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://test_sounds_save.json"))

	print("sound failures: %d" % failures)
	quit()
