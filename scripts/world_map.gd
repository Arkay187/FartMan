class_name WorldMap
extends Control
## The saga map. Left/right walks Fart Man along the path one stop at a time,
## jump goes into the stop. He can only walk as far as the first stop not cleared yet.
## The stops themselves are listed in map_stops.gd. The drawing is in map_canvas.gd.

## Fart Man's marker.
@export var marker: Node2D
## The big stop name at the top.
@export var name_label: Label
## Golden Beans and best score of the stop he is standing on.
@export var info_label: Label
## "COMING SOON!" for stops that have no stage yet.
@export var soon_label: Label
## The drawing of the map (it asks this script what is cleared).
@export var canvas: Control

## While we are trying every level: let him walk to any stop, cleared or not.
## Turn this off in the editor to lock stops again.
@export var unlock_all: bool = true
## How long the slide from one stop to the next takes.
@export var slide_time: float = 0.25
## Ignore buttons for this long after the map appears (so the jump that left a stage is not reused).
@export var input_delay: float = 0.3
## How long "COMING SOON!" stays on screen.
@export var soon_time: float = 1.5
@export var left_action: StringName = &"ui_left"
@export var right_action: StringName = &"ui_right"
@export var jump_action: StringName = &"ui_accept"
## The song that plays here (empty = none), and the sounds for moving along the path and going in.
@export var music_song: String = "theme"
@export var move_sound: AudioStream
@export var accept_sound: AudioStream

## Sent when Fart Man finishes sliding to a stop.
signal arrived(stop_id: String)

## Which stop he is standing on (position in MapStops.STOPS).
var index: int = 0
var _moving: bool = false
var _age: float = 0.0
var _soon_tween: Tween
var _save: SaveData


func _ready() -> void:
	if music_song != "":
		MusicPlayer.play_song(self, music_song)
	_save = SaveLookup.find(self)
	# Start on the stop we came back from, or the first one not cleared yet.
	var start: int = first_open_index()
	if _save != null and _save.last_stop != "":
		var last: int = MapStops.index_of(_save.last_stop)
		if last >= 0 and last <= reachable_index():
			start = last
	index = start
	marker.position = stop_marker_position(index)
	soon_label.hide()
	_show_stop_info()
	if canvas != null:
		canvas.set("map", self)
		canvas.queue_redraw()


func _process(delta: float) -> void:
	_age += delta
	if _age < input_delay or _moving:
		return
	if Input.is_action_just_pressed(right_action):
		move(1)
	elif Input.is_action_just_pressed(left_action):
		move(-1)
	elif Input.is_action_just_pressed(jump_action):
		enter_stop()


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


## Where the marker's feet go for a stop: standing on top of the spot.
func stop_marker_position(stop_index: int) -> Vector2:
	return MapStops.STOPS[stop_index]["pos"] + Vector2(0, -6)


## Walk one stop along the path (direction +1 or -1). Does nothing at the ends
## or at the first stop that is not cleared.
func move(direction: int) -> void:
	var target: int = index + direction
	if _moving or target < 0 or target > reachable_index():
		return
	index = target
	_moving = true
	Sfx.play(self, move_sound)
	_hide_soon()
	var tween: Tween = create_tween()
	tween.tween_property(marker, "position", stop_marker_position(index), slide_time)
	tween.tween_callback(_on_slide_done)
	_show_stop_info()


## Go into the stop he is standing on. Stops with no stage say COMING SOON!
func enter_stop() -> void:
	if _moving:
		return
	var stop: Dictionary = MapStops.STOPS[index]
	var scene_path: String = stop["scene"]
	if scene_path == "" or not ResourceLoader.exists(scene_path):
		_show_soon()
		return
	if _save != null:
		_save.set_last_stop(stop["id"])
	Sfx.play(self, accept_sound)
	get_tree().change_scene_to_file(scene_path)


func _on_slide_done() -> void:
	_moving = false
	arrived.emit(MapStops.STOPS[index]["id"])


func _show_stop_info() -> void:
	name_label.text = MapStops.STOPS[index]["name"]
	if is_stop_cleared(index):
		info_label.text = "GOLDEN BEANS %d/3   BEST %d" % [stop_golden(index), stop_score(index)]
	else:
		info_label.text = ""


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
