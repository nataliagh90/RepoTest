extends Control
## End of a run, win or lose.


func _ready() -> void:
	theme = Game.ui_theme
	Game.make_background(self)
	var center := CenterContainer.new()
	center.set_anchors_preset(PRESET_FULL_RECT)
	add_child(center)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	center.add_child(box)

	var title_text := "You escaped the depths!" if Game.run_won else "You were defeated"
	var title := Game.make_label(title_text, 52, Color("ffd166") if Game.run_won else Color("ff6b5a"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	var lines: Array[String] = []
	if not Game.run_won:
		lines.append("Slain by %s on floor %d of %d" % [Game.killed_by, Game.depth, Game.MAX_DEPTH])
	lines.append("Gold: %d   Max HP: %d" % [Game.gold, Game.max_hp])
	lines.append("Boons: %s" % (", ".join(Game.upgrades) if not Game.upgrades.is_empty() else "none"))
	lines.append("Seed: %d" % Game.run_seed)
	var summary := Game.make_label("\n".join(lines), 20, Color("d6cfe6"))
	summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary.custom_minimum_size.x = 700
	box.add_child(summary)

	var again := Button.new()
	again.text = "New Run"
	again.custom_minimum_size = Vector2(320, 56)
	again.size_flags_horizontal = SIZE_SHRINK_CENTER
	again.pressed.connect(Game.start_new_run)
	box.add_child(again)
	var menu := Button.new()
	menu.text = "Main Menu"
	menu.custom_minimum_size = Vector2(320, 56)
	menu.size_flags_horizontal = SIZE_SHRINK_CENTER
	menu.pressed.connect(Game.goto.bind(Game.SCENE_MENU))
	box.add_child(menu)
	again.grab_focus()
