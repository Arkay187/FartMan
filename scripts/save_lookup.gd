class_name SaveLookup
extends RefCounted
## Finds the SaveGame autoload. Returns null if it is not there (for example in a
## test), so callers just carry on without saving.


static func find(from: Node) -> SaveData:
	if from == null or not from.is_inside_tree():
		return null
	return from.get_node_or_null("/root/SaveGame") as SaveData
