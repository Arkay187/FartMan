class_name Stage
extends Node3D
## Goes on the top node of every stage. Keeps score for that stage:
## the points, how many Golden Beans were found, and whether the Bean Can has been opened.

## Sent when the score goes up. The score on screen listens to this.
signal score_changed(score: int)
## Sent when a Golden Bean is found. The Golden Bean bar listens to this.
signal golden_beans_changed(found: int, total: int)
## Sent when the beans counted for this stage change. The bean counter on screen listens to this.
signal beans_changed(beans: int)
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
## Which song plays, like "garden". Leave empty to choose by the stage number:
## 1-x garden, 2-x factory, 3-x planet_whiff, any x-4 boss fight, test levels garden.
@export var music_song: String = ""
## Flying stages play their song this much faster (1 = same speed).
@export var flight_music_speed: float = 1.15
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
## Beans grabbed since the last bank. Getting hurt spills from this pot.
var beans_pot: int = 0
## Every bean grabbed in this stage that has not been lost to a spill.
var beans_this_stage: int = 0
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


## Counts one eaten bean for the stage being played (and so for the Bean Jar). Beans call this.
static func bean_eaten(from: Node) -> void:
	var stage: Stage = Stage.find(from)
	if stage != null:
		stage.add_beans(1)


## Banks the pot of the stage being played into the jar. Toilets call this.
static func bank(from: Node) -> void:
	var stage: Stage = Stage.find(from)
	if stage != null:
		stage.bank_pot()


## The stage that "from" is in, or null.
static func find(from: Node) -> Stage:
	if from == null or not from.is_inside_tree():
		return null
	return from.get_tree().get_first_node_in_group(&"stage") as Stage


## 2345 -> "2,345" (for the bean counters on screen).
static func with_commas(number: int) -> String:
	var digits: String = str(absi(number))
	var out: String = ""
	for i in digits.length():
		if i > 0 and (digits.length() - i) % 3 == 0:
			out += ","
		out += digits[i]
	return ("-" if number < 0 else "") + out


## The song for this stage: the music_song setting, or one chosen from the stage number.
func song_name() -> String:
	return music_song if music_song != "" else Stage.song_for(stage_id)


## True for flying stages: they start in the air, or are the third stage of a world.
func is_flying_stage() -> bool:
	return start_flight != Vector2.ZERO or stage_id.ends_with("-3")


## Which song a stage id like "2-2" plays. Anything unknown (test levels) gets the garden song.
static func song_for(id: String) -> String:
	var parts: PackedStringArray = id.split("-")
	if parts.size() != 2:
		return "garden"
	if parts[1] == "4":
		return "boss"
	match parts[0]:
		"2":
			return "factory"
		"3":
			return "planet_whiff"
	return "garden"


## Beans eaten (or grabbed back after a spill) go in the pot and the stage total.
func add_beans(count: int) -> void:
	beans_pot += count
	beans_this_stage += count
	beans_changed.emit(beans_this_stage)


## Getting hurt: takes up to "count" beans out of the pot and the stage total.
## Returns how many really came out (an empty pot spills nothing).
func spill_beans(count: int) -> int:
	var taken: int = clampi(count, 0, beans_pot)
	beans_pot -= taken
	beans_this_stage -= taken
	if taken > 0:
		beans_changed.emit(beans_this_stage)
	return taken


## Puts the pot into the jar and saves, so those beans can never be lost.
func bank_pot() -> void:
	if beans_pot <= 0:
		return
	var save: SaveData = SaveLookup.find(self)
	if save != null:
		save.bank_beans(beans_pot)
	beans_pot = 0


func add_points(points: int) -> void:
	score += points
	score_changed.emit(score)


func _ready() -> void:
	add_to_group(&"stage")
	set_process(false)  # only needed after the stage is cleared
	add_child(PauseMenu.new())  # Esc / P / Start opens it
	MusicPlayer.play_song(self, song_name(), flight_music_speed if is_flying_stage() else 1.0)
	# Find every Golden Bean and Bean Can in the stage and listen to them.
	for bean: Node in get_tree().get_nodes_in_group(&"golden_beans"):
		golden_total += 1
		(bean as GoldenBean).collected.connect(_on_golden_bean_collected)
	for can: Node in get_tree().get_nodes_in_group(&"bean_cans"):
		(can as BeanCan).opened.connect(_on_bean_can_opened)
	# Tell the Golden Bean bar how many there are to find.
	golden_beans_changed.emit(golden_found, golden_total)

	if player != null:
		# Losing every heart banks the pot, so banked beans are never lost.
		player.died.connect(bank_pot)
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
	bank_pot()
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
