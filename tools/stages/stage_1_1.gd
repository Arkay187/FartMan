extends RefCounted
## Stage 1-1: THE VEG PATCH (about 1 minute 45 seconds).
## Teaches everything gently: hop, then Trump, then Thunder, then it gets silly:
## a mushroom bounce chain, a wheelbarrow ride, sprinklers and a pie-throwing gnome.
## Hiccups, a Gnome, a Crow or two, and a Chilli to finish.

func build(k) -> Array[String]:
	k.begin("1-1", "LET'S GET THOSE BEANS!", Vector3(-4, 1.2, 0), Color(0.55, 0.8, 0.95))
	k.garden_scenery(-12, 310)

	# --- A. The meadow: hop, and hop a gap. -------------------------------------------
	k.ground(-12, 22)
	k.hint(-1, 0, "TAP JUMP TO HOP!")
	k.beans_line(2, 14, 1.3)
	k.enemy("burpling", 12, 0, {"patrol_distance": 2.0})
	k.hint(18, 0, "HOP OVER THE GAP!")
	k.beans_arc(21, 26, 1.2, 1.6, 5)

	# --- B. Carrot steps: Trump, then a Thunder wall, then prickles. ---------------------
	k.ground(25, 108)
	k.toilet(30, 0)
	k.hint(34, 0, "HOP ONTO THE BOX!")
	k.platform(39, 0.8, 3.0)
	k.bean(39, 1.8)
	k.hint(48, 0, "HOLD FART, LET GO FOR A BIG JUMP!", 4.0)
	k.beans_line(50, 54, 1.3)
	# Steps up to the first Golden Bean (optional).
	k.platform(58, 2.0, 3.0)
	k.platform(64, 4.0, 3.0)
	k.platform(70, 6.0, 3.0)
	k.golden(70, 7.4)
	k.enemy("burpling", 62, 0, {"patrol_distance": 2.0})
	# The big carrot: only a full belly gets over it.
	k.hint(75, 0, "FULL BELLY = HUGE JUMP!", 3.5)
	k.block(80, 83, 0, 3.2, Color(0.95, 0.5, 0.1), true)
	k.beans_arc(78, 85, 3.4, 2.0, 6)
	k.hint(86, 0, "PRICKLES HURT! HOP OVER!")
	k.prickle(90, 0)
	k.prickle(93.5, 0)
	k.beans_arc(88.5, 95, 0.8, 1.8, 5)
	k.enemy("burpling", 98, 0, {"patrol_distance": 2.0})
	k.toilet(106, 0)

	# --- C. Mushroom meadow: bounce across the pit. -------------------------------------
	k.hint(103, 0, "BOING! KEEP HOLDING RIGHT!", 3.0)
	k.pad(107.6, 0)
	k.platform(117.5, 0.0, 7.0, k.GRASS)
	k.pad(117.5, 0)
	k.platform(127.0, 0.0, 7.0, k.GRASS)
	k.pad(127.0, 0)
	k.routes.append([108.0, 133.0, 0.0])
	k.beans_arc(109, 114.5, 1.0, 4.5, 6)
	k.beans_arc(119, 124, 1.0, 4.5, 5)
	k.hint(115, 0, "FART AT THE TOP!", 2.5)
	k.golden(122, 8.4)
	k.enemy("crow", 122, 3.6, {"patrol_distance": 3.5, "walk_speed": 2.0, "bob_height": 0.6})
	# A short Hiccup hop-about, then straight on to the wheelbarrow.
	k.ground(133, 156)
	k.toilet(136, 0)
	k.enemy("hiccup", 142, 0, {"phase": 0.0})
	k.enemy("hiccup", 148, 0, {"phase": 0.5})
	k.beans_line(140, 152, 1.3, 2.5)

	# --- D. The wheelbarrow bog: ride across the mud, then up the lift. ------------------
	k.hint(152, 0, "HOP ON THE WHEELBARROW!", 3.0)
	k.moving(158.5, 0.0, 4.0, Vector3(7, 0, 0), 3.0, 1.0, 0.0)
	k.platform(171.5, 0.0, 4.0, k.WOOD)
	k.routes.append([154.0, 176.0, 0.0])
	k.beans_line(157, 174, 2.0, 3.0)
	k.enemy("crow", 171.5, 4.0, {"patrol_distance": 4.0, "walk_speed": 2.5, "bob_height": 0.8})
	k.ground(176, 186)
	k.toilet(180, 0)
	k.hint(183, 0, "LIFT GOING UP! WAIT FOR IT!", 3.0)
	k.moving(190.5, 0.0, 4.0, Vector3(0, 3.2, 0), 1.6, 1.2, 0.0)
	k.routes.append([188.5, 192.5, 3.2])
	k.beans_line(190.5, 190.5, 3.0)

	# --- E. Sprinkler alley, a gnome, and the finish. --------------------------------
	k.ground(194.5, 305, 3.2)
	k.toilet(198, 3.2)
	k.hint(202, 3.2, "SPRINKLERS! RUN WHEN THEY STOP!", 3.0)
	k.sprinkler(209, 3.2, 0.0)
	k.sprinkler(216, 3.2, 0.5)
	k.beans_line(206, 222, 4.6, 2.5)
	# Golden Bean 3: a stack of crates above the sprinklers.
	k.platform(212, 5.4, 3.0)
	k.platform(217.5, 7.6, 3.0)
	k.golden(217.5, 8.9)
	k.hint(226, 3.2, "GRUMPY GNOMES THROW PIES!", 3.0)
	k.enemy("gnome", 236, 3.2, {"throw_every": 3.0})
	k.block(240, 243, 3.2, 4.4, Color(0.85, 0.75, 0.3))
	k.beans_line(232, 248, 4.6, 2.5)
	k.toilet(251, 3.2)
	k.hint(255, 3.2, "CHILLI! RUN THROUGH THEM ALL!", 3.0)
	k.chilli(258, 4.6)
	for i in 3:
		k.enemy("burpling", 265 + i * 3.5, 3.2, {"patrol_distance": 1.0})
	k.prickle(278, 3.2)
	k.prickle(281.5, 3.2)
	k.mega_can(286, 4.5)
	k.bean_can(295, 3.2)
	return k.finish("res://scenes/stage_1_1.tscn")
