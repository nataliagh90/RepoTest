extends Control
## The memory game screen: a grid of eggs, and a win message at the end.

const PAIRS := 6
const COLUMNS := 4
const MISMATCH_DELAY := 0.9
const BACKGROUND := Color("8fd3c7")

var board: MemoryBoard
var spots: Array[EggSpot] = []
var busy := false
var rng := RandomNumberGenerator.new()

var grid: GridContainer
var win_panel: Control


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = BACKGROUND
	bg.set_anchors_preset(PRESET_FULL_RECT)
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_preset(PRESET_FULL_RECT)
	add_child(center)
	grid = GridContainer.new()
	grid.columns = COLUMNS
	grid.add_theme_constant_override("h_separation", 24)
	grid.add_theme_constant_override("v_separation", 12)
	center.add_child(grid)

	win_panel = _build_win_panel()
	add_child(win_panel)

	rng.randomize()
	new_game()


func new_game() -> void:
	win_panel.visible = false
	busy = false
	for spot in spots:
		spot.queue_free()
	spots.clear()
	board = MemoryBoard.new(PAIRS, rng)
	for i in board.slots.size():
		var spot := EggSpot.new()
		spot.index = i
		spot.bird_id = board.slots[i]
		spot.pressed.connect(_on_spot_pressed)
		grid.add_child(spot)
		spots.append(spot)


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
			if board.is_complete():
				await get_tree().create_timer(0.5).timeout
				win_panel.visible = true
		"mismatch":
			await get_tree().create_timer(MISMATCH_DELAY).timeout
			spots[res["a"]].close()
			await spots[res["b"]].close()
	busy = false


func _build_win_panel() -> Control:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.45)
	dim.set_anchors_preset(PRESET_FULL_RECT)
	var center := CenterContainer.new()
	center.set_anchors_preset(PRESET_FULL_RECT)
	dim.add_child(center)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 24)
	center.add_child(box)

	var title := Label.new()
	title.text = "All the birds are hatched!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 52)
	title.add_theme_color_override("font_color", Color("fff4dc"))
	title.add_theme_constant_override("outline_size", 12)
	title.add_theme_color_override("font_outline_color", EggSpot.OUTLINE)
	box.add_child(title)

	var again := Button.new()
	again.text = "Play Again"
	again.custom_minimum_size = Vector2(260, 64)
	again.size_flags_horizontal = SIZE_SHRINK_CENTER
	again.add_theme_font_size_override("font_size", 28)
	again.pressed.connect(new_game)
	box.add_child(again)
	return dim
