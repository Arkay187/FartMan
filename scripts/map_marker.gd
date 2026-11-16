extends Node2D
## Fart Man on the world map: a little pink round blob that bobs up and down.
## The point (0, 0) is his feet.

@export var body_color: Color = Color(0.95, 0.6, 0.55)
@export var radius: float = 22.0
@export var bob_height: float = 4.0
@export var bob_speed: float = 5.0

var _time: float = 0.0


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var lift: float = absf(sin(_time * bob_speed)) * bob_height
	var middle := Vector2(0, -radius - lift)
	draw_circle(middle, radius + 2.0, Color.BLACK)
	draw_circle(middle, radius, body_color)
	# Two eyes.
	for side: float in [-1.0, 1.0]:
		draw_circle(middle + Vector2(side * 8.0, -5.0), 5.0, Color.WHITE)
		draw_circle(middle + Vector2(side * 8.0 + 1.0, -5.0), 2.5, Color.BLACK)
	# A little round belly.
	draw_circle(middle + Vector2(0, 10.0), 7.0, body_color.lightened(0.25))
