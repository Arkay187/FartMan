extends "res://tools/kit_factory.gd"
## Level kit for World 3, Planet Whiff. Everything in level_kit.gd and kit_factory.gd (belts,
## fans, vents, pipes, switch blocks, biscuits...), plus: squishy gas clouds, floating rocks,
## Burp Bubbles, gas geysers, Whifflers, secret bean rooms, the flying-storm things (jellyfish,
## lightning, rings, speed tunnels), alien scenery and Big Bad Burp himself.
## A stage says:  const KIT := "res://tools/kit_whiff.gd"

const ROCK: Color = Color(0.42, 0.3, 0.55)
const ROCK_DARK: Color = Color(0.27, 0.2, 0.38)
const CLOUD_PINK: Color = Color(1.0, 0.72, 0.85)
const CLOUD_TEAL: Color = Color(0.6, 0.95, 0.9)
const CLOUD_GOLD: Color = Color(1.0, 0.9, 0.6)
const GLOW: Color = Color(0.5, 1.0, 0.7)
const RAINBOW: Array[Color] = [
	Color(1.0, 0.3, 0.35, 0.45), Color(1.0, 0.65, 0.2, 0.45), Color(1.0, 0.95, 0.3, 0.45),
	Color(0.4, 0.9, 0.4, 0.45), Color(0.3, 0.7, 1.0, 0.45), Color(0.7, 0.4, 1.0, 0.45)]

## Stretches of the main path that bubbles, geysers, springs or barrels carry him across, as
## [x_from, x_to]. The route check lets gaps starting or ending inside these through (the tests
## check the helpers really work).
var assists: Array = []


## Says "bubbles, geysers or springs help you across this stretch" (see assists).
func assist(x0: float, x1: float) -> void:
	assists.append([x0, x1])


# ---------------------------------------------------------------- floors

## Planet rock: a purple rock body with a coloured top (a glowing alien moss).
func ground(x0: float, x1: float, top: float = 0.0, color: Color = GRASS, route: bool = true) -> StaticBody3D:
	var moss: Color = color if color != GRASS else CLOUD_TEAL
	var body := _body("Ground", x0, x1, top - 6.0, top, ROCK_DARK)
	var strip := BoxMesh.new()
	strip.size = Vector3(x1 - x0, 0.25, 4.0)
	_mesh(body, "Top", strip, moss, Vector3(0, 3.0 - 0.125, 0))
	if route:
		routes.append([x0, x1, top])
	return body


## A floating rock centred on cx. bob > 0 makes it float gently up and down by that many metres.
func rock(cx: float, top: float, width: float = 3.5, route: bool = false, bob: float = 0.0, color: Color = ROCK) -> StaticBody3D:
	var body: StaticBody3D
	if bob > 0.0:
		body = moving(cx, top, width, Vector3(0, bob, 0), 1.2, 0.3, rng.randf(), color)
	else:
		body = platform(cx, top, width, color, false, 0.8)
	# A little spike underneath, so it reads as a floating rock.
	var spike := CylinderMesh.new()
	spike.top_radius = width * 0.35
	spike.bottom_radius = 0.0
	spike.height = 1.6
	_mesh(body, "Spike", spike, ROCK_DARK, Vector3(0, -1.0 if bob == 0.0 else -1.0, 0))
	_own(body)
	if route:
		routes.append([cx - width * 0.5, cx + width * 0.5, top])
	return body


## A squishy gas cloud from x0 to x1, top at "top". It sinks when stood on and bounces him
## when he LANDS on it from a height. Walking onto it gently does not bounce.
func cloud(x0: float, x1: float, top: float, props: Dictionary = {}, route: bool = true, color: Color = CLOUD_PINK) -> AnimatableBody3D:
	var width: float = x1 - x0
	var body := AnimatableBody3D.new()
	body.name = "GasCloud"
	body.set_script(load("res://scripts/gas_cloud.gd"))
	sfx_for(body, "gas_cloud")
	body.position = Vector3((x0 + x1) * 0.5, top - 0.6, 0)
	_add("Clouds", body)
	var visual := Node3D.new()
	visual.name = "Visual"
	body.add_child(visual)
	var slab := BoxMesh.new()
	slab.size = Vector3(width, 1.2, 3.6)
	_mesh(visual, "Slab", slab, color, Vector3.ZERO)
	# Fluffy lumps along the top, poking above the surface so he looks sunk into the cloud.
	var lumps: int = maxi(int(width / 2.2), 1)
	for i in lumps:
		var lump := SphereMesh.new()
		lump.radius = 0.95
		lump.height = 1.9
		var lx: float = -width * 0.5 + (float(i) + 0.5) * width / float(lumps)
		_mesh(visual, "Lump", lump, color.lightened(0.15), Vector3(lx, 0.05 + 0.1 * float(i % 2), 0.0))
	_shape_box(body, Vector3(width, 1.2, 4.0), Vector3.ZERO)
	var sensor := Area3D.new()
	sensor.name = "Sensor"
	body.add_child(sensor)
	_shape_box(sensor, Vector3(width - 0.2, 1.6, 3.0), Vector3(0, 0.6 + 0.8, 0))
	body.set("visual", visual)
	body.set("sensor", sensor)
	for key: String in props:
		body.set(key, props[key])
	_own(body)
	if route:
		routes.append([x0, x1, top])
	return body


# ---------------------------------------------------------------- bubbles, geysers, springs

## A Burp Bubble floating up from (x, y). Land on top to bounce very high. props = any BurpBubble setting.
func bubble(x: float, y: float, props: Dictionary = {}) -> Node3D:
	var node := place("res://scenes/burp_bubble.tscn", "BurpBubble", Vector3(x, y, 0), "Bubbles")
	for key: String in props:
		node.set(key, props[key])
	return node


## A gas geyser in the floor at x. It fills the tank and blasts him high. Counted by the route check.
func geyser(x: float, top: float, props: Dictionary = {}) -> Area3D:
	var steam := Area3D.new()
	steam.name = "GasGeyser"
	steam.set_script(load("res://scripts/gas_geyser.gd"))
	sfx_for(steam, "gas_geyser")
	steam.position = Vector3(x, top, 0)
	_add("Vents", steam)
	var grate := CylinderMesh.new()
	grate.top_radius = 0.7
	grate.bottom_radius = 0.9
	grate.height = 0.3
	_mesh(steam, "Crater", grate, Color(0.5, 0.25, 0.6), Vector3(0, 0.15, 0))
	var hole := CylinderMesh.new()
	hole.top_radius = 0.45
	hole.bottom_radius = 0.45
	hole.height = 0.05
	_mesh(steam, "Hole", hole, Color(0.1, 0.8, 0.5), Vector3(0, 0.32, 0))
	var height: float = 3.5
	var column := Node3D.new()
	column.name = "Column"
	column.position = Vector3(0, 0.3, 0)
	steam.add_child(column)
	var gas := CylinderMesh.new()
	gas.top_radius = 1.0
	gas.bottom_radius = 0.6
	gas.height = height
	_mesh(column, "Gas", gas, Color(0.3, 1.0, 0.65, 0.55), Vector3(0, height * 0.5, 0))
	_shape_box(steam, Vector3(1.4, height, 2.0), Vector3(0, 0.3 + height * 0.5, 0))
	steam.set("column", column)
	for key: String in props:
		steam.set(key, props[key])
	_own(steam)
	vents.append([x, top, height, float(steam.get("launch_speed"))])
	return steam


## A big coil spring on the floor at x (press jump as you land for a MEGA boing). Counted by the route check.
func spring(x: float, top: float, props: Dictionary = {}) -> Node3D:
	var node := place("res://scenes/spring.tscn", "Spring", Vector3(x, top, 0), "Pads")
	for key: String in props:
		node.set(key, props[key])
	vents.append([x, top, 0.0, float(node.get("bounce_power"))])
	return node


## A barrel cannon at (x, y). aim: degrees (90 = up). swing_to: 0 = fixed, else it swings.
func barrel(x: float, y: float, aim: float = 90.0, swing_to: float = 0.0, speed: float = 22.0, props: Dictionary = {}) -> Node3D:
	var node := place("res://scenes/barrel_cannon.tscn", "BarrelCannon", Vector3(x, y, 0), "Barrels")
	node.set("aim_degrees", aim)
	node.set("swing_to_degrees", swing_to)
	node.set("launch_speed", speed)
	for key: String in props:
		node.set(key, props[key])
	return node


# ---------------------------------------------------------------- enemies and hazards

## Adds the World 3 enemies: "whiffler" (stands on the floor at "top"). The rest are as before.
func enemy(kind: String, x: float, top_or_y: float, props: Dictionary = {}) -> Node3D:
	if kind != "whiffler":
		return super.enemy(kind, x, top_or_y, props)
	var node := place("res://scenes/whiffler.tscn", "Whiffler", Vector3(x, top_or_y + 0.45, 0), "Enemies")
	for key: String in props:
		node.set(key, props[key])
	return node


## A floating jellyfish (Stink Storm) bobbing around (x, y).
func jelly(x: float, y: float, props: Dictionary = {}) -> Node3D:
	var node := place("res://scenes/jellyfish.tscn", "Jellyfish", Vector3(x, y, 0), "Enemies")
	for key: String in props:
		node.set(key, props[key])
	return node


## A lightning bolt striking between y0 and y1 at x. phase spreads a row of them out.
func lightning(x: float, y0: float, y1: float, phase: float = 0.0, props: Dictionary = {}) -> Node3D:
	var node := place("res://scenes/lightning_bolt.tscn", "LightningBolt", Vector3(x, (y0 + y1) * 0.5, 0), "Hazards")
	node.set("length", y1 - y0)
	node.set("phase", phase)
	for key: String in props:
		node.set(key, props[key])
	return node


## A thick alien fog he can walk (or fly) into. What is inside is a surprise.
func fog(x: float, y: float, width: float = 8.0, height: float = 6.0, words: String = "") -> Node3D:
	var node := place("res://scenes/steam_cloud.tscn", "Fog", Vector3(x, y, 0), "Decor")
	node.set("size", Vector2(width, height))
	node.set("words", words)
	return node


# ---------------------------------------------------------------- flying gadgets

## A ring to fly through (chimney rings, for the Stink Storm).
func ring(x: float, y: float, radius: float = 2.2) -> Node3D:
	var r := place("res://scenes/smoke_ring.tscn", "SmokeRing", Vector3(x, y, 0), "Hoops")
	r.set("radius", radius)
	return r


## A SUPER BOOST from x0 to x1, the same as in the World 1 and 2 flying stages: the scroll goes
## "mult" times faster (eased in and out), with a glowing gate, speed lines, a whoosh and a big hint.
func super_boost(x0: float, x1: float, low: float, high: float, mult: float = 3.5) -> Node3D:
	var z := Area3D.new()
	z.name = "SuperBoost"
	z.set_script(load("res://scripts/super_boost.gd"))
	z.position = Vector3((x0 + x1) * 0.5, (low + high) * 0.5, 0)
	z.set("length", x1 - x0)
	z.set("height", high - low)
	z.set("speed_multiplier", mult)
	sfx_for(z, "super_boost")
	_add("Decor", z)
	say_zone(x0 + 3.0, (low + high) * 0.5, 6.0, high - low, "SUPER BOOST!", 2.5)
	return z


## A zone that makes the flight faster while he is inside (the screen speeds up).
func speed_zone(x0: float, x1: float, low: float, high: float, speed_up: float = 1.5) -> Node3D:
	var z := Area3D.new()
	z.name = "SpeedTunnel"
	z.set_script(load("res://scripts/chimney_speed.gd"))
	z.position = Vector3((x0 + x1) * 0.5, (low + high) * 0.5, 0)
	z.set("length", x1 - x0)
	z.set("height", high - low)
	z.set("speed_up", speed_up)
	_add("Decor", z)
	return z


## Says something over Fart Man's head when he flies into the box.
func say_zone(x: float, y: float, w: float, h: float, words: String, seconds: float = 2.5) -> Chatterbox:
	var talker := Chatterbox.new()
	talker.name = "SayZone"
	talker.position = Vector3(x, y, 0)
	talker.set("words", words)
	talker.set("seconds", seconds)
	talker.set("height", 1.8)
	talker.set("speaker", player)
	talker.set("show_at_top", true)
	_add("Hints", talker)
	_collider(talker, Vector3(w, h, 4.0), Vector3.ZERO)
	_own(talker)
	return talker


# ---------------------------------------------------------------- secret bean rooms

## A secret bean room: a tall closed room with LOTS of beans (rings, columns, arcs and a spiral,
## high up) and things to bounce on (springs, geysers and Burp Bubbles) so you bounce about,
## picking them up in the air. A warp pipe at the right end is the way out and takes him to
## exit_dest. Returns where the entrance pipe should drop him.
func bean_room(cx: float, floor_y: float, exit_dest: Vector3, width: float = 36.0, height: float = 27.0) -> Vector3:
	var x0: float = cx - width * 0.5
	var x1: float = cx + width * 0.5
	ground(x0, x1, floor_y, CLOUD_GOLD, false)
	block(x0 - 2.0, x0, floor_y - 6.0, floor_y + height, ROCK, false)
	block(x1, x1 + 2.0, floor_y - 6.0, floor_y + height, ROCK, false)
	block(x0, x1, floor_y + height, floor_y + height + 1.0, ROCK, false)
	# A soft glowing back wall so it feels like a room.
	var back := BoxMesh.new()
	back.size = Vector3(width, height, 0.3)
	_mesh(_group("Decor"), "RoomBack", back, Color(0.3, 0.2, 0.45), Vector3(cx, floor_y + height * 0.5, -2.3))
	hint(x0 + 4.0, floor_y, "SECRET BEAN ROOM! BOUNCE UP!", 3.5)
	# Things to bounce on: two springs, two geysers and two big bubbles.
	spring(cx - 12.0, floor_y)
	spring(cx + 12.0, floor_y)
	geyser(cx - 5.0, floor_y)
	geyser(cx + 5.0, floor_y, {"phase": 0.5})
	bubble(cx - 8.5, floor_y + 4.0, {"rise_height": 14.0, "radius": 1.3})
	bubble(cx + 8.5, floor_y + 8.0, {"rise_height": 14.0, "radius": 1.3})
	# Beans: columns above the springs and geysers, four rings, two arcs and a spiral.
	for bx: float in [cx - 12.0, cx + 12.0, cx - 5.0, cx + 5.0]:
		for i in 6:
			bean(bx, floor_y + 3.0 + float(i) * 2.2)
	for ring_spot: Vector2 in [Vector2(cx - 12.0, 10.0), Vector2(cx + 12.0, 10.0), Vector2(cx - 4.0, 17.0), Vector2(cx + 4.0, 15.0)]:
		for i in 12:
			var a: float = TAU * float(i) / 12.0
			bean(ring_spot.x + cos(a) * 3.2, floor_y + ring_spot.y + sin(a) * 3.2)
	beans_arc(x0 + 3.0, x1 - 3.0, floor_y + 1.3, 3.0, 10)
	beans_arc(x0 + 5.0, x1 - 5.0, floor_y + 20.0, 3.0, 10)
	for i in 16:
		var t: float = float(i) / 15.0
		bean(cx + sin(t * TAU * 2.0) * 7.0, floor_y + 5.0 + t * 15.0)
	# The way out: an orange pipe in the right wall.
	hint(x1 - 8.0, floor_y, "WAY OUT! GO RIGHT!", 3.0)
	warp_pipe(x1 - 1.6, floor_y, 1.0, exit_dest)
	return Vector3(x0 + 3.0, floor_y + 1.3, 0)


## The way in to a bean room: a warp pipe at (x, top) that you walk into going enter_dir.
## "block" is a solid lump behind it, so it looks like it goes into the rock.
func bean_pipe(x: float, top: float, enter_dir: float, entry: Vector3) -> Area3D:
	var lump_x: float = x + enter_dir * 1.6
	block(lump_x - 1.1, lump_x + 1.1, top, top + 3.2, ROCK, false)
	return warp_pipe(x, top, enter_dir, entry)


# ---------------------------------------------------------------- Big Bad Burp

## Big Bad Burp: a huge grumpy purple blob with a chimney on his head, hovering at (x, y).
## The stage plugs in his trigger, door, gate and burrito (see stage_3_4.gd).
func big_bad_burp(x: float, y: float) -> Area3D:
	var boss := Area3D.new()
	boss.name = "BigBadBurp"
	boss.set_script(load("res://scripts/big_bad_burp.gd"))
	sfx_for(boss, "big_bad_burp")
	boss.position = Vector3(x, y, 0)
	_add("Goal", boss)
	var visual := Node3D.new()
	visual.name = "Visual"
	boss.add_child(visual)
	var body := SphereMesh.new()
	body.radius = 2.6
	body.height = 5.2
	_mesh(visual, "Body", body, Color(0.5, 0.35, 0.78), Vector3.ZERO)
	var belly := SphereMesh.new()
	belly.radius = 1.9
	belly.height = 3.8
	_mesh(visual, "Belly", belly, Color(0.8, 0.7, 0.95), Vector3(0, -0.5, 1.0))
	# The chimney on top of his head: air only comes out of the top!
	var pipe := CylinderMesh.new()
	pipe.top_radius = 0.55
	pipe.bottom_radius = 0.7
	pipe.height = 1.3
	_mesh(visual, "Chimney", pipe, Color(0.7, 0.3, 0.22), Vector3(0, 2.7, 0))
	var puff := SphereMesh.new()
	puff.radius = 0.5
	puff.height = 1.0
	_mesh(visual, "Puff", puff, Color(1, 1, 1, 0.6), Vector3(0.3, 3.7, 0))
	# Angry eyes, brows and little horns.
	for side in [-1.0, 1.0]:
		var white := SphereMesh.new()
		white.radius = 0.55
		white.height = 1.1
		_mesh(visual, "Eye", white, Color.WHITE, Vector3(side * 1.0, 0.7, 2.1))
		var pupil := SphereMesh.new()
		pupil.radius = 0.24
		pupil.height = 0.48
		_mesh(visual, "Pupil", pupil, Color.BLACK, Vector3(side * 0.95, 0.65, 2.55))
		var brow := BoxMesh.new()
		brow.size = Vector3(1.3, 0.25, 0.3)
		var brow_mesh: MeshInstance3D = _mesh(visual, "Brow", brow, Color(0.2, 0.1, 0.3), Vector3(side * 1.0, 1.45, 2.2))
		brow_mesh.rotation_degrees = Vector3(0, 0, side * 24.0)
		var horn := CylinderMesh.new()
		horn.top_radius = 0.0
		horn.bottom_radius = 0.35
		horn.height = 1.1
		var horn_mesh: MeshInstance3D = _mesh(visual, "Horn", horn, Color(0.95, 0.9, 0.7), Vector3(side * 1.9, 2.0, 0))
		horn_mesh.rotation_degrees = Vector3(0, 0, side * -25.0)
		var arm := BoxMesh.new()
		arm.size = Vector3(0.7, 0.7, 0.7)
		_mesh(visual, "Arm", arm, Color(0.45, 0.3, 0.7), Vector3(side * 2.7, -0.4, 0.4))
	# The mouth: a dark oval that opens wide before every burp.
	var mouth := Node3D.new()
	mouth.name = "Mouth"
	mouth.position = Vector3(0, -0.6, 2.4)
	visual.add_child(mouth)
	var hole := SphereMesh.new()
	hole.radius = 0.7
	hole.height = 1.0
	_mesh(mouth, "Hole", hole, Color(0.12, 0.03, 0.15), Vector3.ZERO)
	# His stomp zone: a big forgiving sphere on top of his head.
	var head := Area3D.new()
	head.name = "Head"
	head.position = Vector3(0, 2.8, 0)
	boss.add_child(head)
	_collider_shape(head, SphereShape3D.new(), Vector3.ZERO, Vector3(2.0, 2.0, 2.0))
	var stars := Node3D.new()
	stars.name = "Stars"
	stars.position = Vector3(0, 1.4, 0)
	head.add_child(stars)
	for i in 5:
		var star := BoxMesh.new()
		star.size = Vector3(0.5, 0.5, 0.1)
		var angle: float = TAU * float(i) / 5.0
		var star_mesh: MeshInstance3D = _mesh(stars, "Star", star, Color(1.0, 0.9, 0.2), Vector3(cos(angle) * 2.4, 0, sin(angle) * 2.4))
		star_mesh.rotation_degrees = Vector3(0, 0, 45)
	# What hurts: a round zone a bit smaller than his body, so it feels fair.
	var hurt_zone := Area3D.new()
	hurt_zone.name = "HurtZone"
	hurt_zone.position = Vector3(0, -0.3, 0)
	boss.add_child(hurt_zone)
	_collider_shape(hurt_zone, SphereShape3D.new(), Vector3.ZERO, Vector3(2.4, 2.4, 2.4))
	var scene_player := Node.new()
	scene_player.name = "ScenePlayer"
	scene_player.set_script(load("res://scripts/scene_player.gd"))
	boss.add_child(scene_player)
	boss.set("visual", visual)
	boss.set("head", head)
	boss.set("hurt_zone", hurt_zone)
	boss.set("mouth", mouth)
	boss.set("stars", stars)
	boss.set("scene_player", scene_player)
	_own(boss)
	return boss


# ---------------------------------------------------------------- scenery

## Alien plants, glowing mushrooms and floating rocks behind the path, from x0 to x1.
func alien_scenery(x0: float, x1: float, base_y: float = 0.0) -> void:
	var x: float = x0
	while x < x1:
		var z: float = -rng.randf_range(4.0, 16.0)
		match rng.randi() % 4:
			0:
				_alien_plant(x, base_y, z)
			1:
				_glow_mushroom(x, base_y, z)
			2:
				_far_rock(x, base_y + rng.randf_range(6.0, 22.0), -rng.randf_range(10.0, 26.0))
			3:
				_alien_plant(x, base_y + rng.randf_range(-3.0, 0.0), z)
		x += rng.randf_range(5.0, 11.0)


## A far-away sea of coloured gas below everything, so there is a bottom to the world.
func gas_sea(x0: float, x1: float, y: float = -16.0) -> void:
	var count: int = 5
	for i in count:
		var band := BoxMesh.new()
		band.size = Vector3(x1 - x0 + 200.0, 1.0, 400.0 / float(count))
		var color: Color = RAINBOW[i % RAINBOW.size()]
		color.a = 0.9
		_mesh(_group("Decor"), "GasSea", band, color.darkened(0.2), Vector3((x0 + x1) * 0.5, y, -200.0 + 400.0 * (float(i) + 0.5) / float(count)))


## The planet's rings and a big moon, far behind the path.
func planet_rings(x: float, y: float, z: float = -140.0) -> void:
	var planet := SphereMesh.new()
	planet.radius = 38.0
	planet.height = 76.0
	_mesh(_group("Decor"), "Planet", planet, Color(0.85, 0.5, 0.7), Vector3(x, y, z))
	for i in 3:
		var band := TorusMesh.new()
		band.inner_radius = 52.0 + 8.0 * float(i)
		band.outer_radius = 55.0 + 8.0 * float(i)
		var ring_mesh: MeshInstance3D = _mesh(_group("Decor"), "PlanetRing", band, RAINBOW[(i * 2) % 6].lightened(0.2), Vector3(x, y, z))
		ring_mesh.scale = Vector3(1.0, 0.05, 1.0)
		ring_mesh.rotation_degrees = Vector3(12, 0, -14)


## Big soft rainbow clouds drifting behind the path (for the storm).
func storm_clouds(x0: float, x1: float, y0: float, y1: float) -> void:
	var x: float = x0
	var n: int = 0
	while x < x1:
		var ball := SphereMesh.new()
		var radius: float = rng.randf_range(5.0, 11.0)
		ball.radius = radius
		ball.height = radius * 1.3
		_mesh(_group("Decor"), "RainbowCloud", ball, RAINBOW[n % RAINBOW.size()], Vector3(x, rng.randf_range(y0, y1), -rng.randf_range(8.0, 40.0)))
		n += 1
		x += rng.randf_range(10.0, 22.0)


func _alien_plant(x: float, base_y: float, z: float) -> void:
	var stem := CylinderMesh.new()
	var height: float = rng.randf_range(3.0, 8.0)
	stem.top_radius = 0.1
	stem.bottom_radius = 0.2
	stem.height = height
	_mesh(_group("Decor"), "Stem", stem, Color(0.3, 0.7, 0.55), Vector3(x, base_y + height * 0.5, z))
	var bulb := SphereMesh.new()
	bulb.radius = 0.8
	bulb.height = 1.6
	_mesh(_group("Decor"), "Bulb", bulb, GLOW.lightened(rng.randf_range(0.0, 0.2)), Vector3(x, base_y + height + 0.4, z))


func _glow_mushroom(x: float, base_y: float, z: float) -> void:
	var stalk := CylinderMesh.new()
	stalk.top_radius = 0.25
	stalk.bottom_radius = 0.35
	stalk.height = 2.0
	_mesh(_group("Decor"), "Stalk", stalk, Color(0.9, 0.85, 0.95), Vector3(x, base_y + 1.0, z))
	var cap := SphereMesh.new()
	cap.radius = 1.4
	cap.height = 1.4
	_mesh(_group("Decor"), "Cap", cap, Color(1.0, 0.45, 0.7), Vector3(x, base_y + 2.1, z))


func _far_rock(x: float, y: float, z: float) -> void:
	var lump := SphereMesh.new()
	var radius: float = rng.randf_range(2.0, 5.0)
	lump.radius = radius
	lump.height = radius * 1.2
	_mesh(_group("Decor"), "FarRock", lump, ROCK.lightened(rng.randf_range(0.0, 0.15)), Vector3(x, y, z))


# ---------------------------------------------------------------- route checking

## The factory check (vents, geysers and springs on a piece lift him higher), plus: stretches
## listed with assist() are let through, because bubbles or barrels carry him there.
func check_route() -> Array[String]:
	var problems: Array[String] = []
	var pieces: Array = routes.duplicate()
	pieces.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
	var prev: Array = pieces[0] if not pieces.is_empty() else []
	for i in range(1, pieces.size()):
		var next: Array = pieces[i]
		var gap: float = next[0] - prev[1]
		var rise: float = next[2] - prev[2]
		var lift: Array = _vent_on(prev)
		var helped: bool = _is_assisted(prev[1], next[0])
		if next[1] > prev[1]:
			prev = next
		if helped:
			continue
		var max_rise: float = THUNDER_POWER * THUNDER_POWER / (2.0 * GRAVITY) * SAFETY
		if not lift.is_empty():
			var speed: float = lift[3]
			max_rise = maxf(max_rise, (float(lift[2]) + speed * speed / (2.0 * GRAVITY)) * SAFETY)
		if rise > max_rise:
			problems.append("step up of %.1f m at x=%.0f is too high" % [rise, next[0]])
		elif gap > _reach(rise) and (lift.is_empty() or gap > _vent_reach(lift, rise)):
			problems.append("gap of %.1f m (rise %.1f) at x=%.0f is too far" % [gap, rise, next[0]])
	return problems


func _is_assisted(x_from: float, x_to: float) -> bool:
	for a: Array in assists:
		if (x_from >= float(a[0]) and x_from <= float(a[1])) or (x_to >= float(a[0]) and x_to <= float(a[1])):
			return true
	return false
