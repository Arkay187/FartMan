class_name Gnome
extends Burpling
## A Grumpy Gnome: stands still and throws mud pies at Fart Man when he is close.
## It grumbles a moment before each throw, so you can get ready. Stomp it.

## Seconds between throws.
@export var throw_every: float = 2.6
## It only throws when he is this close, in metres.
@export var throw_range: float = 14.0
## How long the pie takes to fly. Longer = easier to dodge.
@export var flight_time: float = 1.1
## It grumbles this long before throwing.
@export var warn_time: float = 0.6
@export var grumble_words: String = "HMPH!"
## Where the throw starts, compared to the middle of the gnome.
@export var hand_offset: Vector3 = Vector3(0, 0.6, 0)

var _timer: float = 0.0
var _warned: bool = false


func _ready() -> void:
	super._ready()
	_timer = throw_every


func _move(delta: float) -> void:
	var player: Node3D = get_tree().get_first_node_in_group(&"player") as Node3D
	if player == null or absf(player.global_position.x - global_position.x) > throw_range:
		_timer = throw_every
		_warned = false
		return
	_timer -= delta
	if not _warned and _timer <= warn_time:
		_warned = true
		SpeechBubble.say(self, grumble_words, warn_time, 1.2)
	if _timer <= 0.0:
		_timer = throw_every
		_warned = false
		# Throw at where he is standing now: keep moving and it misses.
		MudPie.throw(get_parent(), global_position + hand_offset, player.global_position, flight_time)
