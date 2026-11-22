class_name BeanMagnet
extends Node
## The Bean Magnet upgrade. Lives on Fart Man. Beans closer than pull_range fly to his middle
## and get eaten as normal. 0 = off (the normal game). Golden Beans are never pulled.

## How far away (metres) beans start flying to him. 0 = switched off.
@export var pull_range: float = 0.0
## How fast the beans fly to him, in metres a second.
@export var pull_speed: float = 14.0

var _player: Player


func _ready() -> void:
	_player = get_parent() as Player


func _physics_process(delta: float) -> void:
	if pull_range <= 0.0 or _player == null or _player.is_dying:
		return
	var middle: Vector3 = _player.global_position
	for node: Node in get_tree().get_nodes_in_group(&"beans"):
		var bean := node as Bean
		if bean == null or bean.is_queued_for_deletion():
			continue
		# Once a bean is flying to him it keeps coming, even if it started at the edge of range.
		if not bean.has_meta(&"magnet_pulled") and bean.global_position.distance_to(middle) > pull_range:
			continue
		# A bean just thrown out of him can't be eaten for a moment: leave it alone until then.
		var bounce := bean.get_node_or_null("LootBounce") as LootBounce
		if bounce != null:
			if not bean.has_meta(&"magnet_first_seen"):
				bean.set_meta(&"magnet_first_seen", Engine.get_physics_frames())
			var waited: float = (Engine.get_physics_frames() - int(bean.get_meta(&"magnet_first_seen"))) / float(Engine.physics_ticks_per_second)
			if waited < bounce.pickup_delay + 0.1:
				continue
			bounce.set_physics_process(false)  # the magnet wins over the bouncing
			bean.set_deferred("monitoring", true)
		bean.set_meta(&"magnet_pulled", true)
		bean.visible = true
		bean.global_position = bean.global_position.move_toward(middle, pull_speed * delta)
