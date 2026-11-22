extends RefCounted
## Secrets kit: hidden things for any stage. Every function takes the level kit first, e.g.
##     const Secrets := preload("res://tools/kit_secrets.gd")
##     Secrets.fake_wall(k, 40, 46, 0, 3, Color(0.5, 0.35, 0.22))
##     Secrets.bean_room(k, 163.5, 1.6, 0.0, 40.0, {"golden": true})
## Everything that counts as a secret is in the group "secrets" (tests count them).
## Bean rooms are also in the group "bean_rooms".

const PIPE_GREEN: Color = Color(0.3, 0.7, 0.35)
const SpringScene := "res://scenes/spring.tscn"

## What Fart Man can reach, so the tests can check a secret ledge is fair.
## SIMPLE: a held jump (11.5) plus the air jump (Thunder, 16). CLASSIC: a Thunder (16) is the most you can count on.
const SIMPLE_MAX_RISE: float = 6.6
const CLASSIC_MAX_RISE: float = 5.0


## Marks a spot as a secret (a tiny invisible node in the group "secrets"). extra = more info.
static func mark(k, x: float, y: float, label: String, extra: Dictionary = {}) -> Marker3D:
	var spot := Marker3D.new()
	spot.name = "Secret_" + label
	spot.position = Vector3(x, y, 0)
	spot.add_to_group(&"secrets", true)
	for key: String in extra:
		spot.set_meta(key, extra[key])
	k._add("Secrets", spot)
	return spot


## A wall that looks solid but he walks straight through; it turns see-through while he is inside.
## Things placed inside the box (beans, a Golden Bean, a pickup) are hidden until he steps in.
## is_secret = false for a wall that only covers up another secret (like a pipe).
static func fake_wall(k, x0: float, x1: float, y0: float, y1: float, color: Color, is_secret: bool = true) -> Area3D:
	var wall := Area3D.new()
	wall.name = "FakeWall"
	wall.set_script(load("res://scripts/fake_wall.gd"))
	wall.position = Vector3((x0 + x1) * 0.5, (y0 + y1) * 0.5, 0)
	wall.set("is_secret", is_secret)
	k._add("Secrets", wall)
	var box := BoxMesh.new()
	box.size = Vector3(x1 - x0, y1 - y0, 4.2)
	var body: MeshInstance3D = k._mesh(wall, "Mesh", box, color, Vector3.ZERO)
	_see_through(body)
	# A few darker bricks so a sharp eye can tell it is a bit odd.
	for i in 3:
		var brick := BoxMesh.new()
		brick.size = Vector3(0.9, 0.35, 0.05)
		var bx: float = lerpf(-box.size.x * 0.35, box.size.x * 0.35, float(i) / 2.0)
		var by: float = lerpf(-box.size.y * 0.25, box.size.y * 0.25, float((i + 1) % 3) / 2.0)
		_see_through(k._mesh(wall, "Brick", brick, color.darkened(0.25), Vector3(bx, by, 2.12)))
	k._collider(wall, Vector3(x1 - x0, y1 - y0, 4.0), Vector3.ZERO)
	k._own(wall)
	return wall


static func _see_through(mesh: MeshInstance3D) -> void:
	(mesh.mesh.get("material") as StandardMaterial3D).transparency = BaseMaterial3D.TRANSPARENCY_ALPHA


## A high ledge worth a trip. from_top = the floor he jumps from. simple_only = it needs the
## SIMPLE double jump and hover (CLASSIC cannot get there). The rise is saved for the tests.
static func secret_ledge(k, cx: float, top: float, width: float, color: Color, from_top: float, simple_only: bool = false) -> StaticBody3D:
	var ledge: StaticBody3D = k.platform(cx, top, width, color)
	mark(k, cx, top, "Ledge", {"rise": top - from_top, "simple_only": simple_only})
	return ledge


## A big coil spring (from scenes/spring.tscn): 8.8 m bounce, a bigger one for a well-timed press.
static func spring(k, x: float, top: float) -> Node3D:
	return k.place(SpringScene, "Spring", Vector3(x, top, 0), "Pads")


## A sideways warp pipe. He walks into the mouth going enter_dir and pops out at destination.
static func pipe(k, x: float, top: float, enter_dir: float, destination: Vector3, color: Color = PIPE_GREEN) -> Area3D:
	var warp := Area3D.new()
	warp.name = "WarpPipe"
	warp.set_script(load("res://scripts/warp_pipe.gd"))
	k.sfx_for(warp, "warp_pipe")
	warp.position = Vector3(x, top, 0)
	k._add("Pipes", warp)
	var tube := CylinderMesh.new()
	tube.top_radius = 0.95
	tube.bottom_radius = 0.95
	tube.height = 2.4
	var tube_mesh: MeshInstance3D = k._mesh(warp, "Tube", tube, color, Vector3(enter_dir * 1.2, 0.95, -0.7))
	tube_mesh.rotation_degrees = Vector3(0, 0, 90)
	var lip := CylinderMesh.new()
	lip.top_radius = 1.12
	lip.bottom_radius = 1.12
	lip.height = 0.4
	var lip_mesh: MeshInstance3D = k._mesh(warp, "Lip", lip, color.lightened(0.2), Vector3(0, 0.95, -0.7))
	lip_mesh.rotation_degrees = Vector3(0, 0, 90)
	var hole := BoxMesh.new()
	hole.size = Vector3(0.15, 1.5, 1.3)
	k._mesh(warp, "Mouth", hole, Color(0.05, 0.05, 0.08), Vector3(enter_dir * 0.1, 0.95, -0.7))
	k._collider(warp, Vector3(0.8, 1.8, 2.0), Vector3(0, 0.9, 0))
	warp.set("enter_dir", enter_dir)
	warp.set("destination", destination)
	k._own(warp)
	return warp


## A secret BEAN ROOM: a warp pipe at (entrance_x, entrance_top) leads to a tall room whose floor is
## at room_floor (far away, up in the sky, starting at room_x). Inside: loads of beans (floor row,
## columns over springs, rings over mushrooms, arcs between, a high wave) and boost jumps to bounce
## around and grab them. A pipe at the right end takes him home.
## opts (all optional):
##   width 40, springs 3, pads 2, vents 0 (World 2 kit only), color (floor and walls),
##   hidden true (the entrance pipe sits inside a fake wall), golden false (a Golden Bean inside),
##   exit_to (where the home pipe drops him; default just past the entrance),
##   title "SECRET BEAN ROOM!", enter_dir 1.0
## Returns the middle of the room.
static func bean_room(k, entrance_x: float, entrance_top: float, room_x: float, room_floor: float, opts: Dictionary = {}) -> Vector3:
	var width: float = float(opts.get("width", 40.0))
	var spring_count: int = int(opts.get("springs", 3))
	var pad_count: int = int(opts.get("pads", 2))
	var vent_count: int = int(opts.get("vents", 0)) if k.has_method("vent") else 0
	var color: Color = opts.get("color", Color(0.4, 0.62, 0.3))
	var hidden: bool = bool(opts.get("hidden", true))
	var dir: float = float(opts.get("enter_dir", 1.0))
	var exit_to: Vector3 = opts.get("exit_to", Vector3(entrance_x + dir * 3.5, entrance_top + 1.3, 0))
	var height: float = 36.0
	var x1: float = room_x + width

	# The room: a floor and two tall walls.
	k.ground(room_x, x1, room_floor, color, false)
	k.block(room_x - 1.5, room_x, room_floor, room_floor + height, color.darkened(0.3))
	k.block(x1, x1 + 1.5, room_floor, room_floor + height, color.darkened(0.3))
	k.hint(room_x + 2.0, room_floor, str(opts.get("title", "SECRET BEAN ROOM!")), 3.0)
	k.hint(x1 - 9.0, room_floor, "PIPE HOME >>>", 3.0)
	var home_x: float = x1 - 3.0
	pipe(k, home_x, room_floor, 1.0, exit_to, color.lightened(0.15))

	# The way in: a pipe, usually behind a wall that is not quite right.
	pipe(k, entrance_x, entrance_top, dir, Vector3(room_x + 4.0, room_floor + 1.3, 0), color.lightened(0.15))
	if hidden:
		fake_wall(k, minf(entrance_x - dir * 3.0, entrance_x + dir * 2.6), maxf(entrance_x - dir * 3.0, entrance_x + dir * 2.6),
			entrance_top, entrance_top + 3.2, color.darkened(0.1), false)
	mark(k, entrance_x, entrance_top, "Room", {"hidden": hidden})

	# Boost jumps: springs and mushrooms in turns, spread along the floor.
	var kinds: Array[String] = []
	var springs_left: int = spring_count
	var pads_left: int = pad_count
	while springs_left > 0 or pads_left > 0:
		if springs_left > 0:
			kinds.append("spring")
			springs_left -= 1
		if pads_left > 0:
			kinds.append("pad")
			pads_left -= 1
	var xs: Array[float] = []
	var first: float = room_x + 9.0
	var last: float = x1 - 17.0  # leave a flat run before the home pipe
	for i in kinds.size():
		var t: float = float(i) / float(maxi(kinds.size() - 1, 1))
		xs.append(lerpf(first, last, t))

	# Beans everywhere: a row on the floor, then columns, rings and arcs around each bouncer.
	k.beans_line(room_x + 2.0, x1 - 6.0, room_floor + 1.3, 2.0)
	for i in kinds.size():
		var bx: float = xs[i]
		if kinds[i] == "spring":
			spring(k, bx, room_floor)
			var by: float = room_floor + 2.5
			while by <= room_floor + 12.5:
				k.bean(bx, by)
				by += 1.0
		else:
			k.pad(bx, room_floor)
			for j in 10:
				var a: float = TAU * float(j) / 10.0
				k.bean(bx + cos(a) * 2.2, room_floor + 8.0 + sin(a) * 2.2)
		if i + 1 < kinds.size():
			k.beans_arc(bx + 1.5, xs[i + 1] - 1.5, room_floor + 3.0, 7.0, 9)
	k.beans_arc(room_x + 4.0, x1 - 6.0, room_floor + 11.0, 4.0, 14)
	for i in vent_count:
		k.vent(lerpf(room_x + 14.0, x1 - 24.0,float(i) / float(maxi(vent_count - 1, 1))) + 3.0, room_floor, {"phase": 0.25 * float(i)})
	if bool(opts.get("golden", false)):
		k.golden(xs[0], room_floor + 7.5)

	# A marker for tests: where the room is and how big it is.
	var middle := Marker3D.new()
	middle.name = "BeanRoom"
	middle.position = Vector3(room_x + width * 0.5, room_floor + height * 0.5, 0)
	middle.add_to_group(&"bean_rooms", true)
	middle.set_meta("room_size", Vector2(width + 3.0, height))
	k._add("Secrets", middle)
	return middle.position
