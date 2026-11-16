class_name SneezyWeezy
extends Area3D
## Boss 1: Sneezy Weezy, a giant flower with terrible hay fever.
##
## She winds up ("AH... AH...") and sneezes clouds of pollen along the floor: jump over them.
## After three sneezes she droops, worn out. Stomp her head while it is low!
## Three stomps wins. Each time she gets faster, and in the last round petals fall too.
## The pollen and petals come from pollen.gd and falling_petal.gd.

## Sent each time she is stomped, with how many stomps are left.
signal hit(hits_left: int)
## Sent when she is beaten and the gate has opened.
signal defeated

enum State { WAITING, INTRO, IDLE, WINDUP, TIRED, HIT, DEFEATED }

@export_group("The fight")
@export var hits_to_win: int = 3
@export var sneezes_per_round: int = 3
## Pauses, in seconds.
@export var idle_time: float = 1.0
@export var windup_time: float = 0.9
@export var between_sneezes: float = 0.4
## How long she stays drooped, open to being stomped.
@export var tired_time: float = 5.0

@export_group("Pollen (round 1, 2, 3)")
## Pollen speed in each round, in metres per second.
@export var pollen_speed: Array[float] = [4.5, 6.0, 7.5]
## Clouds per sneeze in each round.
@export var pollen_per_sneeze: Array[int] = [1, 2, 2]
## Seconds between clouds of the same sneeze.
@export var pollen_gap: float = 0.8
## Falling petals per sneeze in each round (they drop near him).
@export var petals_per_sneeze: Array[int] = [0, 0, 1]
## Where clouds start, compared to her base, and where they disappear.
@export var pollen_offset: Vector3 = Vector3(-1.5, 0.4, 0)
@export var arena_left_x: float = -9.0
## The floor's top height, for the petal warnings.
@export var floor_y: float = 0.5

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

var state: State = State.WAITING
var hits: int = 0
var _run_id: int = 0
var _gate_opened: bool = false
var _player: Player


func _ready() -> void:
	_player = get_tree().get_first_node_in_group(&"player") as Player
	if trigger != null:
		trigger.body_entered.connect(_on_trigger)
	if _player != null:
		_player.respawned.connect(_reset)
	if head != null:
		head.position = head_up


func _physics_process(_delta: float) -> void:
	if state == State.WAITING or state == State.DEFEATED:
		return
	# Her stalk hurts to touch.
	for body: Node3D in get_overlapping_bodies():
		if body is Player:
			(body as Player).hurt(global_position.x)
	_check_head()


## The head: stompable when she is tired, a harmless bouncy ball otherwise.
func _check_head() -> void:
	if head == null:
		return
	for body: Node3D in head.get_overlapping_bodies():
		var player := body as Player
		if player == null:
			continue
		var above: bool = player.get_feet_y() > head.global_position.y - 0.1 or absf(player.global_position.x - head.global_position.x) < 0.8
		if player.can_stomp() and above:
			player.stomp_bounce()
			if state == State.TIRED:
				_take_hit()
			else:
				SpeechBubble.say(head, "TICKLES!", 0.6, 1.6)
		elif state != State.TIRED:
			player.hurt(head.global_position.x)
		return


func _on_trigger(body: Node3D) -> void:
	if body is Player and state == State.WAITING:
		_start_fight()


func _start_fight() -> void:
	state = State.INTRO
	var id: int = _run_id
	if scene_player != null:
		await scene_player.play(load("res://scripts/puppet/sneezy_hello.gd").STEPS,
			{"boss": head, "player": _player}, "sneezy_hello")
	if id != _run_id:
		return
	_fight(id)


## One run of the whole fight: idle, three sneezes, tired, and again until beaten.
func _fight(id: int) -> void:
	while id == _run_id and hits < hits_to_win:
		state = State.IDLE
		await _wait(idle_time)
		var round_now: int = clampi(hits, 0, pollen_speed.size() - 1)
		for i in sneezes_per_round:
			if id != _run_id:
				return
			await _sneeze(round_now, id)
			await _wait(between_sneezes)
		if id != _run_id:
			return
		await _be_tired(id)


## Winds up, then lets rip.
func _sneeze(round_now: int, id: int) -> void:
	state = State.WINDUP
	SpeechBubble.say(head, "AH... AH...", windup_time, 1.6)
	var tween: Tween = create_tween()
	tween.tween_property(face, "scale", Vector3.ONE * 1.3, windup_time)
	await _wait(windup_time)
	if id != _run_id:
		return
	face.scale = Vector3.ONE
	SpeechBubble.say(head, "ACHOO!", 0.8, 1.6)
	for i in pollen_per_sneeze[round_now]:
		Pollen.launch(get_parent(), global_position + pollen_offset, pollen_speed[round_now], arena_left_x)
		if i < pollen_per_sneeze[round_now] - 1:
			await _wait(pollen_gap)
			if id != _run_id:
				return
	if _player != null:
		for i in petals_per_sneeze[round_now]:
			FallingPetal.drop(get_parent(), _player.global_position.x + (i - 0.5) * 3.0, floor_y)


## Droops down and waits to be stomped.
func _be_tired(id: int) -> void:
	state = State.TIRED
	SpeechBubble.say(head, "*WHEEZE*", tired_time, 1.6)
	var tween: Tween = create_tween()
	tween.tween_property(head, "position", head_down, 0.5)
	var waited: float = 0.0
	while waited < tired_time and state == State.TIRED and id == _run_id:
		await get_tree().create_timer(0.1).timeout
		waited += 0.1
	if state == State.TIRED and id == _run_id:
		# Nobody stomped her: she perks up again.
		_raise_head()


func _take_hit() -> void:
	hits += 1
	hit.emit(hits_to_win - hits)
	_burst_petals()
	if hits >= hits_to_win:
		_defeat()
		return
	state = State.HIT
	SpeechBubble.say(head, "ACHOO! OW!", 1.0, 1.6)
	_raise_head()


func _raise_head() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(head, "position", head_up, 0.5)


func _defeat() -> void:
	state = State.DEFEATED
	_run_id += 1
	_clear_shots()
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
	_run_id += 1
	_clear_shots()
	state = State.WAITING
	if head != null:
		face.scale = Vector3.ONE
		head.position = head_up


func _clear_shots() -> void:
	for shot: Node in get_tree().get_nodes_in_group(&"boss_shots"):
		shot.queue_free()


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
