extends RefCounted
## Level kit: little helpers for building a stage in code (used by tools/build_scenes.gd).
## A stage script calls things like kit.ground(0, 40), kit.platform(50, 2.0, 3),
## kit.enemy("hiccup", 60, 0), kit.toilet(70, 0), then kit.finish("res://scenes/x.tscn").
## Heights are "top" = the height of the walkable surface. Ground level is usually 0.

const GRASS: Color = Color(0.35, 0.72, 0.3)
const DIRT: Color = Color(0.5, 0.35, 0.22)
const WOOD: Color = Color(0.65, 0.45, 0.25)

## What the player can do, used to check the main path is possible (see check_route).
const GRAVITY: float = 25.0
const RUN_SPEED: float = 6.0
const THUNDER_POWER: float = 16.0
const TRUMP_POWER: float = 11.5
const TOOT_POWER: float = 7.5
## Only trust 80% of a jump's reach, so a stage is never a pixel-perfect jump.
const SAFETY: float = 0.8

var root: Node3D
var player: Node3D
var camera: Camera3D
var rng := RandomNumberGenerator.new()
## The main path: [x_from, x_to, top]. Used to check gaps and steps.
var routes: Array = []
var _groups: Dictionary = {}


## Starts a new stage. start = where Fart Man stands, sky = the background colour.
func begin(stage_id: String, opening: String, start: Vector3, sky: Color) -> void:
	rng.seed = hash(stage_id)
	root = Node3D.new()
	root.name = "Stage" + stage_id.replace("-", "_")
	root.set_script(load("res://scripts/stage.gd"))
	root.set("stage_id", stage_id)
	root.set("opening_words", opening)

	player = (load("res://scenes/player.tscn") as PackedScene).instantiate()
	player.position = start
	root.add_child(player)
	player.owner = root
	root.set("player", player)

	camera = Camera3D.new()
	camera.name = "Camera3D"
	camera.set_script(load("res://scripts/follow_camera.gd"))
	camera.position = start + Vector3(0, 3.5, 16)
	root.add_child(camera)
	camera.owner = root
	camera.set("target", player)
	camera.far = 600.0

	var light := DirectionalLight3D.new()
	light.name = "DirectionalLight3D"
	light.rotation_degrees = Vector3(-45, -30, 0)
	light.shadow_enabled = true
	light.directional_shadow_max_distance = 80.0
	root.add_child(light)
	light.owner = root

	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(1, 1, 1)
	env.ambient_light_energy = 0.55
	var world := WorldEnvironment.new()
	world.name = "WorldEnvironment"
	world.environment = env
	root.add_child(world)
	world.owner = root
	_build_hud()


# ---------------------------------------------------------------- the ground

## A stretch of solid ground from x0 to x1 whose walkable top is at "top".
func ground(x0: float, x1: float, top: float = 0.0, color: Color = GRASS, route: bool = true) -> StaticBody3D:
	var body := _body("Ground", x0, x1, top - 6.0, top, DIRT)
	# A thin coloured top so it looks like grass (or whatever the colour is).
	var strip := BoxMesh.new()
	strip.size = Vector3(x1 - x0, 0.25, 4.0)
	_mesh(body, "Top", strip, color, Vector3(0, 3.0 - 0.125, 0))
	if route:
		routes.append([x0, x1, top])
	return body


## A floating platform centred on cx with its top at "top".
func platform(cx: float, top: float, width: float = 3.0, color: Color = WOOD, route: bool = false, thick: float = 0.5) -> StaticBody3D:
	if route:
		routes.append([cx - width * 0.5, cx + width * 0.5, top])
	return _body("Platforms", cx - width * 0.5, cx + width * 0.5, top - thick, top, color)


## A solid block, like a wall to jump over. route = true if it is part of the main path.
func block(x0: float, x1: float, y0: float, y1: float, color: Color = WOOD, route: bool = false) -> StaticBody3D:
	if route:
		routes.append([x0, x1, y1])
	return _body("Platforms", x0, x1, y0, y1, color)


## A slope from (x0, y0) up or down to (x1, y1). Keep it gentle: under 40 degrees.
func ramp(x0: float, x1: float, y0: float, y1: float, color: Color = GRASS) -> StaticBody3D:
	var length: float = Vector2(x1 - x0, y1 - y0).length()
	var angle: float = atan2(y1 - y0, x1 - x0)
	var body := StaticBody3D.new()
	body.name = "Ramp"
	# The box sits half a metre below the line, at right angles to the slope.
	body.position = Vector3((x0 + x1) * 0.5 + 0.5 * sin(angle), (y0 + y1) * 0.5 - 0.5 * cos(angle), 0)
	body.rotation.z = angle
	_add("Ground", body)
	var box := BoxMesh.new()
	box.size = Vector3(length, 1.0, 4.0)
	_mesh(body, "Mesh", box, color, Vector3.ZERO)
	_collider(body, box.size, Vector3.ZERO)
	return body


## A platform that glides back and forth by "travel". Wheelbarrows, lifts, and so on.
func moving(cx: float, top: float, width: float, travel: Vector3, speed: float = 3.0, pause: float = 1.0, phase: float = 0.0, color: Color = WOOD) -> AnimatableBody3D:
	var body := AnimatableBody3D.new()
	body.name = "MovingPlatform"
	body.set_script(load("res://scripts/moving_platform.gd"))
	body.position = Vector3(cx, top - 0.25, 0)
	body.set("travel", travel)
	body.set("speed", speed)
	body.set("pause", pause)
	body.set("phase", phase)
	_add("Platforms", body)
	var slab := BoxMesh.new()
	slab.size = Vector3(width, 0.5, 3.5)
	_mesh(body, "Slab", slab, color, Vector3.ZERO)
	_collider(body, slab.size, Vector3.ZERO)
	return body


# ---------------------------------------------------------------- things to collect

func bean(x: float, y: float) -> Node3D:
	return place("res://scenes/bean.tscn", "Bean", Vector3(x, y, 0), "Beans")


## A row of beans from x0 to x1 at height y.
func beans_line(x0: float, x1: float, y: float, step: float = 2.0) -> void:
	var x: float = x0
	while x <= x1 + 0.01:
		bean(x, y)
		x += step


## A curved row of beans, like a hop: from x0 to x1, rising "height" above y.
func beans_arc(x0: float, x1: float, y: float, height: float, count: int = 5) -> void:
	for i in count:
		var t: float = float(i) / float(maxi(count - 1, 1))
		bean(lerpf(x0, x1, t), y + sin(t * PI) * height)


func golden(x: float, y: float) -> Node3D:
	return place("res://scenes/golden_bean.tscn", "GoldenBean", Vector3(x, y, 0), "GoldenBeans")


## A toilet checkpoint standing on ground at "top". In the sky, pass the flight range.
func toilet(x: float, top: float, flight_range: Vector2 = Vector2.ZERO) -> Node3D:
	var t := place("res://scenes/toilet.tscn", "Toilet", Vector3(x, top, 0), "Checkpoints")
	if flight_range != Vector2.ZERO:
		t.set("flight_range", flight_range)
	return t


## A checkpoint toilet on a cloud in a flying stage. The zone that notices him is as tall as
## the whole sky lane, so he can't miss it. If he comes back here, he comes back flying.
func sky_toilet(x: float, lane: Vector2 = Vector2(3.0, 16.0)) -> Area3D:
	var mid: float = (lane.x + lane.y) * 0.5
	var t := Area3D.new()
	t.name = "SkyToilet"
	t.set_script(load("res://scripts/toilet.gd"))
	t.position = Vector3(x, mid, 0)
	t.set("flight_range", lane)
	t.set("respawn_height", 0.0)
	t.set("flush_words", "FLUSH! WHEEE!")
	_add("Checkpoints", t)
	var visual := Node3D.new()
	visual.name = "Visual"
	t.add_child(visual)
	var bowl := BoxMesh.new()
	bowl.size = Vector3(0.9, 0.7, 0.8)
	_mesh(visual, "Bowl", bowl, Color(0.95, 0.95, 0.95), Vector3(0.1, 0.0, 0))
	var tank := BoxMesh.new()
	tank.size = Vector3(0.35, 1.0, 0.8)
	_mesh(visual, "Tank", tank, Color(0.95, 0.95, 0.95), Vector3(-0.5, 0.35, 0))
	var cloud := SphereMesh.new()
	cloud.radius = 1.8
	cloud.height = 1.0
	_mesh(visual, "Cloud", cloud, Color(1, 1, 1), Vector3(0, -0.7, 0))
	_collider(t, Vector3(2.0, lane.y - lane.x + 1.0, 4.0), Vector3.ZERO)
	t.set("visual", visual)
	_own(t)
	return t


func chilli(x: float, y: float) -> Node3D:
	return place("res://scenes/chilli.tscn", "Chilli", Vector3(x, y, 0), "PowerUps")


func mega_can(x: float, y: float) -> Node3D:
	return place("res://scenes/mega_bean_can.tscn", "MegaBeanCan", Vector3(x, y, 0), "PowerUps")


func bean_can(x: float, top: float) -> Node3D:
	return place("res://scenes/bean_can.tscn", "BeanCan", Vector3(x, top, 0), "Goal")


# ---------------------------------------------------------------- enemies and hazards

## kind: burpling, hiccup, gnome (sit on the ground at "top"), crow (hangs in the air at y).
## props = extra settings, like {"patrol_distance": 3.0}.
func enemy(kind: String, x: float, top_or_y: float, props: Dictionary = {}) -> Node3D:
	var lift: Dictionary = {"burpling": 0.45, "hiccup": 0.45, "gnome": 0.55, "crow": 0.0}
	var node := place("res://scenes/%s.tscn" % kind, kind.capitalize(), Vector3(x, top_or_y + float(lift[kind]), 0), "Enemies")
	for key: String in props:
		node.set(key, props[key])
	return node


func prickle(x: float, top: float) -> Node3D:
	return place("res://scenes/prickle.tscn", "Prickle", Vector3(x, top + 0.3, 0), "Hazards")


func spiky(x: float, y: float) -> Node3D:
	return place("res://scenes/spiky_ball.tscn", "SpikyBall", Vector3(x, y, 0), "Hazards")


func pad(x: float, top: float, props: Dictionary = {}) -> Node3D:
	var node := place("res://scenes/bounce_pad.tscn", "BouncePad", Vector3(x, top, 0), "Pads")
	for key: String in props:
		node.set(key, props[key])
	return node


func hoop(x: float, y: float) -> Node3D:
	return place("res://scenes/hoop.tscn", "Hoop", Vector3(x, y, 0), "Hoops")


## A sprinkler jet standing on the ground. It cycles on and off.
func sprinkler(x: float, top: float, phase: float = 0.0, height: float = 3.5, on_time: float = 1.3, off_time: float = 2.0) -> Area3D:
	var jet_area := Area3D.new()
	jet_area.name = "Sprinkler"
	jet_area.set_script(load("res://scripts/pulse_hazard.gd"))
	jet_area.position = Vector3(x, top, 0)
	jet_area.set("phase", phase)
	jet_area.set("on_time", on_time)
	jet_area.set("off_time", off_time)
	_add("Hazards", jet_area)
	var nozzle := CylinderMesh.new()
	nozzle.top_radius = 0.25
	nozzle.bottom_radius = 0.35
	nozzle.height = 0.4
	_mesh(jet_area, "Nozzle", nozzle, Color(0.6, 0.6, 0.65), Vector3(0, 0.2, 0))
	# The water. Its origin is at the bottom so scaling it makes it grow upwards.
	var column := Node3D.new()
	column.name = "Jet"
	column.position = Vector3(0, 0.4, 0)
	jet_area.add_child(column)
	var water := CylinderMesh.new()
	water.top_radius = 0.5
	water.bottom_radius = 0.6
	water.height = height
	var blue := _mesh(column, "Water", water, Color(0.4, 0.7, 1.0, 0.6), Vector3(0, height * 0.5, 0))
	(blue.mesh.get("material") as StandardMaterial3D).transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_collider(jet_area, Vector3(1.2, height, 2.0), Vector3(0, 0.4 + height * 0.5, 0))
	jet_area.set("jet", column)
	_own(jet_area)
	return jet_area


## A hint that shows at the top middle of the screen when he passes. Draws a little wooden
## sign on the ground.
func hint(x: float, top: float, words: String, seconds: float = 3.0) -> Chatterbox:
	var talker := Chatterbox.new()
	talker.name = "Hint"
	talker.position = Vector3(x, top, 0)
	talker.set("words", words)
	talker.set("seconds", seconds)
	talker.set("height", 2.6)
	talker.set("show_at_top", true)
	_add("Hints", talker)
	_collider(talker, Vector3(2.0, 8.0, 4.0), Vector3(0, 4.0, 0))
	var post := BoxMesh.new()
	post.size = Vector3(0.15, 1.4, 0.15)
	_mesh(talker, "Post", post, WOOD, Vector3(0, 0.7, -1.2))
	var board := BoxMesh.new()
	board.size = Vector3(1.1, 0.7, 0.12)
	_mesh(talker, "Board", board, Color(0.9, 0.8, 0.55), Vector3(0, 1.4, -1.2))
	_own(talker)
	return talker


## An invisible zone that sends a signal when he walks into it (for starting boss fights).
func zone(zone_name: String, x: float, y: float, size: Vector3) -> Area3D:
	var area := Area3D.new()
	area.name = zone_name
	area.position = Vector3(x, y, 0)
	_add("Goal", area)
	_collider(area, size, Vector3.ZERO)
	_own(area)
	return area


## A giant cabbage that chases him. It starts when he passes trigger_x and crashes at end_x.
func chaser(start_x: float, top: float, trigger_x: float, end_x: float, speed: float = 5.4) -> Area3D:
	var cab := Area3D.new()
	cab.name = "GiantCabbage"
	cab.set_script(load("res://scripts/chaser.gd"))
	cab.position = Vector3(start_x, top + 1.5, 0)
	cab.set("trigger_x", trigger_x)
	cab.set("end_x", end_x)
	cab.set("speed", speed)
	_add("Hazards", cab)
	var spin := Node3D.new()
	spin.name = "Spin"
	cab.add_child(spin)
	var ball := SphereMesh.new()
	ball.radius = 1.6
	ball.height = 3.2
	_mesh(spin, "Cabbage", ball, Color(0.4, 0.75, 0.3), Vector3.ZERO)
	for i in 5:
		var leaf := BoxMesh.new()
		leaf.size = Vector3(0.1, 3.0, 3.3)
		var leaf_mesh := _mesh(spin, "Leaf", leaf, Color(0.3, 0.6, 0.25), Vector3.ZERO)
		leaf_mesh.rotation = Vector3(0, 0, PI * i / 5.0)
	# Angry eyes on the camera side. They don't spin, so they stay put.
	var face := Node3D.new()
	face.name = "Face"
	cab.add_child(face)
	for side in [-1.0, 1.0]:
		var white := SphereMesh.new()
		white.radius = 0.35
		white.height = 0.7
		_mesh(face, "Eye", white, Color.WHITE, Vector3(side * 0.6, 0.5, 1.35))
		var pupil := SphereMesh.new()
		pupil.radius = 0.15
		pupil.height = 0.3
		_mesh(face, "Pupil", pupil, Color.BLACK, Vector3(side * 0.6 + 0.12, 0.45, 1.62))
	_collider_shape(cab, SphereShape3D.new(), Vector3.ZERO, Vector3(1.5, 1.5, 1.5))
	cab.set("visual", spin)
	_own(cab)
	return cab


# ---------------------------------------------------------------- flying stages

## A rising column of warm air from y0 up to y1, between x0 and x1.
func updraft(x0: float, x1: float, y0: float, y1: float) -> Area3D:
	var area := Area3D.new()
	area.name = "UpDraft"
	area.set_script(load("res://scripts/up_draft.gd"))
	area.position = Vector3((x0 + x1) * 0.5, (y0 + y1) * 0.5, 0)
	_add("Hazards", area)
	var box := BoxMesh.new()
	box.size = Vector3(x1 - x0, y1 - y0, 3.0)
	var glow := _mesh(area, "Draught", box, Color(1.0, 0.9, 0.5, 0.25), Vector3.ZERO)
	(glow.mesh.get("material") as StandardMaterial3D).transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_collider(area, box.size, Vector3.ZERO)
	_own(area)
	return area


## A washing line from x0 to x1 at height y, with socks. Hurts to touch.
func washing_line(x0: float, x1: float, y: float) -> Area3D:
	var line := Area3D.new()
	line.name = "WashingLine"
	line.set_script(load("res://scripts/hazard.gd"))
	line.set("spiky", false)
	line.position = Vector3((x0 + x1) * 0.5, y, 0)
	_add("Hazards", line)
	var rope := BoxMesh.new()
	rope.size = Vector3(x1 - x0, 0.12, 0.12)
	_mesh(line, "Rope", rope, Color(0.9, 0.9, 0.9), Vector3(0, 0.45, 0))
	var count: int = int((x1 - x0) / 3.0)
	for i in count:
		var sock := BoxMesh.new()
		sock.size = Vector3(0.7, 0.9, 0.1)
		var palette: Array[Color] = [Color(1, 0.3, 0.4), Color(0.3, 0.6, 1), Color(1, 0.85, 0.2), Color(0.5, 0.9, 0.4)]
		_mesh(line, "Sock", sock, palette[i % 4], Vector3(-(x1 - x0) * 0.5 + 1.5 + i * 3.0, 0.0, 0))
	_collider(line, Vector3(x1 - x0, 1.3, 1.5), Vector3(0, 0.1, 0))
	_own(line)
	return line


## A surprised cow standing on the ground. When he flies past between x0 and x1 she says "MOO?!".
func cow(cow_x: float, ground_y: float, x0: float, x1: float, lane_y0: float = 0.0, lane_y1: float = 20.0) -> Node3D:
	var moo := Node3D.new()
	moo.name = "Cow"
	moo.position = Vector3(cow_x, ground_y, -14)
	_add("Decor", moo)
	var body := BoxMesh.new()
	body.size = Vector3(3.0, 1.6, 1.4)
	_mesh(moo, "Body", body, Color.WHITE, Vector3(0, 1.4, 0))
	var head := BoxMesh.new()
	head.size = Vector3(1.0, 1.0, 1.0)
	_mesh(moo, "Head", head, Color(0.95, 0.9, 0.9), Vector3(1.9, 1.9, 0))
	for i in 3:
		var patch := BoxMesh.new()
		patch.size = Vector3(0.7, 0.6, 1.5)
		_mesh(moo, "Patch", patch, Color(0.15, 0.15, 0.15), Vector3(-1.0 + i * 0.9, 1.5 + (i % 2) * 0.3, 0))
	for lx in [-1.1, 1.1]:
		for lz in [-0.45, 0.45]:
			var leg := BoxMesh.new()
			leg.size = Vector3(0.3, 0.9, 0.3)
			_mesh(moo, "Leg", leg, Color.WHITE, Vector3(lx, 0.45, lz))
	var talker := Chatterbox.new()
	talker.name = "CowSpeech"
	talker.position = Vector3((x0 + x1) * 0.5, (lane_y0 + lane_y1) * 0.5, 0)
	talker.set("words", "MOO?!")
	talker.set("seconds", 2.5)
	talker.set("height", 4.5)
	talker.set("speaker", moo)
	_add("Decor", talker)
	_collider(talker, Vector3(x1 - x0, lane_y1 - lane_y0, 4.0), Vector3.ZERO)
	_own(talker)
	_own(moo)
	return moo


# ---------------------------------------------------------------- scenery (just to look at)

## Trees, bushes and sunflowers behind the path, from x0 to x1. Nothing here can be touched.
func garden_scenery(x0: float, x1: float, ground_y: float = 0.0) -> void:
	var x: float = x0
	while x < x1:
		var z: float = -rng.randf_range(5.0, 16.0)
		match rng.randi() % 4:
			0:
				_tree(x, ground_y, z)
			1:
				_sunflower(x, ground_y, z)
			2:
				_bush(x, ground_y, z)
			3:
				_fence(x, ground_y, -4.0)
		x += rng.randf_range(4.0, 9.0)


## Tall plant stalks and a glass-house frame behind the path.
func greenhouse_scenery(x0: float, x1: float, ground_y: float = 0.0) -> void:
	var x: float = x0
	while x < x1:
		var z: float = -rng.randf_range(4.0, 10.0)
		if rng.randi() % 3 == 0:
			_pot_plant(x, ground_y, z)
		else:
			_stalk(x, ground_y, z)
		x += rng.randf_range(3.0, 7.0)
	# The glass wall behind: a frame every 12 m with a pale see-through panel.
	var gx: float = x0
	while gx < x1:
		var frame := BoxMesh.new()
		frame.size = Vector3(0.4, 30.0, 0.4)
		_mesh(_group("Decor"), "Frame", frame, Color(0.85, 0.9, 0.9), Vector3(gx, ground_y + 12.0, -18.0))
		var glass := BoxMesh.new()
		glass.size = Vector3(12.0, 30.0, 0.1)
		var pane := _mesh(_group("Decor"), "Glass", glass, Color(0.7, 0.95, 0.95, 0.2), Vector3(gx + 6.0, ground_y + 12.0, -18.0))
		(pane.mesh.get("material") as StandardMaterial3D).transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		gx += 12.0


## A big green field far below, dotted with hills and houses, for flying over.
func landscape(x0: float, x1: float, field_y: float = -9.0) -> void:
	var field := BoxMesh.new()
	field.size = Vector3(x1 - x0, 1.0, 300.0)
	_mesh(_group("Decor"), "Field", field, Color(0.35, 0.65, 0.3), Vector3((x0 + x1) * 0.5, field_y, 0))
	var x: float = x0
	var n: int = 0
	while x < x1:
		n += 1
		var is_house: bool = n % 3 == 0
		var height: float = rng.randf_range(3.0, 7.0) if is_house else rng.randf_range(4.0, 12.0)
		var width: float = rng.randf_range(3.0, 5.0) if is_house else rng.randf_range(8.0, 16.0)
		var shape := BoxMesh.new()
		shape.size = Vector3(width, height, width)
		var color: Color = Color(0.85, 0.5, 0.4) if is_house else Color(0.25, 0.55, 0.25)
		var side: float = 1.0 if n % 2 == 0 else -1.0
		var z: float = side * rng.randf_range(16.0, 90.0)
		_mesh(_group("Decor"), "House" if is_house else "Hill", shape, color.lightened(rng.randf_range(0.0, 0.25)),
			Vector3(x, field_y + 0.5 + height * 0.5, z))
		# A red roof on the houses.
		if is_house:
			var roof := CylinderMesh.new()
			roof.top_radius = 0.0
			roof.bottom_radius = width * 0.8
			roof.height = 2.5
			roof.radial_segments = 4
			_mesh(_group("Decor"), "Roof", roof, Color(0.7, 0.2, 0.15), Vector3(x, field_y + 0.5 + height + 1.2, z))
		x += rng.randf_range(7.0, 14.0)


# ---------------------------------------------------------------- finishing

## Checks every step on the main path is possible with a Thunder jump. Returns problems.
func check_route() -> Array[String]:
	var problems: Array[String] = []
	var pieces: Array = routes.duplicate()
	pieces.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	# "prev" is whichever piece so far reaches furthest right.
	var prev: Array = pieces[0] if not pieces.is_empty() else []
	for i in range(1, pieces.size()):
		var next: Array = pieces[i]
		var gap: float = next[0] - prev[1]
		var rise: float = next[2] - prev[2]
		if next[1] > prev[1]:
			prev = next
		if rise > THUNDER_POWER * THUNDER_POWER / (2.0 * GRAVITY) * SAFETY:
			problems.append("step up of %.1f m at x=%.0f is too high" % [rise, next[0]])
		elif gap > _reach(rise):
			problems.append("gap of %.1f m (rise %.1f) at x=%.0f is too far" % [gap, rise, next[0]])
	return problems


## How far a Thunder jump gets him across at a given rise, with the safety margin.
func _reach(rise: float) -> float:
	var disc: float = THUNDER_POWER * THUNDER_POWER - 2.0 * GRAVITY * rise
	if disc < 0.0:
		return 0.0
	var air: float = (THUNDER_POWER + sqrt(disc)) / GRAVITY
	return RUN_SPEED * air * SAFETY


## Saves the stage. Returns the problems found with the main path (empty = fine).
func finish(path: String) -> Array[String]:
	var problems: Array[String] = check_route()
	var packed := PackedScene.new()
	print("pack ", path, ": ", packed.pack(root))
	print("save ", path, ": ", ResourceSaver.save(packed, path))
	for p: String in problems:
		print("ROUTE PROBLEM ", path, ": ", p)
	root.free()
	return problems


# ---------------------------------------------------------------- inside the kit

## Makes something from a scene file and puts it in a named group node.
func place(scene_path: String, node_name: String, pos: Vector3, group: String) -> Node3D:
	var thing: Node3D = (load(scene_path) as PackedScene).instantiate()
	thing.name = node_name
	thing.position = pos
	_add(group, thing)
	return thing


func _group(group_name: String) -> Node3D:
	if not _groups.has(group_name):
		var holder := Node3D.new()
		holder.name = group_name
		root.add_child(holder)
		holder.owner = root
		_groups[group_name] = holder
	return _groups[group_name]


## Adds a node to a group node. Only the node itself is owned: scenes keep their insides.
func _add(group_name: String, node: Node) -> void:
	_group(group_name).add_child(node)
	node.owner = root


## For nodes built in code: make everything inside belong to the stage too, so it is saved.
func _own(node: Node) -> void:
	for child: Node in node.get_children():
		child.owner = root
		_own(child)


func _body(group_name: String, x0: float, x1: float, y0: float, y1: float, color: Color) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = group_name.trim_suffix("s")
	body.position = Vector3((x0 + x1) * 0.5, (y0 + y1) * 0.5, 0)
	_add(group_name, body)
	var box := BoxMesh.new()
	box.size = Vector3(x1 - x0, y1 - y0, 4.0)
	_mesh(body, "Mesh", box, color, Vector3.ZERO)
	_collider(body, box.size, Vector3.ZERO)
	_own(body)
	return body


func _mesh(parent: Node, mesh_name: String, shape: Mesh, color: Color, pos: Vector3) -> MeshInstance3D:
	var paint := StandardMaterial3D.new()
	paint.albedo_color = color
	shape.set("material", paint)
	var mesh := MeshInstance3D.new()
	mesh.name = mesh_name
	mesh.mesh = shape
	mesh.position = pos
	parent.add_child(mesh)
	if parent == root or parent.owner == root:
		mesh.owner = root
	return mesh


func _collider(parent: Node, size: Vector3, pos: Vector3) -> void:
	var shape := BoxShape3D.new()
	shape.size = size
	_collider_shape(parent, shape, pos, Vector3.ONE)


## Adds a collision shape. extents is only used for spheres: x = radius.
func _collider_shape(parent: Node, shape: Shape3D, pos: Vector3, extents: Vector3) -> void:
	if shape is SphereShape3D:
		(shape as SphereShape3D).radius = extents.x
	var col := CollisionShape3D.new()
	col.name = "CollisionShape3D"
	col.shape = shape
	col.position = pos
	parent.add_child(col)
	if parent == root or parent.owner == root:
		col.owner = root


func _tree(x: float, ground_y: float, z: float) -> void:
	var trunk := CylinderMesh.new()
	trunk.top_radius = 0.4
	trunk.bottom_radius = 0.5
	trunk.height = 4.0
	_mesh(_group("Decor"), "Trunk", trunk, Color(0.45, 0.3, 0.15), Vector3(x, ground_y + 2.0, z))
	var leaves := SphereMesh.new()
	leaves.radius = 2.4
	leaves.height = 4.4
	_mesh(_group("Decor"), "Leaves", leaves, Color(0.2, 0.55, 0.25).lightened(rng.randf_range(0, 0.2)), Vector3(x, ground_y + 5.2, z))


func _sunflower(x: float, ground_y: float, z: float) -> void:
	var stem := CylinderMesh.new()
	stem.top_radius = 0.08
	stem.bottom_radius = 0.1
	stem.height = 3.5
	_mesh(_group("Decor"), "Stem", stem, Color(0.25, 0.6, 0.2), Vector3(x, ground_y + 1.75, z))
	var petals := CylinderMesh.new()
	petals.top_radius = 0.9
	petals.bottom_radius = 0.9
	petals.height = 0.15
	var disc := _mesh(_group("Decor"), "Petals", petals, Color(1.0, 0.85, 0.1), Vector3(x, ground_y + 3.6, z))
	disc.rotation_degrees = Vector3(90, 0, 0)
	var middle := CylinderMesh.new()
	middle.top_radius = 0.4
	middle.bottom_radius = 0.4
	middle.height = 0.2
	var heart := _mesh(_group("Decor"), "Middle", middle, Color(0.35, 0.2, 0.1), Vector3(x, ground_y + 3.6, z + 0.1))
	heart.rotation_degrees = Vector3(90, 0, 0)


func _bush(x: float, ground_y: float, z: float) -> void:
	var bush := SphereMesh.new()
	bush.radius = 1.3
	bush.height = 2.0
	_mesh(_group("Decor"), "Bush", bush, Color(0.25, 0.6, 0.3).lightened(rng.randf_range(0, 0.2)), Vector3(x, ground_y + 0.7, z))


func _fence(x: float, ground_y: float, z: float) -> void:
	for i in 4:
		var post := BoxMesh.new()
		post.size = Vector3(0.25, 1.4, 0.2)
		_mesh(_group("Decor"), "Post", post, Color(0.9, 0.85, 0.7), Vector3(x + i * 1.0, ground_y + 0.7, z))
	var rail := BoxMesh.new()
	rail.size = Vector3(3.4, 0.2, 0.15)
	_mesh(_group("Decor"), "Rail", rail, Color(0.9, 0.85, 0.7), Vector3(x + 1.5, ground_y + 1.0, z))


func _stalk(x: float, ground_y: float, z: float) -> void:
	var stem := CylinderMesh.new()
	stem.top_radius = 0.12
	stem.bottom_radius = 0.18
	stem.height = 9.0
	_mesh(_group("Decor"), "Stalk", stem, Color(0.2, 0.55, 0.25), Vector3(x, ground_y + 4.5, z))
	var tomato := SphereMesh.new()
	tomato.radius = 0.5
	tomato.height = 1.0
	_mesh(_group("Decor"), "Tomato", tomato, Color(0.9, 0.15, 0.1), Vector3(x + 0.4, ground_y + rng.randf_range(2.0, 7.0), z + 0.2))


func _pot_plant(x: float, ground_y: float, z: float) -> void:
	var pot := CylinderMesh.new()
	pot.top_radius = 0.9
	pot.bottom_radius = 0.6
	pot.height = 1.3
	_mesh(_group("Decor"), "Pot", pot, Color(0.8, 0.4, 0.2), Vector3(x, ground_y + 0.65, z))
	var leaves := SphereMesh.new()
	leaves.radius = 1.4
	leaves.height = 2.4
	_mesh(_group("Decor"), "Leaves", leaves, Color(0.2, 0.6, 0.3), Vector3(x, ground_y + 2.3, z))


func _build_hud() -> void:
	var hud := CanvasLayer.new()
	hud.name = "HUD"
	root.add_child(hud)
	hud.owner = root

	var label := Label.new()
	label.name = "GasLabel"
	label.text = "GAS"
	label.position = Vector2(20, 18)
	label.add_theme_font_size_override("font_size", 24)
	hud.add_child(label)
	label.owner = root

	var bar := ProgressBar.new()
	bar.name = "GasBar"
	bar.set_script(load("res://scripts/gas_bar.gd"))
	bar.position = Vector2(90, 20)
	bar.size = Vector2(300, 30)
	bar.show_percentage = false
	hud.add_child(bar)
	bar.owner = root
	bar.set("player", player)

	var hearts_bar := HBoxContainer.new()
	hearts_bar.name = "HeartsBar"
	hearts_bar.set_script(load("res://scripts/hearts_bar.gd"))
	hearts_bar.position = Vector2(20, 64)
	hearts_bar.add_theme_constant_override("separation", 8)
	hud.add_child(hearts_bar)
	hearts_bar.owner = root
	hearts_bar.set("player", player)

	var gold_bar := HBoxContainer.new()
	gold_bar.name = "GoldenBeanBar"
	gold_bar.set_script(load("res://scripts/golden_bean_bar.gd"))
	gold_bar.position = Vector2(20, 104)
	gold_bar.add_theme_constant_override("separation", 8)
	hud.add_child(gold_bar)
	gold_bar.owner = root
	gold_bar.set("full_color", Color(1.0, 0.8, 0.1))
	gold_bar.set("stage", root)

	var score := Label.new()
	score.name = "ScoreLabel"
	score.set_script(load("res://scripts/score_label.gd"))
	score.text = "SCORE 0"
	score.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	score.add_theme_font_size_override("font_size", 32)
	score.add_theme_color_override("font_outline_color", Color.BLACK)
	score.add_theme_constant_override("outline_size", 8)
	score.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	score.position = Vector2(-320, 16)
	score.size = Vector2(300, 40)
	score.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	hud.add_child(score)
	score.owner = root
	score.set("stage", root)

	var banner := Label.new()
	banner.name = "StageClearBanner"
	banner.set_script(load("res://scripts/stage_clear_banner.gd"))
	banner.text = "STAGE CLEAR!"
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.add_theme_font_size_override("font_size", 64)
	banner.add_theme_color_override("font_outline_color", Color.BLACK)
	banner.add_theme_constant_override("outline_size", 12)
	banner.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	banner.position.y = 120
	banner.grow_horizontal = Control.GROW_DIRECTION_BOTH
	hud.add_child(banner)
	banner.owner = root
	banner.set("stage", root)
