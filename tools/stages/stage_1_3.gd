extends RefCounted
## Stage 1-3: OVER THE ROOFTOPS (a flying stage, about 1 minute).
## He starts already flying. Hold jump to rise, let go to sink.
## Washing lines, flocks of Crows, up-draughts, geysers, a slalom of spiky balls,
## a very surprised cow, and a finale of hoops. Sky toilets keep him flying after a mishap.

const LANE: Vector2 = Vector2(3.0, 16.0)


func build(k) -> Array[String]:
	k.begin("1-3", "HOLD JUMP TO RISE!", Vector3(0, 9, 0), Color(0.55, 0.8, 0.98))
	k.root.set("start_flight", LANE)
	k.landscape(-20, 930, -9.0)

	# --- Warm-up: a wavy line of beans and two hoops. -----------------------------------
	for x in range(10, 101, 3):
		k.bean(x, 9.5 + 4.0 * sin(x * 0.1))
	k.hoop(40, 11.5)
	k.hoop(75, 7.5)
	k.sky_toilet(110)

	# --- The village: washing lines, low then high. -------------------------------------
	k.washing_line(130, 170, 5.5)
	k.washing_line(185, 225, 13.0)
	for x in range(130, 226, 3):
		var line_low: bool = x < 170
		var line_high: bool = x >= 185
		if line_low:
			k.bean(x, 10.5)
		elif line_high:
			k.bean(x, 7.0)
		else:
			k.bean(x, 9.0)
	k.hoop(155, 10.5)
	k.hoop(205, 7.5)
	k.golden(205, 4.0)
	k.sky_toilet(245)

	# --- Crow flocks: fly through the middle, or stomp them from above. -----------------
	for f in 2:
		var cx: float = 270.0 + f * 40.0
		var cy: float = [8.0, 11.5][f]
		for pair in [[0.0, 2.8], [0.0, -2.8], [4.0, 5.6], [4.0, -5.6]]:
			var ey: float = cy + pair[1]
			if ey > 15.0 or ey < 4.0:
				continue
			k.enemy("crow", cx + pair[0], ey, {"walk_speed": 0.0, "patrol_distance": 0.2, "bob_height": 1.4, "bob_speed": 4.0})
		for x in range(int(cx) - 6, int(cx) + 14, 3):
			k.bean(x, cy)
	k.golden(355, 14.6)
	k.enemy("crow", 355, 12.2, {"walk_speed": 0.0, "patrol_distance": 0.2, "bob_height": 0.8})
	k.sky_toilet(385)

	# --- Up-draughts with spiky ceilings, and geysers from the village. -----------------
	k.cow(480, -8.5, 460, 500)
	for i in 2:
		var ux: float = 410.0 + i * 35.0
		k.updraft(ux, ux + 8.0, 3.0, 16.0)
		k.spiky(ux + 4.0, 15.2)
		for y in range(4, 14, 3):
			k.bean(ux + 4.0, float(y))
	for i in 2:
		k.sprinkler(500.0 + i * 22.0, -8.5, 0.25 * i, 16.0, 1.4, 2.0)
	for x in range(495, 540, 3):
		k.bean(x, 11.5 + 2.5 * sin(x * 0.2))
	k.hoop(515, 12.0)
	k.sky_toilet(545)

	# --- The spiky slalom: find the gap in every wall. -----------------------------------
	for i in 3:
		var wx: float = 575.0 + i * 30.0
		var gap_y: float = 9.5 + 4.2 * sin(i * 1.1)
		var y: float = 3.2
		while y <= 16.0:
			if absf(y - gap_y) > 3.0:
				k.spiky(wx, y)
			y += 1.7
		k.bean(wx - 6.0, gap_y)
		k.bean(wx - 3.0, gap_y)
		k.bean(wx, gap_y)
	k.sky_toilet(670)

	# --- Finale: a rollercoaster of hoops, beans and more Crows. -------------------------
	k.cow(740, -8.5, 710, 770)
	for i in 6:
		var hx: float = 690.0 + i * 17.0
		var hy: float = 9.5 + 5.5 * sin(i * 0.75)
		k.hoop(hx, hy)
		for j in 4:
			k.bean(hx + 3.0 + j * 3.0, 9.5 + 5.5 * sin((i + (j + 1) * 0.18) * 0.75))
	for x in [715.0, 755.0]:
		k.enemy("crow", x, 9.0, {"walk_speed": 0.0, "patrol_distance": 0.2, "bob_height": 3.0, "bob_speed": 2.0})
	k.golden(745, 15.2)

	# --- Landing: flight ends at the green curtain. --------------------------------------
	# The ground starts well before the curtain, so he can never drop into a hole when the flight ends.
	k.place("res://scenes/landing_zone.tscn", "LandingZone", Vector3(840, 0, 0), "Goal")
	k.ground(790, 930, 0)
	k.toilet(860, 0)
	k.mega_can(872, 1.3)
	k.bean_can(900, 0)
	return k.finish("res://scenes/stage_1_3.tscn")
