extends RefCounted
## Stage 1-4: BOSS, SNEEZY WEEZY (about 3 minutes).
## A toilet checkpoint outside the door. Dodge the pollen, wait for her to droop,
## stomp her head. Three stomps wins, and the gate to the Bean Can opens.

const PINK: Color = Color(1.0, 0.45, 0.7)
const LEAF: Color = Color(0.25, 0.65, 0.3)


func build(k) -> Array[String]:
	k.begin("1-4", "WHAT'S THAT SNIFFLE?", Vector3(-8, 1.2, 0), Color(0.85, 0.85, 0.95))
	k.garden_scenery(-12, 70)

	# --- The corridor outside, with a toilet checkpoint. -------------------------------
	k.ground(-12, 6)
	k.golden(-11, 1.5)
	k.toilet(-2, 0)
	k.hint(0, 0, "BOSS AHEAD! JUMP ON HER HEAD!", 4.0)
	k.beans_line(-6, 4, 1.3)

	# --- The arena. ------------------------------------------------------------------
	k.ground(6, 39)
	k.hint(9, 0, "JUMP OVER THE POLLEN!", 3.0)
	k.platform(16, 2.0, 3.5, LEAF)
	k.platform(26, 3.2, 3.5, LEAF)
	k.golden(16, 3.4)
	k.golden(26, 4.6)
	k.beans_arc(10, 22, 1.2, 2.5, 7)
	k.mega_can(12, 1.4)

	# --- Sneezy Weezy herself. -------------------------------------------------------
	var boss := Area3D.new()
	boss.name = "SneezyWeezy"
	boss.set_script(load("res://scripts/sneezy_weezy.gd"))
	boss.position = Vector3(33, 0, 0)
	k._add("Goal", boss)
	boss.set("floor_y", 0.0)
	k._collider(boss, Vector3(1.8, 4.4, 3.0), Vector3(0, 2.2, 0))
	# A solid stalk so he can't walk through her.
	var stalk_body := StaticBody3D.new()
	stalk_body.name = "StalkBody"
	boss.add_child(stalk_body)
	k._collider(stalk_body, Vector3(1.2, 4.0, 2.0), Vector3(0, 2.0, 0))
	var stalk := CylinderMesh.new()
	stalk.top_radius = 0.4
	stalk.bottom_radius = 0.6
	stalk.height = 4.4
	k._mesh(boss, "Stalk", stalk, LEAF, Vector3(0, 2.2, 0))
	for side in [-1.0, 1.0]:
		var leaf := BoxMesh.new()
		leaf.size = Vector3(2.0, 0.15, 1.0)
		var leaf_mesh: MeshInstance3D = k._mesh(boss, "Leaf", leaf, LEAF, Vector3(side * 1.3, 1.4, 0))
		leaf_mesh.rotation_degrees = Vector3(0, 0, side * 25.0)

	# The head: an Area3D that moves up and down. Its "Face" holds the picture.
	var head := Area3D.new()
	head.name = "Head"
	boss.add_child(head)
	# A big, forgiving stomp zone (radius 1.3 m), a bit bigger than the face you see.
	k._collider_shape(head, SphereShape3D.new(), Vector3.ZERO, Vector3(2.6, 2.6, 2.6))
	var face := Node3D.new()
	face.name = "Face"
	head.add_child(face)
	var disc := SphereMesh.new()
	disc.radius = 1.1
	disc.height = 2.2
	k._mesh(face, "Middle", disc, Color(1.0, 0.85, 0.2), Vector3.ZERO)
	for i in 10:
		var petal := SphereMesh.new()
		petal.radius = 0.55
		petal.height = 1.1
		var angle: float = TAU * i / 10.0
		var petal_mesh: MeshInstance3D = k._mesh(face, "Petal", petal, PINK, Vector3(cos(angle) * 1.5, sin(angle) * 1.5, -0.2))
		petal_mesh.rotation = Vector3(0, 0, angle)
		petal_mesh.scale = Vector3(1.0, 0.6, 0.5)
	for side in [-1.0, 1.0]:
		var white := SphereMesh.new()
		white.radius = 0.28
		white.height = 0.56
		k._mesh(face, "Eye", white, Color.WHITE, Vector3(side * 0.45, 0.3, 0.95))
		var pupil := SphereMesh.new()
		pupil.radius = 0.12
		pupil.height = 0.24
		k._mesh(face, "Pupil", pupil, Color.BLACK, Vector3(side * 0.45, 0.28, 1.2))
	var nose := SphereMesh.new()
	nose.radius = 0.3
	nose.height = 0.6
	k._mesh(face, "RedNose", nose, Color(0.95, 0.2, 0.2), Vector3(0, -0.15, 1.05))

	var scene_player := Node.new()
	scene_player.name = "ScenePlayer"
	scene_player.set_script(load("res://scripts/scene_player.gd"))
	boss.add_child(scene_player)

	# The door (starts the fight) and the gate (opens when she is beaten).
	var trigger: Area3D = k.zone("ArenaTrigger", 9.0, 4.0, Vector3(1.5, 10.0, 4.0))
	var gate: StaticBody3D = k.block(39, 40.5, 0, 14, Color(0.55, 0.35, 0.2))
	gate.name = "Gate"
	boss.set("head", head)
	boss.set("face", face)
	boss.set("trigger", trigger)
	boss.set("gate", gate)
	boss.set("scene_player", scene_player)
	k._own(boss)

	# --- Beyond the gate: the Bean Can. ------------------------------------------------
	k.ground(40.5, 70)
	k.mega_can(46, 1.4)
	k.bean_can(58, 0)
	return k.finish("res://scenes/stage_1_4.tscn")
