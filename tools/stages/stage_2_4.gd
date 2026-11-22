extends RefCounted
## Stage 2-4: BOSS, COLONEL CORK (about 3 minutes).
## A toilet checkpoint outside the door. The door slams shut behind you. The Colonel charges
## across the room: THUNDER-JUMP OVER HIM! He crashes into the wall and sees stars: stomp his head.
## Six stomps in three phases (see colonel_cork.gd): bots and bouncing corks, then cork rain and
## a double charge. He pops like a champagne cork, and the gate to the Bean Can opens.

const KIT := "res://tools/kit_chimney.gd"


func build(k) -> Array[String]:
	k.begin("2-4", "WHO PLUGGED THE FACTORY?", Vector3(-8, 1.2, 0), Color(0.45, 0.4, 0.38))
	k.factory_hall(-14, 76)

	# --- The corridor outside, with a toilet checkpoint. -------------------------------------
	k.ground(-12, 6, 0.0, Color(0.5, 0.53, 0.58))
	k.golden(-11, 1.5)
	k.toilet(-2, 0)
	k.hint(0, 0, "BOSS AHEAD! THUNDER-JUMP OVER HIM!", 4.0)
	k.beans_line(-6, 4, 1.3)

	# --- The arena: 6 m to 45 m. The door at the left shuts behind you. -----------------------
	k.ground(6, 45, 0.0, Color(0.5, 0.53, 0.58))
	k.hint(12, 0, "WHEN HE SEES STARS, JUMP ON HIS HEAD!", 3.5)
	# Two ledges that need a Thunder jump: a safe spot to watch him charge past below.
	k.platform(20, 3.4, 3.5, Color(0.7, 0.3, 0.22))
	k.platform(32, 3.4, 3.5, Color(0.7, 0.3, 0.22))
	k.golden(20, 4.8)
	k.golden(32, 4.8)
	k.beans_arc(12, 28, 1.2, 2.5, 8)
	k.beans_line(13, 17, 1.4, 2.0)
	k.heart(26, 1.4)

	# --- Colonel Cork himself, on the right. ----------------------------------------------------
	var boss: Area3D = k.colonel_cork(40.5, 0.0)

	# The trigger (starts the fight), the door (shuts behind you), the gate (opens when he's beaten).
	var trigger: Area3D = k.zone("ArenaTrigger", 11.5, 4.0, Vector3(1.5, 10.0, 4.0))
	var door: StaticBody3D = k.block(6, 7.2, 0, 14, Color(0.3, 0.32, 0.36))
	door.name = "Door"
	var gate: StaticBody3D = k.block(45, 46.5, 0, 14, Color(0.55, 0.35, 0.2))
	gate.name = "Gate"
	boss.set("arena_left_x", 9.0)
	boss.set("arena_right_x", 43.5)
	boss.set("trigger", trigger)
	boss.set("door", door)
	boss.set("gate", gate)
	boss.set("bot_scene", load("res://scenes/cork_bot.tscn"))

	# --- Beyond the gate: the Bean Can. ------------------------------------------------------------
	k.ground(46.5, 76, 0.0, Color(0.5, 0.53, 0.58))
	k.heart(52, 1.4)
	k.bean_can(64, 0)
	return k.finish("res://scenes/stage_2_4.tscn")
