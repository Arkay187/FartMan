class_name FakeWall
extends Area3D
## A wall you can walk straight through. It looks solid, but when Fart Man steps inside it
## turns see-through so he can see what is hiding in there. Walk out and it goes solid-looking again.

## How see-through it gets while he is inside (0 = invisible, 1 = solid).
@export_range(0.0, 1.0) var inside_alpha: float = 0.25
## How fast it fades, in "whole fades per second".
@export var fade_speed: float = 5.0
## True if this wall counts as a secret to find (a wall that only covers a pipe does not count).
@export var is_secret: bool = true

## How solid it looks right now (1 = solid, inside_alpha = see-through).
var current_alpha: float = 1.0
## True while Fart Man is inside it.
var player_inside: bool = false

var _paints: Array[StandardMaterial3D] = []


func _ready() -> void:
	if is_secret:
		add_to_group(&"secrets")
	for child: Node in find_children("*", "MeshInstance3D", true, false):
		var mesh: Mesh = (child as MeshInstance3D).mesh
		var paint: Variant = mesh.get("material") if mesh != null else null
		if paint is StandardMaterial3D:
			_paints.append(paint)


func _physics_process(delta: float) -> void:
	player_inside = false
	for body: Node3D in get_overlapping_bodies():
		if body is Player:
			player_inside = true
	var target: float = inside_alpha if player_inside else 1.0
	current_alpha = move_toward(current_alpha, target, fade_speed * delta)
	for paint: StandardMaterial3D in _paints:
		paint.albedo_color.a = current_alpha
