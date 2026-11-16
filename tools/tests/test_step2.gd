extends SceneTree
# Checks toilets, Golden Beans, the Bean Can, the banner and speech bubbles.

var respawns: int = 0


func _initialize() -> void:
	var level: Node = load("res://scenes/test_level.tscn").instantiate()
	root.add_child(level)
	_run(level)


func _wait(seconds: float) -> void:
	for i in int(seconds * 60.0):
		await physics_frame


func _bubbles() -> String:
	var words: Array[String] = []
	for child: Node in root.get_children():
		if child is SpeechBubble:
			var panel: PanelContainer = (child as SpeechBubble).panel
			var label := panel.get_child(0) as Label
			words.append("'%s'%s" % [label.text, "" if panel.visible else "(hidden)"])
	return str(words)


func _gold(bar: Node) -> String:
	var s: String = ""
	for c: ColorRect in bar.get_children():
		if c.visible:
			s += "G" if c.color.g > 0.6 else "-"
	return s


func _run(level: Node) -> void:
	var player: CharacterBody3D = level.get_node("Player")
	var bar: Node = level.get_node("HUD/GoldenBeanBar")
	var banner: Label = level.get_node("HUD/StageClearBanner")
	var toilet: Node3D = level.get_node("Toilet")
	var can: Node3D = level.get_node("BeanCan")
	player.respawned.connect(func() -> void: respawns += 1)
	await _wait(0.5)
	print("start: golden %d/%d bar=%s banner_visible=%s bubbles=%s" % [level.golden_found, level.golden_total, _gold(bar), banner.visible, _bubbles()])

	# Golden Bean.
	player.global_position = level.get_node("GoldenBeans/GoldenBean1").global_position
	player.velocity = Vector3.ZERO
	await _wait(0.5)
	print("golden bean: %d/%d bar=%s bubbles=%s" % [level.golden_found, level.golden_total, _gold(bar), _bubbles()])

	# Fall off before any toilet: back to the start.
	player.global_position = Vector3(0, -11, 0)
	await _wait(0.5)
	print("fell (no toilet yet): respawns=%d pos=%s" % [respawns, player.global_position.snapped(Vector3.ONE * 0.1)])

	# Toilet, then fall off: back to the toilet.
	player.global_position = toilet.global_position + Vector3(0, 1.0, 0)
	player.velocity = Vector3.ZERO
	await _wait(0.5)
	print("toilet: flushed=%s bubbles=%s" % [toilet.is_flushed, _bubbles()])
	player.global_position = Vector3(0, -11, 0)
	await _wait(1.0)
	print("fell (after toilet): respawns=%d pos=%s on_floor=%s" % [respawns, player.global_position.snapped(Vector3.ONE * 0.1), player.is_on_floor()])

	# Bean Can: a Trump from the floor beside it must NOT open it.
	player.global_position = Vector3(can.global_position.x - 2.0, 1.5, 0)
	player.velocity = Vector3.ZERO
	await _wait(0.5)
	Input.action_press(&"ui_accept")
	await _wait(0.3)
	Input.action_release(&"ui_accept")
	Input.action_press(&"ui_right")
	await _wait(1.5)
	Input.action_release(&"ui_right")
	print("trump at the can: open=%s cleared=%s" % [can.is_open, level.is_cleared])

	# A Thunder should get on top and open it.
	player.global_position = Vector3(can.global_position.x - 2.0, 1.5, 0)
	player.velocity = Vector3.ZERO
	player.get_node("GasTank").refill(100.0)
	await _wait(0.5)
	Input.action_press(&"ui_accept")
	await _wait(0.6)
	Input.action_release(&"ui_accept")
	Input.action_press(&"ui_right")
	await _wait(0.45)
	Input.action_release(&"ui_right")
	await _wait(1.5)
	print("thunder at the can: open=%s cleared=%s player y=%.1f banner_visible=%s text=%s bubbles=%s" % [
		can.is_open, level.is_cleared, player.global_position.y, banner.visible, banner.text.replace("\n", " | "), _bubbles()])
	quit()
