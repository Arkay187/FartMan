class_name ChilliPower
extends Node
## The hot-farts power. Lives on Fart Man and switches on when he eats a Chilli Pepper.
## While it is on he runs and jumps much faster, glows red, leaves a flame trail,
## and squashes any enemy he touches.

## Sent when the power starts and ends. Use these later for sounds.
signal started
signal ended

## How long it lasts, in seconds.
@export var duration: float = 6.0
## How much faster he runs. 1.8 = nearly twice as fast.
@export var speed_multiplier: float = 1.8
## How much harder he jumps.
@export var jump_multiplier: float = 1.25
## His body (the Visual node). Everything in it glows red while hot.
@export var body: Node3D
@export var hot_color: Color = Color(1.0, 0.25, 0.1)
## How strong the red glow is. 0 = none, 1 = solid red (hides his face).
@export_range(0.0, 1.0) var glow_strength: float = 0.5
## The flame trail behind him.
@export var trail: FlameTrail

var time_left: float = 0.0


## Chillies call this. Eating another one while hot starts the timer again.
func start() -> void:
	var was_hot: bool = is_hot()
	time_left = duration
	if was_hot:
		return
	var glow := StandardMaterial3D.new()
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glow.albedo_color = Color(hot_color, glow_strength)
	_coat(glow)
	if trail != null:
		trail.emitting = true
	started.emit()


func is_hot() -> bool:
	return time_left > 0.0


## 1 normally, bigger while hot. Fart Man multiplies his speed and jumps by these.
func speed_boost() -> float:
	return speed_multiplier if is_hot() else 1.0


func jump_boost() -> float:
	return jump_multiplier if is_hot() else 1.0


func _physics_process(delta: float) -> void:
	if not is_hot():
		return
	time_left -= delta
	if time_left <= 0.0:
		_cool_down()


func _cool_down() -> void:
	time_left = 0.0
	_coat(null)
	if trail != null:
		trail.emitting = false
	ended.emit()


## Lays a see-through coat over every mesh in his body (null takes it off),
## so he glows but keeps his face and colours.
func _coat(glow: Material) -> void:
	if body == null:
		return
	var meshes: Array[Node] = body.find_children("*", "GeometryInstance3D", true, false)
	if body is GeometryInstance3D:
		meshes.append(body)
	for mesh: Node in meshes:
		(mesh as GeometryInstance3D).material_overlay = glow
