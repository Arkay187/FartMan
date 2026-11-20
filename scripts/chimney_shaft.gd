class_name ChimneyShaft
extends Area3D
## The inside of the giant chimney. While Fart Man flies in here he does not zoom forward:
## he climbs straight up (hold jump to rise, let go to sink) and steers left and right with the
## arrow keys. Above the top of the zone, he blasts out and flies forward again.
## Put this zone over the whole shaft. The walls are solid blocks built next to it.

## Sent when he flies in, and when he bursts out (flies out of the zone).
signal entered_shaft
signal left_shaft


var player_inside: bool = false


func _ready() -> void:
	body_entered.connect(_on_enter)
	body_exited.connect(_on_exit)


func _physics_process(_delta: float) -> void:
	for body: Node3D in get_overlapping_bodies():
		var player := body as Player
		if player != null and player.is_flying():
			player.flight.shaft = true


func _on_enter(body: Node3D) -> void:
	if body is Player:
		player_inside = true
		entered_shaft.emit()


func _on_exit(body: Node3D) -> void:
	if body is Player:
		player_inside = false
		left_shaft.emit()
