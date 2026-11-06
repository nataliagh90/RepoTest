extends Control
## The game screen: eggs on the left, the snake boss on the right.

const PAIRS := 6
const MISTAKES_ALLOWED := 3
const COLUMNS := 4
const MISMATCH_DELAY := 0.9
const BACKGROUND := Color("8fd3c7")
const INK := Color("2b1d2e")
const CREAM := Color("fff4dc")

## PLACEHOLDER lines the snake says when you lose. Edit freely.
const LOSE_LINES := [
	"Hiss-terical! You already SAW that one, birdbrain.",
	"Vroom vroom, loser! My wheels have a better memory than you.",
	"Ssssseriously? I didn't even have to get off my cart.",
]

## PLACEHOLDER lines the snake says when you mismatch eggs you'd already seen
## (a memory slip that costs a mistake). Edit freely.
const SLIP_LINES := [
	"Hah! You've opened that egg before. Memory of a goldfish!",
	"Ssss... didn't you JUST see that one?",
	"Oops! Did your brain take the day off?",
]
const SLIP_LINE_SECONDS := 2.2

var board: MemoryBoard
var speech_id := 0  # Lets an old speech timer know a newer line replaced it.
var spots: Array[EggSpot] = []
var busy := false
var rng := RandomNumberGenerator.new()

var grid: GridContainer
var hp_bar: ProgressBar
var hp_label: Label
var pips: Array[Label] = []
var speech: Label
var end_panel: Control
var end_title: Label
var end_button: Button


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = BACKGROUND
	bg.set_anchors_preset(PRESET_FULL_RECT)
	add_child(bg)

	var row := HBoxContainer.new()
	row.set_anchors_preset(PRESET_FULL_RECT)
	row.add_theme_constant_override("separation", 0)
	add_child(row)

	var left := CenterContainer.new()
	left.size_flags_horizontal = SIZE_EXPAND_FILL
	row.add_child(left)
	grid = GridContainer.new()
	grid.columns = COLUMNS
	grid.add_theme_constant_override("h_separation", 24)
	grid.add_theme_constant_override("v_separation", 12)
	left.add_child(grid)

	var right := CenterContainer.new()
	right.custom_minimum_size.x = 420
	row.add_child(right)
	right.add_child(_build_boss_panel())

	end_panel = _build_end_panel()
	add_child(end_panel)

	rng.randomize()
	new_game()


func new_game() -> void:
	end_panel.visible = false
	speech.visible = false
	busy = false
	for spot in spots:
		spot.queue_free()
	spots.clear()
	board = MemoryBoard.new(PAIRS, MISTAKES_ALLOWED, rng)
	for i in board.slots.size():
		var spot := EggSpot.new()
		spot.index = i
		spot.bird_id = board.slots[i]
		spot.pressed.connect(_on_spot_pressed)
		grid.add_child(spot)
		spots.append(spot)
	_refresh()


func _on_spot_pressed(i: int) -> void:
	if busy or not board.can_pick(i):
		return
	var res := board.pick(i)
	busy = true
	await spots[i].hatch()
	match res["result"]:
		"match":
			spots[res["a"]].set_matched()
			spots[res["b"]].set_matched()
			_refresh()
			if board.is_complete():
				await get_tree().create_timer(0.6).timeout
				_show_end("You beat the snake!", "Play Again")
				return
		"mismatch":
			_refresh()
			if board.lost:
				await _lose()
				return
			if res["mistake"]:
				_say(SLIP_LINES[rng.randi() % SLIP_LINES.size()], SLIP_LINE_SECONDS)
			await get_tree().create_timer(MISMATCH_DELAY).timeout
			spots[res["a"]].close()
			await spots[res["b"]].close()
	busy = false


func _lose() -> void:
	_say(LOSE_LINES[rng.randi() % LOSE_LINES.size()], 0.0)
	await get_tree().create_timer(2.8).timeout
	_show_end("You lose!", "Try Again")


## Shows a speech bubble. With seconds > 0 it hides itself afterwards,
## unless a newer line has replaced it in the meantime.
func _say(text: String, seconds: float) -> void:
	speech_id += 1
	var my_id := speech_id
	speech.text = text
	speech.visible = true
	if seconds > 0.0:
		await get_tree().create_timer(seconds).timeout
		if speech_id == my_id:
			speech.visible = false


func _refresh() -> void:
	hp_bar.max_value = board.boss_max_hp
	hp_bar.value = board.boss_hp
	hp_label.text = "HP %d / %d" % [board.boss_hp, board.boss_max_hp]
	for k in pips.size():
		var used := k >= board.mistakes_left
		pips[k].add_theme_color_override("font_color", Color(INK, 0.25) if used else Color("e2483d"))


# --- UI building ---

func _label(text: String, font_size: int, color: Color = INK) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	return l


func _build_boss_panel() -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)

	speech = _label("", 22)
	speech.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	speech.custom_minimum_size = Vector2(340, 0)
	speech.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var bubble := StyleBoxFlat.new()
	bubble.bg_color = Color.WHITE
	bubble.border_color = INK
	bubble.set_border_width_all(4)
	bubble.set_corner_radius_all(18)
	bubble.set_content_margin_all(14)
	speech.add_theme_stylebox_override("normal", bubble)
	box.add_child(speech)

	box.add_child(SnakeBoss.new())

	hp_bar = ProgressBar.new()
	hp_bar.custom_minimum_size = Vector2(340, 30)
	hp_bar.show_percentage = false
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("e2483d")
	fill.set_corner_radius_all(8)
	var back := StyleBoxFlat.new()
	back.bg_color = CREAM
	back.border_color = INK
	back.set_border_width_all(4)
	back.set_corner_radius_all(8)
	hp_bar.add_theme_stylebox_override("fill", fill)
	hp_bar.add_theme_stylebox_override("background", back)
	box.add_child(hp_bar)
	hp_label = _label("", 22)
	hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(hp_label)

	var mistakes := HBoxContainer.new()
	mistakes.alignment = BoxContainer.ALIGNMENT_CENTER
	mistakes.add_theme_constant_override("separation", 8)
	mistakes.add_child(_label("Mistakes allowed:", 22))
	pips.clear()
	for k in MISTAKES_ALLOWED:
		var p := _label("●", 30)
		mistakes.add_child(p)
		pips.append(p)
	box.add_child(mistakes)
	return box


func _build_end_panel() -> Control:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.45)
	dim.set_anchors_preset(PRESET_FULL_RECT)
	var center := CenterContainer.new()
	center.set_anchors_preset(PRESET_FULL_RECT)
	dim.add_child(center)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 24)
	center.add_child(box)

	end_title = _label("", 56, CREAM)
	end_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	end_title.add_theme_constant_override("outline_size", 12)
	end_title.add_theme_color_override("font_outline_color", INK)
	box.add_child(end_title)

	end_button = Button.new()
	end_button.custom_minimum_size = Vector2(260, 64)
	end_button.size_flags_horizontal = SIZE_SHRINK_CENTER
	end_button.add_theme_font_size_override("font_size", 28)
	end_button.pressed.connect(new_game)
	box.add_child(end_button)
	return dim


func _show_end(title: String, button_text: String) -> void:
	end_title.text = title
	end_button.text = button_text
	end_panel.visible = true
