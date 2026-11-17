extends Node
## The very first scene. It just hands over to the start menu.

@export_file("*.tscn") var menu_scene: String = "res://scenes/start_menu.tscn"


func _ready() -> void:
	get_tree().change_scene_to_file.call_deferred(menu_scene)
