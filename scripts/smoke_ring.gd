class_name SmokeRing
extends Area3D
## A puffy smoke ring in the sky. Fly through it for bonus points and a trail of bonus beans.
## Fly through several in a row and the bonus gets bigger (a chain).
## The looks are made here in code.

## Sent when Fart Man goes through. chain = how many rings in a row (1 for the first).
signal passed(chain: int)

## Points for one ring. A chain multiplies this (2 rings in a row = double, and so on).
@export var points: int = 20
## The biggest the chain multiplier can get.
@export var max_chain: int = 5
## How long he has to reach the next ring to keep the chain going, in seconds.
@export var chain_window: float = 3.0
## Beans that pop out of the ring when he flies through.
@export var bonus_beans: int = 3
## Tick for a ring lying flat, to fly up through (inside a chimney).
@export var flat: bool = false
## How big the ring is, in metres across the hole.
@export var radius: float = 2.2

## When the chain last grew (in game seconds) and how long it is. Shared by all rings.
static var _chain_time: float = -1000.0
static var _chain_count: int = 0

var is_done: bool = false
var _age: float = 0.0
var _body: Node3D


func _ready() -> void:
	_build()
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	_age += delta
	if _body != null and not is_done:
		# Breathes in and out, like a real smoke ring.
		var breathe: float = 1.0 + 0.06 * sin(_age * 3.0 + position.x)
		_body.scale = Vector3.ONE * breathe


## Forgets the chain (used when a stage starts, and by tests).
static func reset_chain() -> void:
	_chain_time = -1000.0
	_chain_count = 0


func _on_body_entered(body: Node3D) -> void:
	if is_done or not (body is Player):
		return
	is_done = true
	var now: float = float(Engine.get_physics_frames()) / float(Engine.physics_ticks_per_second)
	if now - _chain_time <= chain_window:
		_chain_count += 1
	else:
		_chain_count = 1
	_chain_time = now
	var multiplier: int = mini(_chain_count, max_chain)
	Stage.award(self, points * multiplier)
	if multiplier > 1:
		SpeechBubble.say(body as Node3D, "x%d!" % multiplier, 0.8, 1.8)
	_pop_beans(body as Node3D)
	_fade_away()
	passed.emit(_chain_count)


## Bonus beans fly out ahead of him (or above him, in a chimney) in a little arc.
func _pop_beans(player: Node3D) -> void:
	var bean_scene := load("res://scenes/bean.tscn") as PackedScene
	if bean_scene == null or get_parent() == null:
		return
	for i in bonus_beans:
		var bean := bean_scene.instantiate() as Node3D
		get_parent().add_child(bean)
		var step: float = 2.5 * (i + 1)
		var wiggle: float = 0.8 * sin(float(i) * 1.6)
		if flat:
			bean.global_position = global_position + Vector3(wiggle, step, 0)
		else:
			bean.global_position = global_position + Vector3(step, wiggle, 0)


## The ring turns gold, swells and fades.
func _fade_away() -> void:
	if _body == null:
		return
	for part: Node in _body.get_children():
		if part is MeshInstance3D:
			var gold := StandardMaterial3D.new()
			gold.albedo_color = Color(1.0, 0.85, 0.2, 0.8)
			gold.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			(part as MeshInstance3D).material_override = gold
	var tween: Tween = create_tween()
	tween.tween_property(_body, "scale", Vector3.ONE * 1.8, 0.4)
	tween.tween_callback(queue_free)


func _build() -> void:
	_body = Node3D.new()
	_body.name = "Puff"
	add_child(_body)
	# A fat torus of grey smoke. Turned a little so it reads as a ring from the side.
	var torus := TorusMesh.new()
	torus.inner_radius = radius * 0.7
	torus.outer_radius = radius * 1.0
	var smoke := StandardMaterial3D.new()
	smoke.albedo_color = Color(0.82, 0.8, 0.78, 0.85)
	smoke.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	torus.material = smoke
	var ring := MeshInstance3D.new()
	ring.mesh = torus
	ring.rotation_degrees = Vector3(0, 0, 0) if flat else Vector3(0, 25, 90)
	_body.add_child(ring)
	# The zone you fly through: thin across the flight direction, as big as the hole.
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(radius * 1.3, 0.8, 3.0) if flat else Vector3(0.8, radius * 1.3, 3.0)
	shape.shape = box
	add_child(shape)
