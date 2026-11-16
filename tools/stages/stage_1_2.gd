extends RefCounted
## Stage 1-2: THE GREENHOUSE (about 3.5 minutes).
## Hiccups, Gnomes and Prickles, sprinkler pipes, a lift to a secret shelf, then the
## GIANT CABBAGE CHASE, a Chilli-powered downhill dash through a Burpling crowd,
## and a bouncy finale with Crows to stomp.

const POT: Color = Color(0.85, 0.45, 0.25)
const TILE: Color = Color(0.8, 0.55, 0.35)


## The height of the downhill slope's surface at x.
func slope_y(x: float) -> float:
	return -8.0 * (x - 300.0) / 80.0


func build(k) -> Array[String]:
	k.begin("1-2", "WHAT A BIG GREENHOUSE!", Vector3(-4, 1.2, 0), Color(0.72, 0.92, 0.85))
	k.greenhouse_scenery(-12, 500)

	# --- A. Pots, Hiccups and cacti. ------------------------------------------------------
	k.ground(-12, 90, 0, TILE)
	k.hint(-2, 0, "WELCOME TO THE GREENHOUSE!")
	k.hint(6, 0, "HICCUPS HOP! STOMP THEM WHEN THEY LAND!", 3.5)
	k.enemy("hiccup", 12, 0, {"phase": 0.0})
	k.enemy("hiccup", 19, 0, {"phase": 0.5})
	k.enemy("burpling", 26, 0, {"patrol_distance": 2.5})
	k.beans_line(4, 30, 1.3, 2.5)
	# Pot stairs up to Golden Bean 1 (optional).
	k.platform(40, 2.0, 3.0, POT)
	k.platform(46, 4.2, 3.0, POT)
	k.platform(52, 6.4, 3.0, POT)
	k.golden(52, 7.8)
	k.hint(36, 0, "CLIMB THE POTS FOR A SHINY BEAN!", 3.0)
	# Cacti: hop the pair.
	k.hint(56, 0, "CACTI! BIG JUMP OVER!", 3.0)
	k.prickle(62, 0)
	k.prickle(64.2, 0)
	k.beans_arc(60, 66.5, 0.9, 3.0, 6)
	k.enemy("hiccup", 70, 0, {"phase": 0.25})
	# The watering-can gnome with a pot to hide behind.
	k.enemy("gnome", 82, 0, {"throw_every": 3.0})
	k.block(76, 78.5, 0, 1.8, POT)
	k.toilet(90, 0)

	# --- B. Sprinkler pipes, a lift, and a Crow. ----------------------------------------------
	k.ground(90, 164, 0, TILE)
	k.hint(95, 0, "SPRINKLER PIPES! TIME IT!", 3.0)
	k.sprinkler(102, 0, 0.0, 4.0)
	k.sprinkler(108, 0, 0.25, 4.0)
	k.sprinkler(114, 0, 0.5, 4.0)
	k.sprinkler(120, 0, 0.75, 4.0)
	k.beans_line(100, 122, 1.4, 2.0)
	k.enemy("hiccup", 127, 0, {"phase": 0.1})
	k.enemy("hiccup", 133, 0, {"phase": 0.6})
	k.enemy("gnome", 143, 0, {"throw_every": 2.6})
	k.block(137, 139.5, 0, 1.8, POT)
	k.hint(140, 0, "A LIFT! GO UP FOR A SHINY BEAN!", 3.0)
	# Lift up to a high shelf with Golden Bean 2.
	k.moving(150, 0.0, 3.5, Vector3(0, 6.2, 0), 2.0, 1.5, 0.0)
	k.platform(156.5, 6.2, 8.0, POT)
	k.golden(157, 7.6)
	k.enemy("crow", 150, 3.0, {"patrol_distance": 4.0, "walk_speed": 2.0, "bob_height": 0.7})
	k.toilet(162, 0)

	# --- C. The GIANT CABBAGE CHASE. -----------------------------------------------------
	# The cabbage waits at x=164 and rolls once he passes x=176. It crashes at x=268.
	k.chaser(164, 0, 176, 268, 5.4)
	k.chilli(170, 1.4)
	k.hint(172, 0, "RUN! DON'T STOP! (CHILLI HELPS!)", 3.0)
	k.ground(164, 218, 0, TILE)
	k.prickle(190, 0)
	k.prickle(192.2, 0)
	k.beans_arc(188, 194.5, 0.9, 2.8, 5)
	k.enemy("burpling", 202, 0, {"patrol_distance": 1.0})
	k.enemy("burpling", 208, 0, {"patrol_distance": 1.0})
	k.beans_line(180, 215, 1.3, 2.5)
	# Two little gaps to hop.
	k.ground(221, 250, 0, TILE)
	k.beans_arc(217, 222, 1.2, 1.6, 4)
	k.ground(253, 274, 0, TILE)
	k.beans_arc(249, 254, 1.2, 1.6, 4)
	k.enemy("burpling", 235, 0, {"patrol_distance": 1.5})
	# A wall to jump while running: charge a Trump on the move.
	k.hint(255, 0, "BIG JUMP OVER THE WALL! HOLD FART!", 3.0)
	k.block(262, 264.2, 0, 2.0, POT, true)
	k.beans_arc(259.5, 267, 2.1, 1.6, 5)
	k.toilet(276, 0)

	# --- D. Downhill dash: Chilli time! ------------------------------------------------
	k.ground(274, 300, 0, TILE)
	k.hint(284, 0, "CHILLI! RUN DOWNHILL THROUGH THEM!", 3.5)
	k.chilli(292, 1.4)
	k.ramp(300, 380, 0.0, -8.0, TILE)
	k.routes.append([300.0, 380.0, -8.0])
	for i in 13:
		var x: float = 306.0 + i * 5.5
		k.enemy("burpling", x, slope_y(x), {"walk_speed": 0.0, "patrol_distance": 0.1})
	for i in 25:
		var bx: float = 302.0 + i * 3.0
		k.bean(bx, slope_y(bx) + 2.2)
	# Golden Bean 3: high above the slope, a hot Thunder reaches it.
	k.hint(335, -4, "HOT THUNDER REACHES HIGH!", 3.0)
	k.golden(342, slope_y(342) + 8.0)
	k.ground(380, 425, -8, TILE)
	k.toilet(386, -8)

	# --- E. Bouncy finale: pads, Crows and the Bean Can. ---------------------------------
	k.hint(396, -8, "BOING! STOMP THE CROWS FOR MORE BOING!", 3.5)
	k.pad(402, -8)
	k.pad(412, -8)
	k.enemy("crow", 407, -2.0, {"patrol_distance": 3.0, "walk_speed": 2.0, "bob_height": 0.8})
	k.beans_arc(402, 412, -7.0, 6.5, 8)
	k.sprinkler(432, -8, 0.0, 4.0)
	k.sprinkler(438, -8, 0.5, 4.0)
	k.enemy("gnome", 450, -8, {"throw_every": 2.4})
	k.block(444, 447, -8, -6.2, POT)
	k.enemy("hiccup", 458, -8, {"phase": 0.0})
	k.enemy("hiccup", 462, -8, {"phase": 0.5})
	k.toilet(468, -8)
	k.mega_can(474, -6.6)
	k.bean_can(484, -8)
	k.ground(425, 500, -8, TILE)
	return k.finish("res://scenes/stage_1_2.tscn")
