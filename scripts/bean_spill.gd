class_name BeanSpill
extends Node
## Fart Man spills beans when he gets hurt (like Sonic's rings). Add this node under the player.
## The beans pop out, and he has to grab them back before they blink and vanish.
## The gas those beans are worth is taken out of his tank, so grabbing them gives it back.

## How many beans pop out each time he is hurt.
@export var spill_count: int = 6
## How many seconds the beans stay before they blink and vanish.
@export var spill_lifetime: float = 5.0
## How far sideways the beans fly, and how high they pop up (metres per second).
@export var spill_spread: float = 5.0
@export var spill_up: float = 8.0
## The "scatter" sound.
@export var spill_sound: AudioStream

var _player: Player


func _ready() -> void:
	_player = get_parent() as Player
	if _player != null:
		_player.got_hurt.connect(_spill)


## Throws the beans and takes away the gas they are worth.
func _spill() -> void:
	# No floor to land on while flying.
	var stage := get_tree().get_first_node_in_group(&"stage") as Stage
	if stage != null and stage.is_flying_stage():
		return
	var beans: Array[Node3D] = Loot.beans(_player, spill_count, spill_spread, spill_up, spill_lifetime)
	Sfx.play(_player, spill_sound)
	if _player.gas_tank == null:
		return
	var worth: float = 0.0
	for bean: Node3D in beans:
		worth += float(bean.get("gas_amount"))
	# drain() never takes him below empty.
	_player.gas_tank.drain(worth)
