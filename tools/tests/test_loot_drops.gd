extends SceneTree
# Checks the loot: a squashed enemy throws beans (and sometimes a random pickup), none of it in
# flying stages, the Heart pickup gives back one heart (never above full), and Fart Man spills
# beans when he is hurt (they vanish after their time, the gas they are worth is taken away, and
# grabbing one gives its gas back).

var failures: int = 0
var world: Node3D
var p: Player
var options: DebugOptionsData


func _initialize() -> void:
	_run()


func _wait(seconds: float) -> void:
	for i in int(seconds * 60.0):
		await physics_frame


func _check(label: String, ok: bool) -> void:
	print("%s: %s" % [label, "ok" if ok else "FAILED"])
	if not ok:
		failures += 1


func _make_world() -> void:
	world = Node3D.new()
	root.add_child(world)
	var floor_body := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(400, 1, 4)
	col.shape = shape
	floor_body.add_child(col)
	floor_body.position = Vector3(0, -0.5, 0)
	world.add_child(floor_body)
	p = (load("res://scenes/player.tscn") as PackedScene).instantiate() as Player
	p.position = Vector3(100, 1.0, 0)
	world.add_child(p)


## Everything that was thrown (it carries a LootBounce), under "parent".
func _thrown(parent: Node) -> Array[Node3D]:
	var found: Array[Node3D] = []
	for child: Node in parent.get_children():
		if child.get_node_or_null("LootBounce") != null:
			found.append(child as Node3D)
	return found


func _is_bean(node: Node3D) -> bool:
	return node.scene_file_path == "res://scenes/bean.tscn"


func _beans(parent: Node) -> Array[Node3D]:
	return _thrown(parent).filter(_is_bean)


## Adds a Burpling at x, on the floor.
func _burpling(parent: Node, x: float) -> Burpling:
	var b := (load("res://scenes/burpling.tscn") as PackedScene).instantiate() as Burpling
	b.position = Vector3(x, 0.45, 0)
	parent.add_child(b)
	return b


func _reset_player() -> void:
	p.global_position = Vector3(100, 1.0, 0)
	p.velocity = Vector3.ZERO
	p.flashing_left = 0.0
	p.hearts.hearts = p.hearts.max_hearts
	p.gas_tank.gas = p.gas_tank.max_gas


func _run() -> void:
	var save: Node = root.get_node_or_null("SaveGame")
	if save != null:
		save.use_file("user://test_loot_drops_save.json")
		save.reset()
	await _wait(0.2)  # let the autoloads start
	options = root.get_node("DebugOptions")
	options.set_simple_controls(false)
	options.set_gas_mode(DebugOptionsData.GasMode.NORMAL)
	_make_world()
	await _wait(0.5)

	# ---------------------------------------------------------------- enemy drops: beans
	var b1: Burpling = _burpling(world, 0.0)
	b1.drop_chance = 0.0
	b1.squash()
	await _wait(0.1)
	var beans: Array[Node3D] = _beans(world)
	_check("a squashed Burpling throws 2 or 3 beans (%d)" % beans.size(), beans.size() >= 2 and beans.size() <= 3)
	_check("with no chance, no pickup comes with them", _thrown(world).size() == beans.size())
	_check("these beans stay (no vanishing time)", (beans[0].get_node("LootBounce") as LootBounce).lifetime == 0.0)
	for node: Node3D in beans:
		node.free()

	# ---------------------------------------------------------------- enemy drops: pickups
	var b2: Burpling = _burpling(world, 0.0)
	b2.drop_chance = 1.0
	b2.squash()
	await _wait(0.1)
	var things: Array[Node3D] = _thrown(world).filter(func(n: Node3D) -> bool: return not _is_bean(n))
	_check("with the chance at 1, one pickup is thrown too (%d)" % things.size(), things.size() == 1)
	_check("it is one from the list (%s)" % things[0].scene_file_path, things[0].scene_file_path in b2.drop_scenes)
	for node: Node3D in _thrown(world):
		node.free()

	# Over many squashes every pickup in the list turns up (Heart, Chilli, Hot Sauce, Mega Bean Can).
	var seen: Dictionary = {}
	for i in 60:
		var many: Burpling = _burpling(world, 0.0)
		many.drop_chance = 1.0
		many.squash()
		for node: Node3D in _thrown(world):
			if not _is_bean(node):
				seen[node.scene_file_path] = true
			node.free()
	_check("the weighted table drops all four pickups (%s)" % str(seen.keys()), seen.size() == 4 and seen.has("res://scenes/heart.tscn"))

	# Hover cloud and fireballs squash through the same call, so they drop too.
	var b3: Burpling = _burpling(world, 0.0)
	b3.drop_chance = 0.0
	b3.squashed.connect(func() -> void: pass)
	b3.squash()
	b3.squash()  # a second squash must not drop twice
	await _wait(0.1)
	_check("squashing twice drops only once (%d beans)" % _beans(world).size(), _beans(world).size() <= 3)
	for node: Node3D in _thrown(world):
		node.free()

	# ---------------------------------------------------------------- no loot in flying stages
	var flight: Node = (load("res://scenes/stage_1_3.tscn") as PackedScene).instantiate()
	root.add_child(flight)
	await _wait(0.3)
	var fb: Burpling = _burpling(flight, 0.0)
	fb.drop_chance = 1.0
	fb.squash()
	await _wait(0.1)
	_check("a flying stage drops nothing (%d thrown)" % _thrown(flight).size(), _thrown(flight).is_empty())
	flight.free()
	await _wait(0.2)

	# ---------------------------------------------------------------- the Heart pickup
	var hearts: Hearts = p.hearts
	_reset_player()
	hearts.hearts = 1
	var h1: Node3D = (load("res://scenes/heart.tscn") as PackedScene).instantiate()
	h1.position = p.global_position
	world.add_child(h1)
	await _wait(0.3)
	_check("a Heart gives one heart back (1 -> %d)" % hearts.hearts, hearts.hearts == 2)
	_check("and is used up", not is_instance_valid(h1) or h1.is_queued_for_deletion())
	hearts.hearts = hearts.max_hearts
	var h2: Node3D = (load("res://scenes/heart.tscn") as PackedScene).instantiate()
	h2.position = p.global_position
	world.add_child(h2)
	await _wait(0.3)
	_check("never above full (%d of %d)" % [hearts.hearts, hearts.max_hearts], hearts.hearts == hearts.max_hearts)
	_check("a Heart is kept for later when he is full", is_instance_valid(h2) and not h2.is_queued_for_deletion())
	h2.free()
	var sample: Node = (load("res://scenes/heart.tscn") as PackedScene).instantiate()
	_check("the Heart has a pickup sound", sample.get("grab_sound") != null)
	sample.free()

	# ---------------------------------------------------------------- spilling beans when hurt
	var spill: BeanSpill = p.get_node("BeanSpill") as BeanSpill
	_check("the player has a BeanSpill, 6 beans by default", spill != null and spill.spill_count == 6)
	hearts.hearts = hearts.max_hearts
	_reset_player()
	spill.spill_count = 2
	p.hurt(p.global_position.x + 1.0)
	await _wait(0.1)
	var spilled: Array[Node3D] = _beans(world)
	_check("getting hurt spills beans (%d)" % spilled.size(), spilled.size() == 2)
	_check("their gas is taken away, 10 each (100 -> %.0f)" % p.gas_tank.gas, absf(p.gas_tank.gas - 80.0) < 1.0)
	for node: Node3D in spilled:
		node.free()

	# Six beans: they vanish after about 5 seconds, and gas never goes below 0.
	spill.spill_count = 6
	_reset_player()
	p.gas_tank.gas = 40.0
	p.hurt(p.global_position.x + 1.0)
	await _wait(0.1)
	spilled = _beans(world)
	_check("six beans spilled (%d)" % spilled.size(), spilled.size() == 6)
	_check("they are set to vanish (%.1f s)" % (spilled[0].get_node("LootBounce") as LootBounce).lifetime,
		(spilled[0].get_node("LootBounce") as LootBounce).lifetime > 3.0)
	_check("gas never goes below 0 (%.1f)" % p.gas_tank.gas, p.gas_tank.gas == 0.0)
	# He is knocked away; keep him far from the beans so they are not eaten.
	p.global_position = Vector3(150, 1.0, 0)
	await _wait(2.0)
	_check("still there after 2 s", spilled.all(func(b: Variant) -> bool: return is_instance_valid(b)))
	await _wait(3.8)
	_check("all gone after their time", spilled.all(func(b: Variant) -> bool: return not is_instance_valid(b)))

	# Grabbing one gives its gas back.
	_reset_player()
	spill.spill_count = 3
	p.gas_tank.gas = 80.0
	p.hurt(p.global_position.x + 1.0)
	await _wait(0.1)
	spilled = _beans(world)
	var after_spill: float = p.gas_tank.gas
	_check("3 beans cost 30 gas (80 -> %.0f)" % after_spill, absf(after_spill - 50.0) < 1.0)
	await _wait(1.0)
	p.global_position = spilled[0].global_position
	p.velocity = Vector3.ZERO
	await _wait(0.3)
	_check("grabbing a spilled bean gives its 10 gas back (%.0f -> %.0f)" % [after_spill, p.gas_tank.gas],
		p.gas_tank.gas > after_spill + 8.0 and not is_instance_valid(spilled[0]))

	if save != null:
		save.reset()
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://test_loot_drops_save.json"))
	print("loot drops failures: %d" % failures)
	quit()
