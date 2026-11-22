class_name BeanIcon
extends Control
## A little bean picture, drawn with code, for anything on screen that shows beans.

## The colours of the bean and its shiny spot.
@export var bean_color: Color = Color(0.78, 0.45, 0.25)
@export var shine_color: Color = Color(1.0, 0.85, 0.6)
@export var outline_color: Color = Color(0.2, 0.1, 0.05)


func _init() -> void:
	custom_minimum_size = Vector2(48, 48)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var centre: Vector2 = size * 0.5
	var radius: float = minf(size.x, size.y) * 0.5
	# A tilted oval: first a dark outline, then the bean, then a shiny spot.
	draw_set_transform(centre, -0.5, Vector2(1.0, 0.68))
	draw_circle(Vector2.ZERO, radius, outline_color)
	draw_circle(Vector2.ZERO, radius * 0.82, bean_color)
	draw_circle(Vector2(-radius * 0.3, -radius * 0.25), radius * 0.22, shine_color)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
