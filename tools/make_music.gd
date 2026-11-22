extends SceneTree
## Composes the game's songs and writes them as real MIDI files into res://audio/music.
## Run it again any time to make the files fresh:
##     godot --headless --script res://tools/make_music.gd
## The songs are written in a tiny note language, so they are easy to change here:
##   - each word is one step (an eighth note, or whatever step the line says)
##   - a number is the scale degree: 1 = home note, 8 = home note an octave up
##   - ' goes up an octave, a comma goes down one, b flattens, # sharpens
##   - "-" holds the note before, "r" is a rest
## Channels: 1 lead, 2 harmony, 3 bass, 10 drums (General MIDI: 36 kick, 38 snare, 42 hat,
## 46 open hat, 49 crash, 56 cowbell, 37 stick, 75 claves).

const MidiWriter = preload("res://tools/midi_writer.gd")

const MAJOR: Array[int] = [0, 2, 4, 5, 7, 9, 11]
const MINOR: Array[int] = [0, 2, 3, 5, 7, 8, 10]
const DORIAN: Array[int] = [0, 2, 3, 5, 7, 9, 10]
const LYDIAN: Array[int] = [0, 2, 4, 6, 7, 9, 11]

const OUT_DIR: String = "res://audio/music/"

var problems: int = 0


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	_garden()
	_factory()
	_planet_whiff()
	_boss()
	_theme()
	print("music problems: %d" % problems)
	quit()


# ------------------------------------------------------------------ the songs

## World 1, Grandma's Garden: C major, 130 BPM, sunny and bouncy. 24 bars.
func _garden() -> void:
	var w := MidiWriter.new(130.0)
	var lead: int = w.add_track("Lead", 0, 80, 100)
	var harm: int = w.add_track("Harmony", 1, 46, 80)
	var bass: int = w.add_track("Bass", 2, 33, 100)
	var drums: int = w.add_track("Drums", 9, 0, 100)
	var prog: Array[int] = [1, 4, 1, 5, 1, 4, 5, 1,  6, 4, 1, 5, 6, 4, 5, 5,  1, 4, 1, 5, 1, 4, 5, 1]
	# Section A: the bouncy tune.
	_melody(w, lead, 0, 72, MAJOR, 0.5, 8,
		"3 5 8 5 3 5 8 - | 4 6 9 6 4 6 8 - | 8 7 8 5 3 - 5 - | 5 7 9 7 5 - r r | "
		+ "8 - 8 9 10 - 8 - | 9 - 8 6 4 - 6 - | 5 - 7 9 8 - 7 - | 8 5 3 5 8 - r r")
	# Section B: the sing-along part.
	_melody(w, lead, 8, 72, MAJOR, 0.5, 8,
		"8 - 8 6 8 - 10 - | 9 - 8 6 9 - 8 - | 10 - 8 5 8 - 10 - | 9 - 7 5 7 - 9 - | "
		+ "10 - 10 9 8 - 6 - | 6 - 8 9 8 - 6 - | 5 7 9 11 - 9 7 5 | 7 - r r 7 5 7 9")
	# Section A again, ending with a sad trombone "wah wah wah waaah".
	_melody(w, lead, 16, 72, MAJOR, 0.5, 8,
		"3 5 8 5 3 5 8 - | 4 6 9 6 4 6 8 - | 8 7 8 5 3 - 5 - | 5 7 9 7 5 - r r | "
		+ "8 - 8 9 10 - 8 - | 9 - 8 6 4 - 6 - | 5 - 7 9 11 - 9 - | 5 - b5 - 4 - 3 -")
	for bar in 24:
		var tones: Array[int] = _tones(60, MAJOR, prog[bar], 3)
		if bar >= 8 and bar < 16:
			_arp(w, harm, bar, tones, [0, 1, 2, 1, 0, 1, 2, 1], 0.5, 0.4, 62)
		else:
			_stabs(w, harm, bar, tones, [1.0, 3.0], 0.4, 70)
		_bass(w, bass, bar, 48 + MAJOR[prog[bar] - 1], "oompah", 95)
		_drums(w, drums, bar, "bounce", bar % 8 == 7, bar % 8 == 0)
	_finish(w, "garden", 24)


## World 2, Bean Factory: D dorian, 140 BPM, chuggy and mechanical. 24 bars.
func _factory() -> void:
	var w := MidiWriter.new(140.0)
	var lead: int = w.add_track("Lead", 0, 80, 100)
	var harm: int = w.add_track("Harmony", 1, 90, 75)
	var bass: int = w.add_track("Bass", 2, 38, 100)
	var drums: int = w.add_track("Drums", 9, 0, 100)
	var prog: Array[int] = [1, 1, 7, 7, 1, 1, 4, 5,  4, 4, 1, 1, 7, 7, 5, 5,  1, 1, 7, 7, 1, 1, 4, 5]
	var riff_a: String = "1 1 r 3 5 r 3 1 | 1 1 r 3 5 r 6 5 | 7, 7, r 2 4 r 2 7, | 7, 7, r 2 4 r 5 4 | " \
		+ "1 1 r 3 5 r 3 1 | 5 5 r 6 8 r 6 5 | 4 4 r 6 8 r 6 4 | 5 5 r 7 9 r 7 5"
	_melody(w, lead, 0, 62, DORIAN, 0.5, 8, riff_a, 92, 0.6)
	# Section B: the tune gets smoother, and slides down like a slide whistle at the end.
	_melody(w, lead, 8, 62, DORIAN, 0.5, 8,
		"8 - 6 4 6 - 8 - | 9 - 8 6 4 - 6 - | 8 - 5 3 1 - 3 - | 5 - 3 1 3 - 5 - | "
		+ "7, - 2 4 2 - 7, - | 4 - 2 7, 2 - 4 - | 5 - 7 9 7 - 5 - | 9 b9 8 b8 7 6 b6 5", 92, 0.8)
	_melody(w, lead, 16, 62, DORIAN, 0.5, 8, riff_a, 92, 0.6)
	for bar in 24:
		var tones: Array[int] = _tones(62, DORIAN, prog[bar], 3)
		_arp(w, harm, bar, tones, [0, 2, 1, 2], 0.5, 0.25, 64)
		_bass(w, bass, bar, 38 + DORIAN[prog[bar] - 1], "chug", 100)
		_drums(w, drums, bar, "machine", bar % 8 == 7, bar % 8 == 0)
	_finish(w, "factory", 24)


## World 3, Planet Whiff: G lydian, 110 BPM, spacey and bubbly with odd leaps. 16 bars.
func _planet_whiff() -> void:
	var w := MidiWriter.new(110.0)
	var lead: int = w.add_track("Lead", 0, 80, 95)
	var harm: int = w.add_track("Harmony", 1, 88, 75)
	var bass: int = w.add_track("Bass", 2, 39, 100)
	var drums: int = w.add_track("Drums", 9, 0, 95)
	var prog: Array[int] = [1, 2, 1, 2, 3, 2, 7, 2,  1, 2, 1, 2, 3, 2, 1, 1]
	_melody(w, lead, 0, 67, LYDIAN, 0.5, 8,
		"1 4 8 4 1 4 7 - | 2 5 9 5 2 5 8 - | 1 4 8 4 1 4 7 - | 2 5 9 5 8 - 6 - | "
		+ "3 6 10 6 3 6 9 - | 2 5 9 5 2 - r r | 7, 3 5 7 - 5 3 - | 9 - 8 - 7 - 4 -", 88, 0.7)
	# Section B: sixteenth-note bubbles.
	_melody(w, lead, 8, 67, LYDIAN, 0.25, 7,
		"1 3 5 8 5 3 1 3 5 8 10 8 5 3 1 - | 2 4 6 9 6 4 2 4 6 9 11 9 6 4 2 - | "
		+ "1 5 3 8 5 10 8 5 3 8 5 3 1 - r r | 2 6 4 9 6 11 9 6 4 9 6 4 2 - r r | "
		+ "3 5 7 10 7 5 3 5 7 10 9 10 7 5 3 - | 2 4 6 9 6 4 2 4 6 9 8 9 6 4 2 - | "
		+ "1 3 5 8 5 3 1 3 5 8 10 8 5 3 1 -", 80, 0.7)
	_melody(w, lead, 15, 67, LYDIAN, 0.5, 1, "8 7 6 5 4 3 2 1", 88, 0.7)
	for bar in 16:
		var tones: Array[int] = _tones(55, LYDIAN, prog[bar], 5)
		if bar >= 8 and bar < 15:
			_stabs(w, harm, bar, tones.slice(0, 3), [0.0], 3.5, 55)
		else:
			_arp(w, harm, bar, tones, [0, 2, 4, 2, 1, 3, 4, 3], 0.25, 0.2, 60)
		_bass(w, bass, bar, 43 + LYDIAN[prog[bar] - 1], "bubble", 95)
		_drums(w, drums, bar, "space", bar % 4 == 3, bar % 8 == 0)
	_finish(w, "planet_whiff", 16)


## Boss fights: E minor, 160 BPM, urgent with a galloping bass. 32 bars.
func _boss() -> void:
	var w := MidiWriter.new(160.0)
	var lead: int = w.add_track("Lead", 0, 80, 100)
	var harm: int = w.add_track("Harmony", 1, 90, 80)
	var bass: int = w.add_track("Bass", 2, 38, 100)
	var drums: int = w.add_track("Drums", 9, 0, 100)
	var prog_a: Array[int] = [1, 1, 6, 7, 1, 1, 6, 5]
	var prog_b: Array[int] = [6, 7, 1, 1, 6, 7, 5, 5]
	var tune_a: String = "1 1 1 r 1 3 2 1 | 1 1 1 r 3 5 4 3 | 6 6 6 r 6 8 7 6 | 7 7 7 r 7 9 8 7 | " \
		+ "8 - 7 6 5 - 3 - | 3 5 8 5 3 5 8 - | 6 8 10 8 6 8 10 - | 5 7 9 7 5 7 9 -"
	var tune_b: String = "6 8 6 8 10 - 8 - | 7 9 7 9 11 - 9 - | 10 - 8 - 5 - 3 - | 1 3 5 8 10 - r r | " \
		+ "10 - 8 6 8 - 10 - | 11 - 9 7 9 - 11 - | 9 - 7 5 7 - 9 - | "
	_melody(w, lead, 0, 64, MINOR, 0.5, 8, tune_a, 100, 0.8)
	_melody(w, lead, 8, 64, MINOR, 0.5, 8, tune_b + "5 5 5 r 9 9 9 r", 100, 0.8)
	_melody(w, lead, 16, 64, MINOR, 0.5, 8, tune_a, 100, 0.8)
	# The last time round it climbs a chromatic stair, back to the top.
	_melody(w, lead, 24, 64, MINOR, 0.5, 8, tune_b + "5 #5 6 #6 7 #7 8 9", 100, 0.8)
	for bar in 32:
		var section: int = bar >> 3
		var deg: int = prog_a[bar % 8] if section % 2 == 0 else prog_b[bar % 8]
		_stabs(w, harm, bar, _tones(52, MINOR, deg, 3), [0.0, 0.75, 1.5, 2.25, 3.0, 3.5], 0.25, 78)
		_bass(w, bass, bar, 40 + MINOR[deg - 1], "gallop", 105)
		_drums(w, drums, bar, "attack", bar % 8 == 7, bar % 8 == 0)
	_finish(w, "boss", 32)


## Start menu, world map and storybook: the heroic, cheesy FART MAN! theme. F major, 120 BPM. 24 bars.
func _theme() -> void:
	var w := MidiWriter.new(120.0)
	var lead: int = w.add_track("Lead", 0, 56, 105)
	var harm: int = w.add_track("Harmony", 1, 90, 75)
	var bass: int = w.add_track("Bass", 2, 33, 100)
	var drums: int = w.add_track("Drums", 9, 0, 100)
	var prog: Array[int] = [1, 1, 4, 5,  1, 1, 4, 5, 1, 1, 4, 5,  6, 4, 1, 5, 6, 4, 5, 5,  1, 4, 5, 1]
	# Intro fanfare.
	_melody(w, lead, 0, 65, MAJOR, 0.5, 4,
		"1 3 5 8 5 8 - - | 3 5 8 10 8 10 - - | 4 6 8 11 - 9 - - | 5 7 9 7 5 - r r", 105, 0.85)
	# The main tune, with the FART MAN! shout (5 5 8).
	_melody(w, lead, 4, 65, MAJOR, 0.5, 8,
		"5 5 8 - - - 8 9 | 10 - 9 8 5 - 3 - | 4 4 6 - 8 - 6 4 | 5 - 7 - 5 - r r | "
		+ "5 5 8 - - - 8 9 | 10 - 12 - 10 - 8 - | 11 - 10 - 8 - 6 - | 5 - r r 5 - 5 r", 105, 0.85)
	# The march.
	_melody(w, lead, 12, 65, MAJOR, 0.5, 8,
		"6 - 8 - 10 - 8 - | 4 - 6 - 8 - 6 - | 8 - 10 - 12 - 10 - | 7 - 9 - 7 - 5 - | "
		+ "6 - 8 - 10 - 13 - | 11 - 10 - 8 - 6 - | 9 - 8 - 7 - 9 - | 5 5 5 r 5 5 5 r", 105, 0.85)
	# The big finish, then a tiny toot (two low notes sliding down).
	_melody(w, lead, 20, 65, MAJOR, 0.5, 4,
		"5 5 8 - - - 8 9 | 11 - - - 9 - 8 - | 7 - 9 - 12 - - - | 5 5 8 - - - 1, b1,", 105, 0.85)
	for bar in 24:
		var tones: Array[int] = _tones(53, MAJOR, prog[bar], 3)
		_arp(w, harm, bar, tones, [0, 1, 2, 1, 0, 1, 2, 1], 0.5, 0.4, 62)
		_bass(w, bass, bar, 41 + MAJOR[prog[bar] - 1], "hero", 100)
		_drums(w, drums, bar, "march", bar % 4 == 3, bar == 0 or bar == 4 or bar == 12 or bar == 20)
	_finish(w, "theme", 24)


# ------------------------------------------------------------------ helpers

func _finish(w: MidiWriter, song_name: String, bars: int) -> void:
	w.end_at(bars * 4.0)
	var path: String = OUT_DIR + song_name + ".mid"
	var err: Error = w.save(path)
	print("saved %s (%d bars, %.0f s): %s" % [path, bars, bars * 4.0 * 60.0 / w.bpm, error_string(err)])
	if err != OK:
		problems += 1


## Writes a line of notes in the note language (see the top of this file).
## bar = where it starts, bars = how many bars it must fill (checked, so a typo is caught).
func _melody(w: MidiWriter, track: int, bar: int, root: int, scale: Array[int], step: float, bars: int,
		text: String, velocity: int = 90, gate: float = 0.85) -> void:
	var beat: float = bar * 4.0
	var notes: Array = []  # each is [start, length, pitch]
	for word: String in text.split(" ", false):
		if word == "|":
			continue
		if word == "-":
			if not notes.is_empty():
				notes[notes.size() - 1][1] += step
		elif word != "r":
			notes.append([beat, step, _pitch(word, root, scale)])
		beat += step
	var used: float = beat - bar * 4.0
	if absf(used - bars * 4.0) > 0.01:
		push_error("melody at bar %d is %.2f beats, wanted %.2f" % [bar, used, bars * 4.0])
		problems += 1
	for n: Array in notes:
		w.note(track, n[0], maxf(float(n[1]) * gate, 0.1), n[2], velocity)


## "b3" or "5'" or "7," to a MIDI note number.
func _pitch(word: String, root: int, scale: Array[int]) -> int:
	var shift: int = 0
	while word.begins_with("b") or word.begins_with("#"):
		shift += -1 if word.begins_with("b") else 1
		word = word.substr(1)
	var octave: int = 0
	while word.ends_with("'") or word.ends_with(","):
		octave += 1 if word.ends_with("'") else -1
		word = word.left(word.length() - 1)
	return root + _degree(scale, word.to_int()) + shift + 12 * octave


## Semitones above the home note for scale degree 1, 2, 3... (8 = octave up).
func _degree(scale: Array[int], degree: int) -> int:
	var index: int = degree - 1
	return scale[index % 7] + 12 * floori(index / 7.0)


## The notes of a chord built on a scale degree: root, third, fifth, seventh...
func _tones(root: int, scale: Array[int], degree: int, count: int) -> Array[int]:
	var tones: Array[int] = []
	for i in count:
		tones.append(root + _degree(scale, degree + 2 * i))
	return tones


## Short chords at these beats of the bar.
func _stabs(w: MidiWriter, track: int, bar: int, tones: Array[int], beats: Array, length: float, velocity: int) -> void:
	for beat: float in beats:
		for pitch: int in tones:
			w.note(track, bar * 4.0 + beat, length, pitch, velocity)


## Plays the chord one note at a time, going through the pattern (0 = first chord note, 1 = second...).
func _arp(w: MidiWriter, track: int, bar: int, tones: Array[int], pattern: Array, step: float, length: float, velocity: int) -> void:
	var count: int = roundi(4.0 / step)
	for i in count:
		var pitch: int = tones[int(pattern[i % pattern.size()]) % tones.size()]
		w.note(track, bar * 4.0 + i * step, length, pitch, velocity)


## The bass line for one bar, in a named style.
func _bass(w: MidiWriter, track: int, bar: int, root: int, style: String, velocity: int) -> void:
	var start: float = bar * 4.0
	match style:
		"oompah":  # root, fifth, root, fifth
			for i in 4:
				w.note(track, start + i, 0.5, root + (7 if i % 2 == 1 else 0), velocity)
		"chug":  # driving eighths with octave pops
			var pops: Array[int] = [0, 0, 12, 0, 0, 0, 12, 0]
			for i in 8:
				w.note(track, start + i * 0.5, 0.4, root + pops[i], velocity)
		"bubble":  # off-beat bounces
			var times: Array[float] = [0.0, 0.75, 1.5, 2.0, 2.75, 3.25]
			var pops: Array[int] = [0, 12, 0, 7, 12, 0]
			for i in times.size():
				w.note(track, start + times[i], 0.3, root + pops[i], velocity)
		"gallop":  # da-da-dum, da-da-dum
			for beat in 4:
				var pops: Array[int] = [0, 0, 0]
				if beat == 3:
					pops = [0, 7, 12]
				w.note(track, start + beat, 0.4, root + pops[0], velocity)
				w.note(track, start + beat + 0.5, 0.2, root + pops[1], velocity)
				w.note(track, start + beat + 0.75, 0.2, root + pops[2], velocity)
		"hero":  # root and fifth, marching
			var pops: Array[int] = [0, 0, 7, 0, 0, 7, 0, 7]
			for i in 8:
				w.note(track, start + i * 0.5, 0.4, root + pops[i], velocity)


## The drums for one bar. fill = a drum roll on the last beat. crash = a cymbal crash on beat one.
func _drums(w: MidiWriter, track: int, bar: int, style: String, fill: bool, crash: bool) -> void:
	var start: float = bar * 4.0
	if crash:
		w.note(track, start, 0.5, 49, 100)
	match style:
		"bounce":  # kick-snare-kick-snare, hats between
			for beat: float in [0.0, 2.0]:
				w.note(track, start + beat, 0.1, 36, 105)
			for beat: float in [1.0, 3.0]:
				w.note(track, start + beat, 0.1, 38, 95)
			for i in 8:
				w.note(track, start + i * 0.5, 0.1, 46 if i == 7 else 42, 55 if i % 2 == 0 else 40)
		"machine":  # four on the floor, clanking
			for beat in 4:
				w.note(track, start + beat, 0.1, 36, 105)
				w.note(track, start + beat + 0.5, 0.1, 56, 55)
			for beat: float in [1.0, 3.0]:
				w.note(track, start + beat, 0.1, 38, 90)
			for beat: float in [1.75, 3.75]:
				w.note(track, start + beat, 0.1, 37, 80)
			for i in 16:
				w.note(track, start + i * 0.25, 0.05, 42, 35)
		"space":  # loose and wobbly
			for beat: float in [0.0, 1.5, 2.5]:
				w.note(track, start + beat, 0.1, 36, 100)
			w.note(track, start + 2.0, 0.1, 39, 85)
			for i in 8:
				w.note(track, start + i * 0.5 + 0.25, 0.1, 42, 45)
			w.note(track, start + 3.5, 0.2, 46, 55)
			w.note(track, start + 1.75, 0.1, 76, 60)
		"attack":  # hard and fast
			for beat: float in [0.0, 0.75, 2.0, 2.75]:
				w.note(track, start + beat, 0.1, 36, 110)
			for beat: float in [1.0, 3.0]:
				w.note(track, start + beat, 0.1, 38, 105)
			for i in 8:
				w.note(track, start + i * 0.5, 0.1, 42, 60)
			w.note(track, start + 1.75, 0.2, 46, 60)
		"march":  # big and proud
			for beat: float in [0.0, 2.0, 2.5]:
				w.note(track, start + beat, 0.1, 36, 105)
			for beat: float in [1.0, 3.0]:
				w.note(track, start + beat, 0.1, 38, 100)
			for i in 8:
				w.note(track, start + i * 0.5, 0.1, 42, 50)
	if fill:
		for i in 4:
			w.note(track, start + 3.0 + i * 0.25, 0.1, 38, 70 + i * 12)
