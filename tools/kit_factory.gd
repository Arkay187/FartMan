extends "res://tools/level_kit.gd"
## Level kit for World 2, the Bean Factory. Everything in level_kit.gd, plus factory gadgets:
## conveyor belts, stamping presses, crumbling biscuits, red/blue switch blocks and a big button,
## warp pipes, fans, steam vents, factory scenery, and the Cork Bot and Fizz Bat enemies.
## A stage script uses it by saying: const KIT := "res://tools/kit_factory.gd"

const STEEL: Color = Color(0.55, 0.58, 0.66)
const STEEL_DARK: Color = Color(0.3, 0.32, 0.38)
const ORANGE: Color = Color(0.95, 0.55, 0.15)
const CRATE: Color = Color(0.72, 0.5, 0.26)
const BISCUIT: Color = Color(0.86, 0.66, 0.36)

## Steam vents placed so far: [x, top, column height, launch speed]. check_route uses them.
var vents: Array = []


# ---------------------------------------------------------------- floors

## Factory floor: a steel top over a dark steel body (the garden kit paints the body brown).
func ground(x0: float, x1: float, top: float = 0.0, color: Color = GRASS, route: bool = true) -> StaticBody3D:
	var body := _body("Ground", x0, x1, top - 6.0, top, STEEL_DARK)
	var strip := BoxMesh.new()
	strip.size = Vector3(x1 - x0, 0.25, 4.0)
	_mesh(body, "Top", strip, color, Vector3(0, 3.0 - 0.125, 0))
	if route:
		routes.append([x0, x1, top])
	return body


## A conveyor belt floor from x0 to x1. speed > 0 carries him right, speed < 0 carries him left.
func belt(x0: float, x1: float, top: float, speed: float = 3.0, route: bool = true) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = "Conveyor"
	body.set_script(load("res://scripts/conveyor.gd"))
	body.position = Vector3((x0 + x1) * 0.5, top - 0.5, 0)
	_add("Belts", body)
	var length: float = x1 - x0
	var slab := BoxMesh.new()
	slab.size = Vector3(length, 1.0, 4.0)
	_mesh(body, "Slab", slab, Color(0.2, 0.21, 0.25), Vector3.ZERO)
	_collider(body, slab.size, Vector3.ZERO)
	# Orange rollers at both ends.
	for end_x in [-length * 0.5, length * 0.5]:
		var roller := CylinderMesh.new()
		roller.top_radius = 0.5
		roller.bottom_radius = 0.5
		roller.height = 4.1
		var roller_mesh := _mesh(body, "Roller", roller, ORANGE, Vector3(end_x, 0, 0))
		roller_mesh.rotation_degrees = Vector3(90, 0, 0)
	# Yellow stripes on top. The script slides them along.
	var stripes := Node3D.new()
	stripes.name = "Stripes"
	body.add_child(stripes)
	var count: int = maxi(int(round(length / 2.0)), 2)
	for i in count:
		var bar := BoxMesh.new()
		bar.size = Vector3(0.45, 0.05, 3.6)
		_mesh(stripes, "Stripe", bar, Color(0.95, 0.8, 0.1), Vector3(0, 0.53, 0))
	body.set("speed", speed)
	body.set("length", length)
	body.set("stripe_count", count)
	body.set("stripes", stripes)
	_own(body)
	if route:
		routes.append([x0, x1, top])
	return body


## A crumbly biscuit platform centred on cx. It shakes when stood on, falls, and comes back.
func biscuit(cx: float, top: float, width: float = 3.0, props: Dictionary = {}, route: bool = false, thick: float = 0.5) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = "Biscuit"
	body.set_script(load("res://scripts/crumble_platform.gd"))
	sfx_for(body, "crumble_platform")
	body.position = Vector3(cx, top - thick * 0.5, 0)
	_add("Biscuits", body)
	var visual := Node3D.new()
	visual.name = "Visual"
	body.add_child(visual)
	var slab := BoxMesh.new()
	slab.size = Vector3(width, thick, 3.6)
	_mesh(visual, "Slab", slab, BISCUIT, Vector3.ZERO)
	# Chocolate chips.
	var chips: int = maxi(int(width / 0.9), 2)
	for i in chips:
		var chip := BoxMesh.new()
		chip.size = Vector3(0.22, 0.06, 0.22)
		var chip_x: float = -width * 0.5 + (float(i) + 0.5) * width / float(chips)
		_mesh(visual, "Chip", chip, Color(0.35, 0.2, 0.1), Vector3(chip_x, thick * 0.5 + 0.01, 1.2 - 0.6 * (i % 2)))
	var shape_node := _shape_box(body, Vector3(width, thick, 4.0), Vector3.ZERO)
	var sensor := Area3D.new()
	sensor.name = "Sensor"
	body.add_child(sensor)
	_shape_box(sensor, Vector3(width - 0.2, 0.5, 3.0), Vector3(0, thick * 0.5 + 0.2, 0))
	body.set("visual", visual)
	body.set("shape", shape_node)
	body.set("sensor", sensor)
	for key: String in props:
		body.set(key, props[key])
	_own(body)
	if route:
		routes.append([cx - width * 0.5, cx + width * 0.5, top])
	return body


## A red or blue switch block from x0 to x1, its top at "top". Red starts solid, blue starts ghost.
func switch_block(x0: float, x1: float, top: float, is_red: bool, route: bool = true) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = "RedBlock" if is_red else "BlueBlock"
	body.set_script(load("res://scripts/switch_block.gd"))
	body.position = Vector3((x0 + x1) * 0.5, top - 0.3, 0)
	_add("SwitchBlocks", body)
	var box := BoxMesh.new()
	box.size = Vector3(x1 - x0, 0.6, 4.0)
	var picture := _mesh(body, "Mesh", box, Color(0.9, 0.2, 0.2) if is_red else Color(0.2, 0.45, 0.95), Vector3.ZERO)
	var shape_node := _shape_box(body, box.size, Vector3.ZERO)
	body.set("is_red", is_red)
	body.set("mesh", picture)
	body.set("shape", shape_node)
	_own(body)
	if route:
		routes.append([x0, x1, top])
	return body


## The big floor button that swaps the red and blue blocks. x is its middle, top the floor.
func switch_button(x: float, top: float) -> Area3D:
	var button := Area3D.new()
	button.name = "SwitchButton"
	button.set_script(load("res://scripts/switch_button.gd"))
	sfx_for(button, "switch_button")
	button.position = Vector3(x, top, 0)
	_add("SwitchBlocks", button)
	var base := CylinderMesh.new()
	base.top_radius = 1.0
	base.bottom_radius = 1.1
	base.height = 0.15
	_mesh(button, "Base", base, STEEL_DARK, Vector3(0, 0.075, 0))
	var dome := CylinderMesh.new()
	dome.top_radius = 0.7
	dome.bottom_radius = 0.8
	dome.height = 0.3
	var cap := _mesh(button, "Cap", dome, Color(0.2, 0.45, 0.95), Vector3(0, 0.3, 0))
	_shape_box(button, Vector3(1.6, 0.8, 2.0), Vector3(0, 0.4, 0))
	button.set("cap", cap)
	_own(button)
	return button


## A sideways warp pipe whose open mouth is at x. He walks into it going enter_dir (1 = right,
## -1 = left) and pops out at "destination". The pipe body lies behind the mouth, in his way in.
func warp_pipe(x: float, top: float, enter_dir: float, destination: Vector3) -> Area3D:
	var pipe := Area3D.new()
	pipe.name = "WarpPipe"
	pipe.set_script(load("res://scripts/warp_pipe.gd"))
	sfx_for(pipe, "warp_pipe")
	pipe.position = Vector3(x, top, 0)
	_add("Pipes", pipe)
	var tube := CylinderMesh.new()
	tube.top_radius = 0.95
	tube.bottom_radius = 0.95
	tube.height = 2.4
	var tube_mesh := _mesh(pipe, "Tube", tube, ORANGE, Vector3(enter_dir * 1.2, 0.95, -0.7))
	tube_mesh.rotation_degrees = Vector3(0, 0, 90)
	var lip := CylinderMesh.new()
	lip.top_radius = 1.12
	lip.bottom_radius = 1.12
	lip.height = 0.4
	var lip_mesh := _mesh(pipe, "Lip", lip, STEEL, Vector3(0, 0.95, -0.7))
	lip_mesh.rotation_degrees = Vector3(0, 0, 90)
	var hole := BoxMesh.new()
	hole.size = Vector3(0.15, 1.5, 1.3)
	_mesh(pipe, "Mouth", hole, Color(0.05, 0.05, 0.08), Vector3(enter_dir * 0.1, 0.95, -0.7))
	_shape_box(pipe, Vector3(0.8, 1.8, 2.0), Vector3(0, 0.9, 0))
	pipe.set("enter_dir", enter_dir)
	pipe.set("destination", destination)
	_own(pipe)
	return pipe


## A sideways fan. The wind blows in the zone x0..x1, y0..y1 and pushes him while he is in the air.
## direction: 1 = blows right, -1 = blows left. The fan itself hangs behind the path at the upwind end.
func fan(x0: float, x1: float, y0: float, y1: float, direction: float = 1.0, props: Dictionary = {}) -> Area3D:
	var cx: float = (x0 + x1) * 0.5
	var cy: float = (y0 + y1) * 0.5
	var wind := Area3D.new()
	wind.name = "Fan"
	wind.set_script(load("res://scripts/fan.gd"))
	wind.position = Vector3(cx, cy, 0)
	_add("Fans", wind)
	_shape_box(wind, Vector3(x1 - x0, y1 - y0, 4.0), Vector3.ZERO)
	var fan_x: float = (x0 - cx) if direction > 0.0 else (x1 - cx)
	var housing := CylinderMesh.new()
	housing.top_radius = 2.3
	housing.bottom_radius = 2.3
	housing.height = 0.6
	var housing_mesh := _mesh(wind, "Housing", housing, STEEL_DARK, Vector3(fan_x, 0, -2.5))
	housing_mesh.rotation_degrees = Vector3(0, 0, 90)
	var blades := Node3D.new()
	blades.name = "Blades"
	blades.position = Vector3(fan_x + direction * 0.4, 0, -2.5)
	wind.add_child(blades)
	for i in 3:
		var blade := BoxMesh.new()
		blade.size = Vector3(0.12, 4.0, 0.7)
		var blade_mesh := _mesh(blades, "Blade", blade, ORANGE, Vector3.ZERO)
		blade_mesh.rotation = Vector3(PI * float(i) / 3.0, 0, 0)
	# White streaks that slide along so you can see which way the wind goes.
	var streaks := Node3D.new()
	streaks.name = "Streaks"
	wind.add_child(streaks)
	for i in 8:
		var line := BoxMesh.new()
		line.size = Vector3(1.4, 0.06, 0.06)
		var streak := _mesh(streaks, "Streak", line, Color(1, 1, 1, 0.55), Vector3(0, lerpf(y0, y1, (float(i) + 0.5) / 8.0) - cy, 0.5))
		(streak.mesh.get("material") as StandardMaterial3D).transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	wind.set("direction", direction)
	wind.set("blades", blades)
	wind.set("streaks", streaks)
	wind.set("zone_width", x1 - x0)
	for key: String in props:
		wind.set(key, props[key])
	_own(wind)
	return wind


## A steam vent in the floor at x. It puffs on a timer and launches him up.
func vent(x: float, top: float, props: Dictionary = {}) -> Area3D:
	var steam := Area3D.new()
	steam.name = "SteamVent"
	steam.set_script(load("res://scripts/steam_vent.gd"))
	sfx_for(steam, "steam_vent")
	steam.position = Vector3(x, top, 0)
	_add("Vents", steam)
	var grate := BoxMesh.new()
	grate.size = Vector3(1.2, 0.15, 1.6)
	_mesh(steam, "Grate", grate, STEEL_DARK, Vector3(0, 0.075, 0))
	var slot := BoxMesh.new()
	slot.size = Vector3(0.8, 0.05, 1.0)
	_mesh(steam, "Slot", slot, Color(0.05, 0.05, 0.08), Vector3(0, 0.16, 0))
	var height: float = 3.0
	var column := Node3D.new()
	column.name = "Column"
	column.position = Vector3(0, 0.15, 0)
	steam.add_child(column)
	var puff := CylinderMesh.new()
	puff.top_radius = 0.9
	puff.bottom_radius = 0.6
	puff.height = height
	var puff_mesh := _mesh(column, "Steam", puff, Color(1, 1, 1, 0.55), Vector3(0, height * 0.5, 0))
	(puff_mesh.mesh.get("material") as StandardMaterial3D).transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_shape_box(steam, Vector3(1.3, height, 2.0), Vector3(0, 0.15 + height * 0.5, 0))
	steam.set("column", column)
	for key: String in props:
		steam.set(key, props[key])
	_own(steam)
	vents.append([x, top, height, float(steam.get("launch_speed"))])
	return steam


## A stamping press standing on the floor at x (floor height = top). It slams on a beat.
func stamp(x: float, top: float, props: Dictionary = {}) -> Node3D:
	var press := Node3D.new()
	press.name = "StampPress"
	press.set_script(load("res://scripts/stamp_press.gd"))
	sfx_for(press, "stamp_press")
	press.position = Vector3(x, top, 0)
	_add("Presses", press)
	var thickness: float = 1.2
	var drop: float = float(props.get("drop", 3.4))
	var width: float = 3.0
	var block := AnimatableBody3D.new()
	block.name = "Block"
	block.position = Vector3(0, thickness * 0.5 + drop, 0)
	press.add_child(block)
	var visual := Node3D.new()
	visual.name = "Visual"
	block.add_child(visual)
	var slab := BoxMesh.new()
	slab.size = Vector3(width, thickness, 3.6)
	_mesh(visual, "Slab", slab, Color(0.4, 0.42, 0.48), Vector3.ZERO)
	# A hazard stripe along the bottom edge, and the piston going up out of sight.
	var warn := BoxMesh.new()
	warn.size = Vector3(width, 0.25, 0.05)
	_mesh(visual, "Warning", warn, Color(0.95, 0.8, 0.1), Vector3(0, -0.4, 1.83))
	var piston := BoxMesh.new()
	piston.size = Vector3(0.7, 30.0, 0.7)
	_mesh(visual, "Piston", piston, Color(0.25, 0.26, 0.3), Vector3(0, 15.0 + thickness * 0.5, 0))
	_shape_box(block, Vector3(width, thickness, 4.0), Vector3.ZERO)
	var hurt_zone := Area3D.new()
	hurt_zone.name = "HurtZone"
	block.add_child(hurt_zone)
	_shape_box(hurt_zone, Vector3(width - 0.2, thickness, 3.0), Vector3(0, -0.5, 0))
	# The warning shadow on the floor.
	var patch := BoxMesh.new()
	patch.size = Vector3(width, 0.04, 3.4)
	var shadow := _mesh(press, "Shadow", patch, Color(0.0, 0.0, 0.0, 0.55), Vector3(0, 0.03, 0))
	(shadow.mesh.get("material") as StandardMaterial3D).transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shadow.visible = false
	press.set("block", block)
	press.set("hurt_zone", hurt_zone)
	press.set("visual", visual)
	press.set("shadow", shadow)
	for key: String in props:
		press.set(key, props[key])
	_own(press)
	return press


# ---------------------------------------------------------------- enemies

## Adds the Bean Factory enemies to the garden ones:
## cork_bot (rolls on the floor at "top") and fizz_bat (flies in a wave around y).
func enemy(kind: String, x: float, top_or_y: float, props: Dictionary = {}) -> Node3D:
	if kind != "cork_bot" and kind != "fizz_bat":
		return super.enemy(kind, x, top_or_y, props)
	var lift: float = 0.5 if kind == "cork_bot" else 0.0
	var node := place("res://scenes/%s.tscn" % kind, kind.to_pascal_case(), Vector3(x, top_or_y + lift, 0), "Enemies")
	for key: String in props:
		node.set(key, props[key])
	return node


# ---------------------------------------------------------------- scenery

## Steel wall panels, pipes, cogs, bean-tin stacks and chimneys behind the path. Not touchable.
func factory_scenery(x0: float, x1: float, ground_y: float = 0.0) -> void:
	# Wall panels far behind.
	var wall_x: float = x0
	while wall_x < x1:
		var panel := BoxMesh.new()
		panel.size = Vector3(10.0, 70.0, 0.5)
		var shade: float = rng.randf_range(-0.05, 0.05)
		_mesh(_group("Decor"), "Panel", panel, Color(0.38 + shade, 0.4 + shade, 0.46 + shade), Vector3(wall_x + 5.0, ground_y + 25.0, -20.0))
		wall_x += 10.0
	var x: float = x0
	while x < x1:
		var z: float = -rng.randf_range(4.0, 14.0)
		match rng.randi() % 5:
			0:
				_long_pipe(x, ground_y + rng.randf_range(5.0, 14.0), z)
			1:
				_tin_stack(x, ground_y, z)
			2:
				_cog(x, ground_y + rng.randf_range(4.0, 12.0), -12.0)
			3:
				_chimney(x, ground_y, -15.0)
			4:
				_tall_pipe(x, ground_y, z)
		x += rng.randf_range(5.0, 11.0)


func _long_pipe(x: float, y: float, z: float) -> void:
	var pipe := CylinderMesh.new()
	pipe.top_radius = 0.6
	pipe.bottom_radius = 0.6
	pipe.height = rng.randf_range(8.0, 16.0)
	var color: Color = ORANGE if rng.randi() % 2 == 0 else STEEL
	var pipe_mesh := _mesh(_group("Decor"), "Pipe", pipe, color, Vector3(x, y, z))
	pipe_mesh.rotation_degrees = Vector3(0, 0, 90)


func _tall_pipe(x: float, ground_y: float, z: float) -> void:
	var pipe := CylinderMesh.new()
	pipe.top_radius = 0.5
	pipe.bottom_radius = 0.5
	pipe.height = 30.0
	_mesh(_group("Decor"), "TallPipe", pipe, STEEL, Vector3(x, ground_y + 12.0, z))


func _tin_stack(x: float, ground_y: float, z: float) -> void:
	for row in 3:
		for col in 3 - row:
			var tin := CylinderMesh.new()
			tin.top_radius = 0.7
			tin.bottom_radius = 0.7
			tin.height = 1.1
			_mesh(_group("Decor"), "Tin", tin, Color(0.8, 0.2, 0.15), Vector3(x + col * 1.5 + row * 0.75, ground_y + 0.55 + row * 1.1, z))


func _cog(x: float, y: float, z: float) -> void:
	var cog := CylinderMesh.new()
	cog.top_radius = 3.0
	cog.bottom_radius = 3.0
	cog.height = 0.6
	var cog_mesh := _mesh(_group("Decor"), "Cog", cog, Color(0.5, 0.35, 0.2), Vector3(x, y, z))
	cog_mesh.rotation_degrees = Vector3(90, 0, 0)
	for i in 4:
		var tooth := BoxMesh.new()
		tooth.size = Vector3(7.0, 1.0, 0.6)
		var tooth_mesh := _mesh(_group("Decor"), "Tooth", tooth, Color(0.5, 0.35, 0.2), Vector3(x, y, z))
		tooth_mesh.rotation = Vector3(0, 0, PI * float(i) / 4.0)


func _chimney(x: float, ground_y: float, z: float) -> void:
	var stack := CylinderMesh.new()
	stack.top_radius = 1.6
	stack.bottom_radius = 2.2
	stack.height = 24.0
	_mesh(_group("Decor"), "Chimney", stack, Color(0.55, 0.3, 0.25), Vector3(x, ground_y + 10.0, z))
	var smoke := SphereMesh.new()
	smoke.radius = 2.6
	smoke.height = 3.6
	var cloud := _mesh(_group("Decor"), "Smoke", smoke, Color(0.85, 0.85, 0.88, 0.6), Vector3(x + 1.0, ground_y + 24.5, z))
	(cloud.mesh.get("material") as StandardMaterial3D).transparency = BaseMaterial3D.TRANSPARENCY_ALPHA


# ---------------------------------------------------------------- route checking

## Same check as the garden kit, but a steam vent on a piece lets him go up much higher
## (and further) from that piece.
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
		if next[1] > prev[1]:
			prev = next
		var max_rise: float = THUNDER_POWER * THUNDER_POWER / (2.0 * GRAVITY) * SAFETY
		if not lift.is_empty():
			var speed: float = lift[3]
			max_rise = maxf(max_rise, (float(lift[2]) + speed * speed / (2.0 * GRAVITY)) * SAFETY)
		if rise > max_rise:
			problems.append("step up of %.1f m at x=%.0f is too high" % [rise, next[0]])
		elif gap > _reach(rise) and (lift.is_empty() or gap > _vent_reach(lift, rise)):
			problems.append("gap of %.1f m (rise %.1f) at x=%.0f is too far" % [gap, rise, next[0]])
	return problems


## The first steam vent standing on a route piece ([x_from, x_to, top]), or empty.
func _vent_on(piece: Array) -> Array:
	for v: Array in vents:
		if float(v[0]) >= float(piece[0]) and float(v[0]) <= float(piece[1]) and absf(float(v[1]) - float(piece[2])) < 0.01:
			return v
	return []


## How far a vent launch carries him sideways before he is down at a given rise.
func _vent_reach(pad: Array, rise: float) -> float:
	var speed: float = pad[3]
	var disc: float = speed * speed - 2.0 * GRAVITY * (rise - float(pad[2]))
	if disc < 0.0:
		return 0.0
	return RUN_SPEED * (speed + sqrt(disc)) / GRAVITY * SAFETY


# ---------------------------------------------------------------- inside the kit

## A box-shaped collision shape. Returns it, so a script can switch it off.
func _shape_box(parent: Node, size: Vector3, pos: Vector3) -> CollisionShape3D:
	var shape := BoxShape3D.new()
	shape.size = size
	var col := CollisionShape3D.new()
	col.name = "CollisionShape3D"
	col.shape = shape
	col.position = pos
	parent.add_child(col)
	return col
