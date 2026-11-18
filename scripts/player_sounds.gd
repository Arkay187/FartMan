class_name PlayerSounds
extends Node
## Plays Fart Man's sounds (home-made recordings in res://audio/voice). Put it inside the Player.
## It just listens to what he does: hops, farts, squeaks, flying, getting hurt.
## Swap any sound in the editor. Leave one empty and that moment stays quiet.

@export_group("Jumps")
## Picked at random for each little hop.
@export var hop_sounds: Array[AudioStream] = []
@export var trump_sound: AudioStream
@export var thunder_sound: AudioStream
## A shout on top of the Thunder fart.
@export var thunder_shout: AudioStream
## The long squeaky leak when the fart is held too long.
@export var squeak_sound: AudioStream
## Plays over and over while he is flying.
@export var flying_sound: AudioStream

@export_group("Ouch")
## Hurt by most things.
@export var hurt_sound: AudioStream
## Hurt by spikes: prickles, cacti, spiky balls.
@export var spike_sound: AudioStream
## Lost the last heart or fell off.
@export var death_sound: AudioStream
## Lost a boss fight (it starts over). Plays just after the death sound.
@export var game_over_sound: AudioStream
## How long after the death sound the "game over" comes, in seconds.
@export var game_over_delay: float = 1.4

@export_group("Hooray")
## Reached the Bean Can at the end of a stage.
@export var clear_sound: AudioStream

@export_group("Mix")
## Loudness in decibels. 0 = as recorded, -6 = about half.
@export var volume_db: float = 0.0
@export var flying_volume_db: float = -6.0
## Each sound plays a little higher or lower each time, so repeats don't get boring.
@export var pitch_wobble: float = 0.08

var _voice: AudioStreamPlayer
var _fart: AudioStreamPlayer
var _squeak: AudioStreamPlayer
var _flying: AudioStreamPlayer
var _player: Player
## File names of the sounds started so far, for the tests.
var played: Array[String] = []
## True while the flying sound should be going round and round.
var flying_on: bool = false
var _silent: bool = false


func _ready() -> void:
	_silent = DisplayServer.get_name() == "headless"
	_voice = _make_player("Voice", volume_db)
	_fart = _make_player("Fart", volume_db)
	_squeak = _make_player("Squeak", volume_db)
	_flying = _make_player("Flying", flying_volume_db)
	_flying.finished.connect(_on_flying_loop)
	_player = get_parent() as Player
	if _player == null:
		return
	_player.farted.connect(_on_farted)
	_player.squeak_started.connect(func() -> void: _play(_squeak, squeak_sound))
	_player.squeak_stopped.connect(_squeak.stop)
	_player.got_hurt.connect(_on_hurt)
	_player.died.connect(func() -> void: _play(_voice, death_sound))
	if _player.flight != null:
		_player.flight.started.connect(_on_flight_started)
		_player.flight.ended.connect(_on_flight_ended)
	# Bosses, for the "game over" when he loses to one. They may not be ready yet, so wait a frame.
	_connect_bosses.call_deferred()
	# The stage he is in, for the "hooray" at the end.
	var node: Node = get_parent()
	while node != null and not node is Stage:
		node = node.get_parent()
	if node != null:
		(node as Stage).stage_cleared.connect(func() -> void: _play(_voice, clear_sound, false))


## Leaving the level (or quitting): stop everything so no sound is left hanging.
func _exit_tree() -> void:
	for p: AudioStreamPlayer in [_voice, _fart, _squeak, _flying]:
		if p != null:
			p.stop()
			p.stream = null


func _make_player(player_name: String, db: float) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.name = player_name
	p.volume_db = db
	add_child(p)
	return p


func _play(on: AudioStreamPlayer, stream: AudioStream, wobble: bool = true) -> void:
	if stream == null:
		return
	played.append(stream.resource_path.get_file())
	# The automatic tests run with no window and no speakers: just note the sound.
	# (Really playing there leaves sounds stuck in memory when the test quits.)
	if _silent:
		return
	on.stream = stream
	on.pitch_scale = 1.0 + (randf_range(-pitch_wobble, pitch_wobble) if wobble else 0.0)
	on.play()


func _on_farted(tier_name: String) -> void:
	match tier_name:
		"Toot":
			if not hop_sounds.is_empty():
				_play(_fart, hop_sounds.pick_random())
		"Trump":
			_play(_fart, trump_sound)
		"Thunder":
			_play(_fart, thunder_sound)
			_play(_voice, thunder_shout)


func _on_hurt() -> void:
	_play(_voice, spike_sound if _player.hurt_by_spikes else hurt_sound)


func _connect_bosses() -> void:
	for boss: Node in get_tree().get_nodes_in_group(&"bosses"):
		if boss.has_signal(&"fight_lost"):
			boss.connect(&"fight_lost", _on_boss_fight_lost)


func _on_boss_fight_lost() -> void:
	await get_tree().create_timer(game_over_delay).timeout
	if is_inside_tree():
		_play(_voice, game_over_sound, false)


func _on_flight_started() -> void:
	flying_on = true
	_play(_flying, flying_sound, false)


func _on_flight_ended() -> void:
	flying_on = false
	_flying.stop()


## The flying sound ran out: start it again if he is still in the air.
func _on_flying_loop() -> void:
	if flying_on:
		_flying.play()
