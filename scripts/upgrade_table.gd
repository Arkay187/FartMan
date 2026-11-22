class_name UpgradeTable
extends RefCounted
## Every upgrade Grandma sells aboard the Complex2000, all in one list so prices are easy to change.
## (BEAN_SHIP_PLAN.md has the same list in words.)
##
## Each upgrade has one or more levels:
##   "prices" - what each level costs in beans, level 1 first.
##   "values" - what each level sets. The helper in upgrade_applier.gd turns these into
##              Fart Man's numbers at the start of every stage. The comment says what they mean.
##   "icon"   - which little picture the shop draws (see upgrade_icon.gd).
##   "words"  - two or three words under the name, for Dad. The pictures do the talking.
## The save file remembers how many levels he has bought of each one (SaveData.upgrades).

## The four shop rooms aboard, left to right.
const ROOMS: Array[Dictionary] = [
	{"id": "kitchen", "name": "KITCHEN", "color": Color(1.0, 0.72, 0.35)},
	{"id": "gym", "name": "GYM", "color": Color(0.45, 0.75, 1.0)},
	{"id": "lab", "name": "HOT SAUCE LAB", "color": Color(1.0, 0.42, 0.32)},
	{"id": "garage", "name": "GADGET GARAGE", "color": Color(0.6, 0.85, 0.45)},
]

const UPGRADES: Array[Dictionary] = [
	# ---------------------------------------------------------------- the Kitchen: belly and hearts
	# values: how much gas a full tank holds (normal is 100). A bigger tank hovers longer.
	{"id": "bigger_belly", "room": "kitchen", "name": "BIGGER BELLY", "words": "MORE GAS", "icon": "belly",
		"prices": [150, 400, 800], "values": [125.0, 150.0, 200.0]},
	# values: how many hearts he has (normal is 3).
	{"id": "extra_heart", "room": "kitchen", "name": "EXTRA HEART", "words": "ONE MORE HEART", "icon": "heart",
		"prices": [250, 700], "values": [4, 5]},
	# values: how many hearts one Heart pickup gives back (normal is 1).
	{"id": "big_hearts", "room": "kitchen", "name": "BIG HEARTS", "words": "HEARTS HEAL 2", "icon": "big_heart",
		"prices": [300], "values": [2]},
	# values: [seconds spilled beans stay (normal 5), most beans that spill (normal 6)].
	{"id": "sticky_beans", "room": "kitchen", "name": "STICKY BEANS", "words": "FEWER SPILLS", "icon": "sticky_bean",
		"prices": [250], "values": [[10.0, 3]]},

	# ---------------------------------------------------------------- the Gym: moves
	# values: how much faster he runs (1.15 = 15% faster).
	{"id": "speedy_sneakers", "room": "gym", "name": "SPEEDY SNEAKERS", "words": "RUN FASTER", "icon": "sneaker",
		"prices": [200, 500], "values": [1.15, 1.30]},
	# values: how much higher he jumps (1.1 = 10% higher), double jump too.
	{"id": "springy_pants", "room": "gym", "name": "SPRINGY PANTS", "words": "JUMP HIGHER", "icon": "spring",
		"prices": [250, 600], "values": [1.10, 1.20]},
	# values: 1 = a stomp sends out a shockwave that squashes nearby enemies.
	{"id": "super_stomp", "room": "gym", "name": "SUPER STOMP", "words": "STOMP WAVE", "icon": "stomp",
		"prices": [700], "values": [1]},
	# values: extra jumps in the air (an extra air fart in CLASSIC).
	{"id": "triple_jump", "room": "gym", "name": "TRIPLE JUMP", "words": "ONE MORE JUMP", "icon": "triple",
		"prices": [1200], "values": [1]},

	# ---------------------------------------------------------------- the Hot Sauce Lab: fire burp and chilli
	# values: most fireballs at once (normal is 3).
	{"id": "more_fireballs", "room": "lab", "name": "MORE FIREBALLS", "words": "MORE AT ONCE", "icon": "fireballs",
		"prices": [250, 550], "values": [4, 5]},
	# values: how much bigger the balls are (1.6 = 60% bigger), so they squash a wider row.
	{"id": "big_fireballs", "room": "lab", "name": "BIG FIREBALLS", "words": "BIGGER BALLS", "icon": "big_fireball",
		"prices": [350], "values": [1.6]},
	# values: 1 = fireballs hop over small gaps and roll longer.
	{"id": "bouncy_fireballs", "room": "lab", "name": "BOUNCY FIREBALLS", "words": "HOP OVER GAPS", "icon": "bouncy_fireball",
		"prices": [500], "values": [1]},
	# values: seconds the Chilli Pepper lasts (normal is 6).
	{"id": "long_chilli", "room": "lab", "name": "LONG CHILLI", "words": "HOT FOR LONGER", "icon": "chilli",
		"prices": [200, 500], "values": [9.0, 12.0]},
	# values: 1 = every stage starts with the Fire Burp.
	{"id": "spicy_start", "room": "lab", "name": "SPICY START", "words": "FIRE BURP AT START", "icon": "hot_sauce",
		"prices": [1000], "values": [1]},

	# ---------------------------------------------------------------- the Gadget Garage: luck and finding things
	# values: metres away that beans fly to him from.
	{"id": "bean_magnet", "room": "garage", "name": "BEAN MAGNET", "words": "BEANS COME TO YOU", "icon": "magnet",
		"prices": [200, 500, 1000], "values": [2.0, 4.0, 6.0]},
	# values: [extra beans each enemy drops, how many times more often they drop a pickup].
	{"id": "lucky_beans", "room": "garage", "name": "LUCKY BEANS", "words": "MORE DROPS", "icon": "lucky",
		"prices": [400], "values": [[2, 2.0]]},
	# values: 1 = his nose twitches and a "sniff" plays near hidden Golden Beans and secrets.
	{"id": "secret_sniffer", "room": "garage", "name": "SECRET SNIFFER", "words": "SNIFFS OUT SECRETS", "icon": "nose",
		"prices": [600], "values": [1]},
]


## The upgrade with this id, or an empty Dictionary if there is none.
static func find(id: String) -> Dictionary:
	for upgrade: Dictionary in UPGRADES:
		if upgrade["id"] == id:
			return upgrade
	return {}


## The room with this id, or an empty Dictionary.
static func room(room_id: String) -> Dictionary:
	for each: Dictionary in ROOMS:
		if each["id"] == room_id:
			return each
	return {}


## Every upgrade sold in one room, in shop order.
static func in_room(room_id: String) -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	for upgrade: Dictionary in UPGRADES:
		if upgrade["room"] == room_id:
			list.append(upgrade)
	return list


## How many levels an upgrade has (0 for an unknown id).
static func max_level(id: String) -> int:
	var upgrade: Dictionary = find(id)
	return 0 if upgrade.is_empty() else (upgrade["prices"] as Array).size()


## What the next level costs when he already owns "owned" levels. -1 = nothing left to buy.
static func next_price(id: String, owned: int) -> int:
	var upgrade: Dictionary = find(id)
	if upgrade.is_empty() or owned < 0 or owned >= max_level(id):
		return -1
	return int((upgrade["prices"] as Array)[owned])


## What level "level" sets (see "values"). Level 0 (not bought) gives back "fallback".
static func value_at(id: String, level: int, fallback: Variant) -> Variant:
	var upgrade: Dictionary = find(id)
	if upgrade.is_empty() or level <= 0:
		return fallback
	var values: Array = upgrade["values"]
	return values[mini(level, values.size()) - 1]


## Every bean it costs to buy everything (for the price checks in the tests).
static func total_price() -> int:
	var total: int = 0
	for upgrade: Dictionary in UPGRADES:
		for price: int in upgrade["prices"]:
			total += price
	return total
