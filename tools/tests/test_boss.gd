extends SceneTree
# Plays the Sneezy Weezy fight with fake moves: the hello scene (skipped by holding jump),
# pollen along the floor, her drooping, three stomps, the goodbye and the gate opening.

var failures: int = 0
var stage: Stage
var boss: SneezyWeezy
var player: Player


func _initialize() -> void:
	_run()


func _wait(seconds: float) -> void:
	for i in int(seconds * 60.0):
		await physics_frame


func _check(label: String, ok: bool) -> void:
	print("%s: %s" % [label, "ok" if ok else "FAIL"])
	if not ok:
		failures += 1


## Waits until the boss is in a state (or the time runs out).
func _until(state: SneezyWeezy.State, seconds: float) -> bool:
	var left: float = seconds
	while boss.state != state and left > 0.0:
		await physics_frame
		left -= 1.0 / 60.0
	return boss.state == state


## Lets Fart Man fall onto her drooped head.
func _stomp_head() -> void:
	await _wait(0.7)  # her head takes half a second to droop
	player.velocity = Vector3(0, -6, 0)
	player.global_position = boss.head.global_position + Vector3(0, 3.0, 0)
	await _wait(0.5)


func _run() -> void:
	var save: Node = root.get_node_or_null("SaveGame")
	if save != null:
		save.use_file("user://test_boss_save.json")
		save.reset()
	stage = load("res://scenes/stage_1_4.tscn").instantiate()
	root.add_child(stage)
	player = stage.player
	boss = stage.find_child("SneezyWeezy", true, false)
	await _wait(0.5)
	_check("boss waits until he walks in", boss.state == SneezyWeezy.State.WAITING)
	var gate: Node = stage.find_child("Gate", true, false)

	# Walk through the door. The hello scene starts and takes over his buttons.
	player.position = Vector3(9.0, 1.2, 0)
	await _wait(0.5)
	_check("hello scene runs, buttons locked (state %s, locked %s)" % [str(boss.state), str(player.input_locked)],
		boss.state == SneezyWeezy.State.INTRO and player.input_locked)
	# Hold jump to skip it.
	Input.action_press(&"jump")
	await _wait(1.3)
	Input.action_release(&"jump")
	await _wait(0.3)
	_check("held jump skips the hello (state %s, locked %s)" % [str(boss.state), str(player.input_locked)],
		boss.state != SneezyWeezy.State.INTRO and not player.input_locked)
	_check("hello is remembered as seen", save == null or save.has_seen("sneezy_hello"))

	# Keep him safe while we watch: blinking and untouchable.
	player.flashing_left = 1000.0
	player.position = Vector3(8.0, 1.2, 0)

	# First sneeze: pollen on the floor rolling left.
	var cloud: Pollen = null
	for i in 600:
		await physics_frame
		cloud = get_first_node_in_group(&"boss_shots") as Pollen
		if cloud != null:
			break
	_check("a pollen cloud appears", cloud != null)
	if cloud != null:
		var x0: float = cloud.position.x
		await _wait(0.5)
		_check("pollen rolls left along the floor (%.1f -> %.1f, y=%.2f)" % [x0, cloud.position.x, cloud.position.y], cloud.position.x < x0 - 1.5 and cloud.position.y < 1.0)

	# She droops after three sneezes.
	_check("she gets tired after the sneezes", await _until(SneezyWeezy.State.TIRED, 25.0))

	# Three stomps.
	for n in 3:
		if boss.state != SneezyWeezy.State.TIRED:
			_check("tired again for stomp %d" % (n + 1), await _until(SneezyWeezy.State.TIRED, 30.0))
		await _stomp_head()
		_check("stomp %d lands (hits %d)" % [n + 1, boss.hits], boss.hits == n + 1)
		if n < 2:
			_check("after stomp %d she goes on" % (n + 1), boss.state != SneezyWeezy.State.DEFEATED)
	_check("three stomps defeat her", boss.state == SneezyWeezy.State.DEFEATED)

	# Goodbye scene, then the gate opens (hold jump to skip it).
	_check("gate still shut during the goodbye", is_instance_valid(gate))
	Input.action_press(&"jump")
	await _wait(1.5)
	Input.action_release(&"jump")
	await _wait(0.5)
	_check("gate opens (gone: %s), buttons free again (%s)" % [str(not is_instance_valid(gate) or gate.is_queued_for_deletion()), str(not player.input_locked)],
		(not is_instance_valid(gate) or gate.is_queued_for_deletion()) and not player.input_locked)
	_check("no pollen left", get_nodes_in_group(&"boss_shots").is_empty())

	if save != null:
		save.reset()
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://test_boss_save.json"))
	print("boss failures: %d" % failures)
	quit()
