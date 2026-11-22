extends SceneTree
# Checks the sound effects: every generated WAV is there and a sensible length, and the right
# sound name is started for a squash, a bean, a Golden Bean, a spring bounce and a boss sneeze.
# It can't hear anything: it checks which sound file was started (Sfx.played).

const FILES: Array[String] = [
	"bean_pickup", "golden_bean", "chilli_sizzle", "mega_can_glug", "burrito_blast", "landing_tada",
	"squash", "burpling_squish", "hiccup_hop", "gnome_throw", "mud_splat", "crow_caw", "cork_roll",
	"cork_pop", "bat_flap", "sneeze_windup", "sneeze_achoo", "cork_snort", "cork_bonk", "cork_shot",
	"boss_hit", "boss_defeat", "boing", "mega_boing", "flush", "can_open", "hoop_ding", "ring_ding",
	"fan_whoosh", "zap", "steam_hiss", "stamp_thump", "crumble_crack", "switch_click", "barrel_load",
	"cannon_boom", "warp_whoosh", "menu_move", "menu_accept", "pause_open", "pause_close",
	"fire_burp", "fireball_pop"]

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


## Sounds started since the last call.
func _heard() -> Array[String]:
	var list: Array[String] = Sfx.played.duplicate()
	Sfx.played.clear()
	return list


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


func _put(scene_name: String, pos: Vector3) -> Node3D:
	var thing: Node3D = (load("res://scenes/%s.tscn" % scene_name) as PackedScene).instantiate()
	thing.position = pos
	world.add_child(thing)
	return thing


func _run() -> void:
	_check_files()
	await _check_moments()
	await _check_boss()
	print("sfx failures: %d" % failures)
	quit()


func _check_files() -> void:
	for sfx_name in FILES:
		var path: String = "res://audio/sfx/%s.wav" % sfx_name
		var wav := load(path) as AudioStreamWAV
		_check("%s loads" % sfx_name, wav != null)
		if wav == null:
			continue
		# (Godot squeezes imported WAVs, so ask it for the length instead of counting bytes.)
		var seconds: float = wav.get_length()
		_check("%s is %.2f s, mono 22050 Hz" % [sfx_name, seconds],
			seconds >= 0.02 and seconds <= 1.0 and wav.mix_rate == 22050 and not wav.stereo)
	# The menu sounds can be found by name.
	_check("Sfx.named finds a file", Sfx.named("menu_move") != null and Sfx.named("nothing_here") == null)


func _check_moments() -> void:
	_fresh()
	await _wait(0.3)
	Sfx.played.clear()

	# Squashing enemies.
	var blob: Burpling = _put("burpling", Vector3(10, 0.45, 0))
	blob.squash()
	_check("squashing a Burpling plays burpling_squish", _heard() == ["burpling_squish.wav"])
	var hiccup: Burpling = _put("hiccup", Vector3(14, 0.45, 0))
	hiccup.squash()
	_check("squashing a Hiccup plays squash", _heard() == ["squash.wav"])
	var bot: Burpling = _put("cork_bot", Vector3(18, 0.5, 0))
	bot.squash()
	_check("squashing a Cork Bot plays cork_pop", _heard() == ["cork_pop.wav"])
	await _wait(0.5)
	Sfx.played.clear()

	# A bean and a Golden Bean, picked up by walking into them.
	_put("bean", player.position)
	await _wait(0.2)
	_check("a bean plays bean_pickup", "bean_pickup.wav" in _heard())
	var gold: Node3D = _put("golden_bean", player.position)
	await _wait(0.2)
	_check("a Golden Bean plays golden_bean", "golden_bean.wav" in _heard())
	_check("the Golden Bean is gone after", not is_instance_valid(gold) or gold.is_queued_for_deletion())

	# A spring under his feet.
	_put("spring", Vector3(0, 0, 0))
	await _wait(0.4)
	_check("a spring plays boing", "boing.wav" in _heard())

	# A toilet checkpoint.
	_put("toilet", player.position)
	await _wait(0.3)
	_check("a toilet plays flush", "flush.wav" in _heard())

	# Far away from the camera is quiet.
	var camera := Camera3D.new()
	world.add_child(camera)
	camera.make_current()
	camera.global_position = Vector3(0, 2, 12)
	await _wait(0.1)
	var far: Burpling = _put("burpling", Vector3(80, 0.45, 0))
	far.squash()
	_check("a squash 80 m off screen is silent", _heard().is_empty())
	var near: Burpling = _put("burpling", Vector3(10, 0.45, 0))
	near.squash()
	_check("a squash on screen is heard", _heard() == ["burpling_squish.wav"])
	_check("every sound slot is filled by the builder (Burpling squash_sound)", near.squash_sound != null)
	world.free()
	world = null


func _check_boss() -> void:
	var stage: Stage = load("res://scenes/stage_1_4.tscn").instantiate()
	root.add_child(stage)
	var save: Node = root.get_node_or_null("SaveGame")
	if save != null:
		save.use_file("user://test_sfx_save.json")
		save.reset()
	var boss := stage.find_child("SneezyWeezy", true, false) as SneezyWeezy
	await _wait(0.3)
	_check("Sneezy Weezy has her sounds", boss.windup_sound != null and boss.achoo_sound != null)
	# Stand him next to her so the camera is close enough to hear.
	stage.player.position = Vector3(25.0, 1.2, 0)
	stage.player.flashing_left = 1000.0
	await _wait(1.0)
	Sfx.played.clear()
	boss._sneeze(0, false, false, boss._run_id)
	await _wait(1.5)
	var heard: Array[String] = _heard()
	_check("a sneeze plays the wind-up and then the ACHOO (%s)" % str(heard),
		heard.size() >= 2 and heard[0] == "sneeze_windup.wav" and heard[1] == "sneeze_achoo.wav")
	stage.free()
