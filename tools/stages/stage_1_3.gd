extends RefCounted
## Stage 1-3: OVER THE ROOFTOPS (a flying stage, about 40 seconds).
## He starts already flying. Hold jump to rise, let go to sink.
## Three SUPER BOOSTS (the screen rushes along 3.5x faster, all beans and big hoops, nothing
## that hurts) with a short stretch of obstacles between them: washing lines, a flock of
## Crows, up-draughts, geysers and a very surprised cow. Sky toilets keep him flying after a mishap.

## The flight stages use the chimney kit, which has the super boost piece.
const KIT := "res://tools/kit_chimney.gd"
const LANE: Vector2 = Vector2(3.0, 16.0)
## Where each SUPER BOOST starts and ends. Landing is the green curtain after the last one.
const BOOSTS: Array[Vector2] = [Vector2(100.0, 210.0), Vector2(425.0, 535.0), Vector2(655.0, 765.0)]
const BOOST_SPEED: float = 3.5
const LANDING_X: float = 790.0


func build(k) -> Array[String]:
	k.begin("1-3", "HOLD JUMP TO RISE!", Vector3(0, 9, 0), Color(0.55, 0.8, 0.98))
	k.root.set("start_flight", LANE)
	k.landscape(-20, LANDING_X + 90.0, -9.0)

	# --- Warm-up: a wavy line of beans and a hoop. --------------------------------------
	for x in range(10, 81, 3):
		k.bean(x, 9.5 + 4.0 * sin(x * 0.1))
	k.hoop(40, 11.5)
	k.sky_toilet(85)

	# --- SUPER BOOST 1, then the village: washing lines, high then low. -----------------
	_boost(k, BOOSTS[0], 0.0)
	k.washing_line(235, 275, 13.0)
	for x in range(235, 276, 3):
		k.bean(x, 7.0)
	k.hoop(250, 7.5)
	k.golden(258, 4.0)
	k.washing_line(290, 325, 5.5)
	for x in range(290, 326, 3):
		k.bean(x, 10.5)
	k.hoop(308, 10.5)
	k.sky_toilet(340)

	# --- A Crow flock: fly through the middle, or stomp them from above. ----------------
	for pair in [[0.0, 2.8], [0.0, -2.8], [4.0, 5.6], [4.0, -5.6]]:
		k.enemy("crow", 365.0 + pair[0], 11.0 + pair[1], {"walk_speed": 0.0, "patrol_distance": 0.2, "bob_height": 1.4, "bob_speed": 4.0})
	for x in range(359, 380, 3):
		k.bean(x, 11.0)
	k.golden(395, 14.6)
	k.enemy("crow", 395, 12.2, {"walk_speed": 0.0, "patrol_distance": 0.2, "bob_height": 0.8})
	k.sky_toilet(415)

	# --- SUPER BOOST 2, then an up-draught with a spiky ceiling, and geysers. ------------
	_boost(k, BOOSTS[1], 1.0)
	k.updraft(560, 568, 3.0, 16.0)
	k.spiky(564, 15.2)
	for y in range(4, 14, 3):
		k.bean(564.0, float(y))
	k.cow(600, -8.5, 580, 620)
	for i in 2:
		k.sprinkler(590.0 + i * 22.0, -8.5, 0.25 * i, 16.0, 1.4, 2.0)
	for x in range(580, 630, 3):
		k.bean(x, 11.5 + 2.5 * sin(x * 0.2))
	k.hoop(605, 12.0)
	k.golden(626, 14.0)
	k.sky_toilet(645)

	# --- SUPER BOOST 3: the finale, a rollercoaster of big hoops and beans. --------------
	_boost(k, BOOSTS[2], 2.0)

	# --- Landing: flight ends at the green curtain. --------------------------------------
	# The ground starts well before the curtain, so he can never drop into a hole when the flight ends.
	k.place("res://scenes/landing_zone.tscn", "LandingZone", Vector3(LANDING_X, 0, 0), "Goal")
	k.ground(LANDING_X - 45.0, LANDING_X + 90.0, 0)
	k.toilet(LANDING_X + 20.0, 0)
	k.mega_can(LANDING_X + 32.0, 1.3)
	k.bean_can(LANDING_X + 60.0, 0)
	return k.finish("res://scenes/stage_1_3.tscn")


## One SUPER BOOST and everything inside it: three wide rows of beans in gentle waves and big
## hoops now and then. All easy and no hazards. "wave" just shifts the wave so boosts differ.
func _boost(k, span: Vector2, wave: float) -> void:
	k.super_boost(span.x, span.y, LANE.x, LANE.y, BOOST_SPEED)
	var mid: float = (LANE.x + LANE.y) * 0.5
	var x: float = span.x + 14.0
	while x <= span.y - 8.0:
		var swing: float = 3.0 * sin((x - span.x) * 0.06 + wave)
		for row in [-3.5, 0.0, 3.5]:
			k.bean(x, mid + swing + row)
		x += 4.0
	# Big hoops (one and a half times the usual size) to fly straight through.
	var hx: float = span.x + 35.0
	while hx <= span.y - 20.0:
		var hoop: Node3D = k.hoop(hx, mid + 3.0 * sin((hx - span.x) * 0.06 + wave))
		hoop.scale = Vector3.ONE * 1.5
		hx += 25.0
