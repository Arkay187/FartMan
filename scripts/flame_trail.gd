class_name FlameTrail
extends Node3D
## Leaves a trail of glowing puffs that shrink away. Put it under Fart Man, near his bottom.
## Switch it on and off with `emitting`. Used for chilli flames and the rainbow flight trail.

## Seconds between puffs. Smaller = thicker trail.
@export var puff_every: float = 0.04
## How long each puff lasts.
@export var puff_life: float = 0.4
## How big a puff starts.
@export var puff_size: float = 0.7
@export var puff_color: Color = Color(1.0, 0.55, 0.1)
## Tick this and every puff is the next colour of the rainbow instead.
@export var rainbow: bool = false

var emitting: bool = false
var wait_left: float = 0.0
var hue: float = 0.0
var puff_mesh: SphereMesh


func _ready() -> void:
	# One shared ball shape for every puff.
	puff_mesh = SphereMesh.new()


func _physics_process(delta: float) -> void:
	if not emitting:
		return
	wait_left -= delta
	if wait_left <= 0.0:
		wait_left = puff_every
		_make_puff()


func _make_puff() -> void:
	# Unshaded paint so it glows.
	var paint := StandardMaterial3D.new()
	paint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	paint.albedo_color = puff_color
	if rainbow:
		paint.albedo_color = Color.from_hsv(hue, 0.85, 1.0)
		hue = fmod(hue + 0.06, 1.0)

	var puff := MeshInstance3D.new()
	puff.mesh = puff_mesh
	puff.material_override = paint
	# Puffs belong to the level, not to Fart Man, so they stay behind as he moves.
	get_tree().root.add_child(puff)
	var wobble := Vector3(randf_range(-0.15, 0.15), randf_range(-0.15, 0.15), 0.0)
	puff.global_position = global_position + wobble
	puff.scale = Vector3.ONE * puff_size
	var tween: Tween = puff.create_tween()
	tween.tween_property(puff, "scale", Vector3.ONE * 0.05, puff_life)
	tween.tween_callback(puff.queue_free)
