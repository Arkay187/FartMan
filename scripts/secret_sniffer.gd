class_name SecretSniffer
extends Node
## The Secret Sniffer upgrade. Lives on Fart Man. Now and then it checks for an uncollected
## Golden Bean or a secret wall close by. If there is one, his nose twitches, a "sniff" plays
## and a tiny SNIFF! bubble pops up. It waits a while before sniffing again so it never nags.
## Off by default.

## Sent every time he sniffs something out.
signal sniffed

## Switched on by the upgrade.
@export var enabled: bool = false
## How close (metres) a Golden Bean or secret must be to be sniffed out.
@export var sniff_range: float = 9.0
## How often (seconds) it looks around.
@export var check_every: float = 0.5
## Seconds of quiet after a sniff, so it never nags.
@export var cooldown: float = 4.0
## How far (radians) his body wiggles, and how long the wiggle takes (seconds).
@export var wiggle_angle: float = 0.15
@export var wiggle_time: float = 0.4
## The sniff sound and how high it is pitched (1 = as made).
@export var sniff_sound: AudioStream
@export var sniff_pitch: float = 1.6

var _player: Player
var _check_left: float = 0.0
var _cooldown_left: float = 0.0


func _ready() -> void:
	_player = get_parent() as Player


func _physics_process(delta: float) -> void:
	if not enabled or _player == null:
		return
	_cooldown_left = maxf(_cooldown_left - delta, 0.0)
	_check_left -= delta
	if _check_left > 0.0 or _cooldown_left > 0.0:
		return
	_check_left = check_every
	if _something_near():
		_sniff()


## Is an uncollected Golden Bean or a secret within range?
func _something_near() -> bool:
	var middle: Vector3 = _player.global_position
	for group: StringName in [&"golden_beans", &"secrets"]:
		for node: Node in get_tree().get_nodes_in_group(group):
			var thing := node as Node3D
			if thing != null and not thing.is_queued_for_deletion() \
					and thing.global_position.distance_to(middle) <= sniff_range:
				return true
	return false


func _sniff() -> void:
	_cooldown_left = cooldown
	sniffed.emit()
	Sfx.play(_player, sniff_sound, -4.0, sniff_pitch)
	SpeechBubble.say(_player, "SNIFF!", 0.8, 2.3)
	# His nose twitches: a quick wiggle of his whole body.
	if _player.visual != null:
		var body: Node3D = _player.visual
		var tween: Tween = body.create_tween()
		tween.tween_property(body, "rotation:z", wiggle_angle, wiggle_time * 0.25)
		tween.tween_property(body, "rotation:z", -wiggle_angle, wiggle_time * 0.5)
		tween.tween_property(body, "rotation:z", 0.0, wiggle_time * 0.25)
