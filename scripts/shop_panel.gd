class_name ShopPanel
extends CanvasLayer
## Grandma's shop, one room at a time. Big and simple so a 6 year old can use it:
## a row for every upgrade (picture, name, dots for the levels, price in beans), Grandma's
## words at the top, and a jar at the bottom showing how many beans he has.
##   up / down  picks an upgrade (wraps round)
##   jump       buys the picked one
##   back (pause / Esc) leaves
## All buying goes through SaveData.buy_upgrade(), so the jar can only ever go down by a purchase.
## Built entirely in code. A shop counter opens it with open_room().

## Sent when the shop opens, when it closes, and after a purchase.
signal opened(room_id: String)
signal closed
signal bought(upgrade_id: String)

## Ignore buttons for this long after opening (so the jump that opened the shop cannot buy).
@export var input_delay: float = 0.25
## When the shop opens the camera slides this far (metres) so Fart Man and Grandma stay in
## view on the left while the shop fills the right.
@export var camera_shift: float = 4.5
## How long Grandma's "YUM!" stays after a purchase, and her words when he cannot pay.
@export var yum_seconds: float = 1.3
@export var yum_words: String = "YUM!"
@export var broke_words: String = "NOT ENOUGH!"
@export var owned_words: String = "OWNED!"
@export var selected_color: Color = Color(1.0, 0.85, 0.1)
@export var card_color: Color = Color(0.1, 0.12, 0.25, 0.95)
## The sounds. Empty ones are filled in from res://audio.
@export var buy_sound: AudioStream
@export var toot_sound: AudioStream
@export var nope_sound: AudioStream
@export var move_sound: AudioStream
@export var open_sound: AudioStream
@export var close_sound: AudioStream

## True while the shop is on screen.
var is_open: bool = false
var room_id: String = ""
## Which row is picked.
var selected: int = 0
## One entry per upgrade on screen: id, panel, icon, name_label, dots, price_label, bean_icon.
var rows: Array[Dictionary] = []
## What the tests read: Grandma's words, the jar, and "NEED 120 MORE".
var grandma_label: Label
var jar_picture: BeanJarPicture
var jar_label: BeanJarLabel
var need_box: HBoxContainer
var need_label: Label

var _root: Control
var _card: PanelContainer
var _rows_box: VBoxContainer
var _header_box: Panel
var _save: SaveData
var _since_open: float = 0.0
var _say_text: String = ""
var _say_left: float = 0.0
var _camera: Camera3D
var _camera_offset: Vector3
var _wiggle_tween: Tween


func _ready() -> void:
	layer = 20
	DebugOptionsData.ensure_input_actions()
	buy_sound = buy_sound if buy_sound != null else Sfx.named("cha_ching")
	toot_sound = toot_sound if toot_sound != null else load("res://audio/voice/fart_1.wav") as AudioStream
	nope_sound = nope_sound if nope_sound != null else Sfx.named("switch_click")
	move_sound = move_sound if move_sound != null else Sfx.named("menu_move")
	open_sound = open_sound if open_sound != null else Sfx.named("pause_open")
	close_sound = close_sound if close_sound != null else Sfx.named("pause_close")
	_save = SaveLookup.find(self)
	if _save != null:
		_save.changed.connect(_refresh)
	_build()
	_root.visible = false


func _process(delta: float) -> void:
	if not is_open:
		return
	_since_open += delta
	if _say_left > 0.0:
		_say_left -= delta
		if _say_left <= 0.0:
			_refresh()
	if Input.is_action_just_pressed(&"pause") or Input.is_action_just_pressed(&"ui_cancel"):
		close()
		return
	if _since_open < input_delay:
		return
	if Input.is_action_just_pressed(&"ui_down"):
		select(selected + 1)
	elif Input.is_action_just_pressed(&"ui_up"):
		select(selected - 1)
	elif Input.is_action_just_pressed(&"jump") or Input.is_action_just_pressed(&"ui_accept"):
		buy_selected()


## Opens the shop for one room (kitchen, gym, lab or garage).
func open_room(new_room_id: String) -> void:
	if is_open:
		return
	room_id = new_room_id
	var room: Dictionary = UpgradeTable.room(room_id)
	var list: Array[Dictionary] = UpgradeTable.in_room(room_id)
	_build_rows(list)
	_style_card(room.get("color", selected_color))
	selected = 0
	is_open = true
	_since_open = 0.0
	_say_left = 0.0
	_root.visible = true
	_shift_camera(true)
	_refresh()
	Sfx.play(self, open_sound)
	opened.emit(room_id)


## Closes the shop.
func close() -> void:
	if not is_open:
		return
	is_open = false
	_root.visible = false
	_shift_camera(false)
	Sfx.play(self, close_sound)
	closed.emit()


## Moves the pick up or down one row, wrapping round.
func select(index: int) -> void:
	if rows.is_empty():
		return
	selected = (index + rows.size()) % rows.size()
	_say_left = 0.0
	_refresh()
	Sfx.play(self, move_sound)


## Buys the next level of the picked upgrade, if he can pay. Returns true if he bought it.
func buy_selected() -> bool:
	if not is_open or rows.is_empty() or _save == null:
		return false
	var id: String = rows[selected]["id"]
	var price: int = UpgradeTable.next_price(id, _save.upgrade_level(id))
	if price < 0:
		_say(owned_words)
		Sfx.play(self, nope_sound, -3.0, 0.5)
		return false
	if not _save.buy_upgrade(id):
		_say(broke_words)
		Sfx.play(self, nope_sound, -3.0, 0.5)
		_wiggle_jar()
		return false
	Sfx.play(self, buy_sound)
	Sfx.play(self, toot_sound, -4.0)
	_say(yum_words)
	_pop_icon(selected)
	bought.emit(id)
	return true


## How many dots of row i are filled (levels owned), for the tests.
func filled_dots(index: int) -> int:
	return (rows[index]["dots"] as LevelDots).filled


## The ids of the upgrades on screen, top to bottom.
func ids() -> Array[String]:
	var list: Array[String] = []
	for row: Dictionary in rows:
		list.append(row["id"])
	return list


# ---------------------------------------------------------------- what is shown

func _jar() -> int:
	return 0 if _save == null else _save.bean_jar


func _owned(id: String) -> int:
	return 0 if _save == null else _save.upgrade_level(id)


# The price of the picked upgrade, or -1 when all of it is bought.
func _picked_price() -> int:
	if rows.is_empty():
		return -1
	var id: String = rows[selected]["id"]
	return UpgradeTable.next_price(id, _owned(id))


func _say(words: String) -> void:
	_say_text = words
	_say_left = yum_seconds
	_refresh()


# Redraw everything from the save.
func _refresh() -> void:
	if not is_open:
		return
	for i in rows.size():
		var row: Dictionary = rows[i]
		var id: String = row["id"]
		var owned: int = _owned(id)
		(row["dots"] as LevelDots).filled = owned
		var price: int = UpgradeTable.next_price(id, owned)
		var price_label: Label = row["price_label"]
		var bean: Control = row["bean_icon"]
		if price < 0:
			price_label.text = "OWNED"
			price_label.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))
			bean.visible = false
		else:
			price_label.text = Stage.with_commas(price)
			price_label.add_theme_color_override("font_color", Color.WHITE if price <= _jar() else Color(1.0, 0.6, 0.55))
			bean.visible = true
		_style_row(i)
	var picked: int = _picked_price()
	if _say_left > 0.0:
		grandma_label.text = _say_text
	elif picked < 0:
		grandma_label.text = owned_words
	else:
		grandma_label.text = "OOOH! %s BEANS?" % Stage.with_commas(picked)
	# The jar fills towards the price. "NEED 120 MORE" shows while he is short.
	if picked < 0:
		jar_picture.fill = 1.0
	else:
		jar_picture.fill = clampf(float(_jar()) / float(maxi(picked, 1)), 0.0, 1.0)
	need_box.visible = picked > _jar()
	if picked > _jar():
		need_label.text = "NEED %s MORE" % Stage.with_commas(picked - _jar())


func _style_row(index: int) -> void:
	var box := StyleBoxFlat.new()
	box.set_corner_radius_all(14)
	box.content_margin_left = 10.0
	box.content_margin_right = 14.0
	box.content_margin_top = 4.0
	box.content_margin_bottom = 4.0
	if index == selected:
		box.bg_color = Color(1.0, 0.85, 0.1, 0.28)
		box.border_color = selected_color
		box.set_border_width_all(5)
	else:
		box.bg_color = Color(1.0, 1.0, 1.0, 0.07)
	(rows[index]["panel"] as PanelContainer).add_theme_stylebox_override("panel", box)


func _style_card(room_color: Color) -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = card_color
	box.border_color = room_color
	box.set_border_width_all(8)
	box.set_corner_radius_all(24)
	box.set_content_margin_all(14.0)
	_card.add_theme_stylebox_override("panel", box)


func _wiggle_jar() -> void:
	if _wiggle_tween != null:
		_wiggle_tween.kill()
	jar_picture.pivot_offset = jar_picture.size * 0.5
	_wiggle_tween = create_tween()
	for angle: float in [0.18, -0.18, 0.12, -0.08, 0.0]:
		_wiggle_tween.tween_property(jar_picture, "rotation", angle, 0.06)


# The bought picture jumps up a little.
func _pop_icon(index: int) -> void:
	var icon: Control = rows[index]["icon"]
	icon.pivot_offset = icon.size * 0.5
	icon.scale = Vector2(1.5, 1.5)
	create_tween().tween_property(icon, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)


# Slides the camera sideways while the shop is open (see camera_shift).
func _shift_camera(opening: bool) -> void:
	if opening:
		_camera = get_viewport().get_camera_3d()
		if _camera == null or not (_camera.get("offset") is Vector3):
			_camera = null
			return
		_camera_offset = _camera.get("offset")
		_camera.set("offset", _camera_offset + Vector3(camera_shift, 0.0, 0.0))
	elif is_instance_valid(_camera):
		_camera.set("offset", _camera_offset)
		_camera = null


# ---------------------------------------------------------------- building the screen

func _build() -> void:
	_root = Control.new()
	_root.name = "Root"
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	# The card sits on the right, grows down to fit its rows.
	_card = PanelContainer.new()
	_card.name = "Card"
	_card.anchor_left = 1.0
	_card.anchor_right = 1.0
	_card.offset_left = -600.0
	_card.offset_right = -16.0
	_card.offset_top = 14.0
	_card.offset_bottom = 14.0
	_card.grow_vertical = Control.GROW_DIRECTION_END
	_style_card(selected_color)
	_root.add_child(_card)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	_card.add_child(column)

	# Grandma's words in a speech bubble.
	_header_box = Panel.new()
	_header_box.custom_minimum_size = Vector2(0, 62)
	var bubble := StyleBoxFlat.new()
	bubble.bg_color = Color.WHITE
	bubble.border_color = Color.BLACK
	bubble.set_border_width_all(3)
	bubble.set_corner_radius_all(18)
	_header_box.add_theme_stylebox_override("panel", bubble)
	column.add_child(_header_box)
	grandma_label = Label.new()
	grandma_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	grandma_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	grandma_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	grandma_label.add_theme_font_size_override("font_size", 38)
	grandma_label.add_theme_color_override("font_color", Color.BLACK)
	_header_box.add_child(grandma_label)

	_rows_box = VBoxContainer.new()
	_rows_box.add_theme_constant_override("separation", 6)
	column.add_child(_rows_box)

	# The jar and what it needs.
	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 16)
	column.add_child(bottom)
	jar_picture = BeanJarPicture.new()
	jar_picture.custom_minimum_size = Vector2(84, 104)
	bottom.add_child(jar_picture)
	var words := VBoxContainer.new()
	words.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom.add_child(words)
	jar_label = BeanJarLabel.new()
	jar_label.font_size = 34
	words.add_child(jar_label)
	need_box = HBoxContainer.new()
	need_box.add_theme_constant_override("separation", 10)
	words.add_child(need_box)
	var need_bean := BeanIcon.new()
	need_bean.custom_minimum_size = Vector2(36, 36)
	need_box.add_child(need_bean)
	need_label = _label(30, Color(1.0, 0.6, 0.55))
	need_box.add_child(need_label)


func _build_rows(list: Array[Dictionary]) -> void:
	for old: Node in _rows_box.get_children():
		_rows_box.remove_child(old)
		old.queue_free()
	rows.clear()
	for upgrade: Dictionary in list:
		var panel := PanelContainer.new()
		_rows_box.add_child(panel)
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 14)
		panel.add_child(line)
		var icon := UpgradeIcon.new()
		icon.icon_key = upgrade["icon"]
		icon.custom_minimum_size = Vector2(66, 66)
		line.add_child(icon)
		var middle := VBoxContainer.new()
		middle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		middle.alignment = BoxContainer.ALIGNMENT_CENTER
		line.add_child(middle)
		var name_label: Label = _label(28, Color.WHITE)
		name_label.text = upgrade["name"]
		middle.add_child(name_label)
		var dots := LevelDots.new()
		dots.total = (upgrade["prices"] as Array).size()
		middle.add_child(dots)
		var price_box := HBoxContainer.new()
		price_box.add_theme_constant_override("separation", 8)
		price_box.alignment = BoxContainer.ALIGNMENT_END
		price_box.custom_minimum_size = Vector2(150, 0)
		line.add_child(price_box)
		var bean := BeanIcon.new()
		bean.custom_minimum_size = Vector2(34, 34)
		price_box.add_child(bean)
		var price_label: Label = _label(30, Color.WHITE)
		price_box.add_child(price_label)
		rows.append({"id": upgrade["id"], "panel": panel, "icon": icon, "name_label": name_label, "dots": dots,
			"price_label": price_label, "bean_icon": bean})


func _label(font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 6)
	return label
