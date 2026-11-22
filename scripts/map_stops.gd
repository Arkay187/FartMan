class_name MapStops
extends RefCounted
## The world map as plain lists. Edit this file to rename, move or add stops.
##
## Positions are in metres on the 3D map: x runs left to right, z comes towards the
## camera, y is up (Planet Whiff floats high in the sky). The point is the ground
## in the middle of the stop. kind is "run", "fly" or "boss".
## scene is empty until the stage exists.

## The three worlds: a name for the banner and a colour for the ground.
const WORLDS: Array[Dictionary] = [
	{"name": "GRANDMA'S GARDEN", "color": Color(0.45, 0.78, 0.4)},
	{"name": "THE BEAN FACTORY", "color": Color(0.62, 0.58, 0.55)},
	{"name": "PLANET WHIFF", "color": Color(0.6, 0.42, 0.78)},
]

## How high Planet Whiff floats above the other two worlds.
const SKY_HEIGHT: float = 10.0

## The 12 stops, in the order you play them.
const STOPS: Array[Dictionary] = [
	{"id": "1-1", "name": "THE VEG PATCH", "kind": "run", "world": 0, "pos": Vector3(0, 0, 6), "scene": "res://scenes/stage_1_1.tscn"},
	{"id": "1-2", "name": "THE GREENHOUSE", "kind": "run", "world": 0, "pos": Vector3(14, 0, -3), "scene": "res://scenes/stage_1_2.tscn"},
	{"id": "1-3", "name": "OVER THE ROOFTOPS", "kind": "fly", "world": 0, "pos": Vector3(28, 0, 5), "scene": "res://scenes/stage_1_3.tscn"},
	{"id": "1-4", "name": "SNEEZY WEEZY", "kind": "boss", "world": 0, "pos": Vector3(41, 0, -4), "scene": "res://scenes/stage_1_4.tscn"},
	{"id": "2-1", "name": "THE CONVEYOR BELTS", "kind": "run", "world": 1, "pos": Vector3(58, 0, 4), "scene": "res://scenes/stage_2_1.tscn"},
	{"id": "2-2", "name": "THE PIPE MAZE", "kind": "run", "world": 1, "pos": Vector3(72, 0, -4), "scene": "res://scenes/stage_2_2.tscn"},
	{"id": "2-3", "name": "UP THE CHIMNEY", "kind": "fly", "world": 1, "pos": Vector3(86, 0, 5), "scene": "res://scenes/stage_2_3.tscn"},
	{"id": "2-4", "name": "COLONEL CORK", "kind": "boss", "world": 1, "pos": Vector3(99, 0, -3), "scene": "res://scenes/stage_2_4.tscn"},
	{"id": "3-1", "name": "THE CLOUD TOPS", "kind": "run", "world": 2, "pos": Vector3(118, SKY_HEIGHT, 4), "scene": "res://scenes/stage_3_1.tscn"},
	{"id": "3-2", "name": "THE FIZZY FORTRESS", "kind": "run", "world": 2, "pos": Vector3(132, SKY_HEIGHT, -4), "scene": "res://scenes/stage_3_2.tscn"},
	{"id": "3-3", "name": "THE STINK STORM", "kind": "fly", "world": 2, "pos": Vector3(146, SKY_HEIGHT, 5), "scene": "res://scenes/stage_3_3.tscn"},
	{"id": "3-4", "name": "BIG BAD BURP", "kind": "boss", "world": 2, "pos": Vector3(159, SKY_HEIGHT, -3), "scene": "res://scenes/stage_3_4.tscn"},
]


## Position in the list of a stop id, or -1.
static func index_of(stop_id: String) -> int:
	for i in STOPS.size():
		if STOPS[i]["id"] == stop_id:
			return i
	return -1
