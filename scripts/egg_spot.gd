class_name EggSpot
extends Control
## One spot on the board: a nest with an egg that hatches into a bird.
## Drawn with the placeholder pixel art from Sprites. Animations move in
## whole art pixels so the pixel grid stays crisp.

signal pressed(index: int)

const PX := Sprites.PX
const SIZE_PX := Vector2i(30, 32)  # Spot size in art pixels.
const NEST_AT := Vector2i(1, 22)
const EGG_AT := Vector2i(6, 2)
const BIRD_AT := Vector2i(2, 1)

var index := 0
var bird_id := 0
var hatched := false
var hovered := false
var blind := false  # Secretly blindfolded: the bird never shows its color.
var blind_known := false  # Opened at least once, so the blindfold now shows on the egg.

var shake_x := 0  # Animation offsets, in art pixels.
var lift_y := 0


func _ready() -> void:
	custom_minimum_size = Vector2(SIZE_PX * PX)
	mouse_default_cursor_shape = CURSOR_POINTING_HAND
	mouse_entered.connect(func():
		hovered = true
		queue_redraw())
	mouse_exited.connect(func():
		hovered = false
		queue_redraw())


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pressed.emit(index)
		accept_event()


func _set_offsets(x: int, y: int) -> void:
	shake_x = x
	lift_y = y
	queue_redraw()


## Egg shakes, then the bird pops out.
func hatch() -> void:
	var t := create_tween()
	for x in [-1, 1, -1, 1, 0]:
		t.tween_callback(_set_offsets.bind(x, 0))
		t.tween_interval(0.05)
	t.tween_callback(func():
		hatched = true
		if blind:
			blind_known = true
		_set_offsets(0, 2))
	t.tween_interval(0.06)
	t.tween_callback(_set_offsets.bind(0, 1))
	t.tween_interval(0.06)
	t.tween_callback(_set_offsets.bind(0, 0))
	await t.finished


## Bird hides back inside a whole egg.
func close() -> void:
	var t := create_tween()
	t.tween_callback(_set_offsets.bind(0, -1))
	t.tween_interval(0.06)
	t.tween_callback(func():
		hatched = false
		_set_offsets(0, 0))
	t.tween_interval(0.08)
	await t.finished


func set_matched() -> void:
	mouse_default_cursor_shape = CURSOR_ARROW
	blind = false  # A matched pair reveals its true color.
	queue_redraw()


func _draw() -> void:
	_blit(Sprites.nest(), NEST_AT)
	var offset := Vector2i(shake_x, -lift_y)
	if hatched:
		_blit(Sprites.bird(bird_id, blind), BIRD_AT + offset)
	else:
		if hovered and lift_y == 0:
			offset.y -= 1
		_blit(Sprites.egg(blind and blind_known), EGG_AT + offset)


func _blit(tex: Texture2D, at: Vector2i) -> void:
	draw_texture_rect(tex, Rect2(Vector2(at * PX), tex.get_size() * PX), false)
