extends SceneTree
## Makes the game's little retro sound effects (beeps, slides, noise bursts, in the style of sfxr)
## and saves each one as a small WAV file in res://audio/sfx. Run it again any time:
##     godot --headless --script res://tools/make_sfx.gd
## Then open the project once (or run `godot --headless --import`) so Godot notices the new files.
## Every sound is built from a few simple pieces:
##   _tone  = a beep that can slide from one pitch to another (sine, square, triangle or saw)
##   _hiss  = noise, soft (low-pass) or sharp (high-pass)
##   _shape = fades a sound in and out so it doesn't click
##   _mix and _join = lay sounds on top of each other, or one after another

const RATE: int = 22050
const OUT_DIR: String = "res://audio/sfx/"

var _random := RandomNumberGenerator.new()
var _made: int = 0


func _init() -> void:
	_random.seed = 20261122
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	_pickups()
	_enemies()
	_bosses()
	_things()
	_menus()
	_fire_burp_pieces()
	_super_boost()
	print("made %d sound files" % _made)
	quit()


# ------------------------------------------------------------------ the sounds

func _pickups() -> void:
	# Bean: a bright two-note bling.
	_save("bean_pickup", _join([
		_shape(_tone("square", 1175.0, 1175.0, 0.05, 0.5, 0.25), 0.001, 1.0),
		_shape(_tone("square", 1760.0, 1760.0, 0.16, 0.5, 0.25), 0.001, 2.0)]))
	# Golden Bean: a little fanfare going up, with a sparkle on top.
	var notes: Array[float] = [1047.0, 1319.0, 1568.0, 2093.0]
	var fanfare: Array[PackedFloat32Array] = []
	for i in notes.size():
		var last: bool = i == notes.size() - 1
		fanfare.append(_shape(_tone("square", notes[i], notes[i], 0.32 if last else 0.07, 0.5, 0.25, 9.0 if last else 0.0, 0.01), 0.002, 1.5))
	_save("golden_bean", _mix([_join(fanfare), _shape(_hiss(0.5, 0.9, true, 0.15), 0.1, 2.0)]))
	# Chilli pepper: a sizzle, crackling, with a hot whoosh.
	var sizzle: PackedFloat32Array = _crackle(_shape(_hiss(0.55, 0.9, true, 0.8), 0.02, 1.2), 0.012)
	_save("chilli_sizzle", _mix([sizzle, _shape(_tone("saw", 250.0, 900.0, 0.45, 0.25), 0.05, 1.5)]))
	# Mega Bean Can: glug, glug, glug.
	var glugs: Array[PackedFloat32Array] = []
	for pitch: float in [260.0, 330.0, 230.0]:
		glugs.append(_shape(_tone("sine", pitch, pitch * 1.7, 0.1), 0.005, 1.5))
		glugs.append(_silence(0.04))
	_save("mega_can_glug", _mix([_join(glugs), _shape(_hiss(0.55, 0.12, false, 0.3), 0.05, 1.0)]))
	# Rocket burrito: blast off.
	_save("burrito_blast", _mix([
		_shape(_hiss(0.8, 0.2, false, 0.8), 0.25, 1.0),
		_shape(_tone("saw", 100.0, 420.0, 0.7, 0.3), 0.1, 1.0)]))
	# Landing in the landing zone: ta-daa.
	var tada: Array[PackedFloat32Array] = [
		_shape(_tone("square", 523.0, 523.0, 0.08, 0.4, 0.25), 0.002, 1.0),
		_shape(_tone("square", 659.0, 659.0, 0.08, 0.4, 0.25), 0.002, 1.0),
		_shape(_mix([_tone("square", 784.0, 784.0, 0.4, 0.4, 0.25), _tone("square", 1047.0, 1047.0, 0.4, 0.3, 0.25)]), 0.002, 1.5)]
	_save("landing_tada", _join(tada))


func _enemies() -> void:
	# Squash: a wet splat.
	_save("squash", _mix([_shape(_hiss(0.14, 0.35), 0.001, 3.0), _shape(_tone("sine", 320.0, 70.0, 0.16), 0.001, 2.0)]))
	# Burpling: a splat with a tiny burp on the end.
	var burp: PackedFloat32Array = _shape(_tone("saw", 150.0, 85.0, 0.2, 0.5, 0.5, 28.0, 0.25), 0.01, 1.5)
	_save("burpling_squish", _mix([
		_shape(_hiss(0.14, 0.35), 0.001, 3.0), _shape(_tone("sine", 320.0, 70.0, 0.16), 0.001, 2.0),
		_delay(burp, 0.06)]))
	# Hiccup: HIC! (a quick squeak up, then a little drop).
	_save("hiccup_hop", _join([
		_shape(_tone("square", 500.0, 1300.0, 0.05, 0.5, 0.25), 0.001, 1.0),
		_shape(_tone("square", 1300.0, 850.0, 0.07, 0.5, 0.25), 0.001, 1.5)]))
	# Gnome: a grumpy "hmph" and a whoosh as the pie flies.
	_save("gnome_throw", _join([
		_shape(_tone("saw", 190.0, 120.0, 0.14, 0.6, 0.5, 14.0, 0.05), 0.01, 1.2),
		_shape(_hiss(0.22, 0.2), 0.08, 1.2)]))
	# Mud pie: splodge.
	_save("mud_splat", _mix([_shape(_hiss(0.22, 0.1), 0.002, 2.5), _shape(_tone("sine", 130.0, 45.0, 0.18), 0.002, 2.0)]))
	# Crow: caw, caw.
	var caw: PackedFloat32Array = _shape(_mix([_tone("saw", 720.0, 430.0, 0.13, 0.6, 0.5, 48.0, 0.07), _hiss(0.13, 0.5, true, 0.08)]), 0.01, 1.3)
	_save("crow_caw", _join([caw, _silence(0.05), _gain(caw, 0.8)]))
	# Cork Bot: a low rumble of wheels, and a pop when it is squashed.
	var rumble: PackedFloat32Array = _hiss(0.32, 0.05, false, 0.9)
	for i in rumble.size():
		rumble[i] *= 0.65 + 0.35 * sin(TAU * 13.0 * float(i) / RATE)
	_save("cork_roll", _mix([_shape(rumble, 0.05, 0.8), _shape(_tone("sine", 70.0, 60.0, 0.32), 0.05, 1.0)]))
	_save("cork_pop", _mix([_shape(_tone("sine", 1200.0, 190.0, 0.1), 0.001, 3.0), _shape(_hiss(0.02, 0.9, true, 0.8), 0.0, 1.0)]))
	# Fizz Bat: flap, flap.
	var flap: PackedFloat32Array = _shape(_hiss(0.1, 0.25), 0.035, 1.0)
	_save("bat_flap", _mix([flap, _delay(_gain(flap, 0.8), 0.13)]))


func _bosses() -> void:
	# Sneezy Weezy winds up: aaah... aaah...
	var ah1: PackedFloat32Array = _shape(_mix([_tone("saw", 250.0, 520.0, 0.4, 0.5, 0.5, 8.0, 0.03), _tone("tri", 500.0, 1040.0, 0.4, 0.3)]), 0.15, 0.8)
	var ah2: PackedFloat32Array = _shape(_mix([_tone("saw", 280.0, 640.0, 0.42, 0.5, 0.5, 8.0, 0.03), _tone("tri", 560.0, 1280.0, 0.42, 0.3)]), 0.15, 0.8)
	_save("sneeze_windup", _join([ah1, _silence(0.12), ah2]))
	# ...ACHOO!
	_save("sneeze_achoo", _mix([_shape(_hiss(0.38, 0.6), 0.004, 2.0), _shape(_tone("saw", 760.0, 190.0, 0.3, 0.5), 0.004, 2.0)]))
	# Colonel Cork snorts (three puffs).
	var snort: PackedFloat32Array = _mix([_shape(_hiss(0.15, 0.25), 0.02, 1.5), _shape(_tone("sine", 95.0, 70.0, 0.15), 0.01, 1.0)])
	_save("cork_snort", _join([snort, _silence(0.07), snort, _silence(0.07), snort]))
	# BONK on the wall.
	_save("cork_bonk", _mix([
		_shape(_tone("sine", 170.0, 45.0, 0.28), 0.001, 3.0),
		_shape(_hiss(0.04, 0.9, true, 0.8), 0.0, 1.0),
		_delay(_shape(_tone("square", 880.0, 860.0, 0.12, 0.4), 0.001, 3.0), 0.02),
		_delay(_shape(_tone("sine", 500.0, 800.0, 0.2, 0.4, 0.5, 20.0, 0.1), 0.01, 1.5), 0.2)]))
	# A cork pops out of his hat.
	_save("cork_shot", _mix([
		_shape(_tone("sine", 900.0, 260.0, 0.08), 0.001, 3.0),
		_delay(_shape(_hiss(0.25, 0.5, true, 0.25), 0.1, 1.0), 0.05)]))
	# A boss gets stomped: ow!
	_save("boss_hit", _mix([_shape(_tone("square", 520.0, 240.0, 0.25, 0.5, 0.5, 15.0, 0.08), 0.005, 1.5), _shape(_hiss(0.08, 0.7), 0.0, 2.0)]))
	# A boss is beaten: a silly sliding-down tune, then a big "bwoop".
	var down: Array[PackedFloat32Array] = []
	for pitch: float in [784.0, 659.0, 523.0, 392.0]:
		down.append(_shape(_tone("square", pitch, pitch, 0.11, 0.4, 0.25), 0.002, 1.0))
	down.append(_shape(_tone("sine", 200.0, 800.0, 0.35, 0.6, 0.5, 10.0, 0.05), 0.01, 1.2))
	_save("boss_defeat", _join(down))


func _things() -> void:
	# Springs and bounce pads: boing.
	var boing: PackedFloat32Array = _join([
		_shape(_tone("sine", 180.0, 620.0, 0.1), 0.003, 0.5),
		_shape(_tone("sine", 620.0, 330.0, 0.35, 0.6, 0.5, 22.0, 0.12), 0.003, 1.5)])
	_save("boing", boing)
	_save("mega_boing", _join([
		_shape(_tone("sine", 150.0, 900.0, 0.12), 0.003, 0.5),
		_shape(_tone("sine", 900.0, 340.0, 0.55, 0.6, 0.5, 18.0, 0.18), 0.003, 1.5)]))
	# Toilet: flush.
	_save("flush", _mix([
		_shape(_hiss(0.85, 0.2), 0.15, 0.7),
		_delay(_shape(_tone("sine", 220.0, 110.0, 0.35, 0.5, 0.5, 12.0, 0.2), 0.02, 1.0), 0.5)]))
	# Bean Can opening: pop, then beans rattling out.
	var rattle: PackedFloat32Array = _crackle(_shape(_hiss(0.55, 0.6, true, 0.9), 0.0, 2.0), 0.02)
	_save("can_open", _mix([_shape(_tone("sine", 700.0, 170.0, 0.12), 0.001, 2.5), _delay(rattle, 0.06)]))
	# Hoops and smoke rings: ding.
	_save("hoop_ding", _shape(_mix([_tone("sine", 1760.0, 1760.0, 0.5), _tone("sine", 2349.0, 2349.0, 0.5, 0.5), _tone("sine", 3520.0, 3520.0, 0.5, 0.25)]), 0.002, 3.0))
	_save("ring_ding", _shape(_mix([_tone("sine", 1319.0, 1319.0, 0.45), _tone("sine", 1976.0, 1976.0, 0.45, 0.4)]), 0.002, 3.0))
	# Roof fan switches on: whoosh.
	_save("fan_whoosh", _mix([_shape(_hiss(0.85, 0.15), 0.3, 1.2), _shape(_tone("sine", 120.0, 140.0, 0.85, 0.2), 0.3, 1.0)]))
	# Spark cable: zap.
	var zap: PackedFloat32Array = _mix([_tone("saw", 1200.0, 200.0, 0.3, 0.6), _tone("saw", 900.0, 100.0, 0.3, 0.5), _hiss(0.3, 0.9, true, 0.3)])
	for i in zap.size():
		zap[i] *= 1.0 if int(float(i) / RATE * 90.0 * 2.0) % 2 == 0 else 0.35
	_save("zap", _shape(zap, 0.002, 1.2))
	# Steam: pssshhh.
	_save("steam_hiss", _shape(_hiss(0.6, 0.75, true, 0.7), 0.05, 1.5))
	# Stamp press: THUMP and a clank.
	_save("stamp_thump", _mix([
		_shape(_tone("sine", 115.0, 34.0, 0.3), 0.001, 3.0),
		_shape(_hiss(0.12, 0.1), 0.001, 2.0),
		_shape(_tone("square", 310.0, 300.0, 0.05, 0.3), 0.001, 2.0)]))
	# Crumble platform: crack and rumble.
	_save("crumble_crack", _mix([
		_crackle(_shape(_hiss(0.35, 0.9, true, 0.9), 0.0, 1.5), 0.015),
		_shape(_hiss(0.35, 0.06, false, 0.8), 0.02, 2.0)]))
	# Switch button: ka-chunk.
	_save("switch_click", _join([
		_mix([_shape(_tone("square", 1500.0, 1400.0, 0.02, 0.6), 0.0, 2.0), _shape(_hiss(0.02, 0.9, true, 0.5), 0.0, 1.0)]),
		_silence(0.04),
		_mix([_shape(_tone("square", 800.0, 700.0, 0.04, 0.6), 0.0, 2.0), _shape(_tone("sine", 200.0, 120.0, 0.05), 0.0, 1.0)])]))
	# Barrel cannon: a clunk as he climbs in, a boom as he is fired.
	_save("barrel_load", _mix([_shape(_tone("sine", 210.0, 90.0, 0.1), 0.001, 2.0), _shape(_hiss(0.05, 0.2), 0.0, 2.0)]))
	_save("cannon_boom", _mix([_shape(_tone("sine", 95.0, 28.0, 0.5), 0.001, 2.5), _shape(_hiss(0.5, 0.08), 0.001, 2.0)]))
	# Warp pipe: bloop-bloop.
	_save("warp_whoosh", _join([
		_shape(_tone("sine", 700.0, 180.0, 0.25, 0.6, 0.5, 14.0, 0.05), 0.005, 1.0),
		_shape(_tone("sine", 180.0, 520.0, 0.2, 0.6, 0.5, 14.0, 0.05), 0.005, 1.0)]))


func _menus() -> void:
	_save("menu_move", _shape(_tone("square", 1000.0, 1000.0, 0.035), 0.001, 1.0))
	_save("menu_accept", _join([
		_shape(_tone("square", 660.0, 660.0, 0.06, 0.5, 0.25), 0.001, 1.0),
		_shape(_tone("square", 990.0, 990.0, 0.11, 0.5, 0.25), 0.001, 2.0)]))
	_save("pause_open", _shape(_tone("square", 450.0, 900.0, 0.14, 0.5, 0.25), 0.002, 1.5))
	_save("pause_close", _shape(_tone("square", 900.0, 450.0, 0.14, 0.5, 0.25), 0.002, 1.5))


## Two sounds for the Fire Burp power-up another helper is building. Not hooked up here.
func _fire_burp_pieces() -> void:
	var flames: PackedFloat32Array = _crackle(_shape(_hiss(0.5, 0.5, true, 0.5), 0.02, 1.5), 0.02)
	_save("fire_burp", _mix([
		_shape(_tone("saw", 125.0, 70.0, 0.5, 0.6, 0.5, 25.0, 0.2), 0.01, 1.2),
		_shape(_hiss(0.5, 0.3, false, 0.6), 0.05, 1.5),
		flames]))
	_save("fireball_pop", _mix([
		_shape(_tone("sine", 1000.0, 300.0, 0.08), 0.001, 2.5),
		_shape(_hiss(0.2, 0.7, true, 0.5), 0.005, 2.0),
		_shape(_tone("saw", 300.0, 600.0, 0.15, 0.3), 0.01, 1.5)]))


## The SUPER BOOST: a big rushing whoosh that swells up while a bright note slides high.
func _super_boost() -> void:
	_save("super_boost", _mix([
		_shape(_hiss(0.9, 0.7, true, 0.7), 0.35, 1.3),
		_shape(_tone("saw", 110.0, 440.0, 0.9, 0.5, 0.5, 9.0, 0.04), 0.3, 1.4),
		_shape(_tone("sine", 300.0, 1500.0, 0.8, 0.4), 0.2, 1.8)]))


# ------------------------------------------------------------------ the building blocks

## A beep. Slides from pitch f0 to pitch f1 over dur seconds. wave = "sine", "square", "tri" or "saw".
## duty = how thin a square wave is. vib_rate / vib_depth = a wobble (hertz, and how much).
func _tone(wave: String, f0: float, f1: float, dur: float, volume: float = 0.8, duty: float = 0.5,
		vib_rate: float = 0.0, vib_depth: float = 0.0) -> PackedFloat32Array:
	var count: int = int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(count)
	var phase: float = 0.0
	for i in count:
		var t: float = float(i) / float(count)
		var freq: float = f0 * pow(f1 / f0, t)
		if vib_depth > 0.0:
			freq *= 1.0 + vib_depth * sin(TAU * vib_rate * float(i) / RATE)
		phase = fmod(phase + freq / RATE, 1.0)
		var s: float
		match wave:
			"square":
				s = 1.0 if phase < duty else -1.0
			"tri":
				s = absf(phase - 0.5) * 4.0 - 1.0
			"saw":
				s = phase * 2.0 - 1.0
			_:
				s = sin(phase * TAU)
		out[i] = s * volume
	return out


## Noise. softness: 1 = harsh white noise, near 0 = a dull rumble.
## sharp = take the low rumble out, so it hisses.
func _hiss(dur: float, softness: float = 1.0, sharp: bool = false, volume: float = 0.8) -> PackedFloat32Array:
	var count: int = int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(count)
	var low: float = 0.0
	for i in count:
		var white: float = _random.randf_range(-1.0, 1.0)
		low += softness * (white - low)
		out[i] = (white - low if sharp else low) * volume
	return out


## Fades a sound in over "attack" seconds and out to nothing at the end.
## curve: 1 = straight fade, 3 = drops away fast.
func _shape(sound: PackedFloat32Array, attack: float = 0.005, curve: float = 1.5) -> PackedFloat32Array:
	var out := sound.duplicate()
	var count: int = out.size()
	var attack_samples: int = maxi(int(attack * RATE), 1)
	for i in count:
		var fade_in: float = minf(float(i) / attack_samples, 1.0)
		out[i] *= fade_in * pow(1.0 - float(i) / count, curve)
	return out


## Chops a sound into tiny crackly bursts (about every "gap" seconds).
func _crackle(sound: PackedFloat32Array, gap: float) -> PackedFloat32Array:
	var out := sound.duplicate()
	var step: int = maxi(int(gap * RATE), 1)
	var i: int = 0
	while i < out.size():
		var keep: bool = _random.randf() < 0.55
		for j in range(i, mini(i + step, out.size())):
			out[j] *= 1.0 if keep else 0.0
		i += step
	return out


func _silence(dur: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(int(dur * RATE))
	return out


func _gain(sound: PackedFloat32Array, amount: float) -> PackedFloat32Array:
	var out := sound.duplicate()
	for i in out.size():
		out[i] *= amount
	return out


## Starts a sound later, by putting quiet in front of it.
func _delay(sound: PackedFloat32Array, seconds: float) -> PackedFloat32Array:
	var out := _silence(seconds)
	out.append_array(sound)
	return out


## Plays sounds one after another.
func _join(sounds: Array[PackedFloat32Array]) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	for sound in sounds:
		out.append_array(sound)
	return out


## Plays sounds at the same time.
func _mix(sounds: Array[PackedFloat32Array]) -> PackedFloat32Array:
	var count: int = 0
	for sound in sounds:
		count = maxi(count, sound.size())
	var out := PackedFloat32Array()
	out.resize(count)
	for sound in sounds:
		for i in sound.size():
			out[i] += sound[i]
	return out


## Turns the sound into a 16-bit WAV file. Every sound is made equally loud (the game turns them up or down).
func _save(sound_name: String, sound: PackedFloat32Array) -> void:
	var peak: float = 0.0
	for s in sound:
		peak = maxf(peak, absf(s))
	var scale: float = 0.85 / peak if peak > 0.0 else 1.0
	var bytes := PackedByteArray()
	bytes.resize(sound.size() * 2)
	var tail: int = int(0.004 * RATE)  # a very short fade at the end, so it never clicks
	for i in sound.size():
		var s: float = sound[i] * scale
		if i > sound.size() - tail:
			s *= float(sound.size() - i) / tail
		bytes.encode_s16(i * 2, int(clampf(s, -1.0, 1.0) * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = bytes
	var path: String = OUT_DIR + sound_name + ".wav"
	var err: Error = wav.save_to_wav(path)
	print("%s: %.2f s, %s" % [path, float(sound.size()) / RATE, error_string(err)])
	_made += 1
