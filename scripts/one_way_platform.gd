class_name OneWayPlatform
extends StaticBody3D
## A ledge you can jump UP through from below and then stand on.
## (Godot's one-way box only works in 2D, so we do it ourselves: while his feet are
## below the top, or he is still going up, the ledge lets him pass through.)
## Hold DOWN while standing on it to drop through.

## How high the top of the ledge is above this node's middle.
@export var top_height: float = 0.25
## How far below the top his feet can be and still stand on it (so landings feel kind).
@export var landing_slack: float = 0.12
## Hold this to drop down through the ledge.
@export var drop_action: StringName = &"ui_down"
## How long the ledge stays switched off after a drop, so he really gets through.
@export var drop_time: float = 0.35

var _players: Array[Player] = []
var _drop_left: float = 0.0
## The players currently allowed to pass through (ledge switched off for them).
var _passing: Dictionary = {}


func _ready() -> void:
	# Run before the player moves, so the ledge is ready for this very step.
	process_physics_priority = -10
	_find_players()


func _find_players() -> void:
	for node: Node in get_tree().get_nodes_in_group(&"player"):
		if node is Player and not _players.has(node):
			_players.append(node as Player)


func _physics_process(delta: float) -> void:
	_drop_left = maxf(_drop_left - delta, 0.0)
	if _players.is_empty():
		_find_players()
	for player: Player in _players:
		if not is_instance_valid(player):
			continue
		var solid: bool = _is_solid_for(player)
		if solid and player.is_on_floor() and Input.is_action_pressed(drop_action) and _standing_on_me(player):
			_drop_left = drop_time
			solid = false
		if _drop_left > 0.0 and _standing_on_me(player):
			solid = false
		# Only touch the exception list when something changes (it counts every add).
		var passing: bool = _passing.has(player)
		if solid and passing:
			player.remove_collision_exception_with(self)
			_passing.erase(player)
		elif not solid and not passing:
			player.add_collision_exception_with(self)
			_passing[player] = true


## Solid only when he is above it and not rising.
func _is_solid_for(player: Player) -> bool:
	var top: float = global_position.y + top_height
	return player.get_feet_y() >= top - landing_slack and player.velocity.y <= 0.5


func _standing_on_me(player: Player) -> bool:
	var top: float = global_position.y + top_height
	var half_width: float = _half_width()
	return absf(player.get_feet_y() - top) < 0.3 and absf(player.global_position.x - global_position.x) < half_width + 0.4


func _half_width() -> float:
	for child: Node in get_children():
		if child is CollisionShape3D and (child as CollisionShape3D).shape is BoxShape3D:
			return ((child as CollisionShape3D).shape as BoxShape3D).size.x * 0.5
	return 1.0
