extends "res://tools/level_kit.gd"
## Level kit for the tall test levels: everything in level_kit.gd plus
## one-way ledges, springs, barrel cannons, rising soup, wall-jump setup and a climb check.
## A stage says:  const KIT := "res://tools/kit_vertical.gd"

const LEAF: Color = Color(0.35, 0.75, 0.3)
const BRICK: Color = Color(0.62, 0.42, 0.32)

## How long after the first Thunder the second one is let go in the air, in seconds.
const AIR_THUNDER_AT: float = 0.5
## The spring's normal launch speed (see scripts/spring.gd).
const SPRING_POWER: float = 21.0

## When true, finish() only checks the climb and throws the stage away (used by tests).
var dry_run: bool = false
## The main climb in the order you walk it: [x, top, width, kind]. kind is "", "spring" or "carried".
var climb: Array = []
## Barrel cannons placed: [position, aim_a, aim_b, speed].
var barrels: Array = []
## Extra problems found while building (barrel shots that miss, and so on).
var extra_problems: Array[String] = []


## Like begin(), but for a test level: no saving, back to the test list afterwards,
## the camera leans up and down, and wall jump is on.
func begin_test(stage_id: String, opening: String, start: Vector3, sky: Color) -> void:
	begin(stage_id, opening, start, sky)
	root.set("stage_id", "")
	root.set("map_scene", "res://scenes/test_levels.tscn")
	camera.set("vertical_look_ahead", 0.3)
	camera.set("vertical_look_max", 4.0)
	player.set("wall_jump_enabled", true)
	var helper := Node.new()
	helper.name = "WallJump"
	helper.set_script(load("res://scripts/wall_jump.gd"))
	player.add_child(helper)
	helper.owner = root


# ---------------------------------------------------------------- ledges and walls

## A solid start floor from x0 to x1 (counts as the first step of the climb).
func base(x0: float, x1: float, top: float = 0.0, color: Color = GRASS) -> void:
	ground(x0, x1, top, color)
	climb.append([(x0 + x1) * 0.5, top, x1 - x0, ""])


## A ledge you can jump up through from below. Part of the main climb unless route is false.
## kind "spring" means he gets here with a spring bounce, "carried" means a lift brings him.
func oneway(cx: float, top: float, width: float = 4.0, color: Color = LEAF, route: bool = true, kind: String = "") -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = "OneWay"
	body.set_script(load("res://scripts/one_way_platform.gd"))
	body.position = Vector3(cx, top - 0.25, 0)
	_add("Platforms", body)
	var slab := BoxMesh.new()
	slab.size = Vector3(width, 0.5, 4.0)
	_mesh(body, "Mesh", slab, color, Vector3.ZERO)
	_collider(body, slab.size, Vector3.ZERO)
	_own(body)
	if route:
		climb.append([cx, top, width, kind])
	return body


## A wide ledge to rest on (toilets go on these). Also a safety net when he falls.
func shelf(cx: float, top: float, width: float = 12.0, color: Color = Color(0.3, 0.62, 0.28)) -> StaticBody3D:
	return oneway(cx, top, width, color)


func spring(x: float, top: float, props: Dictionary = {}) -> Node3D:
	var node := place("res://scenes/spring.tscn", "Spring", Vector3(x, top, 0), "Pads")
	for key: String in props:
		node.set(key, props[key])
	return node


## A barrel cannon at (x, y). aim: degrees (90 = up). swing_to: 0 = fixed, else it swings.
func barrel(x: float, y: float, aim: float = 90.0, swing_to: float = 0.0, speed: float = 22.0, props: Dictionary = {}) -> Node3D:
	var node := place("res://scenes/barrel_cannon.tscn", "BarrelCannon", Vector3(x, y, 0), "Barrels")
	node.set("aim_degrees", aim)
	node.set("swing_to_degrees", swing_to)
	node.set("launch_speed", speed)
	for key: String in props:
		node.set(key, props[key])
	barrels.append([Vector3(x, y, 0), aim, swing_to if swing_to != 0.0 else aim, speed])
	return node


## Hot bean soup rising from below. Pass any RisingSoup setting in props.
func soup(start_y: float, props: Dictionary = {}) -> Node3D:
	var node := Node3D.new()
	node.name = "BeanSoup"
	node.set_script(load("res://scripts/rising_soup.gd"))
	node.set("start_y", start_y)
	for key: String in props:
		node.set(key, props[key])
	node.position = Vector3(0, start_y, 0)
	_add("Hazards", node)
	# A tall block of orange soup hanging down from the surface, with a frothy top and bubbles.
	var body := BoxMesh.new()
	body.size = Vector3(80.0, 60.0, 12.0)
	var glow := _mesh(node, "Soup", body, Color(0.95, 0.45, 0.1, 0.82), Vector3(0, -30.0, 0))
	(glow.mesh.get("material") as StandardMaterial3D).transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var froth := BoxMesh.new()
	froth.size = Vector3(80.0, 0.3, 12.2)
	_mesh(node, "Froth", froth, Color(1.0, 0.8, 0.35), Vector3(0, -0.1, 0))
	for i in 9:
		var bubble := SphereMesh.new()
		bubble.radius = 0.35 + 0.1 * (i % 3)
		bubble.height = bubble.radius * 2.0
		_mesh(node, "Bubble", bubble, Color(1.0, 0.7, 0.3), Vector3(-16.0 + i * 4.0, 0.05, 4.0 + (i % 2) * 1.5))
	_own(node)
	return node


# ---------------------------------------------------------------- scenery

## A giant beanstalk behind the climb, with leaves and clouds.
func beanstalk_scenery(height: float, x: float = 0.0) -> void:
	var stalk := CylinderMesh.new()
	stalk.top_radius = 1.5
	stalk.bottom_radius = 2.4
	stalk.height = height + 20.0
	_mesh(_group("Decor"), "Stalk", stalk, Color(0.25, 0.6, 0.22), Vector3(x, height * 0.5 - 5.0, -7.0))
	var y: float = 4.0
	var side: float = 1.0
	while y < height:
		var leaf := BoxMesh.new()
		leaf.size = Vector3(7.0, 0.3, 4.0)
		var mesh := _mesh(_group("Decor"), "Leaf", leaf, Color(0.3, 0.7, 0.28).lightened(rng.randf_range(0.0, 0.2)), Vector3(x + side * 5.0, y, -7.0))
		mesh.rotation_degrees.z = side * 18.0
		side = -side
		y += rng.randf_range(4.0, 6.5)
	_clouds(height)


## Brick walls round a tower and a darker wall behind it. Solid walls at x0 and x1.
func tower_scenery(x0: float, x1: float, y0: float, y1: float) -> void:
	var back := BoxMesh.new()
	back.size = Vector3(x1 - x0, y1 - y0, 0.3)
	_mesh(_group("Decor"), "BackWall", back, Color(0.5, 0.36, 0.3), Vector3((x0 + x1) * 0.5, (y0 + y1) * 0.5, -2.4))
	var y: float = y0
	while y < y1:
		var stripe := BoxMesh.new()
		stripe.size = Vector3(x1 - x0, 0.15, 0.1)
		_mesh(_group("Decor"), "Stripe", stripe, Color(0.4, 0.28, 0.24), Vector3((x0 + x1) * 0.5, y, -2.2))
		y += 2.0
	block(x0 - 1.0, x0, y0, y1, BRICK)
	block(x1, x1 + 1.0, y0, y1, BRICK)


func _clouds(height: float) -> void:
	var y: float = 6.0
	while y < height + 10.0:
		var puff := SphereMesh.new()
		puff.radius = rng.randf_range(3.0, 5.0)
		puff.height = puff.radius * 1.2
		_mesh(_group("Decor"), "Cloud", puff, Color(1, 1, 1), Vector3(rng.randf_range(-28.0, 28.0), y, rng.randf_range(-22.0, -12.0)))
		y += rng.randf_range(4.0, 8.0)


# ---------------------------------------------------------------- checks

## How far across he can get while climbing "rise" metres, using a Thunder and then a
## second Thunder in the air (with the usual safety margin).
func two_jump_reach(rise: float) -> float:
	var target: float = rise / SAFETY
	var y_at_second: float = THUNDER_POWER * AIR_THUNDER_AT - 0.5 * GRAVITY * AIR_THUNDER_AT * AIR_THUNDER_AT
	var disc: float = THUNDER_POWER * THUNDER_POWER - 2.0 * GRAVITY * (target - y_at_second)
	if disc < 0.0:
		return 0.0
	var air: float = AIR_THUNDER_AT + (THUNDER_POWER + sqrt(disc)) / GRAVITY
	return RUN_SPEED * air * SAFETY


## The biggest step up (metres) that a Thunder then an air Thunder can do, with safety.
func two_jump_rise() -> float:
	var y_at_second: float = THUNDER_POWER * AIR_THUNDER_AT - 0.5 * GRAVITY * AIR_THUNDER_AT * AIR_THUNDER_AT
	return (y_at_second + THUNDER_POWER * THUNDER_POWER / (2.0 * GRAVITY)) * SAFETY


## Checks every step of the main climb (in walking order) can be done.
## One Thunder does steps up to about 4 m. Bigger steps need an air Thunder as well.
## Spring steps need the spring's bounce to be high enough. Returns problems.
func check_climb() -> Array[String]:
	var problems: Array[String] = []
	var single: float = THUNDER_POWER * THUNDER_POWER / (2.0 * GRAVITY) * SAFETY
	var spring_rise: float = SPRING_POWER * SPRING_POWER / (2.0 * GRAVITY) * SAFETY
	for i in range(1, climb.size()):
		var a: Array = climb[i - 1]
		var b: Array = climb[i]
		var rise: float = b[1] - a[1]
		var gap: float = maxf(absf(b[0] - a[0]) - (a[2] + b[2]) * 0.5, 0.0)
		var where: String = "step %d (x=%.1f, top=%.1f)" % [i, b[0], b[1]]
		if b[3] == "carried":
			# A lift or moving platform takes him across: only the step up counts.
			if rise > single:
				problems.append("%s: carried step up of %.1f m is too high" % [where, rise])
		elif b[3] == "spring":
			if rise > spring_rise:
				problems.append("%s: spring step of %.1f m is more than a spring gives (%.1f m)" % [where, rise, spring_rise])
			elif gap > 2.0:
				problems.append("%s: spring step is %.1f m sideways, too far" % [where, gap])
		elif rise > two_jump_rise():
			problems.append("%s: step up of %.1f m is more than two Thunders (%.1f m)" % [where, rise, two_jump_rise()])
		elif rise > single:
			if gap > two_jump_reach(rise):
				problems.append("%s: step up %.1f m with a %.1f m gap is too far for two Thunders" % [where, rise, gap])
		elif gap > _reach(rise):
			problems.append("%s: step up %.1f m with a %.1f m gap is too far" % [where, rise, gap])
	return problems


## Where a barrel shot is after t seconds (straight line plus gravity).
func _shot_at(i: int, angle_deg: float, t: float) -> Vector3:
	var b: Array = barrels[i]
	var a: float = deg_to_rad(angle_deg)
	var v: Vector3 = Vector3(cos(a), sin(a), 0.0) * float(b[3])
	return (b[0] as Vector3) + v * t + Vector3(0.0, -0.5 * GRAVITY * t * t, 0.0)


## The angles a barrel can point at (a few samples across its swing).
func _aims(i: int) -> Array[float]:
	var b: Array = barrels[i]
	var found: Array[float] = []
	for s in 7:
		found.append(lerpf(float(b[1]), float(b[2]), float(s) / 6.0))
	return found


## Checks that a shot from barrel i (at every aim it can have) passes within "reach"
## metres of barrel j.
func check_barrel_to_barrel(i: int, j: int, reach: float = 1.2) -> bool:
	var target: Vector3 = (barrels[j][0] as Vector3)
	for angle in _aims(i):
		var closest: float = 1e9
		for step in 400:
			closest = minf(closest, _shot_at(i, angle, step * 0.01).distance_to(target))
		if closest > reach:
			extra_problems.append("barrel %d at aim %.0f misses barrel %d (%.1f m away)" % [i, angle, j, closest])
			return false
	return true


## Checks that a shot from barrel i (at every aim it can have) comes down onto a ledge
## from x0 to x1 whose top is at "top".
func check_barrel_to_ledge(i: int, x0: float, x1: float, top: float) -> bool:
	for angle in _aims(i):
		var landed: bool = false
		var last: Vector3 = _shot_at(i, angle, 0.0)
		for step in range(1, 600):
			var p: Vector3 = _shot_at(i, angle, step * 0.01)
			if last.y > top + 1.0 and p.y <= top + 1.0 and p.x > x0 + 0.3 and p.x < x1 - 0.3:
				landed = true
				break
			last = p
		if not landed:
			extra_problems.append("barrel %d at aim %.0f does not land on the ledge" % [i, angle])
			return false
	return true


## Saves the stage and checks the climb and barrel shots. Returns every problem found.
func finish(path: String) -> Array[String]:
	var problems: Array[String] = check_climb()
	problems.append_array(extra_problems)
	for p: String in problems:
		print("CLIMB PROBLEM ", path, ": ", p)
	if dry_run:
		root.free()
		return problems
	problems.append_array(super.finish(path))
	return problems
