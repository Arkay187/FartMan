extends RefCounted
# Builds the 3D world map for world_map.tscn: sky, light, the three worlds, the 12 stops,
# the dotted path and the Bean Blimp. Everything is grey-box low-poly with flat colour.
# Called from build_scenes.gd (_build_world_map). Nothing here runs in the game.
#
# Layout: x runs left to right, z comes towards the camera, y is up.
# Each stop is a node "Stop_<id>" with: Look (platform + landmark), Flag, Lock, Pips.

const STOP_RADIUS: float = 3.2
const BOSS_RADIUS: float = 4.2

var _materials: Dictionary = {}


## Adds all the 3D things under "root" and returns {ship, camera, stops}.
func build(root: Control) -> Dictionary:
	var world := Node3D.new()
	world.name = "Diorama"
	root.add_child(world)
	_environment(world)
	_sea(world)
	_world_garden(world)
	_world_factory(world)
	_world_whiff(world)
	var stops: Node3D = _stops(world)
	_path(world)
	var ship: Node3D = _ship(root)
	var camera := Camera3D.new()
	camera.name = "Camera"
	camera.set_script(load("res://scripts/map_camera.gd"))
	camera.fov = 55.0
	root.add_child(camera)
	camera.set("target", ship)
	_own_all(root, root)
	return {"ship": ship, "camera": camera, "stops": stops}


# ---------- little helpers ----------

func _mat(color: Color) -> StandardMaterial3D:
	var key: String = color.to_html(true)
	if not _materials.has(key):
		var material := StandardMaterial3D.new()
		material.albedo_color = color
		material.roughness = 1.0
		if color.a < 1.0:
			material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_materials[key] = material
	return _materials[key]


func _add(parent: Node, node_name: String, mesh: PrimitiveMesh, pos: Vector3, color: Color, rot_deg: Vector3 = Vector3.ZERO, scale: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	mesh.material = _mat(color)
	instance.position = pos
	instance.rotation_degrees = rot_deg
	instance.scale = scale
	parent.add_child(instance)
	return instance


func _box(parent: Node, node_name: String, size: Vector3, pos: Vector3, color: Color, rot_deg: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return _add(parent, node_name, mesh, pos, color, rot_deg)


func _cyl(parent: Node, node_name: String, radius: float, height: float, pos: Vector3, color: Color, rot_deg: Vector3 = Vector3.ZERO, top_radius: float = -1.0) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius if top_radius < 0.0 else top_radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 10
	mesh.rings = 1
	return _add(parent, node_name, mesh, pos, color, rot_deg)


func _ball(parent: Node, node_name: String, radius: float, pos: Vector3, color: Color, scale: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 10
	mesh.rings = 5
	return _add(parent, node_name, mesh, pos, color, Vector3.ZERO, scale)


func _roof(parent: Node, node_name: String, size: Vector3, pos: Vector3, color: Color) -> MeshInstance3D:
	var mesh := PrismMesh.new()
	mesh.size = size
	return _add(parent, node_name, mesh, pos, color)


func _ring(parent: Node, node_name: String, inner: float, outer: float, pos: Vector3, color: Color, rot_deg: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mesh := TorusMesh.new()
	mesh.inner_radius = inner
	mesh.outer_radius = outer
	mesh.rings = 14
	mesh.ring_segments = 6
	return _add(parent, node_name, mesh, pos, color, rot_deg)


func _holder(parent: Node, node_name: String, pos: Vector3) -> Node3D:
	var holder := Node3D.new()
	holder.name = node_name
	holder.position = pos
	parent.add_child(holder)
	return holder


# Everything we made belongs to the scene, so it is saved.
func _own_all(node: Node, owner_node: Node) -> void:
	for child in node.get_children():
		child.owner = owner_node
		_own_all(child, owner_node)


# ---------- sky, light, sea ----------

func _environment(parent: Node3D) -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.35, 0.6, 0.95)
	sky_material.sky_horizon_color = Color(0.82, 0.9, 1.0)
	sky_material.ground_horizon_color = Color(0.82, 0.9, 1.0)
	sky_material.ground_bottom_color = Color(0.55, 0.75, 0.95)
	sky.sky_material = sky_material
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 1.1
	var world_env := WorldEnvironment.new()
	world_env.name = "Sky"
	world_env.environment = env
	parent.add_child(world_env)
	# One soft sun from the front left.
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-52.0, -30.0, 0.0)
	sun.light_energy = 0.9
	sun.shadow_enabled = true
	parent.add_child(sun)


# A big flat sea the two ground worlds sit in.
func _sea(parent: Node3D) -> void:
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(900.0, 500.0)
	_add(parent, "Sea", mesh, Vector3(80.0, -2.2, 0.0), Color(0.45, 0.75, 0.95))


# ---------- the three worlds ----------

func _world_garden(parent: Node3D) -> void:
	var world := _holder(parent, "GrandmasGarden", Vector3.ZERO)
	var green: Color = MapStops.WORLDS[0]["color"]
	_box(world, "Ground", Vector3(72.0, 3.0, 36.0), Vector3(18.0, -1.5, 0.0), green)
	# Grandma's little house at the start.
	var house := _holder(world, "House", Vector3(-9.0, 0.0, -6.0))
	_box(house, "Walls", Vector3(4.0, 2.6, 3.4), Vector3(0, 1.3, 0), Color(0.98, 0.93, 0.8))
	_roof(house, "Roof", Vector3(4.8, 1.6, 4.0), Vector3(0, 3.4, 0), Color(0.8, 0.28, 0.25))
	_box(house, "Door", Vector3(0.9, 1.5, 0.1), Vector3(0.0, 0.75, 1.72), Color(0.5, 0.3, 0.15))
	_box(house, "Window", Vector3(0.8, 0.8, 0.1), Vector3(1.3, 1.6, 1.72), Color(0.6, 0.85, 1.0))
	_box(house, "Chimney", Vector3(0.6, 1.4, 0.6), Vector3(1.3, 3.9, -0.7), Color(0.6, 0.35, 0.3))
	# Rolling hills at the back and some round trees.
	var hills: Array[Vector3] = [Vector3(-6, 0, -17), Vector3(10, 0, -15), Vector3(28, 0, -16), Vector3(46, 0, -14)]
	for i in hills.size():
		_ball(world, "Hill%d" % i, 6.0, hills[i] + Vector3(0, -1.0, 0), green.lightened(0.08 * float(i % 2)), Vector3(1.8, 0.7, 1.2))
	var trees: Array[Vector3] = [Vector3(-12, 0, 8), Vector3(6, 0, 13), Vector3(20, 0, 12), Vector3(36, 0, 11), Vector3(48, 0, 8), Vector3(-2, 0, -10), Vector3(24, 0, -9), Vector3(34, 0, -12), Vector3(50, 0, -6)]
	for i in trees.size():
		var tree := _holder(world, "Tree%d" % i, trees[i])
		_cyl(tree, "Trunk", 0.3, 1.8, Vector3(0, 0.9, 0), Color(0.5, 0.33, 0.2))
		_ball(tree, "Leaves", 1.5, Vector3(0, 2.8, 0), Color(0.25, 0.62, 0.3), Vector3(1.0, 1.1, 1.0))


func _world_factory(parent: Node3D) -> void:
	var world := _holder(parent, "BeanFactory", Vector3.ZERO)
	var grey: Color = MapStops.WORLDS[1]["color"]
	_box(world, "Ground", Vector3(60.0, 3.0, 36.0), Vector3(83.0, -1.5, 0.0), grey)
	# Big grey factory blocks along the back, with chimneys and puffs of smoke.
	var blocks: Array[Vector3] = [Vector3(58, 0, -13), Vector3(72, 0, -15), Vector3(86, 0, -13), Vector3(100, 0, -15)]
	var heights: Array[float] = [5.0, 7.0, 4.0, 6.0]
	for i in blocks.size():
		var block := _holder(world, "Block%d" % i, blocks[i])
		_box(block, "Walls", Vector3(8.0, heights[i], 6.0), Vector3(0, heights[i] * 0.5, 0), grey.darkened(0.25 + 0.05 * float(i % 2)))
		_box(block, "Door", Vector3(1.6, 2.0, 0.1), Vector3(0, 1.0, 3.02), Color(0.3, 0.3, 0.33))
		_cyl(block, "Chimney", 0.7, 3.0, Vector3(2.4, heights[i] + 1.5, 0), Color(0.55, 0.3, 0.25))
		_ball(block, "Smoke1", 0.9, Vector3(2.4, heights[i] + 3.6, 0), Color(0.85, 0.85, 0.88, 0.8))
		_ball(block, "Smoke2", 1.2, Vector3(2.9, heights[i] + 4.9, 0), Color(0.85, 0.85, 0.88, 0.6))
	# Orange pipes snaking across the front.
	var pipe_color := Color(0.92, 0.55, 0.2)
	for i in 3:
		var x: float = 65.0 + 17.0 * float(i)
		_cyl(world, "Pipe%d" % i, 0.5, 9.0, Vector3(x, 1.0, 11.0), pipe_color, Vector3(0, 0, 90))
		_cyl(world, "PipeLeg%d" % i, 0.5, 2.5, Vector3(x + 4.5, 0.25, 11.0), pipe_color)
	_cyl(world, "BigTank", 2.5, 4.0, Vector3(110.0, 2.0, 8.0), Color(0.55, 0.65, 0.7))


func _world_whiff(parent: Node3D) -> void:
	var world := _holder(parent, "PlanetWhiff", Vector3.ZERO)
	var purple: Color = MapStops.WORLDS[2]["color"]
	var sky_y: float = MapStops.SKY_HEIGHT
	# Soft purple gas clouds the stops float on, with more drifting round them.
	for stop: Dictionary in MapStops.STOPS:
		if stop["world"] != 2:
			continue
		var pos: Vector3 = stop["pos"]
		var cloud := _holder(world, "Cloud_" + str(stop["id"]), Vector3(pos.x, sky_y - 3.0, pos.z))
		_ball(cloud, "Puff1", 6.0, Vector3(0, 0, 0), purple, Vector3(1.0, 0.45, 1.0))
		_ball(cloud, "Puff2", 3.5, Vector3(-4.5, -0.6, 1.0), purple.lightened(0.15), Vector3(1.0, 0.6, 1.0))
		_ball(cloud, "Puff3", 3.0, Vector3(4.5, -0.8, -1.0), purple.lightened(0.1), Vector3(1.0, 0.6, 1.0))
	var drift: Array[Vector3] = [Vector3(112, 4, -8), Vector3(125, 14, -12), Vector3(140, 3, -10), Vector3(152, 15, 8), Vector3(164, 5, 8), Vector3(124, 2, 12)]
	for i in drift.size():
		_ball(world, "Drift%d" % i, 3.0, drift[i], Color(0.85, 0.7, 0.95, 0.85), Vector3(1.6, 0.6, 1.0))
	# Swirly rings that slowly turn.
	var rings: Array[Vector3] = [Vector3(125, sky_y + 5, -2), Vector3(139, sky_y + 6, 1), Vector3(152, sky_y + 5, 0)]
	for i in rings.size():
		var spinner := _holder(world, "Swirl%d" % i, rings[i])
		spinner.set_script(load("res://scripts/map_spin.gd"))
		spinner.set("degrees_per_second", Vector3(40.0, 30.0 + 10.0 * float(i), 0.0))
		_ring(spinner, "Ring", 2.2, 3.0, Vector3.ZERO, Color(0.95, 0.5, 0.85, 0.8), Vector3(70, 0, 0))
		_ring(spinner, "InnerRing", 1.1, 1.6, Vector3.ZERO, Color(0.5, 0.9, 0.85, 0.8), Vector3(70, 0, 0))
	# Alien plants on the cloud tops.
	var plants: Array[Vector3] = [Vector3(114, sky_y, 8), Vector3(123, sky_y, -1), Vector3(128, sky_y, -8), Vector3(137, sky_y, 1), Vector3(143, sky_y, 9), Vector3(151, sky_y, 0), Vector3(163, sky_y, 2)]
	for i in plants.size():
		var plant := _holder(world, "Plant%d" % i, plants[i])
		var tint: Color = Color(0.3, 0.85, 0.75) if i % 2 == 0 else Color(0.95, 0.45, 0.7)
		_cyl(plant, "Stalk", 0.15, 2.2, Vector3(0, 1.1, 0), tint.darkened(0.2), Vector3(0, 0, 8.0 * float(i % 3 - 1)))
		_ball(plant, "Bulb", 0.7, Vector3(0, 2.4, 0), tint)
		_ball(plant, "Bulb2", 0.4, Vector3(0.6, 1.7, 0), tint.lightened(0.2))


# ---------- the stops ----------

func _stops(parent: Node3D) -> Node3D:
	var holder := _holder(parent, "Stops", Vector3.ZERO)
	for stop: Dictionary in MapStops.STOPS:
		var node := _holder(holder, "Stop_" + str(stop["id"]), stop["pos"])
		var look := _holder(node, "Look", Vector3.ZERO)
		var world_color: Color = MapStops.WORLDS[stop["world"]]["color"]
		var radius: float = BOSS_RADIUS if stop["kind"] == "boss" else STOP_RADIUS
		# The round platform, with a lighter top ring so it stands out from the ground.
		_cyl(look, "Platform", radius, 0.7, Vector3(0, 0.35, 0), world_color.darkened(0.2))
		_cyl(look, "Top", radius - 0.5, 0.1, Vector3(0, 0.72, 0), world_color.lightened(0.3))
		_landmark(look, stop)
		_flag(node, radius)
		_lock(node)
		_pips(node)
	return holder


# The little building or machine that says what the stop is. Surface is at y = 0.75.
func _landmark(look: Node3D, stop: Dictionary) -> void:
	var id: String = stop["id"]
	if stop["kind"] == "fly":
		_launch_pad(look, int(stop["world"]))
	match id:
		"1-1":  # the veg patch: soil rows with cabbages
			for r in 3:
				var x: float = -1.4 + 1.4 * float(r)
				_box(look, "Row%d" % r, Vector3(0.9, 0.3, 3.2), Vector3(x, 0.85, 0), Color(0.45, 0.3, 0.18))
				for c in 3:
					_ball(look, "Cabbage%d_%d" % [r, c], 0.38, Vector3(x, 1.2, -1.1 + 1.1 * float(c)), Color(0.35, 0.75, 0.3) if c % 2 == 0 else Color(0.85, 0.35, 0.5))
		"1-2":  # the greenhouse: glass box with plants
			_box(look, "Frame", Vector3(3.6, 0.2, 2.8), Vector3(0, 0.85, 0), Color(0.95, 0.95, 0.95))
			_box(look, "Glass", Vector3(3.4, 2.0, 2.6), Vector3(0, 1.85, 0), Color(0.7, 0.95, 1.0, 0.45))
			_roof(look, "GlassRoof", Vector3(3.6, 1.0, 2.8), Vector3(0, 3.35, 0), Color(0.8, 1.0, 1.0, 0.5))
			for p in 3:
				_ball(look, "Plant%d" % p, 0.4, Vector3(-1.0 + 1.0 * float(p), 1.25, 0), Color(0.3, 0.7, 0.3))
		"1-4":  # Sneezy Weezy: a big pink flower
			_cyl(look, "Stem", 0.25, 2.4, Vector3(0, 1.95, 0), Color(0.3, 0.65, 0.3))
			for p in 6:
				var angle: float = TAU * float(p) / 6.0
				_ball(look, "Petal%d" % p, 0.7, Vector3(cos(angle) * 1.2, 3.3 + sin(angle) * 1.2, 0.2), Color(0.98, 0.6, 0.78), Vector3(1, 1, 0.5))
			_ball(look, "Centre", 0.8, Vector3(0, 3.3, 0.35), Color(1.0, 0.85, 0.2))
		"2-1":  # the conveyor belts
			_box(look, "Belt", Vector3(4.6, 0.4, 1.6), Vector3(0, 1.0, 0), Color(0.25, 0.25, 0.28))
			_cyl(look, "RollerL", 0.4, 1.6, Vector3(-2.3, 1.0, 0), Color(0.6, 0.6, 0.65), Vector3(90, 0, 0))
			_cyl(look, "RollerR", 0.4, 1.6, Vector3(2.3, 1.0, 0), Color(0.6, 0.6, 0.65), Vector3(90, 0, 0))
			_box(look, "Crate1", Vector3(0.8, 0.8, 0.8), Vector3(-1.0, 1.6, 0), Color(0.75, 0.55, 0.3))
			_box(look, "Crate2", Vector3(0.7, 0.7, 0.7), Vector3(1.0, 1.55, 0), Color(0.75, 0.55, 0.3))
		"2-2":  # the pipe maze
			var pipe := Color(0.92, 0.55, 0.2)
			_cyl(look, "PipeA", 0.4, 4.0, Vector3(0, 1.4, 0.8), pipe, Vector3(0, 0, 90))
			_cyl(look, "PipeB", 0.4, 2.4, Vector3(-2.0, 2.2, 0.8), pipe)
			_cyl(look, "PipeC", 0.4, 3.0, Vector3(1.0, 2.4, -0.8), pipe, Vector3(90, 0, 0))
			_cyl(look, "PipeD", 0.4, 2.0, Vector3(2.0, 1.8, -2.0), pipe)
		"2-4":  # Colonel Cork: a giant cork with a red hat
			_cyl(look, "Cork", 1.2, 2.6, Vector3(0, 2.05, 0), Color(0.82, 0.62, 0.38), Vector3.ZERO, 0.95)
			_cyl(look, "Hat", 1.4, 0.3, Vector3(0, 3.5, 0), Color(0.8, 0.2, 0.2))
			_cyl(look, "HatTop", 0.8, 0.5, Vector3(0, 3.8, 0), Color(0.8, 0.2, 0.2))
			_box(look, "Stripe", Vector3(2.4, 0.2, 0.1), Vector3(0, 2.0, 1.1), Color(0.95, 0.8, 0.2))
		"3-1":  # the cloud tops: puffs and a crystal
			_ball(look, "Puff1", 1.2, Vector3(-1.2, 1.6, 0), Color(0.9, 0.82, 1.0), Vector3(1.3, 0.8, 1.0))
			_ball(look, "Puff2", 1.0, Vector3(0.8, 1.5, 0.8), Color(0.95, 0.9, 1.0), Vector3(1.3, 0.8, 1.0))
			_cyl(look, "Crystal", 0.5, 2.0, Vector3(1.0, 1.8, -0.8), Color(0.5, 0.9, 0.9), Vector3.ZERO, 0.0)
		"3-2":  # the fizzy fortress: two towers and a bubble
			_box(look, "Wall", Vector3(3.6, 1.6, 1.0), Vector3(0, 1.55, 0), Color(0.55, 0.45, 0.7))
			for side: float in [-1.0, 1.0]:
				_cyl(look, "Tower%d" % int(side), 0.8, 3.2, Vector3(side * 1.8, 2.35, 0), Color(0.6, 0.5, 0.78))
				_cyl(look, "TowerTop%d" % int(side), 1.0, 0.3, Vector3(side * 1.8, 4.1, 0), Color(0.75, 0.35, 0.65))
			_ball(look, "Bubble", 0.7, Vector3(0, 2.9, 0.6), Color(0.7, 1.0, 0.95, 0.6))
		"3-4":  # Big Bad Burp: a giant bubble with a cross face
			_ball(look, "Burp", 1.9, Vector3(0, 2.8, 0), Color(0.6, 0.95, 0.5, 0.7))
			_ball(look, "EyeL", 0.3, Vector3(-0.7, 3.2, 1.65), Color(0.1, 0.1, 0.1))
			_ball(look, "EyeR", 0.3, Vector3(0.7, 3.2, 1.65), Color(0.1, 0.1, 0.1))
			_box(look, "Mouth", Vector3(1.0, 0.3, 0.2), Vector3(0, 2.3, 1.75), Color(0.1, 0.1, 0.1))


# A flight stop: a striped launch pad with two boosters and fluffy little clouds round the edge.
func _launch_pad(look: Node3D, world: int) -> void:
	var cloud: Color = Color(1.0, 1.0, 1.0) if world < 2 else Color(0.9, 0.82, 1.0)
	_cyl(look, "Pad", 1.9, 0.25, Vector3(0, 0.88, 0), Color(0.9, 0.25, 0.25))
	_cyl(look, "PadStripe", 1.0, 0.27, Vector3(0, 0.89, 0), Color(1.0, 0.95, 0.4))
	_roof(look, "Arrow", Vector3(1.0, 0.2, 1.4), Vector3(0, 1.1, 0), Color(0.2, 0.2, 0.25))
	_cyl(look, "BoosterL", 0.3, 1.2, Vector3(-1.4, 1.6, 0), Color(0.7, 0.7, 0.75))
	_cyl(look, "BoosterR", 0.3, 1.2, Vector3(1.4, 1.6, 0), Color(0.7, 0.7, 0.75))
	for i in 5:
		var angle: float = TAU * float(i) / 5.0 + 0.4
		_ball(look, "Puff%d" % i, 0.8, Vector3(cos(angle) * 2.9, 0.4, sin(angle) * 2.9), cloud, Vector3(1.0, 0.7, 1.0))


# The flag that shows a stop is cleared: a pole and a little red pennant.
func _flag(node: Node3D, radius: float) -> void:
	var flag := _holder(node, "Flag", Vector3(radius - 0.9, 0.7, 0.9))
	_cyl(flag, "Pole", 0.07, 2.6, Vector3(0, 1.3, 0), Color(0.95, 0.95, 0.95))
	_roof(flag, "Pennant", Vector3(0.9, 1.2, 0.06), Vector3(0.6, 2.2, 0), Color(0.9, 0.2, 0.25)).rotation_degrees = Vector3(0, 0, -90)
	flag.visible = false


# The padlock over a stop that is not open yet.
func _lock(node: Node3D) -> void:
	var lock := _holder(node, "Lock", Vector3(0, 3.0, 0))
	_box(lock, "Body", Vector3(1.1, 0.9, 0.5), Vector3(0, 0, 0), Color(0.95, 0.75, 0.15))
	_ring(lock, "Shackle", 0.28, 0.42, Vector3(0, 0.65, 0), Color(0.75, 0.75, 0.8), Vector3(90, 0, 0))
	_box(lock, "Keyhole", Vector3(0.15, 0.3, 0.1), Vector3(0, 0, 0.26), Color(0.15, 0.15, 0.15))
	lock.visible = false


# Three Golden Bean pips going slowly round the stop.
func _pips(node: Node3D) -> void:
	var pips := _holder(node, "Pips", Vector3(0, 2.4, 0))
	pips.set_script(load("res://scripts/map_spin.gd"))
	pips.set("degrees_per_second", Vector3(0.0, 70.0, 0.0))
	for i in 3:
		var angle: float = TAU * float(i) / 3.0
		_ball(pips, "Pip%d" % i, 0.32, Vector3(cos(angle) * 2.4, 0.0, sin(angle) * 2.4), Color(1.0, 0.82, 0.1), Vector3(1.0, 1.2, 0.8))
	pips.visible = false


# The dotted path between stops, as little cream discs on the ground (or in the sky).
func _path(parent: Node3D) -> void:
	var holder := _holder(parent, "Path", Vector3.ZERO)
	var count: int = 0
	for i in MapStops.STOPS.size() - 1:
		var a: Vector3 = MapStops.STOPS[i]["pos"]
		var b: Vector3 = MapStops.STOPS[i + 1]["pos"]
		var length: float = a.distance_to(b)
		var steps: int = int(length / 1.7)
		for s in range(1, steps):
			var spot: Vector3 = a.lerp(b, float(s) / float(steps))
			# Keep the dots off the platforms.
			var from_a: float = Vector2(spot.x - a.x, spot.z - a.z).length()
			var from_b: float = Vector2(spot.x - b.x, spot.z - b.z).length()
			if from_a < STOP_RADIUS + 0.8 or from_b < STOP_RADIUS + 0.8:
				continue
			_cyl(holder, "Dot%d" % count, 0.28, 0.1, spot + Vector3(0, 0.08, 0), Color(1.0, 0.95, 0.7))
			count += 1


# ---------- the Bean Blimp ----------

func _ship(root: Control) -> Node3D:
	var ship := Node3D.new()
	ship.name = "Ship"
	ship.set_script(load("res://scripts/map_ship.gd"))
	root.add_child(ship)
	var rig := _holder(ship, "Rig", Vector3.ZERO)
	var bean := Color(0.78, 0.45, 0.25)
	# A bean shaped body: a long middle with a round lump at each end.
	_ball(rig, "Body", 1.0, Vector3(0, 0.5, 0), bean, Vector3(2.9, 1.35, 1.35))
	_ball(rig, "Nose", 1.0, Vector3(1.9, 0.3, 0), bean.lightened(0.05), Vector3(1.2, 1.1, 1.15))
	_ball(rig, "Rear", 1.0, Vector3(-1.9, 0.6, 0), bean.darkened(0.05), Vector3(1.2, 1.0, 1.1))
	_ball(rig, "Belly", 1.0, Vector3(0.2, 0.2, 0.0), bean.lightened(0.2), Vector3(2.0, 1.1, 1.2))
	_ring(rig, "StripeA", 1.28, 1.42, Vector3(0.6, 0.5, 0), Color(1.0, 0.82, 0.1), Vector3(0, 0, 90))
	_ring(rig, "StripeB", 1.28, 1.42, Vector3(-0.7, 0.5, 0), Color(1.0, 0.82, 0.1), Vector3(0, 0, 90))
	# Tail fins and the propeller at the back.
	var red := Color(0.85, 0.25, 0.2)
	_box(rig, "TailFin", Vector3(1.0, 1.4, 0.12), Vector3(-3.1, 1.2, 0), red, Vector3(0, 0, 18))
	_box(rig, "TailWing", Vector3(1.0, 0.1, 1.8), Vector3(-3.1, 0.6, 0), red)
	_ball(rig, "Hub", 0.25, Vector3(-3.6, 0.5, 0), Color(0.3, 0.3, 0.35))
	var prop := _holder(rig, "Propeller", Vector3(-3.7, 0.5, 0))
	prop.set_script(load("res://scripts/map_spin.gd"))
	prop.set("degrees_per_second", Vector3(900.0, 0.0, 0.0))
	_box(prop, "BladeA", Vector3(0.06, 2.0, 0.3), Vector3.ZERO, Color(0.9, 0.9, 0.95))
	_box(prop, "BladeB", Vector3(0.06, 0.3, 2.0), Vector3.ZERO, Color(0.9, 0.9, 0.95))
	# The gondola slung underneath on four ropes.
	var wood := Color(0.55, 0.36, 0.2)
	_box(rig, "GondolaFloor", Vector3(1.9, 0.2, 1.3), Vector3(0, -2.4, 0), wood)
	_box(rig, "GondolaFront", Vector3(1.9, 0.7, 0.12), Vector3(0, -2.05, 0.6), wood.lightened(0.1))
	_box(rig, "GondolaBack", Vector3(1.9, 0.7, 0.12), Vector3(0, -2.05, -0.6), wood)
	_box(rig, "GondolaLeft", Vector3(0.12, 0.7, 1.3), Vector3(-0.9, -2.05, 0), wood)
	_box(rig, "GondolaRight", Vector3(0.12, 0.7, 1.3), Vector3(0.9, -2.05, 0), wood)
	for corner in 4:
		var rope_x: float = -0.8 if corner % 2 == 0 else 0.8
		var rope_z: float = -0.5 if corner < 2 else 0.5
		_cyl(rig, "Rope%d" % corner, 0.04, 1.1, Vector3(rope_x, -1.2, rope_z), Color(0.9, 0.85, 0.7))
	# Fart Man: a little capsule in his green suit with a round head and white goggles.
	var pilot := _holder(rig, "Pilot", Vector3(0, -1.85, 0))
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.3
	capsule.height = 1.1
	_add(pilot, "Body", capsule, Vector3.ZERO, Color(0.36, 0.55, 0.2))
	_ball(pilot, "Head", 0.34, Vector3(0, 0.78, 0), Color(0.95, 0.75, 0.6))
	_ball(pilot, "GoggleL", 0.13, Vector3(-0.14, 0.84, 0.28), Color(1, 1, 1))
	_ball(pilot, "GoggleR", 0.13, Vector3(0.14, 0.84, 0.28), Color(1, 1, 1))
	_ball(pilot, "PupilL", 0.06, Vector3(-0.14, 0.84, 0.39), Color(0.1, 0.1, 0.1))
	_ball(pilot, "PupilR", 0.06, Vector3(0.14, 0.84, 0.39), Color(0.1, 0.1, 0.1))
	ship.set("rig", rig)
	ship.set("pilot", pilot)
	return ship
