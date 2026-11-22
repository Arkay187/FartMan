class_name BigBadBurp
extends Area3D
## The final boss: Big Bad Burp, a huge grumpy fizzy blob who believes air only comes out of the top.
##
## PART 1, the bubble fight. He floats high above the arena and burps giant bubbles (BUUURP! and the
## bubbles swell up first, so you see them coming). Land on a bubble to bounce very high, climb the
## bubbles like stairs and stomp his head. Green stinky bubbles hurt. He gets faster each round and
## sends helpers (Burplings, then Whifflers). Six stomps.
## Then he flies off in a huff and drops a Rocket Burrito.
##
## PART 2, the ring chase. You fly after him round the planet's rings. He burps rings (fly through
## the hole) and walls of stinky bubbles (fly through the gap), then gets burp-sick and dizzy:
## stars! Fly right into him while he is dizzy. Four hits.
##
## When he is beaten there is the ending scene (see scripts/puppet/burp_ending.gd).

## Sent each time he is hit, with how many hits are left in this part.
signal hit(hits_left: int)
## Sent when part 1 is won and the burrito arrives.
signal part_one_won
## Sent when he is beaten for good (the ending starts).
signal defeated

enum Phase { WAITING, INTRO, PART1, LEAVING, BURRITO, PART2, DEFEATED }
enum Mood { CALM, TELL, DIZZY, HIT }

@export_group("Part 1: the bubble fight")
## Stomps needed. He gets faster every third of these (three rounds).
@export var hits_part1: int = 6
## After a stomp he can't be stomped again for this long, then he glides to a new spot.
@export var hit_pause: float = 2.0
## Rest between bubble volleys, for round 1, 2 and 3.
@export var rest_time: Array[float] = [3.0, 2.4, 1.9]
## How fast the bubbles float up, for round 1, 2 and 3.
@export var rise_speed: Array[float] = [1.0, 1.4, 1.8]
## How long a new bubble swells before it can be stomped (the warning).
@export var tell_time: float = 1.0
## How long each bubble lasts before it pops by itself.
@export var bubble_lifetime: float = 7.5
## The room: its left and right edge and floor height.
@export var arena_left_x: float = 0.0
@export var arena_right_x: float = 60.0
@export var floor_y: float = 0.0
## Where he hovers in the air (x, y), one per hit.
@export var perches: Array[Vector2] = [Vector2(30, 18), Vector2(26, 19), Vector2(33, 17)]
## Helpers on the floor: Burplings from round 2, plus Whifflers in round 3.
@export var burplings_round2: int = 2
@export var whifflers_round3: int = 2

@export_group("Part 2: the ring chase")
## Hits needed in the chase.
@export var hits_part2: int = 4
## How far ahead of Fart Man he flies, in metres.
@export var chase_gap: float = 32.0
## How fast he slows down when he is dizzy, so you can catch up (metres per second).
@export var dizzy_gap_speed: float = 6.0
## How long he stays dizzy before he shakes it off.
@export var dizzy_time: float = 7.0
## The hole in his rings, in metres. Bigger = easier.
@export var ring_gap: float = 9.0
## How many things he burps before each dizzy moment, per round.
@export var attacks_per_round: Array[int] = [2, 2, 3, 3]
## The sky he flies in (lowest and highest height).
@export var lane: Vector2 = Vector2(3.0, 20.0)
## If the runway ends before he is beaten: when Fart Man gets past this x, he is put back
## "wrap_back" metres. 0 = off.
@export var wrap_at_x: float = 0.0
@export var wrap_back: float = 700.0

@export_group("Parts")
## All his pictures (they shake, swell and fly off).
@export var visual: Node3D
## His stomp zone (a big forgiving sphere on top of his head).
@export var head: Area3D
## What hurts when you touch his body.
@export var hurt_zone: Area3D
## His mouth (it opens wide before every burp).
@export var mouth: Node3D
## The stars that circle his head when he is dizzy.
@export var stars: Node3D
## Touch this to start the fight.
@export var trigger: Area3D
## The door behind you (shuts when the fight starts) and the wall on the right (opens after part 1).
@export var door: Node3D
@export var gate: Node3D
## How far down the door sinks when open. Must be more than the door is tall, or it still blocks the way.
@export var door_drop: float = 34.0
## The Rocket Burrito that arrives after part 1 (hidden until then).
@export var burrito: Area3D
@export var scene_player: ScenePlayer

@export_group("Sounds")
@export var burp_sound: AudioStream
@export var hit_sound: AudioStream
@export var defeat_sound: AudioStream

var phase: Phase = Phase.WAITING
var mood: Mood = Mood.CALM
var hits1: int = 0
var hits2: int = 0
## How far ahead of Fart Man he is right now (part 2).
var gap: float = 32.0

var _run_id: int = 0
var _player: Player
var _home: Vector3
var _perch: int = 0
var _volleys: int = 0
var _target_y: float = 10.0
var _age: float = 0.0
var _helpers: Array[Node] = []
var _door_closed_y: float = 0.0
var _burrito_home: Vector3
var _gap_tween: Tween
var _leave_tween: Tween
var _shake_tween: Tween
var _shaking_camera: Camera3D
var _shake_strength: float = 0.0


func _ready() -> void:
	add_to_group(&"bosses")
	_home = position
	_player = get_tree().get_first_node_in_group(&"player") as Player
	if trigger != null:
		trigger.body_entered.connect(_on_trigger)
	if _player != null:
		_player.respawned.connect(_reset)
		if _player.flight != null:
			_player.flight.started.connect(_on_flight_started)
	if is_instance_valid(door):
		_door_closed_y = door.position.y
		door.position.y = _door_closed_y - door_drop
	if burrito != null:
		_burrito_home = burrito.position
		burrito.visible = false
		burrito.monitoring = false
	_show_calm()


func _process(delta: float) -> void:
	_age += delta
	if stars != null and stars.visible:
		stars.rotation.y += 4.0 * delta
	# He bobs gently, and puffs up a little before a burp.
	if visual != null and phase != Phase.DEFEATED:
		visual.position.y = sin(_age * 1.6) * 0.35


func _physics_process(delta: float) -> void:
	match phase:
		Phase.PART1:
			_check_head()
			_check_body()
		Phase.PART2:
			_chase_step(delta)


# ====================================================================== part 1: bubbles

func _on_trigger(body: Node3D) -> void:
	if body is Player and phase == Phase.WAITING:
		_start_fight()


func _start_fight() -> void:
	phase = Phase.INTRO
	mood = Mood.CALM
	_camera_shows_me(true)
	_move_door(true)
	var id: int = _run_id
	if scene_player != null:
		await scene_player.play(load("res://scripts/puppet/burp_hello.gd").STEPS,
			{"boss": head, "player": _player}, "burp_hello")
	if id != _run_id:
		return
	phase = Phase.PART1
	_fight(id)


## The round: 0 for the first two stomps, 1 for the next two, 2 for the last two.
func round_now() -> int:
	return clampi(int(float(hits1) * 3.0 / float(maxi(hits_part1, 1))), 0, 2)


## The patterns of bubbles he can burp: [x from the left edge, height above the floor, stinky 0/1].
## Each is a staircase or a puzzle. The first bubble is always low, so a hop reaches it.
func patterns() -> Array:
	return [
		# 0: stairs going right, up to his head.
		[[12, 2.0, 0], [18, 7.5, 0], [24, 13.0, 0]],
		# 1: stairs from the middle, both sides.
		[[26, 2.5, 0], [20, 8.0, 0], [32, 8.0, 0], [26, 13.5, 0]],
		# 2: a zig-zag, with two stinky bubbles in the gaps.
		[[10, 2.0, 0], [17, 7.5, 0], [23, 13.0, 0], [20, 4.0, 1], [14, 12.0, 1]],
		# 3: a ladder with stinky bubbles on both sides.
		[[27, 2.0, 0], [27, 8.0, 0], [27, 14.0, 0], [22, 8.0, 1], [32, 8.0, 1], [22, 14.0, 1]],
		# 4: wide and fast, a stinky bubble guarding the best path.
		[[8, 2.0, 0], [14, 8.0, 0], [21, 4.0, 0], [28, 10.0, 0], [35, 14.0, 0], [18, 12.0, 1], [31, 5.0, 1]],
	]


## Which patterns can come in each round.
func patterns_for_round(r: int) -> Array[int]:
	match r:
		0:
			return [0, 1]
		1:
			return [1, 2, 3]
	return [2, 3, 4]


func _fight(id: int) -> void:
	while id == _run_id and hits1 < hits_part1:
		mood = Mood.CALM
		await _wait(rest_time[round_now()])
		if id != _run_id:
			return
		_top_up_helpers()
		await _burp_volley(id)
		if id != _run_id:
			return
		await _wait(bubble_lifetime * 0.55)


## One volley: he opens wide, says BUUURP!, and the bubbles swell up.
func _burp_volley(id: int) -> void:
	var r: int = round_now()
	mood = Mood.TELL
	SpeechBubble.say(head, "BUUURP!", tell_time + 0.6, 2.2)
	Sfx.play(self, burp_sound)
	_open_mouth(true)
	var choices: Array[int] = patterns_for_round(r)
	var which: int = choices[_volleys % choices.size()]
	_volleys += 1
	for entry: Array in patterns()[which]:
		spawn_bubble(Vector3(arena_left_x + float(entry[0]), floor_y + float(entry[1]), 0.0), bool(entry[2]), r)
	await _wait(tell_time)
	if id != _run_id:
		return
	_open_mouth(false)
	mood = Mood.CALM


## Makes one giant bubble (used by the volleys, and by tests).
func spawn_bubble(spot: Vector3, stinky: bool, r: int = 0) -> BurpBubble:
	var bubble := BurpBubble.new()
	bubble.radius = 1.2 if stinky else 1.6
	bubble.rise_speed = rise_speed[clampi(r, 0, rise_speed.size() - 1)]
	bubble.rise_height = 0.0
	bubble.lifetime = bubble_lifetime
	bubble.respawn = false
	bubble.stinky = stinky
	bubble.grow_time = tell_time
	bubble.is_boss_shot = true
	bubble.sway = 0.25
	bubble.position = spot
	get_parent().add_child(bubble)
	return bubble


## His head: land on it from above and he takes a hit.
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
			if mood != Mood.HIT:
				_take_hit1()
		return


## His body hurts if you bump it (not while he is dizzy from a hit, and never during a scene).
func _check_body() -> void:
	if hurt_zone == null or mood == Mood.HIT:
		return
	for body: Node3D in hurt_zone.get_overlapping_bodies():
		if body is Player:
			(body as Player).hurt(global_position.x)


func _take_hit1() -> void:
	hits1 += 1
	hit.emit(hits_part1 - hits1)
	Sfx.play(self, hit_sound)
	_burst(head.global_position, Color(0.8, 0.7, 1.0))
	Loot.beans(self, 8, 5.0, 9.0, 6.0)
	if hits1 >= hits_part1:
		_leave()
		return
	_run_id += 1
	var id: int = _run_id
	_clear_shots()
	_open_mouth(false)
	mood = Mood.HIT
	_show_dizzy(true)
	SpeechBubble.say(head, "OW! MY HEAD!", 1.4, 2.2)
	_shake_camera(0.2, 0.4)
	# Long enough that bouncing straight back onto his head doesn't count twice.
	await _wait(hit_pause)
	if id != _run_id:
		return
	_show_dizzy(false)
	# Glide to a new spot (a different one each time).
	_perch = (_perch + 1) % perches.size()
	var spot: Vector2 = perches[_perch]
	var glide: Tween = create_tween()
	glide.tween_property(self, "position", Vector3(arena_left_x + spot.x, floor_y + spot.y, 0.0), 0.9)
	await glide.finished
	if id == _run_id:
		_fight(id)


## Helpers on the floor: Burplings from round 2, Whifflers too in round 3.
func _top_up_helpers() -> void:
	var r: int = round_now()
	var wanted_b: int = burplings_round2 if r >= 1 else 0
	var wanted_w: int = whifflers_round3 if r >= 2 else 0
	var alive: Array[Node] = []
	var have_b: int = 0
	for helper: Node in _helpers:
		if is_instance_valid(helper) and not bool(helper.get("is_squashed")):
			alive.append(helper)
			if not (helper is Whiffler):
				have_b += 1
	_helpers = alive
	var have_w: int = _helpers.size() - have_b
	for i in maxi(wanted_b - have_b, 0):
		_spawn_helper("res://scenes/burpling.tscn", 0.45, i)
	for i in maxi(wanted_w - have_w, 0):
		_spawn_helper("res://scenes/whiffler.tscn", 0.45, i + 2)


func _spawn_helper(scene_path: String, lift: float, slot: int) -> void:
	var scene := load(scene_path) as PackedScene
	if scene == null:
		return
	var thing: Node3D = scene.instantiate()
	var xs: Array[float] = [6.0, 54.0, 18.0, 44.0]
	thing.position = Vector3(arena_left_x + xs[slot % 4], floor_y + lift, 0.0)
	get_parent().add_child(thing)
	_helpers.append(thing)


func _clear_helpers() -> void:
	for helper: Node in _helpers:
		if is_instance_valid(helper):
			helper.queue_free()
	_helpers.clear()


# ====================================================================== between the parts

## Part 1 is won: the goodbye-for-now scene (he flies off in a huff), then the burrito.
func _leave() -> void:
	phase = Phase.LEAVING
	_run_id += 1
	_clear_shots()
	_clear_helpers()
	_open_mouth(false)
	mood = Mood.CALM
	_show_calm()
	part_one_won.emit()
	if scene_player != null:
		await scene_player.play(load("res://scripts/puppet/burp_leaves.gd").STEPS,
			{"boss": head, "player": _player, "burp": self}, "burp_leaves")
	_arrive_burrito()


## The leaving scene calls this: he flies off into the sky.
func fly_off() -> void:
	_shake_camera(0.3, 0.6)
	Sfx.play(self, defeat_sound)
	_leave_tween = create_tween()
	_leave_tween.set_parallel(true)
	_leave_tween.tween_property(self, "position", position + Vector3(70.0, 30.0, 0.0), 1.6).set_ease(Tween.EASE_IN)
	_leave_tween.tween_property(visual, "rotation:z", -TAU, 1.6)
	_leave_tween.chain().tween_callback(func() -> void: visual.visible = false)


## Opens the way on: the door, the wall on the right, the Rocket Burrito.
func _arrive_burrito() -> void:
	if phase == Phase.DEFEATED:
		return
	phase = Phase.BURRITO
	_camera_shows_me(false)
	_move_door(false)
	if is_instance_valid(gate):
		gate.queue_free()
	drop_burrito()


## The scene (or the end of part 1) calls this: a Rocket Burrito falls from the sky.
func drop_burrito() -> void:
	if burrito == null:
		return
	burrito.visible = true
	burrito.monitoring = true
	burrito.position = _burrito_home + Vector3(0.0, 14.0, 0.0)
	var tween: Tween = create_tween()
	tween.tween_property(burrito, "position", _burrito_home, 0.9).set_ease(Tween.EASE_IN)


# ====================================================================== part 2: the ring chase

func _on_flight_started() -> void:
	if phase == Phase.BURRITO:
		_start_chase()


func _start_chase() -> void:
	if _leave_tween != null:
		_leave_tween.kill()
	phase = Phase.PART2
	mood = Mood.CALM
	_run_id += 1
	var id: int = _run_id
	_clear_shots()
	gap = chase_gap
	_target_y = (lane.x + lane.y) * 0.5
	visual.visible = true
	_show_calm()
	position = Vector3(_player.global_position.x + gap, _target_y, 0.0)
	_chase_loop(id)


func _chase_loop(id: int) -> void:
	await _wait(1.5)
	while id == _run_id and hits2 < hits_part2:
		var r: int = clampi(hits2, 0, attacks_per_round.size() - 1)
		for i in attacks_per_round[r]:
			if id != _run_id:
				return
			await _chase_attack(id, i)
		if id != _run_id:
			return
		await _chase_dizzy(id)
		if id != _run_id:
			return
		await _wait(1.2)


## He roams to a new height, opens wide (the warning), then burps a ring or a wall of stinky bubbles.
func _chase_attack(id: int, index: int) -> void:
	_target_y = randf_range(lane.x + 3.0, lane.y - 3.0)
	mood = Mood.TELL
	SpeechBubble.say(head, "BUUURP!", 1.2, 2.2)
	Sfx.play(self, burp_sound)
	_open_mouth(true)
	await _wait(0.9)
	if id != _run_id:
		return
	_open_mouth(false)
	mood = Mood.CALM
	if index % 2 == 0:
		spawn_ring()
	else:
		spawn_bubble_wall()
	await _wait(maxf(2.0 - 0.2 * float(hits2), 1.2))


## A ring whose hole is near where Fart Man is flying (a little off, so he has to steer).
func spawn_ring() -> BurpRing:
	var ring := BurpRing.new()
	ring.gap_height = ring_gap
	var aim: float = _player.global_position.y + randf_range(-3.0, 3.0)
	ring.position = Vector3(position.x - 2.0, clampf(aim, lane.x + ring_gap * 0.5, lane.y - ring_gap * 0.5), 0.0)
	get_parent().add_child(ring)
	return ring


## A row of stinky bubbles drifting towards him, with a gap near where he is flying.
func spawn_bubble_wall() -> Array[BurpBubble]:
	var made: Array[BurpBubble] = []
	var gap_y: float = clampf(_player.global_position.y + randf_range(-2.5, 2.5), lane.x + 2.0, lane.y - 2.0)
	var y: float = lane.x - 1.0
	while y <= lane.y + 2.0:
		if absf(y - gap_y) > ring_gap * 0.5:
			var bubble := BurpBubble.new()
			bubble.radius = 1.5
			bubble.stinky = true
			bubble.rise_speed = 0.0
			bubble.rise_height = 0.0
			bubble.drift_x = -4.0
			bubble.sway = 0.0
			bubble.lifetime = 9.0
			bubble.respawn = false
			bubble.is_boss_shot = true
			bubble.position = Vector3(position.x - 2.0, y, 0.0)
			get_parent().add_child(bubble)
			made.append(bubble)
		y += 3.4
	return made


## Dizzy: he slows down. Fly into him! If you miss, he shakes it off and zooms ahead.
func _chase_dizzy(id: int) -> void:
	mood = Mood.DIZZY
	_show_dizzy(true)
	SpeechBubble.say(head, "BLEUGH... TUMMY!", 1.6, 2.2)
	var waited: float = 0.0
	while mood == Mood.DIZZY and id == _run_id and waited < dizzy_time and gap > -6.0:
		await get_tree().physics_frame
		waited += 1.0 / 60.0
	if id != _run_id or mood != Mood.DIZZY:
		return
	# Nobody bumped him: he shakes it off and zooms away.
	mood = Mood.CALM
	_show_dizzy(false)
	SpeechBubble.say(head, "HA HA! TOO SLOW!", 1.2, 2.2)
	_set_gap(chase_gap, 1.5)


## Every frame of the chase: stay ahead of Fart Man (or slow down if dizzy) and check for bumps.
func _chase_step(delta: float) -> void:
	if _player == null or not visual.visible:
		return
	if mood == Mood.DIZZY:
		gap -= dizzy_gap_speed * delta
		# While dizzy he drifts towards Fart Man's height, so he is always catchable.
		_target_y = move_toward(_target_y, _player.global_position.y, 2.5 * delta)
	if wrap_at_x > 0.0 and _player.global_position.x > wrap_at_x:
		_player.global_position.x -= wrap_back
		_clear_shots()
	position.x = _player.global_position.x + gap
	position.y = lerpf(position.y, clampf(_target_y, lane.x, lane.y), 1.0 - exp(-3.0 * delta))
	if mood == Mood.HIT:
		return
	var touching: bool = _touching_player()
	if touching and mood == Mood.DIZZY:
		_chase_hit()
	elif touching and _player != null:
		_player.hurt(global_position.x)


func _touching_player() -> bool:
	for zone: Area3D in [head, hurt_zone]:
		if zone == null:
			continue
		for body: Node3D in zone.get_overlapping_bodies():
			if body is Player:
				return true
	return false


func _chase_hit() -> void:
	hits2 += 1
	mood = Mood.HIT
	hit.emit(hits_part2 - hits2)
	Sfx.play(self, hit_sound)
	_burst(global_position, Color(0.8, 0.7, 1.0))
	Loot.beans(self, 10, 7.0, 8.0, 6.0)
	_shake_camera(0.25, 0.4)
	_show_dizzy(false)
	_clear_shots()
	if hits2 >= hits_part2:
		_defeat()
		return
	SpeechBubble.say(head, "OW! MY TUMMY!", 1.4, 2.2)
	_set_gap(chase_gap, 1.3)
	var id: int = _run_id
	await _wait(1.3)
	if id == _run_id and mood == Mood.HIT:
		mood = Mood.CALM


func _set_gap(value: float, seconds: float) -> void:
	if _gap_tween != null:
		_gap_tween.kill()
	_gap_tween = create_tween()
	_gap_tween.tween_property(self, "gap", value, seconds)


# ====================================================================== the ending

func _defeat() -> void:
	phase = Phase.DEFEATED
	_run_id += 1
	mood = Mood.CALM
	_clear_shots()
	defeated.emit()
	_ending()


## He lands next to Fart Man, they have a little talk, and then the biggest fart in history.
func _ending() -> void:
	if _player.is_flying():
		_player.stop_flying()
	var waited: float = 0.0
	while not _player.is_on_floor() and waited < 5.0:
		await get_tree().physics_frame
		waited += 1.0 / 60.0
	_show_calm()
	var feet: float = _player.get_feet_y()
	var tween: Tween = create_tween()
	tween.tween_property(self, "position", Vector3(_player.global_position.x + 6.0, feet + 3.0, 0.0), 1.0)
	await tween.finished
	if scene_player != null:
		await scene_player.play(load("res://scripts/puppet/burp_ending.gd").STEPS,
			{"boss": head, "player": _player, "burp": self}, "burp_ending")
	# Let the cloud and the last bean shower finish, even if the scene was skipped.
	await _wait(2.2)
	finish()


## The very last thing: the ending storybook, then the map.
func finish() -> void:
	StoryEnding.go(self)


## Scene step: Fart Man feeds him a bean.
func eat_bean() -> void:
	var bean := MeshInstance3D.new()
	var shape := SphereMesh.new()
	shape.radius = 0.3
	shape.height = 0.7
	var paint := StandardMaterial3D.new()
	paint.albedo_color = Color(0.85, 0.65, 0.3)
	shape.material = paint
	bean.mesh = shape
	get_parent().add_child(bean)
	bean.global_position = _player.global_position + Vector3(0, 0.6, 0.5)
	var arc: Tween = bean.create_tween()
	arc.tween_property(bean, "global_position", global_position + Vector3(0, 0.5, 1.5), 0.7)
	arc.tween_callback(bean.queue_free)
	_open_mouth(true)
	get_tree().create_timer(0.9).timeout.connect(func() -> void: _open_mouth(false))


## Scene step: his tummy rumbles and wobbles.
func rumble() -> void:
	_shake_camera(0.15, 1.5)
	if visual == null:
		return
	var tween: Tween = create_tween()
	tween.tween_property(visual, "scale", Vector3(1.25, 0.85, 1.25), 0.25)
	tween.tween_property(visual, "scale", Vector3(0.85, 1.25, 0.85), 0.25)
	tween.tween_property(visual, "scale", Vector3(1.35, 0.8, 1.35), 0.2)
	tween.tween_property(visual, "scale", Vector3.ONE, 0.2)


## Scene step: THE BIGGEST FART IN HISTORY. A huge cloud, a shaking screen, the factory cork
## pops out far away, and beans rain down on the whole world.
func big_fart() -> void:
	Sfx.play(self, defeat_sound)
	_shake_camera(0.7, 2.5)
	var holder: Node = get_parent()
	for i in 14:
		var puff := MeshInstance3D.new()
		var ball := SphereMesh.new()
		ball.radius = 1.0
		ball.height = 2.0
		var paint := StandardMaterial3D.new()
		paint.albedo_color = Color(0.6, 0.85, 0.3, 0.55)
		paint.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		ball.material = paint
		puff.mesh = ball
		holder.add_child(puff)
		puff.global_position = global_position + Vector3(randf_range(-2, 2), randf_range(-1, 2), randf_range(0, 2))
		var grow: Tween = puff.create_tween()
		grow.set_parallel(true)
		grow.tween_property(puff, "scale", Vector3.ONE * randf_range(5.0, 9.0), 1.6)
		grow.tween_property(puff, "global_position:x", puff.global_position.x - 8.0 + float(i) * 1.2, 1.6)
		grow.chain().tween_callback(puff.queue_free)
	# The factory cork, far away, pops out of the sky.
	var cork := MeshInstance3D.new()
	var plug := CylinderMesh.new()
	plug.top_radius = 6.0
	plug.bottom_radius = 6.0
	plug.height = 2.0
	var tan := StandardMaterial3D.new()
	tan.albedo_color = Color(0.78, 0.58, 0.32)
	plug.material = tan
	cork.mesh = plug
	holder.add_child(cork)
	cork.global_position = global_position + Vector3(-20, -2, -25)
	cork.rotation_degrees = Vector3(90, 0, 0)
	var fly: Tween = cork.create_tween()
	fly.set_parallel(true)
	fly.tween_property(cork, "global_position:y", global_position.y + 90.0, 2.2).set_ease(Tween.EASE_IN)
	fly.tween_property(cork, "rotation:z", TAU * 3.0, 2.2)
	fly.chain().tween_callback(cork.queue_free)
	# Beans rain on the whole world, in three big showers.
	for shower in 3:
		get_tree().create_timer(0.4 + 0.5 * float(shower)).timeout.connect(_rain_beans)
	# He is blown backwards, spinning, then settles feeling MUCH better.
	var blast: Tween = create_tween()
	blast.tween_property(self, "position:x", position.x + 4.0, 0.4).set_ease(Tween.EASE_OUT)
	blast.tween_property(self, "position:x", position.x, 1.2)


## One shower of beans (the fart calls three of these).
func _rain_beans() -> void:
	if is_inside_tree():
		Loot.beans(self, 24, 16.0, 11.0, 0.0)


# ====================================================================== bits and pieces

## He is ready to start over: Fart Man went back to a toilet.
func _reset() -> void:
	if phase == Phase.DEFEATED or phase == Phase.WAITING or phase == Phase.LEAVING:
		return
	_run_id += 1
	_clear_shots()
	_clear_helpers()
	mood = Mood.CALM
	_show_calm()
	_open_mouth(false)
	match phase:
		Phase.INTRO, Phase.PART1:
			# Part 1 starts again, but the stomps he already took stay.
			phase = Phase.WAITING
			_camera_shows_me(false)
			position = Vector3(arena_left_x + perches[_perch].x, floor_y + perches[_perch].y, 0.0)
			if is_instance_valid(door):
				door.position.y = _door_closed_y - door_drop
		Phase.PART2:
			if _player != null and _player.is_flying():
				# Back at a toilet in the sky: the chase starts again, the hits he took stay.
				phase = Phase.BURRITO
				_start_chase()
			else:
				phase = Phase.BURRITO
				visual.visible = false


func _clear_shots() -> void:
	for shot: Node in get_tree().get_nodes_in_group(&"boss_shots"):
		shot.queue_free()


func _open_mouth(yes: bool) -> void:
	if mouth == null:
		return
	var tween: Tween = create_tween()
	tween.tween_property(mouth, "scale", Vector3(1.5, 2.2, 1.0) if yes else Vector3.ONE, 0.2)


func _show_dizzy(yes: bool) -> void:
	if stars != null:
		stars.visible = yes


func _show_calm() -> void:
	if stars != null:
		stars.visible = false
	if visual != null:
		visual.scale = Vector3.ONE
		visual.rotation = Vector3.ZERO
		visual.visible = true
	if mouth != null:
		mouth.scale = Vector3.ONE


func _move_door(shut: bool) -> void:
	if not is_instance_valid(door):
		return
	var tween: Tween = create_tween()
	tween.tween_property(door, "position:y", _door_closed_y if shut else _door_closed_y - door_drop, 0.4)


func _camera_shows_me(yes: bool) -> void:
	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera == null or not camera.has_method("show_too"):
		return
	if yes:
		camera.call("show_too", self)
	else:
		camera.call("stop_showing", self)


func _burst(at: Vector3, color: Color) -> void:
	var holder: Node = get_parent()
	for i in 10:
		var bit := MeshInstance3D.new()
		var ball := SphereMesh.new()
		ball.radius = 0.3
		ball.height = 0.6
		var paint := StandardMaterial3D.new()
		paint.albedo_color = color
		ball.material = paint
		bit.mesh = ball
		holder.add_child(bit)
		bit.global_position = at
		var angle: float = TAU * float(i) / 10.0
		var goal: Vector3 = at + Vector3(cos(angle) * 3.0, sin(angle) * 3.0, 0.0)
		var tween: Tween = bit.create_tween()
		tween.tween_property(bit, "global_position", goal, 0.6)
		tween.tween_callback(bit.queue_free)


func _shake_camera(strength: float, seconds: float) -> void:
	_shaking_camera = get_viewport().get_camera_3d()
	if _shaking_camera == null:
		return
	_shake_strength = strength
	if _shake_tween != null:
		_shake_tween.kill()
	_shake_tween = create_tween()
	_shake_tween.set_loops(maxi(1, int(seconds / 0.05)))
	_shake_tween.tween_callback(_shake_step)
	_shake_tween.tween_interval(0.05)
	get_tree().create_timer(seconds).timeout.connect(_shake_end)


func _shake_step() -> void:
	if is_instance_valid(_shaking_camera):
		_shaking_camera.h_offset = randf_range(-_shake_strength, _shake_strength)
		_shaking_camera.v_offset = randf_range(-_shake_strength, _shake_strength)


func _shake_end() -> void:
	if _shake_tween != null:
		_shake_tween.kill()
	if is_instance_valid(_shaking_camera):
		_shaking_camera.h_offset = 0.0
		_shaking_camera.v_offset = 0.0


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
