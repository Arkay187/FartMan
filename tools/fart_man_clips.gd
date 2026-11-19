extends RefCounted
## Builds Fart Man's animation library from the Mixamo clips, cutting each one into
## the little pieces the game needs. build_scenes.gd runs this before building the player.
##
## Every clip is made IN PLACE: the game moves him with physics, so the animation must
## not also walk him forward. Floor clips are lowered or raised so his lowest toe touches
## the floor. Air clips keep his hips at standing height so tucked legs just lift.

const DIR: String = "res://art/characters/fart_man/"
const OUT: String = "res://art/characters/fart_man/fart_man_clips.res"
const HIPS: String = "mixamorig_Hips"
const TOES: Array[String] = ["mixamorig_LeftToe_End", "mixamorig_RightToe_End"]

## The recipe. Each row: game clip name, source file, start second, end second
## (-1 = to the end of the clip), loop mode, hips mode.
## Hips mode: "floor" = lowest toe sits on the floor, "air" = hips stay at standing height.
const NO: int = Animation.LOOP_NONE
const LOOP: int = Animation.LOOP_LINEAR
const PING: int = Animation.LOOP_PINGPONG
const RECIPE: Array = [
	["idle", "Idle", 0.0, -1.0, LOOP, "floor"],
	["walk", "Walking", 0.0, -1.0, LOOP, "floor"],
	["run", "Run", 0.0, -1.0, LOOP, "floor"],
	["sprint", "Sprint", 0.0, -1.0, LOOP, "floor"],
	["fall", "Falling Idle", 0.0, -1.0, LOOP, "air"],
	["flight", "Flight", 0.0, -1.0, LOOP, "air"],
	["talk", "Talking", 0.0, -1.0, LOOP, "floor"],
	# Deep crouch while the belly grows.
	["charge", "Jumping", 0.22, 0.44, PING, "floor"],
	# Hands on knees, straining. The source starts on a ledge; the floor rule fixes that.
	["squeak", "Jumping Down", 0.0, 0.6, PING, "floor"],
	# Toot hop from standing, and while running.
	["hop", "Jump", 0.62, 1.18, NO, "air"],
	["hop_run", "Jump (1)", 0.07, 0.47, NO, "air"],
	# Trump launch, ends in a tuck.
	["jump", "Jumping", 0.44, 0.89, NO, "air"],
	# Thunder launch, fist up like a superhero.
	["big_jump", "Jumping Down", 1.45, 1.85, NO, "air"],
	# Bounce off an enemy, arms spread.
	["stomp", "Jump", 0.8, 1.2, NO, "air"],
	["land", "Falling To Landing", 0.3, 0.88, NO, "floor"],
	# Superhero crouch landing.
	["big_land", "Jumping Down", 2.02, 2.9, NO, "floor"],
	# Big landing while running.
	["roll", "Falling To Roll", 0.15, 1.79, NO, "floor"],
	["hurt", "Getting Hit", 1.3, 2.4, NO, "floor"],
	["victory", "Victory", 0.0, -1.0, NO, "floor"],
	["death", "Dying Backwards", 0.0, -1.0, NO, "floor"],
	["death_2", "Death", 0.0, -1.0, NO, "floor"],
]

var _skeleton: Skeleton3D
var _sources: Dictionary = {}
var _idle_x: float = 0.0
var _idle_y: float = 0.0
var _idle_z: float = 0.0


## Builds and saves the library. Returns it (null if something was missing).
func build() -> AnimationLibrary:
	var rig: Node = (load(DIR + "fart_man_rigged.fbx") as PackedScene).instantiate()
	_skeleton = rig.find_children("*", "Skeleton3D", true, false)[0] as Skeleton3D
	var idle_src: Animation = _source("Idle")
	if idle_src == null:
		rig.free()
		return null
	var idle_pos: Vector3 = idle_src.position_track_interpolate(_hips_track(idle_src), 0.0)
	_idle_x = idle_pos.x
	_idle_y = idle_pos.y
	_idle_z = idle_pos.z

	var library := AnimationLibrary.new()
	for row: Array in RECIPE:
		var clip: Animation = _make_clip(row)
		if clip == null:
			push_error("fart_man_clips: could not build '%s'" % row[0])
			rig.free()
			return null
		library.add_animation(StringName(row[0]), clip)
	print("fart_man_clips save: ", ResourceSaver.save(library, OUT))
	rig.free()
	return library


## Loads one Mixamo clip's "mixamo_com" animation (cached).
func _source(file_name: String) -> Animation:
	if _sources.has(file_name):
		return _sources[file_name]
	var path: String = DIR + "animations/" + file_name + ".fbx"
	if not ResourceLoader.exists(path):
		push_error("fart_man_clips: missing file " + path)
		return null
	var scene: Node = (load(path) as PackedScene).instantiate()
	var found: Array[Node] = scene.find_children("*", "AnimationPlayer", true, false)
	var anim: Animation = null
	if not found.is_empty() and (found[0] as AnimationPlayer).has_animation(&"mixamo_com"):
		anim = (found[0] as AnimationPlayer).get_animation(&"mixamo_com").duplicate()
	else:
		push_error("fart_man_clips: no mixamo_com in " + path)
	scene.free()
	_sources[file_name] = anim
	return anim


func _hips_track(anim: Animation) -> int:
	for t in anim.get_track_count():
		if anim.track_get_type(t) == Animation.TYPE_POSITION_3D and str(anim.track_get_path(t)).ends_with(HIPS):
			return t
	return -1


func _interp(anim: Animation, track: int, time: float) -> Variant:
	match anim.track_get_type(track):
		Animation.TYPE_POSITION_3D:
			return anim.position_track_interpolate(track, time)
		Animation.TYPE_ROTATION_3D:
			return anim.rotation_track_interpolate(track, time)
		Animation.TYPE_SCALE_3D:
			return anim.scale_track_interpolate(track, time)
	return null


func _make_clip(row: Array) -> Animation:
	var src: Animation = _source(row[1])
	if src == null:
		return null
	var start: float = row[2]
	var finish: float = src.length if float(row[3]) < 0.0 else float(row[3])
	var clip := Animation.new()
	clip.length = finish - start
	clip.loop_mode = row[4]
	for t in src.get_track_count():
		var type: int = src.track_get_type(t)
		if type != Animation.TYPE_POSITION_3D and type != Animation.TYPE_ROTATION_3D and type != Animation.TYPE_SCALE_3D:
			continue
		var n: int = clip.add_track(type)
		clip.track_set_path(n, src.track_get_path(t))
		clip.track_set_interpolation_type(n, src.track_get_interpolation_type(t))
		# Exact start, the keys in between, exact end.
		clip.track_insert_key(n, 0.0, _interp(src, t, start))
		for k in src.track_get_key_count(t):
			var time: float = src.track_get_key_time(t, k)
			if time > start + 0.0001 and time < finish - 0.0001:
				clip.track_insert_key(n, time - start, src.track_get_key_value(t, k))
		clip.track_insert_key(n, clip.length, _interp(src, t, finish))

	# In place: hips stay at the Idle clip's x and z.
	var hips: int = _hips_track(clip)
	if hips < 0:
		push_error("fart_man_clips: no hips track in " + str(row[1]))
		return null
	for k in clip.track_get_key_count(hips):
		var p: Vector3 = clip.track_get_key_value(hips, k)
		var y: float = _idle_y if row[5] == "air" else p.y
		clip.track_set_key_value(hips, k, Vector3(_idle_x, y, _idle_z))
	var shift: float = 0.0
	if row[5] == "floor":
		shift = -lowest_toe_with(_skeleton, clip)
		for k in clip.track_get_key_count(hips):
			var p: Vector3 = clip.track_get_key_value(hips, k)
			clip.track_set_key_value(hips, k, p + Vector3(0.0, shift, 0.0))
	print("clip %-9s length %.2f  loop %d  hips shift %.5f" % [row[0], clip.length, clip.loop_mode, shift])
	return clip


## The height of the lowest toe over the whole clip, in skeleton units.
## Poses the skeleton by hand from the tracks (bones without a track use their rest pose).
static func lowest_toe_with(skeleton: Skeleton3D, clip: Animation) -> float:
	var tracks: Dictionary = {}  # bone index -> {track type: track number}
	for t in clip.get_track_count():
		var path: String = str(clip.track_get_path(t))
		var bone: int = skeleton.find_bone(path.get_slice(":", 1))
		if bone < 0:
			continue
		if not tracks.has(bone):
			tracks[bone] = {}
		tracks[bone][clip.track_get_type(t)] = t
	var lowest: float = INF
	var steps: int = maxi(int(ceil(clip.length * 30.0)), 1)
	for s in steps + 1:
		var time: float = minf(clip.length * s / float(steps), clip.length)
		for toe_name: String in TOES:
			var chain: Array[int] = []
			var b: int = skeleton.find_bone(toe_name)
			while b >= 0:
				chain.push_front(b)
				b = skeleton.get_bone_parent(b)
			var global := Transform3D.IDENTITY
			for c: int in chain:
				var rest: Transform3D = skeleton.get_bone_rest(c)
				var pos: Vector3 = rest.origin
				var rot: Quaternion = rest.basis.get_rotation_quaternion()
				var scl: Vector3 = rest.basis.get_scale()
				if tracks.has(c):
					var tc: Dictionary = tracks[c]
					if tc.has(Animation.TYPE_POSITION_3D):
						pos = clip.position_track_interpolate(tc[Animation.TYPE_POSITION_3D], time)
					if tc.has(Animation.TYPE_ROTATION_3D):
						rot = clip.rotation_track_interpolate(tc[Animation.TYPE_ROTATION_3D], time)
					if tc.has(Animation.TYPE_SCALE_3D):
						scl = clip.scale_track_interpolate(tc[Animation.TYPE_SCALE_3D], time)
				global = global * Transform3D(Basis(rot).scaled(scl), pos)
			lowest = minf(lowest, global.origin.y)
	return lowest
