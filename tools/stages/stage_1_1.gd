extends RefCounted
## Stage 1-1: THE VEG PATCH. The tutorial. About 2 minutes, very hard to fail.
## One new idea at a time, each with a hint sign (a different text for SIMPLE and CLASSIC controls):
## walk, hop, hold for a high jump, double jump, hover over a hole, stomp Burplings, a mushroom,
## a toilet checkpoint, and the Bean Can. There is no bottomless pit: the one "gap" is a soft ditch
## with a slope out. A fake wall and a secret bean room are placed on purpose to show secrets exist.

const Secrets := preload("res://tools/kit_secrets.gd")
const CARROT: Color = Color(0.95, 0.5, 0.1)


func build(k) -> Array[String]:
	k.begin("1-1", "LET'S GET THOSE BEANS!", Vector3(-4, 1.2, 0), Color(0.55, 0.8, 0.95))
	k.garden_scenery(-12, 260)

	# --- A. Walk, hop, high jump. Flat ground all the way, nothing can hurt him yet. -----------
	k.ground(-12, 110)
	k.hint(-3, 0, "RUN RIGHT!", 3.0)
	k.beans_line(0, 12, 1.3)
	k.hint(8, 0, "TAP JUMP TO HOP!", 3.0, "TAP JUMP TO HOP!")
	k.beans_arc(14, 19, 0.6, 1.6, 4)
	k.hint(20, 0, "HOP ONTO THE BOX!")
	k.platform(25, 1.0, 3.0)
	k.bean(25, 2.0)
	k.hint(30, 0, "HOLD FART, LET GO FOR A BIG JUMP!", 4.0, "HOLD JUMP TO JUMP HIGHER!")
	k.block(37, 40, 0, 2.0, CARROT, true)
	k.beans_arc(36, 41, 2.2, 1.5, 5)
	# --- B. Burplings: jump on them. ----------------------------------------------------------
	k.hint(43, 0, "JUMP ON BURPLINGS!", 3.0)
	k.enemy("burpling", 49, 0, {"patrol_distance": 2.0})
	k.enemy("burpling", 54, 0, {"patrol_distance": 2.0})
	k.beans_line(46, 58, 1.3, 2.0)
	k.toilet(60, 0)
	# --- C. Double jump over a wall. -------------------------------------------------------------
	k.hint(63, 0, "HOLD FART FOR A HUGE JUMP!", 3.5, "JUMP AGAIN IN THE AIR!")
	k.block(70, 73, 0, 3.6, CARROT, true)
	k.beans_arc(68, 75, 3.8, 2.0, 6)
	# Golden Bean 1: a high crate, a double jump away (a big Thunder does it too).
	k.hint(79, 0, "A SHINY BEAN UP THERE!", 3.0, "DOUBLE JUMP FOR THE SHINY BEAN!")
	Secrets.secret_ledge(k, 85, 4.4, 3.0, k.WOOD, 0.0)
	k.golden(85, 5.8)
	k.enemy("burpling", 92, 0, {"patrol_distance": 2.0})
	# --- D. The ditch: hover across (or just walk down and up the slope). ----------------------
	k.hint(98, 0, "OOPS-A-DITCH! WALK DOWN AND UP!", 3.5, "HOLD LB TO HOVER ACROSS!")
	k.ground(110, 118, -3.0, k.DIRT, false)
	k.ramp(118, 128, -3.0, 0.0)
	k.routes.append([110.0, 118.0, -3.0])
	k.routes.append([118.0, 128.0, 0.0])
	k.beans_arc(108, 127, 1.5, 4.0, 10)
	k.beans_line(111, 117, -1.7, 2.0)
	k.ground(128, 262)
	k.toilet(133, 0)

	# --- E. A mushroom, then a bean room hidden in a wobbly wall. -----------------------------
	k.hint(136, 0, "BOING! LAND ON THE MUSHROOM!", 3.0)
	k.pad(143, 0)
	k.beans_arc(141, 149, 2.0, 3.5, 6)
	# Pickup off the path: a Heart on a ledge the mushroom reaches.
	Secrets.secret_ledge(k, 150, 4.6, 3.0, k.WOOD, 0.0)
	k.heart(150, 6.0)
	# The easy secret: the wall on the ledge is fake, and a pipe hides inside.
	k.hint(156, 0, "WOBBLY WALL? WALK INTO IT!", 4.0)
	k.platform(168, 1.6, 14.0)
	k.beans_line(160, 166, 2.9, 2.0)
	Secrets.bean_room(k, 169.5, 1.6, -20.0, 40.0, {"golden": true, "hidden": true, "color": k.GRASS, "springs": 3, "pads": 2,
		"exit_to": Vector3(172.5, 3.0, 0)})
	k.enemy("burpling", 182, 0, {"patrol_distance": 2.0})
	k.enemy("burpling", 188, 0, {"patrol_distance": 2.0})
	k.beans_line(178, 192, 1.3, 2.0)
	k.toilet(196, 0)

	# --- F. A fake wall on the path (Golden Bean 2), and a double-jump-and-hover bean room. -----
	Secrets.fake_wall(k, 204, 211, 0.0, 3.5, k.DIRT.lightened(0.15))
	k.golden(207.5, 1.4)
	k.beans_line(202, 210, 1.3, 1.5)
	# High ledges: double jump to the first, then hover across the gap to the second.
	k.hint(214, 0, "SECRETS UP HIGH!", 3.0, "DOUBLE JUMP, THEN HOVER!")
	Secrets.secret_ledge(k, 221, 4.6, 3.0, k.WOOD, 0.0)
	Secrets.secret_ledge(k, 233, 5.4, 6.0, k.WOOD, 0.0, true)
	k.beans_arc(222, 232, 6.0, 2.5, 7)
	Secrets.bean_room(k, 235.0, 5.4, 40.0, 80.0, {"hidden": true, "color": k.GRASS, "springs": 2, "pads": 3,
		"exit_to": Vector3(237.0, 6.7, 0)})

	# --- G. The finish. ------------------------------------------------------------------------
	k.enemy("burpling", 246, 0, {"patrol_distance": 1.5})
	k.toilet(244, 0)
	k.beans_line(246, 256, 1.3, 2.0)
	k.hint(250, 0, "THE BEAN CAN! JUMP ON IT!", 3.0)
	k.bean_can(258, 0)
	return k.finish("res://scenes/stage_1_1.tscn")
