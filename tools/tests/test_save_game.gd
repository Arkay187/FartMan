extends SceneTree
# Checks saving, reloading and resetting progress, using a test file (never the real save).

const TEST_FILE: String = "user://test_save_game.json"


func _initialize() -> void:
	_run()


func _fresh() -> SaveData:
	var save := SaveData.new()
	root.add_child(save)
	save.use_file(TEST_FILE)
	return save


func _run() -> void:
	print("autoload present in --script run: %s" % (root.get_node_or_null("SaveGame") != null))
	if FileAccess.file_exists(TEST_FILE):
		DirAccess.remove_absolute(TEST_FILE)

	var a: SaveData = _fresh()
	print("new save: cleared=%s golden=%d score=%d seen=%s" % [a.is_cleared("1-1"), a.best_golden("1-1"), a.best_score("1-1"), a.has_seen("intro_story")])
	a.record_stage("1-1", 2, 1500)
	a.mark_seen("intro_story")
	print("recorded: cleared=%s golden=%d score=%d seen=%s" % [a.is_cleared("1-1"), a.best_golden("1-1"), a.best_score("1-1"), a.has_seen("intro_story")])
	# A worse run must not lower the bests; a better one raises them.
	a.record_stage("1-1", 1, 900)
	print("worse run keeps bests: golden=%d score=%d" % [a.best_golden("1-1"), a.best_score("1-1")])
	a.record_stage("1-1", 3, 2000)
	print("better run raises bests: golden=%d score=%d" % [a.best_golden("1-1"), a.best_score("1-1")])
	a.free()

	# A second copy reading the same file sees everything.
	var b: SaveData = _fresh()
	print("reloaded: cleared=%s golden=%d score=%d seen=%s other stage cleared=%s last_stop=%s" % [
		b.is_cleared("1-1"), b.best_golden("1-1"), b.best_score("1-1"), b.has_seen("intro_story"), b.is_cleared("1-2"), b.last_stop])
	b.reset()
	print("after reset: cleared=%s seen=%s" % [b.is_cleared("1-1"), b.has_seen("intro_story")])
	b.free()
	var c: SaveData = _fresh()
	print("reset persisted: cleared=%s seen=%s" % [c.is_cleared("1-1"), c.has_seen("intro_story")])
	c.free()

	# A broken file is just a fresh start.
	var broken := FileAccess.open(TEST_FILE, FileAccess.WRITE)
	broken.store_string("this is not json {{{")
	broken.close()
	var d: SaveData = _fresh()
	print("broken file: cleared=%s" % d.is_cleared("1-1"))
	d.free()

	# The real save file is separate from the test file.
	var plain := SaveData.new()
	print("test file is not the real save: %s" % (TEST_FILE != plain.save_path))
	plain.free()
	DirAccess.remove_absolute(TEST_FILE)
	quit()
