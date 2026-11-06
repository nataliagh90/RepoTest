class_name EggSpot
extends Control
## One spot on the board: a nest with an egg that hatches into a bird.
## PLACEHOLDER ART: everything is drawn with simple shapes so it can be
## swapped for real sprites later.

signal pressed(index: int)

const BIRD_COLORS: Array[Color] = [
	Color("ef5b5b"),  # red
	Color("4d9de0"),  # blue
	Color("ffd23f"),  # yellow
	Color("3bb273"),  # green
	Color("9b5de5"),  # purple
	Color("ff8c42"),  # orange
	Color("f15bb5"),  # pink
	Color("00bbbf"),  # teal
]

const OUTLINE := Color("2b1d2e")
const EGG := Color("fff4dc")
const EGG_SPOTS := Color("e3cfa6")
const NEST := Color("b5793f")
const NEST_DARK := Color("7d4f26")
const OUTLINE_W := 4.0

var index := 0
var bird_id := 0
var hatched := false
var hovered := false


func _ready() -> void:
	custom_minimum_size = Vector2(150, 160)
	mouse_default_cursor_shape = CURSOR_POINTING_HAND
	mouse_entered.connect(func():
		hovered = true
		queue_redraw())
	mouse_exited.connect(func():
		hovered = false
		queue_redraw())
	resized.connect(func(): pivot_offset = Vector2(size.x / 2, size.y * 0.8))


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pressed.emit(index)
		accept_event()


## Egg wobbles, then the bird pops out.
func hatch() -> void:
	var t := create_tween()
	for angle in [-0.12, 0.12, -0.08, 0.0]:
		t.tween_property(self, "rotation", angle, 0.05)
	t.tween_callback(func():
		hatched = true
		queue_redraw())
	t.tween_property(self, "scale", Vector2(1.1, 0.92), 0.06)
	t.tween_property(self, "scale", Vector2(0.95, 1.08), 0.08)
	t.tween_property(self, "scale", Vector2.ONE, 0.08)
	await t.finished


## Bird hides back inside a whole egg.
func close() -> void:
	var t := create_tween()
	t.tween_property(self, "scale", Vector2(1.08, 0.9), 0.07)
	t.tween_callback(func():
		hatched = false
		queue_redraw())
	t.tween_property(self, "scale", Vector2.ONE, 0.1)
	await t.finished


func set_matched() -> void:
	mouse_default_cursor_shape = CURSOR_ARROW


# --- Drawing ---

func _draw() -> void:
	var s := size.x / 150.0
	var base := Vector2(size.x / 2, size.y * 0.8)
	_draw_nest(base, s)
	if hatched:
		_draw_bird(base + Vector2(0, -42) * s, s, BIRD_COLORS[bird_id % BIRD_COLORS.size()])
		_draw_bottom_shell(base + Vector2(0, -22) * s, s)
	else:
		_draw_egg(base + Vector2(0, -50) * s, s)


func _ellipse(center: Vector2, radius: Vector2, top_scale: float = 1.0, points: int = 40) -> PackedVector2Array:
	var arr := PackedVector2Array()
	for k in points:
		var a := TAU * k / points
		var p := Vector2(cos(a) * radius.x, sin(a) * radius.y)
		if p.y < 0:
			p.y *= top_scale  # Taller top half gives an egg shape.
		arr.append(center + p)
	return arr


func _shape(points: PackedVector2Array, fill: Color) -> void:
	draw_colored_polygon(points, fill)
	var closed := points.duplicate()
	closed.append(points[0])
	draw_polyline(closed, OUTLINE, OUTLINE_W, true)


func _draw_nest(base: Vector2, s: float) -> void:
	_shape(_ellipse(base, Vector2(62, 22) * s), NEST)
	for k in 5:
		var x := (-40 + k * 20) * s
		draw_line(base + Vector2(x - 10 * s, -6 * s), base + Vector2(x + 10 * s, 6 * s), NEST_DARK, 3 * s)


func _draw_egg(c: Vector2, s: float) -> void:
	var r := Vector2(38, 44) * s
	if hovered:
		r *= 1.05
	_shape(_ellipse(c, r, 1.25), EGG)
	for spot in [Vector2(-14, -20), Vector2(12, -4), Vector2(-6, 16), Vector2(16, 22)]:
		draw_circle(c + spot * s, 5 * s, EGG_SPOTS)


func _draw_bottom_shell(c: Vector2, s: float) -> void:
	# Lower half of an egg with a zigzag crack along the top.
	var pts := PackedVector2Array()
	var w := 40.0
	var zig := 8  # Even, so both ends of the zigzag sit at the top.
	for k in zig + 1:
		var x := -w + 2 * w * k / zig
		pts.append(c + Vector2(x, -8 if k % 2 == 0 else 4) * s)
	for k in range(0, 21):
		var a := PI * k / 20.0
		pts.append(c + Vector2(cos(a) * w, sin(a) * 30) * s)
	_shape(pts, EGG)


func _draw_bird(c: Vector2, s: float, col: Color) -> void:
	# Tuft
	for dx in [-8, 0, 8]:
		_shape(PackedVector2Array([c + Vector2(dx - 5, -34) * s, c + Vector2(dx + 5, -34) * s,
				c + Vector2(dx + dx * 0.6, -50) * s]), col.darkened(0.2))
	# Body
	_shape(_ellipse(c, Vector2(36, 36) * s), col)
	# Belly
	draw_colored_polygon(_ellipse(c + Vector2(0, 14) * s, Vector2(22, 16) * s), col.lightened(0.45))
	# Wing
	_shape(_ellipse(c + Vector2(-26, 6) * s, Vector2(12, 18) * s), col.darkened(0.15))
	# Big silly eye
	_shape(_ellipse(c + Vector2(8, -10) * s, Vector2(13, 13) * s), Color.WHITE)
	draw_circle(c + Vector2(11, -8) * s, 6 * s, OUTLINE)
	# Beak
	_shape(PackedVector2Array([c + Vector2(24, -2) * s, c + Vector2(44, 4) * s,
			c + Vector2(24, 10) * s]), Color("ffb627"))
	# Top half of the shell, worn like a hat
	var hat := PackedVector2Array()
	for k in range(0, 21):
		var a := PI + PI * k / 20.0
		hat.append(c + Vector2(-6, -36) * s + Vector2(cos(a) * 26, sin(a) * 22) * s)
	_shape(hat, EGG)
