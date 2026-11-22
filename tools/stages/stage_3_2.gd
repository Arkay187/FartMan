extends RefCounted
## Stage 3-2: THE FIZZY FORTRESS (about 4 minutes). The hardest running stage: everything from the
## whole game, remixed. Big Bad Burp's fortress is made of the Bean Factory's bits and the planet's gas.
##  A. THE GATE: belts (forwards and backwards) and Cork Bots.
##  B. STAMPS AND STINK: stamping presses with Whifflers between, then a bouncy cloud.
##  C. SPRINGS AND A CANNON: spring up, then a barrel cannon shoots you over a pit.
##  D. THE GAS PIT: a tail-wind fan, crumbling biscuits and bubbles over a pit (a cloud net catches you).
##  E. THE SWITCH YARD: red and blue blocks, Fizz Bats and Cork Bots.
##  F. CHILLI DASH, then the HOT SAUCE PARTY: enemies from all three worlds to bowl over.
##  G. THE TOWER: steam vent, geysers and rocks up to the Bean Can.
## Secrets: 3 Golden Beans (on top of the stamps, in a fog over the gas pit, up a geyser at the
## tower) and two secret bean rooms (a fogged pipe up a geyser, and a pipe up a spring).

const KIT := "res://tools/kit_whiff.gd"

const ROOM_A_X: float = 300.0
const ROOM_B_X: float = 380.0
const ROOM_Y: float = 60.0


func build(k) -> Array[String]:
	k.begin("3-2", "THE FIZZY FORTRESS!", Vector3(-4, 1.2, 0), Color(0.36, 0.18, 0.45))
	k.gas_sea(-20, 680)
	k.planet_rings(330, 50)
	k.factory_scenery(-12, 660)
	k.alien_scenery(-12, 660)
	_gate(k)
	_stamps(k)
	_springs(k)
	_gas_pit(k)
	_switch_yard(k)
	_party(k)
	_tower(k)
	return k.finish("res://scenes/stage_3_2.tscn")


# ------------------------------------------------------------------ A. the gate

func _gate(k) -> void:
	k.ground(-12, 22, 0)
	k.hint(-6, 0, "THE FIZZY FORTRESS! EVERYTHING IS HERE!", 4.0)
	k.beans_line(0, 20, 1.3, 2.5)
	k.toilet(8, 0)
	k.belt(22, 44, 0, 3.0)
	k.enemy("cork_bot", 33, 0, {"patrol_distance": 4.0})
	k.beans_line(24, 42, 1.4, 2.0)
	k.ground(44, 52, 0)
	k.hint(45, 0, "BACKWARDS BELT! KEEP RUNNING!", 3.0)
	k.belt(52, 76, 0, -3.0)
	k.enemy("cork_bot", 63, 0, {"patrol_distance": 5.0})
	k.enemy("fizz_bat", 66, 4.5, {"patrol_distance": 3.0})
	k.beans_line(54, 74, 1.4, 2.5)
	k.ground(76, 90, 0)
	k.toilet(79, 0)


# ------------------------------------------------------------------ B. stamps and stink

func _stamps(k) -> void:
	k.ground(90, 160, 0)
	k.toilet(94, 0)
	k.hint(96, 0, "STAMPS! THEN STINK! TIME IT!", 3.5)
	k.stamp(103, 0, {"phase": 0.0})
	k.stamp(113, 0, {"phase": 0.5})
	k.enemy("whiffler", 122, 0, {"phase": 0.2})
	k.stamp(132, 0, {"phase": 0.25})
	# Golden Bean 1: ride the stamp up (it is safe on top) to the high rock.
	k.hint(127, 0, "STAMPS ARE SAFE ON TOP!", 3.0)
	k.rock(132, 8.0, 3.2, false)
	k.golden(132, 9.4)
	k.enemy("whiffler", 143, 0, {"phase": 0.6})
	k.beans_line(98, 158, 1.3, 3.0)
	k.toilet(150, 0)
	k.mega_can(153, 1.6)
	k.cloud(164, 176, 0)
	k.bubble(170, 1.0, {"rise_height": 7.0, "radius": 1.2})
	k.beans_arc(163, 177, 4.0, 3.0, 6)
	k.ground(180, 200, 0)
	k.toilet(184, 0)


# ------------------------------------------------------------------ C. springs and a cannon

func _springs(k) -> void:
	k.hint(187, 0, "SPRING UP! THEN FIND THE CANNON!", 3.5)
	k.spring(195, 0)
	k.rock(207, 6.0, 6.0, true)
	k.beans_arc(196, 207, 7.0, 4.0, 6)
	# The barrel cannon on the rock shoots you across the gap (aim 60 degrees, about 17 m).
	k.hint(205, 6.0, "JUMP IN THE BARREL! PRESS JUMP TO FIRE!", 4.0)
	k.assist(210, 219)
	k.barrel(206, 7.2, 60.0, 0.0, 22.0)
	k.rock(223, 6.0, 8.0, true)
	k.beans_arc(209, 221, 9.0, 4.0, 7)
	k.ground(230, 262, 0)
	k.toilet(234, 0)
	k.enemy("hiccup", 244, 0)
	k.enemy("gnome", 254, 0)


# ------------------------------------------------------------------ D. the gas pit

func _gas_pit(k) -> void:
	k.hint(250, 0, "GAS PIT! THE WIND HELPS. BISCUITS CRUMBLE!", 4.0)
	k.fan(263, 297, 1.0, 13.0, 1.0)
	k.cloud(263, 297, -5, {"bounce_power": 17.5, "high_bounce_power": 20.0}, false, k.CLOUD_TEAL)
	for bx in [268.0, 274.0, 280.0, 286.0, 292.0]:
		k.biscuit(bx, 0.0, 3.0, {}, true)
	k.beans_arc(266, 294, 2.0, 4.0, 10)
	k.bubble(277, 1.0, {"rise_height": 10.0, "radius": 1.3})
	k.bubble(289, 1.0, {"rise_height": 10.0, "radius": 1.3})
	# Golden Bean 2: a rock high in a fog, over the middle of the pit. Bounce up a bubble.
	k.rock(283, 14.0, 4.0, false)
	k.fog(283, 15.5, 7.0, 5.0)
	k.golden(283, 15.4)
	k.ground(298, 332, 0)
	k.toilet(301, 0)
	# The first bean room: a pipe up a geyser, hidden in a fog.
	k.hint(302, 0, "A GEYSER AND A FOG... SUSPICIOUS!", 3.5)
	k.geyser(299.5, 0, {"phase": 0.3})
	k.rock(309, 11.0, 5.0, false)
	k.fog(310, 13.5, 7.0, 6.0)
	var entry_a: Vector3 = k.bean_room(ROOM_A_X, ROOM_Y, Vector3(307.5, 12.3, 0))
	k.bean_pipe(310.2, 11.0, 1.0, entry_a)
	k.enemy("whiffler", 322, 0, {"phase": 0.4})
	k.beans_line(316, 330, 1.3, 2.5)


# ------------------------------------------------------------------ E. the switch yard

func _switch_yard(k) -> void:
	k.hint(333, 0, "RED BLOCKS GO! BLUE BLOCKS COME!", 3.5)
	k.switch_block(335, 338, 0.0, true)
	k.switch_block(341, 344, 0.0, true)
	k.enemy("fizz_bat", 339, 4.0, {"patrol_distance": 3.0})
	k.beans_arc(334, 345, 1.5, 1.8, 6)
	k.ground(347, 357, 0)
	k.toilet(349, 0)
	k.enemy("cork_bot", 351, 0, {"patrol_distance": 2.0})
	k.hint(353, 0, "STEP ON THE BIG BUTTON!", 3.0)
	k.switch_button(355.5, 0.0)
	k.switch_block(360, 363, 0.0, false)
	k.switch_block(366, 369, 0.0, false)
	k.beans_arc(359, 370, 1.5, 1.8, 6)
	k.ground(372, 394, 0)
	# The second bean room: a spring to a rock with a pipe.
	k.hint(373, 0, "HOLD JUMP FOR A MEGA BOING!", 3.0)
	k.spring(377, 0)
	k.rock(384, 7.0, 8.0, false)
	var entry_b: Vector3 = k.bean_room(ROOM_B_X, ROOM_Y, Vector3(381.5, 8.3, 0))
	k.bean_pipe(387.0, 7.0, 1.0, entry_b)
	k.enemy("burpling", 390, 0, {"patrol_distance": 2.0})


# ------------------------------------------------------------------ F. chilli dash and hot sauce party

func _party(k) -> void:
	k.ground(394, 580, 0)
	k.toilet(398, 0)
	k.hint(401, 0, "CHILLI! RUN STRAIGHT THROUGH EVERYTHING!", 3.5)
	k.chilli(406, 1.4)
	# The chilli crowd: Burplings, Hiccups, Whifflers and Cork Bots in one long row.
	var x: float = 416.0
	for i in 16:
		match i % 4:
			0:
				k.enemy("burpling", x, 0, {"patrol_distance": 1.5})
			1:
				k.enemy("hiccup", x, 0)
			2:
				k.enemy("cork_bot", x, 0, {"patrol_distance": 1.5})
			3:
				k.enemy("whiffler", x, 0, {"phase": float(i) * 0.13})
		x += 3.0
	k.beans_line(414, 466, 1.4, 2.5)
	k.toilet(468, 0)
	k.mega_can(472, 1.6)
	# The hot sauce party: fire burp them all.
	k.hint(480, 0, "HOT SAUCE! SHOOT FIREBALLS WITH C OR B!", 4.0)
	k.hot_sauce(486, 1.4)
	var px: float = 498.0
	for i in 22:
		match i % 6:
			0:
				k.enemy("burpling", px, 0, {"patrol_distance": 1.5})
			1:
				k.enemy("hiccup", px, 0)
			2:
				k.enemy("cork_bot", px, 0, {"patrol_distance": 2.0})
			3:
				k.enemy("whiffler", px, 0, {"phase": float(i) * 0.11})
			4:
				k.enemy("gnome", px, 0)
			5:
				k.enemy("fizz_bat", px, 3.0, {"patrol_distance": 2.0})
		px += 3.5
	k.beans_line(496, 572, 1.4, 3.0)
	k.toilet(576, 0)


# ------------------------------------------------------------------ G. the tower

func _tower(k) -> void:
	k.ground(580, 600, 0)
	k.toilet(583, 0)
	k.hint(585, 0, "THE LAST CLIMB! VENT, GEYSERS, GO GO GO!", 3.5)
	# Golden Bean 3: a geyser to a rock in a fog, off to the left.
	k.geyser(588, 0, {"phase": 0.5})
	k.rock(593, 12.5, 4.0, false)
	k.fog(593, 14.0, 8.0, 5.0)
	k.golden(593, 13.9)
	k.vent(598, 0)
	k.bubble(603, 1.0, {"rise_height": 7.0, "radius": 1.2})
	k.rock(608, 7.5, 6.0, true)
	k.geyser(609, 7.5, {"phase": 0.2})
	k.beans_arc(599, 607, 8.0, 4.0, 6)
	k.rock(619, 16.5, 6.0, true)
	k.geyser(620, 16.5, {"phase": 0.7})
	k.enemy("fizz_bat", 614, 14.0, {"patrol_distance": 3.0})
	k.beans_arc(610, 618, 17.0, 4.0, 6)
	k.rock(630, 25.5, 6.0, true)
	k.toilet(631, 25.5)
	k.beans_arc(621, 629, 26.0, 4.0, 6)
	k.bubble(613.5, 10.0, {"rise_height": 6.0, "radius": 1.3})
	k.cloud(636, 648, 25.5)
	k.ground(652, 690, 25.5)
	k.hint(654, 25.5, "ALMOST THERE!", 2.5)
	k.beans_line(656, 684, 26.9, 2.5)
	k.mega_can(660, 26.8)
	k.bean_can(676, 25.5)
