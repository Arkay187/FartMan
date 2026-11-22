class_name Chatterbox
extends Area3D
## Says something when Fart Man walks (or flies) past. Used for hints and silly jokes.
## Put it where it should speak. Keep the words short and LOUD.

## What it says.
@export var words: String = "HELLO!"
## What it says when the SIMPLE controls are on. Leave empty to say `words` for both.
@export var simple_words: String = ""
## How long the bubble stays.
@export var seconds: float = 2.5
## How high above this spot the bubble floats.
@export var height: float = 2.0
## Say it only the first time, or every time he passes.
@export var only_once: bool = true
## Who the bubble points at. Leave empty to point at this spot.
@export var speaker: Node3D
## On for hint signs: the words show at the top middle of the screen instead of in a
## bubble, so they never cover the game. Off for characters talking (like the cow).
@export var show_at_top: bool = false

var _done: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	if body is Player and not (_done and only_once):
		_done = true
		var text: String = what_to_say(body as Player)
		if show_at_top:
			HintBanner.show_hint(self, text, seconds)
			return
		SpeechBubble.say(speaker if speaker != null else self, text, seconds, height)


## The words for the controls he is using: simple_words for SIMPLE (if set), otherwise words.
func what_to_say(player: Player) -> String:
	if simple_words != "" and player != null and player.is_simple():
		return simple_words
	return words
