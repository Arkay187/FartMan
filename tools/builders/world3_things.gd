extends RefCounted
## Builds the World 3 (Planet Whiff) things as scenes: the Burp Bubble, the Lightning Bolt, the
## Whiffler and the Jellyfish. (Clouds, geysers, rocks and the rest are built by tools/kit_whiff.gd
## inside each stage. Big Bad Burp is built inside stage 3-4.)
## build_scenes.gd runs build() on every script in tools/builders/.

const SfxTable = preload("res://tools/sfx_table.gd")
## Things that are just an Area3D with a script. The script makes its own looks in _ready().
const GADGETS: Dictionary = {
	"burp_bubble": "res://scripts/burp_bubble.gd",
	"lightning_bolt": "res://scripts/lightning_bolt.gd",
}


func build() -> void:
	for scene_name: String in GADGETS:
		var area := Area3D.new()
		area.name = scene_name.to_pascal_case()
		area.set_script(load(GADGETS[scene_name]))
		_save(area, "res://scenes/%s.tscn" % scene_name)
	_build_whiffler()
	_build_jellyfish()


func _save(root: Node, path: String) -> void:
	SfxTable.apply_for_scene(root, path)  # fill in the sound slots
	var packed := PackedScene.new()
	print("pack ", path, ": ", packed.pack(root))
	print("save ", path, ": ", ResourceSaver.save(packed, path))
	root.free()


func _mesh(parent: Node, owner_node: Node, mesh_name: String, shape: Mesh, color: Color, pos: Vector3) -> MeshInstance3D:
	var paint := StandardMaterial3D.new()
	paint.albedo_color = color
	if color.a < 1.0:
		paint.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
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


## Whiffler: a little teal alien bulb on two legs, with a big surprised mouth. When it puffs, a
## green stink cloud (the Cloud zone) appears around it.
func _build_whiffler() -> void:
	var alien := _enemy_base("Whiffler", "res://scripts/whiffler.gd", 0.5)
	var visual: Node3D = alien.get_node("Visual")
	var bulb := SphereMesh.new()
	bulb.radius = 0.45
	bulb.height = 0.9
	_mesh(visual, alien, "Body", bulb, Color(0.35, 0.8, 0.75), Vector3.ZERO)
	for side in [-1.0, 1.0]:
		var foot := BoxMesh.new()
		foot.size = Vector3(0.3, 0.12, 0.4)
		_mesh(visual, alien, "Foot", foot, Color(0.2, 0.55, 0.55), Vector3(side * 0.22, -0.42, 0.05))
		# Eye stalks with the eyes on top.
		var stalk := BoxMesh.new()
		stalk.size = Vector3(0.06, 0.3, 0.06)
		_mesh(visual, alien, "Stalk", stalk, Color(0.2, 0.55, 0.55), Vector3(side * 0.18, 0.55, 0.0))
	_eyes(visual, alien, 0.75, 0.18, 0.1, 0.05)
	var mouth := SphereMesh.new()
	mouth.radius = 0.14
	mouth.height = 0.28
	_mesh(visual, alien, "Mouth", mouth, Color(0.1, 0.05, 0.1), Vector3(0.0, -0.1, 0.4))
	# The stink cloud: a zone (off until it puffs) with a few green puffs inside.
	var zone := Area3D.new()
	zone.name = "Cloud"
	zone.monitoring = false
	alien.add_child(zone)
	zone.owner = alien
	var col := CollisionShape3D.new()
	col.name = "CollisionShape3D"
	var round_shape := SphereShape3D.new()
	round_shape.radius = 1.7
	col.shape = round_shape
	col.position = Vector3(0, 0.4, 0)
	zone.add_child(col)
	col.owner = alien
	var puffs := Node3D.new()
	puffs.name = "Puffs"
	zone.add_child(puffs)
	puffs.owner = alien
	for i in 6:
		var angle: float = TAU * float(i) / 6.0
		var puff := SphereMesh.new()
		puff.radius = 0.75
		puff.height = 1.5
		_mesh(puffs, alien, "Puff", puff, Color(0.55, 0.85, 0.2, 0.55), Vector3(cos(angle) * 0.9, 0.4 + sin(angle) * 0.9, 0.3))
	var middle := SphereMesh.new()
	middle.radius = 1.1
	middle.height = 2.2
	_mesh(puffs, alien, "Middle", middle, Color(0.45, 0.8, 0.15, 0.5), Vector3(0, 0.4, 0.4))
	alien.set("cloud_zone", zone)
	alien.set("cloud_visual", puffs)
	_save(alien, "res://scenes/whiffler.tscn")


## Jellyfish: a glowing pink dome with wiggly tentacles, for the Stink Storm.
func _build_jellyfish() -> void:
	var jelly := _enemy_base("Jellyfish", "res://scripts/jellyfish.gd", 0.9)
	var visual: Node3D = jelly.get_node("Visual")
	var dome_holder := Node3D.new()
	dome_holder.name = "Dome"
	visual.add_child(dome_holder)
	dome_holder.owner = jelly
	var dome := SphereMesh.new()
	dome.radius = 0.9
	dome.height = 1.3
	_mesh(dome_holder, jelly, "Cap", dome, Color(1.0, 0.5, 0.85, 0.8), Vector3.ZERO)
	for i in 5:
		var tentacle := BoxMesh.new()
		tentacle.size = Vector3(0.1, 1.1 + 0.2 * float(i % 2), 0.1)
		_mesh(visual, jelly, "Tentacle", tentacle, Color(1.0, 0.6, 0.9, 0.8), Vector3(-0.6 + 0.3 * float(i), -0.9, 0.0))
	_eyes(visual, jelly, 0.1, 0.28, 0.13, 0.75)
	jelly.set("pulse_target", dome_holder)
	_save(jelly, "res://scenes/jellyfish.tscn")
