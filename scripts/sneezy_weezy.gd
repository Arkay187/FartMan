class_name SneezyWeezy
extends Area3D
## Boss 1: Sneezy Weezy, a giant flower with terrible hay fever.
## It takes 6 stomps, in 3 phases of 2 stomps. Each phase she gets faster and adds a trick.
## She always shows what is coming: a speech bubble, a pause, and a change in her face.
##
## PHASE 1: she puffs up ("AH... AH...") and sneezes pollen that rolls along the floor: jump it.
## PHASE 2: she also tips her head back ("AAAH...") and sneezes puffs that hop through the air,
##          and a pink patch on the floor warns where a big petal is about to fall.
## PHASE 3: three sneezes in a row, and she calls friends ("COME HELP!") who are Burplings.
## After each round of sneezes she droops, worn out. Stomp her head! (A stomp counts any time.)
## Between phases she shouts and the camera shakes. Every hit sends a burst of beans flying and
## beating her makes a huge shower of beans. The pollen and petals come from pollen.gd and
## falling_petal.gd.

## Sent each time she is stomped, with how many stomps are left.
signal hit(hits_left: int)
## Sent when a new phase starts, with its number (1 = the second phase, 2 = the third).
signal phase_changed(phase: int)
## Sent when she is beaten and the gate has opened.
signal defeated
## Sent when Fart Man loses all his hearts (or falls) during the fight, and it starts over.
signal fight_lost

enum State { WAITING, INTRO, IDLE, WINDUP, TIRED, HIT, DEFEATED, SUMMON, PHASE }

@export_group("The fight")
## Stomps needed in all, and how many of them make one phase.
@export var hits_to_win: int = 6
@export var hits_per_phase: int = 2
## Seconds of calm before each round of sneezes (phase 1, 2, 3).
@export var idle_times: Array[float] = [1.5, 1.2, 1.0]
## How long she winds up before a sneeze (phase 1, 2, 3).
@export var windup_times: Array[float] = [1.1, 1.0, 0.9]
## The pause between sneezes (phase 1, 2, 3).
@export var between_sneezes: Array[float] = [0.8, 0.7, 0.3]
## How long she stays drooped, extra easy to stomp (phase 1, 2, 3).
@export var tired_times: Array[float] = [6.0, 5.0, 4.0]
## How many sneezes in a round (phase 1, 2, 3).
@export var sneezes_per_round: Array[int] = [2, 3, 3]
## In the rapid sneezes of phase 3, the short wind-up of the 2nd and 3rd.
@export var quick_windup: float = 0.45
## After a stomp she can't be stomped again for this long (each hit needs its own jump).
@export var hit_pause: float = 1.8
## Tick to make her stalk hurt to touch (harder).
@export var stalk_hurts: bool = false

@export_group("Phase change")
## How long the shout-and-shake moment lasts between phases.
@export var phase_change_time: float = 1.8
## What she shouts when each phase starts (phase 1 has no shout).
@export var phase_words: Array[String] = ["", "NOW I'M REALLY SNEEZY!", "ATCHOOOO!! FRIENDS, HELP!"]

@export_group("Pollen and petals (phase 1, 2, 3)")
## Pollen speed in each phase, in metres per second.
@export var pollen_speed: Array[float] = [3.5, 4.2, 5.0]
## Clouds per sneeze in each phase.
@export var pollen_per_sneeze: Array[int] = [1, 1, 1]
## Seconds between clouds of the same sneeze.
@export var pollen_gap: float = 1.2
## How high the hopping puffs of phase 2 and 3 go.
@export var hop_height: float = 2.2
## Falling petals per sneeze in each phase (they drop near him).
@export var petals_per_sneeze: Array[int] = [0, 1, 1]
## Where clouds start, compared to her base, and where they disappear.
@export var pollen_offset: Vector3 = Vector3(-1.5, 0.4, 0)
@export var arena_left_x: float = -9.0
## The floor's top height, for the petal warnings.
@export var floor_y: float = 0.5

@export_group("Friends (phase 3)")
## How many Burplings she calls each round (phase 1, 2, 3).
@export var friends_per_call: Array[int] = [0, 0, 2]
## She never has more than this many friends out at once.
@export var max_friends: int = 3
## The Burpling to call. The stage fills this in.
@export var friend_scene: PackedScene
@export var friend_speed: float = 2.2
@export var friend_patrol: float = 3.0
## How long she shouts "COME HELP!" before they pop out.
@export var summon_time: float = 1.1

@export_group("Beans")
## Beans that fly out every time she is stomped.
@export var hit_beans: int = 8
## Beans that rain down when she is beaten, over this many seconds.
@export var defeat_beans: int = 44
@export var defeat_rain_seconds: float = 2.0
## The stretch of floor the beans rain on, compared to her base.
@export var rain_left_offset: float = -26.0
@export var rain_right_offset: float = 4.0

@export_group("Parts")
## The head: raised normally, drooped when tired. Needs a collision shape.
@export var head: Area3D
## The picture of the head (the part that puffs up when she winds up to sneeze).
@export var face: Node3D
@export var head_up: Vector3 = Vector3(-0.5, 4.6, 0)
@export var head_down: Vector3 = Vector3(-2.4, 1.4, 0)
## Touch this to start the fight.
@export var trigger: Area3D
## This wall opens when she is beaten, so you can reach the Bean Can.
@export var gate: Node3D
@export var scene_player: ScenePlayer

@export_group("Sounds")
## The AH... AH... before a sneeze, the ACHOO!, getting stomped, a new phase, and being beaten.
@export var windup_sound: AudioStream
@export var achoo_sound: AudioStream
@export var hit_sound: AudioStream
@export var phase_sound: AudioStream
@export var defeat_sound: AudioStream

var state: State = State.WAITING
var hits: int = 0
var _run_id: int = 0
var _gate_opened: bool = false
var _player: Player
var _pose_tween: Tween


func _ready() -> void:
	add_to_group(&"bosses")
	_player = get_tree().get_first_node_in_group(&"player") as Player
	if trigger != null:
		trigger.body_entered.connect(_on_trigger)
	if _player != null:
		_player.respawned.connect(_reset)
	if head != null:
		head.position = head_up


## Which phase she is in: 0, 1 or 2 (every hits_per_phase stomps makes a new one).
func phase_now() -> int:
	return clampi(hits / maxi(hits_per_phase, 1), 0, 2)


func _physics_process(_delta: float) -> void:
	if state == State.WAITING or state == State.DEFEATED:
		return
	# Only her pollen and petals hurt. Her stalk and head are safe to touch.
	if stalk_hurts:
		for body: Node3D in get_overlapping_bodies():
			if body is Player:
				(body as Player).hurt(global_position.x)
	_check_head()


## The head: land on it from above and she takes a hit, whenever the fight is on.
## (She droops when tired to make it extra easy.) Touching it any other way is harmless.
func _check_head() -> void:
	if head == null:
		return
	for body: Node3D in head.get_overlapping_bodies():
		var player := body as Player
		if player == null:
			continue
		var above: bool = player.get_feet_y() > head.global_position.y - 0.6
		if player.can_stomp() and above:
			player.stomp_bounce()
			if state in [State.IDLE, State.WINDUP, State.TIRED, State.SUMMON]:
				_take_hit()
		return


func _on_trigger(body: Node3D) -> void:
	if body is Player and state == State.WAITING:
		_start_fight()


func _start_fight() -> void:
	state = State.INTRO
	_camera_shows_me(true)
	var id: int = _run_id
	if scene_player != null:
		await scene_player.play(load("res://scripts/puppet/sneezy_hello.gd").STEPS,
			{"boss": head, "player": _player}, "sneezy_hello")
	if id != _run_id:
		return
	_fight(id)


## One run of the whole fight: calm, (friends), sneezes, tired, and again until beaten.
func _fight(id: int) -> void:
	while id == _run_id and hits < hits_to_win:
		var phase: int = phase_now()
		state = State.IDLE
		await _wait(idle_times[phase])
		if id != _run_id:
			return
		await _call_friends(phase, id)
		if id != _run_id:
			return
		var sneezes: int = sneezes_per_round[phase]
		for i in sneezes:
			# From phase 2 on, every other sneeze goes up in the air.
			var in_the_air: bool = phase >= 1 and i % 2 == 1
			# In phase 3 the 2nd and 3rd sneeze come right after the first.
			var quick: bool = phase >= 2 and i > 0
			await _sneeze(phase, in_the_air, quick, id)
			if id != _run_id:
				return
			await _wait(between_sneezes[phase])
			if id != _run_id:
				return
		await _be_tired(phase, id)


## Winds up (the tell), then lets rip. A ground sneeze puffs her face up. An air sneeze also
## tips her head back and raises it.
func _sneeze(phase: int, in_the_air: bool, quick: bool, id: int) -> void:
	state = State.WINDUP
	var wind: float = quick_windup if quick else windup_times[phase]
	var words: String = "AH!" if quick else ("AAAH... AAAH..." if in_the_air else "AH... AH...")
	SpeechBubble.say(head, words, wind, 1.6)
	Sfx.play(head, windup_sound)
	if in_the_air:
		_pose(head_up + Vector3(0, 0.8, 0), 0.5, 1.3, wind)
	else:
		_pose(head_up, 0.0, 1.3, wind)
	await _wait(wind)
	if id != _run_id:
		return
	_pose(head_up, 0.0, 1.0, 0.0)
	SpeechBubble.say(head, "ACHOO!", 0.8, 1.6)
	Sfx.play(head, achoo_sound)
	var clouds: int = pollen_per_sneeze[phase]
	for i in clouds:
		var start: Vector3 = global_position + pollen_offset
		Pollen.launch(get_parent(), start, pollen_speed[phase], arena_left_x, hop_height if in_the_air else 0.0)
		if i < clouds - 1:
			await _wait(pollen_gap)
			if id != _run_id:
				return
	if _player != null:
		for i in petals_per_sneeze[phase]:
			FallingPetal.drop(get_parent(), _player.global_position.x + (i - 0.5) * 3.0, floor_y)


## Phase 3: she shouts for help and Burplings pop out further along the floor.
func _call_friends(phase: int, id: int) -> void:
	var out: int = get_tree().get_nodes_in_group(&"boss_minions").size()
	var want: int = mini(friends_per_call[phase], max_friends - out)
	if want <= 0 or friend_scene == null:
		return
	state = State.SUMMON
	SpeechBubble.say(head, "COME HELP, FRIENDS!", summon_time, 1.6)
	Sfx.play(head, windup_sound)
	_pose(head_up + Vector3(0, 0.5, 0), 0.0, 1.2, summon_time)
	await _wait(summon_time)
	if id != _run_id:
		return
	_pose(head_up, 0.0, 1.0, 0.2)
	var spots: Array[float] = []
	for i in want:
		spots.append(global_position.x - 11.0 - 8.0 * i)
	BossFx.summon(self, friend_scene, spots, floor_y, 0.45, friend_speed, friend_patrol)
	await _wait(0.5)


## Droops down and waits to be stomped.
func _be_tired(phase: int, id: int) -> void:
	state = State.TIRED
	var tired: float = tired_times[phase]
	SpeechBubble.say(head, "*WHEEZE*", tired, 1.6)
	_pose(head_down, 0.0, 1.0, 0.5)
	var waited: float = 0.0
	while waited < tired and state == State.TIRED and id == _run_id:
		await get_tree().create_timer(0.1).timeout
		waited += 0.1
	if state == State.TIRED and id == _run_id:
		# Nobody stomped her: she perks up again.
		_raise_head()


func _take_hit() -> void:
	hits += 1
	hit.emit(hits_to_win - hits)
	Sfx.play(head, hit_sound)
	_burst_petals()
	BossFx.bean_burst(self, hit_beans)
	if hits >= hits_to_win:
		_defeat()
		return
	# Stop whatever she was doing, shake it off for a moment, then start the next round.
	_run_id += 1
	var id: int = _run_id
	_clear_shots()
	state = State.HIT
	_pose(head_up, 0.0, 1.0, 0.0)
	SpeechBubble.say(head, "ACHOO! OW!", 1.0, 1.6)
	_raise_head()
	# Long enough that bouncing straight back onto her head doesn't count twice.
	await _wait(hit_pause)
	if id != _run_id:
		return
	if hits % maxi(hits_per_phase, 1) == 0:
		await _change_phase(id)
		if id != _run_id:
			return
	_fight(id)


## Between phases: she puffs up, shouts, and the whole arena shakes.
func _change_phase(id: int) -> void:
	state = State.PHASE
	phase_changed.emit(phase_now())
	_pose(head_up + Vector3(0, 0.6, 0), 0.0, 1.35, 0.3)
	SpeechBubble.say(head, phase_words[phase_now()], phase_change_time, 1.9)
	Sfx.play(head, phase_sound)
	BossFx.shake_camera(self, 0.3, 0.7)
	_burst_petals()
	await _wait(phase_change_time)
	if id == _run_id:
		_pose(head_up, 0.0, 1.0, 0.3)


func _raise_head() -> void:
	_pose(head_up, 0.0, 1.0, 0.5)


## Moves her head, tilts and puffs her face to these values over this many seconds
## (0 = straight away). Stops whatever pose she was moving into.
func _pose(pos: Vector3, tilt: float, puff: float, seconds: float) -> void:
	if _pose_tween != null:
		_pose_tween.kill()
	if head == null or face == null:
		return
	if seconds <= 0.0:
		head.position = pos
		face.rotation.z = tilt
		face.scale = Vector3.ONE * puff
		return
	_pose_tween = create_tween()
	_pose_tween.set_parallel(true)
	_pose_tween.tween_property(head, "position", pos, seconds)
	_pose_tween.tween_property(face, "rotation:z", tilt, seconds)
	_pose_tween.tween_property(face, "scale", Vector3.ONE * puff, seconds)


func _defeat() -> void:
	state = State.DEFEATED
	_run_id += 1
	_clear_shots()
	BossFx.clear_minions(self)
	_pose(head_up, 0.0, 1.0, 0.0)
	Sfx.play(head, defeat_sound)
	# A huge shower of beans over the whole arena.
	var left: float = global_position.x + rain_left_offset
	BeanShower.rain(get_parent(), left, global_position.x + rain_right_offset, floor_y, defeat_beans, defeat_rain_seconds)
	if scene_player != null:
		await scene_player.play(load("res://scripts/puppet/sneezy_goodbye.gd").STEPS,
			{"boss": self, "player": _player}, "sneezy_goodbye")
	open_gate()


## The goodbye scene calls this too.
func open_gate() -> void:
	if state != State.DEFEATED or head == null or _gate_opened:
		return
	_gate_opened = true
	if is_instance_valid(gate):
		gate.queue_free()
	_raise_head()
	_camera_shows_me(false)
	defeated.emit()


## A fountain of petals flying off her head.
func _burst_petals() -> void:
	for i in 10:
		var petal := MeshInstance3D.new()
		var blob := SphereMesh.new()
		blob.radius = 0.2
		blob.height = 0.3
		var pink := StandardMaterial3D.new()
		pink.albedo_color = Color(1.0, 0.5, 0.75)
		blob.material = pink
		petal.mesh = blob
		get_parent().add_child(petal)
		petal.global_position = head.global_position
		var angle: float = TAU * i / 10.0
		var goal: Vector3 = petal.global_position + Vector3(cos(angle) * 3.0, absf(sin(angle)) * 3.0 + 1.0, 0.0)
		var tween: Tween = petal.create_tween()
		tween.tween_property(petal, "global_position", goal, 0.6)
		tween.tween_callback(petal.queue_free)


## She is ready to start over: the player went back to a toilet.
func _reset() -> void:
	if state == State.DEFEATED:
		return
	# He lost while the fight was on: that's "Game Over" for this try.
	if state != State.WAITING:
		fight_lost.emit()
	_run_id += 1
	_clear_shots()
	BossFx.clear_minions(self)
	_camera_shows_me(false)
	state = State.WAITING
	_pose(head_up, 0.0, 1.0, 0.0)


## While the fight is on, the camera zooms out to keep her and him both in the shot.
func _camera_shows_me(yes: bool) -> void:
	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera == null or not camera.has_method("show_too"):
		return
	if yes:
		camera.call("show_too", self)
	else:
		camera.call("stop_showing", self)


func _clear_shots() -> void:
	for shot: Node in get_tree().get_nodes_in_group(&"boss_shots"):
		shot.queue_free()


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
