class_name LevelDots
extends Control
## A row of little dots for the shop: a filled dot is a level he owns, a hollow dot is one
## still to buy. Drawn with code.

## How many levels the upgrade has, and how many he owns.
@export var total: int = 1:
	set(value):
		total = maxi(value, 0)
		queue_redraw()
@export var filled: int = 0:
	set(value):
		filled = maxi(value, 0)
		queue_redraw()
@export var dot_radius: float = 9.0
@export var owned_color: Color = Color(1.0, 0.85, 0.1)
@export var outline_color: Color = Color(1.0, 1.0, 1.0)


func _init() -> void:
	custom_minimum_size = Vector2(120, 24)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	for i in total:
		var centre := Vector2(dot_radius + 2.0 + float(i) * (dot_radius * 2.0 + 8.0), size.y * 0.5)
		if i < filled:
			draw_circle(centre, dot_radius, owned_color)
			draw_arc(centre, dot_radius, 0.0, TAU, 20, Color(0.3, 0.2, 0.0), 2.0)
		else:
			draw_arc(centre, dot_radius - 1.0, 0.0, TAU, 20, outline_color, 3.0)
