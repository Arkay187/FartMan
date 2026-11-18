extends SceneTree
# Checks Fart Man's real 3D model: it loads, is the right size, stands on the ground,
# and turns to face the way he runs (angled toward the camera).
# Tests can't see the screen: tools/snapshot_player.gd takes pictures for that.

var failures: int = 0


func _initialize() -> void:
	var level: Node = load("res://scenes/test_level.tscn").instantiate()
	root.add_child(level)
	_run(level)


func _wait(seconds: float) -> void:
	for i in int(seconds * 60.0):
		await physics_frame


func _check(what: String, ok: bool) -> void:
	print("%s: %s" % [what, "ok" if ok else "FAILED"])
	if not ok:
		failures += 1


## Which way his face points, flat on the ground. The model file faces +Z.
func _front(model: Node3D) -> Vector3:
	var f: Vector3 = model.global_basis.z
	f.y = 0.0
	return f.normalized()


func _run(level: Node) -> void:
	var player: Player = level.get_node("Player")
	await _wait(1.0)

	var model: Node3D = player.get_node_or_null("Visual/ModelTurn/Model")
	_check("model is on the player", model != null)
	if model == null:
		print("model failures: %d" % failures)
		quit()
		return
	var meshes: Array[Node] = model.find_children("*", "MeshInstance3D", true, false)
	_check("model has a mesh (%d)" % meshes.size(), meshes.size() > 0)
	_check("grey capsule is hidden", not (player.get_node("Visual/MeshInstance3D") as Node3D).visible)

	# Size and footing, measured from the mesh's box in the world.
	var mesh: MeshInstance3D = meshes[0]
	var box: AABB = mesh.global_transform * mesh.get_aabb()
	var feet_y: float = player.global_position.y - 1.0  # bottom of his 2 m capsule
	_check("about 2 m tall (%.2f)" % box.size.y, box.size.y > 1.8 and box.size.y < 2.2)
	_check("feet on the ground (%.2f vs %.2f)" % [box.position.y, feet_y], absf(box.position.y - feet_y) < 0.1)

	# Facing: right and toward the camera (+Z), then left and toward the camera.
	Input.action_press(&"ui_right")
	await _wait(0.3)
	Input.action_release(&"ui_right")
	var f: Vector3 = _front(model)
	_check("running right: faces right (%.2f) and a bit toward camera (%.2f)" % [f.x, f.z], f.x > 0.5 and f.z > 0.2)
	Input.action_press(&"ui_left")
	await _wait(0.3)
	Input.action_release(&"ui_left")
	await _wait(0.1)
	f = _front(model)
	_check("running left: faces left (%.2f) and a bit toward camera (%.2f)" % [f.x, f.z], f.x < -0.5 and f.z > 0.2)

	# Belly sits on his front, at tummy height, not up by his face.
	var belly: Node3D = player.belly
	var tummy: float = belly.global_position.y - feet_y
	_check("belly at tummy height (%.2f m up)" % tummy, tummy > 0.7 and tummy < 1.2)

	print("model failures: %d" % failures)
	quit()
