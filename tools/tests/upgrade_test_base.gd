extends SceneTree
# Shared helpers for test_upgrades and test_upgrades_more (split so each stays under the time limit).
# Checks that every shop upgrade really changes Fart Man in a real stage (and that UPGRADES OFF
# changes nothing): belly, hearts, big hearts, sticky beans, sneakers, springy pants, super stomp,
# triple jump, fireball count / size / bounce, long chilli, spicy start, bean magnet, lucky beans,
# the secret sniffer. A throw-away save file is used, never the real one.

const SAVE_FILE: String = "user://test_upgrades_save.json"
## The test floor sits far from the real level.
const OFF: float = 3000.0
var failures: int = 0
var save: SaveData
var options: DebugOptionsData
var level: Stage
var p: Player


func _initialize() -> void:
	_run()


## Each test replaces this.
func _run() -> void:
	pass


func _wait(seconds: float) -> void:
	for i in int(seconds * 60.0):
		await physics_frame


func _check(label: String, ok: bool) -> void:
	print("%s: %s" % [label, "ok" if ok else "FAILED"])
	if not ok:
		failures += 1


func _box(center: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.position = center
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)
	level.add_child(body)


## Loads a fresh real stage with these upgrade levels, with a long flat floor (top at y = 0)
## under Fart Man, who is moved there and made safe from hurt unless "safe" is false.
func _stage(levels: Dictionary, simple: bool = true, floor_wide: bool = true, safe: bool = true) -> void:
	if level != null:
		level.queue_free()
		await physics_frame
		await physics_frame
	save.upgrades = levels.duplicate()
	options.set_simple_controls(simple)
	level = (load("res://scenes/stage_1_1.tscn") as PackedScene).instantiate() as Stage
	root.add_child(level)
	p = level.get_node("Player") as Player
	if floor_wide:
		_box(Vector3(OFF, -0.5, 0), Vector3(400, 1, 4))
	p.global_position = Vector3(OFF, 1.0, 0)
	p.velocity = Vector3.ZERO
	p.flashing_left = 100000.0 if safe else 0.0
	await _wait(0.4)


## The numbers that upgrades change, so two runs can be compared.
func _numbers() -> Dictionary:
	var burp: FireBurpPower = p.fire_burp
	var spill := p.get_node("BeanSpill") as BeanSpill
	return {
		"max_gas": p.gas_tank.max_gas, "start_gas": p.gas_tank.start_gas, "gas": p.gas_tank.gas,
		"hover_free": p.hover_helper.hover_time_free_gas,
		"max_hearts": p.hearts.max_hearts, "hearts": p.hearts.hearts, "heal": p.hearts.heal_per_pickup,
		"spill_count": spill.spill_count, "spill_life": spill.spill_lifetime,
		"move_speed": p.move_speed, "toot": p.toot_power, "trump": p.trump_power, "thunder": p.thunder_power,
		"simple_jump": p.simple_helper.simple_jump_power, "air_jumps": p.simple_helper.air_jumps,
		"air_farts": p.air_farts_free_gas,
		"max_fireballs": burp.max_fireballs, "ball_size": burp.fireball_size, "bouncy": burp.bouncy_fireballs,
		"has_burp": burp.has_power, "chilli": p.chilli.duration,
		"magnet": (p.get_node("BeanMagnet") as BeanMagnet).pull_range,
		"stomp": (p.get_node("SuperStomp") as SuperStomp).enabled,
		"sniffer": (p.get_node("SecretSniffer") as SecretSniffer).enabled,
		"extra_beans": level.extra_drop_beans, "drop_x": level.drop_chance_multiplier,
	}


## Tallest height (metres above the start) reached in 1.5 s while holding an action for "hold" s.
func _peak(action: StringName, hold: float) -> float:
	p.global_position = Vector3(OFF, 1.0, 0)
	p.velocity = Vector3.ZERO
	await _wait(0.3)
	var start_y: float = p.global_position.y
	var peak: float = 0.0
	Input.action_press(action)
	for i in 70:
		if i == int(hold * 60.0):
			Input.action_release(action)
		await physics_frame
		peak = maxf(peak, p.global_position.y - start_y)
	Input.action_release(action)
	return peak


## Peak of a SIMPLE jump followed by an air jump 0.3 s later.
func _double_peak() -> float:
	p.global_position = Vector3(OFF, 1.0, 0)
	p.velocity = Vector3.ZERO
	await _wait(0.4)
	var start_y: float = p.global_position.y
	var peak: float = 0.0
	Input.action_press(&"jump")
	for i in 75:
		if i == 30:
			Input.action_release(&"jump")
			Input.action_press(&"jump")
		if i == 36:
			Input.action_release(&"jump")
		await physics_frame
		peak = maxf(peak, p.global_position.y - start_y)
	Input.action_release(&"jump")
	return peak


func _tap(action: StringName) -> void:
	Input.action_press(action)
	await _wait(0.1)
	Input.action_release(action)
	await _wait(0.05)


## How far he runs right in one second from a standstill.
func _run_distance() -> float:
	p.global_position = Vector3(OFF - 50.0, 1.0, 0)
	p.velocity = Vector3.ZERO
	await _wait(0.3)
	var start_x: float = p.global_position.x
	Input.action_press(&"ui_right")
	await _wait(1.0)
	Input.action_release(&"ui_right")
	return p.global_position.x - start_x


func _enemy(x: float, y: float = 0.45) -> Burpling:
	var b := (load("res://scenes/burpling.tscn") as PackedScene).instantiate() as Burpling
	b.position = Vector3(x, y, 0)
	b.walk_speed = 0.0
	level.add_child(b)
	return b


func _gone(b: Variant) -> bool:
	return not is_instance_valid(b) or (b as Burpling).is_squashed


## Children of the stage made from this scene file.
func _count_scene(scene_path: String) -> int:
	var count: int = 0
	for child: Node in level.get_children():
		if child.scene_file_path == scene_path:
			count += 1
	return count


func _squares_shown(bar: SquareBar) -> int:
	var shown: int = 0
	for child: Node in bar.get_children():
		if (child as CanvasItem).visible:
			shown += 1
	return shown

## Throw-away save, gas mode, UPGRADES ON.
func _setup() -> void:
	save = root.get_node_or_null("SaveGame") as SaveData
	if save == null:
		save = SaveData.new()
		save.name = "SaveGame"
		root.add_child(save)
	save.use_file(SAVE_FILE)
	save.reset()
	await _wait(0.2)
	options = root.get_node("DebugOptions")
	options.set_gas_mode(DebugOptionsData.GasMode.NORMAL)
	options.set_upgrades_on(true)
	save.bean_jar = 321
	_check("throw-away save (%s)" % save.save_path, save.save_path == SAVE_FILE)


## Puts everything back and ends the test.
func _finish(name: String) -> void:
	if level != null:
		level.queue_free()
		await _wait(0.5)
	options.set_upgrades_on(true)
	options.set_simple_controls(true)
	save.reset()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_FILE))
	print("%s failures: %d" % [name, failures])
	quit()
