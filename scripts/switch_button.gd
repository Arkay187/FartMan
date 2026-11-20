class_name SwitchButton
extends Area3D
## A big floor button. Land or walk on it: red and blue blocks swap places.
## The button is the colour of the blocks that will turn solid next.

## Seconds before it can be pressed again.
@export var cooldown: float = 0.8
## The round top that squashes when pressed.
@export var cap: MeshInstance3D
## What it says when pressed.
@export var words: String = "CLICK!"

var _cooldown_left: float = 0.0


func _ready() -> void:
	add_to_group(&"switch_buttons")
	body_entered.connect(_on_body_entered)
	refresh.call_deferred()


func _physics_process(delta: float) -> void:
	_cooldown_left = maxf(_cooldown_left - delta, 0.0)


func _on_body_entered(body: Node3D) -> void:
	var player := body as Player
	if player != null and not player.is_flying():
		press()


## Swaps every red and blue block.
func press() -> void:
	if _cooldown_left > 0.0:
		return
	_cooldown_left = cooldown
	get_tree().call_group(&"switch_blocks", &"toggle")
	get_tree().call_group(&"switch_buttons", &"refresh")
	SpeechBubble.say(self, words, 0.8, 1.2)
	if cap != null:
		var tween: Tween = create_tween()
		tween.tween_property(cap, "scale", Vector3(1.0, 0.3, 1.0), 0.06)
		tween.tween_property(cap, "scale", Vector3.ONE, 0.2)


## Show the colour that will turn solid next.
func refresh() -> void:
	if cap == null:
		return
	var red_is_solid: bool = true
	for block: Node in get_tree().get_nodes_in_group(&"switch_blocks"):
		var one := block as SwitchBlock
		if one != null and one.is_red:
			red_is_solid = one.is_solid
			break
	var paint := StandardMaterial3D.new()
	paint.albedo_color = Color(0.2, 0.45, 0.95) if red_is_solid else Color(0.9, 0.2, 0.2)
	cap.material_override = paint
