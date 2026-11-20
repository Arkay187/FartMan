extends RefCounted
## Test level T-2: THE BEAN SOUP TOWER (about 55 m tall, 2 to 3 minutes).
## Hot bean soup rises from below. It stops for a rest when you flush a toilet.
## Catch you and you lose a heart and pop back to the last toilet. Easy to outrun.
## Ledges you jump up through, sideways bits (a moving platform, a sprinkler, prickles),
## a wall-jump shortcut, and a lift with a crow. Works in any gas mode,
## best with F1: FILL ON LAND. Not saved; goes back to the TEST LEVELS list when cleared.

const KIT := "res://tools/kit_vertical.gd"


func build(k) -> Array[String]:
	k.begin_test("T-2", "THE SOUP IS RISING!", Vector3(-8, 1.2, 0), Color(0.7, 0.6, 0.5))
	k.tower_scenery(-14, 14, -10.0, 62.0)
	k.soup(-8.0, {"rise_speed": 0.8, "start_delay": 8.0, "pause_after_toilet": 10.0, "max_y": 50.0})

	# --- A. The ground floor. ----------------------------------------------------------
	k.base(-14, 14, 0.0)
	k.hint(-5, 0, "BEAN SOUP IS RISING! CLIMB!", 4.0)
	k.hint(0, 0, "BEST WITH F1: FILL ON LAND!", 5.0)
	k.oneway(-3, 3.6, 5.0, k.WOOD)
	k.oneway(4, 7.2, 5.0, k.WOOD)
	k.oneway(-3, 10.8, 5.0, k.WOOD)
	k.beans_arc(-3, 4, 4.8, 1.5, 4)

	# --- B. First floor: cross the gap on the moving platform. A sprinkler and a Burpling. --
	k.shelf(-8.5, 14.4, 11, k.WOOD)
	k.toilet(-10, 14.4)
	k.hint(-5, 14.4, "RIDE THE PLATFORM ACROSS!", 3.0)
	k.moving(-1, 14.4, 3.5, Vector3(6, 0, 0), 2.5, 1.0, 0.0)
	k.oneway(9.5, 14.4, 9.0, k.WOOD, true, "carried")
	k.sprinkler(8, 14.4, 0.0, 3.5)
	k.enemy("burpling", 11.5, 14.4, {"patrol_distance": 1.0})
	k.beans_line(-1, 5, 16.0, 2.0)
	# A shiny bean on a little ledge straight above the left shelf (a Thunder, then fart again).
	k.oneway(-12.5, 20.0, 3.0, k.WOOD, false)
	k.golden(-12.5, 21.4)

	# --- C. Up to the second floor. ---------------------------------------------------------
	k.oneway(10, 18.0, 4.0, k.WOOD)
	k.oneway(3, 21.6, 4.0, k.WOOD)
	k.shelf(0, 25.2, 28, k.WOOD)
	k.toilet(-10, 25.2)

	# --- D. Second floor: the wall-jump shortcut on the right (a shiny bean inside), or stairs on the left.
	k.hint(2, 25.2, "WALL JUMP SHORTCUT! PUSH AT A WALL, THEN JUMP!", 4.0)
	k.block(5.5, 6.5, 27.8, 38.1, k.BRICK)
	k.block(10.0, 11.0, 27.8, 38.1, k.BRICK)
	k.golden(8.25, 33.5)
	k.oneway(-11, 28.8, 4.0, k.WOOD)
	k.oneway(-4, 32.4, 4.0, k.WOOD)
	k.oneway(-11, 36.0, 4.0, k.WOOD)

	# --- E. Third floor: prickles and a Burpling to hop, then a lift or stairs. -----------------
	k.shelf(0, 38.6, 28, k.WOOD)
	k.toilet(-10, 38.6)
	k.prickle(-2, 38.6)
	k.prickle(1.5, 38.6)
	k.enemy("burpling", 5, 38.6, {"patrol_distance": 2.0})
	k.hint(7, 38.6, "LIFT GOING UP! DUCK THE CROW!", 3.0)
	k.moving(12.5, 38.6, 3.0, Vector3(0, 11.4, 0), 2.2, 1.5, 0.0)
	k.enemy("crow", 12.5, 44.0, {"patrol_distance": 1.0, "walk_speed": 1.5, "bob_height": 0.5})
	k.golden(12.5, 46.5)
	k.oneway(-10, 42.2, 4.0, k.WOOD)
	k.oneway(-3, 45.8, 4.0, k.WOOD)
	k.oneway(4, 49.4, 4.0, k.WOOD)

	# --- F. The top: the Bean Can. ---------------------------------------------------------------
	k.shelf(2, 53.0, 20, k.WOOD)
	k.bean_can(8.5, 53.0)
	return k.finish("res://scenes/stage_t_2.tscn")
