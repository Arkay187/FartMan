class_name WorldMap
extends Control
## The saga map, as a little 3D world. Left/right flies Fart Man's ship (the Complex2000)
## along the path one stop at a time, accept drops him into the stop. He can only fly as far
## as the first stop not cleared yet. The stops are listed in map_stops.gd. The scenery is
## built into world_map.tscn by tools/world_map_3d.gd. The names and numbers
## at the top and bottom are plain 2D labels drawn over the 3D picture.

## The ship, the camera, and the holder of all the stops ("Stop_1-1", "Stop_1-2", ...).
@export var ship: MapShip
@export var camera: MapCamera
@export var stops_root: Node3D
## The big stop name at the top.
@export var name_label: Label
## Golden Beans and best score of the stop he is hovering over.
@export var info_label: Label
## "COMING SOON!" for stops that have no stage yet.
@export var soon_label: Label
## The world's name, shown for a moment when the ship arrives in a new world.
@export var world_label: Label
## "Y: GO ABOARD", for the day the Complex2000 becomes a hub. Hidden until ship_hub_scene is set.
@export var hub_hint: Label

## While we are trying every level: let him fly to any stop, cleared or not.
## Turn this off in the editor to lock stops again.
@export var unlock_all: bool = true
## How long the flight from one stop to the next takes.
@export var slide_time: float = 1.1
## How high the ship hovers above the ground of a stop, in metres.
@export var hover_height: float = 7.5
## Ignore buttons for this long after the map appears (so the jump that left a stage is not reused).
@export var input_delay: float = 0.3
## How long "COMING SOON!" stays on screen, and how long the world's name does.
@export var soon_time: float = 1.5
@export var world_name_time: float = 2.5
@export var left_action: StringName = &"ui_left"
@export var right_action: StringName = &"ui_right"
@export var jump_action: StringName = &"ui_accept"
## The song that plays here (empty = none), and the sounds for flying along the path and going in.
@export var music_song: String = "theme"
@export var move_sound: AudioStream
@export var accept_sound: AudioStream
## The room the Complex2000 hub lives in. Empty = no hub yet: no hint, and Y does nothing.
@export_file("*.tscn") var ship_hub_scene: String = ""
@export_group("Stop looks")
## What a locked stop looks like, the Golden Beans he has found, and the ones he has not.
@export var locked_color: Color = Color(0.45, 0.45, 0.5)
@export var found_color: Color = Color(1.0, 0.82, 0.1)
@export var missing_color: Color = Color(0.25, 0.25, 0.3)

## Sent when the ship finishes flying to a stop.
signal arrived(stop_id: String)
## Sent when Fart Man jumps out of the ship to start a stage.
signal entering(stop_id: String)

## Which stop he is hovering over (position in MapStops.STOPS).
var index: int = 0
var _moving: bool = false
var _entering: bool = false
var _age: float = 0.0
var _look_dir: int = 1
var _soon_tween: Tween
var _world_tween: Tween
var _save: SaveData
var _state_key: String = ""
var _state_timer: float = 0.0
var _locked_material: StandardMaterial3D
var _found_material: StandardMaterial3D
var _missing_material: StandardMaterial3D


func _ready() -> void:
	if music_song != "":
		MusicPlayer.play_song(self, music_song)
	_save = SaveLookup.find(self)
	_locked_material = _plain(locked_color)
	_found_material = _plain(found_color)
	_missing_material = _plain(missing_color)
	# Start on the stop we came back from, or the first one not cleared yet.
	var start: int = first_open_index()
	if _save != null and _save.last_stop != "":
		var last: int = MapStops.index_of(_save.last_stop)
		if last >= 0 and last <= reachable_index():
			start = last
	index = start
	ship.snap_to(stop_hover_position(index))
	ship.landed.connect(_on_slide_done)
	camera.target = ship
	_aim_camera()
	camera.snap()
	soon_label.hide()
	world_label.hide()
	hub_hint.visible = ship_hub_scene != ""
	refresh_stops()
	_show_stop_info()
	_show_world_name()


func _process(delta: float) -> void:
	_age += delta
	# The map follows the save: if a stop gets cleared while we look, update the flags.
	_state_timer += delta
	if _state_timer > 0.25:
		_state_timer = 0.0
		if _state_text() != _state_key:
			refresh_stops()
			_show_stop_info()
	if _age < input_delay or _moving or _entering:
		return
	if Input.is_action_just_pressed(right_action):
		move(1)
	elif Input.is_action_just_pressed(left_action):
		move(-1)
	elif Input.is_action_just_pressed(jump_action):
		enter_stop()


func _unhandled_input(event: InputEvent) -> void:
	# Y on the keyboard or the pad: board the Complex2000 (only once a hub exists).
	var key := event as InputEventKey
	var pad := event as InputEventJoypadButton
	if (key != null and key.pressed and not key.echo and key.keycode == KEY_Y) \
			or (pad != null and pad.pressed and pad.button_index == JOY_BUTTON_Y):
		board_ship()


## The furthest stop he is allowed to reach. With unlock_all every stop is open;
## otherwise it is the first one not cleared (or the last one).
func reachable_index() -> int:
	if unlock_all:
		return MapStops.STOPS.size() - 1
	return first_open_index()


## The first stop not cleared yet (or the last one).
func first_open_index() -> int:
	for i in MapStops.STOPS.size():
		if not is_stop_cleared(i):
			return i
	return MapStops.STOPS.size() - 1


func is_stop_cleared(stop_index: int) -> bool:
	return _save != null and _save.is_cleared(MapStops.STOPS[stop_index]["id"])


func stop_golden(stop_index: int) -> int:
	return 0 if _save == null else _save.best_golden(MapStops.STOPS[stop_index]["id"])


func stop_score(stop_index: int) -> int:
	return 0 if _save == null else _save.best_score(MapStops.STOPS[stop_index]["id"])


## A stop he cannot fly to yet (further on than the first stop not cleared).
func is_stop_locked(stop_index: int) -> bool:
	return stop_index > reachable_index()


## The 3D node of a stop (platform, landmark, flag, padlock, Golden Bean pips).
func stop_node(stop_index: int) -> Node3D:
	return stops_root.get_node_or_null("Stop_" + str(MapStops.STOPS[stop_index]["id"])) as Node3D


## Where the ship hovers for a stop: straight above the middle of it.
func stop_hover_position(stop_index: int) -> Vector3:
	return (MapStops.STOPS[stop_index]["pos"] as Vector3) + Vector3(0.0, hover_height, 0.0)


## How many Golden Bean pips over a stop are lit (found).
func pips_lit(stop_index: int) -> int:
	var lit: int = 0
	for pip: MeshInstance3D in stop_node(stop_index).get_node("Pips").get_children():
		if pip.material_override == _found_material:
			lit += 1
	return lit


## Fly one stop along the path (direction +1 or -1). Does nothing at the ends
## or at the first stop that is not cleared.
func move(direction: int) -> void:
	var target: int = index + direction
	if _moving or _entering or target < 0 or target > reachable_index():
		return
	var old_world: int = MapStops.STOPS[index]["world"]
	index = target
	_look_dir = direction
	_moving = true
	Sfx.play(self, move_sound)
	_hide_soon()
	ship.fly_to(stop_hover_position(index), slide_time)
	_aim_camera()
	_show_stop_info()
	if MapStops.STOPS[index]["world"] != old_world:
		_show_world_name()


## Go into the stop he is hovering over: Fart Man jumps out of the ship, then the stage
## loads. Stops with no stage say COMING SOON!
func enter_stop() -> void:
	if _moving or _entering:
		return
	var stop: Dictionary = MapStops.STOPS[index]
	var scene_path: String = stop["scene"]
	if scene_path == "" or not ResourceLoader.exists(scene_path):
		_show_soon()
		return
	_entering = true
	if _save != null:
		_save.set_last_stop(stop["id"])
	Sfx.play(self, accept_sound)
	entering.emit(stop["id"])
	ship.dropped.connect(_load_stage.bind(scene_path), CONNECT_ONE_SHOT)
	ship.drop_pilot()


## The hook for the Complex2000 hub (see BEAN_SHIP_PLAN.md). With no hub scene set
## it does nothing and returns false.
func board_ship() -> bool:
	if ship_hub_scene == "" or _moving or _entering or not ResourceLoader.exists(ship_hub_scene):
		return false
	_entering = true
	if _save != null:
		_save.set_last_stop(MapStops.STOPS[index]["id"])
	Sfx.play(self, accept_sound)
	get_tree().change_scene_to_file(ship_hub_scene)
	return true


## Show or hide the "GO ABOARD" hint to match ship_hub_scene.
func refresh_hub_hint() -> void:
	hub_hint.visible = ship_hub_scene != ""


## Redraw what the save says: flags on cleared stops, Golden Bean pips, padlocks and
## grey for stops that are still locked.
func refresh_stops() -> void:
	_state_key = _state_text()
	for i in MapStops.STOPS.size():
		var node: Node3D = stop_node(i)
		var cleared: bool = is_stop_cleared(i)
		var locked: bool = is_stop_locked(i)
		node.get_node("Flag").visible = cleared
		node.get_node("Pips").visible = cleared
		node.get_node("Lock").visible = locked
		var found: int = stop_golden(i)
		var pips: Array[Node] = node.get_node("Pips").get_children()
		for p in pips.size():
			(pips[p] as MeshInstance3D).material_override = _found_material if p < found else _missing_material
		for mesh: Node in node.get_node("Look").find_children("*", "MeshInstance3D", true, false):
			(mesh as MeshInstance3D).material_override = _locked_material if locked else null


# A short text that changes whenever the map has to look different.
func _state_text() -> String:
	var text: String = str(reachable_index()) + ":"
	for i in MapStops.STOPS.size():
		text += "%d%d%d," % [int(is_stop_cleared(i)), stop_golden(i), int(is_stop_locked(i))]
	return text


func _plain(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	return material


# Point the camera's peek at the stop he is heading for next.
func _aim_camera() -> void:
	var next: int = clampi(index + _look_dir, 0, MapStops.STOPS.size() - 1)
	camera.peek_point = stop_hover_position(next)
	camera.has_peek = next != index


func _on_slide_done() -> void:
	_moving = false
	arrived.emit(MapStops.STOPS[index]["id"])


func _load_stage(scene_path: String) -> void:
	get_tree().change_scene_to_file(scene_path)


func _show_stop_info() -> void:
	name_label.text = MapStops.STOPS[index]["name"]
	if is_stop_cleared(index):
		info_label.text = "GOLDEN BEANS %d/3   BEST %d" % [stop_golden(index), stop_score(index)]
	else:
		info_label.text = ""


# The world's name, for a moment.
func _show_world_name() -> void:
	world_label.text = MapStops.WORLDS[MapStops.STOPS[index]["world"]]["name"]
	world_label.show()
	if _world_tween != null:
		_world_tween.kill()
	_world_tween = create_tween()
	_world_tween.tween_interval(world_name_time)
	_world_tween.tween_callback(world_label.hide)


func _show_soon() -> void:
	soon_label.show()
	if _soon_tween != null:
		_soon_tween.kill()
	_soon_tween = create_tween()
	_soon_tween.tween_interval(soon_time)
	_soon_tween.tween_callback(soon_label.hide)


func _hide_soon() -> void:
	if _soon_tween != null:
		_soon_tween.kill()
	soon_label.hide()
