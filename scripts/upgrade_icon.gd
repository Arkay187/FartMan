class_name UpgradeIcon
extends Control
## A simple picture for each shop upgrade, drawn with code so no art files are needed.
## Set `icon_key` to one of the `icon` words in upgrade_table.gd (belly, heart, sneaker ...).
## Every picture is drawn on a 100 x 100 grid and scaled to fit the control.

## Every picture this can draw.
const KEYS: Array[String] = ["belly", "heart", "big_heart", "sticky_bean", "sneaker", "spring", "stomp", "triple",
	"fireballs", "big_fireball", "bouncy_fireball", "chilli", "hot_sauce", "magnet", "lucky", "nose"]

const OUTLINE: Color = Color(0.15, 0.08, 0.05)
const RED: Color = Color(0.9, 0.2, 0.25)
const ORANGE: Color = Color(1.0, 0.55, 0.1)
const YELLOW: Color = Color(1.0, 0.85, 0.2)
const GREEN: Color = Color(0.3, 0.75, 0.3)
const BLUE: Color = Color(0.3, 0.55, 0.95)
const STEEL: Color = Color(0.72, 0.75, 0.8)
const PINK: Color = Color(1.0, 0.75, 0.7)
const BEAN: Color = Color(0.78, 0.45, 0.25)

@export var icon_key: String = "belly":
	set(value):
		icon_key = value
		queue_redraw()

var _scale: float = 1.0
var _origin: Vector2 = Vector2.ZERO


func _init() -> void:
	custom_minimum_size = Vector2(64, 64)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	_scale = minf(size.x, size.y) / 100.0
	_origin = (size - Vector2(100, 100) * _scale) * 0.5
	match icon_key:
		"belly":
			_belly()
		"heart":
			_heart(Vector2(50, 52), 1.0, RED)
		"big_heart":
			_heart(Vector2(46, 56), 1.25, RED)
			_two_dots()
		"sticky_bean":
			_sticky_bean()
		"sneaker":
			_sneaker()
		"spring":
			_spring()
		"stomp":
			_stomp()
		"triple":
			_triple()
		"fireballs":
			_fire(Vector2(26, 62), 0.55)
			_fire(Vector2(52, 44), 0.6)
			_fire(Vector2(76, 62), 0.55)
		"big_fireball":
			_fire(Vector2(50, 56), 1.5)
		"bouncy_fireball":
			_bouncy_fireball()
		"chilli":
			_chilli()
		"hot_sauce":
			_hot_sauce()
		"magnet":
			_magnet()
		"lucky":
			_clover()
		"nose":
			_nose()
		_:
			_circle(Vector2(50, 50), 30.0, STEEL)


# ---------------------------------------------------------------- drawing helpers (100 x 100 grid)

func _p(point: Vector2) -> Vector2:
	return _origin + point * _scale


func _circle(centre: Vector2, radius: float, color: Color) -> void:
	draw_circle(_p(centre), radius * _scale, color)


# A circle with a dark outline.
func _ball(centre: Vector2, radius: float, color: Color) -> void:
	draw_circle(_p(centre), (radius + 3.0) * _scale, OUTLINE)
	draw_circle(_p(centre), radius * _scale, color)


func _poly(points: Array[Vector2], color: Color) -> void:
	var scaled := PackedVector2Array()
	for point: Vector2 in points:
		scaled.append(_p(point))
	draw_colored_polygon(scaled, color)
	scaled.append(scaled[0])
	draw_polyline(scaled, OUTLINE, 3.0 * _scale)


func _rect(x: float, y: float, w: float, h: float, color: Color) -> void:
	draw_rect(Rect2(_p(Vector2(x, y)), Vector2(w, h) * _scale), color)


func _line(a: Vector2, b: Vector2, color: Color, width: float) -> void:
	draw_line(_p(a), _p(b), color, width * _scale)


func _arc(centre: Vector2, radius: float, from: float, to: float, color: Color, width: float) -> void:
	draw_arc(_p(centre), radius * _scale, from, to, 24, color, width * _scale)


# ---------------------------------------------------------------- the pictures

func _belly() -> void:
	_ball(Vector2(46, 56), 34.0, PINK)
	_circle(Vector2(46, 62), 4.0, Color(0.85, 0.55, 0.5))
	# A few puffs of gas.
	_circle(Vector2(82, 22), 8.0, Color(0.7, 0.9, 0.5))
	_circle(Vector2(72, 12), 6.0, Color(0.7, 0.9, 0.5))
	_circle(Vector2(90, 10), 5.0, Color(0.7, 0.9, 0.5))


func _heart(centre: Vector2, grow: float, color: Color) -> void:
	var r: float = 20.0 * grow
	var lobe_y: float = centre.y - 10.0 * grow
	_ball(Vector2(centre.x - r * 0.9, lobe_y), r, color)
	_ball(Vector2(centre.x + r * 0.9, lobe_y), r, color)
	_poly([Vector2(centre.x - r * 1.85, lobe_y + 4.0 * grow), Vector2(centre.x + r * 1.85, lobe_y + 4.0 * grow),
		Vector2(centre.x, centre.y + 32.0 * grow)], color)
	_circle(Vector2(centre.x - r * 1.2, lobe_y - r * 0.3), r * 0.25, Color(1, 0.8, 0.8))


# Two gold dots beside the big heart: it heals 2.
func _two_dots() -> void:
	_ball(Vector2(88, 22), 8.0, YELLOW)
	_ball(Vector2(88, 46), 8.0, YELLOW)


func _sticky_bean() -> void:
	draw_set_transform(_p(Vector2(50, 40)), -0.5, Vector2(1.0, 0.68))
	draw_circle(Vector2.ZERO, 40.0 * _scale, OUTLINE)
	draw_circle(Vector2.ZERO, 35.0 * _scale, BEAN)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Honey drips running down.
	for drip: Vector2 in [Vector2(30, 52), Vector2(52, 60), Vector2(72, 50)]:
		_rect(drip.x - 5.0, drip.y, 10.0, 24.0, YELLOW)
		_circle(Vector2(drip.x, drip.y + 24.0), 7.0, YELLOW)


func _sneaker() -> void:
	_poly([Vector2(10, 40), Vector2(40, 36), Vector2(52, 52), Vector2(86, 58), Vector2(90, 76), Vector2(10, 76)], BLUE)
	_rect(8.0, 72.0, 84.0, 10.0, Color.WHITE)
	_line(Vector2(34, 46), Vector2(44, 56), Color.WHITE, 4.0)
	_line(Vector2(44, 44), Vector2(54, 54), Color.WHITE, 4.0)
	# Speed lines behind it.
	_line(Vector2(0, 50), Vector2(14, 50), ORANGE, 4.0)
	_line(Vector2(2, 62), Vector2(16, 62), ORANGE, 4.0)


func _spring() -> void:
	_rect(22.0, 82.0, 56.0, 8.0, STEEL)
	_rect(22.0, 28.0, 56.0, 8.0, ORANGE)
	var points: Array[Vector2] = [Vector2(30, 80), Vector2(70, 70), Vector2(30, 60), Vector2(70, 50), Vector2(30, 40), Vector2(50, 36)]
	for i in points.size() - 1:
		_line(points[i], points[i + 1], STEEL.darkened(0.2), 7.0)
	# An up arrow.
	_poly([Vector2(50, 2), Vector2(64, 20), Vector2(36, 20)], YELLOW)


func _stomp() -> void:
	_rect(6.0, 80.0, 88.0, 8.0, Color(0.5, 0.35, 0.22))
	_poly([Vector2(50, 70), Vector2(30, 38), Vector2(70, 38)], RED)
	_rect(40.0, 8.0, 20.0, 30.0, RED)
	# Shock waves along the floor.
	_arc(Vector2(50, 80), 28.0, PI, PI * 1.5, YELLOW, 5.0)
	_arc(Vector2(50, 80), 28.0, PI * 1.5, TAU, YELLOW, 5.0)
	_arc(Vector2(50, 80), 42.0, PI * 1.1, PI * 1.5, ORANGE, 4.0)
	_arc(Vector2(50, 80), 42.0, PI * 1.5, PI * 1.9, ORANGE, 4.0)


func _triple() -> void:
	for i in 3:
		var y: float = 70.0 - float(i) * 26.0
		_poly([Vector2(50, y - 22.0), Vector2(86, y + 4.0), Vector2(70, y + 8.0), Vector2(50, y - 8.0),
			Vector2(30, y + 8.0), Vector2(14, y + 4.0)], GREEN.lightened(float(i) * 0.15))


# A flame ball: a fat orange ball with a yellow middle and a tail trailing to the left.
func _fire(centre: Vector2, grow: float) -> void:
	var r: float = 22.0 * grow
	_poly([centre + Vector2(-r * 2.0, -r * 0.2), centre + Vector2(0, -r), centre + Vector2(0, r)], ORANGE)
	_ball(centre, r, ORANGE)
	_circle(centre, r * 0.55, YELLOW)


func _bouncy_fireball() -> void:
	_arc(Vector2(30, 82), 22.0, PI, TAU, Color(1, 1, 1, 0.8), 4.0)
	_arc(Vector2(74, 82), 22.0, PI, TAU, Color(1, 1, 1, 0.8), 4.0)
	_fire(Vector2(52, 34), 0.8)


func _chilli() -> void:
	_poly([Vector2(24, 24), Vector2(46, 22), Vector2(70, 42), Vector2(90, 80), Vector2(70, 74), Vector2(44, 52)], RED)
	_poly([Vector2(14, 26), Vector2(26, 14), Vector2(38, 18), Vector2(36, 32), Vector2(24, 34)], GREEN)
	_circle(Vector2(46, 34), 4.0, Color(1, 0.7, 0.7))


func _hot_sauce() -> void:
	_rect(34.0, 6.0, 32.0, 14.0, Color.WHITE)
	_rect(40.0, 20.0, 20.0, 16.0, STEEL)
	_poly([Vector2(26, 36), Vector2(74, 36), Vector2(78, 92), Vector2(22, 92)], RED)
	_rect(32.0, 54.0, 36.0, 26.0, YELLOW)
	_fire(Vector2(52, 66), 0.4)


func _magnet() -> void:
	_arc(Vector2(50, 50), 26.0, 0.0, PI, RED, 22.0)
	_rect(13.0, 18.0, 22.0, 32.0, RED)
	_rect(65.0, 18.0, 22.0, 32.0, RED)
	_rect(13.0, 8.0, 22.0, 14.0, STEEL)
	_rect(65.0, 8.0, 22.0, 14.0, STEEL)
	# Sparks.
	_line(Vector2(50, 6), Vector2(50, 22), YELLOW, 4.0)
	_line(Vector2(42, 10), Vector2(44, 20), YELLOW, 4.0)
	_line(Vector2(58, 10), Vector2(56, 20), YELLOW, 4.0)


func _clover() -> void:
	for spot: Vector2 in [Vector2(36, 36), Vector2(64, 36), Vector2(36, 64), Vector2(64, 64)]:
		_ball(spot, 17.0, GREEN)
	_line(Vector2(50, 54), Vector2(66, 96), GREEN.darkened(0.3), 6.0)
	_circle(Vector2(50, 50), 5.0, YELLOW)


func _nose() -> void:
	_ball(Vector2(50, 56), 30.0, PINK)
	_ball(Vector2(50, 30), 14.0, PINK)
	_circle(Vector2(40, 66), 6.0, Color(0.6, 0.3, 0.3))
	_circle(Vector2(60, 66), 6.0, Color(0.6, 0.3, 0.3))
	# Sniff lines.
	_line(Vector2(8, 52), Vector2(18, 56), Color.WHITE, 4.0)
	_line(Vector2(6, 66), Vector2(18, 66), Color.WHITE, 4.0)
