class_name ShipHub
extends Node3D
## The inside of the Complex2000 spaceship, seen from the side like a doll's house. Fart Man
## walks along one long floor past four rooms (Kitchen, Gym, Hot Sauce Lab, Gadget Garage).
## At each counter Grandma sells upgrades (see ShopCounter and ShopPanel). There is an airlock
## hatch at each end (left and far right): both lead back to the world map, over the stop he
## boarded from.
## The scenery is built into ship_hub.tscn by tools/builders/ship_hub.gd.

## Sent when he walks into the hatch and the map is on its way.
signal leaving

## Fart Man and the camera that follows him.
@export var player: Player
@export var camera: Camera3D
## The airlock hatch at the left end: walking into it goes back to the map.
@export var hatch: Area3D
## The second hatch at the far right end, past the Gadget Garage. It goes back to the map too.
@export var far_hatch: Area3D
## The holder of the four counters (ShopCounter nodes, left to right).
@export var counters_root: Node3D
## The shop screen (one for the whole ship) and the Bean Jar total on screen.
@export var panel: ShopPanel
@export var jar_label: BeanJarLabel
## Where the hatch leads.
@export_file("*.tscn") var map_scene: String = "res://scenes/world_map.tscn"
## The song that plays here, and how fast. A bit slower than the map makes it calm.
@export var music_song: String = "theme"
@export_range(0.25, 2.0) var music_speed: float = 0.85
## The sound of the hatch.
@export var hatch_sound: AudioStream

## True once he has walked into the hatch.
var is_leaving: bool = false


func _ready() -> void:
	hatch_sound = hatch_sound if hatch_sound != null else Sfx.named("warp_whoosh")
	if music_song != "":
		MusicPlayer.play_song(self, music_song, music_speed)
	hatch.body_entered.connect(_on_hatch_entered)
	if far_hatch != null:
		far_hatch.body_entered.connect(_on_hatch_entered)
	# He feels what he has bought aboard too (faster sneakers, springy pants...), unless UPGRADES is OFF.
	# Things bought now start working when the next stage (or the next visit) begins.
	UpgradeApplier.apply(player)
	# Every counter opens the one shop.
	for counter: ShopCounter in counters():
		if counter.panel == null:
			counter.panel = panel


## The counters, left to right (the same order as UpgradeTable.ROOMS).
func counters() -> Array[ShopCounter]:
	var list: Array[ShopCounter] = []
	for child: Node in counters_root.get_children():
		if child is ShopCounter:
			list.append(child as ShopCounter)
	list.sort_custom(func(a: ShopCounter, b: ShopCounter) -> bool: return a.position.x < b.position.x)
	return list


## The counter that sells for this room, or null.
func counter_for(room_id: String) -> ShopCounter:
	for counter: ShopCounter in counters():
		if counter.room_id == room_id:
			return counter
	return null


## Leaves through a hatch: back to the world map. The map starts over the stop he boarded from.
func leave() -> void:
	if is_leaving:
		return
	is_leaving = true
	if player != null:
		player.input_locked = true
	Sfx.play(self, hatch_sound)
	leaving.emit()
	# Deferred: we are inside a physics callback, and the hub holds physics bodies.
	get_tree().change_scene_to_file.call_deferred(map_scene)


func _on_hatch_entered(body: Node3D) -> void:
	if body is Player:
		leave()
