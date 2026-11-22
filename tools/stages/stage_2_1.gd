extends RefCounted
## Stage 2-1: THE CONVEYOR BELTS (about 2 minutes 15 seconds).
## Four different feelings: the LOADING DOCK (belts that help you and belts that fight you),
## the STAMP HALL (timing the presses), the BISCUIT BAKERY (platforms that crumble under you)
## and the BELT BACKWARDS (a long belt against you, with Cork Bots rolling at you).

const KIT := "res://tools/kit_factory.gd"
const Secrets := preload("res://tools/kit_secrets.gd")


func build(k) -> Array[String]:
	k.begin("2-1", "WELCOME TO THE BEAN FACTORY!", Vector3(-4, 1.2, 0), Color(0.42, 0.44, 0.5))
	k.factory_scenery(-12, 340)
	var steel: Color = k.STEEL

	# --- A. THE LOADING DOCK: belts, a Cork Bot, and a tower of bean tins. -----------------
	k.ground(-12, 30, 0, steel)
	k.hint(-2, 0, "BELTS CARRY YOU ALONG!")
	k.hint(6, 0, "HOLD FART, LET GO TO JUMP!", 3.0, "JUMP, THEN JUMP AGAIN IN THE AIR!")
	k.beans_line(2, 26, 1.3, 2.5)
	k.toilet(12, 0)
	k.hint(14, 0, "CORK BOTS ROLL! STOMP THEM!", 3.5)
	k.enemy("cork_bot", 22, 0, {"patrol_distance": 4.0})
	# A belt going your way: zoom!
	k.hint(27, 0, "THIS BELT HELPS YOU!", 2.5)
	k.belt(30, 52, 0, 3.0)
	k.beans_line(32, 50, 1.4, 2.0)
	k.ground(52, 60, 0, steel)
	k.toilet(56, 0)
	# A belt going backwards: keep running!
	k.hint(54, 0, "BACKWARDS BELT! KEEP RUNNING!", 3.5)
	k.belt(60, 88, 0, -3.0)
	k.beans_line(62, 86, 1.4, 2.5)
	k.enemy("cork_bot", 74, 0, {"patrol_distance": 5.0})
	# The bean tin tower up to Golden Bean 1 (optional).
	k.ground(88, 150, 0, steel)
	k.toilet(92, 0)
	k.hint(95, 0, "CLIMB THE TINS FOR A SHINY BEAN!", 3.5, "JUMP UP THE TINS FOR A SHINY BEAN!")
	k.platform(98, 2.0, 3.0, k.CRATE)
	k.platform(103, 4.2, 3.0, k.CRATE)
	k.platform(108, 6.4, 3.0, k.CRATE)
	k.golden(108, 7.8)
	# Secret bean room: walk right along the tin ledge into the wobbly wall.
	Secrets.secret_ledge(k, 114, 6.4, 8.0, k.CRATE, 4.2)
	Secrets.bean_room(k, 116.2, 6.4, -20.0, 40.0, {"hidden": true, "color": k.STEEL, "springs": 3, "pads": 2, "vents": 1,
		"exit_to": Vector3(111.5, 7.7, 0)})

	# --- B. THE STAMP HALL: wait for the stamps, then go. ---------------------------------
	k.hint(112, 0, "STAMPS! GO WHEN THEY ARE UP!", 3.5)
	k.stamp(118, 0, {"phase": 0.0})
	k.stamp(129, 0, {"phase": 0.5})
	k.beans_line(114, 134, 1.3, 2.5)
	# Golden Bean 2: ride the stamp up (it is safe on top) and jump to the high shelf.
	k.hint(122, 0, "STAMPS ARE SAFE ON TOP!", 3.0)
	k.platform(129, 8.0, 3.0, k.CRATE)
	k.golden(129, 9.4)
	k.toilet(138, 0)
	# A Mega Bean Can in a wall that is not really there.
	Secrets.fake_wall(k, 140, 146, 0.0, 3.2, k.STEEL_DARK.lightened(0.15))
	k.mega_can(143, 1.6)
	# Stamps over a belt that carries you towards them.
	k.hint(146, 0, "BELT + STAMPS! KEEP MOVING!", 3.5)
	k.belt(150, 182, 0, 2.5)
	k.stamp(160, 0, {"phase": 0.25})
	k.stamp(172, 0, {"phase": 0.75})
	k.beans_line(152, 180, 1.3, 2.5)
	k.ground(182, 200, 0, steel)
	k.toilet(186, 0)
	k.enemy("cork_bot", 194, 0, {"patrol_distance": 3.0})

	# --- C. THE BISCUIT BAKERY: the floor crumbles, so keep hopping. ------------------------
	k.hint(197, 0, "BISCUITS CRUMBLE! KEEP HOPPING!", 3.5, "KEEP JUMPING! HOLD LB IF YOU SLIP!")
	for cx in [204.0, 209.0, 214.0, 219.0]:
		k.biscuit(cx, 0.0, 3.0, {}, true)
	k.beans_arc(202, 221, 1.3, 1.5, 8)
	k.ground(224, 232, 0, steel)
	k.toilet(227, 0)
	# Biscuit stairs going up.
	k.biscuit(236, 1.5, 3.0, {}, true)
	k.biscuit(241, 3.0, 3.0, {"crumble_delay": 0.8}, true)
	k.biscuit(246, 4.5, 3.0, {"crumble_delay": 0.8}, true)
	k.beans_arc(234, 247, 2.8, 1.5, 7)
	# Golden Bean 3: a high lonely biscuit.
	k.biscuit(243, 7.0, 3.0, {"crumble_delay": 1.2}, false, 0.3)
	k.golden(243, 8.4)
	k.ground(250, 262, 4.5, steel)
	k.toilet(254, 4.5)

	# --- D. THE BELT BACKWARDS: a long belt against you, Cork Bots rolling at you. ---------
	k.hint(258, 4.5, "A LONG BACKWARDS BELT! GO GO GO!", 3.5, "BACKWARDS BELT! HOVER OVER IT!")
	k.belt(262, 300, 4.5, -3.5)
	k.beans_line(264, 298, 5.9, 2.5)
	k.enemy("cork_bot", 276, 4.5, {"patrol_distance": 5.0})
	k.enemy("cork_bot", 290, 4.5, {"patrol_distance": 5.0, "walk_speed": 4.0})
	# A Mega Bean Can on a high crate, and a bean room on a higher ledge (double jump + hover).
	Secrets.secret_ledge(k, 284, 9.3, 3.0, k.CRATE, 4.5)
	k.mega_can(284, 10.7)
	Secrets.secret_ledge(k, 270, 11.0, 7.0, k.CRATE, 4.5, true)
	Secrets.bean_room(k, 272.0, 11.0, 40.0, 80.0, {"hidden": true, "color": k.STEEL, "springs": 2, "pads": 3, "vents": 2,
		"exit_to": Vector3(267.5, 12.3, 0)})
	k.ground(300, 312, 4.5, steel)
	k.toilet(304, 4.5)

	# --- E. THE FIZZ BAT CROSSING: small crates, bats to bounce off, then a belt against you. -----
	k.hint(308, 4.5, "BATS BOUNCE YOU! HOP ALONG!", 3.5, "JUMP, JUMP AGAIN, HOVER ACROSS!")
	for cx in [317.0, 324.0, 331.0]:
		k.platform(cx, 4.5, 2.6, k.CRATE, true)
	k.enemy("fizz_bat", 320.5, 7.2, {"patrol_distance": 2.0, "wave_height": 1.2})
	k.enemy("fizz_bat", 327.5, 7.2, {"patrol_distance": 2.0, "wave_height": 1.2})
	k.beans_arc(315, 333, 5.8, 3.0, 8)
	k.belt(335, 355, 4.5, -3.0)
	k.stamp(343, 4.5, {"phase": 0.5})
	k.enemy("cork_bot", 350, 4.5, {"patrol_distance": 3.0})
	k.beans_line(337, 353, 5.9, 2.5)
	k.ground(355, 390, 4.5, steel)
	k.toilet(359, 4.5)
	k.hint(364, 4.5, "ALMOST THERE!", 2.5)
	k.beans_line(362, 380, 5.9, 2.5)
	k.bean_can(382, 4.5)
	return k.finish("res://scenes/stage_2_1.tscn")
