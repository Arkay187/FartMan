class_name SaveData
extends Node
## Remembers progress between plays. Registered as the autoload "SaveGame".
##
## Keeps, for every stage id like "1-1": cleared or not, the best Golden Beans found
## and the best score. Also keeps "seen" flags so story scenes only show once.
## Saved in a plain text file (JSON), so it is easy to look at or delete.
##
## Other scripts get at it with SaveLookup.find(self), which copes if it is missing.

## Sent after anything changes.
signal changed

## Where the real save lives.
@export var save_path: String = "user://save.json"
## When running with no window (the automatic tests) use this file instead,
## so a test run can never touch the real save.
@export var headless_path: String = "user://save_headless.json"

## Stage id -> { "cleared": bool, "golden": int, "score": int }
var stages: Dictionary = {}
## Flag name -> true, for story scenes already shown.
var seen: Dictionary = {}
## The last map stop that was entered or cleared, so the map can put Fart Man there.
var last_stop: String = ""
## Every bean he has banked. It is kept forever and only goes down when he spends beans.
var bean_jar: int = 0
var _path_chosen: bool = false


func _ready() -> void:
	# If a test already picked a file, leave it alone.
	if not _path_chosen:
		if DisplayServer.get_name() == "headless":
			save_path = headless_path
		load_game()


## Switch to a different file and read it. Tests use this.
func use_file(path: String) -> void:
	_path_chosen = true
	save_path = path
	load_game()


func is_cleared(stage_id: String) -> bool:
	return bool(_entry(stage_id).get("cleared", false))


func best_golden(stage_id: String) -> int:
	return int(_entry(stage_id).get("golden", 0))


func best_score(stage_id: String) -> int:
	return int(_entry(stage_id).get("score", 0))


## Call when a stage is cleared. Keeps the best golden beans and best score.
func record_stage(stage_id: String, golden: int, score: int) -> void:
	if stage_id == "":
		return
	stages[stage_id] = {
		"cleared": true,
		"golden": maxi(best_golden(stage_id), golden),
		"score": maxi(best_score(stage_id), score),
	}
	last_stop = stage_id
	save_game()


## True once he has played anything, so the start menu can offer CONTINUE.
func has_progress() -> bool:
	return not stages.is_empty() or last_stop != ""


func has_seen(flag: String) -> bool:
	return seen.has(flag)


func mark_seen(flag: String) -> void:
	seen[flag] = true
	save_game()


func set_last_stop(stage_id: String) -> void:
	last_stop = stage_id
	save_game()


## Puts beans into the jar and saves. A zero or negative number does nothing,
## so nothing but spend_beans() can ever make the jar smaller.
func bank_beans(count: int) -> void:
	if count <= 0:
		return
	bean_jar += count
	save_game()


## Takes beans out of the jar for a purchase. Says no (false, nothing changes) if the jar
## has too few. This is the only way the jar ever goes down.
func spend_beans(count: int) -> bool:
	if count < 0 or count > bean_jar:
		return false
	bean_jar -= count
	save_game()
	return true


## Forget everything and save the empty state.
func reset() -> void:
	stages = {}
	seen = {}
	last_stop = ""
	bean_jar = 0
	save_game()


func save_game() -> void:
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({"stages": stages, "seen": seen, "last_stop": last_stop, "bean_jar": bean_jar}, "\t"))
	changed.emit()


## Reads the file. A missing or broken file just means a fresh start.
func load_game() -> void:
	stages = {}
	seen = {}
	last_stop = ""
	bean_jar = 0
	if not FileAccess.file_exists(save_path):
		return
	var json := JSON.new()
	# parse() just returns an error code for a broken file (parse_string logs an error).
	if json.parse(FileAccess.get_file_as_string(save_path)) == OK and json.data is Dictionary:
		var dict: Dictionary = json.data
		stages = dict.get("stages", {})
		seen = dict.get("seen", {})
		last_stop = str(dict.get("last_stop", ""))
		bean_jar = maxi(int(dict.get("bean_jar", 0)), 0)
	changed.emit()


func _entry(stage_id: String) -> Dictionary:
	var entry: Variant = stages.get(stage_id, {})
	return entry if entry is Dictionary else {}
