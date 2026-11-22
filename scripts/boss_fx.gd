class_name BossFx
extends RefCounted
## Little effects both bosses share: shaking the camera, and letting out a bean burst.

## Shakes the camera for a moment (strength in metres, seconds).
static func shake_camera(from: Node, strength: float, seconds: float) -> void:
	var camera: Camera3D = from.get_viewport().get_camera_3d()
	if camera == null:
		return
	var tween: Tween = from.create_tween()
	tween.set_loops(maxi(1, int(seconds / 0.05)))
	tween.tween_callback(func() -> void:
		if is_instance_valid(camera):
			camera.h_offset = randf_range(-strength, strength)
			camera.v_offset = randf_range(-strength, strength))
	tween.tween_interval(0.05)
	from.get_tree().create_timer(seconds).timeout.connect(func() -> void:
		tween.kill()
		if is_instance_valid(camera):
			camera.h_offset = 0.0
			camera.v_offset = 0.0)


## A burst of beans thrown up from the boss every time he is hit.
static func bean_burst(boss: Node3D, count: int) -> void:
	Loot.beans(boss, count, 6.0, 9.0)


## Pops up "count" of the little helper enemies (Burplings or Cork Bots) at these x spots on
## the floor. They join the group "boss_minions" so the boss can clear them away later.
## Returns them. They are set up before they enter the level so they patrol from where they land.
static func summon(boss: Node3D, scene: PackedScene, xs: Array[float], floor_y: float, lift: float, speed: float, patrol: float) -> Array[Burpling]:
	var made: Array[Burpling] = []
	if scene == null:
		return made
	for x: float in xs:
		var helper := scene.instantiate() as Burpling
		if helper == null:
			continue
		helper.walk_speed = speed
		helper.patrol_distance = patrol
		helper.position = Vector3(x, floor_y + lift, 0.0)
		helper.add_to_group(&"boss_minions")
		boss.get_parent().add_child(helper)
		made.append(helper)
	return made


## Removes every helper enemy the boss summoned.
static func clear_minions(from: Node) -> void:
	for helper: Node in from.get_tree().get_nodes_in_group(&"boss_minions"):
		helper.queue_free()
