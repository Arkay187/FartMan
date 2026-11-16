class_name Stage
extends Node3D
## Goes on the top node of every stage. Keeps score for that stage:
## the points, how many Golden Beans were found, and whether the Bean Can has been opened.

## Sent when the score goes up. The score on screen listens to this.
signal score_changed(score: int)
## Sent when a Golden Bean is found. The Golden Bean bar listens to this.
signal golden_beans_changed(found: int, total: int)
## Sent when the Bean Can is opened. A few seconds later we go back to the world map.
signal stage_cleared

## Fart Man, so he can say something when the stage starts.
@export var player: Player
## What he says at the start. Leave empty for nothing.
@export var opening_words: String = "LET'S GET THOSE BEANS!"

## Which stop on the world map this is, like "1-1". Empty = do not save anything.
@export var stage_id: String = ""
## For a flying stage: the lowest and highest height. He starts the stage already flying.
## (0, 0) = a normal running stage.
@export var start_flight: Vector2 = Vector2.ZERO
## Where to go after the stage is cleared.
@export_file("*.tscn") var map_scene: String = "res://scenes/world_map.tscn"
## How long the STAGE CLEAR banner stays before going back to the map.
@export var return_delay: float = 4.0
## Pressing this after a short moment goes back to the map straight away.
@export var skip_action: StringName = &"ui_accept"
## How long to wait before that button counts (so the jump onto the can does not skip it).
@export var skip_after: float = 0.8

var score: int = 0
var golden_found: int = 0
var golden_total: int = 0
var is_cleared: bool = false
var _clear_time: float = 0.0
var _leaving: bool = false


## Gives points to whichever stage is being played. Use it from any script:
##     Stage.award(self, 10)
static func award(from: Node, points: int) -> void:
	if points == 0 or from == null or not from.is_inside_tree():
		return
	var stage := from.get_tree().get_first_node_in_group(&"stage") as Stage
	if stage != null:
		stage.add_points(points)


func add_points(points: int) -> void:
	score += points
	score_changed.emit(score)


func _ready() -> void:
	add_to_group(&"stage")
	set_process(false)  # only needed after the stage is cleared
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
		if start_flight != Vector2.ZERO:
			# Flying stages start in the air, and every checkpoint keeps him flying.
			player.set_checkpoint(player.global_position, start_flight)
			player.start_flying.call_deferred(start_flight.x, start_flight.y)


func _on_golden_bean_collected() -> void:
	golden_found += 1
	golden_beans_changed.emit(golden_found, golden_total)


func _on_bean_can_opened() -> void:
	if is_cleared:
		return
	is_cleared = true
	# Remember the result, then count down to going back to the map.
	var save: SaveData = SaveLookup.find(self)
	if save != null:
		save.record_stage(stage_id, golden_found, score)
	set_process(true)
	stage_cleared.emit()


func _process(delta: float) -> void:
	if not is_cleared or _leaving:
		return
	_clear_time += delta
	if _clear_time >= return_delay or (_clear_time >= skip_after and Input.is_action_just_pressed(skip_action)):
		_leaving = true
		get_tree().change_scene_to_file(map_scene)
