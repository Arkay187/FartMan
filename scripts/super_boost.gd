class_name SuperBoost
extends Area3D
## A SUPER BOOST: a glowing tunnel in a flying stage. Fly in and the world rushes past
## 3 or 4 times faster! It eases in and eases out, so it never jolts. Inside it is all
## easy: long lines of beans and big rings, nothing that hurts.

## How many times faster than normal he flies in the middle of the boost.
@export_range(1.0, 6.0) var speed_multiplier: float = 3.5
## How long the whole boost is, in metres, and how tall (the height of the sky lane).
@export var length: float = 110.0
@export var height: float = 13.0
## How many metres at each end it takes to speed up and slow down. Bigger = gentler.
@export var ease_length: float = 25.0
## The whoosh when he flies in.
@export var boost_sound: AudioStream
## How many speed lines streak past inside the boost.
@export var streak_count: int = 70
## How fast the speed lines slide backwards, in metres per second.
@export var streak_speed: float = 60.0

var _streaks: Array[MeshInstance3D] = []
var _gate: Node3D
var _time: float = 0.0
var _played: bool = false


func _ready() -> void:
	_build()
	body_entered.connect(_on_enter)


func _physics_process(delta: float) -> void:
	_time += delta
	for body: Node3D in get_overlapping_bodies():
		var player := body as Player
		if player != null and player.is_flying():
			var scale_now: float = scale_at(player.global_position.x)
			player.flight.speed_scale = maxf(player.flight.speed_scale, scale_now)
	# The speed lines slide backwards, and loop round when they reach the end.
	for streak in _streaks:
		streak.position.x -= streak_speed * delta
		if streak.position.x < -length * 0.5:
			streak.position.x += length
	# The entry gate pulses so it catches the eye.
	if _gate != null:
		var pulse: float = 1.0 + 0.06 * sin(_time * 6.0)
		_gate.scale = Vector3(1.0, pulse, pulse)


## The speed multiplier at world position x: 1 outside, easing up to the full amount
## over "ease_length" metres, and back down again at the far end.
func scale_at(x: float) -> float:
	var into: float = x - (global_position.x - length * 0.5)
	var edge: float = minf(into, length - into)
	var t: float = clampf(edge / maxf(ease_length, 0.01), 0.0, 1.0)
	return 1.0 + (speed_multiplier - 1.0) * smoothstep(0.0, 1.0, t)


func _on_enter(body: Node3D) -> void:
	if body is Player and (body as Player).is_flying() and not _played:
		_played = true
		Sfx.play(self, boost_sound)


func _build() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	# A faint hot-orange haze so the tunnel can be seen from far away.
	var glow := BoxMesh.new()
	glow.size = Vector3(length, height, 0.2)
	var haze := StandardMaterial3D.new()
	haze.albedo_color = Color(1.0, 0.75, 0.2, 0.12)
	haze.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	haze.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow.material = haze
	var wall := MeshInstance3D.new()
	wall.mesh = glow
	wall.position = Vector3(0, 0, -1.8)
	add_child(wall)
	# Long bright speed lines, in front of and behind him.
	for i in streak_count:
		var line := BoxMesh.new()
		line.size = Vector3(rng.randf_range(6.0, 14.0), 0.14, 0.14)
		var white := StandardMaterial3D.new()
		white.albedo_color = Color(1.0, 0.95, 0.7, 0.75)
		white.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		white.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		line.material = white
		var streak := MeshInstance3D.new()
		streak.mesh = line
		streak.position = Vector3(rng.randf_range(-length * 0.5, length * 0.5),
			rng.randf_range(-height * 0.5, height * 0.5), rng.randf_range(-2.0, 8.0))
		add_child(streak)
		_streaks.append(streak)
	# The entry gate: glowing rings you fly through, and arrows pointing the way.
	_gate = Node3D.new()
	_gate.name = "Gate"
	_gate.position = Vector3(-length * 0.5 + 2.0, 0, 0)
	add_child(_gate)
	var colours: Array[Color] = [Color(1.0, 0.85, 0.2), Color(1.0, 0.55, 0.1), Color(1.0, 0.3, 0.1)]
	for i in 3:
		var torus := TorusMesh.new()
		torus.outer_radius = height * 0.5 + 0.8 - i * 0.2
		torus.inner_radius = torus.outer_radius - 0.7
		var hot := StandardMaterial3D.new()
		hot.albedo_color = colours[i]
		hot.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		torus.material = hot
		var ring := MeshInstance3D.new()
		ring.mesh = torus
		ring.rotation_degrees = Vector3(0, 0, 90)
		ring.position = Vector3(i * 3.0, 0, 0)
		_gate.add_child(ring)
	for i in 3:
		_add_arrow(Vector3(6.0 + i * 3.0, height * 0.5 + 2.0, 0))
		_add_arrow(Vector3(6.0 + i * 3.0, -height * 0.5 - 2.0, 0))
	# What notices him: the whole tunnel, as tall as the sky lane.
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(length, height, 4.0)
	shape.shape = box
	add_child(shape)


## A chevron arrow (like ">") made of two bars.
func _add_arrow(at: Vector3) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.9, 0.3)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for side in [1.0, -1.0]:
		var bar := BoxMesh.new()
		bar.size = Vector3(2.2, 0.5, 0.5)
		bar.material = mat
		var piece := MeshInstance3D.new()
		piece.mesh = bar
		piece.position = at + Vector3(0, side * 0.55, 0)
		piece.rotation_degrees = Vector3(0, 0, -side * 35.0)
		_gate.add_child(piece)
