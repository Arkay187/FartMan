class_name LightningBolt
extends Area3D
## A lightning bolt in the Stink Storm. A thin pale flicker shows where it is about to strike
## (the WARNING), then a thick bright bolt crashes down for a moment. ZAP means a lost heart.
## Fly through while it is off. The looks are made here in code.

## Sent each time the bolt strikes.
signal struck

## How long the bolt is (metres, straight up and down).
@export var length: float = 12.0
## Seconds it is off (the last part of this is the warning flicker), and seconds the bolt lasts.
@export var off_time: float = 2.6
@export var warn_time: float = 1.0
@export var on_time: float = 0.35
## Where in the cycle it starts (0 to 1).
@export var phase: float = 0.0
## The crack of thunder.
@export var zap_sound: AudioStream

var is_on: bool = false
var is_warning: bool = false
var _age: float = 0.0
var _glow: MeshInstance3D
var _core: MeshInstance3D
var _was_on: bool = false


func _ready() -> void:
	_age = phase * (off_time + on_time)
	_build()
	_update_look()


func _physics_process(delta: float) -> void:
	_age = fmod(_age + delta, off_time + on_time)
	is_on = _age >= off_time
	is_warning = not is_on and _age >= off_time - warn_time
	if is_on and not _was_on:
		struck.emit()
		Sfx.play(self, zap_sound)
	_was_on = is_on
	_update_look()
	if not is_on:
		return
	for body: Node3D in get_overlapping_bodies():
		var player := body as Player
		if player != null:
			player.hurt(global_position.x)


func _update_look() -> void:
	if _glow == null:
		return
	_glow.visible = is_on or (is_warning and fmod(_age, 0.16) < 0.08)
	_core.visible = is_on
	_glow.scale = Vector3(1.0 if is_on else 0.25, 1.0, 1.0)


func _build() -> void:
	var halo := BoxMesh.new()
	halo.size = Vector3(1.0, length, 0.3)
	var yellow := StandardMaterial3D.new()
	yellow.albedo_color = Color(1.0, 0.95, 0.4, 0.6)
	yellow.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	yellow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	halo.material = yellow
	_glow = MeshInstance3D.new()
	_glow.mesh = halo
	add_child(_glow)
	var bolt := BoxMesh.new()
	bolt.size = Vector3(0.3, length, 0.3)
	var white := StandardMaterial3D.new()
	white.albedo_color = Color(1, 1, 1)
	white.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bolt.material = white
	_core = MeshInstance3D.new()
	_core.mesh = bolt
	add_child(_core)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.9, length, 2.0)
	shape.shape = box
	add_child(shape)
