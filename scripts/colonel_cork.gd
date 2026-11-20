class_name ColonelCork
extends Area3D
## Boss 2: Colonel Cork, a huge cork robot who plugged up the factory.
##
## He snorts and stamps ("SNORT!" and a red "!"), then CHARGES across the room.
## Thunder-jump over him! He crashes into the wall at the other end and sees stars.
## Stomp his head while he is dizzy. Three stomps wins.
## After each stomp he also lobs corks out of his hat (a red patch shows where they land),
## and he charges faster. When he is beaten he pops like a champagne cork.
## The corks come from cork_shot.gd. The gate opens at the end, to the Bean Can.

## Sent each time he is stomped, with how many stomps are left.
signal hit(hits_left: int)
## Sent when he crashes into a wall.
signal bonked
## Sent when he is beaten and the gate has opened.
signal defeated
## Sent when Fart Man loses all his hearts (or falls) during the fight, and it starts over.
signal fight_lost

enum State { WAITING, INTRO, IDLE, CORKS, WINDUP, CHARGE, DIZZY, HIT, DEFEATED }

@export_group("The fight")
@export var hits_to_win: int = 3
## Pauses, in seconds.
@export var idle_time: float = 1.2
## How long he snorts and stamps before he charges. Plenty of time to get ready.
@export var windup_time: float = 1.3
## How long he stays dizzy after crashing, extra easy to stomp.
@export var dizzy_time: float = 6.0
## After a stomp he can't be stomped again for this long (each hit needs its own jump).
@export var hit_pause: float = 1.8
## Tick to make his body hurt even when he is standing still (harder).
@export var body_hurts_always: bool = false

@export_group("Charge (round 1, 2, 3)")
## How fast he charges in each round, in metres per second. Faster each time.
@export var charge_speed: Array[float] = [7.5, 8.5, 9.5]
## The furthest left and right his middle goes. He crashes into the wall there.
@export var arena_left_x: float = 9.0
@export var arena_right_x: float = 43.5
## The floor's top height.
@export var floor_y: float = 0.0

@export_group("Corks (round 1, 2, 3)")
## How many corks he lobs before each charge. Round 1 has none: they start after the first stomp.
@export var corks_per_volley: Array[int] = [0, 2, 3]
## How long each cork takes to fly. Bigger = slower and easier.
@export var cork_flight_time: Array[float] = [2.4, 2.2, 2.0]
## Seconds between corks of the same volley.
@export var cork_gap: float = 1.1
## How far apart the extra corks land, around where Fart Man stands, in metres.
@export var cork_spread: float = 3.5

@export_group("Parts")
## All the pictures of him. This is what leans, shakes and pops. Not his stomp zone.
@export var visual: Node3D
## His stomp zone: a big forgiving sphere on top of his head. Needs a collision shape.
@export var head: Area3D
## What hurts when he charges into you: a box a little smaller than his body.
@export var hurt_zone: Area3D
## The hat, so corks come out of the top and it jumps when they do.
@export var hat: Node3D
## The stars that circle his head when he is dizzy.
@export var stars: Node3D
## The red "!" that flashes when he is about to charge.
@export var warning: Node3D
@export var head_up: Vector3 = Vector3(0, 3.6, 0)
## His head sinks a bit when dizzy, so even a Trump jump can stomp it.
@export var head_dizzy: Vector3 = Vector3(0, 2.7, 0)
## Touch this to start the fight.
@export var trigger: Area3D
## The door behind you slams shut when the fight starts, and opens if you lose or win.
@export var door: Node3D
## This wall opens when he is beaten, so you can reach the Bean Can.
@export var gate: Node3D
@export var scene_player: ScenePlayer

var state: State = State.WAITING
var hits: int = 0
var _run_id: int = 0
var _gate_opened: bool = false
var _player: Player
var _dir: float = -1.0
var _home_x: float = 0.0
var _door_closed_y: float = 0.0
var _puff_timer: float = 0.0


func _ready() -> void:
	add_to_group(&"bosses")
	_home_x = position.x
	_player = get_tree().get_first_node_in_group(&"player") as Player
	if trigger != null:
		trigger.body_entered.connect(_on_trigger)
	if _player != null:
		_player.respawned.connect(_reset)
	if is_instance_valid(door):
		_door_closed_y = door.position.y
		door.position.y = _door_closed_y - 15.0
	_show_calm()


func _physics_process(delta: float) -> void:
	if state == State.WAITING or state == State.DEFEATED:
		return
	_check_head()
	if state == State.CHARGE:
		_charge_step(delta)
	_check_body()


func _process(delta: float) -> void:
	# The stars circle his head while he is dizzy.
	if stars != null and stars.visible:
		stars.rotation.y += 4.0 * delta
	if warning != null and warning.visible:
		warning.scale = Vector3.ONE * (1.0 + 0.15 * sin(Time.get_ticks_msec() * 0.03))


## His head: land on it from above and he takes a hit, whenever the fight is on.
## He bounces you off even during the hit pause, but only counts it in fighting moods.
func _check_head() -> void:
	if head == null:
		return
	for body: Node3D in head.get_overlapping_bodies():
		var player := body as Player
		if player == null:
			continue
		var above: bool = player.get_feet_y() > head.global_position.y - 0.8
		if player.can_stomp() and above:
			player.stomp_bounce()
			if state in [State.IDLE, State.CORKS, State.WINDUP, State.CHARGE, State.DIZZY]:
				_take_hit()
		return


## He only hurts when charging (or always, if body_hurts_always is ticked).
func _check_body() -> void:
	if hurt_zone == null or state == State.HIT or state == State.INTRO:
		return
	if state != State.CHARGE and not body_hurts_always:
		return
	for body: Node3D in hurt_zone.get_overlapping_bodies():
		if body is Player:
			(body as Player).hurt(global_position.x)


func _on_trigger(body: Node3D) -> void:
	if body is Player and state == State.WAITING:
		_start_fight()


func _start_fight() -> void:
	state = State.INTRO
	_camera_shows_me(true)
	_move_door(true)
	var id: int = _run_id
	if scene_player != null:
		await scene_player.play(load("res://scripts/puppet/cork_hello.gd").STEPS,
			{"boss": head, "player": _player}, "cork_hello")
	if id != _run_id:
		return
	_fight(id)


## One run of the whole fight: corks (after the first stomp), a charge, dizzy, and again.
func _fight(id: int) -> void:
	while id == _run_id and hits < hits_to_win:
		state = State.IDLE
		await _wait(idle_time)
		if id != _run_id:
			return
		await _fire_corks(id)
		if id != _run_id:
			return
		await _charge(id)


## The round: 0 before any stomp, 1 after the first, 2 after the second.
func round_now() -> int:
	return clampi(hits, 0, charge_speed.size() - 1)


## How fast he charges right now.
func charge_speed_now() -> float:
	return charge_speed[round_now()]


## Lobs a volley of corks at where Fart Man is standing.
func _fire_corks(id: int) -> void:
	var r: int = clampi(hits, 0, corks_per_volley.size() - 1)
	var count: int = corks_per_volley[r]
	if count <= 0 or _player == null:
		return
	state = State.CORKS
	for i in count:
		SpeechBubble.say(head, "POP!", 0.7, 1.8)
		_hat_jump()
		# The first cork lands right on him. The others land either side.
		var offsets: Array[float] = [0.0, cork_spread, -cork_spread]
		var x: float = clampf(_player.global_position.x + offsets[i % 3], arena_left_x - 1.0, arena_right_x + 1.0)
		var top: Vector3 = hat.global_position + Vector3(0, 1.0, 0) if hat != null else global_position + Vector3(0, 5, 0)
		CorkShot.launch(get_parent(), top, x, floor_y, cork_flight_time[clampi(hits, 0, cork_flight_time.size() - 1)])
		await _wait(cork_gap)
		if id != _run_id:
			return
	await _wait(0.6)


## Snorts, stamps, charges at the far wall, crashes and gets dizzy.
func _charge(id: int) -> void:
	state = State.WINDUP
	# He charges towards whichever wall is further away.
	_dir = -1.0 if position.x - arena_left_x > arena_right_x - position.x else 1.0
	SpeechBubble.say(head, "SNORT!", windup_time, 1.8)
	if warning != null:
		warning.visible = true
	var shake: Tween = create_tween()
	shake.set_loops(maxi(1, int(windup_time / 0.1)))
	shake.tween_property(visual, "rotation:z", 0.06, 0.05)
	shake.tween_property(visual, "rotation:z", -0.06, 0.05)
	await _wait(windup_time)
	shake.kill()
	if id != _run_id:
		return
	visual.rotation.z = 0.0
	if warning != null:
		warning.visible = false
	state = State.CHARGE
	visual.rotation.z = -_dir * 0.15
	# Wait for the charge to end (a crash, a stomp, or the fight being reset).
	while state == State.CHARGE and id == _run_id:
		await get_tree().physics_frame
	if id != _run_id or state != State.DIZZY:
		return
	await _be_dizzy(id)


## Runs along the floor, puffing dust, until he crashes into the wall.
func _charge_step(delta: float) -> void:
	position.x += _dir * charge_speed_now() * delta
	_puff_timer -= delta
	if _puff_timer <= 0.0:
		_puff_timer = 0.12
		_dust()
	if (_dir < 0.0 and position.x <= arena_left_x) or (_dir > 0.0 and position.x >= arena_right_x):
		position.x = clampf(position.x, arena_left_x, arena_right_x)
		_bonk()


func _bonk() -> void:
	state = State.DIZZY
	visual.rotation.z = 0.0
	SpeechBubble.say(head, "BONK!", 1.0, 1.8)
	_shake_camera(0.3, 0.4)
	bonked.emit()
	_show_dizzy(true)


## Dizzy: head sinks, stars circle. Waits to be stomped, then shakes it off.
func _be_dizzy(id: int) -> void:
	var waited: float = 0.0
	while waited < dizzy_time and state == State.DIZZY and id == _run_id:
		await get_tree().create_timer(0.1).timeout
		waited += 0.1
	if state == State.DIZZY and id == _run_id:
		# Nobody stomped him: he shakes it off.
		SpeechBubble.say(head, "GRRR!", 1.0, 1.8)
		_show_dizzy(false)


func _take_hit() -> void:
	hits += 1
	hit.emit(hits_to_win - hits)
	_burst_crumbs()
	if hits >= hits_to_win:
		_defeat()
		return
	# Stop whatever he was doing, rub his head for a moment, then start the next round.
	_run_id += 1
	var id: int = _run_id
	_clear_shots()
	state = State.HIT
	_show_calm()
	SpeechBubble.say(head, "OW! MY HEAD!", 1.2, 1.8)
	_hat_jump()
	# Long enough that bouncing straight back onto his head doesn't count twice.
	await _wait(hit_pause)
	if id == _run_id:
		_fight(id)


func _defeat() -> void:
	state = State.DEFEATED
	_run_id += 1
	_clear_shots()
	_show_calm()
	if scene_player != null:
		await scene_player.play(load("res://scripts/puppet/cork_goodbye.gd").STEPS,
			{"boss": head, "player": _player, "cork": self}, "cork_goodbye")
	open_gate()


## The goodbye scene calls this: he pops like a champagne cork and flies off.
func pop() -> void:
	if visual == null or state != State.DEFEATED:
		return
	_shake_camera(0.4, 0.5)
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(visual, "position:y", 22.0, 0.9).set_ease(Tween.EASE_OUT)
	tween.tween_property(visual, "rotation:z", TAU * 3.0, 0.9)
	tween.chain().tween_callback(visual.hide)
	# A spray of fizz bubbles.
	for i in 14:
		var fizz := MeshInstance3D.new()
		var bubble := SphereMesh.new()
		bubble.radius = 0.25
		bubble.height = 0.5
		var white := StandardMaterial3D.new()
		white.albedo_color = Color(1.0, 1.0, 0.8, 0.8)
		white.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		bubble.material = white
		fizz.mesh = bubble
		get_parent().add_child(fizz)
		fizz.global_position = global_position + Vector3(0, 3.0, 0)
		var angle: float = PI * float(i) / 13.0
		var goal: Vector3 = fizz.global_position + Vector3(cos(angle) * 5.0, 2.0 + sin(angle) * 5.0, 0.0)
		var fizz_tween: Tween = fizz.create_tween()
		fizz_tween.tween_property(fizz, "global_position", goal, 0.8)
		fizz_tween.tween_callback(fizz.queue_free)


## The goodbye scene calls this too.
func open_gate() -> void:
	if state != State.DEFEATED or _gate_opened:
		return
	_gate_opened = true
	if is_instance_valid(gate):
		gate.queue_free()
	_move_door(false)
	_camera_shows_me(false)
	defeated.emit()


## Crumbs of cork flying off his head.
func _burst_crumbs() -> void:
	for i in 10:
		var crumb := MeshInstance3D.new()
		var bit := BoxMesh.new()
		bit.size = Vector3(0.3, 0.3, 0.3)
		var brown := StandardMaterial3D.new()
		brown.albedo_color = Color(0.78, 0.58, 0.32)
		bit.material = brown
		crumb.mesh = bit
		get_parent().add_child(crumb)
		crumb.global_position = head.global_position
		var angle: float = TAU * float(i) / 10.0
		var goal: Vector3 = crumb.global_position + Vector3(cos(angle) * 3.0, absf(sin(angle)) * 3.0 + 1.0, 0.0)
		var tween: Tween = crumb.create_tween()
		tween.tween_property(crumb, "global_position", goal, 0.6)
		tween.tween_callback(crumb.queue_free)


## A little cloud of dust behind him while he charges.
func _dust() -> void:
	var dust := MeshInstance3D.new()
	var puff := SphereMesh.new()
	puff.radius = 0.5
	puff.height = 1.0
	var grey := StandardMaterial3D.new()
	grey.albedo_color = Color(0.8, 0.75, 0.7, 0.6)
	grey.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	puff.material = grey
	dust.mesh = puff
	get_parent().add_child(dust)
	dust.global_position = global_position + Vector3(-_dir * 1.6, floor_y + 0.5, 0.5)
	var tween: Tween = dust.create_tween()
	tween.tween_property(dust, "scale", Vector3.ONE * 2.0, 0.4)
	tween.tween_callback(dust.queue_free)


## The hat hops up when a cork pops out.
func _hat_jump() -> void:
	if hat == null:
		return
	var rest: float = hat.position.y
	var tween: Tween = create_tween()
	tween.tween_property(hat, "position:y", rest + 0.5, 0.1)
	tween.tween_property(hat, "position:y", rest, 0.15)


## Dizzy or not: stars, a sunk head and a slumped body.
func _show_dizzy(yes: bool) -> void:
	if stars != null:
		stars.visible = yes
	if head != null:
		var tween: Tween = create_tween()
		tween.tween_property(head, "position", head_dizzy if yes else head_up, 0.4)
	if visual != null:
		var squash: Tween = create_tween()
		squash.tween_property(visual, "scale", Vector3(1.1, 0.85, 1.0) if yes else Vector3.ONE, 0.3)


## Standing tall, not dizzy, not warning.
func _show_calm() -> void:
	if stars != null:
		stars.visible = false
	if warning != null:
		warning.visible = false
	if head != null:
		head.position = head_up
	if visual != null:
		visual.scale = Vector3.ONE
		visual.rotation.z = 0.0


## The door at the start of the arena: shut it behind you (or open it again).
func _move_door(shut: bool) -> void:
	if not is_instance_valid(door):
		return
	var tween: Tween = create_tween()
	tween.tween_property(door, "position:y", _door_closed_y if shut else _door_closed_y - 15.0, 0.4)


## He is ready to start over: the player went back to a toilet.
func _reset() -> void:
	if state == State.DEFEATED:
		return
	# He lost while the fight was on: that's "Game Over" for this try.
	if state != State.WAITING:
		fight_lost.emit()
	_run_id += 1
	_clear_shots()
	_camera_shows_me(false)
	state = State.WAITING
	position.x = _home_x
	_show_calm()
	if is_instance_valid(door):
		door.position.y = _door_closed_y - 15.0


## While the fight is on, the camera zooms out to keep him and Fart Man both in the shot.
func _camera_shows_me(yes: bool) -> void:
	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera == null or not camera.has_method("show_too"):
		return
	if yes:
		camera.call("show_too", self)
	else:
		camera.call("stop_showing", self)


func _shake_camera(strength: float, seconds: float) -> void:
	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera == null:
		return
	var tween: Tween = create_tween()
	tween.set_loops(maxi(1, int(seconds / 0.05)))
	tween.tween_callback(func() -> void:
		if is_instance_valid(camera):
			camera.h_offset = randf_range(-strength, strength)
			camera.v_offset = randf_range(-strength, strength))
	tween.tween_interval(0.05)
	get_tree().create_timer(seconds).timeout.connect(func() -> void:
		tween.kill()
		if is_instance_valid(camera):
			camera.h_offset = 0.0
			camera.v_offset = 0.0)


func _clear_shots() -> void:
	for shot: Node in get_tree().get_nodes_in_group(&"boss_shots"):
		shot.queue_free()


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
