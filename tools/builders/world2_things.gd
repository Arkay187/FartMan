extends RefCounted
## Builds the World 2 (Bean Factory) enemies as scenes: Cork Bot and Fizz Bat.
## (The gadgets, like belts and presses, are built by tools/kit_factory.gd inside each stage.)
## build_scenes.gd runs build() on every script in tools/builders/.


const SfxTable = preload("res://tools/sfx_table.gd")


func build() -> void:
	_build_cork_bot()
	_build_fizz_bat()


func _save(root: Node, path: String) -> void:
	SfxTable.apply_for_scene(root, path)  # fill in the sound slots
	var packed := PackedScene.new()
	print("pack ", path, ": ", packed.pack(root))
	print("save ", path, ": ", ResourceSaver.save(packed, path))
	root.free()


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


## Cork Bot: a tan cork disc (it spins) with a cross on its face, and eyes that stay still.
func _build_cork_bot() -> void:
	var bot := _enemy_base("CorkBot", "res://scripts/cork_bot.gd", 0.5)
	var visual: Node3D = bot.get_node("Visual")
	var roll := Node3D.new()
	roll.name = "Roll"
	visual.add_child(roll)
	roll.owner = bot
	var disc := CylinderMesh.new()
	disc.top_radius = 0.5
	disc.bottom_radius = 0.5
	disc.height = 0.7
	var disc_mesh := _mesh(roll, bot, "Cork", disc, Color(0.78, 0.6, 0.35), Vector3.ZERO)
	disc_mesh.rotation_degrees = Vector3(90, 0, 0)
	# A metal band round the edge, so you can see it spin.
	for i in 2:
		var bar := BoxMesh.new()
		bar.size = Vector3(1.0, 0.1, 0.76)
		var bar_mesh := _mesh(roll, bot, "Band", bar, Color(0.45, 0.47, 0.52), Vector3.ZERO)
		bar_mesh.rotation = Vector3(0, 0, PI * 0.5 * i)
	_eyes(visual, bot, 0.1, 0.17, 0.11, 0.42)
	bot.set("roller", roll)
	bot.set("walk_speed", 3.5)
	bot.set("patrol_distance", 4.0)
	bot.set("stomp_width", 0.7)
	_save(bot, "res://scenes/cork_bot.tscn")


## Fizz Bat: a purple-blue fizzy bat with flappy wings and white bubbles on top.
func _build_fizz_bat() -> void:
	var bat := _enemy_base("FizzBat", "res://scripts/fizz_bat.gd", 0.5)
	var visual: Node3D = bat.get_node("Visual")
	var body := SphereMesh.new()
	body.radius = 0.38
	body.height = 0.76
	_mesh(visual, bat, "Body", body, Color(0.45, 0.35, 0.85), Vector3.ZERO)
	for side in [-1.0, 1.0]:
		var wing_root := Node3D.new()
		wing_root.name = "LeftWing" if side < 0.0 else "RightWing"
		wing_root.position = Vector3(side * 0.3, 0.05, 0)
		visual.add_child(wing_root)
		wing_root.owner = bat
		var wing := BoxMesh.new()
		wing.size = Vector3(0.7, 0.08, 0.45)
		_mesh(wing_root, bat, "Wing", wing, Color(0.3, 0.2, 0.6), Vector3(side * 0.35, 0, 0))
		bat.set("left_wing" if side < 0.0 else "right_wing", wing_root)
	for i in 3:
		var fizz := SphereMesh.new()
		fizz.radius = 0.08
		fizz.height = 0.16
		_mesh(visual, bat, "Fizz", fizz, Color(0.9, 0.95, 1.0), Vector3(-0.15 + i * 0.15, 0.45 + (i % 2) * 0.1, 0.0))
	_eyes(visual, bat, 0.08, 0.14, 0.09, 0.3)
	bat.set("walk_speed", 2.5)
	bat.set("patrol_distance", 3.0)
	_save(bat, "res://scenes/fizz_bat.tscn")
