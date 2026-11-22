extends Area3D
## A Heart. Touch it to get one heart back. If his hearts are already full it stays put,
## waiting for later. Enemies sometimes drop these when squashed.

## How many points it is worth.
@export var points: int = 25
## How fast it spins.
@export var spin_speed: float = 2.5
## How high it bobs up and down, in metres.
@export var bob_height: float = 0.12
## How fast it bobs.
@export var bob_speed: float = 3.0
## What Fart Man says when he grabs it. Leave empty for nothing.
@export var grab_words: String = "YUM!"
## The picture of the heart. It bobs, so the pickup itself keeps still.
@export var visual: Node3D
## The happy "ding" when he grabs it.
@export var grab_sound: AudioStream

var _time: float = 0.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_time += delta
	if visual != null:
		visual.rotate_y(spin_speed * delta)
		visual.position.y = sin(_time * bob_speed) * bob_height


func _on_body_entered(body: Node3D) -> void:
	var player := body as Player
	if player == null or player.hearts == null:
		return
	# Already full? Leave it for later.
	if not player.hearts.gain(player.hearts.heal_per_pickup):
		return
	Stage.award(self, points)
	player.say(grab_words, 1.0)
	Sfx.play(self, grab_sound)
	queue_free()
