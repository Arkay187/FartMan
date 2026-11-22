extends RefCounted
## Which sound file each thing in the game uses. The scene builders look things up here and
## fill in the sound slots (the "..._sound" settings you see in the editor), so to change a
## sound for everything, change it here and rebuild. (To change one thing, just drop a new
## sound file into its slot in the editor.)
## Names without ".wav" are files in res://audio/sfx (made by tools/make_sfx.gd).
## Other settings in a row (like idle_every) are set as they are.

const SOUNDS: Dictionary = {
	# Pickups and goals
	"bean": {"pickup_sound": "bean_pickup"},
	"golden_bean": {"found_sound": "golden_bean"},
	"chilli": {"grab_sound": "chilli_sizzle"},
	"heart": {"grab_sound": "heart_pickup"},
	"bean_spill": {"spill_sound": "bean_spill"},
	"hot_sauce": {"grab_sound": "chilli_sizzle"},
	"fireball": {"pop_sound": "fireball_pop"},
	"rocket_burrito": {"grab_sound": "burrito_blast"},
	"bean_can": {"open_sound": "can_open"},
	"stage_clear_banner": {"ching_sound": "cha_ching"},
	"landing_zone": {"landing_sound": "landing_tada"},
	"toilet": {"flush_sound": "flush"},
	# Enemies (every enemy is a Burpling, so they all have squash_sound)
	"burpling": {"squash_sound": "burpling_squish"},
	"hiccup": {"squash_sound": "squash", "hop_sound": "hiccup_hop"},
	"gnome": {"squash_sound": "squash", "throw_sound": "gnome_throw", "splat_sound": "mud_splat"},
	"crow": {"squash_sound": "squash", "idle_sound": "crow_caw", "idle_every": 4.0, "idle_volume_db": -3.0},
	"cork_bot": {"squash_sound": "cork_pop", "idle_sound": "cork_roll", "idle_every": 1.8, "idle_volume_db": -9.0},
	"fizz_bat": {"squash_sound": "squash", "idle_sound": "bat_flap", "idle_every": 1.3, "idle_volume_db": -9.0},
	# Bosses
	"sneezy_weezy": {"windup_sound": "sneeze_windup", "achoo_sound": "sneeze_achoo", "hit_sound": "boss_hit", "phase_sound": "boss_phase", "defeat_sound": "boss_defeat"},
	"colonel_cork": {"snort_sound": "cork_snort", "bonk_sound": "cork_bonk", "shot_sound": "cork_shot", "hit_sound": "boss_hit", "phase_sound": "boss_phase", "defeat_sound": "cork_pop"},
	# World 3
	"whiffler": {"squash_sound": "squash", "puff_sound": "whiffler_puff"},
	"jellyfish": {"squash_sound": "squash"},
	"big_bad_burp": {"burp_sound": "big_burp", "bubble_pop_sound": "bubble_pop", "flash_sound": "ring_ding", "hit_sound": "boss_hit", "defeat_sound": "boss_defeat"},
	"burp_bubble": {"pop_sound": "bubble_pop"},
	"gas_cloud": {"boing_sound": "boing"},
	"gas_geyser": {"puff_sound": "geyser_blast"},
	"lightning_bolt": {"zap_sound": "thunder"},
	# Gadgets and hazards
	"spring": {"boing_sound": "boing", "mega_sound": "mega_boing"},
	"bounce_pad": {"boing_sound": "boing"},
	"hoop": {"ding_sound": "hoop_ding"},
	"smoke_ring": {"ding_sound": "ring_ding"},
	"roof_fan": {"switch_sound": "fan_whoosh"},
	"spark_cable": {"zap_sound": "zap"},
	"steam_cloud": {"enter_sound": "steam_hiss"},
	"steam_vent": {"puff_sound": "steam_hiss"},
	"stamp_press": {"slam_sound": "stamp_thump"},
	"crumble_platform": {"crack_sound": "crumble_crack"},
	"switch_button": {"click_sound": "switch_click"},
	"barrel_cannon": {"load_sound": "barrel_load", "fire_sound": "cannon_boom"},
	"warp_pipe": {"warp_sound": "warp_whoosh"},
	"super_boost": {"boost_sound": "super_boost"},
	# Menus
	"start_menu": {"move_sound": "menu_move", "accept_sound": "menu_accept"},
	"world_map": {"move_sound": "menu_move", "accept_sound": "menu_accept"},
	"test_levels": {"move_sound": "menu_move", "accept_sound": "menu_accept"},
	"storybook": {"page_sound": "menu_move"},
}


## Fills in the sound slots of a node that is about to be saved as the scene at "path".
static func apply_for_scene(node: Node, path: String) -> void:
	apply(node, path.get_file().get_basename())


## Fills in the sound slots of a node made in code (a kit piece or a boss), by its kind.
static func apply(node: Node, kind: String) -> void:
	var row: Dictionary = SOUNDS.get(kind, {})
	for key: String in row:
		if key.ends_with("_sound"):
			node.set(key, load("res://audio/sfx/%s.wav" % row[key]))
		else:
			node.set(key, row[key])
