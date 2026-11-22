class_name SuperStomp
extends Node
## The Super Stomp upgrade. Lives on Fart Man. Every time he squashes something by landing
## on it, a shockwave ring spreads over the ground and squashes every other enemy nearby.
## Bosses are never hurt by it. Off by default.

## Switched on by the upgrade.
@export var enabled: bool = false
## How far the shockwave reaches, in metres.
@export var radius: float = 4.0
## How long the ring takes to grow and fade, in seconds.
@export var ring_time: float = 0.35
@export var ring_color: Color = Color(1.0, 0.85, 0.3, 0.8)
## The thump.
@export var stomp_sound: AudioStream

var _player: Player


func _ready() -> void:
	_player = get_parent() as Player
	if _player != null:
		_player.stomped.connect(_on_stomped)


func _on_stomped() -> void:
	if not enabled or _player == null:
		return
	# Measured from his feet, which are what land on the enemy.
	var middle: Vector3 = _player.global_position - Vector3(0.0, 1.0, 0.0)
	for node: Node in get_tree().get_nodes_in_group(&"enemies"):
		var enemy := node as Burpling  # bosses are not Burplings, so they are safe
		if enemy == null or enemy.is_squashed:
			continue
		var gap := Vector2(enemy.global_position.x - middle.x, enemy.global_position.y - middle.y)
		if gap.length() <= radius:
			enemy.squash()
	Sfx.play(_player, stomp_sound, -2.0)
	_show_ring(Vector3(middle.x, middle.y, 0.0))


## A flat ring on the ground that grows to the full radius while fading out.
func _show_ring(spot: Vector3) -> void:
	var holder: Node = _player.get_parent()
	if holder == null:
		return
	var ring := MeshInstance3D.new()
	var shape := TorusMesh.new()
	shape.inner_radius = 0.85
	shape.outer_radius = 1.0
	var paint := StandardMaterial3D.new()
	paint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	paint.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	paint.albedo_color = ring_color
	shape.material = paint
	ring.mesh = shape
	holder.add_child(ring)
	ring.global_position = spot
	ring.scale = Vector3.ONE * 0.3
	var tween: Tween = ring.create_tween()
	tween.set_parallel(true)
	tween.tween_property(ring, "scale", Vector3.ONE * radius, ring_time)
	tween.tween_property(paint, "albedo_color:a", 0.0, ring_time)
	tween.chain().tween_callback(ring.queue_free)
