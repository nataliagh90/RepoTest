extends Control
## Battle screen: player panel (left), card board (middle), enemy panel (right).
## Sends clicks to Combat and animates the events it returns.

const CARD_SIZE := Vector2(100, 125)

var combat: Combat
var card_views: Array[CardView] = []
var busy := true

var grid: GridContainer
var floor_label: Label
var gold_label: Label
var log_label: Label
var player_panel: PanelContainer
var player_hp_bar: ProgressBar
var player_hp_label: Label
var block_label: Label
var combo_label: Label
var stats_label: Label
var enemy_panel: PanelContainer
var enemy_name_label: Label
var enemy_traits_label: Label
var enemy_hp_bar: ProgressBar
var enemy_hp_label: Label
var intent_label: Label


func _ready() -> void:
	theme = Game.ui_theme
	_build_ui()
	combat = Combat.new(Game, Game.enemy_for_depth(Game.depth), Game.rng)
	_log("%s blocks the way!" % combat.enemy["name"])
	_rebuild_board()
	_refresh()
	await _peek()


# --- Input & event playback ---

func _on_card_pressed(i: int) -> void:
	if busy or not combat.can_pick(i):
		return
	busy = true
	await _play(combat.pick(i))
	if not combat.finished:
		busy = false


func _play(events: Array[Dictionary]) -> void:
	for e in events:
		match e["type"]:
			"flip":
				await card_views[e["index"]].flip(true)
			"match":
				await _wait(0.25)
				card_views[e["a"]].set_matched()
				card_views[e["b"]].set_matched()
				if e["combo"] > 0:
					_float("Combo x%d!" % (e["combo"] + 1), Color("ffd166"), _center_of(grid) + Vector2(0, -40))
			"mismatch":
				await _wait(0.65)
				card_views[e["a"]].flip(false)
				await card_views[e["b"]].flip(false)
				_log("No match.")
			"enemy_hit":
				_flash(enemy_panel, Color(1, 0.5, 0.5))
				_float("-%d" % e["amount"], Color("ff6b5a"), _center_of(enemy_panel))
				var verb: String = {"sword": "strike", "bolt": "blast", "thorns": "thorns hit"}.get(e["source"], "hit")
				_log("You %s %s for %d." % [verb, combat.enemy["name"], e["amount"]])
			"block":
				_float("+%d block" % e["amount"], Color("7fb2ff"), _center_of(player_panel))
				_log("You raise your guard (+%d block)." % e["amount"])
			"heal":
				if e["amount"] > 0:
					_float("+%d HP" % e["amount"], Color("6fdc8c"), _center_of(player_panel))
			"gold":
				_float("+%d gold" % e["amount"], Color("ffd166"), _center_of(player_panel))
				_log("You pocket %d gold." % e["amount"])
			"stall":
				_log("The bolt staggers %s!" % combat.enemy["name"])
			"cleanse":
				_log("You lift the curse.")
			"enemy_attack":
				await _lunge(enemy_panel)
			"player_hit":
				_flash(player_panel, Color(1, 0.45, 0.45))
				var txt := "-%d" % e["amount"]
				if e["blocked"] > 0:
					txt += " (%d blocked)" % e["blocked"]
				_float(txt, Color("ff6b5a"), _center_of(player_panel))
				if e["source"] == "curse":
					_log("The curse burns you for %d!" % e["amount"])
				else:
					_log("%s hits you for %d." % [combat.enemy["name"], e["amount"]])
			"regen":
				_float("+%d" % e["amount"], Color("6fdc8c"), _center_of(enemy_panel))
				_log("%s regenerates." % combat.enemy["name"])
			"enrage":
				_log("%s grows angrier!" % combat.enemy["name"])
			"shuffle":
				_log("%s shuffles your cards!" % combat.enemy["name"])
				for v in card_views:
					if not v.matched:
						v.card_type = combat.cards[v.index]["type"]
						v.wobble()
				await _wait(0.3)
			"new_board":
				await _wait(0.5)
				_log("The board is cleared. New cards are dealt!")
				_rebuild_board()
				_refresh()
				await _peek()
			"victory":
				_refresh()
				_log("%s is defeated!" % combat.enemy["name"])
				await _wait(1.0)
				Game.on_battle_won(combat)
				return
			"defeat":
				_refresh()
				_log("You fall...")
				await _wait(1.2)
				Game.on_battle_lost(combat)
				return
		_refresh()


func _peek() -> void:
	busy = true
	if Game.peek_time > 0:
		await _wait(0.3)
		for v in card_views:
			v.flip(true)
		await _wait(0.2 + Game.peek_time)
		for v in card_views:
			v.flip(false)
		await _wait(0.2)
	busy = false


# --- Board & UI ---

func _rebuild_board() -> void:
	for v in card_views:
		v.queue_free()
	card_views.clear()
	grid.columns = maxi(4, ceili(combat.cards.size() / 4.0))
	for i in combat.cards.size():
		var v := CardView.new()
		v.setup(i, combat.cards[i]["type"], CARD_SIZE)
		v.pressed.connect(_on_card_pressed)
		grid.add_child(v)
		card_views.append(v)


func _refresh() -> void:
	var boss := " - BOSS" if Game.is_boss_depth() else ""
	floor_label.text = "Floor %d / %d%s" % [Game.depth, Game.MAX_DEPTH, boss]
	gold_label.text = "Gold: %d" % Game.gold

	player_hp_bar.max_value = Game.max_hp
	player_hp_bar.value = Game.hp
	player_hp_label.text = "HP %d / %d" % [Game.hp, Game.max_hp]
	block_label.text = "Block: %d" % combat.block
	combo_label.text = "Combo: x%d" % (combat.combo + 1) if combat.combo > 0 else "Combo: -"
	stats_label.text = "Strike %d   Bolt %d\nGuard +%d   Potion +%d\nGold +%d   Peek %.1fs" % [
		Game.sword_damage, Game.sword_damage + 2, Game.block_gain, Game.potion_heal,
		Game.coin_gain, Game.peek_time]
	if Game.thorns > 0 or Game.lifesteal > 0:
		stats_label.text += "\nThorns %d   Lifesteal %d" % [Game.thorns, Game.lifesteal]

	var e := combat.enemy
	enemy_name_label.text = e["name"]
	enemy_hp_bar.max_value = e["max_hp"]
	enemy_hp_bar.value = e["hp"]
	enemy_hp_label.text = "HP %d / %d" % [e["hp"], e["max_hp"]]
	var traits: Array = e.get("traits", [])
	enemy_traits_label.text = "\n".join(traits.map(func(t): return "- " + GameData.TRAITS[t]))
	if e["timer"] <= 1:
		intent_label.text = "Attacks for %d\nNEXT TURN!" % e["atk"]
		intent_label.add_theme_color_override("font_color", Color("ff6b5a"))
	else:
		intent_label.text = "Attacks for %d\nin %d turns" % [e["atk"], e["timer"]]
		intent_label.add_theme_color_override("font_color", Color("ffd166"))


func _build_ui() -> void:
	Game.make_background(self)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	margin.add_child(root)

	var top := HBoxContainer.new()
	root.add_child(top)
	floor_label = Game.make_label("", 24)
	top.add_child(floor_label)
	var spacer := Control.new()
	spacer.size_flags_horizontal = SIZE_EXPAND_FILL
	top.add_child(spacer)
	gold_label = Game.make_label("", 24, Color("ffd166"))
	top.add_child(gold_label)

	var mid := HBoxContainer.new()
	mid.size_flags_vertical = SIZE_EXPAND_FILL
	mid.add_theme_constant_override("separation", 16)
	root.add_child(mid)

	# Player
	player_panel = PanelContainer.new()
	player_panel.custom_minimum_size.x = 250
	mid.add_child(player_panel)
	var pv := VBoxContainer.new()
	pv.add_theme_constant_override("separation", 10)
	player_panel.add_child(pv)
	pv.add_child(Game.make_label("YOU", 26))
	player_hp_bar = _bar(Color("c0392b"))
	pv.add_child(player_hp_bar)
	player_hp_label = Game.make_label("", 20)
	pv.add_child(player_hp_label)
	block_label = Game.make_label("", 20, Color("7fb2ff"))
	pv.add_child(block_label)
	combo_label = Game.make_label("", 20, Color("ffd166"))
	pv.add_child(combo_label)
	pv.add_child(HSeparator.new())
	stats_label = Game.make_label("", 16, Color("b8afc9"))
	pv.add_child(stats_label)

	# Board
	var center := CenterContainer.new()
	center.size_flags_horizontal = SIZE_EXPAND_FILL
	mid.add_child(center)
	grid = GridContainer.new()
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	center.add_child(grid)

	# Enemy
	enemy_panel = PanelContainer.new()
	enemy_panel.custom_minimum_size.x = 250
	mid.add_child(enemy_panel)
	var ev := VBoxContainer.new()
	ev.add_theme_constant_override("separation", 10)
	enemy_panel.add_child(ev)
	enemy_name_label = Game.make_label("", 26, Color("ff9b8a"))
	enemy_name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ev.add_child(enemy_name_label)
	enemy_hp_bar = _bar(Color("8e44ad"))
	ev.add_child(enemy_hp_bar)
	enemy_hp_label = Game.make_label("", 20)
	ev.add_child(enemy_hp_label)
	intent_label = Game.make_label("", 22)
	ev.add_child(intent_label)
	ev.add_child(HSeparator.new())
	enemy_traits_label = Game.make_label("", 16, Color("b8afc9"))
	enemy_traits_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	enemy_traits_label.custom_minimum_size.x = 220
	ev.add_child(enemy_traits_label)

	log_label = Game.make_label("", 18, Color("b8afc9"))
	log_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(log_label)


func _bar(color: Color) -> ProgressBar:
	var b := ProgressBar.new()
	b.custom_minimum_size = Vector2(0, 22)
	b.show_percentage = false
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.set_corner_radius_all(6)
	b.add_theme_stylebox_override("fill", fill)
	return b


# --- Juice ---

func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _log(text: String) -> void:
	log_label.text = text


func _center_of(c: Control) -> Vector2:
	return c.get_global_rect().get_center()


func _float(text: String, color: Color, at: Vector2) -> void:
	var l := Game.make_label(text, 28, color)
	l.add_theme_constant_override("outline_size", 8)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.mouse_filter = MOUSE_FILTER_IGNORE
	l.z_index = 10
	add_child(l)
	l.position = at - Vector2(l.get_minimum_size().x / 2, 20)
	var t := create_tween().set_parallel()
	t.tween_property(l, "position:y", l.position.y - 70, 1.0).set_ease(Tween.EASE_OUT)
	t.tween_property(l, "modulate:a", 0.0, 0.5).set_delay(0.5)
	t.chain().tween_callback(l.queue_free)


func _flash(c: Control, color: Color) -> void:
	c.modulate = color
	create_tween().tween_property(c, "modulate", Color.WHITE, 0.35)


func _lunge(c: Control) -> void:
	var t := create_tween()
	t.tween_property(c, "position:x", c.position.x - 30, 0.1).set_ease(Tween.EASE_OUT)
	t.tween_property(c, "position:x", c.position.x, 0.15).set_ease(Tween.EASE_IN)
	await t.finished
