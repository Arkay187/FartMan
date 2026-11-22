class_name Loot
extends RefCounted
## Throws beans and pickups out into the level. Enemies drop them when squashed, bosses shower
## them, and Fart Man spills beans when he gets hurt. Each one pops up, falls, lands on the
## ground and waits there to be picked up.
##
##     Loot.beans(self, 5)                                   # five beans that stay
##     Loot.beans(self, 6, 5.0, 8.0, 5.0)                    # six beans that vanish after 5 s
##     Loot.thing(self, "res://scenes/chilli.tscn", Vector3(2, 7, 0))

const BEAN_SCENE: String = "res://scenes/bean.tscn"


## Throws "count" beans up and out from where "from" is, spread "spread" metres per second
## sideways, "up" metres per second upwards. lifetime > 0 = they blink and vanish after that
## many seconds (for beans he spilled). Returns the beans.
static func beans(from: Node3D, count: int, spread: float = 4.0, up: float = 7.0, lifetime: float = 0.0) -> Array[Node3D]:
	var thrown: Array[Node3D] = []
	for i in count:
		# Fan them out evenly from left to right, with a little randomness.
		var side: float = 0.0 if count == 1 else lerpf(-1.0, 1.0, float(i) / float(count - 1))
		var push := Vector3(side * spread + randf_range(-0.5, 0.5), up + randf_range(-1.0, 1.0), 0.0)
		var bean: Node3D = thing(from, BEAN_SCENE, push, lifetime)
		if bean != null:
			thrown.append(bean)
	return thrown


## Throws one thing (any pickup scene) from where "from" is, with this starting push.
static func thing(from: Node3D, scene_path: String, push: Vector3, lifetime: float = 0.0) -> Node3D:
	if from == null or not from.is_inside_tree():
		return null
	var holder: Node = from.get_parent()
	if holder == null:
		return null
	var scene := load(scene_path) as PackedScene
	if scene == null:
		return null
	var item: Node3D = scene.instantiate()
	var bounce := LootBounce.new()
	bounce.name = "LootBounce"
	bounce.velocity = push
	bounce.lifetime = lifetime
	item.add_child(bounce)
	var spot: Vector3 = from.global_position + Vector3(0.0, 0.5, 0.0)
	spot.z = 0.0
	holder.add_child(item)
	item.global_position = spot
	return item
