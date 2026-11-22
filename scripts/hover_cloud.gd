class_name HoverCloud
extends Node3D
## The green fart cloud under Fart Man's feet while he hovers.
## It squashes every Burpling (enemy) that it touches. Bosses, hazards and spikes are not affected.
## Grey-box art: a few squashed green balls that wobble. Lives as a child of the Player.

## How wide the squashing area is, in metres.
@export var cloud_width: float = 2.5
## How far below his feet it reaches, in metres.
@export var cloud_depth: float = 3.0
## How deep the area is (towards the camera), so it never misses in 2.5D.
@export var cloud_thickness: float = 2.0
## How fast the puffs wobble.
@export var wobble_speed: float = 6.0
@export var cloud_color: Color = Color(0.45, 0.8, 0.2, 0.45)

var area: Area3D
var _puffs: Array[MeshInstance3D] = []
var _time: float = 0.0
var _on: bool = false


func _ready() -> void:
	# His middle is 1 m above his feet, so the feet are 1 m below the Player's origin.
	position = Vector3(0.0, -1.0, 0.0)
	area = Area3D.new()
	area.name = "SquashArea"
	area.monitorable = false  # we look for enemies; nothing needs to see us
	area.collision_layer = 0
	area.collision_mask = 1
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(cloud_width, cloud_depth, cloud_thickness)
	shape.shape = box
	shape.position = Vector3(0.0, -cloud_depth * 0.5, 0.0)
	area.add_child(shape)
	add_child(area)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = cloud_color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var spots: Array[Vector3] = [Vector3(-0.8, -0.15, 0), Vector3(0, -0.3, 0.1), Vector3(0.8, -0.15, 0), Vector3(-0.35, -0.5, -0.1), Vector3(0.4, -0.55, 0.1)]
	for spot: Vector3 in spots:
		var puff := MeshInstance3D.new()
		var ball := SphereMesh.new()
		ball.radius = 0.5
		ball.height = 1.0
		ball.material = mat
		puff.mesh = ball
		puff.position = spot
		add_child(puff)
		_puffs.append(puff)
	set_active(_on)


## Shows the cloud and makes it squash things, or hides it and makes it harmless.
func set_active(on: bool) -> void:
	_on = on
	visible = on
	if area != null:
		area.monitoring = on


func is_active() -> bool:
	return _on


func _process(delta: float) -> void:
	if not _on:
		return
	_time += delta * wobble_speed
	for i in _puffs.size():
		var wobble: float = sin(_time + i * 1.7) * 0.12
		_puffs[i].scale = Vector3(1.0 + wobble, 0.55 - wobble * 0.5, 1.0 - wobble)


func _physics_process(_delta: float) -> void:
	if not _on:
		return
	for other: Area3D in area.get_overlapping_areas():
		var enemy := other as Burpling
		if enemy != null:
			enemy.squash()
