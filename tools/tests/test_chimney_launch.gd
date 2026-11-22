extends SceneTree
# Chimney climb and burst-out: while climbing inside the chimney the camera is fully side on
# and Fart Man points straight up like a rocket; when he bursts out of the top he turns flat and
# the camera swings round to the flying view; a respawn at the half-way toilet is upright again.
# Also: the flying stages 1-3 and 2-3 were cut by 30% (they land earlier, still 3 Golden Beans).

var failures: int = 0
var p: Player
var cam: Camera3D


func _initialize() -> void:
	_run()


func _wait(seconds: float) -> void:
	for i in int(seconds * 60.0):
		await physics_frame


func _check(label: String, ok: bool) -> void:
	print("%s: %s" % [label, "ok" if ok else "FAILED"])
	if not ok:
		failures += 1


## Which way his head points (the model's forward axis), as a direction in the world.
func _head() -> Vector3:
	return (p.visual.global_transform.basis * Vector3.RIGHT).normalized()


func _view() -> float:
	return (cam as Object).get("flying_amount")


func _landing_x(stage: Node) -> float:
	var zone: Node3D = stage.find_child("LandingZone", true, false)
	return zone.global_position.x


func _run() -> void:
	var save: Node = root.get_node_or_null("SaveGame")
	if save != null:
		save.use_file("user://test_chimney_launch_save.json")
		save.reset()

	# ------------------------------------------------------------------ the climb
	var stage: Stage = load("res://scenes/stage_2_3.tscn").instantiate()
	root.add_child(stage)
	await _wait(0.5)
	p = stage.player
	cam = stage.find_child("Camera3D", true, false)
	p.flashing_left = 100000.0
	_check("start of 2-3: he is climbing, upright at once", p.flight.is_climbing() and p.flight.climb_amount > 0.99)
	Input.action_press(&"jump")
	await _wait(2.0)
	var look: Vector3 = -cam.global_transform.basis.z
	_check("climbing: camera fully side on (flying view %.2f, looks along z %.2f)" % [_view(), look.z], _view() < 0.05 and absf(look.z) > 0.99)
	_check("climbing: his head points straight up (%s)" % [_head().snapped(Vector3.ONE * 0.01)], _head().dot(Vector3.UP) > 0.95)
	_check("climbing: the camera leans up to show what is above (camera y %.1f, his y %.1f)" % [cam.global_position.y, p.position.y], cam.global_position.y > p.position.y + 2.0)

	# Steering: a small lean, and he faces the way he goes. Upright either way.
	Input.action_press(&"ui_left")
	await _wait(0.8)
	_check("steering left: still upright (%s)" % [_head().snapped(Vector3.ONE * 0.01)], _head().dot(Vector3.UP) > 0.93)
	_check("steering left: he leans a little to the left", _head().x < -0.05)
	_check("steering left: he faces left", cos(p.visual.rotation.y) < 0.0)
	Input.action_release(&"ui_left")
	Input.action_press(&"ui_right")
	await _wait(0.8)
	_check("steering right: still upright and leaning right", _head().dot(Vector3.UP) > 0.93 and _head().x > 0.05)
	Input.action_release(&"ui_right")

	# ------------------------------------------------------------------ respawn at the toilet
	Input.action_release(&"jump")
	p.position = Vector3(8.0, 50.0, 0)
	p.velocity = Vector3.ZERO
	await _wait(0.4)
	p.flashing_left = 0.0
	for i in 3:
		p.flashing_left = 0.0
		p.hurt(p.global_position.x + 1.0)
	await _wait(p.death_time + 0.4)
	_check("respawn at the shaft toilet: climbing again (y %.0f)" % p.position.y, p.is_flying() and p.flight.climb_amount > 0.99 and p.position.y > 30.0)
	_check("respawn: his head points up (%s)" % [_head().snapped(Vector3.ONE * 0.01)], _head().dot(Vector3.UP) > 0.95)
	await _wait(3.0)
	_check("respawn: camera is side on again (%.2f)" % _view(), _view() < 0.1)
	# ------------------------------------------------------------------ burst out of the top
	p.flashing_left = 100000.0
	p.position = Vector3(8.0, 82.0, 0)
	p.velocity = Vector3.ZERO
	Input.action_press(&"jump")
	await _wait(0.3)
	var turned_mid: bool = false
	for i in 60 * 3:
		await physics_frame
		if p.flight.climb_amount > 0.2 and p.flight.climb_amount < 0.8:
			turned_mid = true
	_check("burst out: he turned over a moment, not in one jump", turned_mid)
	await _wait(1.0)
	_check("burst out: he is flying forward (x %.1f)" % p.position.x, p.position.x > 30.0)
	_check("burst out: pose is flat, head forward (%s)" % [_head().snapped(Vector3.ONE * 0.01)], _head().dot(Vector3.RIGHT) > 0.9)
	_check("burst out: not climbing any more", not p.flight.is_climbing())
	_check("burst out: camera is in the flying view (%.2f)" % _view(), _view() > 0.85)
	Input.action_release(&"jump")

	var new_2_3: float = _landing_x(stage)
	var golden_2_3: int = stage.golden_total
	stage.queue_free()
	await _wait(0.3)

	# ------------------------------------------------------------------ a stage that starts flat
	stage = load("res://scenes/stage_1_3.tscn").instantiate()
	root.add_child(stage)
	await _wait(1.0)
	p = stage.player
	cam = stage.find_child("Camera3D", true, false)
	_check("1-3: starts flying flat, not climbing", p.is_flying() and not p.flight.is_climbing())
	_check("1-3: head forward (%s)" % [_head().snapped(Vector3.ONE * 0.01)], _head().dot(Vector3.RIGHT) > 0.9)
	await _wait(2.5)
	_check("1-3: flying camera as before (%.2f)" % _view(), _view() > 0.8)
	var new_1_3: float = _landing_x(stage)
	var golden_1_3: int = stage.golden_total
	stage.queue_free()
	await _wait(0.3)

	# ------------------------------------------------------------------ shorter stages
	print("landing x: 1-3 = %.0f (was 1200), 2-3 = %.0f (was 1710)" % [new_1_3, new_2_3])
	_check("1-3 is at least 28 percent shorter", new_1_3 <= 1200.0 * 0.72)
	_check("2-3 is at least 28 percent shorter", new_2_3 <= 1710.0 * 0.72)
	_check("1-3 still has 3 Golden Beans", golden_1_3 == 3)
	_check("2-3 still has 3 Golden Beans", golden_2_3 == 3)

	print("test_chimney_launch failures: %d" % failures)
	quit()
