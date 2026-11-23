extends RefCounted
## Stage 3-4: THE FINAL BOSS, BIG BAD BURP. A toilet outside the door. Two parts.
## PART 1: he says hello down low (so he is in the shot), flies up, and burps giant bubbles (BUUURP! and they swell up first). Bounce up the
## bubbles like stairs and stomp his head. Green stinky bubbles hurt. He gets faster each round and
## sends helpers (floating jellyfish, then Whifflers). Six stomps. Then he flies off in a huff and a Rocket
## Burrito falls from the sky.
## PART 2: grab the burrito and chase him round the planet's rings. He burps rings and walls of
## stinky bubbles, then gets dizzy: fly into him. Four hits. Then the ending.
## Sky toilets all along the runway keep you flying if you get hurt.

const KIT := "res://tools/kit_whiff.gd"

const LANE: Vector2 = Vector2(3.0, 20.0)
const ARENA_LEFT: float = 6.0
const ARENA_RIGHT: float = 62.0
const RUNWAY_END: float = 1700.0


func build(k) -> Array[String]:
	k.begin("3-4", "WHO PUT THE CORK IN THE FACTORY?", Vector3(-8, 1.2, 0), Color(0.2, 0.1, 0.35))
	k.gas_sea(-20, RUNWAY_END + 100.0, -8.0)
	k.planet_rings(60, 40)
	k.planet_rings(900, 30, -170.0)
	k.alien_scenery(-12, 120)
	k.storm_clouds(60, RUNWAY_END, 0.0, 36.0)

	# --- The corridor outside, with a toilet checkpoint. ---------------------------------------
	k.ground(-12, 6, 0.0)
	k.golden(-11, 1.5)
	k.toilet(-2, 0)
	k.hint(0, 0, "BOSS AHEAD! BOUNCE UP THE BUBBLES!", 4.0)
	k.beans_line(-6, 4, 1.3)

	# --- The arena: 6 m to 62 m. The door on the left shuts behind you. -----------------------
	k.ground(6, 62, 0.0)
	k.hint(12, 0, "LAND ON BUBBLES! STOMP HIS HEAD!", 3.5)
	k.heart(14, 1.4)
	# Golden Bean 2: a high ledge at the side. Bounce up a bubble (or a hover) to get it.
	k.rock(58, 9.0, 4.0, false)
	k.golden(58, 10.4)
	k.beans_arc(12, 56, 1.3, 2.5, 14)

	# --- Big Bad Burp himself. -----------------------------------------------------------------
	var boss: Area3D = k.big_bad_burp(ARENA_LEFT + 30.0, 4.5)
	var trigger: Area3D = k.zone("ArenaTrigger", 11.5, 4.0, Vector3(1.5, 10.0, 4.0))
	var door: StaticBody3D = k.block(6, 7.2, 0, 30, Color(0.3, 0.2, 0.4))
	door.name = "Door"
	var gate: StaticBody3D = k.block(62, 63.5, 0, 30, Color(0.55, 0.35, 0.5))
	gate.name = "Gate"
	var burrito: Node3D = k.place("res://scenes/rocket_burrito.tscn", "RocketBurrito", Vector3(ARENA_LEFT + 30.0, 1.3, 0), "PowerUps")
	burrito.set("lowest_y", LANE.x)
	burrito.set("highest_y", LANE.y)
	boss.set("arena_left_x", ARENA_LEFT)
	boss.set("arena_right_x", ARENA_RIGHT)
	boss.set("lane", LANE)
	boss.set("wrap_at_x", RUNWAY_END - 60.0)
	boss.set("trigger", trigger)
	boss.set("door", door)
	boss.set("gate", gate)
	boss.set("burrito", burrito)

	# --- Part 2: a long runway under the sky lane, with toilets, beans and rings. ---------------
	k.ground(62, RUNWAY_END + 40.0, 0.0)
	for i in 10:
		k.sky_toilet(140.0 + 160.0 * float(i), LANE)
	var x: float = 100.0
	var n: int = 0
	while x < RUNWAY_END - 40.0:
		for j in 8:
			k.bean(x + float(j) * 3.0, 11.5 + 6.0 * sin(float(n) * 0.9 + float(j) * 0.35))
		if n % 3 == 1:
			k.ring(x + 12.0, 11.5 + 6.0 * sin(float(n) * 0.9 + 1.0), 3.4)
		x += 50.0
		n += 1
	# Golden Bean 3: in a fog up in the sky.
	k.fog(520, 15.0, 12.0, 6.0)
	k.golden(520, 15.0)
	return k.finish("res://scenes/stage_3_4.tscn")
