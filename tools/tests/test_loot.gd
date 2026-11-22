extends SceneTree
# Checks thrown beans (Loot): they fly up, land on the floor, can't be eaten for a moment,
# and spilled beans vanish after their time.

var failures: int = 0


func _initialize() -> void:
	_run()


func _wait(seconds: float) -> void:
	for i in int(seconds * 60.0):
		await physics_frame


func _check(label: String, ok: bool) -> void:
	print("%s: %s" % [label, "ok" if ok else "FAILED"])
	if not ok:
		failures += 1


func _run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var ground := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(60, 1, 4)
	col.shape = box
	ground.add_child(col)
	ground.position = Vector3(0, -0.5, 0)
	world.add_child(ground)
	var thrower := Node3D.new()
	thrower.position = Vector3(0, 1, 0)
	world.add_child(thrower)
	await _wait(0.1)

	var thrown: Array[Node3D] = Loot.beans(thrower, 5)
	_check("five beans thrown", thrown.size() == 5)
	await _wait(0.1)
	var first: Area3D = thrown[0] as Area3D
	_check("they can't be eaten straight away", not first.monitoring)
	var peak: float = 0.0
	for i in 30:
		await physics_frame
		peak = maxf(peak, thrown[2].global_position.y)
	_check("they pop up first (peak %.1f m)" % peak, peak > 1.8)
	await _wait(2.0)
	var all_down: bool = true
	var xs: Array[float] = []
	for bean: Node3D in thrown:
		var bounce := bean.get_node("LootBounce") as LootBounce
		all_down = all_down and bounce.is_settled() and absf(bean.global_position.y - 0.45) < 0.05
		xs.append(bean.global_position.x)
	_check("they all land and rest on the floor", all_down)
	_check("they spread out left and right (%.1f to %.1f)" % [xs.min(), xs.max()], xs.min() < -1.0 and xs.max() > 1.0)
	_check("now they can be eaten", first.monitoring)

	var spilled: Array = Loot.beans(thrower, 3, 4.0, 7.0, 2.0)
	await _wait(1.0)
	_check("spilled beans are still there at 1 s", spilled.all(func(b: Variant) -> bool: return is_instance_valid(b)))
	await _wait(1.3)
	_check("spilled beans vanish after their time", spilled.all(func(b: Variant) -> bool: return not is_instance_valid(b)))

	var chilli: Node3D = Loot.thing(thrower, "res://scenes/chilli.tscn", Vector3(3, 6, 0))
	await _wait(2.0)
	_check("a thrown chilli lands too (%.1f, %.1f)" % [chilli.global_position.x, chilli.global_position.y],
		chilli.global_position.x > 1.0 and chilli.global_position.y < 1.0)

	print("loot failures: %d" % failures)
	quit()
