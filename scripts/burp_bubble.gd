class_name BurpBubble
extends Area3D
## A Burp Bubble. It floats upwards slowly. LAND ON TOP of it and it pops and bounces you very high!
## Touching it from the side or below does nothing. A STINKY (green) bubble hurts if you touch it,
## so keep away. Big Bad Burp burps giant ones in his fight (the same script, just bigger).
## The looks are made here in code, from the settings below.

## Sent when it pops.
signal popped

@export_group("Bubble")
## How big the bubble is (radius in metres).
@export var radius: float = 0.9
## How fast it floats up, and how far it floats before it pops by itself (0 = never).
@export var rise_speed: float = 1.2
@export var rise_height: float = 7.0
## Sideways drift, metres per second (negative = left). Used for bubbles burped in flight.
@export var drift_x: float = 0.0
## How far it sways left and right while floating.
@export var sway: float = 0.4
## Launch speed when stomped. 22 = about 9.7 metres high. Hold jump for a little more.
@export var bounce_power: float = 22.0
@export var high_bounce_power: float = 25.0
## Green and nasty: it hurts, and it cannot be stomped.
@export var stinky: bool = false
## After popping (or floating away) it comes back at its start after this many seconds.
## Turn off for bubbles that are burped once (the boss fight).
@export var respawn: bool = true
@export var respawn_delay: float = 2.5
## A new bubble swells up from nothing for this long first, so you see it coming.
@export var grow_time: float = 0.0
## 0 = floats until it reaches rise_height. More than 0 = pops by itself after this many seconds.
@export var lifetime: float = 0.0
## Tick for bubbles burped by a boss: they are cleared when the fight restarts.
@export var is_boss_shot: bool = false
## The pop.
@export var pop_sound: AudioStream

var is_alive: bool = true
var _home: Vector3
var _age: float = 0.0
var _gone_for: float = 0.0
var _body: Node3D
var _shape: CollisionShape3D


func _ready() -> void:
	_home = position
	if is_boss_shot:
		add_to_group(&"boss_shots")
	_build()
	_show(true)


func _physics_process(delta: float) -> void:
	if not is_alive:
		_gone_for += delta
		if respawn and _gone_for >= respawn_delay:
			_revive()
		return
	_age += delta
	position.y += rise_speed * delta
	position.x += drift_x * delta
	position.x += cos(_age * 1.3 + _home.x) * sway * delta
	var grown: float = 1.0 if grow_time <= 0.0 else clampf(_age / grow_time, 0.0, 1.0)
	_body.scale = Vector3.ONE * (0.25 + 0.75 * grown) * (1.0 + 0.04 * sin(_age * 4.0))
	if (lifetime > 0.0 and _age >= lifetime) or (lifetime <= 0.0 and rise_height > 0.0 and position.y - _home.y >= rise_height):
		_vanish()
		return
	if grown < 1.0:
		return
	for body: Node3D in get_overlapping_bodies():
		var player := body as Player
		if player == null or player.is_dying:
			continue
		if stinky:
			player.hurt(global_position.x)
		elif _is_on_top(player):
			_launch(player)
			return


func _is_on_top(player: Player) -> bool:
	return player.velocity.y <= 0.5 and player.get_feet_y() > global_position.y - 0.1 \
		and not player.is_flying()


func _launch(player: Player) -> void:
	var holding: bool = Input.is_action_pressed(player.jump_action) or player.fart_held()
	player.velocity.y = high_bounce_power if holding else bounce_power
	player.air_farts_used = 0
	player.stomp_window_left = 0.0
	if player.simple_helper != null:
		player.simple_helper.refill_air_jumps()
	if player.gas_tank != null:
		player.gas_tank.refill(10.0)
	Stage.award(self, 25)
	Sfx.play(self, pop_sound)
	popped.emit()
	_vanish()


## Pops and disappears (and comes back later, if it is the respawning kind).
func _vanish() -> void:
	is_alive = false
	_gone_for = 0.0
	_show(false)
	if not respawn:
		get_tree().create_timer(0.3).timeout.connect(queue_free)


func _revive() -> void:
	is_alive = true
	_age = 0.0
	position = _home
	_show(true)


func _show(yes: bool) -> void:
	_body.visible = yes
	_shape.set_deferred("disabled", not yes)


func _build() -> void:
	_body = Node3D.new()
	_body.name = "Body"
	add_child(_body)
	var ball := SphereMesh.new()
	ball.radius = radius
	ball.height = radius * 2.0
	var paint := StandardMaterial3D.new()
	paint.albedo_color = Color(0.55, 0.9, 0.35, 0.55) if stinky else Color(0.75, 0.6, 1.0, 0.5)
	paint.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	paint.emission_enabled = true
	paint.emission = Color(0.2, 0.5, 0.1) if stinky else Color(0.3, 0.2, 0.5)
	ball.material = paint
	var shell := MeshInstance3D.new()
	shell.mesh = ball
	_body.add_child(shell)
	# A bright shine so it reads as a bubble.
	var shine := SphereMesh.new()
	shine.radius = radius * 0.22
	shine.height = radius * 0.44
	var white := StandardMaterial3D.new()
	white.albedo_color = Color(1, 1, 1, 0.9)
	shine.material = white
	var spot := MeshInstance3D.new()
	spot.mesh = shine
	spot.position = Vector3(-radius * 0.4, radius * 0.45, radius * 0.7)
	_body.add_child(spot)
	if stinky:
		# Two dark stink lines on the front.
		for i in 2:
			var wavy := BoxMesh.new()
			wavy.size = Vector3(0.12, radius * 0.7, 0.12)
			var dark := StandardMaterial3D.new()
			dark.albedo_color = Color(0.15, 0.4, 0.1)
			wavy.material = dark
			var line := MeshInstance3D.new()
			line.mesh = wavy
			line.position = Vector3(-radius * 0.3 + i * radius * 0.6, radius * 0.1, radius * 0.9)
			_body.add_child(line)
	_shape = CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = radius
	_shape.shape = sphere
	add_child(_shape)
