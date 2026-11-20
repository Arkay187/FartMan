class_name ChimneyLane
extends Area3D
## Changes how high and low he can fly. Fly through it and the "sky" becomes the new lane.
## Used just outside the chimney: the tall shaft turns into the lane over the factory roofs.

## The new lowest and highest height of the sky.
@export var lane_low: float = 73.0
@export var lane_high: float = 92.0


func _ready() -> void:
	body_entered.connect(_on_enter)


func _on_enter(body: Node3D) -> void:
	var player := body as Player
	if player != null and player.is_flying():
		player.flight.lowest_y = lane_low
		player.flight.highest_y = lane_high
