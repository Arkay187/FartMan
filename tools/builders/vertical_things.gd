extends RefCounted
## Builds the things for the tall test levels: the spring, the barrel cannon,
## and the little TEST LEVELS list scene. (Run by tools/build_scenes.gd.)


func build() -> void:
	_build_spring()
	_build_barrel_cannon()
	_build_test_levels()


func _save(root: Node, path: String) -> void:
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


## A red coil spring on a flat plate. The coil squashes when it bounces.
func _build_spring() -> void:
	var spring := Area3D.new()
	spring.name = "Spring"
	spring.set_script(load("res://scripts/spring.gd"))

	var plate := CylinderMesh.new()
	plate.top_radius = 0.8
	plate.bottom_radius = 0.8
	plate.height = 0.15
	_mesh(spring, spring, "Plate", plate, Color(0.35, 0.35, 0.4), Vector3(0, 0.075, 0))

	# The coil: its origin is at the bottom so squashing keeps it sitting on the plate.
	var coil := Node3D.new()
	coil.name = "Coil"
	coil.position = Vector3(0, 0.15, 0)
	spring.add_child(coil)
	coil.owner = spring
	for i in 4:
		var ring := CylinderMesh.new()
		ring.top_radius = 0.55
		ring.bottom_radius = 0.55
		ring.height = 0.12
		_mesh(coil, spring, "Ring", ring, Color(0.9, 0.2, 0.2) if i % 2 == 0 else Color(0.95, 0.85, 0.2), Vector3(0, 0.15 + i * 0.22, 0))
	var top := CylinderMesh.new()
	top.top_radius = 0.75
	top.bottom_radius = 0.75
	top.height = 0.15
	_mesh(coil, spring, "Top", top, Color(0.9, 0.2, 0.2), Vector3(0, 1.0, 0))

	var col := CollisionShape3D.new()
	col.name = "CollisionShape3D"
	var box := BoxShape3D.new()
	box.size = Vector3(1.4, 1.0, 2.0)
	col.shape = box
	col.position = Vector3(0, 0.5, 0)
	spring.add_child(col)
	col.owner = spring
	spring.set("coil", coil)
	_save(spring, "res://scenes/spring.tscn")


## A wooden barrel on its side-ish: the Barrel node turns to point the way it will fire.
func _build_barrel_cannon() -> void:
	var cannon := Area3D.new()
	cannon.name = "BarrelCannon"
	cannon.set_script(load("res://scripts/barrel_cannon.gd"))

	var barrel := Node3D.new()
	barrel.name = "Barrel"
	cannon.add_child(barrel)
	barrel.owner = cannon
	var body := CylinderMesh.new()
	body.top_radius = 1.0
	body.bottom_radius = 1.0
	body.height = 1.8
	_mesh(barrel, cannon, "Body", body, Color(0.6, 0.38, 0.18), Vector3.ZERO)
	for y in [-0.6, 0.6]:
		var band := CylinderMesh.new()
		band.top_radius = 1.06
		band.bottom_radius = 1.06
		band.height = 0.15
		_mesh(barrel, cannon, "Band", band, Color(0.25, 0.25, 0.28), Vector3(0, y, 0))
	# A glowing mouth and an arrow on the end it fires from.
	var mouth := CylinderMesh.new()
	mouth.top_radius = 0.8
	mouth.bottom_radius = 0.8
	mouth.height = 0.1
	_mesh(barrel, cannon, "Mouth", mouth, Color(0.1, 0.05, 0.02), Vector3(0, 0.9, 0))
	var arrow := CylinderMesh.new()
	arrow.top_radius = 0.0
	arrow.bottom_radius = 0.5
	arrow.height = 0.9
	_mesh(barrel, cannon, "Arrow", arrow, Color(1.0, 0.85, 0.1), Vector3(0, 1.5, 0))

	var col := CollisionShape3D.new()
	col.name = "CollisionShape3D"
	var sphere := SphereShape3D.new()
	sphere.radius = 1.3
	col.shape = sphere
	cannon.add_child(col)
	col.owner = cannon
	cannon.set("barrel", barrel)
	_save(cannon, "res://scenes/barrel_cannon.tscn")


## The list: T-1, T-2 and BACK.
func _build_test_levels() -> void:
	var root := Control.new()
	root.name = "TestLevels"
	root.set_script(load("res://scripts/test_levels.gd"))
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var back := ColorRect.new()
	back.name = "Background"
	back.color = Color(0.45, 0.7, 0.9)
	back.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(back)
	back.owner = root

	var title := _big_label(root, "Title", "TEST LEVELS", 96)
	title.add_theme_color_override("font_color", Color(0.45, 0.28, 0.1))
	title.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 40
	title.offset_bottom = 160

	var titles: Array[String] = ["T-1  THE BEANSTALK", "T-2  THE BEAN SOUP TOWER", "BACK"]
	var rows: Array[Label] = []
	for i in titles.size():
		var row := _big_label(root, "Row%d" % i, titles[i], 64)
		row.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		row.grow_horizontal = Control.GROW_DIRECTION_BOTH
		row.offset_top = -60 + i * 100
		rows.append(row)

	var info := _big_label(root, "Description", "", 32)
	info.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	info.offset_top = -110
	info.offset_bottom = -30

	var scenes: Array[String] = ["res://scenes/stage_t_1.tscn", "res://scenes/stage_t_2.tscn", ""]
	var notes: Array[String] = [
		"A tall climb. Made for free gas: press F1 until it says FILL ON LAND.",
		"Hot bean soup is rising! Climb, wall jump, ride the lift. Try FILL ON LAND too.",
		"Back to the start menu.",
	]
	root.set("rows", rows)
	root.set("titles", titles)
	root.set("scenes", scenes)
	root.set("descriptions", notes)
	root.set("description_label", info)
	_save(root, "res://scenes/test_levels.tscn")
