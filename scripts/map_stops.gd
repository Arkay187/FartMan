class_name MapStops
extends RefCounted
## The world map as plain lists. Edit this file to rename, move or add stops.
##
## Positions are in map pixels on a 1152 x 648 picture.
## kind is "run", "fly" or "boss". scene is empty until the stage exists.

## The three worlds. Each gets a coloured band of the map, left to right.
const WORLDS: Array[Dictionary] = [
	{"name": "GRANDMA'S GARDEN", "color": Color(0.45, 0.78, 0.4)},
	{"name": "THE BEAN FACTORY", "color": Color(0.62, 0.55, 0.5)},
	{"name": "PLANET WHIFF", "color": Color(0.55, 0.4, 0.7)},
]

## Width of one world band in map pixels.
const BAND_WIDTH: float = 384.0

## The 12 stops, in the order you play them.
const STOPS: Array[Dictionary] = [
	{"id": "1-1", "name": "THE VEG PATCH", "kind": "run", "world": 0, "pos": Vector2(70, 500), "scene": "res://scenes/stage_1_1.tscn"},
	{"id": "1-2", "name": "THE GREENHOUSE", "kind": "run", "world": 0, "pos": Vector2(170, 380), "scene": "res://scenes/stage_1_2.tscn"},
	{"id": "1-3", "name": "OVER THE ROOFTOPS", "kind": "fly", "world": 0, "pos": Vector2(290, 480), "scene": "res://scenes/stage_1_3.tscn"},
	{"id": "1-4", "name": "SNEEZY WEEZY", "kind": "boss", "world": 0, "pos": Vector2(335, 300), "scene": "res://scenes/stage_1_4.tscn"},
	{"id": "2-1", "name": "THE CONVEYOR BELTS", "kind": "run", "world": 1, "pos": Vector2(450, 220), "scene": ""},
	{"id": "2-2", "name": "THE PIPE MAZE", "kind": "run", "world": 1, "pos": Vector2(520, 380), "scene": ""},
	{"id": "2-3", "name": "UP THE CHIMNEY", "kind": "fly", "world": 1, "pos": Vector2(630, 490), "scene": ""},
	{"id": "2-4", "name": "COLONEL CORK", "kind": "boss", "world": 1, "pos": Vector2(715, 320), "scene": ""},
	{"id": "3-1", "name": "THE CLOUD TOPS", "kind": "run", "world": 2, "pos": Vector2(830, 230), "scene": ""},
	{"id": "3-2", "name": "THE FIZZY FORTRESS", "kind": "run", "world": 2, "pos": Vector2(900, 390), "scene": ""},
	{"id": "3-3", "name": "THE STINK STORM", "kind": "fly", "world": 2, "pos": Vector2(1010, 490), "scene": ""},
	{"id": "3-4", "name": "BIG BAD BURP", "kind": "boss", "world": 2, "pos": Vector2(1065, 310), "scene": ""},
]


## Position in the list of a stop id, or -1.
static func index_of(stop_id: String) -> int:
	for i in STOPS.size():
		if STOPS[i]["id"] == stop_id:
			return i
	return -1
