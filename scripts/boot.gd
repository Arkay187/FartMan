extends Node
## The very first scene. Shows the opening story the first time only,
## otherwise goes straight to the world map.

@export_file("*.tscn") var story_scene: String = "res://scenes/storybook.tscn"
@export_file("*.tscn") var map_scene: String = "res://scenes/world_map.tscn"
## The "seen it" flag saved once the story has been shown.
@export var seen_flag: String = "intro_story"


func _ready() -> void:
	get_tree().change_scene_to_file.call_deferred(choose_scene())


## Which scene comes next. Marks the story as seen so it never repeats.
func choose_scene() -> String:
	var save: SaveData = SaveLookup.find(self)
	if save != null and save.has_seen(seen_flag):
		return map_scene
	if save != null:
		save.mark_seen(seen_flag)
	return story_scene
