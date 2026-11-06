extends Control
## Title screen.

const HOW_TO_PLAY := """Every battle is a game of memory.

- Flip two cards per turn. A matching pair triggers its effect:
    Strike: damage   Bolt: big damage + delays the enemy
    Guard: block   Potion: heal   Gold: money
- Matches in a row build a combo that powers up every effect.
- Each turn the enemy's countdown ticks. At zero, it attacks.
- Missing a Curse card hurts. Watch out for enemies that shuffle!
- Clear the board and a new one is dealt. You peek at it first.

Win battles to choose boons, visit shops, and beat both bosses
to escape all 10 floors. If you die, the run is over."""


func _ready() -> void:
	theme = Game.ui_theme
	Game.make_background(self)
	var center := CenterContainer.new()
	center.set_anchors_preset(PRESET_FULL_RECT)
	add_child(center)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	center.add_child(box)

	var title := Game.make_label("MNEMOS", 84, Color("e0d4ff"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var sub := Game.make_label("A roguelike memory dungeon", 24, Color("b8afc9"))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(sub)
	box.add_child(Control.new())

	var help := Game.make_label(HOW_TO_PLAY, 17, Color("d6cfe6"))
	help.visible = false

	var start := _button("New Run", Game.start_new_run)
	box.add_child(start)
	box.add_child(_button("How to Play", func(): help.visible = not help.visible))
	if OS.get_name() != "Web":
		box.add_child(_button("Quit", get_tree().quit))
	box.add_child(help)
	start.grab_focus()


func _button(text: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(320, 56)
	b.size_flags_horizontal = SIZE_SHRINK_CENTER
	b.pressed.connect(action)
	return b
