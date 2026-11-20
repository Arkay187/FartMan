class_name SwitchBlock
extends StaticBody3D
## A red or blue block. Red ones are solid at first, blue ones are ghosts.
## Every time the big button is pressed they swap: red turns ghost, blue turns solid.
## After he falls and comes back, they go back to how they started.

## Red block (true) or blue block (false).
@export var is_red: bool = true
## The block's shape, switched off when it is a ghost.
@export var shape: CollisionShape3D
## The picture of the block.
@export var mesh: MeshInstance3D
@export var red_color: Color = Color(0.9, 0.2, 0.2)
@export var blue_color: Color = Color(0.2, 0.45, 0.95)

var is_solid: bool = true


func _ready() -> void:
	add_to_group(&"switch_blocks")
	reset()
	var player := get_tree().get_first_node_in_group(&"player") as Player
	if player != null:
		player.respawned.connect(_on_respawned)


## The big button calls this.
func toggle() -> void:
	is_solid = not is_solid
	_apply()


## Back to how it started: red solid, blue ghost.
func reset() -> void:
	is_solid = is_red
	_apply()


func _on_respawned() -> void:
	reset()
	get_tree().call_group(&"switch_buttons", &"refresh")


func _apply() -> void:
	if shape != null:
		shape.set_deferred("disabled", not is_solid)
	if mesh != null:
		var paint := StandardMaterial3D.new()
		paint.albedo_color = red_color if is_red else blue_color
		if not is_solid:
			paint.albedo_color.a = 0.22
			paint.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mesh.material_override = paint
