extends RefCounted
## Test level T-1: THE BEANSTALK (about 60 m tall, 2 to 3 minutes).
## Made for FREE GAS (press F1 until it says FILL ON LAND, or ALWAYS FULL):
## leaf ledges you can jump up through, a Thunder then a second Thunder in the air for the
## bigger steps, a spring, a wall-jump shaft, and two barrel cannons that fire you to the Bean Can.
## Not saved, and it goes back to the TEST LEVELS list when cleared.

const KIT := "res://tools/kit_vertical.gd"


func build(k) -> Array[String]:
	k.begin_test("T-1", "UP THE BEANSTALK!", Vector3(-4, 1.2, 0), Color(0.45, 0.75, 0.95))
	k.beanstalk_scenery(66.0, 0.0)

	# --- A. The ground, and the first leaves. ------------------------------------------
	k.base(-14, 14, 0.0)
	k.hint(-3, 0, "PRESS F1: FILL ON LAND!", 6.0)
	k.hint(3, 0, "HOP UP THE LEAVES! FART AGAIN IN THE AIR!", 4.0)
	k.oneway(4, 3.6, 4.5)
	k.oneway(-3, 7.2, 4.5)
	k.oneway(5, 10.8, 4.5)
	k.beans_arc(-1, 4, 4.8, 1.5, 4)
	k.beans_arc(-1, 5, 8.4, 1.5, 4)

	# --- B. First rest: a wide shelf with a toilet, and a side ledge with a shiny bean. ---
	k.shelf(0, 14.4, 14)
	k.toilet(-4, 14.4)
	k.oneway(-11.5, 17.0, 3.0, k.LEAF, false)
	k.golden(-11.5, 18.4)

	# --- C. Zig-zag up the leaves. The right ledge hides a shiny bean up high. -----------
	k.hint(3, 14.4, "HOLD FART, LET GO. THEN FART AGAIN IN THE AIR!", 4.0)
	k.oneway(8, 18.0, 4.0)
	k.oneway(1, 21.6, 4.0)
	k.oneway(14.5, 23.0, 3.0, k.LEAF, false)
	k.golden(14.5, 24.4)
	k.oneway(-6, 25.2, 4.0)

	# --- D. The spring. Press jump as you land for a MEGA boing. -------------------------
	k.hint(-6, 25.2, "BOING! PRESS JUMP AS YOU LAND FOR A MEGA BOING!", 4.0)
	k.spring(-6, 25.2)
	k.oneway(-6, 31.4, 4.0, k.LEAF, true, "spring")
	k.beans_line(-6, -6, 37.0, 2.0)
	k.beans_line(-6, -6, 39.0, 2.0)

	# --- E. Second rest, and the wall-jump shaft with the last shiny bean. -----------------
	k.shelf(3.5, 35.2, 24)
	k.toilet(-2, 35.2)
	k.hint(7, 35.2, "WALL JUMP! PUSH AT A WALL, THEN PRESS JUMP!", 4.0)
	k.block(9.5, 10.5, 38.5, 48.0, k.BRICK)
	k.block(14.0, 15.0, 38.5, 48.0, k.BRICK)
	k.golden(12.25, 49.5)

	# --- F. More leaves up to the third rest. -------------------------------------------
	k.oneway(-6, 38.9, 4.0)
	k.oneway(0, 42.5, 4.0)
	k.oneway(-6, 46.0, 4.0)
	k.shelf(0, 49.5, 12)
	k.toilet(2, 49.5)

	# --- G. The barrel cannons. Jump in, press jump to fire. The second one swings. ----------
	k.hint(-1, 49.5, "BARRELS! PRESS JUMP TO FIRE!", 4.0)
	k.barrel(-4, 54.0, 90.0, 0.0, 22.0)
	k.barrel(-4, 60.0, 30.0, 60.0, 20.0)
	k.check_barrel_to_barrel(0, 1)
	k.oneway(12.5, 57.5, 8.0, k.LEAF, false)
	k.check_barrel_to_ledge(1, 8.5, 16.5, 57.5)
	k.bean_can(14.5, 57.5)
	return k.finish("res://scenes/stage_t_1.tscn")
