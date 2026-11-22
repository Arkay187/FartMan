class_name Fireball
extends CharacterBody3D
## A rolling fireball from the Fire Burp. It falls, lands and rolls along the ground like a
## bowling ball: up and down slopes, off ledges. It squashes every Burpling it touches and keeps
## going. It pops on walls, on bosses, after a few seconds, or when it falls into a pit.
## It never touches Fart Man: it is on no collision layer and ignores him.

## Sent when it pops.
signal popped

## How fast it rolls, in metres a second. Faster than he can run (6), so it pulls ahead.
@export var roll_speed: float = 12.0
@export var gravity: float = 25.0
## Seconds before it fizzles out.
@export var lifetime: float = 3.0
## It pops if it falls this far (metres) below where it started.
@export var fall_pop_depth: float = 14.0
## Keep rolling after squashing an enemy, like a bowling ball.
@export var rolls_through_enemies: bool = true
## Ball size, used to turn its spin to match the rolling.
@export var radius: float = 0.35
## The spinning picture of the ball (a child node).
@export var ball: Node3D
## Looks for enemies and bosses it touches (a child Area3D).
@export var squash_area: Area3D

## 1 = rolls right, -1 = rolls left. Set before it is added to the level.
var direction: float = 1.0
var is_popped: bool = false
var _age: float = 0.0
var _start_y: float = 0.0


func _ready() -> void:
	add_to_group(&"fireballs")
	collision_layer = 0   # nothing bumps into it
	collision_mask = 1    # it bumps into floors and walls
	floor_snap_length = 0.4  # sticks to slopes going downhill
	floor_max_angle = deg_to_rad(50.0)
	# Never touch Fart Man.
	for hero: Node in get_tree().get_nodes_in_group(&"player"):
		add_collision_exception_with(hero)
	if squash_area != null:
		squash_area.collision_layer = 0
		squash_area.collision_mask = 1
		squash_area.monitorable = false
	_start_y = global_position.y
	velocity = Vector3(direction * roll_speed, 0.0, 0.0)


func _physics_process(delta: float) -> void:
	if is_popped:
		return
	_age += delta
	if _age >= lifetime or global_position.y < _start_y - fall_pop_depth:
		pop()
		return
	# Steady speed sideways, gravity pulls it down.
	velocity.x = direction * roll_speed
	velocity.z = 0.0
	velocity.y -= gravity * delta
	move_and_slide()
	position.z = 0.0
	# Spin like it is rolling.
	if ball != null:
		ball.rotation.z -= direction * roll_speed / radius * delta
	# Ran into a wall? Pop.
	if is_on_wall() and get_wall_normal().x * direction < -0.5:
		pop()
		return
	_hit_things()


## Squash enemies; pop on bosses.
func _hit_things() -> void:
	if squash_area == null:
		return
	for other: Area3D in squash_area.get_overlapping_areas():
		if other is SneezyWeezy or other is ColonelCork:
			pop()
			return
		var enemy := other as Burpling
		if enemy != null and not enemy.is_squashed:
			enemy.squash()
			if not rolls_through_enemies:
				pop()
				return


## Goes away in a little puff of orange smoke.
func pop() -> void:
	if is_popped:
		return
	is_popped = true
	remove_from_group(&"fireballs")
	popped.emit()
	_puff()
	queue_free()


func _puff() -> void:
	var holder: Node = get_parent()
	if holder == null or not is_inside_tree():
		return
	var paint := StandardMaterial3D.new()
	paint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	paint.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	paint.albedo_color = Color(1.0, 0.6, 0.15, 0.8)
	for i in 4:
		var puff := MeshInstance3D.new()
		var blob := SphereMesh.new()
		blob.radius = 0.18
		blob.height = 0.36
		blob.material = paint
		puff.mesh = blob
		holder.add_child(puff)
		puff.global_position = global_position
		var angle: float = i * TAU / 4.0 + 0.4
		var tween: Tween = puff.create_tween()
		tween.set_parallel(true)
		tween.tween_property(puff, "position", puff.position + Vector3(cos(angle), sin(angle), 0.0) * 0.6, 0.3)
		tween.tween_property(puff, "scale", Vector3.ONE * 0.1, 0.3)
		tween.chain().tween_callback(puff.queue_free)
