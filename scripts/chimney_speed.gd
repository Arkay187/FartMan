class_name ChimneySpeed
extends Area3D
## A speed-up tunnel. While Fart Man flies through it, everything goes faster (the screen
## speeds up!). Streaky speed lines whoosh past to show it. Harmless, just exciting.

## How much faster he flies in here (1.5 = one and a half times as fast).
@export var speed_up: float = 1.5
## How long the tunnel is, in metres, and how tall (the same size as its zone).
@export var length: float = 200.0
@export var height: float = 20.0
## What he says when he zooms in. Leave empty for nothing.
@export var words: String = "WHOOOOSH!"

var _streaks: Array[MeshInstance3D] = []
var _said: bool = false


func _ready() -> void:
	_build()
	body_entered.connect(_on_enter)


func _physics_process(delta: float) -> void:
	for body: Node3D in get_overlapping_bodies():
		var player := body as Player
		if player != null and player.is_flying():
			player.flight.speed_scale = maxf(player.flight.speed_scale, speed_up)
	# The speed lines slide backwards, and loop round when they reach the end.
	for streak in _streaks:
		streak.position.x -= 30.0 * delta
		if streak.position.x < -length * 0.5:
			streak.position.x += length


func _on_enter(body: Node3D) -> void:
	if body is Player and not _said and words != "":
		_said = true
		(body as Player).say(words, 1.2)


func _build() -> void:
	# A faint orange glow so the tunnel can be seen.
	var glow := BoxMesh.new()
	glow.size = Vector3(length, height, 0.2)
	var haze := StandardMaterial3D.new()
	haze.albedo_color = Color(1.0, 0.6, 0.2, 0.1)
	haze.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glow.material = haze
	var wall := MeshInstance3D.new()
	wall.mesh = glow
	wall.position = Vector3(0, 0, -1.8)
	add_child(wall)
	# Long thin bright speed lines.
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 40:
		var line := BoxMesh.new()
		line.size = Vector3(rng.randf_range(4.0, 9.0), 0.12, 0.12)
		var white := StandardMaterial3D.new()
		white.albedo_color = Color(1.0, 0.95, 0.8, 0.7)
		white.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		white.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		line.material = white
		var streak := MeshInstance3D.new()
		streak.mesh = line
		streak.position = Vector3(rng.randf_range(-length * 0.5, length * 0.5),
			rng.randf_range(-height * 0.5, height * 0.5), rng.randf_range(-1.5, 3.0))
		add_child(streak)
		_streaks.append(streak)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(length, height, 4.0)
	shape.shape = box
	add_child(shape)
