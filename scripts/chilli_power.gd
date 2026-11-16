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
## His body model, so it can glow while hot.
@export var body: MeshInstance3D
@export var hot_color: Color = Color(1.0, 0.25, 0.1)
## The flame trail behind him.
@export var trail: FlameTrail

var time_left: float = 0.0


## Chillies call this. Eating another one while hot starts the timer again.
func start() -> void:
	var was_hot: bool = is_hot()
	time_left = duration
	if was_hot:
		return
	if body != null:
		var paint := StandardMaterial3D.new()
		paint.albedo_color = hot_color
		body.material_override = paint
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
	if body != null:
		body.material_override = null
	if trail != null:
		trail.emitting = false
	ended.emit()
