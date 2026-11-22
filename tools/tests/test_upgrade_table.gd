extends SceneTree
# Checks the upgrade price table and buying: every upgrade from BEAN_SHIP_PLAN.md is there with the
# right prices, buying takes beans from the jar and can never take it below zero, a fully bought
# upgrade can't be bought again, nothing but buying lowers the jar, upgrades come back after
# reloading the save (a throwaway file, never the real save), and the UPGRADES ON/OFF setting is
# remembered in the options file.

const SAVE_FILE: String = "user://test_upgrade_table_save.json"
const OPTIONS_FILE: String = "user://test_upgrade_table_options.json"
var failures: int = 0


func _initialize() -> void:
	_run()


func _check(label: String, ok: bool) -> void:
	print("%s: %s" % [label, "ok" if ok else "FAILED"])
	if not ok:
		failures += 1


func _room_total(room_id: String) -> int:
	var total: int = 0
	for upgrade: Dictionary in UpgradeTable.in_room(room_id):
		for price: int in upgrade["prices"]:
			total += price
	return total


func _run() -> void:
	# ---------------------------------------------------------------- the table
	_check("four rooms: kitchen, gym, lab, garage",
		UpgradeTable.ROOMS.size() == 4 and not UpgradeTable.room("kitchen").is_empty()
		and not UpgradeTable.room("gym").is_empty() and not UpgradeTable.room("lab").is_empty()
		and not UpgradeTable.room("garage").is_empty())
	var ids: Dictionary = {}
	var tidy: bool = true
	for upgrade: Dictionary in UpgradeTable.UPGRADES:
		var id: String = upgrade["id"]
		if ids.has(id) or UpgradeTable.room(upgrade["room"]).is_empty():
			tidy = false
		ids[id] = true
		if (upgrade["prices"] as Array).size() != (upgrade["values"] as Array).size():
			tidy = false
		for key: String in ["name", "words", "icon"]:
			if str(upgrade.get(key, "")) == "":
				tidy = false
	_check("16 upgrades, ids unique, a price and a value for every level, names and icons set (%d)" % ids.size(),
		ids.size() == 16 and tidy)
	_check("the plan's room totals: kitchen 2850, gym 3450, lab 3350, garage 2700 (%d %d %d %d)" % [
		_room_total("kitchen"), _room_total("gym"), _room_total("lab"), _room_total("garage")],
		_room_total("kitchen") == 2850 and _room_total("gym") == 3450 and _room_total("lab") == 3350
		and _room_total("garage") == 2700)
	_check("Bigger Belly costs 150 / 400 / 800",
		UpgradeTable.next_price("bigger_belly", 0) == 150 and UpgradeTable.next_price("bigger_belly", 1) == 400
		and UpgradeTable.next_price("bigger_belly", 2) == 800 and UpgradeTable.next_price("bigger_belly", 3) == -1)
	_check("Triple Jump 1200, Spicy Start 1000, Bean Magnet 3 is 1000",
		UpgradeTable.next_price("triple_jump", 0) == 1200 and UpgradeTable.next_price("spicy_start", 0) == 1000
		and UpgradeTable.next_price("bean_magnet", 2) == 1000)
	_check("value_at: level 0 gives the normal value, levels give theirs",
		UpgradeTable.value_at("extra_heart", 0, 3) == 3 and UpgradeTable.value_at("extra_heart", 2, 3) == 5
		and is_equal_approx(float(UpgradeTable.value_at("bean_magnet", 1, 0.0)), 2.0))
	_check("an unknown id has no levels and no price",
		UpgradeTable.max_level("rocket_socks") == 0 and UpgradeTable.next_price("rocket_socks", 0) == -1)

	# ---------------------------------------------------------------- buying
	var save := root.get_node_or_null("SaveGame") as SaveData
	if save == null:
		save = SaveData.new()
		save.name = "SaveGame"
		root.add_child(save)
	save.use_file(SAVE_FILE)
	save.reset()
	_check("headless tests use a throwaway save (%s)" % save.save_path, save.save_path == SAVE_FILE)
	_check("nothing owned at the start", save.upgrade_level("bigger_belly") == 0 and save.upgrades.is_empty())
	_check("an empty jar can't buy anything", not save.can_buy_upgrade("bigger_belly")
		and not save.buy_upgrade("bigger_belly") and save.bean_jar == 0 and save.upgrade_level("bigger_belly") == 0)
	save.bank_beans(149)
	_check("149 beans can't buy a 150 bean upgrade (jar stays 149)",
		not save.buy_upgrade("bigger_belly") and save.bean_jar == 149 and save.upgrade_level("bigger_belly") == 0)
	save.bank_beans(1)
	_check("150 beans buy Bigger Belly 1 and the jar is empty (%d)" % save.bean_jar,
		save.buy_upgrade("bigger_belly") and save.bean_jar == 0 and save.upgrade_level("bigger_belly") == 1)
	save.bank_beans(5000)
	_check("level 2 costs 400 (%d left)" % save.bean_jar,
		save.buy_upgrade("bigger_belly") and save.bean_jar == 4600 and save.upgrade_level("bigger_belly") == 2)
	_check("level 3 costs 800 (%d left)" % save.bean_jar,
		save.buy_upgrade("bigger_belly") and save.bean_jar == 3800 and save.upgrade_level("bigger_belly") == 3)
	_check("a fully bought upgrade can't be bought again and costs nothing",
		not save.can_buy_upgrade("bigger_belly") and not save.buy_upgrade("bigger_belly") and save.bean_jar == 3800)
	_check("an unknown upgrade can't be bought", not save.buy_upgrade("rocket_socks") and save.bean_jar == 3800)
	# Buy until the jar runs dry: it never goes below zero.
	var lowest: int = save.bean_jar
	for round_number in 4:
		for upgrade: Dictionary in UpgradeTable.UPGRADES:
			save.buy_upgrade(upgrade["id"])
			lowest = mini(lowest, save.bean_jar)
	_check("buying everything it can never takes the jar below zero (lowest %d)" % lowest, lowest >= 0)
	save.reset()
	save.bank_beans(UpgradeTable.total_price())
	for round_number in 4:
		for upgrade: Dictionary in UpgradeTable.UPGRADES:
			save.buy_upgrade(upgrade["id"])
	var all_owned: bool = true
	for upgrade: Dictionary in UpgradeTable.UPGRADES:
		if save.upgrade_level(upgrade["id"]) != UpgradeTable.max_level(upgrade["id"]):
			all_owned = false
	_check("the whole price list (%d) buys every level of everything, leaving 0 (%d)" % [UpgradeTable.total_price(), save.bean_jar],
		all_owned and save.bean_jar == 0)

	# ---------------------------------------------------------------- only buying lowers the jar
	save.reset()
	save.bank_beans(1000)
	save.buy_upgrade("speedy_sneakers")
	var after_buy: int = save.bean_jar
	save.record_stage("1-1", 2, 900)
	save.mark_seen("shop_hello")
	save.set_last_stop("1-2")
	save.bank_beans(0)
	save.bank_beans(-50)
	save.load_game()
	_check("saving stages, flags, stops, banking nothing and reloading never lower the jar (%d)" % save.bean_jar,
		save.bean_jar == after_buy and after_buy == 800)

	# ---------------------------------------------------------------- the save file
	save.bank_beans(5000)
	save.buy_upgrade("extra_heart")
	save.buy_upgrade("extra_heart")
	save.buy_upgrade("bean_magnet")
	var jar_now: int = save.bean_jar
	var fresh := SaveData.new()
	fresh.use_file(SAVE_FILE)
	_check("a fresh SaveData reading the file sees the upgrades and the jar",
		fresh.upgrade_level("extra_heart") == 2 and fresh.upgrade_level("bean_magnet") == 1
		and fresh.upgrade_level("speedy_sneakers") == 1 and fresh.bean_jar == jar_now)
	fresh.free()
	# A hand-edited or broken file: unknown ids dropped, levels kept in range, floats made whole.
	var file := FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	file.store_string(JSON.stringify({"bean_jar": 10, "upgrades": {"extra_heart": 9.0, "rocket_socks": 2, "long_chilli": -3, "bean_magnet": 1.0}}))
	file.close()
	save.load_game()
	_check("a messy file is tidied: extra_heart capped at 2, junk dropped, magnet 1",
		save.upgrade_level("extra_heart") == 2 and not save.upgrades.has("rocket_socks")
		and not save.upgrades.has("long_chilli") and save.upgrade_level("bean_magnet") == 1)
	save.reset()
	_check("NEW GAME (reset) forgets the upgrades", save.upgrades.is_empty() and save.upgrade_level("extra_heart") == 0)

	# ---------------------------------------------------------------- UPGRADES ON / OFF is remembered
	var options := root.get_node("DebugOptions") as DebugOptionsData
	_check("UPGRADES is ON by default", options.upgrades_on)
	var writer := DebugOptionsData.new()
	writer.test_saving = true
	writer.save_path = OPTIONS_FILE
	writer.set_upgrades_on(false)
	var reader := DebugOptionsData.new()
	reader.test_saving = true
	reader.save_path = OPTIONS_FILE
	reader._load()
	_check("UPGRADES OFF is remembered in the options file", not reader.upgrades_on)
	writer.set_upgrades_on(true)
	reader._load()
	_check("and ON too", reader.upgrades_on)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(OPTIONS_FILE))
	writer.free()
	reader.free()

	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_FILE))
	print("upgrade table failures: %d" % failures)
	quit()
