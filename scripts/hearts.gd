class_name Hearts
extends Node
## Fart Man's hearts. Getting hurt loses one.

## Sent every time the number of hearts changes. The hearts bar listens to this.
signal hearts_changed(hearts: int, max_hearts: int)

## How many hearts he has when full.
@export var max_hearts: int = 3

var hearts: int = 0


func _ready() -> void:
	refill()


## Takes one heart away. Returns true if he still has some left.
func lose_one() -> bool:
	hearts = maxi(hearts - 1, 0)
	hearts_changed.emit(hearts, max_hearts)
	return hearts > 0


## Back to full hearts.
func refill() -> void:
	hearts = max_hearts
	hearts_changed.emit(hearts, max_hearts)
