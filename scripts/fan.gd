class_name Fan
extends Area3D
## A big sideways fan. While Fart Man is in the air in front of it, the wind pushes him along.
## On the ground he is not pushed. A tailwind helps you across gaps; a headwind makes you work.

## Which way it blows: 1 = right, -1 = left.
@export var direction: float = 1.0
## How hard it pushes. His own air steering is 25, so more than that wins.
@export var push_accel: float = 40.0
## The wind will not push him faster than this.
@export var max_push_speed: float = 8.0
## The spinning blades.
@export var blades: Node3D
## How fast the blades spin.
@export var spin_speed: float = 14.0
## Little wind streaks that slide along in the wind. The level kit makes them.
@export var streaks: Node3D
## How wide the wind zone is (the streaks need to know).
@export var zone_width: float = 10.0

var _travel: float = 0.0


func _process(delta: float) -> void:
	if blades != null:
		blades.rotation.x += spin_speed * delta * direction
	if streaks != null:
		_travel += 6.0 * direction * delta
		var index: int = 0
		var count: int = streaks.get_child_count()
		for streak: Node in streaks.get_children():
			var offset: float = zone_width * float(index) / float(maxi(count, 1))
			(streak as Node3D).position.x = fposmod(offset + _travel, zone_width) - zone_width * 0.5
			index += 1


func _physics_process(delta: float) -> void:
	for body: Node3D in get_overlapping_bodies():
		var player := body as Player
		if player == null or player.is_flying() or player.is_on_floor():
			continue
		if player.velocity.x * direction < max_push_speed:
			player.velocity.x += push_accel * direction * delta
