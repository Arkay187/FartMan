class_name SquareBar
extends HBoxContainer
## A row of coloured squares on screen. Used for hearts and Golden Beans
## until we have real pictures.

@export var square_size: float = 28.0
## Colour of a square you have.
@export var full_color: Color = Color(0.9, 0.15, 0.2)
## Colour of a square you do not have (yet).
@export var empty_color: Color = Color(0.3, 0.3, 0.3)


## Shows `total` squares, with the first `filled` of them coloured in.
func show_squares(filled: int, total: int) -> void:
	while get_child_count() < total:
		var square := ColorRect.new()
		square.custom_minimum_size = Vector2(square_size, square_size)
		add_child(square)
	for i in get_child_count():
		var square := get_child(i) as ColorRect
		square.visible = i < total
		square.color = full_color if i < filled else empty_color
