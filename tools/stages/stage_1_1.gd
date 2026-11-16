extends RefCounted
## Stage 1-1: THE VEG PATCH (about 2.5 minutes).
## Teaches everything gently: hop, then Trump, then Thunder, then it gets silly:
## a mushroom bounce chain, a wheelbarrow ride, sprinklers and pie-throwing gnomes.
## Four Hiccups, three Gnomes, a Crow or two, and a Chilli to finish.

func build(k) -> Array[String]:
	k.begin("1-1", "LET'S GET THOSE BEANS!", Vector3(-4, 1.2, 0), Color(0.55, 0.8, 0.95))
	k.garden_scenery(-12, 345)

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
	k.enemy("burpling", 103, 0, {"patrol_distance": 1.5})
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
	k.ground(133, 178)
	k.toilet(136, 0)
	k.enemy("hiccup", 142, 0, {"phase": 0.0})
	k.enemy("hiccup", 149, 0, {"phase": 0.5})
	k.enemy("burpling", 155, 0, {"patrol_distance": 2.5})
	k.enemy("burpling", 162, 0, {"patrol_distance": 2.5})
	k.enemy("hiccup", 168, 0, {"phase": 0.25})
	k.beans_line(140, 172, 1.3, 2.5)
	k.toilet(174, 0)

	# --- D. The wheelbarrow bog: ride across the mud. ---------------------------------
	k.hint(176, 0, "HOP ON THE WHEELBARROW!", 3.0)
	k.moving(182.5, 0.0, 4.0, Vector3(7, 0, 0), 3.0, 1.0, 0.0)
	k.platform(195.5, 0.0, 4.0, k.WOOD)
	k.moving(204.0, 0.0, 4.0, Vector3(7, 0, 0), 3.0, 1.0, 0.5)
	k.routes.append([178.0, 214.0, 0.0])
	k.beans_line(181, 212, 2.0, 3.0)
	k.enemy("crow", 199, 4.0, {"patrol_distance": 4.0, "walk_speed": 2.5, "bob_height": 0.8})
	k.ground(214, 224)
	k.toilet(218, 0)
	k.hint(221, 0, "LIFT GOING UP! WAIT FOR IT!", 3.0)
	k.moving(228.5, 0.0, 4.0, Vector3(0, 3.2, 0), 1.6, 1.2, 0.0)
	k.routes.append([226.5, 230.5, 3.2])
	k.beans_line(228.5, 228.5, 3.0)

	# --- E. Sprinkler alley, gnomes, and the finish. ---------------------------------
	k.ground(232.5, 345, 3.2)
	k.toilet(236, 3.2)
	k.hint(240, 3.2, "SPRINKLERS! RUN WHEN THEY STOP!", 3.0)
	k.sprinkler(247, 3.2, 0.0)
	k.sprinkler(254, 3.2, 0.33)
	k.sprinkler(261, 3.2, 0.66)
	k.beans_line(244, 264, 4.6, 2.5)
	# Golden Bean 3: a stack of crates above the sprinklers.
	k.platform(250, 5.4, 3.0)
	k.platform(255.5, 7.6, 3.0)
	k.golden(255.5, 8.9)
	k.hint(266, 3.2, "GRUMPY GNOMES THROW PIES!", 3.0)
	k.enemy("gnome", 274, 3.2, {"throw_every": 3.0})
	k.block(278, 281, 3.2, 4.4, Color(0.85, 0.75, 0.3))
	k.enemy("gnome", 286, 3.2, {"throw_every": 2.6})
	k.beans_line(270, 290, 4.6, 2.5)
	k.toilet(292, 3.2)
	k.hint(296, 3.2, "CHILLI! RUN THROUGH THEM ALL!", 3.0)
	k.chilli(299, 4.6)
	for i in 4:
		k.enemy("burpling", 306 + i * 3.5, 3.2, {"patrol_distance": 1.0})
	k.prickle(321, 3.2)
	k.prickle(324.5, 3.2)
	k.mega_can(329, 4.5)
	k.bean_can(338, 3.2)
	return k.finish("res://scenes/stage_1_1.tscn")
