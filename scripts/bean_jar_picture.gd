class_name BeanJarPicture
extends Control
## A simple jar drawn with code. It fills up with beans as "fill" goes from 0 to 1,
## and while beans are pouring a few of them fall in from the top.

## How full it is, 0 (empty) to 1 (full).
@export_range(0.0, 1.0) var fill: float = 0.0:
	set(value):
		fill = clampf(value, 0.0, 1.0)
		queue_redraw()
## True while beans are falling in.
@export var pouring: bool = false:
	set(value):
		pouring = value
		queue_redraw()
@export var glass_color: Color = Color(0.7, 0.9, 1.0, 0.35)
@export var rim_color: Color = Color(0.9, 0.95, 1.0)
@export var bean_color: Color = Color(0.78, 0.45, 0.25)
@export var lid_color: Color = Color(0.85, 0.25, 0.2)
## How fast the falling beans drop.
@export var fall_speed: float = 2.4

var _time: float = 0.0


func _init() -> void:
	custom_minimum_size = Vector2(220, 260)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	if pouring:
		_time += delta
		queue_redraw()


func _draw() -> void:
	var w: float = size.x
	var h: float = size.y
	var body := Rect2(w * 0.12, h * 0.22, w * 0.76, h * 0.74)
	# The beans inside, from the bottom up.
	var beans_h: float = body.size.y * fill
	draw_rect(Rect2(body.position.x, body.end.y - beans_h, body.size.x, beans_h), bean_color)
	if fill > 0.0:
		draw_rect(Rect2(body.position.x, body.end.y - beans_h, body.size.x, 6.0), bean_color.lightened(0.3))
	# The glass, and its outline.
	draw_rect(body, glass_color)
	draw_rect(body, rim_color, false, 6.0)
	# The neck and the lid.
	draw_rect(Rect2(w * 0.2, h * 0.12, w * 0.6, h * 0.1), glass_color)
	draw_rect(Rect2(w * 0.2, h * 0.12, w * 0.6, h * 0.1), rim_color, false, 5.0)
	draw_rect(Rect2(w * 0.16, h * 0.04, w * 0.68, h * 0.09), lid_color)
	# A few beans dropping in from above.
	if pouring and fill < 1.0:
		for i in 4:
			var phase: float = fposmod(_time * fall_speed + float(i) * 0.25, 1.0)
			var x: float = w * (0.4 + 0.07 * float(i))
			draw_circle(Vector2(x, lerpf(-h * 0.1, body.end.y - beans_h, phase)), 7.0, bean_color.darkened(0.1))
