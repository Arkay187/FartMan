class_name SteamCloud
extends Area3D
## A thick cloud of bean steam. You can't see through it, so whatever is inside (beans, a
## Golden Bean, a ring) is a surprise. It is always safe: nothing nasty hides in here.
## The looks are made here in code.

## Sent when Fart Man flies in, and when he comes out the other side.
signal entered
signal left

## How big the cloud is, in metres (width, height).
@export var size: Vector2 = Vector2(12.0, 10.0)
## What he says the first time he goes in. Leave empty for nothing.
@export var words: String = "SMELLS LIKE BEANS!"
## The hiss as he flies in.
@export var enter_sound: AudioStream

var player_inside: bool = false
var _age: float = 0.0
var _puffs: Array[MeshInstance3D] = []
var _said: bool = false


func _ready() -> void:
	_build()
	body_entered.connect(_on_enter)
	body_exited.connect(_on_exit)


func _physics_process(delta: float) -> void:
	_age += delta
	# The puffs slowly bubble about so the cloud looks alive.
	for i in _puffs.size():
		var puff := _puffs[i]
		var wobble: float = 1.0 + 0.08 * sin(_age * 1.5 + float(i) * 1.7)
		puff.scale = Vector3.ONE * wobble


func _on_enter(body: Node3D) -> void:
	if not (body is Player):
		return
	player_inside = true
	Sfx.play(self, enter_sound)
	if not _said and words != "":
		_said = true
		(body as Player).say(words, 1.5)
	entered.emit()


func _on_exit(body: Node3D) -> void:
	if not (body is Player):
		return
	player_inside = false
	left.emit()


func _build() -> void:
	# A big clump of overlapping soft balls, almost solid so you can't see inside.
	var paint := StandardMaterial3D.new()
	paint.albedo_color = Color(0.95, 0.88, 0.7, 0.93)
	paint.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var count: int = 9
	for i in count:
		var t: float = float(i) / float(count - 1)
		var ball := SphereMesh.new()
		var r: float = size.y * (0.38 + 0.12 * sin(float(i) * 2.3))
		ball.radius = r
		ball.height = r * 2.0
		ball.material = paint
		var puff := MeshInstance3D.new()
		puff.mesh = ball
		puff.position = Vector3(lerpf(-size.x * 0.5 + r * 0.7, size.x * 0.5 - r * 0.7, t),
			sin(float(i) * 1.9) * size.y * 0.15, sin(float(i) * 2.9) * 1.2)
		add_child(puff)
		_puffs.append(puff)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(size.x, size.y, 4.0)
	shape.shape = box
	add_child(shape)
