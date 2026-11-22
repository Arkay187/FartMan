class_name UpgradeApplier
extends RefCounted
## Turns the upgrades Fart Man bought aboard the Complex2000 into his real numbers.
## The stage calls apply() once as it starts. If UPGRADES is switched OFF (start menu)
## nothing at all changes. The values come from UpgradeTable (scripts/upgrade_table.gd).


## How many levels of an upgrade count right now: 0 when UPGRADES is OFF or there is no save.
static func level(from: Node, id: String) -> int:
	if from == null or not from.is_inside_tree():
		return 0
	var options := from.get_node_or_null("/root/DebugOptions") as DebugOptionsData
	if options != null and not options.upgrades_on:
		return 0
	var save: SaveData = SaveLookup.find(from)
	return 0 if save == null else save.upgrade_level(id)


## Sets Fart Man's numbers for this stage. Safe to call twice: the second call does nothing.
static func apply(player: Player, stage: Stage = null) -> void:
	if player == null or not player.is_inside_tree() or player.has_meta(&"upgrades_applied"):
		return
	player.set_meta(&"upgrades_applied", true)
	if stage == null:
		stage = Stage.find(player)

	# ---------------------------------------------------------------- belly and hearts
	var belly: int = level(player, "bigger_belly")
	if belly > 0 and player.gas_tank != null:
		var tank: GasTank = player.gas_tank
		var old_max: float = tank.max_gas
		var new_max: float = float(UpgradeTable.value_at("bigger_belly", belly, old_max))
		tank.max_gas = new_max
		tank.start_gas = new_max
		tank.gas = new_max  # starts full
		tank.gas_changed.emit(tank.gas, tank.max_gas)  # the gas bar redraws
		# A bigger belly hovers longer in the free-gas test modes too.
		if player.hover_helper != null and old_max > 0.0:
			player.hover_helper.hover_time_free_gas *= new_max / old_max
	var hearts_level: int = level(player, "extra_heart")
	if hearts_level > 0 and player.hearts != null:
		player.hearts.max_hearts = int(UpgradeTable.value_at("extra_heart", hearts_level, player.hearts.max_hearts))
		player.hearts.refill()  # full, and the hearts bar redraws
	var big: int = level(player, "big_hearts")
	if big > 0 and player.hearts != null:
		player.hearts.heal_per_pickup = int(UpgradeTable.value_at("big_hearts", big, 1))
	var sticky: int = level(player, "sticky_beans")
	var spill := player.get_node_or_null("BeanSpill") as BeanSpill
	if sticky > 0 and spill != null:
		var pair: Array = UpgradeTable.value_at("sticky_beans", sticky, [spill.spill_lifetime, spill.spill_count])
		spill.spill_lifetime = float(pair[0])
		spill.spill_count = int(pair[1])

	# ---------------------------------------------------------------- moves
	var shoes: int = level(player, "speedy_sneakers")
	if shoes > 0:
		player.move_speed *= float(UpgradeTable.value_at("speedy_sneakers", shoes, 1.0))
	var pants: int = level(player, "springy_pants")
	if pants > 0:
		# The value is a HEIGHT multiplier; height grows with speed squared, so take the square root.
		var boost: float = sqrt(float(UpgradeTable.value_at("springy_pants", pants, 1.0)))
		player.toot_power *= boost
		player.trump_power *= boost
		player.thunder_power *= boost
		if player.simple_helper != null:
			player.simple_helper.simple_jump_power *= boost
	if level(player, "super_stomp") > 0:
		var stomp := player.get_node_or_null("SuperStomp") as SuperStomp
		if stomp != null:
			stomp.enabled = true
	var triple: int = level(player, "triple_jump")
	if triple > 0:
		var extra: int = int(UpgradeTable.value_at("triple_jump", triple, 0))
		if player.simple_helper != null:
			player.simple_helper.air_jumps += extra
			player.simple_helper.refill_air_jumps()
		if player.air_farts_free_gas != -1:
			player.air_farts_free_gas += extra

	# ---------------------------------------------------------------- fire burp and chilli
	var burp: FireBurpPower = player.fire_burp
	if burp != null:
		var more: int = level(player, "more_fireballs")
		if more > 0:
			burp.max_fireballs = int(UpgradeTable.value_at("more_fireballs", more, burp.max_fireballs))
		var bigger: int = level(player, "big_fireballs")
		if bigger > 0:
			burp.fireball_size = float(UpgradeTable.value_at("big_fireballs", bigger, 1.0))
		if level(player, "bouncy_fireballs") > 0:
			burp.bouncy_fireballs = true
		if level(player, "spicy_start") > 0:
			burp.give(true)  # quietly: no speech or hint at every stage start
	var hot: int = level(player, "long_chilli")
	if hot > 0 and player.chilli != null:
		player.chilli.duration = float(UpgradeTable.value_at("long_chilli", hot, player.chilli.duration))

	# ---------------------------------------------------------------- garage
	var magnet: int = level(player, "bean_magnet")
	var magnet_node := player.get_node_or_null("BeanMagnet") as BeanMagnet
	if magnet > 0 and magnet_node != null:
		magnet_node.pull_range = float(UpgradeTable.value_at("bean_magnet", magnet, 0.0))
	var lucky: int = level(player, "lucky_beans")
	if lucky > 0 and stage != null:
		var drops: Array = UpgradeTable.value_at("lucky_beans", lucky, [0, 1.0])
		stage.extra_drop_beans = int(drops[0])
		stage.drop_chance_multiplier = float(drops[1])
	if level(player, "secret_sniffer") > 0:
		var nose := player.get_node_or_null("SecretSniffer") as SecretSniffer
		if nose != null:
			nose.enabled = true
