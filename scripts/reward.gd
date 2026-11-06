extends Control
## After a won battle: pick one of three boons (or skip for gold).

const SKIP_GOLD := 10


func _ready() -> void:
	theme = Game.ui_theme
	Game.make_background(self)
	var center := CenterContainer.new()
	center.set_anchors_preset(PRESET_FULL_RECT)
	add_child(center)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 20)
	center.add_child(box)

	var r := Game.last_reward
	var title := Game.make_label("Victory over %s!" % r.get("enemy", "the enemy"), 40, Color("ffd166"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var info := Game.make_label("+%d gold   +%d HP   (%d turns)\nHP %d / %d   Gold %d" % [
		r.get("gold", 0), r.get("heal", 0), r.get("turns", 0), Game.hp, Game.max_hp, Game.gold], 20, Color("b8afc9"))
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(info)
	var pick := Game.make_label("Choose a boon", 26)
	pick.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(pick)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(row)
	var first: Button = null
	for u in Game.roll_upgrades(3):
		var b := Button.new()
		b.text = "%s\n\n%s" % [u["name"], u["desc"]]
		b.custom_minimum_size = Vector2(260, 130)
		b.pressed.connect(_choose.bind(u))
		row.add_child(b)
		if first == null:
			first = b

	var skip := Button.new()
	skip.text = "Skip (+%d gold)" % SKIP_GOLD
	skip.size_flags_horizontal = SIZE_SHRINK_CENTER
	skip.pressed.connect(_skip)
	box.add_child(skip)
	if first:
		first.grab_focus()


func _choose(u: Dictionary) -> void:
	Game.apply_upgrade(u)
	Game.after_reward()


func _skip() -> void:
	Game.gold += SKIP_GOLD
	Game.after_reward()
