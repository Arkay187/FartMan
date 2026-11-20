extends "res://tools/level_kit.gd"
## Extra kit pieces for Stage 2-3 (Up the Chimney) and Stage 2-4 (Colonel Cork).
## A stage says:  const KIT := "res://tools/kit_chimney.gd"  and then uses k.shaft(...), k.cable(...) and so on.
## Factory colours: steel, brick, orange.

const STEEL: Color = Color(0.5, 0.53, 0.58)
const DARK_STEEL: Color = Color(0.3, 0.32, 0.36)
const BRICK: Color = Color(0.7, 0.3, 0.22)
const DARK_BRICK: Color = Color(0.5, 0.22, 0.17)
const ORANGE: Color = Color(1.0, 0.6, 0.15)
const CORK: Color = Color(0.78, 0.58, 0.32)
const OLIVE: Color = Color(0.3, 0.38, 0.22)


# ---------------------------------------------------------------- flying gadgets

## An electric cable. length along x, or up and down if vertical. Cycles on and off.
func cable(x: float, y: float, length: float, vertical: bool = false, phase: float = 0.0, on_time: float = 1.5, off_time: float = 1.5) -> Node3D:
	var c := place("res://scenes/spark_cable.tscn", "SparkCable", Vector3(x, y, 0), "Hazards")
	c.set("length", length)
	c.set("vertical", vertical)
	c.set("phase", phase)
	c.set("on_time", on_time)
	c.set("off_time", off_time)
	return c


## A smoke ring to fly through. flat = lying flat, for flying up through (inside the chimney).
func ring(x: float, y: float, flat: bool = false) -> Node3D:
	var r := place("res://scenes/smoke_ring.tscn", "SmokeRing", Vector3(x, y, 0), "Hoops")
	r.set("flat", flat)
	return r


## A rooftop fan at roof height. It blows a column of wind up when it is on.
func fan(x: float, roof_y: float, phase: float = 0.0, column_height: float = 20.0) -> Node3D:
	var f := place("res://scenes/roof_fan.tscn", "RoofFan", Vector3(x, roof_y, 0), "Hazards")
	f.set("phase", phase)
	f.set("column_height", column_height)
	return f


## A thick cloud of bean steam. Beans and surprises inside are hidden.
func steam(x: float, y: float, width: float = 12.0, height: float = 10.0) -> Node3D:
	var s := place("res://scenes/steam_cloud.tscn", "SteamCloud", Vector3(x, y, 0), "Decor")
	s.set("size", Vector2(width, height))
	return s


## A chimney standing on a roof, with its base at base_y. It puffs smoke.
func stack(x: float, base_y: float, height: float, phase: float = 0.0) -> Node3D:
	var s := place("res://scenes/chimney_stack.tscn", "ChimneyStack", Vector3(x, base_y, 0), "Hazards")
	s.set("height", height)
	s.set("phase", phase)
	return s


## A pipe hanging down from above. top_y is where it hangs from.
func pipe(x: float, top_y: float, length: float) -> Node3D:
	var s := place("res://scenes/chimney_stack.tscn", "HangingPipe", Vector3(x, top_y, 0), "Hazards")
	s.set("height", length)
	s.set("hanging", true)
	return s


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


## A zone that changes the sky lane (how low and high he can fly) when he flies through.
func lane_zone(x: float, low: float, high: float) -> Area3D:
	var z := Area3D.new()
	z.name = "LaneChange"
	z.set_script(load("res://scripts/chimney_lane.gd"))
	z.position = Vector3(x, 80.0, 0)
	z.set("lane_low", low)
	z.set("lane_high", high)
	_add("Goal", z)
	_collider(z, Vector3(2.0, 200.0, 4.0), Vector3.ZERO)
	_own(z)
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
	_add("Hints", talker)
	_collider(talker, Vector3(w, h, 4.0), Vector3.ZERO)
	_own(talker)
	return talker


# ---------------------------------------------------------------- the chimney

## The inside of a giant chimney from x0 to x1, walls going up to "top". Returns the shaft zone.
func shaft(x0: float, x1: float, top: float) -> Area3D:
	# Solid brick walls and a steel floor.
	var left: StaticBody3D = block(x0 - 2.0, x0, 0.0, top, BRICK)
	left.name = "WallLeft"
	var right: StaticBody3D = block(x1, x1 + 2.0, 0.0, top, BRICK)
	right.name = "WallRight"
	ground(x0 - 2.0, x1 + 2.0, 0.0, STEEL, false)
	# A dark brick back wall with lighter stripes, so it reads as the inside of a tall tube.
	var back := BoxMesh.new()
	back.size = Vector3(x1 - x0 + 4.0, top, 0.4)
	_mesh(_group("Decor"), "BackWall", back, DARK_BRICK, Vector3((x0 + x1) * 0.5, top * 0.5, -2.2))
	var y: float = 6.0
	while y < top:
		var stripe := BoxMesh.new()
		stripe.size = Vector3(x1 - x0, 0.6, 0.2)
		_mesh(_group("Decor"), "Stripe", stripe, BRICK, Vector3((x0 + x1) * 0.5, y, -1.95))
		# An orange lamp on each wall every second stripe.
		if int(y / 6.0) % 2 == 0:
			for wall_x in [x0 + 0.2, x1 - 0.2]:
				var lamp := BoxMesh.new()
				lamp.size = Vector3(0.5, 0.9, 0.5)
				_mesh(_group("Decor"), "Lamp", lamp, ORANGE, Vector3(wall_x, y + 2.0, 1.0))
		y += 6.0
	# The zone that turns flying into climbing. It reaches 2.5 m above the wall tops, so he is
	# clear of the walls before it lets go and he blasts forward.
	var zone := Area3D.new()
	zone.name = "ChimneyShaft"
	zone.set_script(load("res://scripts/chimney_shaft.gd"))
	zone.position = Vector3((x0 + x1) * 0.5, (top + 2.5) * 0.5, 0)
	_add("Goal", zone)
	_collider(zone, Vector3(x1 - x0, top + 2.5, 4.0), Vector3.ZERO)
	_own(zone)
	return zone


## A sky toilet inside the shaft at height y, on a little steel shelf against the left wall.
func shaft_toilet(x0: float, x1: float, y: float, lane: Vector2) -> Area3D:
	var cx: float = (x0 + x1) * 0.5
	var t := Area3D.new()
	t.name = "ShaftToilet"
	t.set_script(load("res://scripts/toilet.gd"))
	t.position = Vector3(cx, y, 0)
	t.set("flight_range", lane)
	t.set("respawn_height", 0.0)
	t.set("flush_words", "FLUSH! WHEEE!")
	_add("Checkpoints", t)
	var visual := Node3D.new()
	visual.name = "Visual"
	visual.position = Vector3(x0 + 1.6 - cx, -1.0, 0)
	t.add_child(visual)
	var bowl := BoxMesh.new()
	bowl.size = Vector3(0.9, 0.7, 0.8)
	_mesh(visual, "Bowl", bowl, Color(0.95, 0.95, 0.95), Vector3(0.1, 0.35, 0))
	var tank := BoxMesh.new()
	tank.size = Vector3(0.35, 1.0, 0.8)
	_mesh(visual, "Tank", tank, Color(0.95, 0.95, 0.95), Vector3(-0.5, 0.7, 0))
	_collider(t, Vector3(x1 - x0, 4.0, 4.0), Vector3.ZERO)
	t.set("visual", visual)
	_own(t)
	# The shelf it stands on: top is level with the toilet's feet.
	platform(x0 + 1.6, y - 1.0, 3.0, STEEL)
	return t


# ---------------------------------------------------------------- scenery

## Factory roofs under the flight path: flat roofs with tanks, vents and little chimneys.
func factory_roofs(x0: float, x1: float, roof_y: float) -> void:
	# A dark floor far below, so there is a bottom to the world.
	var floor_box := BoxMesh.new()
	floor_box.size = Vector3(x1 - x0 + 200.0, 1.0, 400.0)
	_mesh(_group("Decor"), "FarFloor", floor_box, DARK_STEEL, Vector3((x0 + x1) * 0.5, -3.0, 0))
	var x: float = x0
	while x < x1:
		var width: float = rng.randf_range(24.0, 44.0)
		var top: float = roof_y - rng.randf_range(0.0, 4.0)
		var depth: float = rng.randf_range(16.0, 28.0)
		var z: float = -rng.randf_range(2.0, 10.0)
		var hall := BoxMesh.new()
		hall.size = Vector3(width, top, depth)
		_mesh(_group("Decor"), "Hall", hall, BRICK.lightened(rng.randf_range(0.0, 0.2)), Vector3(x + width * 0.5, top * 0.5, z))
		# A steel roof slab with an orange edge stripe.
		var slab := BoxMesh.new()
		slab.size = Vector3(width + 0.6, 0.5, depth + 0.6)
		_mesh(_group("Decor"), "RoofSlab", slab, STEEL, Vector3(x + width * 0.5, top + 0.25, z))
		var edge := BoxMesh.new()
		edge.size = Vector3(width + 0.7, 0.3, 0.3)
		_mesh(_group("Decor"), "Edge", edge, ORANGE, Vector3(x + width * 0.5, top + 0.65, z + depth * 0.5))
		# Things on the roof.
		for i in 3:
			var px: float = x + rng.randf_range(2.0, width - 2.0)
			var pz: float = z + rng.randf_range(-depth * 0.35, depth * 0.35)
			if rng.randi() % 2 == 0:
				var tank := CylinderMesh.new()
				tank.top_radius = 2.0
				tank.bottom_radius = 2.0
				tank.height = rng.randf_range(2.5, 5.0)
				_mesh(_group("Decor"), "Tank", tank, STEEL.lightened(0.15), Vector3(px, top + 0.5 + tank.height * 0.5, pz))
			else:
				var vent := BoxMesh.new()
				vent.size = Vector3(2.5, rng.randf_range(1.5, 3.0), 2.5)
				_mesh(_group("Decor"), "Vent", vent, DARK_STEEL, Vector3(px, top + 0.5 + vent.size.y * 0.5, pz))
		x += width + rng.randf_range(2.0, 6.0)


## A far-away skyline of tall chimneys puffing smoke, behind everything.
func skyline(x0: float, x1: float, z: float = -60.0) -> void:
	var x: float = x0
	while x < x1:
		var height: float = rng.randf_range(60.0, 110.0)
		var chimney := CylinderMesh.new()
		chimney.top_radius = 4.0
		chimney.bottom_radius = 5.5
		chimney.height = height
		_mesh(_group("Decor"), "FarChimney", chimney, DARK_BRICK, Vector3(x, height * 0.5, z - rng.randf_range(0.0, 40.0)))
		var smoke := SphereMesh.new()
		smoke.radius = 9.0
		smoke.height = 14.0
		var puff := _mesh(_group("Decor"), "FarSmoke", smoke, Color(0.55, 0.5, 0.5, 0.6), Vector3(x + 6.0, height + 8.0, z - 10.0))
		(puff.mesh.get("material") as StandardMaterial3D).transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		x += rng.randf_range(30.0, 70.0)


## The boss hall: a brick back wall, steel girders, pipes, lamps and a giant cork stuck in the wall.
func factory_hall(x0: float, x1: float, floor_y: float = 0.0) -> void:
	var wall := BoxMesh.new()
	wall.size = Vector3(x1 - x0, 40.0, 0.5)
	_mesh(_group("Decor"), "BackWall", wall, DARK_BRICK, Vector3((x0 + x1) * 0.5, floor_y + 18.0, -6.0))
	var x: float = x0
	while x < x1:
		var girder := BoxMesh.new()
		girder.size = Vector3(0.8, 40.0, 0.8)
		_mesh(_group("Decor"), "Girder", girder, STEEL, Vector3(x, floor_y + 18.0, -5.3))
		# An orange lamp hanging between the girders.
		var lamp := SphereMesh.new()
		lamp.radius = 0.5
		lamp.height = 1.0
		_mesh(_group("Decor"), "Lamp", lamp, ORANGE, Vector3(x + 5.0, floor_y + 11.0, -5.0))
		x += 10.0
	# Long steel pipes across the wall.
	for py in [8.0, 14.0, 20.0]:
		var pipe_mesh := CylinderMesh.new()
		pipe_mesh.top_radius = 0.7
		pipe_mesh.bottom_radius = 0.7
		pipe_mesh.height = x1 - x0
		var pipe_node := _mesh(_group("Decor"), "WallPipe", pipe_mesh, STEEL, Vector3((x0 + x1) * 0.5, floor_y + py, -5.0))
		pipe_node.rotation_degrees = Vector3(0, 0, 90)
	# The giant cork he used to plug up the factory.
	var plug := CylinderMesh.new()
	plug.top_radius = 6.0
	plug.bottom_radius = 6.0
	plug.height = 2.0
	var plug_node := _mesh(_group("Decor"), "GiantCork", plug, CORK, Vector3((x0 + x1) * 0.5 + 8.0, floor_y + 11.0, -5.2))
	plug_node.rotation_degrees = Vector3(90, 0, 0)


# ---------------------------------------------------------------- Colonel Cork

## Builds Colonel Cork standing on a floor at floor_y, middle at x. Returns him. The stage
## then plugs in his trigger, door and gate (see stage_2_4.gd).
func colonel_cork(x: float, floor_y: float) -> Area3D:
	var boss := Area3D.new()
	boss.name = "ColonelCork"
	boss.set_script(load("res://scripts/colonel_cork.gd"))
	boss.position = Vector3(x, floor_y, 0)
	_add("Goal", boss)
	boss.set("floor_y", floor_y)

	# All the pictures live in "Visual", so they can lean, shake and pop together.
	var visual := Node3D.new()
	visual.name = "Visual"
	boss.add_child(visual)
	var body := CylinderMesh.new()
	body.top_radius = 1.6
	body.bottom_radius = 1.6
	body.height = 3.2
	_mesh(visual, "CorkBody", body, CORK, Vector3(0, 1.6, 0))
	# A dark green uniform on the bottom half.
	var coat := CylinderMesh.new()
	coat.top_radius = 1.65
	coat.bottom_radius = 1.65
	coat.height = 1.5
	_mesh(visual, "Uniform", coat, OLIVE, Vector3(0, 0.75, 0))
	# Cork speckles on his face and chest.
	for i in 9:
		var dot := SphereMesh.new()
		dot.radius = 0.14
		dot.height = 0.2
		var a: float = -1.1 + 2.2 * float(i) / 8.0
		_mesh(visual, "Speck", dot, Color(0.45, 0.3, 0.15), Vector3(sin(a) * 1.58, 1.8 + sin(float(i) * 2.7) * 0.7, cos(a) * 1.58))
	# Medals.
	for i in 3:
		var medal := SphereMesh.new()
		medal.radius = 0.18
		medal.height = 0.36
		_mesh(visual, "Medal", medal, Color(1.0, 0.82, 0.2), Vector3(-0.55 + 0.55 * float(i), 1.35, 1.6))
	# Angry eyes, eyebrows and a big moustache.
	for side in [-1.0, 1.0]:
		var white := SphereMesh.new()
		white.radius = 0.32
		white.height = 0.64
		_mesh(visual, "Eye", white, Color.WHITE, Vector3(side * 0.6, 2.55, 1.3))
		var pupil := SphereMesh.new()
		pupil.radius = 0.14
		pupil.height = 0.28
		_mesh(visual, "Pupil", pupil, Color.BLACK, Vector3(side * 0.6, 2.5, 1.58))
		var brow := BoxMesh.new()
		brow.size = Vector3(0.85, 0.16, 0.2)
		var brow_mesh: MeshInstance3D = _mesh(visual, "Brow", brow, Color(0.2, 0.12, 0.08), Vector3(side * 0.6, 2.98, 1.45))
		brow_mesh.rotation_degrees = Vector3(0, 0, side * 22.0)
		var stache := BoxMesh.new()
		stache.size = Vector3(1.0, 0.24, 0.25)
		var stache_mesh: MeshInstance3D = _mesh(visual, "Moustache", stache, Color(0.25, 0.15, 0.1), Vector3(side * 0.5, 2.0, 1.55))
		stache_mesh.rotation_degrees = Vector3(0, 0, side * -14.0)
	# Steel arms and boots.
	for side in [-1.0, 1.0]:
		var arm := BoxMesh.new()
		arm.size = Vector3(0.6, 1.7, 0.7)
		_mesh(visual, "Arm", arm, STEEL, Vector3(side * 2.15, 1.7, 0))
		var boot := BoxMesh.new()
		boot.size = Vector3(1.1, 0.5, 1.5)
		_mesh(visual, "Boot", boot, DARK_STEEL, Vector3(side * 0.8, 0.25, 0.3))
	# The peaked hat: a brim and a tall cone with a gold badge.
	var hat := Node3D.new()
	hat.name = "Hat"
	hat.position = Vector3(0, 3.25, 0)
	visual.add_child(hat)
	var brim := CylinderMesh.new()
	brim.top_radius = 1.95
	brim.bottom_radius = 1.95
	brim.height = 0.2
	_mesh(hat, "Brim", brim, OLIVE.darkened(0.2), Vector3.ZERO)
	var cone := CylinderMesh.new()
	cone.top_radius = 0.3
	cone.bottom_radius = 1.5
	cone.height = 1.5
	_mesh(hat, "Cone", cone, OLIVE, Vector3(0, 0.85, 0))
	var badge := SphereMesh.new()
	badge.radius = 0.28
	badge.height = 0.56
	_mesh(hat, "Badge", badge, Color(1.0, 0.82, 0.2), Vector3(0, 0.7, 1.2))

	# His stomp zone: a big forgiving sphere on his head.
	var head := Area3D.new()
	head.name = "Head"
	head.position = Vector3(0, 3.6, 0)
	boss.add_child(head)
	_collider_shape(head, SphereShape3D.new(), Vector3.ZERO, Vector3(1.6, 1.6, 1.6))
	# The stars that circle his head when he is dizzy.
	var stars := Node3D.new()
	stars.name = "Stars"
	stars.position = Vector3(0, 2.0, 0)
	head.add_child(stars)
	for i in 5:
		var star := BoxMesh.new()
		star.size = Vector3(0.45, 0.45, 0.1)
		var angle: float = TAU * float(i) / 5.0
		var star_mesh: MeshInstance3D = _mesh(stars, "Star", star, Color(1.0, 0.9, 0.2), Vector3(cos(angle) * 1.8, 0, sin(angle) * 1.8))
		star_mesh.rotation_degrees = Vector3(0, 0, 45)
	# What hurts when he charges: a box a bit smaller than his body, so it feels fair.
	var hurt_zone := Area3D.new()
	hurt_zone.name = "HurtZone"
	hurt_zone.position = Vector3(0, 1.4, 0)
	boss.add_child(hurt_zone)
	_collider(hurt_zone, Vector3(2.3, 2.8, 3.0), Vector3.ZERO)
	# The red "!" that warns he is about to charge.
	var warning := Node3D.new()
	warning.name = "Warning"
	warning.position = Vector3(0, 6.6, 0)
	boss.add_child(warning)
	var bar := BoxMesh.new()
	bar.size = Vector3(0.5, 1.3, 0.3)
	_mesh(warning, "Bar", bar, Color(1.0, 0.1, 0.1), Vector3(0, 0.4, 0))
	var dot := SphereMesh.new()
	dot.radius = 0.3
	dot.height = 0.6
	_mesh(warning, "Dot", dot, Color(1.0, 0.1, 0.1), Vector3(0, -0.6, 0))

	var scene_player := Node.new()
	scene_player.name = "ScenePlayer"
	scene_player.set_script(load("res://scripts/scene_player.gd"))
	boss.add_child(scene_player)

	boss.set("visual", visual)
	boss.set("head", head)
	boss.set("hurt_zone", hurt_zone)
	boss.set("hat", hat)
	boss.set("stars", stars)
	boss.set("warning", warning)
	boss.set("scene_player", scene_player)
	_own(boss)
	return boss
