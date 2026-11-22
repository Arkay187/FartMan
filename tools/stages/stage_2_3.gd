extends RefCounted
## Stage 2-3: UP THE CHIMNEY (a flying stage, about 1 minute).
## Part 1: climb the inside of the giant chimney. Hold jump to rise, let go to sink, arrow keys
## steer left and right. Electric cables switch sides, smoke rings give bonus beans, a toilet
## waits half way, a steam updraft shoots you to the top and you BURST OUT.
## Part 2: fly across the factory roofs: smoke rings, rooftop fans, a little rodeo of cables,
## thick clouds of bean steam hiding surprises and a slalom of puffing chimneys, with three
## SUPER BOOSTS (everything goes 3.5x faster, all beans and big rings) in between. Sky toilets keep him flying after a mishap.

const KIT := "res://tools/kit_chimney.gd"

## The chimney: inside width from x = 0 to 16, walls up to 84 m.
const X0: float = 0.0
const X1: float = 16.0
const TOP: float = 84.0
## The factory roofs are at this height. The flying lane over them is 73 m to 92 m.
const ROOF_Y: float = 66.0
const LANE: Vector2 = Vector2(73.0, 92.0)
## While inside the chimney he can fly from the floor up to well above the walls.
const SHAFT_LANE: Vector2 = Vector2(1.5, 100.0)
## The three SUPER BOOSTS (start and end x). The flight ends at the landing curtain after the last.
const BOOSTS: Array[Vector2] = [Vector2(150.0, 260.0), Vector2(410.0, 520.0), Vector2(775.0, 885.0)]
const BOOST_SPEED: float = 3.5
const LANDING_X: float = 920.0


func build(k) -> Array[String]:
	k.begin("2-3", "UP THE CHIMNEY!", Vector3(8, 3, 0), Color(1.0, 0.72, 0.45))
	k.root.set("start_flight", SHAFT_LANE)
	k.factory_roofs(20, LANDING_X - 40.0, ROOF_Y)
	k.skyline(-60, LANDING_X + 150.0)
	_chimney(k)
	_roofs(k)
	_landing(k)
	return k.finish("res://scenes/stage_2_3.tscn")


# ------------------------------------------------------------------ part 1: inside the chimney

func _chimney(k) -> void:
	k.shaft(X0, X1, TOP)
	k.say_zone(8, 7, 14, 10, "HOLD JUMP TO RISE! ARROWS STEER!", 4.0)

	# --- Warm-up: a zig-zag of beans going up. ----------------------------------------------
	for i in 6:
		k.bean(8.0 + 4.0 * sin(i * 0.9), 8.0 + i * 1.8)

	# --- Spark gates: one half of the shaft is live, the other half is safe. They swap. -----
	for gate in [[18.0, 0.0], [30.0, 0.4]]:
		var y: float = gate[0]
		var ph: float = gate[1]
		k.cable(X0 + 4.0, y, 8.0, false, ph)
		k.cable(X0 + 12.0, y, 8.0, false, ph + 0.5)
		k.bean(X0 + 4.0, y + 2.5)
		k.bean(X0 + 12.0, y + 2.5)
	k.say_zone(8, 15, 14, 4, "SPARKS! GO TO THE DARK SIDE!", 3.0)

	# --- Smoke rings lying flat, to fly up through. ----------------------------------------
	k.ring(4, 24, true)
	k.ring(12, 36, true)

	# --- Half way: a toilet on a shelf. --------------------------------------------------------
	k.shaft_toilet(X0, X1, 42.0, SHAFT_LANE)

	# --- The steam updraft: WHEEE! Beans all the way up. ---------------------------------------
	k.updraft(X0, X1, 46.0, 74.0)
	for y in range(48, 74, 3):
		k.bean(8.0 + 3.0 * sin(y * 0.5), float(y))
	k.say_zone(8, 47, 14, 4, "WHEEEE!", 2.0)

	# --- A cloud of bean steam at the top hides a Golden Bean. ---------------------------------
	k.steam(5.0, 78.0, 9.0, 8.0)
	k.golden(4.0, 78.0)

	# --- Burst out of the top and into the roof lane. -----------------------------------------
	k.say_zone(8, 87, 14, 4, "BURST OUT!", 2.0)
	k.beans_arc(X1 + 2.0, X1 + 20.0, 88.0, 3.0, 6)
	k.lane_zone(24.0, LANE.x, LANE.y)


# ------------------------------------------------------------------ part 2: the factory roofs

func _roofs(k) -> void:
	var mid: float = (LANE.x + LANE.y) * 0.5

	# --- Smoke rings over the rooftops: fly through them in a row for a bigger bonus. ---------
	for x in range(40, 131, 3):
		k.bean(x, mid + 6.0 * sin((x - 60.0) / 22.0 * 0.9))
	for i in 3:
		k.ring(60.0 + i * 30.0, mid + 6.0 * sin(i * 1.2))
	k.say_zone(50, mid, 8, 20, "FLY THROUGH THE RINGS!", 3.0)
	k.sky_toilet(135, LANE)

	# --- SUPER BOOST 1. -----------------------------------------------------------------------
	_boost(k, BOOSTS[0], 0.0)

	# --- Rooftop fans: ride the wind up. The fan with pipes above is a trap! -------------------
	var fan_xs: Array[float] = [290.0, 330.0, 370.0]
	for i in fan_xs.size():
		k.fan(fan_xs[i], ROOF_Y + 0.8, [0.0, 0.3, 0.6][i], 26.0)
		if i == 1:
			k.pipe(fan_xs[i], 94.0, 10.0)
		else:
			k.bean(fan_xs[i], 88.0)
			k.bean(fan_xs[i], 85.0)
	k.golden(330, 90.5)
	for x in range(280, 381, 4):
		k.bean(x, 78.0)
	k.say_zone(280, mid, 8, 20, "FANS BLOW YOU UP!", 3.0)
	k.sky_toilet(395, LANE)

	# --- SUPER BOOST 2. -----------------------------------------------------------------------
	_boost(k, BOOSTS[1], 1.0)

	# --- Bean steam clouds: you can't see in! A ring and a Golden Bean are hiding. -------------
	var clouds: Array = [[560.0, 82.0], [610.0, 85.0]]
	for c in clouds:
		k.steam(c[0], c[1], 16.0, 14.0)
		for dx in [-5.0, -2.5, 0.0, 2.5, 5.0]:
			k.bean(c[0] + dx, c[1])
	k.ring(560.0, 79.0)
	k.golden(610, 87.0)
	k.say_zone(540, mid, 8, 20, "WHAT'S IN THE STEAM?", 3.0)
	k.sky_toilet(640, LANE)

	# --- The chimney slalom: over the puffing chimneys, under the pipes. -------------------------
	for i in 3:
		var sx: float = 665.0 + i * 28.0
		var top_y: float = 79.0 + 5.0 * sin(i * 1.3)
		k.stack(sx, ROOF_Y, top_y - ROOF_Y, i * 0.2)
		var pipe_bottom: float = top_y + 11.0
		if pipe_bottom < 94.0:
			k.pipe(sx, 94.0, 94.0 - pipe_bottom)
		k.bean(sx - 5.0, top_y + 5.5)
		k.bean(sx, top_y + 5.5)
		k.bean(sx + 5.0, top_y + 5.5)
	k.say_zone(650, mid, 8, 20, "OVER THE CHIMNEYS!", 3.0)
	k.sky_toilet(745, LANE)

	# --- SUPER BOOST 3: the finale, then the landing. -----------------------------------------
	_boost(k, BOOSTS[2], 2.0)


## One SUPER BOOST and everything inside it: three wide rows of beans in gentle waves and big
## smoke rings now and then. All easy and no hazards.
func _boost(k, span: Vector2, wave: float) -> void:
	k.super_boost(span.x, span.y, LANE.x, LANE.y, BOOST_SPEED)
	var mid: float = (LANE.x + LANE.y) * 0.5
	var x: float = span.x + 14.0
	while x <= span.y - 8.0:
		var swing: float = 4.0 * sin((x - span.x) * 0.06 + wave)
		for row in [-5.0, 0.0, 5.0]:
			k.bean(x, mid + swing + row)
		x += 4.0
	var rx: float = span.x + 35.0
	while rx <= span.y - 20.0:
		var ring: Node3D = k.ring(rx, mid + 4.0 * sin((rx - span.x) * 0.06 + wave))
		ring.set("radius", 3.4)
		rx += 25.0

# ------------------------------------------------------------------ the end

func _landing(k) -> void:
	# The flight ends at the curtain. The roof starts well before it, so he can't drop into a hole.
	k.place("res://scenes/landing_zone.tscn", "LandingZone", Vector3(LANDING_X, ROOF_Y, 0), "Goal")
	k.ground(LANDING_X - 40.0, LANDING_X + 100.0, ROOF_Y, Color(0.5, 0.53, 0.58))
	var hall := BoxMesh.new()
	hall.size = Vector3(140.0, ROOF_Y - 6.0, 14.0)
	k._mesh(k._group("Decor"), "FinalHall", hall, Color(0.7, 0.3, 0.22), Vector3(LANDING_X + 30.0, (ROOF_Y - 6.0) * 0.5, -4))
	k.toilet(LANDING_X + 20.0, ROOF_Y)
	k.beans_arc(LANDING_X + 31.0, LANDING_X + 41.0, ROOF_Y + 1.3, 2.5, 6)
	k.bean_can(LANDING_X + 65.0, ROOF_Y)
