extends RefCounted
## Stage 3-1: THE CLOUD TOPS (about 3 minutes). Planet Whiff, an alien gas planet. Normal gravity.
##  A. LANDING: squishy gas clouds. Drop onto one and it bounces you.
##  B. BURP BUBBLES: a pit full of bubbles. Land on one to bounce very high. A cloud net catches you.
##  C. GEYSER GORGE: gas geysers fill your tank and blast you up a tower of floating rocks.
##  D. WHIFFLER MEADOW: little aliens that puff stink clouds. Stomp them between puffs.
##  E. THE SKY CLIMB: geysers, bubbles and a hover gap up to the Bean Can.
## Secrets: 3 Golden Beans (a bubble ledge in a fog, a geyser ledge in a fog, a fogged pocket under
## the last bridge) and two secret bean rooms (a pipe in the fog up a bubble ledge, and a pipe in
## the fog up a geyser ledge) with loads of beans and things to bounce on.

const KIT := "res://tools/kit_whiff.gd"

## The bean rooms sit far above the stage, out of the way.
const ROOM_1_X: float = 250.0
const ROOM_2_X: float = 330.0
const ROOM_Y: float = 60.0


func build(k) -> Array[String]:
	k.begin("3-1", "WELCOME TO PLANET WHIFF!", Vector3(-4, 1.2, 0), Color(0.42, 0.28, 0.6))
	k.gas_sea(-20, 460)
	k.planet_rings(180, 40)
	k.alien_scenery(-12, 450)
	_landing(k)
	_bubbles(k)
	_geysers(k)
	_whifflers(k)
	_climb(k)
	return k.finish("res://scenes/stage_3_1.tscn")


# ------------------------------------------------------------------ A. the landing: squishy clouds

func _landing(k) -> void:
	k.ground(-12, 20, 0)
	k.hint(-6, 0, "CLOUDS ARE SQUISHY! DROP ONTO ONE TO BOUNCE!", 4.0)
	k.beans_line(-2, 18, 1.3, 2.5)
	k.toilet(10, 0)
	# A rock to jump up on, then drop onto the cloud and BOUNCE.
	k.rock(26, 3.0, 5.0, true)
	k.cloud(31, 49, 0)
	k.beans_arc(30, 48, 5.0, 3.0, 8)
	k.ground(49, 76, 0)
	k.toilet(54, 0)
	k.hint(56, 0, "BEANS UP HIGH? BOUNCE ON THE CLOUD!", 3.0)


# ------------------------------------------------------------------ B. Burp Bubbles

func _bubbles(k) -> void:
	k.hint(68, 0, "BURP BUBBLES! LAND ON TOP TO BOUNCE HIGH!", 4.0)
	# The pit: three bubbles carry you across. A squishy cloud at the bottom bounces you back up.
	k.assist(76, 96)
	k.cloud(77, 95, -5, {"bounce_power": 17.5, "high_bounce_power": 20.0}, false, k.CLOUD_TEAL)
	k.bubble(81, -1.0, {"rise_height": 8.0, "radius": 1.2})
	k.bubble(86, 2.0, {"rise_height": 7.0, "radius": 1.2})
	k.bubble(91, -1.0, {"rise_height": 8.0, "radius": 1.2})
	k.beans_arc(78, 94, 4.0, 5.0, 9)
	k.ground(96, 126, 0)
	k.toilet(99, 0)
	# Golden Bean 1 and the first bean room: a high ledge in a fog. Bounce up a bubble to reach it.
	k.hint(100, 0, "WHAT'S THAT FOG UP THERE?", 3.0)
	k.bubble(99.5, 0.5, {"rise_height": 9.0, "radius": 1.3})
	k.rock(107.5, 14.0, 9.0, false)
	k.golden(104.5, 15.4)
	k.fog(110.5, 16.5, 7.0, 6.0)
	var entry: Vector3 = k.bean_room(ROOM_1_X, ROOM_Y, Vector3(105.5, 15.3, 0))
	k.bean_pipe(110.0, 14.0, 1.0, entry)


# ------------------------------------------------------------------ C. Geyser Gorge

func _geysers(k) -> void:
	k.hint(112, 0, "GAS GEYSERS FILL YOUR TANK AND BLAST YOU UP!", 4.0)
	k.geyser(122, 0)
	k.beans_line(114, 124, 1.3, 2.5)
	# A tower of floating rocks, one geyser on each.
	k.rock(135, 9.5, 8.0, true)
	k.geyser(137, 9.5, {"phase": 0.3})
	k.enemy("fizz_bat", 129, 8.0, {"patrol_distance": 3.0})
	k.rock(147, 19.0, 7.0, true)
	k.geyser(148, 19.0, {"phase": 0.6})
	k.beans_arc(138, 146, 12.0, 4.0, 6)
	k.rock(158, 28.5, 8.0, true)
	k.toilet(160, 28.5)
	k.mega_can(156, 29.8)
	k.beans_arc(149, 157, 21.0, 4.0, 6)
	k.hint(158, 28.5, "WHEEE! NOW DROP DOWN THE CLOUDS!", 3.5)
	# Down the clouds like a giant staircase.
	k.cloud(166, 176, 20.0)
	k.cloud(181, 191, 10.0)
	k.beans_arc(163, 193, 18.0, 6.0, 10)
	k.ground(196, 232, 0)


# ------------------------------------------------------------------ D. Whiffler Meadow

func _whifflers(k) -> void:
	k.toilet(200, 0)
	k.hint(203, 0, "WHIFFLERS PUFF STINK! STOMP THEM BETWEEN PUFFS!", 4.5)
	k.enemy("whiffler", 213, 0)
	k.beans_arc(209, 217, 1.3, 4.0, 5)
	k.enemy("whiffler", 224, 0, {"phase": 0.5})
	k.cloud(236, 250, 0)
	k.enemy("whiffler", 243, 0, {"phase": 0.25})
	k.ground(254, 272, 0)
	k.toilet(257, 0)
	k.enemy("whiffler", 262, 0, {"phase": 0.1})
	k.enemy("whiffler", 268, 0, {"phase": 0.6})
	# Bobbing rocks.
	k.rock(278, 3.0, 4.0, true, 1.5)
	k.rock(285, 5.0, 4.0, true, 1.5)
	k.rock(292, 3.0, 4.0, true, 1.5)
	k.beans_arc(276, 294, 6.0, 4.0, 8)
	k.ground(298, 332, 0)
	k.toilet(300, 0)
	k.enemy("whiffler", 313, 0, {"phase": 0.0})
	k.enemy("whiffler", 320, 0, {"phase": 0.5})
	k.enemy("fizz_bat", 316, 5.0, {"patrol_distance": 4.0})
	# Golden Bean 2: up a geyser to a rock hiding in a fog.
	k.hint(298.5, 0, "A GEYSER? WHAT'S IN THE FOG?", 3.0)
	k.geyser(302, 0, {"phase": 0.2})
	k.rock(310, 12.0, 4.0, false)
	k.fog(310, 13.5, 9.0, 6.0)
	k.golden(310, 13.4)
	k.beans_arc(306, 314, 14.0, 3.0, 5)
	k.mega_can(326, 1.4)


# ------------------------------------------------------------------ E. the sky climb

func _climb(k) -> void:
	k.ground(332, 350, 0)
	k.toilet(336, 0)
	k.hint(338, 0, "UP AND UP! GEYSERS AND BUBBLES!", 3.5)
	k.geyser(344, 0)
	k.rock(357, 10.0, 6.0, true)
	k.toilet(358, 10.0)
	k.beans_arc(346, 356, 12.0, 4.0, 6)
	# Bubbles carry you up to the next rock.
	k.assist(360, 372)
	k.bubble(364, 8.0, {"rise_height": 8.0, "radius": 1.3})
	k.bubble(369, 11.0, {"rise_height": 8.0, "radius": 1.3})
	k.enemy("fizz_bat", 366, 17.0, {"patrol_distance": 3.0})
	k.rock(375, 20.0, 6.0, true)
	k.cloud(381, 393, 20.0)
	k.beans_arc(374, 394, 22.0, 3.0, 8)
	# The hover gap: double jump and hover across, or bounce on the bubble in the middle.
	k.hint(384, 20, "BIG GAP! HOVER ACROSS, OR USE THE BUBBLE!", 4.0)
	k.assist(393, 400)
	k.bubble(396, 16.0, {"rise_height": 7.0, "radius": 1.4})
	# Golden Bean 3: a fogged pocket under the gap. The geyser blasts you back up.
	k.ground(384, 400, 8.0, k.CLOUD_TEAL, false)
	k.geyser(395, 8.0, {"phase": 0.1})
	k.golden(389, 9.4)
	k.fog(392, 10.5, 14.0, 4.0)
	k.ground(400, 450, 20)
	k.geyser(402, 20, {"phase": 0.4})
	k.hint(405, 20, "SECRET UP THERE? USE THE GEYSER!", 3.5)
	# The second bean room: a pipe in a fog on a ledge high above.
	k.rock(410, 29.0, 7.0, false)
	k.fog(411.5, 31.0, 7.0, 6.0)
	var entry: Vector3 = k.bean_room(ROOM_2_X, ROOM_Y, Vector3(408.5, 30.3, 0))
	k.bean_pipe(412.0, 29.0, 1.0, entry)
	k.toilet(421, 20)
	k.enemy("whiffler", 428, 20, {"phase": 0.3})
	k.beans_line(414, 436, 21.4, 2.5)
	k.hint(430, 20, "ALMOST THERE!", 2.5)
	k.mega_can(433, 21.3)
	k.bean_can(442, 20)
