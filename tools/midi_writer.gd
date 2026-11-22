extends RefCounted
## A tiny writer for standard MIDI files (SMF type 1, 480 ticks per beat).
## tools/make_music.gd uses it to write the songs in res://audio/music.
##
##     var w := MidiWriter.new(130.0)                  # 130 beats per minute
##     var lead := w.add_track("Lead", 0, 80)          # name, channel (0 = channel 1), instrument
##     w.note(lead, 0.0, 1.0, 72, 90)                  # track, start beat, length in beats, note, loudness
##     w.end_at(96.0)                                  # the song is 96 beats long
##     w.save("res://audio/music/song.mid")

## How many ticks make one beat.
const TICKS_PER_BEAT: int = 480

var bpm: float = 120.0
var _end_beat: float = 0.0
## Each track: {"name", "channel", "program", "volume", "events"}. An event is [tick, order, bytes].
var _tracks: Array[Dictionary] = []


func _init(tempo: float = 120.0) -> void:
	bpm = tempo


## Adds a track. channel is 0 to 15 (so 9 is the drums, "channel 10"). Returns the track number.
func add_track(track_name: String, channel: int, program: int, volume: int = 100) -> int:
	_tracks.append({"name": track_name, "channel": channel, "program": program, "volume": volume, "events": []})
	return _tracks.size() - 1


## One note. start and length are in beats, velocity is how hard it is hit (1 to 127).
func note(track: int, start: float, length: float, pitch: int, velocity: int = 90) -> void:
	var info: Dictionary = _tracks[track]
	var on_tick: int = roundi(start * TICKS_PER_BEAT)
	var off_tick: int = on_tick + maxi(1, roundi(length * TICKS_PER_BEAT))
	var channel: int = info["channel"]
	var events: Array = info["events"]
	# Note off sorts before note on at the same tick, so repeated notes stay clean.
	events.append([off_tick, 0, PackedByteArray([0x80 | channel, pitch, 0])])
	events.append([on_tick, 1, PackedByteArray([0x90 | channel, pitch, clampi(velocity, 1, 127)])])
	_end_beat = maxf(_end_beat, start + length)


## Where the song ends, in beats. Loops come back round to the start from here.
func end_at(beats: float) -> void:
	_end_beat = maxf(_end_beat, beats)


func save(path: String) -> Error:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_buffer(to_bytes())
	file.close()
	return OK


func to_bytes() -> PackedByteArray:
	var end_tick: int = roundi(_end_beat * TICKS_PER_BEAT)
	var out := PackedByteArray()
	out.append_array("MThd".to_ascii_buffer())
	out.append_array(_u32(6))
	out.append_array(_u16(1))  # type 1: several tracks played together
	out.append_array(_u16(_tracks.size() + 1))
	out.append_array(_u16(TICKS_PER_BEAT))
	out.append_array(_track_chunk(_conductor_events(end_tick)))
	for info: Dictionary in _tracks:
		out.append_array(_track_chunk(_track_events(info, end_tick)))
	return out


## The first track holds the tempo and the time signature (4/4).
func _conductor_events(end_tick: int) -> Array:
	var micros: int = roundi(60000000.0 / bpm)
	var tempo := PackedByteArray([0xFF, 0x51, 0x03, (micros >> 16) & 0xFF, (micros >> 8) & 0xFF, micros & 0xFF])
	var events: Array = []
	events.append([0, 0, _name_event("Fart Man")])
	events.append([0, 1, tempo])
	events.append([0, 2, PackedByteArray([0xFF, 0x58, 0x04, 4, 2, 24, 8])])
	events.append([end_tick, 9, PackedByteArray([0xFF, 0x2F, 0x00])])
	return events


func _track_events(info: Dictionary, end_tick: int) -> Array:
	var channel: int = info["channel"]
	var events: Array = []
	events.append([0, -2, _name_event(info["name"])])
	events.append([0, -1, PackedByteArray([0xC0 | channel, int(info["program"])])])
	events.append([0, -1, PackedByteArray([0xB0 | channel, 7, int(info["volume"])])])
	events.append_array(info["events"])
	events.append([end_tick, 9, PackedByteArray([0xFF, 0x2F, 0x00])])
	return events


func _name_event(text: String) -> PackedByteArray:
	var bytes := PackedByteArray([0xFF, 0x03, text.length()])
	bytes.append_array(text.to_ascii_buffer())
	return bytes


## Sorts the events by time, then writes each with the gap since the one before it.
func _track_chunk(events: Array) -> PackedByteArray:
	events.sort_custom(func(a: Array, b: Array) -> bool:
		return a[0] < b[0] if a[0] != b[0] else a[1] < b[1])
	var body := PackedByteArray()
	var last_tick: int = 0
	for event: Array in events:
		var tick: int = event[0]
		body.append_array(_variable_length(tick - last_tick))
		body.append_array(event[2])
		last_tick = tick
	var chunk := PackedByteArray()
	chunk.append_array("MTrk".to_ascii_buffer())
	chunk.append_array(_u32(body.size()))
	chunk.append_array(body)
	return chunk


## MIDI's way of writing a number in 1 to 4 bytes (7 bits at a time).
func _variable_length(value: int) -> PackedByteArray:
	var bytes := PackedByteArray([value & 0x7F])
	value >>= 7
	while value > 0:
		bytes.insert(0, (value & 0x7F) | 0x80)
		value >>= 7
	return bytes


func _u32(value: int) -> PackedByteArray:
	return PackedByteArray([(value >> 24) & 0xFF, (value >> 16) & 0xFF, (value >> 8) & 0xFF, value & 0xFF])


func _u16(value: int) -> PackedByteArray:
	return PackedByteArray([(value >> 8) & 0xFF, value & 0xFF])
