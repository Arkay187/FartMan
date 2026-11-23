extends RefCounted
## Builds scenes/ship_hub.tscn: the inside of the Complex2000 spaceship, seen from the side.
## One long floor, an airlock hatch at the left end, then four rooms (the Kitchen, the Gym, the
## Hot Sauce Lab, the Gadget Garage) each with a sign, props and a counter where Grandma hides,
## then a second hatch at the right end, so he never has to walk all the way back.
## build_scenes.gd runs build() on every script in tools/builders/.
## All grey-box low-poly: boxes, cylinders and balls.

const PATH: String = "res://scenes/ship_hub.tscn"
## Every room is this wide. The hatch bay at each end is FIRST_ROOM_X wide.
const ROOM_WIDTH: float = 24.0
const FIRST_ROOM_X: float = 12.0
## How far each round door is from its end wall.
const DOOR_FROM_END: float = 3.5
## How tall the rooms are, and where the back wall is.
const HEIGHT: float = 8.0
const WALL_Z: float = -3.8
## How far past each end the hull carries on (so the camera never sees empty space inside).
const END_CAP: float = 14.0

const STEEL: Color = Color(0.62, 0.66, 0.72)
const DARK_STEEL: Color = Color(0.32, 0.35, 0.42)
const WOOD: Color = Color(0.62, 0.42, 0.24)
const SKY: Color = Color(0.03, 0.04, 0.12)

var root: Node3D
var _rng := RandomNumberGenerator.new()


func build() -> void:
	_rng.seed = 2000
	root = Node3D.new()
	root.name = "ShipHub"
	root.set_script(load("res://scripts/ship_hub.gd"))
	var length: float = FIRST_ROOM_X * 2.0 + ROOM_WIDTH * UpgradeTable.ROOMS.size()
	_light_and_sky()
	_hull(length)
	var hatch: Area3D = _hatch_end("AirlockHatch", DOOR_FROM_END, 1.0)
	var far_hatch: Area3D = _hatch_end("FarHatch", length - DOOR_FROM_END, -1.0)
	var counters := Node3D.new()
	counters.name = "Counters"
	_add(root, counters)
	var panel_node := CanvasLayer.new()
	panel_node.name = "ShopPanel"
	panel_node.set_script(load("res://scripts/shop_panel.gd"))
	var counter_list: Array[Node] = []
	for i in UpgradeTable.ROOMS.size():
		var room: Dictionary = UpgradeTable.ROOMS[i]
		var cx: float = FIRST_ROOM_X + ROOM_WIDTH * (float(i) + 0.5)
		_room(room, cx)
		counter_list.append(_counter(counters, room, cx))
	var player := _player()
	var camera := _camera(player)
	_add(root, panel_node)
	var hud := CanvasLayer.new()
	hud.name = "HUD"
	_add(root, hud)
	var jar := BeanJarLabel.new()
	jar.name = "BeanJarLabel"
	jar.font_size = 40
	jar.position = Vector2(20, 18)
	_add(hud, jar)
	for counter: Node in counter_list:
		counter.set("panel", panel_node)
	root.set("player", player)
	root.set("camera", camera)
	root.set("hatch", hatch)
	root.set("far_hatch", far_hatch)
	root.set("counters_root", counters)
	root.set("panel", panel_node)
	root.set("jar_label", jar)
	var packed := PackedScene.new()
	print("pack ", PATH, ": ", packed.pack(root))
	print("save ", PATH, ": ", ResourceSaver.save(packed, PATH))
	root.free()


# ---------------------------------------------------------------- the ship's shell

func _light_and_sky() -> void:
	var light := DirectionalLight3D.new()
	light.name = "DirectionalLight3D"
	light.rotation_degrees = Vector3(-35, -20, 0)
	light.light_energy = 0.7
	# No shadows: the ceiling would put the whole inside in the dark.
	light.shadow_enabled = false
	_add(root, light)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = SKY
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(1, 1, 1)
	env.ambient_light_energy = 0.7
	var world := WorldEnvironment.new()
	world.name = "WorldEnvironment"
	world.environment = env
	_add(root, world)


# Floor, ceiling and the two end walls (solid), plus dark hull beyond them.
func _hull(length: float) -> void:
	var wide: float = length + END_CAP * 2.0
	var middle: float = length * 0.5
	_solid("Floor", Vector3(wide, 6.0, 8.0), Vector3(wide, 6.0, 4.0), STEEL, Vector3(middle, -3.0, 0))
	_solid("Ceiling", Vector3(wide, 6.0, 8.0), Vector3(wide, 6.0, 4.0), DARK_STEEL, Vector3(middle, HEIGHT + 3.0, 0))
	_solid("WallLeft", Vector3(END_CAP, 22.0, 8.0), Vector3(END_CAP, 22.0, 4.0), DARK_STEEL, Vector3(-END_CAP * 0.5, 4.0, 0))
	_solid("WallRight", Vector3(END_CAP, 22.0, 8.0), Vector3(END_CAP, 22.0, 4.0), DARK_STEEL, Vector3(length + END_CAP * 0.5, 4.0, 0))
	# Back wall and a ceiling lamp for both hatch ends, and a stripe of colour on the floor for every room.
	for end_x: float in [FIRST_ROOM_X * 0.5, length - FIRST_ROOM_X * 0.5]:
		_box(root, "HatchWall", Vector3(FIRST_ROOM_X, HEIGHT, 0.4), Color(0.5, 0.58, 0.7), Vector3(end_x, HEIGHT * 0.5, WALL_Z))
		_box(root, "HatchSkirting", Vector3(FIRST_ROOM_X, 1.0, 0.5), DARK_STEEL, Vector3(end_x, 0.5, WALL_Z + 0.1))
		_lamp(Vector3(end_x, HEIGHT - 0.1, -1.0))
	for i in UpgradeTable.ROOMS.size() + 1:
		var x: float = FIRST_ROOM_X + ROOM_WIDTH * float(i)
		_box(root, "Pillar", Vector3(0.8, HEIGHT, 1.2), STEEL, Vector3(x, HEIGHT * 0.5, WALL_Z + 0.5))
	for i in UpgradeTable.ROOMS.size():
		var room_color: Color = UpgradeTable.ROOMS[i]["color"]
		var cx: float = FIRST_ROOM_X + ROOM_WIDTH * (float(i) + 0.5)
		_box(root, "FloorStripe", Vector3(ROOM_WIDTH - 1.0, 0.04, 5.0), room_color.darkened(0.25), Vector3(cx, 0.0, -0.5))
	# A ceiling lamp for every room.
	for i in UpgradeTable.ROOMS.size():
		_lamp(Vector3(FIRST_ROOM_X + ROOM_WIDTH * (float(i) + 0.5), HEIGHT - 0.1, -1.0))


func _lamp(pos: Vector3) -> void:
	_cyl(root, "Lamp", 1.6, 1.6, 0.2, Color(1.0, 0.97, 0.8), pos, Vector3.ZERO, true)


# ---------------------------------------------------------------- the hatches at both ends

## An airlock hatch on the back wall at door_x: a round door, an arrow, a little world on a sign,
## and the zone that sends him back to the map. inward is 1 at the left end and -1 at the right
## end (the way back towards the rooms), so the right one is a mirror of the left one.
func _hatch_end(holder_name: String, door_x: float, inward: float) -> Area3D:
	var holder := Node3D.new()
	holder.name = holder_name
	_add(root, holder)
	# The round door, a yellow frame, a wheel to turn.
	_cyl(holder, "Door", 2.2, 2.2, 0.3, Color(0.55, 0.6, 0.66), Vector3(door_x, 2.6, WALL_Z + 0.35), Vector3(90, 0, 0))
	var frame := TorusMesh.new()
	frame.inner_radius = 2.15
	frame.outer_radius = 2.5
	_mesh(holder, "Frame", frame, Color(1.0, 0.8, 0.1), Vector3(door_x, 2.6, WALL_Z + 0.5), Vector3(90, 0, 0))
	var wheel := TorusMesh.new()
	wheel.inner_radius = 0.55
	wheel.outer_radius = 0.75
	_mesh(holder, "Wheel", wheel, Color(0.8, 0.2, 0.2), Vector3(door_x, 2.6, WALL_Z + 0.7), Vector3(90, 0, 0))
	for spoke in 3:
		var bar: MeshInstance3D = _box(holder, "Spoke", Vector3(1.4, 0.12, 0.12), Color(0.8, 0.2, 0.2), Vector3(door_x, 2.6, WALL_Z + 0.7))
		bar.rotation_degrees.z = 60.0 * float(spoke)
	# A big arrow pointing at it, and a little world on a sign.
	var arrow := Node3D.new()
	arrow.name = "Arrow"
	arrow.position = Vector3(door_x + 1.1 * inward, 6.0, WALL_Z + 0.5)
	_add(holder, arrow)
	_box(arrow, "Shaft", Vector3(3.0, 0.9, 0.3), Color(1.0, 0.85, 0.1), Vector3(0.9 * inward, 0, 0))
	var head := PrismMesh.new()
	head.size = Vector3(1.8, 1.9, 0.3)
	_mesh(arrow, "Head", head, Color(1.0, 0.85, 0.1), Vector3(-1.1 * inward, 0, 0), Vector3(0, 0, 90.0 * inward))
	var world_spot := Vector3(door_x + 4.5 * inward, 6.0, WALL_Z + 0.7)
	_ball(holder, "World", 0.95, Color(0.2, 0.5, 0.95), world_spot)
	for patch: Vector3 in [Vector3(-0.3, 0.3, 0.7), Vector3(0.35, -0.2, 0.75), Vector3(0.1, 0.6, 0.6)]:
		_ball(holder, "Land", 0.3, Color(0.3, 0.75, 0.35), world_spot + patch, Vector3(1.2, 0.8, 0.4))
	# The zone that sends him back to the map.
	var area := Area3D.new()
	area.name = "HatchZone"
	area.position = Vector3(door_x - 0.5 * inward, 2.5, 0)
	_add(holder, area)
	_collider(area, Vector3(3.0, 5.0, 4.0), Vector3.ZERO)
	return area


# ---------------------------------------------------------------- one room

func _room(room: Dictionary, cx: float) -> void:
	var color: Color = room["color"]
	var node := Node3D.new()
	node.name = "Room_" + str(room["id"])
	node.position = Vector3(cx, 0, 0)
	_add(root, node)
	# Back wall in the room's colour with a darker skirting board.
	_box(node, "BackWall", Vector3(ROOM_WIDTH, HEIGHT, 0.4), color.lightened(0.15), Vector3(0, HEIGHT * 0.5, WALL_Z))
	_box(node, "Skirting", Vector3(ROOM_WIDTH, 1.1, 0.5), color.darkened(0.35), Vector3(0, 0.55, WALL_Z + 0.1))
	# Round portholes with a dark starry sky outside.
	_porthole(node, Vector3(-5.6, 4.0, WALL_Z + 0.2))
	_porthole(node, Vector3(5.6, 4.0, WALL_Z + 0.2))
	# The big sign: a picture on the left and the room's name.
	_box(node, "Sign", Vector3(12.0, 2.3, 0.3), color.darkened(0.5), Vector3(0, 6.4, WALL_Z + 0.3))
	var picture := Node3D.new()
	picture.name = "SignPicture"
	picture.position = Vector3(-4.6, 6.4, WALL_Z + 0.6)
	picture.scale = Vector3(0.8, 0.8, 0.8)
	_add(node, picture)
	var text := Label3D.new()
	text.name = "SignText"
	text.text = room["name"]
	text.font_size = 100
	text.pixel_size = 0.01
	text.outline_size = 14
	text.position = Vector3(1.4, 6.4, WALL_Z + 0.55)
	_add(node, text)
	match str(room["id"]):
		"kitchen":
			_pot(picture, Vector3.ZERO, 1.0)
			_kitchen(node)
		"gym":
			_dumbbell(picture, Vector3.ZERO, 1.6, Color(0.2, 0.2, 0.25))
			_gym(node)
		"lab":
			_bottle(picture, Vector3(0, -0.8, 0), 2.0, Color(0.9, 0.15, 0.1))
			_lab(node)
		"garage":
			_magnet(picture, Vector3(0, -1.0, 0), 1.0)
			_garage(node)


func _kitchen(node: Node3D) -> void:
	# A stove with a bubbling pot.
	_box(node, "Stove", Vector3(2.6, 1.7, 1.6), Color(0.82, 0.83, 0.86), Vector3(-8.5, 0.85, -2.7))
	for x: float in [-9.2, -7.8]:
		_cyl(node, "Burner", 0.45, 0.45, 0.06, Color(0.1, 0.1, 0.12), Vector3(x, 1.72, -2.6))
	_pot(node, Vector3(-9.2, 1.75, -2.6), 0.8)
	# A fridge.
	_box(node, "Fridge", Vector3(2.0, 4.0, 1.6), Color(0.93, 0.95, 0.97), Vector3(8.8, 2.0, -2.7))
	_box(node, "FridgeHandle", Vector3(0.14, 1.2, 0.2), STEEL, Vector3(8.0, 2.6, -1.8))
	_box(node, "FridgeDoorLine", Vector3(2.02, 0.06, 0.05), Color(0.6, 0.62, 0.66), Vector3(8.8, 2.9, -1.88))
	# The big bean jar.
	_cyl(node, "BigJar", 0.95, 0.95, 2.3, Color(0.7, 0.9, 1.0, 0.35), Vector3(5.4, 1.15, -2.7))
	for i in 14:
		var bean: MeshInstance3D = _ball(node, "JarBean", 0.22, Color(0.78, 0.45, 0.25),
			Vector3(5.4 + _rng.randf_range(-0.6, 0.6), 0.3 + _rng.randf_range(0.0, 1.2), -2.7 + _rng.randf_range(-0.5, 0.5)), Vector3(1.0, 0.7, 0.7))
		bean.rotation_degrees.z = _rng.randf_range(0.0, 180.0)
	_cyl(node, "JarLid", 1.0, 1.0, 0.25, Color(0.85, 0.25, 0.2), Vector3(5.4, 2.4, -2.7))


func _gym(node: Node3D) -> void:
	# A dumbbell rack: two posts, two shelves, a few dumbbells.
	for x: float in [-10.0, -7.0]:
		_box(node, "RackPost", Vector3(0.2, 2.2, 0.9), DARK_STEEL, Vector3(x, 1.1, -2.7))
	for y: float in [0.8, 1.6]:
		_box(node, "RackShelf", Vector3(3.2, 0.15, 0.9), STEEL, Vector3(-8.5, y, -2.7))
	_dumbbell(node, Vector3(-9.3, 1.0, -2.7), 0.6, Color(0.9, 0.2, 0.2))
	_dumbbell(node, Vector3(-8.2, 1.0, -2.7), 0.6, Color(0.2, 0.4, 0.9))
	_dumbbell(node, Vector3(-9.0, 1.8, -2.7), 0.8, Color(0.2, 0.2, 0.25))
	# A trampoline.
	for x: float in [-1.6, 1.6]:
		_box(node, "TrampolineLeg", Vector3(0.2, 0.9, 0.2), DARK_STEEL, Vector3(7.5 + x, 0.45, -2.7))
	_cyl(node, "TrampolineRing", 2.1, 2.1, 0.2, Color(0.9, 0.2, 0.2), Vector3(7.5, 0.95, -2.7))
	_cyl(node, "TrampolineMat", 1.8, 1.8, 0.25, Color(0.2, 0.45, 0.95), Vector3(7.5, 1.0, -2.7))
	# A big dumbbell lying on the floor.
	_dumbbell(node, Vector3(4.0, 0.5, -2.2), 1.6, Color(0.2, 0.2, 0.25))


func _lab(node: Node3D) -> void:
	# A shelf of hot sauce bottles.
	_box(node, "Shelf", Vector3(3.6, 0.2, 1.0), WOOD, Vector3(-8.5, 1.8, -2.9))
	for x: float in [-10.2, -6.8]:
		_box(node, "ShelfLeg", Vector3(0.15, 1.8, 0.8), WOOD.darkened(0.2), Vector3(x, 0.9, -2.9))
	var colors: Array[Color] = [Color(0.9, 0.15, 0.1), Color(1.0, 0.55, 0.1), Color(0.3, 0.7, 0.25), Color(0.9, 0.15, 0.1)]
	for i in 4:
		_bottle(node, Vector3(-9.8 + float(i) * 0.95, 1.9, -2.9), 1.0 + float(i % 2) * 0.3, colors[i])
	_bottle(node, Vector3(-5.0, 0.0, -2.4), 2.4, Color(0.9, 0.15, 0.1))
	# A table with a bubbling flask.
	_box(node, "Table", Vector3(2.6, 1.2, 1.6), DARK_STEEL, Vector3(7.8, 0.6, -2.7))
	_ball(node, "Flask", 0.95, Color(0.75, 1.0, 0.8, 0.4), Vector3(7.8, 2.2, -2.7))
	_cyl(node, "FlaskNeck", 0.3, 0.3, 1.0, Color(0.75, 1.0, 0.8, 0.4), Vector3(7.8, 3.2, -2.7))
	_ball(node, "Potion", 0.8, Color(0.3, 0.9, 0.3), Vector3(7.8, 2.0, -2.7), Vector3(1.0, 0.7, 1.0), true)
	for y: float in [3.0, 3.6, 4.3]:
		_ball(node, "Bubble", 0.16, Color(0.6, 1.0, 0.6), Vector3(7.8 + (y - 3.5) * 0.2, y, -2.6), Vector3.ONE, true)


func _garage(node: Node3D) -> void:
	# A toolbox.
	_box(node, "Toolbox", Vector3(2.2, 1.0, 1.1), Color(0.85, 0.15, 0.15), Vector3(-8.5, 0.5, -2.6))
	_box(node, "ToolboxLid", Vector3(2.2, 0.2, 1.15), Color(0.65, 0.1, 0.1), Vector3(-8.5, 1.1, -2.6))
	_box(node, "ToolboxHandle", Vector3(0.9, 0.12, 0.12), STEEL, Vector3(-8.5, 1.35, -2.6))
	var wrench: MeshInstance3D = _box(node, "WrenchHandle", Vector3(0.18, 1.6, 0.1), STEEL, Vector3(-6.6, 0.8, -2.6))
	wrench.rotation_degrees.z = 20.0
	# Two gears on the wall.
	_gear(node, Vector3(7.5, 3.0, WALL_Z + 0.3), 1.3, Color(0.7, 0.72, 0.78))
	_gear(node, Vector3(9.7, 4.4, WALL_Z + 0.3), 0.9, Color(1.0, 0.6, 0.15))
	# A big horseshoe magnet standing on the floor.
	_magnet(node, Vector3(4.2, 0.0, -2.5), 1.4)


# ---------------------------------------------------------------- props

func _porthole(parent: Node3D, pos: Vector3) -> void:
	_cyl(parent, "Window", 1.0, 1.0, 0.05, SKY, pos, Vector3(90, 0, 0))
	var ring := TorusMesh.new()
	ring.inner_radius = 0.95
	ring.outer_radius = 1.25
	_mesh(parent, "PortholeRing", ring, STEEL, pos + Vector3(0, 0, 0.05), Vector3(90, 0, 0))
	for i in 6:
		var spot := Vector2(_rng.randf_range(-0.7, 0.7), _rng.randf_range(-0.7, 0.7))
		_ball(parent, "Star", 0.05, Color.WHITE, pos + Vector3(spot.x, spot.y, 0.04), Vector3.ONE, true)


func _pot(parent: Node3D, pos: Vector3, grow: float) -> void:
	_cyl(parent, "Pot", 0.55 * grow, 0.5 * grow, 0.7 * grow, Color(0.3, 0.3, 0.35), pos + Vector3(0, 0.35 * grow, 0))
	for side: float in [-1.0, 1.0]:
		_box(parent, "PotHandle", Vector3(0.3, 0.1, 0.1) * grow, Color(0.2, 0.2, 0.25), pos + Vector3(side * 0.65 * grow, 0.5 * grow, 0))
	# Steam.
	for i in 3:
		_ball(parent, "Steam", (0.2 - float(i) * 0.03) * grow, Color(1, 1, 1, 0.7), pos + Vector3(float(i - 1) * 0.15 * grow, (0.95 + float(i) * 0.3) * grow, 0))


# A dumbbell lying sideways: a bar and a weight at each end.
func _dumbbell(parent: Node3D, pos: Vector3, grow: float, color: Color) -> void:
	_cyl(parent, "DumbbellBar", 0.08 * grow, 0.08 * grow, 1.0 * grow, STEEL, pos, Vector3(0, 0, 90))
	for side: float in [-1.0, 1.0]:
		_cyl(parent, "DumbbellWeight", 0.3 * grow, 0.3 * grow, 0.25 * grow, color, pos + Vector3(side * 0.5 * grow, 0, 0), Vector3(0, 0, 90))


# A hot sauce bottle standing on pos (its feet).
func _bottle(parent: Node3D, pos: Vector3, grow: float, color: Color) -> void:
	_cyl(parent, "Bottle", 0.28 * grow, 0.3 * grow, 0.8 * grow, color, pos + Vector3(0, 0.4 * grow, 0))
	_cyl(parent, "BottleNeck", 0.12 * grow, 0.2 * grow, 0.3 * grow, color, pos + Vector3(0, 0.95 * grow, 0))
	_cyl(parent, "BottleCap", 0.14 * grow, 0.14 * grow, 0.14 * grow, Color(1, 1, 1), pos + Vector3(0, 1.17 * grow, 0))
	_box(parent, "BottleLabel", Vector3(0.36, 0.34, 0.04) * grow, Color(1.0, 0.85, 0.2), pos + Vector3(0, 0.4 * grow, 0.3 * grow))


# A horseshoe magnet standing on pos, legs up.
func _magnet(parent: Node3D, pos: Vector3, grow: float) -> void:
	_box(parent, "MagnetBase", Vector3(1.7, 0.5, 0.5) * grow, Color(0.85, 0.15, 0.15), pos + Vector3(0, 0.25 * grow, 0))
	for side: float in [-1.0, 1.0]:
		_box(parent, "MagnetLeg", Vector3(0.5, 1.2, 0.5) * grow, Color(0.85, 0.15, 0.15), pos + Vector3(side * 0.6 * grow, 1.0 * grow, 0))
		_box(parent, "MagnetTip", Vector3(0.5, 0.4, 0.5) * grow, STEEL, pos + Vector3(side * 0.6 * grow, 1.8 * grow, 0))


func _gear(parent: Node3D, pos: Vector3, radius: float, color: Color) -> void:
	_cyl(parent, "Gear", radius, radius, 0.3, color, pos, Vector3(90, 0, 0))
	for i in 8:
		var angle: float = TAU * float(i) / 8.0
		var tooth: MeshInstance3D = _box(parent, "GearTooth", Vector3(radius * 0.4, radius * 0.4, 0.3), color,
			pos + Vector3(cos(angle), sin(angle), 0) * radius * 1.05)
		tooth.rotation.z = angle
	_cyl(parent, "GearHole", radius * 0.3, radius * 0.3, 0.32, DARK_STEEL, pos + Vector3(0, 0, 0.02), Vector3(90, 0, 0))


# ---------------------------------------------------------------- a counter with Grandma

func _counter(parent: Node3D, room: Dictionary, cx: float) -> Area3D:
	var area := Area3D.new()
	area.name = "Counter_" + str(room["id"])
	area.set_script(load("res://scripts/shop_counter.gd"))
	area.position = Vector3(cx, 0, 0)
	area.set("room_id", room["id"])
	_add(parent, area)
	_collider(area, Vector3(6.0, 4.0, 4.0), Vector3(0, 2.0, 0))
	# Grandma crouches behind it on a hidden stool; the counter hides her until she pops up.
	var grandma := Node3D.new()
	grandma.name = "Grandma"
	grandma.set_script(load("res://scripts/grandma.gd"))
	grandma.position = Vector3(0, 0.5, -2.4)
	_add(area, grandma)
	_box(area, "CounterBase", Vector3(5.0, 1.5, 1.0), WOOD, Vector3(0, 0.75, -1.2))
	_box(area, "CounterTop", Vector3(5.4, 0.2, 1.3), Color(0.96, 0.88, 0.68), Vector3(0, 1.6, -1.2))
	_box(area, "CounterTrim", Vector3(5.0, 0.2, 0.05), (room["color"] as Color), Vector3(0, 1.2, -0.68))
	# The "press jump" hint: a bouncing arrow over a round green button.
	var hint := Node3D.new()
	hint.name = "Hint"
	hint.position = Vector3(0, 2.4, 0.2)
	_add(area, hint)
	var point := PrismMesh.new()
	point.size = Vector3(1.2, 1.0, 0.3)
	_mesh(hint, "HintArrow", point, Color(1.0, 0.85, 0.1), Vector3(0, 0, 0), Vector3(0, 0, 180))
	_box(hint, "HintStem", Vector3(0.45, 0.6, 0.3), Color(1.0, 0.85, 0.1), Vector3(0, 0.75, 0))
	_cyl(hint, "HintButton", 0.5, 0.5, 0.25, Color(0.25, 0.8, 0.3), Vector3(0, 1.5, 0), Vector3(90, 0, 0))
	area.set("grandma", grandma)
	area.set("hint", hint)
	return area


# ---------------------------------------------------------------- the player and the camera

func _player() -> Node3D:
	var player: Node3D = (load("res://scenes/player.tscn") as PackedScene).instantiate()
	player.name = "Player"
	player.position = Vector3(9.0, 1.2, 0.0)
	_add(root, player)
	return player


# A follow camera, closer than in the stages so the rooms fill the screen.
func _camera(player: Node3D) -> Camera3D:
	var camera := Camera3D.new()
	camera.name = "Camera3D"
	camera.set_script(load("res://scripts/follow_camera.gd"))
	camera.set("offset", Vector3(0.0, 2.6, 10.0))
	camera.set("walk_fov", 55.0)
	camera.position = player.position + Vector3(0.0, 2.6, 10.0)
	_add(root, camera)
	camera.set("target", player)
	return camera


# ---------------------------------------------------------------- little helpers

# Puts a node in the scene file: everything made here belongs to the root.
func _add(parent: Node, node: Node) -> void:
	parent.add_child(node)
	node.owner = root


func _paint(color: Color, glow: bool) -> StandardMaterial3D:
	var paint := StandardMaterial3D.new()
	paint.albedo_color = color
	if color.a < 1.0:
		paint.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if glow:
		paint.emission_enabled = true
		paint.emission = color
		paint.emission_energy_multiplier = 0.8
	return paint


func _mesh(parent: Node, mesh_name: String, shape: Mesh, color: Color, pos: Vector3, rot_degrees: Vector3 = Vector3.ZERO,
		glow: bool = false) -> MeshInstance3D:
	shape.set("material", _paint(color, glow))
	var mesh := MeshInstance3D.new()
	mesh.name = mesh_name
	mesh.mesh = shape
	mesh.position = pos
	mesh.rotation_degrees = rot_degrees
	_add(parent, mesh)
	return mesh


func _box(parent: Node, box_name: String, size: Vector3, color: Color, pos: Vector3) -> MeshInstance3D:
	var shape := BoxMesh.new()
	shape.size = size
	return _mesh(parent, box_name, shape, color, pos)


func _cyl(parent: Node, cyl_name: String, top: float, bottom: float, height: float, color: Color, pos: Vector3,
		rot_degrees: Vector3 = Vector3.ZERO, glow: bool = false) -> MeshInstance3D:
	var shape := CylinderMesh.new()
	shape.top_radius = top
	shape.bottom_radius = bottom
	shape.height = height
	shape.radial_segments = 16
	return _mesh(parent, cyl_name, shape, color, pos, rot_degrees, glow)


# A ball; squash stretches it (x, y, z) to make ovals.
func _ball(parent: Node, ball_name: String, radius: float, color: Color, pos: Vector3, squash: Vector3 = Vector3.ONE,
		glow: bool = false) -> MeshInstance3D:
	var shape := SphereMesh.new()
	shape.radius = radius
	shape.height = radius * 2.0
	shape.radial_segments = 12
	shape.rings = 6
	var mesh: MeshInstance3D = _mesh(parent, ball_name, shape, color, pos, Vector3.ZERO, glow)
	mesh.scale = squash
	return mesh


# A solid (walkable or wall) piece: a mesh and a collider, collider can be thinner than the mesh.
func _solid(solid_name: String, mesh_size: Vector3, collider_size: Vector3, color: Color, pos: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = solid_name
	body.position = pos
	_add(root, body)
	var shape := BoxMesh.new()
	shape.size = mesh_size
	_mesh(body, "Mesh", shape, color, Vector3.ZERO)
	_collider(body, collider_size, Vector3.ZERO)
	return body


func _collider(parent: Node, size: Vector3, pos: Vector3) -> void:
	var shape := BoxShape3D.new()
	shape.size = size
	var col := CollisionShape3D.new()
	col.name = "CollisionShape3D"
	col.shape = shape
	col.position = pos
	_add(parent, col)
