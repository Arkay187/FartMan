class_name StoryEnding
extends RefCounted
## The very end of the game: marks the last stage as cleared, then shows the ending storybook,
## which goes back to the world map when it is done.


## Saves "3-4" as cleared, then swaps the stage for the ending storybook.
## "from" is any node in the stage. The map is where the storybook goes afterwards.
static func go(from: Node, story: String = "ending", map_scene: String = "res://scenes/world_map.tscn") -> Storybook:
	var tree: SceneTree = from.get_tree()
	var stage := tree.get_first_node_in_group(&"stage") as Stage
	if stage != null:
		var save: SaveData = SaveLookup.find(from)
		if save != null:
			save.record_stage(stage.stage_id, stage.golden_found, stage.score)
	var book: Storybook = (load("res://scenes/storybook.tscn") as PackedScene).instantiate()
	book.story_name = story
	book.next_scene = map_scene
	book.music_song = "theme"
	tree.root.add_child(book)
	tree.current_scene = book
	if stage != null:
		stage.queue_free()
	return book
