class_name Sfx
extends RefCounted
## Plays little sound effects. Use it from any script, in one line:
##     Sfx.play(self, bean_sound)
## It makes a throw-away speaker, plays the sound once, and tidies up when it is done.
## Sounds far off the edge of the screen are skipped, so enemies you can't see stay quiet.
## The sound files are made by tools/make_sfx.gd and live in res://audio/sfx.

## Sounds further than this from the camera (in metres, across and up) are not played.
const HEAR_DISTANCE: float = 30.0
## The mixer channels (buses) the game makes for itself if they are missing.
const MUSIC_BUS: StringName = &"Music"
const SOUNDS_BUS: StringName = &"Sounds"
## Every sound each play() call has started (file names), for the tests.
static var played: Array[String] = []


## Plays "stream" once.
##   from = the thing making the noise (used to skip sounds far off screen). A menu can pass itself.
##   volume_db = 0 as made, -6 about half as loud.
##   pitch = 1 as made, 2 an octave higher.
##   wobble = each play comes out a little higher or lower, so repeats don't get boring.
static func play(from: Node, stream: AudioStream, volume_db: float = 0.0, pitch: float = 1.0, wobble: float = 0.05) -> void:
	if stream == null or from == null or not from.is_inside_tree():
		return
	if not is_near_camera(from):
		return
	played.append(stream.resource_path.get_file())
	# The automatic tests run with no window and no speakers: just note the sound.
	if DisplayServer.get_name() == "headless":
		return
	ensure_buses()
	var speaker := AudioStreamPlayer.new()
	speaker.stream = stream
	speaker.bus = SOUNDS_BUS
	speaker.volume_db = volume_db
	speaker.pitch_scale = maxf(pitch + randf_range(-wobble, wobble), 0.1)
	speaker.process_mode = Node.PROCESS_MODE_ALWAYS  # menu sounds work while the game is paused
	speaker.finished.connect(speaker.queue_free)
	from.get_tree().root.add_child(speaker)
	speaker.play()


## One of the generated sound files by name (like "menu_move"), or null if it isn't there.
static func named(sfx_name: String) -> AudioStream:
	var path: String = "res://audio/sfx/%s.wav" % sfx_name
	return load(path) as AudioStream if ResourceLoader.exists(path) else null


## True if "from" is close enough to the camera to be heard. Things with no place (menus) always are.
static func is_near_camera(from: Node) -> bool:
	var thing := from as Node3D
	if thing == null or not thing.is_inside_tree():
		return true
	var camera: Camera3D = thing.get_viewport().get_camera_3d()
	if camera == null:
		return true
	var offset: Vector3 = thing.global_position - camera.global_position
	return Vector2(offset.x, offset.y).length() <= HEAR_DISTANCE


## Makes the "Music" and "Sounds" buses if the project doesn't have them. Safe to call any time.
static func ensure_buses() -> void:
	for bus_name: StringName in [MUSIC_BUS, SOUNDS_BUS]:
		if AudioServer.get_bus_index(bus_name) == -1:
			AudioServer.add_bus()
			var index: int = AudioServer.bus_count - 1
			AudioServer.set_bus_name(index, bus_name)
			AudioServer.set_bus_send(index, &"Master")
