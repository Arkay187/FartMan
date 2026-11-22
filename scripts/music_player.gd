class_name MusicPlayer
extends Node
## Plays the songs in res://audio/music (real .mid files) with a tiny chiptune synthesizer.
## Godot can't play MIDI by itself, so this reads the notes (MidiFile) and makes the sound:
## square waves for the tune, a triangle wave for the bass, noise for the drums. It loops forever.
##
## Use it from any script, in one line (it keeps playing when the scene changes):
##     MusicPlayer.play_song(self, "garden")
## Asking for the song that is already playing does nothing, so it never restarts by mistake.

## The sound card speed. 22050 is plenty for beepy music and cheap to make.
const MIX_RATE: int = 22050
## How many notes can sound at once. Extra ones steal the oldest.
const MAX_VOICES: int = 16
## The folder the songs live in.
const SONG_DIR: String = "res://audio/music/"

## What kind of sound a voice makes.
const _FREE: int = 0
const _PULSE: int = 1
const _TRIANGLE: int = 2
const _KICK: int = 3
const _SNARE: int = 4
const _HAT: int = 5
const _CLANK: int = 6

## Samples per piece. Loudness is worked out once per piece, not once per sample (it is faster).
const _CHUNK: int = 32
## A note fades in over this many samples (stops clicks), and fades out over _RELEASE after it ends.
const _ATTACK: float = 90.0
const _RELEASE: float = 700.0

@export_group("Loudness")
## Loudness in decibels. The voice recordings are 0, so the music sits well under them.
@export var volume_db: float = -10.0
## How much quieter it gets while the game is paused.
@export var paused_drop_db: float = -9.0
## How loud each kind of sound is inside the mix (0 to 1).
@export var lead_gain: float = 0.16
@export var harmony_gain: float = 0.12
@export var bass_gain: float = 0.26
@export var drum_gain: float = 0.30

@export_group("Playing")
## 1 = the speed in the file. 1.15 = a bit faster (flying stages).
@export var speed: float = 1.0:
	set(value):
		value = clampf(value, 0.25, 4.0)
		# Stay at the same place in the song when the speed changes.
		var place: float = float(_clock) / float(_loop_samples) if _loop_samples > 0 else 0.0
		speed = value
		if _count > 0:
			_rebuild_times()
			_clock = int(place * _loop_samples)
			_next = 0
			while _next < _count and _note_start[_next] < _clock:
				_next += 1
## How much sound is made ahead of time, in seconds. More = safer on a slow PC, but slower to react.
@export var lead_time: float = 0.2
## Music on or off (the pause menu's MUSIC choice).
@export var enabled: bool = true:
	set(value):
		enabled = value
		_apply_enabled()

## The song that is playing now, like "garden". Empty = none.
var song_name: String = ""
var song: MidiFile
## True when the song has been loaded and the music is on.
var playing: bool = false
## How many times the song has gone round to the start again.
var loops_played: int = 0

var _speaker: AudioStreamPlayer
var _generator: AudioStreamGenerator
var _playback: AudioStreamGeneratorPlayback
var _silent: bool = false
var _duck: float = 0.0

# The song, as flat lists (fast to read). One entry per note.
var _count: int = 0
var _note_time: PackedFloat32Array = PackedFloat32Array()
var _note_length: PackedFloat32Array = PackedFloat32Array()
var _note_pitch: PackedInt32Array = PackedInt32Array()
var _note_channel: PackedInt32Array = PackedInt32Array()
var _note_loud: PackedFloat32Array = PackedFloat32Array()
var _note_kind: PackedInt32Array = PackedInt32Array()
var _note_start: PackedInt32Array = PackedInt32Array()  # in samples, at the current speed
var _note_hold: PackedInt32Array = PackedInt32Array()
var _loop_samples: int = 0
var _clock: int = 0
var _next: int = 0

# The voices (notes sounding right now).
var _v_kind: PackedInt32Array = PackedInt32Array()
var _v_phase: PackedFloat32Array = PackedFloat32Array()
var _v_inc: PackedFloat32Array = PackedFloat32Array()
var _v_amp: PackedFloat32Array = PackedFloat32Array()
var _v_aux: PackedFloat32Array = PackedFloat32Array()
var _v_age: PackedInt32Array = PackedInt32Array()
var _v_hold: PackedInt32Array = PackedInt32Array()
var _v_life: PackedInt32Array = PackedInt32Array()

var _mix: PackedFloat32Array = PackedFloat32Array()
var _noise: int = 12345
var _hat_last: float = 0.0


# ------------------------------------------------------------------ finding and starting

## Plays the song called "garden", "factory", "planet_whiff", "boss" or "theme".
## "from" is anything in the game. A speed other than 1 plays it faster or slower.
static func play_song(from: Node, name_of_song: String, song_speed: float = 1.0) -> MusicPlayer:
	if from == null or not from.is_inside_tree():
		return null
	var player: MusicPlayer = current(from)
	if player == null:
		player = MusicPlayer.new()
		player.name = "MusicPlayer"
		var screen_root: Window = from.get_tree().root
		screen_root.set_meta(&"music_player", player)
		screen_root.add_child.call_deferred(player)
	player.start_song(name_of_song)
	player.speed = song_speed
	return player


## The one MusicPlayer of the game, or null if none has been made yet.
static func current(from: Node) -> MusicPlayer:
	if from == null or not from.is_inside_tree():
		return null
	var screen_root: Window = from.get_tree().root
	if screen_root.has_meta(&"music_player"):
		var found: Variant = screen_root.get_meta(&"music_player")
		if is_instance_valid(found):
			return found as MusicPlayer
	return null


## Loads a song and starts it from the top. Does nothing if it is already the one playing.
func start_song(name_of_song: String) -> void:
	if name_of_song == song_name and song != null:
		return
	var loaded: MidiFile = MidiFile.load_file(SONG_DIR + name_of_song + ".mid")
	if loaded == null:
		push_warning("MusicPlayer: can't read the song %s" % name_of_song)
		return
	song_name = name_of_song
	song = loaded
	_load_notes()
	_clock = 0
	_next = 0
	for i in MAX_VOICES:
		_v_kind[i] = _FREE
	_apply_enabled()


# ------------------------------------------------------------------ the node

func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # keeps playing (quieter) while the game is paused
	_v_kind.resize(MAX_VOICES)
	_v_phase.resize(MAX_VOICES)
	_v_inc.resize(MAX_VOICES)
	_v_amp.resize(MAX_VOICES)
	_v_aux.resize(MAX_VOICES)
	_v_age.resize(MAX_VOICES)
	_v_hold.resize(MAX_VOICES)
	_v_life.resize(MAX_VOICES)


func _ready() -> void:
	_silent = DisplayServer.get_name() == "headless"
	# The pause menu's MUSIC choice is remembered by DebugOptions.
	var options := get_node_or_null("/root/DebugOptions") as DebugOptionsData
	if options != null:
		enabled = options.music_on
		options.music_changed.connect(func(on: bool) -> void: enabled = on)
	if _silent:
		_apply_enabled()
		return
	Sfx.ensure_buses()
	_generator = AudioStreamGenerator.new()
	_generator.mix_rate = MIX_RATE
	_generator.buffer_length = maxf(lead_time * 3.0, 0.5)
	_speaker = AudioStreamPlayer.new()
	_speaker.stream = _generator
	_speaker.bus = Sfx.MUSIC_BUS
	_speaker.volume_db = volume_db
	add_child(_speaker)
	_apply_enabled()


func _exit_tree() -> void:
	if _speaker != null:
		_speaker.stop()


func _process(delta: float) -> void:
	if _speaker == null or _playback == null or not playing:
		return
	# Quieter while the game is paused, with a quick fade so it isn't a jolt.
	var wanted: float = paused_drop_db if get_tree().paused else 0.0
	_duck = move_toward(_duck, wanted, 40.0 * delta)
	_speaker.volume_db = volume_db + _duck
	# Keep about lead_time seconds of sound waiting in the speaker.
	var room: int = _playback.get_frames_available()
	var waiting: int = int(_generator.buffer_length * MIX_RATE) - room
	var needed: int = mini(int(lead_time * MIX_RATE) - waiting, room)
	if needed >= 128:
		_playback.push_buffer(render(needed))


## Starts or stops the speaker to match "enabled" and whether a song is loaded.
func _apply_enabled() -> void:
	playing = enabled and song != null
	if _speaker == null:
		return
	if playing:
		if not _speaker.playing:
			_speaker.play()
			_playback = _speaker.get_stream_playback() as AudioStreamGeneratorPlayback
	else:
		_speaker.stop()
		_playback = null


## True while music is really coming out (the song is loaded and music is not turned off).
func is_audible() -> bool:
	return playing


# ------------------------------------------------------------------ the song

## Copies the notes into flat lists and decides which sound each one makes.
func _load_notes() -> void:
	_count = song.notes.size()
	_note_time.resize(_count)
	_note_length.resize(_count)
	_note_pitch.resize(_count)
	_note_channel.resize(_count)
	_note_loud.resize(_count)
	_note_kind.resize(_count)
	_note_start.resize(_count)
	_note_hold.resize(_count)
	for i in _count:
		var n: Dictionary = song.notes[i]
		var channel: int = n["channel"]
		_note_time[i] = n["time"]
		_note_length[i] = n["duration"]
		_note_pitch[i] = n["note"]
		_note_channel[i] = channel
		var kind: int = _kind_for(n["program"], channel)
		_note_kind[i] = kind
		var gain: float = drum_gain
		if kind == _PULSE:
			gain = lead_gain if channel == 0 else harmony_gain
		elif kind == _TRIANGLE:
			gain = bass_gain
		_note_loud[i] = float(n["velocity"]) / 127.0 * float(n["volume"]) * gain
	_rebuild_times()


## Which sound a note makes, from its instrument number (a rough guess for other people's MIDI files).
func _kind_for(program: int, channel: int) -> int:
	if channel == 9:
		return _KICK  # drums choose their own kind when they start (see _start_drum)
	if program < 0:
		return _TRIANGLE if channel == 2 else _PULSE
	match program >> 3:  # instruments come in families of 8
		4, 9:  # bass, pipes and flutes
			return _TRIANGLE
	return _PULSE


## The width of the square wave: 50% for tunes and brass, 25% (thinner) for the rest.
func _duty_for(program: int, channel: int) -> float:
	if program < 0:
		return 0.5 if channel == 0 else 0.25
	var family: int = program >> 3
	if family == 2 or family == 7 or family == 8 or family == 10:
		return 0.5
	return 0.25


func _rebuild_times() -> void:
	if song == null:
		return
	_loop_samples = maxi(int(song.length / speed * MIX_RATE), 1)
	for i in _count:
		_note_start[i] = int(_note_time[i] / speed * MIX_RATE)
		_note_hold[i] = int(_note_length[i] / speed * MIX_RATE)


# ------------------------------------------------------------------ making the sound

## Makes "frames" samples of music (stereo, both sides the same) and moves the song on.
## The speaker asks for this every frame. Tests call it directly, with no sound card.
func render(frames: int) -> PackedVector2Array:
	var out := PackedVector2Array()
	out.resize(frames)
	if _count == 0 or frames <= 0:
		return out
	_mix.resize(frames)
	_mix.fill(0.0)
	var done: int = 0
	while done < frames:
		var span: int = frames - done
		# Start every note that is due, and work out how long until the next one.
		while _next < _count:
			var due: int = _note_start[_next]
			if due > _clock:
				span = mini(span, due - _clock)
				break
			_start_voice(_next)
			_next += 1
		span = clampi(mini(span, _loop_samples - _clock), 1, frames)
		_mix_voices(done, span)
		_clock += span
		done += span
		if _clock >= _loop_samples:
			_clock = 0
			_next = 0
			loops_played += 1
	for i in frames:
		var s: float = clampf(_mix[i], -1.0, 1.0)
		out[i] = Vector2(s, s)
	return out


## Gives a note a voice. Drums and tunes are set up differently.
func _start_voice(index: int) -> void:
	var voice: int = _free_voice()
	var pitch: int = _note_pitch[index]
	var amp: float = _note_loud[index]
	_v_age[voice] = 0
	_v_phase[voice] = 0.0
	_v_amp[voice] = amp
	if _note_channel[index] == 9:
		_start_drum(voice, pitch, amp)
		return
	_v_kind[voice] = _note_kind[index]
	_v_inc[voice] = 440.0 * pow(2.0, (pitch - 69) / 12.0) / MIX_RATE
	_v_aux[voice] = _duty_for(song.notes[index]["program"], _note_channel[index])
	_v_hold[voice] = _note_hold[index]
	_v_life[voice] = _note_hold[index] + int(_RELEASE)


## A drum hit, chosen by its General MIDI note number.
func _start_drum(voice: int, pitch: int, amp: float) -> void:
	_v_hold[voice] = 0
	match pitch:
		35, 36:  # kick: a thump that falls in pitch
			_set_drum(voice, _KICK, 150.0, 0.99955, 6000, amp * 2.0)
		41, 43, 45, 47, 48, 50:  # toms: a lower thump the lower the note
			_set_drum(voice, _KICK, 80.0 + (pitch - 41) * 14.0, 0.9997, 5000, amp * 1.6)
		38, 39, 40:  # snare and clap: a noise burst
			_set_drum(voice, _SNARE, 190.0, 0.9993, 4200, amp * 1.4)
		42, 44, 54:  # closed hat: a tiny tick of noise
			_set_drum(voice, _HAT, 0.0, 0.9975, 1600, amp * 1.2)
		46, 51, 59:  # open hat and ride: a longer tick
			_set_drum(voice, _HAT, 0.0, 0.9996, 7000, amp * 1.0)
		49, 52, 55, 57:  # crash
			_set_drum(voice, _HAT, 0.0, 0.99985, 16000, amp * 1.3)
		56:  # cowbell: clank
			_set_drum(voice, _CLANK, 820.0, 0.9993, 3500, amp * 1.0)
		37:  # side stick: tick
			_set_drum(voice, _CLANK, 1700.0, 0.9980, 1800, amp * 1.0)
		75, 76, 77:  # claves and wood blocks: pok
			_set_drum(voice, _CLANK, 1250.0 + (pitch - 75) * 250.0, 0.9985, 2200, amp * 1.0)
		_:
			_set_drum(voice, _HAT, 0.0, 0.9990, 3000, amp * 1.0)


func _set_drum(voice: int, kind: int, frequency: float, decay: float, life: int, amp: float) -> void:
	_v_kind[voice] = kind
	_v_inc[voice] = frequency / MIX_RATE
	_v_aux[voice] = decay
	_v_life[voice] = life
	_v_amp[voice] = amp


## A free voice, or the one that has been going longest.
func _free_voice() -> int:
	var oldest: int = 0
	var oldest_age: int = -1
	for i in MAX_VOICES:
		if _v_kind[i] == _FREE:
			return i
		if _v_age[i] > oldest_age:
			oldest_age = _v_age[i]
			oldest = i
	return oldest


## Adds every sounding voice into the mix for samples start .. start + count.
func _mix_voices(start: int, count: int) -> void:
	for v in MAX_VOICES:
		var kind: int = _v_kind[v]
		if kind == _FREE:
			continue
		match kind:
			_PULSE:
				_mix_pulse(v, start, count)
			_TRIANGLE:
				_mix_triangle(v, start, count)
			_KICK:
				_mix_kick(v, start, count)
			_SNARE:
				_mix_snare(v, start, count)
			_HAT:
				_mix_hat(v, start, count)
			_CLANK:
				_mix_clank(v, start, count)
		_v_age[v] += count
		if _v_age[v] >= _v_life[v]:
			_v_kind[v] = _FREE


## How loud a held note is at this age: fades in, stays, fades out after it ends.
func _envelope(age: int, hold: int) -> float:
	if age < _ATTACK:
		return (float(age) + 16.0) / _ATTACK
	if age > hold:
		return maxf(1.0 - float(age - hold) / _RELEASE, 0.0)
	return 1.0


## A square wave (the tune and the harmony).
func _mix_pulse(v: int, start: int, count: int) -> void:
	var phase: float = _v_phase[v]
	var inc: float = _v_inc[v]
	var duty: float = _v_aux[v]
	var age: int = _v_age[v]
	var hold: int = _v_hold[v]
	var base: float = _v_amp[v]
	var k: int = start
	var stop: int = start + count
	while k < stop:
		var n: int = mini(_CHUNK, stop - k)
		var amp: float = base * _envelope(age, hold)
		for j in range(k, k + n):
			phase += inc
			if phase >= 1.0:
				phase -= 1.0
			_mix[j] += amp if phase < duty else -amp
		k += n
		age += n
	_v_phase[v] = phase


## A triangle wave (the bass): softer and rounder than a square.
func _mix_triangle(v: int, start: int, count: int) -> void:
	var phase: float = _v_phase[v]
	var inc: float = _v_inc[v]
	var age: int = _v_age[v]
	var hold: int = _v_hold[v]
	var base: float = _v_amp[v]
	var k: int = start
	var stop: int = start + count
	while k < stop:
		var n: int = mini(_CHUNK, stop - k)
		var amp: float = base * _envelope(age, hold)
		for j in range(k, k + n):
			phase += inc
			if phase >= 1.0:
				phase -= 1.0
			_mix[j] += amp * (absf(phase - 0.5) * 4.0 - 1.0)
		k += n
		age += n
	_v_phase[v] = phase


## Kick and toms: a sine wave that quickly falls in pitch.
func _mix_kick(v: int, start: int, count: int) -> void:
	var phase: float = _v_phase[v]
	var inc: float = _v_inc[v]
	var decay: float = _v_aux[v]
	var amp: float = _v_amp[v]
	for j in range(start, start + count):
		phase += inc
		inc *= decay
		amp *= decay
		_mix[j] += sin(phase * TAU) * amp
	_v_phase[v] = phase
	_v_inc[v] = inc
	_v_amp[v] = amp


## Snare and clap: a burst of noise with a little tone in it.
func _mix_snare(v: int, start: int, count: int) -> void:
	var phase: float = _v_phase[v]
	var inc: float = _v_inc[v]
	var decay: float = _v_aux[v]
	var amp: float = _v_amp[v]
	var noise: int = _noise
	for j in range(start, start + count):
		noise = (noise * 1103515245 + 12345) & 0x7FFFFFFF
		phase += inc
		amp *= decay
		var tone: float = absf(fmod(phase, 1.0) - 0.5) * 4.0 - 1.0
		_mix[j] += (float(noise >> 8) / 4194304.0 - 1.0 + tone * 0.4) * amp
	_noise = noise
	_v_phase[v] = phase
	_v_amp[v] = amp


## Hats and cymbals: noise with the low rumble taken out, so it hisses.
func _mix_hat(v: int, start: int, count: int) -> void:
	var decay: float = _v_aux[v]
	var amp: float = _v_amp[v]
	var noise: int = _noise
	var last: float = _hat_last
	for j in range(start, start + count):
		noise = (noise * 1103515245 + 12345) & 0x7FFFFFFF
		var s: float = float(noise >> 8) / 4194304.0 - 1.0
		amp *= decay
		_mix[j] += (s - last) * 0.5 * amp
		last = s
	_noise = noise
	_hat_last = last
	_v_amp[v] = amp


## Cowbell, side stick and wood blocks: a short square "clank".
func _mix_clank(v: int, start: int, count: int) -> void:
	var phase: float = _v_phase[v]
	var inc: float = _v_inc[v]
	var decay: float = _v_aux[v]
	var amp: float = _v_amp[v]
	for j in range(start, start + count):
		phase += inc
		if phase >= 1.0:
			phase -= 1.0
		amp *= decay
		_mix[j] += amp if phase < 0.5 else -amp
	_v_phase[v] = phase
	_v_amp[v] = amp
