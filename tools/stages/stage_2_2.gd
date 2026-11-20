extends RefCounted
## Stage 2-2: THE PIPE MAZE (about 2 minutes 15 seconds).
## Five different feelings: STEAM ALLEY (vents launch you up a wall), FIZZ BAT SKY (hop across a
## pit full of bats), the SWITCH YARD (a big button swaps red and blue blocks), the WIND TUNNEL
## (fans push you while you are in the air) and the PIPE TOWER (warp pipe to a secret bean
## room, then vents lift you up to the Bean Can).

const KIT := "res://tools/kit_factory.gd"


func build(k) -> Array[String]:
	k.begin("2-2", "WHAT A MAZE OF PIPES!", Vector3(-4, 1.2, 0), Color(0.36, 0.4, 0.48))
	k.factory_scenery(-12, 340)
	var steel: Color = k.STEEL

	# --- A. STEAM ALLEY: step in the steam and it blasts you over the wall. -------------------
	k.ground(-12, 20, 0, steel)
	k.toilet(2, 0)
	k.hint(-2, 0, "STEAM VENTS BOOST YOU!", 3.0)
	k.hint(7, 0, "JUMP IN THE PUFF!", 3.0)
	k.vent(13, 0)
	k.beans_arc(14, 26, 5.8, 3.0, 7)
	k.block(20, 24, 0, 5.0, k.CRATE, true)
	# The plateau, with the first Fizz Bats.
	k.ground(24, 62, 5.0, steel)
	k.toilet(28, 5.0)
	k.hint(31, 5.0, "FIZZ BATS! STOMP THEM!", 3.0)
	k.enemy("fizz_bat", 36, 7.4, {"patrol_distance": 3.0})
	k.enemy("fizz_bat", 52, 7.8, {"patrol_distance": 3.0, "wave_height": 1.5})
	k.beans_line(30, 60, 6.3, 2.5)
	# Golden Bean 1: a vent blasts you up to a high ledge (optional).
	k.hint(37, 5.0, "STEAM UP FOR A SHINY BEAN!", 3.5)
	k.vent(40, 5.0, {"phase": 0.3})
	k.platform(47.5, 12.5, 5.0, k.CRATE)
	k.golden(47.5, 13.9)

	# --- B. FIZZ BAT SKY: a pit with bats to stomp and bounce off. ---------------------------
	k.hint(60, 5.0, "HOP ACROSS! BATS BOUNCE YOU!", 3.5)
	for cx in [67.0, 74.0, 81.0, 88.0]:
		k.platform(cx, 5.0, 3.0, k.CRATE, true)
	k.enemy("fizz_bat", 70.5, 8.0, {"patrol_distance": 2.0, "wave_height": 1.2})
	k.enemy("fizz_bat", 77.5, 8.0, {"patrol_distance": 2.0, "wave_height": 1.2})
	k.enemy("fizz_bat", 84.5, 8.0, {"patrol_distance": 2.0, "wave_height": 1.2})
	k.beans_arc(65, 90, 6.0, 3.0, 9)
	k.ground(93, 119, 5.0, steel)
	k.toilet(97, 5.0)

	# --- C. THE SWITCH YARD: press the big button, red blocks go and blue blocks come. -------
	k.hint(104, 5.0, "RED BLOCKS GO! BLUE BLOCKS COME!", 4.0)
	k.switch_block(122, 125, 5.0, true)
	k.switch_block(128, 131, 5.0, true)
	k.beans_arc(121, 132, 6.0, 1.8, 6)
	k.ground(134, 143, 5.0, steel)
	k.toilet(136, 5.0)
	k.hint(138, 5.0, "STEP ON THE BIG BUTTON!", 3.0)
	k.switch_button(140, 5.0)
	k.switch_block(146, 149, 5.0, false)
	k.switch_block(152, 155, 5.0, false)
	k.beans_arc(145, 156, 6.0, 1.8, 6)
	k.ground(158, 176, 5.0, steel)
	k.toilet(162, 5.0)

	# --- D. THE WIND TUNNEL: fans push you while you are in the air. ------------------------
	k.hint(168, 5.0, "FANS BLOW YOU ALONG!", 3.0)
	k.fan(177, 200, 2.0, 12.0, 1.0)
	k.platform(182, 5.0, 3.0, k.CRATE, true)
	k.platform(189.5, 6.0, 3.0, k.CRATE, true)
	k.platform(197, 5.0, 3.0, k.CRATE, true)
	k.beans_arc(177, 201, 6.5, 3.5, 9)
	# Golden Bean 3: a high platform in the wind (optional).
	k.platform(194, 9.8, 3.2, k.CRATE, false, 0.3)
	k.golden(194, 11.2)
	k.ground(201, 208, 5.0, steel)
	k.toilet(204, 5.0)
	# Now the wind blows the other way, a little. Keep holding right!
	k.hint(205, 5.0, "WIND IN YOUR FACE! HOLD RIGHT!", 3.5)
	k.fan(209, 225, 2.0, 11.0, -1.0, {"push_accel": 31.0})
	k.platform(211.5, 5.0, 3.0, k.CRATE, true)
	k.platform(216.5, 5.0, 3.0, k.CRATE, true)
	k.platform(221.5, 5.0, 3.0, k.CRATE, true)
	k.beans_arc(210, 223, 6.5, 2.0, 6)

	# --- E. THE PIPE TOWER: a warp pipe, a secret room, and steam all the way up. -----------
	k.ground(226, 276, 5.0, steel)
	k.toilet(230, 5.0)
	k.hint(233, 5.0, "A PIPE UP THERE? STEAM UP!", 3.5)
	k.vent(238, 5.0, {"phase": 0.5})
	# The secret ledge with the warp pipe on it (optional). The pipe goes to the bean room.
	k.platform(246, 10.0, 9.0, k.CRATE, false)
	k.block(250.6, 253, 10.0, 13.5, k.CRATE, false)
	k.warp_pipe(249.4, 10.0, 1.0, Vector3(240, 41.5, 0))
	# The secret room: far above, a floor, Golden Bean 2, and a pipe home.
	k.ground(234, 264, 40.0, steel, false)
	k.hint(240, 40.0, "SECRET BEAN ROOM!", 3.0)
	k.beans_arc(242, 254, 41.3, 2.5, 8)
	k.golden(248, 41.9)
	k.block(260.6, 263, 40.0, 43.5, k.CRATE, false)
	k.warp_pipe(259.4, 40.0, 1.0, Vector3(262, 6.2, 0))
	# The real way up: vent after vent, to the Bean Can.
	k.hint(262, 5.0, "STEAM TOWER! GO UP!", 3.0)
	k.vent(270, 5.0)
	k.platform(280, 11.0, 8.0, k.STEEL, true)
	k.toilet(277.5, 11.0)
	k.vent(283.5, 11.0, {"phase": 0.4})
	k.beans_arc(270, 280, 6.0, 7.0, 7)
	k.platform(292, 17.0, 8.0, k.STEEL, true)
	k.vent(294.5, 17.0, {"phase": 0.2})
	k.beans_arc(284, 293, 12.0, 7.0, 7)
	k.ground(300, 330, 23.0, steel)
	k.beans_arc(295, 304, 18.0, 7.0, 7)
	k.toilet(304, 23.0)
	k.hint(308, 23.0, "YOU MADE IT UP!", 2.5)
	k.beans_line(308, 322, 24.4, 2.5)
	k.bean_can(320, 23.0)
	return k.finish("res://scenes/stage_2_2.tscn")
