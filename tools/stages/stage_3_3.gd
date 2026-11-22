extends RefCounted
## Stage 3-3: THE STINK STORM (a flying stage, about 1 minute). He starts already flying.
## Hold jump to rise, let go to sink. A swirling gas storm with rainbow clouds and the planet's rings
## behind. Floating alien jellyfish bob about (bump them from above, or steer round), and lightning
## bolts flicker (a thin flicker is the warning) before they strike.
## Two fast BOOST sections: the screen speeds up to twice as fast, with wide lines of beans and big
## rings and nothing nasty, so you can just enjoy zooming.
## Sky toilets keep him flying after a mishap.

const KIT := "res://tools/kit_whiff.gd"

## The sky he can fly in (lowest and highest height).
const LANE: Vector2 = Vector2(3.0, 22.0)
## The two SUPER BOOST sections, from x to x. Flying is 3.5 times as fast inside them.
const BOOST_1: Vector2 = Vector2(190.0, 360.0)
const BOOST_2: Vector2 = Vector2(660.0, 840.0)
const LANDING_X: float = 1060.0


func build(k) -> Array[String]:
	k.begin("3-3", "HOLD JUMP TO RISE! WHAT A STORM!", Vector3(0, 12, 0), Color(0.25, 0.15, 0.4))
	k.root.set("start_flight", LANE)
	k.gas_sea(-20, LANDING_X + 100.0, -4.0)
	k.storm_clouds(-20, LANDING_X + 60.0, -2.0, 34.0)
	k.planet_rings(300, 20)
	k.planet_rings(850, 25, -160.0)
	_warm_up(k)
	_boost(k, BOOST_1, 0)
	_lightning(k)
	_boost(k, BOOST_2, 1)
	_rings_gauntlet(k)
	_landing(k)
	return k.finish("res://scenes/stage_3_3.tscn")


## Wavy bean lines, big rings and the first slow jellyfish.
func _warm_up(k) -> void:
	k.say_zone(10, 12, 12, 20, "WHEEE! FLY THROUGH THE STORM!", 3.0)
	for x in range(10, 181, 3):
		k.bean(x, 12.0 + 5.0 * sin(x * 0.09))
	for i in 4:
		k.ring(45.0 + i * 30.0, 12.0 + 5.0 * sin((45.0 + i * 30.0) * 0.09), 3.2)
	k.jelly(95, 18.0, {"bob_height": 2.0})
	k.jelly(135, 7.0, {"bob_height": 2.0})
	k.jelly(165, 17.0, {"bob_height": 2.0})
	k.sky_toilet(110, LANE)
	k.sky_toilet(172, LANE)


## A boost: much faster, nothing nasty. Wide lines of beans in three heights and big rings.
func _boost(k, span: Vector2, n: int) -> void:
	k.super_boost(span.x, span.y, LANE.x, LANE.y)
	var x: float = span.x + 10.0
	var i: int = 0
	while x < span.y - 6.0:
		var wave: float = sin(float(i) * 0.7 + float(n))
		# Three lines of beans, one above the other, all easy to scoop up.
		for line in 3:
			var y: float = 7.0 + 5.5 * float(line) + 3.0 * wave
			k.bean(x, y)
			k.bean(x + 2.5, y)
		if i % 3 == 0:
			k.ring(x + 6.0, 12.0 + 4.0 * wave, 3.8)
		x += 9.0
		i += 1
	k.sky_toilet(span.y + 8.0, LANE)


## Lightning: gaps move up and down, with jellyfish in between. Bolts flicker before they strike.
func _lightning(k) -> void:
	k.say_zone(372, 12, 10, 20, "LIGHTNING! WATCH THE FLICKER!", 3.0)
	# Each bolt covers part of the sky; the gap moves. (x, bottom, top of the bolt)
	var bolts: Array = [[400.0, 3.0, 14.0], [440.0, 11.0, 22.0], [480.0, 3.0, 12.0], [520.0, 12.0, 22.0], [560.0, 3.0, 13.0], [600.0, 11.0, 22.0]]
	for i in bolts.size():
		var b: Array = bolts[i]
		k.lightning(b[0], b[1], b[2], float(i) * 0.31)
		# Beans in the safe gap.
		var gap_y: float = 17.5 if b[1] < 8.0 else 7.0
		k.bean(b[0] - 5.0, gap_y)
		k.bean(b[0], gap_y)
		k.bean(b[0] + 5.0, gap_y)
	k.jelly(420, 14.0, {"bob_height": 2.5})
	k.jelly(500, 9.0, {"bob_height": 2.5})
	k.jelly(580, 16.0, {"bob_height": 2.5})
	k.sky_toilet(380, LANE)
	k.sky_toilet(460, LANE)
	k.sky_toilet(540, LANE)
	k.sky_toilet(625, LANE)
	# Golden Bean 1: hiding in a rainbow fog between the bolts.
	k.fog(540, 17.0, 12.0, 7.0)
	k.golden(540, 17.0)
	# Golden Bean 2: hiding down low in a fog, just before the second boost.
	k.fog(640, 6.5, 12.0, 6.0)
	k.golden(640, 6.5)


## The planet's rings: jellyfish in pairs, quick lightning and rings to fly through.
func _rings_gauntlet(k) -> void:
	k.say_zone(852, 12, 10, 20, "THE PLANET'S RINGS! ALMOST THERE!", 3.0)
	for i in 5:
		var gx: float = 870.0 + float(i) * 34.0
		var wave: float = sin(float(i) * 1.1)
		k.jelly(gx, 8.0 + 2.0 * wave, {"bob_height": 2.0, "bob_speed": 1.8})
		k.jelly(gx + 6.0, 17.0 - 2.0 * wave, {"bob_height": 2.0, "bob_speed": 1.8})
		k.ring(gx + 17.0, 12.5 + 4.0 * wave, 3.2)
		k.bean(gx + 11.0, 12.5 + 4.0 * wave)
		k.bean(gx + 14.0, 12.5 + 4.0 * wave)
		k.bean(gx + 20.0, 12.5 + 4.0 * wave)
		k.bean(gx + 23.0, 12.5 + 4.0 * wave)
	k.lightning(940, 3.0, 12.0, 0.2)
	k.lightning(1000, 12.0, 22.0, 0.6)
	k.bean(940, 17.0)
	k.bean(1000, 7.0)
	k.sky_toilet(865, LANE)
	k.sky_toilet(955, LANE)
	# Golden Bean 3: high up, in a fog among the rings.
	k.fog(915, 20.0, 12.0, 4.0)
	k.golden(915, 20.0)


func _landing(k) -> void:
	# The flight ends at the curtain. The ground starts well before it, so he can't drop into a hole.
	k.place("res://scenes/landing_zone.tscn", "LandingZone", Vector3(LANDING_X, 0, 0), "Goal")
	k.ground(LANDING_X - 50.0, LANDING_X + 130.0, 0)
	k.toilet(LANDING_X + 25.0, 0)
	k.mega_can(LANDING_X + 38.0, 1.3)
	k.bean_can(LANDING_X + 70.0, 0)
