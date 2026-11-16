extends Control
## Draws the world map in flat coloured shapes: a band per world, the dotted path,
## a round spot per stop (bigger and red for bosses), flags and Golden Beans on cleared stops.

## The map that knows what is cleared. Set by the map when it starts.
var map: WorldMap

@export var map_height: float = 648.0
@export var dot_spacing: float = 22.0
@export var dot_radius: float = 5.0
@export var spot_radius: float = 26.0
@export var boss_radius: float = 40.0
@export var path_color: Color = Color(1.0, 0.95, 0.8)
@export var world_name_size: int = 28


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_delta: float) -> void:
	# Cheap, and means the flags always match the save.
	queue_redraw()


func _draw() -> void:
	_draw_bands()
	_draw_path()
	for i in MapStops.STOPS.size():
		_draw_stop(i)


func _draw_bands() -> void:
	var count: int = MapStops.WORLDS.size()
	for w in count:
		var color: Color = MapStops.WORLDS[w]["color"]
		# The first and last bands stretch past the screen edge on wide windows.
		var left: float = -2000.0 if w == 0 else w * MapStops.BAND_WIDTH
		var right: float = 3000.0 if w == count - 1 else (w + 1) * MapStops.BAND_WIDTH
		draw_rect(Rect2(left, -500.0, right - left, map_height + 1000.0), color)
		# Some flat shapes in a darker shade so each world has a look.
		var dark: Color = color.darkened(0.15)
		var x0: float = w * MapStops.BAND_WIDTH
		for k in 5:
			var cx: float = x0 + 40.0 + k * 75.0
			var cy: float = 600.0 - (k % 2) * 25.0
			match w:
				0: draw_circle(Vector2(cx, cy), 60.0, dark)  # round garden hills
				1: draw_rect(Rect2(cx - 15.0, 560.0 - (k % 3) * 40.0, 30.0, 140.0), dark)  # factory chimneys
				_: draw_circle(Vector2(cx, 590.0 - (k % 3) * 20.0), 22.0 + (k % 2) * 14.0, color.lightened(0.2))  # gas puffs
		var font: Font = ThemeDB.fallback_font
		draw_string(font, Vector2(x0, 150.0), MapStops.WORLDS[w]["name"], HORIZONTAL_ALIGNMENT_CENTER,
			MapStops.BAND_WIDTH, world_name_size, Color.WHITE.darkened(0.1))
		if w > 0:
			draw_line(Vector2(x0, 0), Vector2(x0, map_height), color.darkened(0.4), 4.0)


## Dots along a gentle curve between each pair of stops.
func _draw_path() -> void:
	for i in MapStops.STOPS.size() - 1:
		var a: Vector2 = MapStops.STOPS[i]["pos"]
		var b: Vector2 = MapStops.STOPS[i + 1]["pos"]
		var bend: Vector2 = (b - a).orthogonal().normalized() * 30.0 * (1.0 if i % 2 == 0 else -1.0)
		var mid: Vector2 = (a + b) * 0.5 + bend
		var dots: int = int(a.distance_to(b) / dot_spacing) + 1
		for d in range(1, dots):
			var t: float = float(d) / dots
			var point: Vector2 = a.lerp(mid, t).lerp(mid.lerp(b, t), t)
			draw_circle(point, dot_radius, path_color)


func _draw_stop(i: int) -> void:
	var stop: Dictionary = MapStops.STOPS[i]
	var pos: Vector2 = stop["pos"]
	var kind: String = stop["kind"]
	var cleared: bool = map != null and map.is_stop_cleared(i)
	var radius: float = boss_radius if kind == "boss" else spot_radius
	var fill: Color = Color(0.85, 0.15, 0.15) if kind == "boss" else Color(0.97, 0.97, 0.9)
	if kind == "fly":
		fill = Color(0.6, 0.85, 1.0)
	draw_circle(pos, radius + 4.0, Color.BLACK)
	draw_circle(pos, radius, fill)
	if kind == "boss":
		draw_circle(pos, radius * 0.45, Color(0.4, 0.05, 0.05))
	if cleared:
		_draw_flag(pos + Vector2(radius * 0.4, -radius))
		_draw_beans(pos + Vector2(0, radius + 16.0), map.stop_golden(i))


func _draw_flag(base: Vector2) -> void:
	draw_line(base, base + Vector2(0, -34.0), Color.BLACK, 4.0)
	draw_colored_polygon(PackedVector2Array([base + Vector2(0, -34.0), base + Vector2(26.0, -26.0), base + Vector2(0, -18.0)]),
		Color(1.0, 0.85, 0.1))


## Three little beans: gold for each found, grey for the rest.
func _draw_beans(middle: Vector2, found: int) -> void:
	for k in 3:
		var color: Color = Color(1.0, 0.8, 0.1) if k < found else Color(0.4, 0.4, 0.4)
		var at: Vector2 = middle + Vector2((k - 1) * 22.0, 0)
		draw_circle(at, 9.0, Color.BLACK)
		draw_circle(at, 7.0, color)
