extends Control
## The game screen: level bar on top, eggs on the left, the snake boss on
## the right.

const MISTAKES_ALLOWED := 3
const MISMATCH_DELAY := 0.9
# NES-style UI: black boxes, white borders, white text.
const BOX := Color("000000")
const TEXT := Color("fcfcfc")
const TEXT_DIM := Color("7c7c7c")
const HIGHLIGHT := Color("f8b800")

## The levels, in order. "pairs" is how many bird pairs are on the board,
## "columns" how wide the grid is, and "tricks" what the snake may do (see
## MemoryBoard for timing).
const LEVELS := [
	{"pairs": 6, "columns": 4, "tricks": []},
	{"pairs": 8, "columns": 4, "tricks": ["swap"]},
	{"pairs": 10, "columns": 5, "tricks": ["blind"]},
	{"pairs": 12, "columns": 6, "tricks": ["swap", "blind"]},
]

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

## PLACEHOLDER lines announcing a swap, so the player sees it happen.
const SWAP_LINES := ["Vroom! Swapsies!", "Let's shuffle things up a bit..."]
## PLACEHOLDER lines when you discover a secretly blindfolded egg.
const BLIND_LINES := ["Surprise! That one's blindfolded. Hehehe.", "Peekaboo... not!"]

var level := 0
var board: MemoryBoard
var spots: Array[EggSpot] = []
var busy := false
var rng := RandomNumberGenerator.new()
var game_id := 0  # Bumped on every (re)start so unfinished animations of an old board stop.

var grid: GridContainer
var level_label: Label
var prev_button: Button
var skip_button: Button
var snake: SnakeBoss
var fx_layer: Control  # Bullets fly here, above everything else.
var hp_bar: ProgressBar
var hp_label: Label
var pips: Array[TextureRect] = []
var speech: Label
var end_panel: Control
var end_title: Label
var end_quote: Label
var end_button: Button
var end_action: Callable


func _ready() -> void:
	theme = _build_theme()
	# The snake's lair, a pixel-art background covering the whole screen.
	var bg := TextureRect.new()
	bg.texture = Sprites.lair()
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_preset(PRESET_FULL_RECT)
	bg.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(bg)

	var root := VBoxContainer.new()
	root.set_anchors_preset(PRESET_FULL_RECT)
	add_child(root)
	root.add_child(_build_level_bar())

	var row := HBoxContainer.new()
	row.size_flags_vertical = SIZE_EXPAND_FILL
	root.add_child(row)
	var left := CenterContainer.new()
	left.size_flags_horizontal = SIZE_EXPAND_FILL
	row.add_child(left)
	grid = GridContainer.new()
	left.add_child(grid)
	# Right column, pinned to the top so nothing moves when the snake talks.
	var right := MarginContainer.new()
	right.custom_minimum_size.x = 420
	right.add_theme_constant_override("margin_top", 8)
	row.add_child(right)
	var boss_panel := _build_boss_panel()
	boss_panel.size_flags_horizontal = SIZE_SHRINK_CENTER
	boss_panel.size_flags_vertical = SIZE_SHRINK_BEGIN
	right.add_child(boss_panel)

	fx_layer = Control.new()
	fx_layer.set_anchors_preset(PRESET_FULL_RECT)
	fx_layer.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(fx_layer)

	end_panel = _build_end_panel()
	add_child(end_panel)

	rng.randomize()
	start_level(0)


func start_level(n: int) -> void:
	level = clampi(n, 0, LEVELS.size() - 1)
	game_id += 1
	end_panel.visible = false
	_hush()
	busy = false
	for spot in spots:
		spot.queue_free()
	spots.clear()
	var cfg: Dictionary = LEVELS[level]
	board = MemoryBoard.new(cfg["pairs"], MISTAKES_ALLOWED, rng, cfg["tricks"])
	# Bigger boards (4 rows) use smaller art pixels so everything fits.
	var rows := ceili(board.slots.size() / float(cfg["columns"]))
	var art_px := Sprites.PX if rows <= 3 else Sprites.PX - 1
	grid.columns = cfg["columns"]
	grid.add_theme_constant_override("h_separation", 24 if rows <= 3 else 12)
	grid.add_theme_constant_override("v_separation", 12 if rows <= 3 else 6)
	for i in board.slots.size():
		var spot := EggSpot.new()
		spot.px = art_px
		spot.index = i
		spot.bird_id = board.slots[i]
		spot.blind = board.blind[i]
		spot.pressed.connect(_on_spot_pressed)
		grid.add_child(spot)
		spots.append(spot)
	level_label.text = "Level %d / %d" % [level + 1, LEVELS.size()]
	prev_button.disabled = level == 0
	skip_button.disabled = level == LEVELS.size() - 1
	_refresh()


# --- Turns ---

func _on_spot_pressed(i: int) -> void:
	if busy or not board.can_pick(i):
		return
	var my_game := game_id
	_hush()  # Speech stays up until the player picks the next egg.
	var res := board.pick(i)
	busy = true
	await spots[i].hatch()
	if my_game != game_id:
		return
	if res.get("discovered_blind", false):
		_say(_pick_line(BLIND_LINES))
	match res["result"]:
		"match":
			spots[res["a"]].set_matched()
			spots[res["b"]].set_matched()
			await _shoot([spots[res["a"]], spots[res["b"]]])
			if my_game != game_id:
				return
			_refresh()
			if board.is_complete():
				await _wait(0.6)
				if my_game == game_id:
					_win()
				return
			await _after_turn()
		"mismatch":
			_refresh()
			if board.lost:
				await _lose()
				return
			if res["mistake"]:
				_say(_pick_line(SLIP_LINES))
			await _wait(MISMATCH_DELAY)
			if my_game != game_id:
				return
			spots[res["a"]].close()
			await spots[res["b"]].close()
			if my_game != game_id:
				return
			await _after_turn()
	if my_game == game_id:
		busy = false


## Between turns the snake may pull a trick.
func _after_turn() -> void:
	var trick := board.maybe_trick(rng)
	match trick.get("trick", ""):
		"swap":
			_say(_pick_line(SWAP_LINES))
			await _animate_swap(trick["a"], trick["b"])


## The two eggs visibly hop over to each other's nest.
func _animate_swap(a: int, b: int) -> void:
	var ea := spots[a]
	var eb := spots[b]
	var pa := ea.position
	var pb := eb.position
	ea.z_index = 5
	eb.z_index = 5
	var t := create_tween().set_parallel()
	t.tween_method(func(v: float): ea.position = pa.lerp(pb, v) + Vector2(0, -60 * sin(v * PI)), 0.0, 1.0, 0.7)
	t.tween_method(func(v: float): eb.position = pb.lerp(pa, v) + Vector2(0, -60 * sin(v * PI)), 0.0, 1.0, 0.7)
	await t.finished
	if not is_instance_valid(ea) or not is_instance_valid(eb) or ea.is_queued_for_deletion():
		return
	# The view's eggs return to their slots, now showing the swapped contents.
	ea.position = pa
	eb.position = pb
	ea.z_index = 0
	eb.z_index = 0
	for k in [a, b]:
		spots[k].bird_id = board.slots[k]
		spots[k].blind = board.blind[k]
		spots[k].blind_known = board.is_known_blind(k)
		spots[k].queue_redraw()


## Both birds of a matched pair fire bursts at the snake. Each bullet that
## lands takes its share of the match's damage off the HP bar.
const SHOTS_PER_BIRD := 3

func _shoot(shooters: Array) -> void:
	var my_game := game_id
	var shots := SHOTS_PER_BIRD * shooters.size()
	var per_shot := MemoryBoard.DAMAGE_PER_MATCH / float(shots)
	await _wait(0.25)
	for s in SHOTS_PER_BIRD:
		for bird in shooters:
			if my_game != game_id:
				return
			bird.fire()
			_fire_bullet(bird.muzzle_global(), per_shot)
			await _wait(0.09)
	await _wait(0.35)  # Let the last bullets land.


func _fire_bullet(from: Vector2, damage: float) -> void:
	var bullet := ColorRect.new()
	bullet.color = Sprites.BULLET
	bullet.size = Vector2(3, 1) * Sprites.PX
	bullet.mouse_filter = MOUSE_FILTER_IGNORE
	fx_layer.add_child(bullet)
	bullet.global_position = from
	var target := snake.global_position + snake.size * Vector2(rng.randf_range(0.3, 0.85), rng.randf_range(0.15, 0.6))
	var t := bullet.create_tween()
	t.tween_property(bullet, "global_position", target, 0.22)
	t.tween_callback(func():
		bullet.queue_free()
		snake.hit()
		hp_bar.value = maxf(hp_bar.value - damage, board.boss_hp)
		hp_label.text = "HP %d / %d" % [ceili(hp_bar.value), board.boss_max_hp])


func _win() -> void:
	if level < LEVELS.size() - 1:
		_show_end("Level %d complete!" % (level + 1), "Next level", start_level.bind(level + 1))
	else:
		_show_end("You beat every level!", "Play again", start_level.bind(0))


func _lose() -> void:
	var my_game := game_id
	var line := _pick_line(LOSE_LINES)
	_say(line)
	await _wait(1.5)
	if my_game == game_id:
		# The snake's line is repeated on the lose screen so there's time to read it.
		_show_end("You lose!", "Try Again", start_level.bind(level), "The snake: \"%s\"" % line)


# --- Helpers ---

func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _pick_line(lines: Array) -> String:
	return lines[rng.randi() % lines.size()]


## Shows a speech bubble. It stays until the player picks the next egg.
func _say(text: String) -> void:
	speech.text = text
	speech.modulate.a = 1.0


## Hides the speech box but keeps its space, so the layout doesn't jump.
func _hush() -> void:
	speech.modulate.a = 0.0


func _refresh() -> void:
	hp_bar.max_value = board.boss_max_hp
	hp_bar.value = board.boss_hp
	hp_label.text = "HP %d / %d" % [board.boss_hp, board.boss_max_hp]
	for k in pips.size():
		pips[k].texture = Sprites.pip(k < board.mistakes_left)


# --- UI building ---

## Pixel font and square, chunky boxes for every button.
func _build_theme() -> Theme:
	var t := Theme.new()
	var font: FontFile = load("res://fonts/PixelifySans-Regular.woff2")
	font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	font.hinting = TextServer.HINTING_NONE
	t.default_font = font
	t.default_font_size = 24
	var states := {"normal": TEXT, "hover": HIGHLIGHT, "pressed": HIGHLIGHT,
			"disabled": TEXT_DIM, "focus": Color(0, 0, 0, 0)}
	for state in states:
		var sb := StyleBoxFlat.new()
		sb.bg_color = BOX
		sb.border_color = states[state]
		sb.set_border_width_all(4)
		sb.draw_center = state != "focus"
		sb.set_content_margin_all(8)
		t.set_stylebox(state, "Button", sb)
	for c in ["font_color", "font_focus_color"]:
		t.set_color(c, "Button", TEXT)
	t.set_color("font_hover_color", "Button", HIGHLIGHT)
	t.set_color("font_pressed_color", "Button", HIGHLIGHT)
	t.set_color("font_disabled_color", "Button", TEXT_DIM)
	return t


func _label(text: String, font_size: int, color: Color = TEXT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	return l


func _small_button(text: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(110, 40)
	b.add_theme_font_size_override("font_size", 20)
	b.pressed.connect(action)
	return b


func _build_level_bar() -> Control:
	var margin := MarginContainer.new()
	for side in ["left", "right", "top"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 16)
	margin.add_child(bar)
	prev_button = _small_button("< Back", func(): start_level(level - 1))
	bar.add_child(prev_button)
	level_label = _label("", 26)
	level_label.size_flags_horizontal = SIZE_EXPAND_FILL
	bar.add_child(level_label)
	skip_button = _small_button("Skip >", func(): start_level(level + 1))
	bar.add_child(skip_button)
	return margin


func _build_boss_panel() -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)

	speech = _label("", 22)
	speech.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	speech.custom_minimum_size = Vector2(340, 92)
	speech.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	speech.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var bubble := StyleBoxFlat.new()
	bubble.bg_color = BOX
	bubble.border_color = TEXT
	bubble.set_border_width_all(4)
	bubble.set_content_margin_all(14)
	speech.add_theme_stylebox_override("normal", bubble)
	box.add_child(speech)

	snake = SnakeBoss.new()
	box.add_child(snake)

	# Status box: HP and mistakes, in an NES-style black panel.
	var status := PanelContainer.new()
	var status_style := StyleBoxFlat.new()
	status_style.bg_color = BOX
	status_style.border_color = TEXT
	status_style.set_border_width_all(4)
	status_style.set_content_margin_all(12)
	status.add_theme_stylebox_override("panel", status_style)
	box.add_child(status)
	var status_box := VBoxContainer.new()
	status_box.add_theme_constant_override("separation", 8)
	status.add_child(status_box)

	hp_bar = ProgressBar.new()
	hp_bar.custom_minimum_size = Vector2(310, 26)
	hp_bar.show_percentage = false
	var fill := StyleBoxFlat.new()
	fill.bg_color = Sprites.CART
	var back := StyleBoxFlat.new()
	back.bg_color = BOX
	back.border_color = Sprites.GREY_DARK
	back.set_border_width_all(2)
	hp_bar.add_theme_stylebox_override("fill", fill)
	hp_bar.add_theme_stylebox_override("background", back)
	status_box.add_child(hp_bar)
	hp_label = _label("", 22)
	hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_box.add_child(hp_label)

	var mistakes := HBoxContainer.new()
	mistakes.alignment = BoxContainer.ALIGNMENT_CENTER
	mistakes.add_theme_constant_override("separation", 8)
	mistakes.add_child(_label("Mistakes allowed:", 22))
	pips.clear()
	for k in MISTAKES_ALLOWED:
		var p := TextureRect.new()
		p.texture = Sprites.pip(true)
		p.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		p.custom_minimum_size = Vector2(6, 6) * Sprites.PX
		mistakes.add_child(p)
		pips.append(p)
	status_box.add_child(mistakes)
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

	end_title = _label("", 56, TEXT)
	end_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	end_title.add_theme_constant_override("outline_size", 12)
	end_title.add_theme_color_override("font_outline_color", BOX)
	box.add_child(end_title)

	end_quote = _label("", 26, TEXT)
	end_quote.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	end_quote.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	end_quote.custom_minimum_size.x = 760
	end_quote.add_theme_constant_override("outline_size", 8)
	end_quote.add_theme_color_override("font_outline_color", BOX)
	box.add_child(end_quote)

	end_button = Button.new()
	end_button.custom_minimum_size = Vector2(260, 64)
	end_button.size_flags_horizontal = SIZE_SHRINK_CENTER
	end_button.add_theme_font_size_override("font_size", 28)
	end_button.pressed.connect(func(): end_action.call())
	box.add_child(end_button)
	return dim


func _show_end(title: String, button_text: String, action: Callable, quote: String = "") -> void:
	end_title.text = title
	end_quote.text = quote
	end_quote.visible = quote != ""
	end_button.text = button_text
	end_action = action
	end_panel.visible = true
