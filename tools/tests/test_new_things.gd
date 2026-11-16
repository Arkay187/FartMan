extends SceneTree
# Checks the new building blocks one at a time on a plain floor:
# Hiccup, Gnome and mud pies, Crow, bounce pad, moving platform, sprinkler,
# giant cabbage chase, hint bubbles, up-draught, and the sky toilet.

var failures: int = 0
var world: Node3D
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


## A fresh world: a floor with its top at y=0 (or none), and Fart Man standing on it.
func _fresh(with_floor: bool = true, at: Vector3 = Vector3(0, 1.2, 0)) -> void:
	if world != null:
		world.free()
	world = Node3D.new()
	root.add_child(world)
	if with_floor:
		var body := StaticBody3D.new()
		body.position = Vector3(0, -0.5, 0)
		var col := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(400, 1, 4)
		col.shape = shape
		body.add_child(col)
		world.add_child(body)
	player = (load("res://scenes/player.tscn") as PackedScene).instantiate()
	player.position = at
	world.add_child(player)
	var camera := Camera3D.new()
	world.add_child(camera)
	camera.position = Vector3(0, 3, 16)


func _hearts() -> int:
	return (player.get_node("Hearts") as Hearts).hearts


func _run() -> void:
	# --- Hiccup hops on the spot. ---
	_fresh()
	var hiccup: Node3D = (load("res://scenes/hiccup.tscn") as PackedScene).instantiate()
	hiccup.position = Vector3(20, 0.45, 0)
	world.add_child(hiccup)
	var top: float = 0.0
	for i in 300:
		await physics_frame
		top = maxf(top, hiccup.position.y - 0.45)
	_check("hiccup hops (%.2f m high) and stays put (x=%.1f)" % [top, hiccup.position.x], top > 1.0 and absf(hiccup.position.x - 20.0) < 0.1)

	# --- Gnome throws pies that hurt. ---
	_fresh()
	var gnome: Node3D = (load("res://scenes/gnome.tscn") as PackedScene).instantiate()
	gnome.position = Vector3(8, 0.55, 0)
	world.add_child(gnome)
	var pies: Array[int] = [0]
	world.child_entered_tree.connect(func(n: Node) -> void: pies[0] += 1 if n is MudPie else 0)
	await _wait(5.0)
	_check("gnome threw %d pies, hearts now %d" % [pies[0], _hearts()], pies[0] >= 1 and _hearts() < 3)
	# And it keeps still when he is far away.
	_fresh()
	gnome = (load("res://scenes/gnome.tscn") as PackedScene).instantiate()
	gnome.position = Vector3(60, 0.55, 0)
	world.add_child(gnome)
	pies[0] = 0
	world.child_entered_tree.connect(func(n: Node) -> void: pies[0] += 1 if n is MudPie else 0)
	await _wait(4.0)
	_check("gnome far away throws nothing", pies[0] == 0)

	# --- Crow can be stomped. ---
	_fresh(true, Vector3(0, 7, 0))
	var crow: Node3D = (load("res://scenes/crow.tscn") as PackedScene).instantiate()
	crow.position = Vector3(0, 2.5, 0)
	crow.set("walk_speed", 0.0)
	world.add_child(crow)
	var squashed: Array[bool] = [false]
	crow.connect("squashed", func() -> void: squashed[0] = true)
	await _wait(1.5)
	_check("crow stomped from above, hearts %d" % _hearts(), squashed[0] and _hearts() == 3)

	# --- Bounce pad. ---
	_fresh()
	var pad: Node3D = (load("res://scenes/bounce_pad.tscn") as PackedScene).instantiate()
	pad.position = Vector3(0, 0, 0)
	world.add_child(pad)
	var peak: float = 0.0
	for i in 120:
		await physics_frame
		peak = maxf(peak, player.position.y)
	_check("bounce pad launches him (peak %.1f m)" % (peak - 1.0), peak - 1.0 > 4.5)

	# --- Moving platform carries him. ---
	_fresh(false, Vector3(0, 1.2, 0))
	var slab := MovingPlatform.new()
	slab.travel = Vector3(8, 0, 0)
	slab.speed = 4.0
	slab.pause = 0.2
	var slab_col := CollisionShape3D.new()
	var slab_shape := BoxShape3D.new()
	slab_shape.size = Vector3(4, 0.5, 3.5)
	slab_col.shape = slab_shape
	slab.add_child(slab_col)
	slab.position = Vector3(0, -0.25, 0)
	world.add_child(slab)
	await _wait(1.5)
	_check("moving platform carries him (x=%.1f, on floor %s)" % [player.position.x, str(player.is_on_floor())], player.position.x > 3.0 and player.is_on_floor())

	# --- Sprinkler: only hurts while on, and flickers first. ---
	_fresh()
	var jet := PulseHazard.new()
	jet.on_time = 1.0
	jet.off_time = 2.0
	jet.warn_time = 0.5
	var jet_col := CollisionShape3D.new()
	var jet_shape := BoxShape3D.new()
	jet_shape.size = Vector3(3, 4, 3)
	jet_col.shape = jet_shape
	jet.add_child(jet_col)
	var column := Node3D.new()
	jet.add_child(column)
	jet.jet = column
	jet.position = Vector3(0, 1, 0)
	world.add_child(jet)
	var saw_on: bool = false
	var saw_off: bool = false
	var hearts_while_off: int = 3
	for i in 150:
		await physics_frame
		saw_on = saw_on or jet.is_on
		if not jet.is_on and not saw_on:
			hearts_while_off = _hearts()
		saw_off = saw_off or not jet.is_on
	_check("sprinkler off at first (hearts %d), then on, then off (%s %s), hurt (hearts now %d)" % [hearts_while_off, saw_on, saw_off, _hearts()],
		saw_on and saw_off and hearts_while_off == 3 and _hearts() < 3)

	# --- Giant cabbage chase. ---
	_fresh(true, Vector3(10, 1.2, 0))
	var cabbage := Chaser.new()
	cabbage.trigger_x = 5.0
	cabbage.end_x = 60.0
	cabbage.speed = 5.4
	var cab_col := CollisionShape3D.new()
	var cab_shape := SphereShape3D.new()
	cab_shape.radius = 1.5
	cab_col.shape = cab_shape
	cabbage.add_child(cab_col)
	cabbage.position = Vector3(-6, 1.5, 0)
	world.add_child(cabbage)
	await _wait(1.0)
	_check("cabbage rolls once he is past the line (x=%.1f)" % cabbage.position.x, cabbage.is_rolling and cabbage.position.x > -6.0)
	await _wait(4.0)
	_check("cabbage catches him if he stands still: hearts %d" % _hearts(), _hearts() < 3)
	player.respawned.emit()
	_check("cabbage goes back to the start after a respawn (x=%.1f)" % cabbage.position.x, cabbage.position.x == -6.0 and not cabbage.is_rolling)
	await _wait(1.0)

	# --- Hint bubbles: say it once. ---
	_fresh()
	var talker := Chatterbox.new()
	talker.words = "HI!"
	var talk_col := CollisionShape3D.new()
	var talk_shape := BoxShape3D.new()
	talk_shape.size = Vector3(4, 4, 4)
	talk_col.shape = talk_shape
	talker.add_child(talk_col)
	talker.position = Vector3(0, 1, 0)
	world.add_child(talker)
	var bubbles: Array[int] = [0]
	var counter := func(n: Node) -> void: bubbles[0] += 1 if n is SpeechBubble else 0
	root.child_entered_tree.connect(counter)
	await _wait(0.5)
	player.position.x = 20
	await _wait(0.5)
	player.position.x = 0
	await _wait(0.5)
	root.child_entered_tree.disconnect(counter)
	_check("hint spoke once (%d bubbles)" % bubbles[0], bubbles[0] == 1)

	# --- Up-draught shoves a flying Fart Man upwards. ---
	_fresh(false, Vector3(0, 6, 0))
	var draft := UpDraft.new()
	var draft_col := CollisionShape3D.new()
	var draft_shape := BoxShape3D.new()
	draft_shape.size = Vector3(40, 30, 4)
	draft_col.shape = draft_shape
	draft.add_child(draft_col)
	draft.position = Vector3(0, 10, 0)
	world.add_child(draft)
	player.start_flying(3.0, 16.0)
	await _wait(0.6)
	var with_draft: float = player.position.y
	_fresh(false, Vector3(0, 6, 0))
	player.start_flying(3.0, 16.0)
	await _wait(0.6)
	_check("up-draught lifts him (%.1f vs %.1f without)" % [with_draft, player.position.y], with_draft > player.position.y + 3.0)

	print("new things failures: %d" % failures)
	quit()
