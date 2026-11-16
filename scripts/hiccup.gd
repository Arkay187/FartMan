class_name Hiccup
extends Burpling
## A Hiccup: a blob that hops on the spot, every couple of seconds, saying "HIC!".
## Wait for it to land, then stomp it (or run under its next hop).

## Seconds between hops.
@export var hop_every: float = 2.0
## How fast it launches upwards. 9 = about 1.6 metres high.
@export var hop_speed: float = 9.0
@export var hop_gravity: float = 25.0
## Where in the hop cycle it starts (0 to 1), so a row of Hiccups can hop out of step.
@export var phase: float = 0.0

var _vy: float = 0.0
var _base_y: float = 0.0
var _timer: float = 0.0


func _ready() -> void:
	super._ready()
	_base_y = position.y
	_timer = hop_every * (1.0 - phase)


func _move(delta: float) -> void:
	if position.y <= _base_y and _vy <= 0.0:
		position.y = _base_y
		_timer -= delta
		if _timer <= 0.0:
			_timer = hop_every
			_vy = hop_speed
			SpeechBubble.say(self, "HIC!", 0.5, 1.0)
		return
	_vy -= hop_gravity * delta
	position.y = maxf(position.y + _vy * delta, _base_y)
