class_name BeanSpill
extends Node
## Fart Man spills beans when he gets hurt (like Sonic's rings). Add this node under the player.
## The beans pop out of the pot of beans he has grabbed but not banked yet, and he has to
## grab them back before they blink and vanish. Grabbing one puts it back in the pot.
## Beans already in the Bean Jar are safe. An empty pot spills nothing.

## The most beans that pop out each time he is hurt.
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


## Throws up to spill_count beans, taken out of the pot.
func _spill() -> void:
	var stage := Stage.find(_player)
	# No floor to land on while flying.
	if stage == null or stage.is_flying_stage():
		return
	var count: int = stage.spill_beans(spill_count)
	if count <= 0:
		return
	Loot.beans(_player, count, spill_spread, spill_up, spill_lifetime)
	Sfx.play(_player, spill_sound)
