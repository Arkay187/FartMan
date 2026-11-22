extends RefCounted
## Builds the flying gadgets of Stage 2-3 (Up the Chimney) as scenes.
## Each is just an Area3D with a script: the script makes its own grey-box looks and its
## collision shape in _ready(), from the settings you can tweak in the editor.
## Colonel Cork himself is built inside his stage (see tools/kit_chimney.gd), like Sneezy Weezy.

const SfxTable = preload("res://tools/sfx_table.gd")
const GADGETS: Dictionary = {
	"spark_cable": "res://scripts/spark_cable.gd",
	"smoke_ring": "res://scripts/smoke_ring.gd",
	"roof_fan": "res://scripts/roof_fan.gd",
	"steam_cloud": "res://scripts/steam_cloud.gd",
	"chimney_stack": "res://scripts/chimney_stack.gd",
}


func build() -> void:
	for scene_name: String in GADGETS:
		var area := Area3D.new()
		area.name = scene_name.to_pascal_case()
		area.set_script(load(GADGETS[scene_name]))
		_save(area, "res://scenes/%s.tscn" % scene_name)


func _save(root: Node, path: String) -> void:
	SfxTable.apply_for_scene(root, path)  # fill in the sound slots
	var packed := PackedScene.new()
	print("pack ", path, ": ", packed.pack(root))
	print("save ", path, ": ", ResourceSaver.save(packed, path))
	root.free()
