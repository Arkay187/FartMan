class_name Stage
extends Node3D
## Goes on the top node of every stage. Keeps score for that stage:
## how many Golden Beans were found, and whether the Bean Can has been opened.

## Sent when a Golden Bean is found. The Golden Bean bar listens to this.
signal golden_beans_changed(found: int, total: int)
## Sent when the Bean Can is opened. Later this will go back to the world map.
signal stage_cleared

## Fart Man, so he can say something when the stage starts.
@export var player: Player
## What he says at the start. Leave empty for nothing.
@export var opening_words: String = "LET'S GET THOSE BEANS!"

var golden_found: int = 0
var golden_total: int = 0
var is_cleared: bool = false


func _ready() -> void:
	# Find every Golden Bean and Bean Can in the stage and listen to them.
	for bean: Node in get_tree().get_nodes_in_group(&"golden_beans"):
		golden_total += 1
		(bean as GoldenBean).collected.connect(_on_golden_bean_collected)
	for can: Node in get_tree().get_nodes_in_group(&"bean_cans"):
		(can as BeanCan).opened.connect(_on_bean_can_opened)
	# Tell the Golden Bean bar how many there are to find.
	golden_beans_changed.emit(golden_found, golden_total)

	if player != null:
		player.say(opening_words, 2.5)


func _on_golden_bean_collected() -> void:
	golden_found += 1
	golden_beans_changed.emit(golden_found, golden_total)


func _on_bean_can_opened() -> void:
	if is_cleared:
		return
	is_cleared = true
	stage_cleared.emit()
