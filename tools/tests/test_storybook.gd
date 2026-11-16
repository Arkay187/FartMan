extends SceneTree
# Checks the storybook: jump turns pages, it finishes after the last page, holding jump skips.

var finished_count: int = 0


func _initialize() -> void:
	_run()


func _wait(seconds: float) -> void:
	for i in int(seconds * 60.0):
		await process_frame


func _tap() -> void:
	Input.action_press(&"ui_accept")
	await _wait(0.1)
	Input.action_release(&"ui_accept")
	await _wait(0.2)


func _make() -> Storybook:
	finished_count = 0
	var book: Storybook = load("res://scenes/storybook.tscn").instantiate()
	book.next_scene = ""  # stay put so the test can look around
	root.add_child(book)
	book.finished.connect(func() -> void: finished_count += 1)
	return book


func _run() -> void:
	var book: Storybook = _make()
	await _wait(0.5)
	print("pages: %d, on page 1: '%s'" % [book.pages.size(), book.caption.text])
	var words: Array[String] = []
	for page in book.pages:
		words.append(str(page["text"]))
	print("every page is a short capitals line: %s" % words.all(func(w: String) -> bool: return w == w.to_upper() and w.length() <= 40))

	# Wobble: the card should be moving a little.
	var angle_a: float = book.card.rotation_degrees
	await _wait(0.4)
	print("card wobbles: %s" % (not is_equal_approx(angle_a, book.card.rotation_degrees)))

	# Jump turns the page.
	await _tap()
	print("after one jump: page %d '%s' finished=%s" % [book.page_index + 1, book.caption.text, book.is_finished])
	for i in book.pages.size() - 2:
		await _tap()
	print("on the last page: page %d '%s' finished=%s" % [book.page_index + 1, book.caption.text, book.is_finished])
	await _tap()
	print("jump after the last page: finished=%s signals=%d" % [book.is_finished, finished_count])
	book.queue_free()
	await _wait(0.2)

	# Holding jump for a second skips the whole story.
	var skipper: Storybook = _make()
	await _wait(0.5)
	Input.action_press(&"ui_accept")
	await _wait(0.5)
	print("held 0.5s: page %d finished=%s" % [skipper.page_index + 1, skipper.is_finished])
	await _wait(0.8)
	Input.action_release(&"ui_accept")
	print("held 1.3s: finished=%s signals=%d" % [skipper.is_finished, finished_count])
	quit()
