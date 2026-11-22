class_name MidiFile
extends RefCounted
## Reads a standard MIDI file (type 0 or 1) and turns it into a list of notes with times in seconds.
## MusicPlayer plays that list. Godot cannot read .mid files by itself, so this does it.
##
##     var song := MidiFile.load_file("res://audio/music/garden.mid")
##     song.notes     # every note: {time, duration, channel, note, velocity, program, volume}
##     song.length    # how long the song is, in seconds

## Every note, sorted by start time. time and duration are in seconds.
## channel is 0 to 15 (9 = drums). program is the instrument (0 to 127). volume is 0 to 1.
var notes: Array[Dictionary] = []
## The length of the song in seconds (where it loops back to the start).
var length: float = 0.0
## How many ticks make one beat in the file.
var ticks_per_beat: int = 480

var _bytes: PackedByteArray
var _pos: int = 0


## Reads a .mid file from disk (res:// or user://). Returns null if it is missing or broken.
static func load_file(path: String) -> MidiFile:
	if not FileAccess.file_exists(path):
		return null
	return parse(FileAccess.get_file_as_bytes(path))


## Reads the bytes of a .mid file. Returns null if they are not a MIDI file.
static func parse(bytes: PackedByteArray) -> MidiFile:
	var song := MidiFile.new()
	if not song._read(bytes):
		return null
	return song


# Kinds of event while reading. Lower comes first when two happen at the same tick.
const _TEMPO: int = 0
const _CONTROL: int = 1
const _NOTE_OFF: int = 2
const _NOTE_ON: int = 3
const _END: int = 4


func _read(bytes: PackedByteArray) -> bool:
	_bytes = bytes
	_pos = 0
	if bytes.size() < 14 or _text(4) != "MThd":
		return false
	_pos = 8
	_read_u16()  # the file type (0 or 1): both are read the same way
	var track_count: int = _read_u16()
	var division: int = _read_u16()
	ticks_per_beat = division if division < 0x8000 else 480
	var events: Array[Dictionary] = []
	for i in track_count:
		if _pos + 8 > _bytes.size():
			break
		var chunk_id: String = _text(4)
		var size: int = _read_u32()
		var end: int = mini(_pos + size, _bytes.size())
		if chunk_id == "MTrk":
			_read_track(end, events)
		_pos = end
	_build(events)
	return not notes.is_empty()


## Reads one track's events into the list (ticks only so far, no seconds).
func _read_track(end: int, events: Array[Dictionary]) -> void:
	var tick: int = 0
	var status: int = 0
	while _pos < end:
		tick += _read_variable()
		if _pos >= end:
			break
		var first: int = _bytes[_pos]
		if first >= 0x80:
			status = first
			_pos += 1
		# (Otherwise it is "running status": the same kind of message as the last one.)
		if status == 0xFF:
			var meta_type: int = _bytes[_pos]
			_pos += 1
			var meta_size: int = _read_variable()
			if meta_type == 0x51 and meta_size == 3:
				var micros: int = (_bytes[_pos] << 16) | (_bytes[_pos + 1] << 8) | _bytes[_pos + 2]
				events.append({"tick": tick, "kind": _TEMPO, "micros": micros})
			elif meta_type == 0x2F:
				events.append({"tick": tick, "kind": _END})
			_pos += meta_size
		elif status == 0xF0 or status == 0xF7:
			_pos += _read_variable()
		else:
			var channel: int = status & 0x0F
			var message: int = status & 0xF0
			var size: int = 1 if (message == 0xC0 or message == 0xD0) else 2
			var a: int = _bytes[_pos] if _pos < end else 0
			var b: int = _bytes[_pos + 1] if size == 2 and _pos + 1 < end else 0
			_pos += size
			match message:
				0x90:
					if b > 0:
						events.append({"tick": tick, "kind": _NOTE_ON, "channel": channel, "note": a, "velocity": b})
					else:
						events.append({"tick": tick, "kind": _NOTE_OFF, "channel": channel, "note": a})
				0x80:
					events.append({"tick": tick, "kind": _NOTE_OFF, "channel": channel, "note": a})
				0xC0:
					events.append({"tick": tick, "kind": _CONTROL, "channel": channel, "program": a})
				0xB0:
					if a == 7:
						events.append({"tick": tick, "kind": _CONTROL, "channel": channel, "volume": b})


## Puts all the tracks together in time order and works out each note's time in seconds.
func _build(events: Array[Dictionary]) -> void:
	for i in events.size():
		events[i]["seq"] = i
	events.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a["tick"] != b["tick"]:
			return a["tick"] < b["tick"]
		if a["kind"] != b["kind"]:
			return a["kind"] < b["kind"]
		return a["seq"] < b["seq"])
	# The tempo changes, so ticks can be turned into seconds.
	var tempo_ticks: Array[int] = [0]
	var tempo_seconds: Array[float] = [0.0]
	var tempo_micros: Array[int] = [500000]
	for event: Dictionary in events:
		if event["kind"] == _TEMPO:
			var last: int = tempo_ticks.size() - 1
			var seconds: float = tempo_seconds[last] + float(event["tick"] - tempo_ticks[last]) * tempo_micros[last] / 1000000.0 / ticks_per_beat
			if event["tick"] == tempo_ticks[last]:
				tempo_micros[last] = event["micros"]
			else:
				tempo_ticks.append(event["tick"])
				tempo_seconds.append(seconds)
				tempo_micros.append(event["micros"])
	var programs: Array[int] = []
	var volumes: Array[float] = []
	for i in 16:
		programs.append(-1)
		volumes.append(1.0)
	var open: Dictionary = {}  # "channel:note" -> list of notes still sounding
	var end_tick: int = 0
	var last_off_tick: int = 0
	for event: Dictionary in events:
		var tick: int = event["tick"]
		match event["kind"]:
			_CONTROL:
				if event.has("program"):
					programs[event["channel"]] = event["program"]
				else:
					volumes[event["channel"]] = event["volume"] / 127.0
			_NOTE_ON:
				var note: Dictionary = {
					"time": _seconds(tick, tempo_ticks, tempo_seconds, tempo_micros), "duration": 0.0,
					"channel": event["channel"], "note": event["note"], "velocity": event["velocity"],
					"program": programs[event["channel"]], "volume": volumes[event["channel"]], "tick": tick}
				var key: String = "%d:%d" % [event["channel"], event["note"]]
				if not open.has(key):
					open[key] = []
				open[key].append(note)
				notes.append(note)
			_NOTE_OFF:
				var key: String = "%d:%d" % [event["channel"], event["note"]]
				if open.has(key) and not (open[key] as Array).is_empty():
					var note: Dictionary = (open[key] as Array).pop_front()
					note["duration"] = maxf(_seconds(tick, tempo_ticks, tempo_seconds, tempo_micros) - note["time"], 0.01)
					last_off_tick = maxi(last_off_tick, tick)
			_END:
				end_tick = maxi(end_tick, tick)
	var song_end: float = _seconds(maxi(end_tick, last_off_tick), tempo_ticks, tempo_seconds, tempo_micros)
	# Notes that never got a note-off ring until the end.
	for ringing: Dictionary in notes:
		if ringing["duration"] <= 0.0:
			ringing["duration"] = maxf(song_end - ringing["time"], 0.05)
	length = song_end


func _seconds(tick: int, tempo_ticks: Array[int], tempo_seconds: Array[float], tempo_micros: Array[int]) -> float:
	var index: int = tempo_ticks.size() - 1
	while index > 0 and tempo_ticks[index] > tick:
		index -= 1
	return tempo_seconds[index] + float(tick - tempo_ticks[index]) * tempo_micros[index] / 1000000.0 / ticks_per_beat


func _text(count: int) -> String:
	var text: String = _bytes.slice(_pos, _pos + count).get_string_from_ascii()
	_pos += count
	return text


func _read_u16() -> int:
	var value: int = (_bytes[_pos] << 8) | _bytes[_pos + 1]
	_pos += 2
	return value


func _read_u32() -> int:
	var value: int = (_bytes[_pos] << 24) | (_bytes[_pos + 1] << 16) | (_bytes[_pos + 2] << 8) | _bytes[_pos + 3]
	_pos += 4
	return value


## MIDI's 1 to 4 byte number: 7 bits at a time, top bit set means "more follows".
func _read_variable() -> int:
	var value: int = 0
	for i in 4:
		if _pos >= _bytes.size():
			break
		var byte: int = _bytes[_pos]
		_pos += 1
		value = (value << 7) | (byte & 0x7F)
		if byte < 0x80:
			break
	return value
