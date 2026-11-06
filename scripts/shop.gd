extends Control
## Merchant between floors: spend gold on healing and boons.

var gold_label: Label
var hp_label: Label
var buttons: Array[Button] = []
var prices: Array[int] = []


func _ready() -> void:
	theme = Game.ui_theme
	Game.make_background(self)
	var center := CenterContainer.new()
	center.set_anchors_preset(PRESET_FULL_RECT)
	add_child(center)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	center.add_child(box)

	var title := Game.make_label("The Wandering Merchant", 40, Color("ffd166"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var stats := HBoxContainer.new()
	stats.alignment = BoxContainer.ALIGNMENT_CENTER
	stats.add_theme_constant_override("separation", 40)
	box.add_child(stats)
	gold_label = Game.make_label("", 24, Color("ffd166"))
	stats.add_child(gold_label)
	hp_label = Game.make_label("", 24, Color("ff8a7a"))
	stats.add_child(hp_label)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	box.add_child(row)

	var heal := GameData.HEAL_ITEM
	_add_item(row, "%s\n%s\n\n%d gold" % [heal["name"], heal["desc"], heal["cost"]], heal["cost"],
			func(): Game.heal(heal["heal"]), true)
	for u in Game.roll_upgrades(3):
		_add_item(row, "%s\n%s\n\n%d gold" % [u["name"], u["desc"], u["cost"]], u["cost"],
				func(): Game.apply_upgrade(u), false)

	var leave := Button.new()
	leave.text = "Continue to floor %d" % (Game.depth + 1)
	leave.size_flags_horizontal = SIZE_SHRINK_CENTER
	leave.custom_minimum_size = Vector2(320, 56)
	leave.pressed.connect(Game.next_floor)
	box.add_child(leave)
	leave.grab_focus()
	_refresh()


func _add_item(row: HBoxContainer, text: String, cost: int, effect: Callable, repeatable: bool) -> void:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(220, 150)
	b.pressed.connect(func():
		if Game.gold < cost:
			return
		Game.gold -= cost
		effect.call()
		if not repeatable:
			b.text = "SOLD"
			b.set_meta("sold", true)
		_refresh())
	row.add_child(b)
	buttons.append(b)
	prices.append(cost)


func _refresh() -> void:
	gold_label.text = "Gold: %d" % Game.gold
	hp_label.text = "HP: %d / %d" % [Game.hp, Game.max_hp]
	for i in buttons.size():
		buttons[i].disabled = buttons[i].has_meta("sold") or Game.gold < prices[i]
