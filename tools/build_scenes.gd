extends SceneTree
# One-off builder: makes player.tscn, bean.tscn and test_level.tscn using the engine itself.


const SfxTable = preload("res://tools/sfx_table.gd")


func _init() -> void:
	_build_fireball()  # before the player, who carries it
	_build_player()
	_build_bean()
	_build_burpling()
	_build_toilet()
	_build_golden_bean()
	_build_bean_can()
	_build_powerups()
	_build_flight_things()
	_build_new_enemies()
	_run_extra_builders()
	_build_level()
	_build_stages()
	_build_world_map()
	_build_storybook()
	_build_start_menu()
	_build_boot()
	_register_project()
	quit()


func _save(root: Node, path: String) -> void:
	SfxTable.apply_for_scene(root, path)  # fill in the sound slots
	var packed := PackedScene.new()
	print("pack ", path, ": ", packed.pack(root))
	print("save ", path, ": ", ResourceSaver.save(packed, path))
	root.free()


func _build_player() -> void:
	var player := CharacterBody3D.new()
	player.name = "Player"
	player.set_script(load("res://scripts/player.gd"))

	# Visual sits at his feet so squashing keeps his feet on the ground.
	var visual := Node3D.new()
	visual.name = "Visual"
	visual.position = Vector3(0, -1, 0)
	player.add_child(visual)
	visual.owner = player

	# The old grey capsule, hidden now he has a real model. Tick it visible in the
	# editor to see the size of the shape that actually bumps into things.
	var mesh := MeshInstance3D.new()
	mesh.name = "MeshInstance3D"
	mesh.mesh = CapsuleMesh.new()
	mesh.position = Vector3(0, 1, 0)
	mesh.visible = false
	visual.add_child(mesh)
	mesh.owner = player

	# The real Fart Man model: a Mixamo rig with the Tripo textures. It is only a
	# costume: the capsule collision below still does all the bumping.
	var turn := Node3D.new()
	turn.name = "ModelTurn"
	turn.set_script(load("res://scripts/model_turn.gd"))
	visual.add_child(turn)
	turn.owner = player
	turn.call("face", true)
	var model: Node3D = (load("res://art/characters/fart_man/fart_man_rigged.fbx") as PackedScene).instantiate()
	model.name = "Model"
	var skeleton: Skeleton3D = model.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	var body_mesh: MeshInstance3D = model.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
	# The file is tiny (Mixamo centimetres). Scale it so he is 2 m tall, like his capsule.
	var model_scale: float = 2.0 / body_mesh.get_aabb().size.y
	model.scale = Vector3.ONE * model_scale
	turn.add_child(model)
	model.owner = player
	# We add things inside the model (belly spot, textures), so its insides must be saved.
	player.set_editable_instance(model, true)

	# The rigged file has no textures, so we give him his suit here.
	var folder: String = "res://art/characters/fart_man/"
	var suit := StandardMaterial3D.new()
	suit.albedo_texture = load(folder + "sci-fi_soldier_3d_model_color.jpg")
	suit.normal_enabled = true
	suit.normal_texture = load(folder + "sci-fi_soldier_3d_model_normal.jpg")
	suit.roughness_texture = load(folder + "sci-fi_soldier_3d_model_roughness.jpg")
	suit.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
	suit.metallic = 1.0
	suit.metallic_texture = load(folder + "sci-fi_soldier_3d_model_metallic.jpg")
	suit.metallic_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
	body_mesh.material_override = suit

	# His animation clips, cut from the Mixamo files (see tools/fart_man_clips.gd).
	var clip_builder: RefCounted = load("res://tools/fart_man_clips.gd").new()
	clip_builder.call("build")
	var clips := AnimationPlayer.new()
	clips.name = "Clips"
	model.add_child(clips)
	clips.owner = player
	clips.root_node = NodePath("..")
	clips.add_animation_library(&"", ResourceLoader.load("res://art/characters/fart_man/fart_man_clips.res", "", ResourceLoader.CACHE_MODE_REPLACE) as AnimationLibrary)
	clips.playback_default_blend_time = 0.15

	# Belly: a ball in his suit colour on his front that grows while charging.
	# It is pinned to his spine so it follows him when he crouches.
	var attach := BoneAttachment3D.new()
	attach.name = "BellyBone"
	skeleton.add_child(attach)
	attach.owner = player
	attach.bone_name = "mixamorig_Spine"
	var spot := Node3D.new()
	spot.name = "BellySpot"
	attach.add_child(spot)
	spot.owner = player
	# This cancels the model's big scale, so the belly stays life size: 0.95 m up, 0.3 m in front.
	var spine_rest: Transform3D = skeleton.get_bone_global_rest(skeleton.find_bone("mixamorig_Spine"))
	spot.transform = spine_rest.affine_inverse() * Transform3D(Basis().scaled(Vector3.ONE / model_scale), Vector3(0.0, 0.95, 0.3) / model_scale)
	var belly := MeshInstance3D.new()
	belly.name = "Belly"
	var ball := SphereMesh.new()
	var suit_green := StandardMaterial3D.new()
	suit_green.albedo_color = Color(0.36, 0.55, 0.2)
	ball.material = suit_green
	belly.mesh = ball
	belly.visible = false
	spot.add_child(belly)
	belly.owner = player

	var col := CollisionShape3D.new()
	col.name = "CollisionShape3D"
	col.shape = CapsuleShape3D.new()
	player.add_child(col)
	col.owner = player

	var tank := Node.new()
	tank.name = "GasTank"
	tank.set_script(load("res://scripts/gas_tank.gd"))
	player.add_child(tank)
	tank.owner = player

	var hearts := Node.new()
	hearts.name = "Hearts"
	hearts.set_script(load("res://scripts/hearts.gd"))
	player.add_child(hearts)
	hearts.owner = player
	player.set("hearts", hearts)

	# Spills beans whenever he is hurt (Sonic-ring style).
	var spill := Node.new()
	spill.name = "BeanSpill"
	spill.set_script(load("res://scripts/bean_spill.gd"))
	SfxTable.apply(spill, "bean_spill")
	player.add_child(spill)
	spill.owner = player

	# The upgrade helpers. All OFF until the shop upgrades switch them on (scripts/upgrade_applier.gd).
	for helper: Array in [["BeanMagnet", "bean_magnet", "bean_magnet"], ["SuperStomp", "super_stomp", "super_stomp"], ["SecretSniffer", "secret_sniffer", "secret_sniffer"]]:
		var node := Node.new()
		node.name = helper[0]
		node.set_script(load("res://scripts/%s.gd" % helper[1]))
		SfxTable.apply(node, helper[2])
		player.add_child(node)
		node.owner = player

	var trail := Node3D.new()
	trail.name = "FlameTrail"
	trail.set_script(load("res://scripts/flame_trail.gd"))
	trail.position = Vector3(0, -0.5, 0)
	player.add_child(trail)
	trail.owner = player

	var chilli := Node.new()
	chilli.name = "ChilliPower"
	chilli.set_script(load("res://scripts/chilli_power.gd"))
	player.add_child(chilli)
	chilli.owner = player
	chilli.set("body", visual)
	chilli.set("trail", trail)
	player.set("chilli", chilli)

	var fire_burp := Node.new()
	fire_burp.name = "FireBurpPower"
	fire_burp.set_script(load("res://scripts/fire_burp_power.gd"))
	player.add_child(fire_burp)
	fire_burp.owner = player
	fire_burp.set("fireball_scene", load("res://scenes/fireball.tscn"))
	player.set("fire_burp", fire_burp)

	var rainbow := Node3D.new()
	rainbow.name = "RainbowTrail"
	rainbow.set_script(load("res://scripts/flame_trail.gd"))
	rainbow.position = Vector3(-0.3, -0.3, 0)
	player.add_child(rainbow)
	rainbow.owner = player
	rainbow.set("rainbow", true)
	rainbow.set("puff_every", 0.03)
	rainbow.set("puff_life", 1.2)
	rainbow.set("puff_size", 1.3)

	var flight := Node.new()
	flight.name = "FlightPower"
	flight.set_script(load("res://scripts/flight_power.gd"))
	player.add_child(flight)
	flight.owner = player
	flight.set("trail", rainbow)
	# The Flight clip is already lying flat, so the whole body does not need to lean as well.
	flight.set("tilt_degrees", 0.0)
	player.set("flight", flight)

	# Animator: plays run, jump, charge, hurt... Grey box now, real model later.
	var animator := Node.new()
	animator.name = "Animator"
	animator.set_script(load("res://scripts/player_animator.gd"))
	player.add_child(animator)
	animator.owner = player
	animator.set("squash_target", visual)
	animator.set("animation_player", clips)

	# Sounds, recorded at home. Change them on the Sounds node in the editor.
	var sounds := Node.new()
	sounds.name = "Sounds"
	sounds.set_script(load("res://scripts/player_sounds.gd"))
	player.add_child(sounds)
	sounds.owner = player
	var hops: Array[AudioStream] = [load("res://audio/voice/jump_1.wav"), load("res://audio/voice/jump_2.wav")]
	sounds.set("hop_sounds", hops)
	# Short farts for the medium jump, long ones for the big jump. The "bits" were cut
	# out of the longer recordings so there are plenty to pick from.
	var trumps: Array[AudioStream] = [load("res://audio/voice/fart_1.wav"), load("res://audio/voice/farts/flying_bit_2.wav"),
		load("res://audio/voice/farts/flying_bit_4.wav"), load("res://audio/voice/farts/long_bit_1.wav")]
	var thunders: Array[AudioStream] = [load("res://audio/voice/long_fart_2.wav"), load("res://audio/voice/farts/flying_bit_1.wav"),
		load("res://audio/voice/farts/flying_bit_3.wav"), load("res://audio/voice/farts/flying_bit_5.wav")]
	sounds.set("trump_sounds", trumps)
	sounds.set("thunder_sounds", thunders)
	sounds.set("squeak_sound", load("res://audio/voice/long_fart.wav"))
	sounds.set("flying_sound", load("res://audio/voice/flying_fart.wav"))
	sounds.set("hurt_sound", load("res://audio/voice/small_hit.wav"))
	sounds.set("spike_sound", load("res://audio/voice/yow.wav"))
	sounds.set("death_sound", load("res://audio/voice/oh_noo.wav"))
	sounds.set("game_over_sound", load("res://audio/voice/game_over.wav"))
	sounds.set("clear_sound", load("res://audio/voice/wahoo.wav"))
	sounds.set("fire_burp_sound", load("res://audio/sfx/fire_burp.wav"))

	player.set("visual", visual)
	player.set("belly", belly)
	player.set("gas_tank", tank)
	_save(player, "res://scenes/player.tscn")


func _build_bean() -> void:
	var bean := Area3D.new()
	bean.name = "Bean"
	bean.set_script(load("res://scripts/bean.gd"))

	var mesh := MeshInstance3D.new()
	mesh.name = "MeshInstance3D"
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.2
	capsule.height = 0.7
	var brown := StandardMaterial3D.new()
	brown.albedo_color = Color(0.5, 0.27, 0.1)
	capsule.material = brown
	mesh.mesh = capsule
	mesh.rotation_degrees = Vector3(0, 0, 35)
	bean.add_child(mesh)
	mesh.owner = bean

	var col := CollisionShape3D.new()
	col.name = "CollisionShape3D"
	var sphere := SphereShape3D.new()
	sphere.radius = 0.45
	col.shape = sphere
	bean.add_child(col)
	col.owner = bean

	_save(bean, "res://scenes/bean.tscn")


func _build_burpling() -> void:
	var burp := Area3D.new()
	burp.name = "Burpling"
	burp.set_script(load("res://scripts/burpling.gd"))

	var mesh := MeshInstance3D.new()
	mesh.name = "MeshInstance3D"
	var blob := SphereMesh.new()
	blob.radius = 0.45
	blob.height = 0.8
	var green := StandardMaterial3D.new()
	green.albedo_color = Color(0.35, 0.75, 0.25)
	blob.material = green
	mesh.mesh = blob
	burp.add_child(mesh)
	mesh.owner = burp

	var col := CollisionShape3D.new()
	col.name = "CollisionShape3D"
	var sphere := SphereShape3D.new()
	sphere.radius = 0.45
	col.shape = sphere
	burp.add_child(col)
	col.owner = burp

	# Animator: plays "walk" and "squash". Grey box now, real model later.
	var animator := Node.new()
	animator.name = "Animator"
	animator.set_script(load("res://scripts/enemy_animator.gd"))
	burp.add_child(animator)
	animator.owner = burp
	animator.set("squash_target", mesh)

	burp.set("visual", mesh)
	burp.set("animator", animator)
	_save(burp, "res://scenes/burpling.tscn")


## Two googly eyes looking at the camera (the +z side).
func _eyes(parent: Node, owner_node: Node, y: float, spread: float, size: float, forward: float) -> void:
	for side in [-1.0, 1.0]:
		var white := SphereMesh.new()
		white.radius = size
		white.height = size * 2.0
		_mesh(parent, owner_node, "Eye", white, Color.WHITE, Vector3(side * spread, y, forward))
		var pupil := SphereMesh.new()
		pupil.radius = size * 0.5
		pupil.height = size
		_mesh(parent, owner_node, "Pupil", pupil, Color.BLACK, Vector3(side * spread, y, forward + size * 0.7))


## An enemy Area3D with a "Visual" holder, a sphere to touch, an Animator and a script.
func _enemy_base(node_name: String, script_path: String, hit_radius: float) -> Area3D:
	var enemy := Area3D.new()
	enemy.name = node_name
	enemy.set_script(load(script_path))
	var visual := Node3D.new()
	visual.name = "Visual"
	enemy.add_child(visual)
	visual.owner = enemy
	var col := CollisionShape3D.new()
	col.name = "CollisionShape3D"
	var sphere := SphereShape3D.new()
	sphere.radius = hit_radius
	col.shape = sphere
	enemy.add_child(col)
	col.owner = enemy
	var animator := Node.new()
	animator.name = "Animator"
	animator.set_script(load("res://scripts/enemy_animator.gd"))
	enemy.add_child(animator)
	animator.owner = enemy
	animator.set("squash_target", visual)
	enemy.set("visual", visual)
	enemy.set("animator", animator)
	return enemy


func _build_new_enemies() -> void:
	# Hiccup: a sunny orange blob that hops on the spot.
	var hiccup := _enemy_base("Hiccup", "res://scripts/hiccup.gd", 0.45)
	var hv: Node3D = hiccup.get_node("Visual")
	var hb := SphereMesh.new()
	hb.radius = 0.45
	hb.height = 0.9
	_mesh(hv, hiccup, "Body", hb, Color(1.0, 0.6, 0.15), Vector3.ZERO)
	_eyes(hv, hiccup, 0.12, 0.17, 0.12, 0.34)
	var mouth := SphereMesh.new()
	mouth.radius = 0.08
	mouth.height = 0.16
	_mesh(hv, hiccup, "Mouth", mouth, Color(0.5, 0.1, 0.1), Vector3(0, -0.12, 0.42))
	hiccup.set("walk_speed", 0.0)
	_save(hiccup, "res://scenes/hiccup.tscn")

	# Grumpy Gnome: blue jacket, red pointy hat, big white beard.
	var gnome := _enemy_base("Gnome", "res://scripts/gnome.gd", 0.5)
	var gv: Node3D = gnome.get_node("Visual")
	var jacket := CylinderMesh.new()
	jacket.top_radius = 0.3
	jacket.bottom_radius = 0.42
	jacket.height = 0.7
	_mesh(gv, gnome, "Jacket", jacket, Color(0.2, 0.35, 0.8), Vector3(0, -0.15, 0))
	var face := SphereMesh.new()
	face.radius = 0.28
	face.height = 0.56
	_mesh(gv, gnome, "Face", face, Color(0.95, 0.75, 0.6), Vector3(0, 0.38, 0))
	var hat := CylinderMesh.new()
	hat.top_radius = 0.0
	hat.bottom_radius = 0.32
	hat.height = 0.6
	_mesh(gv, gnome, "Hat", hat, Color(0.85, 0.1, 0.1), Vector3(0, 0.88, 0))
	var beard := BoxMesh.new()
	beard.size = Vector3(0.4, 0.35, 0.15)
	_mesh(gv, gnome, "Beard", beard, Color(0.95, 0.95, 0.95), Vector3(0, 0.15, 0.22))
	_eyes(gv, gnome, 0.45, 0.1, 0.06, 0.24)
	gnome.set("walk_speed", 0.0)
	gnome.set("stomp_width", 0.7)
	_save(gnome, "res://scenes/gnome.tscn")

	# Crow: a black bird with orange beak and flappy wing slabs.
	var crow := _enemy_base("Crow", "res://scripts/flapper.gd", 0.5)
	var cv: Node3D = crow.get_node("Visual")
	var crow_body := SphereMesh.new()
	crow_body.radius = 0.4
	crow_body.height = 0.8
	_mesh(cv, crow, "Body", crow_body, Color(0.15, 0.15, 0.2), Vector3.ZERO)
	for side in [-1.0, 1.0]:
		var wing := BoxMesh.new()
		wing.size = Vector3(0.2, 0.08, 1.1)
		var wing_mesh := _mesh(cv, crow, "Wing", wing, Color(0.1, 0.1, 0.15), Vector3(0, 0.1, side * 0.6))
		wing_mesh.rotation_degrees = Vector3(side * 20.0, 0, 0)
	var beak := CylinderMesh.new()
	beak.top_radius = 0.0
	beak.bottom_radius = 0.12
	beak.height = 0.35
	var beak_mesh := _mesh(cv, crow, "Beak", beak, Color(1.0, 0.65, 0.1), Vector3(0.45, 0.0, 0.0))
	beak_mesh.rotation_degrees = Vector3(0, 0, -90)
	_eyes(cv, crow, 0.12, 0.14, 0.09, 0.28)
	crow.set("walk_speed", 3.0)
	crow.set("patrol_distance", 3.0)
	_save(crow, "res://scenes/crow.tscn")

	# Prickle: a small spiky ball sitting on the ground. Always hurts.
	var prickle := Area3D.new()
	prickle.name = "Prickle"
	prickle.set_script(load("res://scripts/hazard.gd"))
	var ball := SphereMesh.new()
	ball.radius = 0.3
	ball.height = 0.6
	_mesh(prickle, prickle, "Ball", ball, Color(0.55, 0.15, 0.3), Vector3.ZERO)
	for i in 7:
		var spike := CylinderMesh.new()
		spike.top_radius = 0.0
		spike.bottom_radius = 0.1
		spike.height = 0.4
		var angle: float = PI * i / 6.0
		var spike_mesh := _mesh(prickle, prickle, "Spike%d" % (i + 1), spike, Color(0.85, 0.25, 0.4),
			Vector3(cos(angle), sin(angle), 0) * 0.35)
		spike_mesh.rotation = Vector3(0, 0, angle - PI / 2.0)
	var prickle_col := CollisionShape3D.new()
	prickle_col.name = "CollisionShape3D"
	var prickle_shape := SphereShape3D.new()
	prickle_shape.radius = 0.35
	prickle_col.shape = prickle_shape
	prickle.add_child(prickle_col)
	prickle_col.owner = prickle
	_save(prickle, "res://scenes/prickle.tscn")

	# Bounce pad: a red mushroom with white spots.
	var pad := Area3D.new()
	pad.name = "BouncePad"
	pad.set_script(load("res://scripts/bounce_pad.gd"))
	var stalk := CylinderMesh.new()
	stalk.top_radius = 0.25
	stalk.bottom_radius = 0.3
	stalk.height = 0.5
	_mesh(pad, pad, "Stalk", stalk, Color(0.95, 0.9, 0.8), Vector3(0, 0.25, 0))
	var cap := Node3D.new()
	cap.name = "Cap"
	cap.position = Vector3(0, 0.45, 0)
	pad.add_child(cap)
	cap.owner = pad
	var dome := SphereMesh.new()
	dome.radius = 0.8
	dome.height = 0.8
	_mesh(cap, pad, "Dome", dome, Color(0.9, 0.15, 0.15), Vector3.ZERO)
	for spot in [Vector3(0.3, 0.3, 0.4), Vector3(-0.35, 0.25, 0.35), Vector3(0.0, 0.38, -0.3)]:
		var dot := SphereMesh.new()
		dot.radius = 0.12
		dot.height = 0.24
		_mesh(cap, pad, "Spot", dot, Color.WHITE, spot)
	var pad_col := CollisionShape3D.new()
	pad_col.name = "CollisionShape3D"
	var pad_shape := BoxShape3D.new()
	pad_shape.size = Vector3(1.4, 0.9, 2.0)
	pad_col.shape = pad_shape
	pad_col.position = Vector3(0, 0.45, 0)
	pad.add_child(pad_col)
	pad_col.owner = pad
	pad.set("cap", cap)
	_save(pad, "res://scenes/bounce_pad.tscn")


func _mesh(parent: Node, owner_node: Node, mesh_name: String, shape: Mesh, color: Color, pos: Vector3) -> MeshInstance3D:
	var paint := StandardMaterial3D.new()
	paint.albedo_color = color
	shape.set("material", paint)
	var mesh := MeshInstance3D.new()
	mesh.name = mesh_name
	mesh.mesh = shape
	mesh.position = pos
	parent.add_child(mesh)
	mesh.owner = owner_node
	return mesh


func _build_toilet() -> void:
	var toilet := Area3D.new()
	toilet.name = "Toilet"
	toilet.set_script(load("res://scripts/toilet.gd"))

	var visual := Node3D.new()
	visual.name = "Visual"
	toilet.add_child(visual)
	visual.owner = toilet

	var bowl := BoxMesh.new()
	bowl.size = Vector3(0.9, 0.7, 0.8)
	_mesh(visual, toilet, "Bowl", bowl, Color(0.95, 0.95, 0.95), Vector3(0.1, 0.35, 0))
	var tank := BoxMesh.new()
	tank.size = Vector3(0.35, 1.0, 0.8)
	_mesh(visual, toilet, "Tank", tank, Color(0.95, 0.95, 0.95), Vector3(-0.5, 0.9, 0))

	var col := CollisionShape3D.new()
	col.name = "CollisionShape3D"
	var box := BoxShape3D.new()
	box.size = Vector3(1.4, 3.0, 4.0)
	col.shape = box
	col.position = Vector3(0, 1.5, 0)
	toilet.add_child(col)
	col.owner = toilet

	toilet.set("visual", visual)
	_save(toilet, "res://scenes/toilet.tscn")


func _build_golden_bean() -> void:
	var bean := Area3D.new()
	bean.name = "GoldenBean"
	bean.set_script(load("res://scripts/golden_bean.gd"))

	var capsule := CapsuleMesh.new()
	capsule.radius = 0.3
	capsule.height = 1.0
	var mesh := _mesh(bean, bean, "MeshInstance3D", capsule, Color(1.0, 0.8, 0.1), Vector3.ZERO)
	mesh.rotation_degrees = Vector3(0, 0, 35)

	var col := CollisionShape3D.new()
	col.name = "CollisionShape3D"
	var sphere := SphereShape3D.new()
	sphere.radius = 0.6
	col.shape = sphere
	bean.add_child(col)
	col.owner = bean

	_save(bean, "res://scenes/golden_bean.tscn")


## The Fire Burp fireball: a glowing orange ball that rolls. Pieces: a spinning Ball (with
## yellow spots so you can see it turn), a sphere collider, and an Area3D that finds enemies.
func _build_fireball() -> void:
	var fireball := CharacterBody3D.new()
	fireball.name = "Fireball"
	fireball.set_script(load("res://scripts/fireball.gd"))
	var spin := Node3D.new()
	spin.name = "Ball"
	fireball.add_child(spin)
	spin.owner = fireball
	var orb := SphereMesh.new()
	orb.radius = 0.35
	orb.height = 0.7
	var glow := _mesh(spin, fireball, "Orb", orb, Color(1.0, 0.45, 0.05), Vector3.ZERO)
	var glow_paint := orb.material as StandardMaterial3D
	glow_paint.emission_enabled = true
	glow_paint.emission = Color(1.0, 0.45, 0.05)
	glow_paint.emission_energy_multiplier = 1.6
	glow.name = "Orb"
	var spot_spots: Array[Vector3] = [Vector3(0.3, 0.15, 0.0), Vector3(-0.2, 0.25, 0.1), Vector3(-0.1, -0.3, 0.1), Vector3(0.1, 0.0, 0.33)]
	for i in spot_spots.size():
		var dot := SphereMesh.new()
		dot.radius = 0.1
		dot.height = 0.2
		var d := _mesh(spin, fireball, "Spot%d" % i, dot, Color(1.0, 0.9, 0.2), spot_spots[i])
		var dot_paint := dot.material as StandardMaterial3D
		dot_paint.emission_enabled = true
		dot_paint.emission = Color(1.0, 0.9, 0.2)
		d.name = "Spot%d" % i
	var col := CollisionShape3D.new()
	col.name = "CollisionShape3D"
	var sphere := SphereShape3D.new()
	sphere.radius = 0.35
	col.shape = sphere
	fireball.add_child(col)
	col.owner = fireball
	var area := Area3D.new()
	area.name = "SquashArea"
	fireball.add_child(area)
	area.owner = fireball
	var area_col := CollisionShape3D.new()
	area_col.name = "CollisionShape3D"
	var area_shape := SphereShape3D.new()
	area_shape.radius = 0.5
	area_col.shape = area_shape
	area.add_child(area_col)
	area_col.owner = fireball
	fireball.set("ball", spin)
	fireball.set("squash_area", area)
	_save(fireball, "res://scenes/fireball.tscn")


func _pickup(scene_name: String, script_path: String) -> Area3D:
	var pickup := Area3D.new()
	pickup.name = scene_name
	pickup.set_script(load(script_path))
	var col := CollisionShape3D.new()
	col.name = "CollisionShape3D"
	var sphere := SphereShape3D.new()
	sphere.radius = 0.6
	col.shape = sphere
	pickup.add_child(col)
	col.owner = pickup
	return pickup


func _build_powerups() -> void:
	# Chilli Pepper: a long red pepper with a green stalk.
	var chilli := _pickup("Chilli", "res://scripts/chilli.gd")
	var pepper := CapsuleMesh.new()
	pepper.radius = 0.18
	pepper.height = 1.0
	var body := _mesh(chilli, chilli, "Pepper", pepper, Color(0.9, 0.1, 0.1), Vector3.ZERO)
	body.rotation_degrees = Vector3(0, 0, 40)
	var stalk := BoxMesh.new()
	stalk.size = Vector3(0.12, 0.3, 0.12)
	var stalk_mesh := _mesh(chilli, chilli, "Stalk", stalk, Color(0.2, 0.6, 0.2), Vector3(-0.38, 0.45, 0))
	stalk_mesh.rotation_degrees = Vector3(0, 0, 40)
	_save(chilli, "res://scenes/chilli.tscn")

	# Heart: a red heart made of two round bumps and a point, on a "Visual" that spins and bobs.
	var heart := _pickup("Heart", "res://scripts/heart_pickup.gd")
	var heart_visual := Node3D.new()
	heart_visual.name = "Visual"
	heart.add_child(heart_visual)
	heart_visual.owner = heart
	var red := Color(0.95, 0.12, 0.25)
	for side in [-1.0, 1.0]:
		var bump := SphereMesh.new()
		bump.radius = 0.24
		bump.height = 0.48
		_mesh(heart_visual, heart, "Bump", bump, red, Vector3(side * 0.18, 0.12, 0))
	var point := BoxMesh.new()
	point.size = Vector3(0.36, 0.36, 0.3)
	var point_mesh := _mesh(heart_visual, heart, "Point", point, red, Vector3(0, -0.02, 0))
	point_mesh.rotation_degrees = Vector3(0, 0, 45)
	heart.set("visual", heart_visual)
	_save(heart, "res://scenes/heart.tscn")

	# Hot Sauce: a small red bottle with a yellow cap.
	var sauce := _pickup("HotSauce", "res://scripts/hot_sauce.gd")
	var bottle := CylinderMesh.new()
	bottle.top_radius = 0.16
	bottle.bottom_radius = 0.22
	bottle.height = 0.6
	_mesh(sauce, sauce, "Bottle", bottle, Color(0.85, 0.08, 0.05), Vector3.ZERO)
	var neck := CylinderMesh.new()
	neck.top_radius = 0.09
	neck.bottom_radius = 0.12
	neck.height = 0.2
	_mesh(sauce, sauce, "Neck", neck, Color(0.85, 0.08, 0.05), Vector3(0, 0.38, 0))
	var cap := CylinderMesh.new()
	cap.top_radius = 0.1
	cap.bottom_radius = 0.1
	cap.height = 0.12
	_mesh(sauce, sauce, "Cap", cap, Color(1.0, 0.85, 0.1), Vector3(0, 0.52, 0))
	var label := BoxMesh.new()
	label.size = Vector3(0.3, 0.25, 0.02)
	_mesh(sauce, sauce, "Label", label, Color(1.0, 0.9, 0.5), Vector3(0, 0.0, 0.2))
	_save(sauce, "res://scenes/hot_sauce.tscn")


func _build_flight_things() -> void:
	# Rocket Burrito: a fat tan roll with a red rocket nose.
	var burrito := _pickup("RocketBurrito", "res://scripts/rocket_burrito.gd")
	var roll := CapsuleMesh.new()
	roll.radius = 0.3
	roll.height = 1.2
	var roll_mesh := _mesh(burrito, burrito, "Roll", roll, Color(0.9, 0.75, 0.5), Vector3.ZERO)
	roll_mesh.rotation_degrees = Vector3(0, 0, -60)
	var nose := CylinderMesh.new()
	nose.top_radius = 0.0
	nose.bottom_radius = 0.3
	nose.height = 0.5
	var nose_mesh := _mesh(burrito, burrito, "Nose", nose, Color(0.9, 0.15, 0.1), Vector3(0.62, 0.36, 0))
	nose_mesh.rotation_degrees = Vector3(0, 0, -60)
	_save(burrito, "res://scenes/rocket_burrito.tscn")

	# Hazard: a dark spiky ball. Hurts to touch, can't be squashed.
	var hazard := Area3D.new()
	hazard.name = "SpikyBall"
	hazard.set_script(load("res://scripts/hazard.gd"))
	var ball := SphereMesh.new()
	ball.radius = 0.8
	ball.height = 1.6
	_mesh(hazard, hazard, "Ball", ball, Color(0.25, 0.1, 0.3), Vector3.ZERO)
	for i in 6:
		var spike := CylinderMesh.new()
		spike.top_radius = 0.0
		spike.bottom_radius = 0.25
		spike.height = 0.7
		var angle: float = TAU * i / 6.0
		var spike_mesh := _mesh(hazard, hazard, "Spike%d" % (i + 1), spike, Color(0.25, 0.1, 0.3),
			Vector3(sin(angle), cos(angle), 0) * 1.0)
		spike_mesh.rotation = Vector3(0, 0, -angle)
	var hazard_col := CollisionShape3D.new()
	hazard_col.name = "CollisionShape3D"
	var hazard_shape := SphereShape3D.new()
	hazard_shape.radius = 0.9
	hazard_col.shape = hazard_shape
	hazard.add_child(hazard_col)
	hazard_col.owner = hazard
	_save(hazard, "res://scenes/spiky_ball.tscn")

	# Hoop: a gold ring to fly through, turned a little so it reads from the side.
	var hoop := Area3D.new()
	hoop.name = "Hoop"
	hoop.set_script(load("res://scripts/hoop.gd"))
	var torus := TorusMesh.new()
	torus.inner_radius = 1.5
	torus.outer_radius = 1.85
	var ring := _mesh(hoop, hoop, "Ring", torus, Color(1.0, 0.8, 0.1), Vector3.ZERO)
	ring.rotation_degrees = Vector3(0, 30, 90)
	var hoop_col := CollisionShape3D.new()
	hoop_col.name = "CollisionShape3D"
	var hoop_shape := BoxShape3D.new()
	hoop_shape.size = Vector3(0.6, 2.6, 4.0)
	hoop_col.shape = hoop_shape
	hoop.add_child(hoop_col)
	hoop_col.owner = hoop
	hoop.set("ring", ring)
	_save(hoop, "res://scenes/hoop.tscn")

	# Landing zone: a tall see-through green curtain that ends the flight.
	var zone := Area3D.new()
	zone.name = "LandingZone"
	zone.set_script(load("res://scripts/landing_zone.gd"))
	var curtain := BoxMesh.new()
	curtain.size = Vector3(0.3, 40, 4)
	var curtain_mesh := _mesh(zone, zone, "Curtain", curtain, Color(0.3, 1.0, 0.4, 0.25), Vector3(0, 20, 0))
	(curtain_mesh.mesh.get("material") as StandardMaterial3D).transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var zone_col := CollisionShape3D.new()
	zone_col.name = "CollisionShape3D"
	var zone_shape := BoxShape3D.new()
	zone_shape.size = Vector3(2, 40, 4)
	zone_col.shape = zone_shape
	zone_col.position = Vector3(0, 20, 0)
	zone.add_child(zone_col)
	zone_col.owner = zone
	_save(zone, "res://scenes/landing_zone.tscn")


func _build_bean_can() -> void:
	# The can is 3.5 m tall: too high for a Trump, just right for a Thunder.
	var can := StaticBody3D.new()
	can.name = "BeanCan"
	can.set_script(load("res://scripts/bean_can.gd"))

	var tin := CylinderMesh.new()
	tin.top_radius = 1.2
	tin.bottom_radius = 1.2
	tin.height = 3.5
	_mesh(can, can, "Tin", tin, Color(0.8, 0.2, 0.15), Vector3(0, 1.75, 0))

	var col := CollisionShape3D.new()
	col.name = "CollisionShape3D"
	var cyl := CylinderShape3D.new()
	cyl.radius = 1.2
	cyl.height = 3.5
	col.shape = cyl
	col.position = Vector3(0, 1.75, 0)
	can.add_child(col)
	col.owner = can

	var lid_mesh := CylinderMesh.new()
	lid_mesh.top_radius = 1.3
	lid_mesh.bottom_radius = 1.3
	lid_mesh.height = 0.2
	var lid := _mesh(can, can, "Lid", lid_mesh, Color(0.85, 0.85, 0.9), Vector3(0, 3.6, 0))

	var sensor := Area3D.new()
	sensor.name = "LidSensor"
	sensor.position = Vector3(0, 4.0, 0)
	can.add_child(sensor)
	sensor.owner = can
	var sensor_col := CollisionShape3D.new()
	sensor_col.name = "CollisionShape3D"
	var sensor_shape := CylinderShape3D.new()
	sensor_shape.radius = 1.1
	sensor_shape.height = 0.8
	sensor_col.shape = sensor_shape
	sensor.add_child(sensor_col)
	sensor_col.owner = can

	can.set("lid", lid)
	can.set("lid_sensor", sensor)
	_save(can, "res://scenes/bean_can.tscn")


func _place(root: Node, parent: Node, scene_path: String, node_name: String, pos: Vector3) -> Node3D:
	var thing: Node3D = (load(scene_path) as PackedScene).instantiate()
	thing.name = node_name
	thing.position = pos
	parent.add_child(thing)
	thing.owner = root
	return thing


func _box(root: Node, box_name: String, size: Vector3, pos: Vector3) -> void:
	var body := StaticBody3D.new()
	body.name = box_name
	body.position = pos
	root.add_child(body)
	body.owner = root

	var mesh := MeshInstance3D.new()
	mesh.name = "MeshInstance3D"
	var box_mesh := BoxMesh.new()
	box_mesh.size = size
	mesh.mesh = box_mesh
	body.add_child(mesh)
	mesh.owner = root

	var col := CollisionShape3D.new()
	col.name = "CollisionShape3D"
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)
	col.owner = root


## The flying bit: from x = 42 to x = 226, no ground, sky between y = 3 and y = 16.
func _build_flight_section(root: Node) -> void:
	var sky := Node3D.new()
	sky.name = "FlightSection"
	root.add_child(sky)
	sky.owner = root

	# Two wavy lines of beans to follow.
	var n: int = 0
	for x in range(50, 101, 3):
		n += 1
		_place(root, sky, "res://scenes/bean.tscn", "SkyBean%d" % n, Vector3(x, 9.5 + 4.0 * sin(x * 0.12), 0))
	for x in range(130, 176, 3):
		n += 1
		_place(root, sky, "res://scenes/bean.tscn", "SkyBean%d" % n, Vector3(x, 9.5 - 4.5 * sin(x * 0.1), 0))

	# Hoops to fly through.
	var hoop_spots: Array[Vector2] = [Vector2(70, 12.5), Vector2(108, 6), Vector2(142, 11), Vector2(182, 7), Vector2(210, 10)]
	for i in hoop_spots.size():
		_place(root, sky, "res://scenes/hoop.tscn", "Hoop%d" % (i + 1), Vector3(hoop_spots[i].x, hoop_spots[i].y, 0))

	# Spiky balls to dodge.
	var spike_spots: Array[Vector2] = [Vector2(88, 4.5), Vector2(118, 13), Vector2(124, 5), Vector2(160, 14),
		Vector2(165, 4), Vector2(196, 12.5), Vector2(202, 5)]
	for i in spike_spots.size():
		_place(root, sky, "res://scenes/spiky_ball.tscn", "SpikyBall%d" % (i + 1), Vector3(spike_spots[i].x, spike_spots[i].y, 0))

	# Burplings floating in the sky: drop onto them for a bounce.
	var sky_burp_spots: Array[Vector2] = [Vector2(112, 9), Vector2(152, 7), Vector2(174, 12)]
	for i in sky_burp_spots.size():
		var burp := _place(root, sky, "res://scenes/burpling.tscn", "SkyBurpling%d" % (i + 1), Vector3(sky_burp_spots[i].x, sky_burp_spots[i].y, 0))
		burp.set("patrol_distance", 1.0)

	_place(root, sky, "res://scenes/landing_zone.tscn", "LandingZone", Vector3(226, 0, 0))

	# The landscape far below and behind: a big green field with hills and houses.
	# Just for looking at. Nothing here can be touched.
	var land := Node3D.new()
	land.name = "Landscape"
	sky.add_child(land)
	land.owner = root
	var field := BoxMesh.new()
	field.size = Vector3(500, 1, 260)
	_mesh(land, root, "Field", field, Color(0.35, 0.65, 0.3), Vector3(190, -9, 0))
	var rng := RandomNumberGenerator.new()
	rng.seed = 6
	for i in 90:
		var is_house: bool = i % 3 == 0
		var shape := BoxMesh.new()
		var height: float = rng.randf_range(3, 7) if is_house else rng.randf_range(4, 14)
		var width: float = rng.randf_range(3, 5) if is_house else rng.randf_range(8, 18)
		shape.size = Vector3(width, height, width)
		var color: Color = Color(0.85, 0.5, 0.4) if is_house else Color(0.25, 0.55, 0.25)
		color = color.lightened(rng.randf_range(0.0, 0.25))
		_mesh(land, root, ("House%d" if is_house else "Hill%d") % i, shape, color,
			# Both sides of the flight path, and on ahead past the landing, never in the way.
			Vector3(rng.randf_range(20, 400), -8.5 + height * 0.5, rng.randf_range(14, 90) * (1.0 if i % 2 == 0 else -1.0)))


func _build_level() -> void:
	var root := Node3D.new()
	root.name = "TestLevel"
	root.set_script(load("res://scripts/stage.gd"))
	root.set("stage_id", "1-1")

	_box(root, "Floor", Vector3(60, 1, 4), Vector3(12, 0, 0))
	# Three ledges: one each for Toot, Trump and Thunder to reach.
	_box(root, "TootLedge", Vector3(3, 0.5, 4), Vector3(2, 1.05, 0))
	_box(root, "TrumpLedge", Vector3(3, 0.5, 4), Vector3(9, 2.55, 0))
	_box(root, "ThunderLedge", Vector3(3, 0.5, 4), Vector3(16, 4.85, 0))

	var player: Node3D = load("res://scenes/player.tscn").instantiate()
	player.position = Vector3(-6, 2, 0)
	root.add_child(player)
	player.owner = root

	# Beans: two on the floor, one on top of each ledge.
	var beans := Node3D.new()
	beans.name = "Beans"
	root.add_child(beans)
	beans.owner = root
	var bean_scene: PackedScene = load("res://scenes/bean.tscn")
	var spots: Array[Vector3] = [
		Vector3(-3, 1.3, 0), Vector3(5.5, 1.3, 0),
		Vector3(2, 2.1, 0), Vector3(9, 3.6, 0), Vector3(16, 5.9, 0),
	]
	for i in spots.size():
		var bean: Node3D = bean_scene.instantiate()
		bean.name = "Bean%d" % (i + 1)
		bean.position = spots[i]
		beans.add_child(bean)
		bean.owner = root

	# Burplings waddling about on the floor. [x position, how far they walk each way]
	var enemies := Node3D.new()
	enemies.name = "Enemies"
	root.add_child(enemies)
	enemies.owner = root
	var burp_scene: PackedScene = load("res://scenes/burpling.tscn")
	# The last three stand in a row after the Chilli, ready to be run through.
	var burp_spots: Array[Vector2] = [Vector2(-2, 1.5), Vector2(5.5, 1.2), Vector2(12.5, 1.2),
		Vector2(25.5, 0.8), Vector2(28, 0.8), Vector2(30.5, 0.8)]
	for i in burp_spots.size():
		var burp: Node3D = burp_scene.instantiate()
		burp.name = "Burpling%d" % (i + 1)
		burp.position = Vector3(burp_spots[i].x, 0.9, 0)
		burp.set("patrol_distance", burp_spots[i].y)
		enemies.add_child(burp)
		burp.owner = root

	# Checkpoint toilet, three Golden Beans and the Bean Can at the end.
	_place(root, root, "res://scenes/toilet.tscn", "Toilet", Vector3(20, 0.5, 0))
	var golden := Node3D.new()
	golden.name = "GoldenBeans"
	root.add_child(golden)
	golden.owner = root
	# One hidden behind the start, one high above the Thunder ledge, one needing a Thunder.
	_place(root, golden, "res://scenes/golden_bean.tscn", "GoldenBean1", Vector3(-12, 1.5, 0))
	_place(root, golden, "res://scenes/golden_bean.tscn", "GoldenBean2", Vector3(16, 8.0, 0))
	_place(root, golden, "res://scenes/golden_bean.tscn", "GoldenBean3", Vector3(188, 14.5, 0))
	root.set("player", player)
	_build_flight_section(root)
	# After the flight: solid ground, a second toilet, and the Bean Can at the very end.
	_box(root, "LandingGround", Vector3(40, 1, 4), Vector3(242, 0, 0))
	_place(root, root, "res://scenes/toilet.tscn", "Toilet2", Vector3(232, 0.5, 0))
	_place(root, root, "res://scenes/bean_can.tscn", "BeanCan", Vector3(250, 0.5, 0))

	# Power-ups: a Chilli just after the toilet, a Heart just before the big can.
	var powerups := Node3D.new()
	powerups.name = "PowerUps"
	root.add_child(powerups)
	powerups.owner = root
	_place(root, powerups, "res://scenes/chilli.tscn", "Chilli", Vector3(22.5, 1.4, 0))
	_place(root, powerups, "res://scenes/heart.tscn", "Heart", Vector3(241, 1.3, 0))
	# The Rocket Burrito sits at the end of the first bit of ground.
	_place(root, powerups, "res://scenes/rocket_burrito.tscn", "RocketBurrito", Vector3(38, 1.6, 0))

	var camera := Camera3D.new()
	camera.name = "Camera3D"
	camera.set_script(load("res://scripts/follow_camera.gd"))
	camera.position = Vector3(-6, 5, 16)
	root.add_child(camera)
	camera.owner = root
	camera.set("target", player)

	var light := DirectionalLight3D.new()
	light.name = "DirectionalLight3D"
	light.rotation_degrees = Vector3(-45, -30, 0)
	light.shadow_enabled = true
	root.add_child(light)
	light.owner = root

	# On-screen gas bar.
	var hud := CanvasLayer.new()
	hud.name = "HUD"
	root.add_child(hud)
	hud.owner = root

	var label := Label.new()
	label.name = "GasLabel"
	label.text = "GAS"
	label.position = Vector2(20, 18)
	label.add_theme_font_size_override("font_size", 24)
	hud.add_child(label)
	label.owner = root

	var bar := ProgressBar.new()
	bar.name = "GasBar"
	bar.set_script(load("res://scripts/gas_bar.gd"))
	bar.position = Vector2(90, 20)
	bar.size = Vector2(300, 30)
	bar.show_percentage = false
	hud.add_child(bar)
	bar.owner = root
	bar.set("player", player)

	var hearts_bar := HBoxContainer.new()
	hearts_bar.name = "HeartsBar"
	hearts_bar.set_script(load("res://scripts/hearts_bar.gd"))
	hearts_bar.position = Vector2(20, 64)
	hearts_bar.add_theme_constant_override("separation", 8)
	hud.add_child(hearts_bar)
	hearts_bar.owner = root
	hearts_bar.set("player", player)

	var gold_bar := HBoxContainer.new()
	gold_bar.name = "GoldenBeanBar"
	gold_bar.set_script(load("res://scripts/golden_bean_bar.gd"))
	gold_bar.position = Vector2(20, 104)
	gold_bar.add_theme_constant_override("separation", 8)
	hud.add_child(gold_bar)
	gold_bar.owner = root
	gold_bar.set("full_color", Color(1.0, 0.8, 0.1))
	gold_bar.set("stage", root)

	# How many beans he has grabbed in this stage (under the Golden Beans, away from the hint and score).
	var bean_counter := HBoxContainer.new()
	bean_counter.name = "BeanCounter"
	bean_counter.set_script(load("res://scripts/bean_counter.gd"))
	bean_counter.position = Vector2(20, 138)
	hud.add_child(bean_counter)
	bean_counter.owner = root
	bean_counter.set("stage", root)

	var score := Label.new()
	score.name = "ScoreLabel"
	score.set_script(load("res://scripts/score_label.gd"))
	score.text = "SCORE 0"
	score.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	score.add_theme_font_size_override("font_size", 32)
	score.add_theme_color_override("font_outline_color", Color.BLACK)
	score.add_theme_constant_override("outline_size", 8)
	score.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	score.position = Vector2(-320, 16)
	score.size = Vector2(300, 40)
	score.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	hud.add_child(score)
	score.owner = root
	score.set("stage", root)

	var banner := Label.new()
	banner.name = "StageClearBanner"
	banner.set_script(load("res://scripts/stage_clear_banner.gd"))
	banner.text = "STAGE CLEAR!"
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.add_theme_font_size_override("font_size", 64)
	banner.add_theme_color_override("font_outline_color", Color.BLACK)
	banner.add_theme_constant_override("outline_size", 12)
	banner.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	banner.position.y = 120
	banner.grow_horizontal = Control.GROW_DIRECTION_BOTH
	hud.add_child(banner)
	banner.owner = root
	banner.set("stage", root)
	SfxTable.apply(banner, "stage_clear_banner")

	_save(root, "res://scenes/test_level.tscn")


## A label with big outlined letters, added to a parent.
func _big_label(root: Node, label_name: String, text: String, size: int) -> Label:
	var label := Label.new()
	label.name = label_name
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", maxi(size / 6, 4))
	root.add_child(label)
	label.owner = root
	return label


func _build_world_map() -> void:
	var root := Control.new()
	root.name = "WorldMap"
	root.set_script(load("res://scripts/world_map.gd"))
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# The 3D diorama, the stops, the Complex2000 and the camera (see tools/world_map_3d.gd).
	var diorama: Dictionary = load("res://tools/world_map_3d.gd").new().call("build", root)

	# Stop name big at the top, the world's name under it, beans and score at the bottom,
	# COMING SOON in the middle and the GO ABOARD hint in the corner.
	var title := _big_label(root, "NameLabel", "", 64)
	title.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	title.custom_minimum_size.y = 90
	title.position.y = 20
	var world_name := _big_label(root, "WorldLabel", "", 44)
	world_name.add_theme_color_override("font_color", Color(1.0, 0.85, 0.1))
	world_name.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	world_name.custom_minimum_size.y = 70
	world_name.position.y = 110
	world_name.hide()
	var info := _big_label(root, "InfoLabel", "", 40)
	info.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	info.custom_minimum_size.y = 70
	info.position.y = -80
	# The Bean Jar total, above the stop's info line.
	var jar := BeanJarLabel.new()
	jar.name = "BeanJarLabel"
	jar.font_size = 38
	jar.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	jar.grow_horizontal = Control.GROW_DIRECTION_BOTH
	jar.position.y = -150
	root.add_child(jar)
	jar.owner = root
	var soon := _big_label(root, "SoonLabel", "COMING SOON!", 96)
	soon.add_theme_color_override("font_color", Color(1.0, 0.85, 0.1))
	soon.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	soon.grow_horizontal = Control.GROW_DIRECTION_BOTH
	soon.grow_vertical = Control.GROW_DIRECTION_BOTH
	soon.hide()
	var hub := _big_label(root, "HubHint", "Y: GO ABOARD", 36)
	hub.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	hub.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	hub.grow_vertical = Control.GROW_DIRECTION_BEGIN
	hub.position -= Vector2(30, 30)
	hub.hide()

	root.set("ship", diorama["ship"])
	root.set("camera", diorama["camera"])
	root.set("stops_root", diorama["stops"])
	root.set("name_label", title)
	root.set("world_label", world_name)
	root.set("info_label", info)
	root.set("soon_label", soon)
	root.set("hub_hint", hub)
	# Y goes aboard the Complex2000 (built by tools/builders/ship_hub.gd).
	root.set("ship_hub_scene", "res://scenes/ship_hub.tscn")
	_save(root, "res://scenes/world_map.tscn")


func _build_storybook() -> void:
	var root := Control.new()
	root.name = "Storybook"
	root.set_script(load("res://scripts/storybook.gd"))
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var back := ColorRect.new()
	back.name = "Background"
	back.color = Color(0.12, 0.1, 0.18)
	back.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(back)
	back.owner = root

	# The big card. A drawing goes in the Picture inside it.
	var card := ColorRect.new()
	card.name = "Card"
	card.color = Color(0.5, 0.5, 0.5)
	card.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	card.offset_left = 120
	card.offset_right = -120
	card.offset_top = 40
	card.offset_bottom = -200
	root.add_child(card)
	card.owner = root

	var picture := TextureRect.new()
	picture.name = "Picture"
	picture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	picture.visible = false
	card.add_child(picture)
	picture.owner = root

	var caption := _big_label(root, "Caption", "", 64)
	caption.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	caption.offset_top = -180
	caption.offset_bottom = -20
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	root.set("card", card)
	root.set("picture", picture)
	root.set("caption", caption)
	root.set("next_scene", "res://scenes/world_map.tscn")
	_save(root, "res://scenes/storybook.tscn")


func _build_start_menu() -> void:
	var root := Control.new()
	root.name = "StartMenu"
	root.set_script(load("res://scripts/start_menu.gd"))
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var back := ColorRect.new()
	back.name = "Background"
	back.color = Color(0.55, 0.8, 0.95)
	back.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(back)
	back.owner = root

	# A green hill along the bottom, just a grey-box touch.
	var hill := ColorRect.new()
	hill.name = "Hill"
	hill.color = Color(0.4, 0.7, 0.3)
	hill.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	hill.offset_top = -220
	root.add_child(hill)
	hill.owner = root

	var title := _big_label(root, "Title", "FART MAN", 160)
	title.add_theme_color_override("font_color", Color(0.45, 0.28, 0.1))
	title.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 70
	title.offset_bottom = 270
	var go := _big_label(root, "ContinueLabel", "CONTINUE", 80)
	go.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	go.grow_horizontal = Control.GROW_DIRECTION_BOTH
	go.offset_top = -30
	var fresh := _big_label(root, "NewGameLabel", "NEW GAME", 80)
	fresh.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	fresh.grow_horizontal = Control.GROW_DIRECTION_BOTH
	fresh.offset_top = 55
	var upgrades := _big_label(root, "UpgradesLabel", "UPGRADES: ON", 48)
	upgrades.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	upgrades.grow_horizontal = Control.GROW_DIRECTION_BOTH
	upgrades.offset_top = 140
	var tests := _big_label(root, "TestLevelsLabel", "TEST LEVELS", 44)
	tests.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	tests.grow_horizontal = Control.GROW_DIRECTION_BOTH
	tests.offset_top = 200
	var hint := _big_label(root, "HintLabel", "", 36)
	hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	hint.offset_top = -60
	hint.offset_bottom = -10

	root.set("continue_label", go)
	root.set("new_game_label", fresh)
	root.set("test_levels_label", tests)
	root.set("upgrades_label", upgrades)
	root.set("hint_label", hint)
	_save(root, "res://scenes/start_menu.tscn")


func _build_boot() -> void:
	var root := Node.new()
	root.name = "Boot"
	root.set_script(load("res://scripts/boot.gd"))
	_save(root, "res://scenes/boot.tscn")


## Writes the autoload and main scene into project.godot using the engine itself.
## Extra scene builders: every script in tools/builders/ has a build() that makes its scenes
## (new enemies, gadgets, bosses). Keeps this file from growing for each new world.
func _run_extra_builders() -> void:
	for file in _scripts_in("res://tools/builders"):
		var builder: RefCounted = load("res://tools/builders/" + file).new()
		builder.build()


## Builds every stage in tools/stages/ (stage_*.gd) with the level kit.
## A stage script can use a bigger kit by saying: const KIT := "res://tools/kit_factory.gd"
## (a kit that extends tools/level_kit.gd).
func _build_stages() -> void:
	for file in _scripts_in("res://tools/stages"):
		var script: GDScript = load("res://tools/stages/" + file)
		var kit_path: String = script.get_script_constant_map().get("KIT", "res://tools/level_kit.gd")
		var kit: RefCounted = load(kit_path).new()
		var stage: RefCounted = script.new()
		stage.build(kit)


## The .gd files in a folder, sorted, or none if the folder is missing.
func _scripts_in(folder: String) -> Array[String]:
	var found: Array[String] = []
	if not DirAccess.dir_exists_absolute(folder):
		return found
	for file in DirAccess.get_files_at(folder):
		if file.ends_with(".gd"):
			found.append(file)
	found.sort()
	return found


## Writes the autoload and main scene into project.godot using the engine itself.
func _register_project() -> void:
	ProjectSettings.set_setting("autoload/SaveGame", "*res://scripts/save_game.gd")
	ProjectSettings.set_setting("autoload/DebugOptions", "*res://scripts/debug_options.gd")
	# Window: the menus and HUD are laid out for 1152 x 648 and scaled up to fit, but the
	# game opens big (maximized, 1920 x 1080 if it can't) and the 3D draws at full screen sharpness.
	ProjectSettings.set_setting("display/window/size/viewport_width", 1152)
	ProjectSettings.set_setting("display/window/size/viewport_height", 648)
	ProjectSettings.set_setting("display/window/size/window_width_override", 1920)
	ProjectSettings.set_setting("display/window/size/window_height_override", 1080)
	ProjectSettings.set_setting("display/window/size/mode", DisplayServer.WINDOW_MODE_MAXIMIZED)
	ProjectSettings.set_setting("display/window/stretch/mode", "canvas_items")
	ProjectSettings.set_setting("display/window/stretch/aspect", "expand")
	ProjectSettings.set_setting("application/run/main_scene", "res://scenes/boot.tscn")
	# Controls. Jump = instant hop (Space / pad A). Fart = charge (F or Z / pad X or B).
	# Controller: A or Y jump; X, B, right bumper or LEFT trigger fart (pull to charge, let go to launch).
	ProjectSettings.set_setting("input/jump", _action([_key(KEY_SPACE), _pad(JOY_BUTTON_A), _pad(JOY_BUTTON_Y)]))
	ProjectSettings.set_setting("input/fart", _action([_key(KEY_F), _key(KEY_Z), _pad(JOY_BUTTON_X), _pad(JOY_BUTTON_B),
		_pad(JOY_BUTTON_RIGHT_SHOULDER), _trigger(JOY_AXIS_TRIGGER_LEFT)]))
	# Walking uses the built-in ui_left / ui_right (arrows, D-pad and left stick), so those
	# are written out here too, so the controller keeps working whatever the engine defaults are.
	ProjectSettings.set_setting("input/ui_left", _action([_key(KEY_LEFT), _key(KEY_A), _pad(JOY_BUTTON_DPAD_LEFT), _stick(JOY_AXIS_LEFT_X, -1.0)]))
	ProjectSettings.set_setting("input/ui_right", _action([_key(KEY_RIGHT), _key(KEY_D), _pad(JOY_BUTTON_DPAD_RIGHT), _stick(JOY_AXIS_LEFT_X, 1.0)]))
	# Menus and story pages: A, Start, Space or Enter all say "go".
	ProjectSettings.set_setting("input/ui_accept", _action([_key(KEY_ENTER), _key(KEY_KP_ENTER), _key(KEY_SPACE),
		_pad(JOY_BUTTON_A), _pad(JOY_BUTTON_START)]))
	print("project save: ", ProjectSettings.save())


func _action(events: Array) -> Dictionary:
	return {"deadzone": 0.5, "events": events}


func _key(code: Key) -> InputEventKey:
	var e := InputEventKey.new()
	e.physical_keycode = code
	return e


## A thumbstick pushed one way (-1 left/up, 1 right/down).
func _stick(axis: JoyAxis, value: float) -> InputEventJoypadMotion:
	var e := InputEventJoypadMotion.new()
	e.axis = axis
	e.axis_value = value
	return e


## A trigger pulled all the way in.
func _trigger(axis: JoyAxis) -> InputEventJoypadMotion:
	return _stick(axis, 1.0)


func _pad(button: JoyButton) -> InputEventJoypadButton:
	var e := InputEventJoypadButton.new()
	e.button_index = button
	return e
