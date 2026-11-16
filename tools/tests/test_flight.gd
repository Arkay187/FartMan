extends SceneTree
# Checks Rocket Burrito flight.

var respawns: int = 0


func _initialize() -> void:
	var level: Node = load("res://scenes/test_level.tscn").instantiate()
	root.add_child(level)
	_run(level)


func _wait(seconds: float) -> void:
	for i in int(seconds * 60.0):
		await physics_frame


func _puffs() -> int:
	var n: int = 0
	for child: Node in root.get_children():
		if child is MeshInstance3D:
			n += 1
	return n


func _run(level: Node) -> void:
	var player: CharacterBody3D = level.get_node("Player")
	var tank: Node = player.get_node("GasTank")
	var hearts: Node = player.get_node("Hearts")
	var camera: Camera3D = level.get_node("Camera3D")
	var visual: Node3D = player.get_node("Visual")
	player.respawned.connect(func() -> void: respawns += 1)
	await _wait(0.5)

	# Take off.
	player.global_position = level.get_node("PowerUps/RocketBurrito").global_position
	player.velocity = Vector3.ZERO
	await _wait(0.2)
	print("grabbed burrito: flying=%s score=%d burrito still there=%s" % [player.is_flying(), level.score, level.has_node("PowerUps/RocketBurrito")])

	# Not holding: sinks to the bottom of the sky and stays there.
	var x0: float = player.global_position.x
	await _wait(1.0)
	print("1s, not holding: y=%.1f (floor of sky is 3.0), moved %.1f m forward, tilt=%.0f deg, puffs=%d" % [
		player.global_position.y, player.global_position.x - x0, rad_to_deg(visual.rotation.z), _puffs()])

	# Holding: climbs to the top of the sky and stays there.
	tank.drain(1000.0)
	Input.action_press(&"ui_accept")
	await _wait(2.5)
	var rel: Vector3 = camera.global_position - player.global_position
	var looking: Vector3 = -camera.global_transform.basis.z
	print("2.5s holding: y=%.1f (top of sky is 16.0), gas=%.0f, camera is %.1f behind, %.1f above, %.1f to the side, looking %s" % [
		player.global_position.y, tank.gas, -rel.x, rel.y, rel.z, looking.snapped(Vector3.ONE * 0.01)])
	Input.action_release(&"ui_accept")

	# Hoop.
	var before: int = level.score
	var hoop: Node3D = level.get_node("FlightSection/Hoop2")
	player.global_position = hoop.global_position + Vector3(-3, 0, 0)
	player.velocity.y = 0.0
	await _wait(0.5)
	print("hoop: done=%s score +%d (may include beans)" % [hoop.is_done, level.score - before])

	# Spiky ball: lose a heart, keep flying.
	var ball: Node3D = level.get_node("FlightSection/SpikyBall2")
	player.global_position = ball.global_position + Vector3(-1.2, 0, 0)
	await _wait(0.3)
	print("spiky ball: hearts=%d still flying=%s vel y=%.1f" % [hearts.hearts, player.is_flying(), player.velocity.y])

	# Drop onto a sky Burpling.
	await _wait(1.6)
	var burp: Node3D = level.get_node("FlightSection/SkyBurpling2")
	player.global_position = burp.global_position + Vector3(-1.5, 1.6, 0)
	player.velocity.y = -6.0
	await _wait(0.4)
	print("sky burpling: squashed=%s hearts=%d vel y=%.1f" % [not is_instance_valid(burp) or burp.is_squashed, hearts.hearts, player.velocity.y])

	# Fly into the landing zone.
	player.global_position = Vector3(222, 8, 0)
	await _wait(0.5)
	var flying_after_zone: bool = player.is_flying()
	await _wait(2.5)
	print("landing: flying=%s on_floor=%s x=%.1f y=%.1f tilt=%.0f deg, camera side-on again=%s (z=%.1f, looking %s), puffs=%d" % [
		flying_after_zone, player.is_on_floor(), player.global_position.x, player.global_position.y,
		rad_to_deg(visual.rotation.z), (-camera.global_transform.basis.z).z < -0.99, camera.global_position.z,
		(-camera.global_transform.basis.z).snapped(Vector3.ONE * 0.01), _puffs()])

	# Running out of hearts in the air: back to the checkpoint, flight over, burrito reusable.
	player.global_position = level.get_node("PowerUps/RocketBurrito").global_position
	await _wait(0.3)
	var flying_again: bool = player.is_flying()
	hearts.hearts = 1
	await _wait(1.6)
	player.global_position = ball.global_position + Vector3(-1.2, 0, 0)
	await _wait(0.5)
	print("second flight started=%s, then last heart lost: flying=%s respawns=%d hearts=%d pos=%s" % [
		flying_again, player.is_flying(), respawns, hearts.hearts, player.global_position.snapped(Vector3.ONE * 0.1)])
	quit()
