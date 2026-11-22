extends SceneTree
# Checks the music: every song file exists and reads properly, each stage picks the right song,
# the synth makes real (non-silent) sound fast enough, the songs loop, and the pause menu's
# MUSIC choice silences it and is remembered. It can't hear anything: it checks the numbers.

const SONGS: Array[String] = ["garden", "factory", "planet_whiff", "boss", "theme"]

var failures: int = 0


func _initialize() -> void:
	_run()


func _wait(seconds: float) -> void:
	for i in int(seconds * 60.0):
		await process_frame


func _check(label: String, ok: bool) -> void:
	print("%s: %s" % [label, "ok" if ok else "FAIL"])
	if not ok:
		failures += 1


func _peak(samples: PackedVector2Array) -> float:
	var peak: float = 0.0
	for s: Vector2 in samples:
		peak = maxf(peak, absf(s.x))
	return peak


func _run() -> void:
	await _wait(0.1)  # let the autoloads start
	_check_files()
	await _check_stage_choice()
	_check_synth()
	_check_loop()
	await _check_music_off()
	print("music failures: %d" % failures)
	quit()


## Every .mid file is there and reads: plenty of notes, a sensible length, all four channels.
func _check_files() -> void:
	for song_name in SONGS:
		var path: String = "res://audio/music/%s.mid" % song_name
		_check("%s.mid exists" % song_name, FileAccess.file_exists(path))
		var song: MidiFile = MidiFile.load_file(path)
		_check("%s.mid reads" % song_name, song != null)
		if song == null:
			continue
		var channels: Dictionary = {}
		for note: Dictionary in song.notes:
			channels[note["channel"]] = true
		_check("%s has plenty of notes (%d)" % [song_name, song.notes.size()], song.notes.size() > 300)
		_check("%s is 20 to 90 seconds (%.1f)" % [song_name, song.length], song.length >= 20.0 and song.length <= 90.0)
		_check("%s uses lead, harmony, bass and drums" % song_name,
			channels.has(0) and channels.has(1) and channels.has(2) and channels.has(9))
		_check("%s notes are in time order" % song_name, _in_order(song))
	# The tempo is read: garden is 130 BPM, 24 bars of 4 beats.
	var garden: MidiFile = MidiFile.load_file("res://audio/music/garden.mid")
	_check("garden is 24 bars at 130 BPM (%.2f s)" % garden.length, absf(garden.length - 96.0 * 60.0 / 130.0) < 0.05)
	# Bad bytes give null, not a crash.
	_check("garbage is not a song", MidiFile.parse(PackedByteArray([1, 2, 3])) == null)


func _in_order(song: MidiFile) -> bool:
	var last: float = -1.0
	for note: Dictionary in song.notes:
		if note["time"] < last:
			return false
		last = note["time"]
	return true


## Which song each stage plays, by the number and in a real stage (and a bit faster when flying).
func _check_stage_choice() -> void:
	_check("1-1 is garden", Stage.song_for("1-1") == "garden")
	_check("1-3 is garden", Stage.song_for("1-3") == "garden")
	_check("2-2 is factory", Stage.song_for("2-2") == "factory")
	_check("3-1 is planet_whiff", Stage.song_for("3-1") == "planet_whiff")
	_check("1-4 is boss", Stage.song_for("1-4") == "boss")
	_check("2-4 is boss", Stage.song_for("2-4") == "boss")
	_check("a test level is garden", Stage.song_for("") == "garden" and Stage.song_for("T-1") == "garden")

	for row: Array in [["stage_1_1", "garden", 1.0], ["stage_2_2", "factory", 1.0], ["stage_1_3", "garden", 1.15],
			["stage_1_4", "boss", 1.0], ["stage_2_4", "boss", 1.0], ["stage_t_1", "garden", 1.0]]:
		var stage: Stage = load("res://scenes/%s.tscn" % row[0]).instantiate()
		root.add_child(stage)
		await _wait(0.3)
		var music: MusicPlayer = MusicPlayer.current(root)
		_check("%s plays %s at speed %s" % [row[0], row[1], row[2]],
			music != null and music.song_name == row[1] and is_equal_approx(music.speed, row[2]))
		stage.free()
		await _wait(0.1)
		var survived: MusicPlayer = MusicPlayer.current(root)
		_check("the music keeps going when the stage goes", survived != null and survived.is_inside_tree())

	# Another stage with the same song does not restart it.
	var music: MusicPlayer = MusicPlayer.current(root)
	music.render(5000)
	var clock_before: int = music._clock
	MusicPlayer.play_song(root, music.song_name)
	_check("asking for the song already playing does nothing", music._clock == clock_before)
	# The override setting wins over the stage number.
	var stage: Stage = load("res://scenes/stage_1_1.tscn").instantiate()
	stage.music_song = "theme"
	_check("music_song overrides the choice", stage.song_name() == "theme")
	stage.free()

	# Menu, map and storybook play the theme.
	for scene_name in ["start_menu", "world_map", "storybook"]:
		var screen: Node = load("res://scenes/%s.tscn" % scene_name).instantiate()
		root.add_child(screen)
		await _wait(0.2)
		_check("%s plays the theme" % scene_name, MusicPlayer.current(root).song_name == "theme")
		screen.free()
		await _wait(0.1)


## The synth makes real sound, and fast enough.
func _check_synth() -> void:
	for song_name in SONGS:
		var player := MusicPlayer.new()
		player.start_song(song_name)
		player.render(2000)  # warm up
		var started: int = Time.get_ticks_usec()
		var audio: PackedVector2Array = player.render(MusicPlayer.MIX_RATE)
		var seconds: float = float(Time.get_ticks_usec() - started) / 1000000.0
		var peak: float = _peak(audio)
		var loud: int = 0
		for s: Vector2 in audio:
			if absf(s.x) > 0.02:
				loud += 1
		_check("%s: 1 s of audio has real sound (peak %.2f, %d loud samples)" % [song_name, peak, loud],
			peak > 0.1 and peak <= 1.0 and loud > 2000)
		_check("%s: 1 s of audio takes %.0f ms (under 200)" % [song_name, seconds * 1000.0], seconds < 0.2)
		player.free()
	# Faster speed makes the song shorter.
	var fast := MusicPlayer.new()
	fast.start_song("garden")
	fast.speed = 1.15
	_check("speed 1.15 shortens the loop", fast._loop_samples < int(fast.song.length * MusicPlayer.MIX_RATE * 0.9))
	fast.free()


## The song goes round again at the end.
func _check_loop() -> void:
	var player := MusicPlayer.new()
	player.start_song("planet_whiff")
	var seconds: int = ceili(player.song.length) + 2
	var last_peak: float = 0.0
	for i in seconds:
		last_peak = _peak(player.render(MusicPlayer.MIX_RATE))
	_check("the song loops (went round %d time)" % player.loops_played, player.loops_played == 1)
	_check("it is still making sound after the loop (peak %.2f)" % last_peak, last_peak > 0.1)
	player.free()


## MUSIC OFF from the pause menu silences it, and is remembered.
func _check_music_off() -> void:
	var options: DebugOptionsData = root.get_node("DebugOptions")
	var stage: Stage = load("res://scenes/stage_1_1.tscn").instantiate()
	root.add_child(stage)
	await _wait(0.3)
	var music: MusicPlayer = MusicPlayer.current(root)
	var menu: PauseMenu = null
	for child: Node in stage.get_children():
		if child is PauseMenu:
			menu = child
	_check("music is on to begin with", music.is_audible() and options.music_on)
	menu.open()
	await _wait(0.3)
	menu.select(PauseMenu.MUSIC)
	menu.choose()
	_check("MUSIC: OFF silences it", not options.music_on and not music.is_audible() and not music.enabled)
	_check("the pause menu says so", menu.choice_text(PauseMenu.MUSIC) == "MUSIC: OFF")
	# A new song while music is off stays silent.
	MusicPlayer.play_song(root, "boss")
	_check("a new song stays silent while it is off", music.song_name == "boss" and not music.is_audible())
	menu.choose()
	_check("MUSIC: ON brings it back", options.music_on and music.is_audible())
	menu.close()
	stage.free()

	# Remembered between games: save, then read it back into a fresh options object.
	var temp: String = "user://test_music_options.json"
	var writer := DebugOptionsData.new()
	writer.test_saving = true
	writer.save_path = temp
	writer.set_music(false)
	var reader := DebugOptionsData.new()
	reader.test_saving = true
	reader.save_path = temp
	reader._load()
	_check("MUSIC OFF is remembered in the options file", not reader.music_on)
	writer.set_music(true)
	reader._load()
	_check("and ON too", reader.music_on)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(temp))
	writer.free()
	reader.free()
	# A fresh MusicPlayer obeys the remembered choice.
	options.set_music(false)
	var late := MusicPlayer.new()
	root.add_child(late)
	late.start_song("garden")
	await _wait(0.1)
	_check("a new player starts silent when music is off", not late.is_audible())
	options.set_music(true)
	await _wait(0.1)
	_check("and wakes up when it is turned on", late.is_audible())
	late.queue_free()
