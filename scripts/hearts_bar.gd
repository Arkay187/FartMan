extends HBoxContainer
## The hearts on screen: one red square per heart, grey when it is lost.

## Whose hearts to show.
@export var player: Player
@export var heart_size: float = 28.0
@export var full_color: Color = Color(0.9, 0.15, 0.2)
@export var empty_color: Color = Color(0.3, 0.3, 0.3)


func _ready() -> void:
	if player == null or player.hearts == null:
		return
	player.hearts.hearts_changed.connect(_on_hearts_changed)
	_on_hearts_changed(player.hearts.hearts, player.hearts.max_hearts)


func _on_hearts_changed(hearts: int, max_hearts: int) -> void:
	# Make sure there is one square per heart.
	while get_child_count() < max_hearts:
		var square := ColorRect.new()
		square.custom_minimum_size = Vector2(heart_size, heart_size)
		add_child(square)
	# Colour them in.
	for i in get_child_count():
		var square := get_child(i) as ColorRect
		square.visible = i < max_hearts
		square.color = full_color if i < hearts else empty_color
