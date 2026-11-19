extends SceneTree
# Takes pictures of Fart Man in a stage so Claude can check his model by eye.
# Needs a real window, so run it WITHOUT --headless:
#     godot --path . --resolution 1280x720 --script res://tools/snapshot_player.gd -- <folder> [scene] [x]
# Saves right, left, front, belly, chilli and game_view pictures (.png) in that folder.
# The scene defaults to Stage 1-1, which has the real stage lighting.
# If x is given, he is moved there before game_view (for example x=9 walks into the boss room).

var _out: String = "user://snapshots"
var _scene: String = "res://scenes/stage_1_1.tscn"
var _move_to_x: float = NAN


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() > 0:
		_out = args[0]
	if args.size() > 1:
		_scene = args[1]
	if args.size() > 2:
		_move_to_x = float(args[2])
	DirAccess.make_dir_recursive_absolute(_out)
	var save: Node = root.get_node_or_null("SaveGame")
	if save != null:
		save.use_file("user://snapshot_save.json")  # never touch the real save
		save.reset()
	var level: Node = load(_scene).instantiate()
	root.add_child(level)
	_run(level)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _shot(file_name: String) -> void:
	await _frames(4)
	await RenderingServer.frame_post_draw
	var path: String = _out.path_join(file_name)
	print("saved ", path, ": ", root.get_texture().get_image().save_png(path))


func _run(level: Node) -> void:
	var player: Player = level.get_node("Player")
	var turn: ModelTurn = player.get_node("Visual/ModelTurn")
	await _frames(90)  # let him land and settle
	player.set_physics_process(false)
	var game_camera: Camera3D = root.get_camera_3d()

	# Close-up camera, side on like the game camera but nearer.
	var close := Camera3D.new()
	level.add_child(close)
	close.global_position = player.global_position + Vector3(0.0, 0.3, 3.6)
	close.look_at(player.global_position + Vector3(0.0, 0.1, 0.0), Vector3.UP)
	close.make_current()

	await _shot("right.png")
	player.visual.rotation.y = PI
	await _shot("left.png")
	player.visual.rotation.y = 0.0
	var turn_before: float = turn.turn_degrees
	turn.turn_degrees = 90.0
	await _shot("front.png")
	turn.turn_degrees = turn_before
	player.belly.visible = true
	player.belly.scale = Vector3.ONE * player.belly_full_scale
	await _shot("belly.png")
	player.belly.visible = false
	(player.get_node("ChilliPower") as ChilliPower).start()
	await _shot("chilli.png")
	(player.get_node("ChilliPower") as ChilliPower).time_left = 0.01
	await _frames(5)
	if game_camera != null:
		game_camera.make_current()
	if not is_nan(_move_to_x):
		player.set_physics_process(true)
		player.global_position = Vector3(_move_to_x, player.global_position.y + 0.5, 0.0)
		await _frames(150)  # let the camera catch up
	await _shot("game_view.png")
	quit()
