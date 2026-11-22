extends RefCounted
## Stage 1-2: THE GREENHOUSE (about 2 minutes 30 seconds). The second tutorial.
## New ideas, one at a time: Hiccups, Prickles (cacti), a mud-pie Gnome, a big Spring, the Chilli dash
## (a giant cabbage chases you), then Hot Sauce and the FIRE BURP PARTY (lots of Burplings to bowl over)
## and a bouncy finale. Chillies and Hearts hide behind secrets; two secret bean rooms.

const Secrets := preload("res://tools/kit_secrets.gd")
const POT: Color = Color(0.85, 0.45, 0.25)
const TILE: Color = Color(0.8, 0.55, 0.35)


## The height of the downhill slope's surface at x (it runs from x=232 down to x=288).
func slope_y(x: float) -> float:
	return -8.0 * (x - 232.0) / 56.0


func build(k) -> Array[String]:
	k.begin("1-2", "WHAT A BIG GREENHOUSE!", Vector3(-4, 1.2, 0), Color(0.72, 0.92, 0.85))
	k.greenhouse_scenery(-12, 491)

	# --- A. Pots, Hiccups and cacti. ------------------------------------------------------
	k.ground(-12, 80, 0, TILE)
	k.hint(-2, 0, "WELCOME TO THE GREENHOUSE!")
	k.hint(6, 0, "HICCUPS HOP! STOMP THEM WHEN THEY LAND!", 3.5)
	k.enemy("hiccup", 12, 0, {"phase": 0.0})
	k.enemy("hiccup", 19, 0, {"phase": 0.5})
	k.enemy("burpling", 26, 0, {"patrol_distance": 2.5})
	k.beans_line(4, 30, 1.3, 2.5)
	# Pot stairs up to Golden Bean 1 (optional).
	k.hint(36, 0, "CLIMB THE POTS FOR A SHINY BEAN!", 3.0, "JUMP UP THE POTS FOR A SHINY BEAN!")
	Secrets.secret_ledge(k, 40, 2.0, 3.0, POT, 0.0)
	Secrets.secret_ledge(k, 46, 4.2, 3.0, POT, 2.0)
	Secrets.secret_ledge(k, 52, 6.4, 3.0, POT, 4.2)
	k.golden(52, 7.8)
	# Cacti: hop the pair.
	k.hint(56, 0, "CACTI HURT! BIG JUMP OVER!", 3.0, "CACTI HURT! JUMP OVER THEM!")
	k.prickle(62, 0)
	k.prickle(64.2, 0)
	k.beans_arc(60, 66.5, 0.9, 3.0, 6)
	# The watering-can gnome with a pot to hide behind.
	k.hint(70, 0, "GNOMES THROW MUD PIES! DUCK BEHIND THE POT!", 3.5)
	k.enemy("gnome", 76, 0, {"throw_every": 3.0})
	k.block(72, 74.5, 0, 1.8, POT)
	k.toilet(80, 0)

	# --- B. Sprinkler pipes, a spring, a lift, and a Crow. ------------------------------------
	k.ground(80, 138, 0, TILE)
	k.hint(85, 0, "SPRINKLER PIPES! TIME IT!", 3.0, "SPRINKLERS! WAIT, THEN RUN!")
	k.sprinkler(92, 0, 0.0, 4.0)
	k.sprinkler(98, 0, 0.5, 4.0)
	k.beans_line(90, 100, 1.4, 2.0)
	k.enemy("hiccup", 105, 0, {"phase": 0.1})
	# A big spring to a ledge of beans (the spring throws him high: jump as you land for a MEGA boing).
	k.hint(106, 0, "A SPRING! JUMP AS YOU LAND FOR A MEGA BOING!", 4.0)
	Secrets.spring(k, 110, 0)
	Secrets.secret_ledge(k, 115, 6.5, 6.0, POT, 2.0)
	k.beans_line(113, 117, 7.8, 1.0)
	k.hint(118, 0, "A LIFT! GO UP FOR A SHINY BEAN!", 3.0)
	# Lift up to a high shelf with Golden Bean 2, and a bean room behind a wobbly wall.
	k.moving(124, 0.0, 3.5, Vector3(0, 6.2, 0), 2.0, 1.5, 0.0)
	k.platform(132, 6.2, 12.0, POT)
	k.golden(130, 7.6)
	Secrets.bean_room(k, 135.2, 6.2, -20.0, 40.0, {"hidden": true, "color": TILE, "springs": 3, "pads": 3,
		"exit_to": Vector3(129.0, 7.5, 0)})
	k.enemy("crow", 124, 3.0, {"patrol_distance": 4.0, "walk_speed": 2.0, "bob_height": 0.7})
	k.toilet(136, 0)

	# --- C. The GIANT CABBAGE CHASE. -----------------------------------------------------
	# The cabbage waits at x=138 and rolls once he passes x=150. It crashes at x=206.
	k.chaser(138, 0, 150, 206, 5.4)
	k.chilli(144, 1.4)
	k.hint(146, 0, "RUN! DON'T STOP! (CHILLI HELPS!)", 3.0)
	k.ground(138, 182, 0, TILE)
	k.prickle(160, 0)
	k.prickle(162.2, 0)
	k.beans_arc(158, 164.5, 0.9, 2.8, 5)
	k.enemy("burpling", 170, 0, {"patrol_distance": 1.0})
	k.enemy("burpling", 175, 0, {"patrol_distance": 1.0})
	k.beans_line(152, 180, 1.3, 2.5)
	# One little gap to hop.
	k.ground(185, 214, 0, TILE)
	k.beans_arc(181, 186, 1.2, 1.6, 4)
	# A wall to jump while running.
	k.hint(191, 0, "BIG JUMP OVER THE WALL! HOLD FART!", 3.0, "JUMP OVER THE WALL! HOLD JUMP!")
	k.block(198, 200.2, 0, 2.0, POT, true)
	k.beans_arc(195.5, 203, 2.1, 1.6, 5)
	k.toilet(212, 0)

	# --- D. Downhill dash. A second Chilli hides in a wall. ---------------------------------
	k.ground(214, 232, 0, TILE)
	k.hint(218, 0, "A WALL WITH A CHILLI IN IT!", 3.0)
	Secrets.fake_wall(k, 222, 230, 0.0, 3.2, TILE.darkened(0.2))
	k.chilli(226, 1.4)
	k.ramp(232, 288, 0.0, -8.0, TILE)
	k.routes.append([232.0, 288.0, -8.0])
	for i in 9:
		var x: float = 238.0 + i * 5.5
		k.enemy("burpling", x, slope_y(x), {"walk_speed": 0.0, "patrol_distance": 0.1})
	for i in 17:
		var bx: float = 234.0 + i * 3.0
		k.bean(bx, slope_y(bx) + 2.2)
	# Golden Bean 3: high above the slope.
	k.hint(262, -4, "A HIGH SHINY BEAN! BIG JUMP!", 3.0, "DOUBLE JUMP FOR THE SHINY BEAN!")
	k.golden(268, slope_y(268) + 4.8)
	k.ground(288, 486, -8, TILE)
	k.toilet(294, -8)

	# --- E. FIRE BURP PARTY: Hot Sauce, then a long flat run packed with Burplings. -----------
	# Hot Sauce at x=304. Press C (pad B) to burp a rolling fireball: it bowls through a whole line.
	# The party is x=324 to x=418: 6 clumps of Burplings and Hiccups, 3 Crows to stomp, beans between.
	k.hint(298, -8, "HOT SAUCE! PRESS C OR B TO FIRE BURP!", 3.5, "HOT SAUCE! PRESS B TO FIRE BURP!")
	k.hot_sauce(304, -6.6)
	k.beans_line(308, 320, -6.7, 2.0)
	# A bean room up on a ledge: double jump from the floor to get up.
	Secrets.secret_ledge(k, 313, -4.2, 10.0, POT, -8.0)
	Secrets.bean_room(k, 316.0, -4.2, 60.0, 120.0, {"hidden": true, "color": TILE, "springs": 2, "pads": 2,
		"exit_to": Vector3(311.0, -2.9, 0)})
	var floor_y: float = -8.0
	var clump_x: Array[float] = [326.0, 342.0, 358.0, 374.0, 390.0, 406.0]
	var clump_size: Array[int] = [5, 4, 5, 4, 5, 5]
	for c in clump_x.size():
		for i in clump_size[c]:
			var ex: float = clump_x[c] + i * 1.5
			if (i + c) % 4 == 3:
				k.enemy("hiccup", ex, floor_y, {"phase": (i * 0.23 + c * 0.11)})
			else:
				k.enemy("burpling", ex, floor_y, {"walk_speed": 0.6, "patrol_distance": 0.5})
		# Beans over each clump and in the gap before the next one.
		k.beans_line(clump_x[c], clump_x[c] + clump_size[c] * 1.5, -5.6, 1.5)
		k.beans_line(clump_x[c] + 9.0, clump_x[c] + 14.0, -6.7, 1.7)
	# Crows overhead, low enough to stomp with a hop.
	k.enemy("crow", 334, -5.2, {"patrol_distance": 3.0, "walk_speed": 2.0, "bob_height": 0.6})
	k.enemy("crow", 366, -5.2, {"patrol_distance": 3.0, "walk_speed": 2.0, "bob_height": 0.6})
	k.enemy("crow", 398, -5.2, {"patrol_distance": 3.0, "walk_speed": 2.0, "bob_height": 0.6})
	k.toilet(424, -8)

	# --- F. Bouncy finale: pads, a Crow and the Bean Can. ---------------------------------
	k.hint(428, -8, "BOING! STOMP THE CROW FOR MORE BOING!", 3.5)
	k.pad(434, -8)
	k.pad(444, -8)
	k.enemy("crow", 439, -2.0, {"patrol_distance": 3.0, "walk_speed": 2.0, "bob_height": 0.8})
	k.beans_arc(434, 444, -7.0, 6.5, 8)
	k.enemy("hiccup", 458, -8, {"phase": 0.0})
	k.toilet(464, -8)
	# A Chilli behind a wall (a few steps before the Bean Can).
	Secrets.fake_wall(k, 466, 474, -8.0, -4.8, TILE.darkened(0.2))
	k.chilli(470, -6.6)
	k.bean_can(478, -8)
	return k.finish("res://scenes/stage_1_2.tscn")
