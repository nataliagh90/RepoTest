class_name CardView
extends Control
## One card on the board. Draws itself with shapes (no image assets needed)
## and animates flips. Game rules live in Combat; this is only the view.

signal pressed(index: int)

const BACK := Color("3a2f57")
const BACK_BORDER := Color("6b5b95")
const BACK_HOVER := Color("b9a5ef")
const FACE := Color(0.95, 0.92, 0.85)
const INK := Color(0.16, 0.12, 0.2)

var index := 0
var card_type := ""
var face_up := false
var matched := false
var hovered := false

var _face_box := StyleBoxFlat.new()
var _back_box := StyleBoxFlat.new()


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_STOP
	mouse_default_cursor_shape = CURSOR_POINTING_HAND
	for sb in [_face_box, _back_box]:
		sb.set_corner_radius_all(10)
		sb.set_border_width_all(4)
	_face_box.bg_color = FACE
	_back_box.bg_color = BACK
	mouse_entered.connect(_set_hover.bind(true))
	mouse_exited.connect(_set_hover.bind(false))
	resized.connect(func(): pivot_offset = size / 2)


func setup(p_index: int, p_type: String, card_size: Vector2) -> void:
	index = p_index
	card_type = p_type
	custom_minimum_size = card_size


func _set_hover(value: bool) -> void:
	hovered = value
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pressed.emit(index)
		accept_event()


func flip(up: bool, duration: float = 0.18) -> void:
	if face_up == up:
		return
	var t := create_tween()
	t.tween_property(self, "scale:x", 0.0, duration / 2).set_ease(Tween.EASE_IN)
	t.tween_callback(func():
		face_up = up
		queue_redraw())
	t.tween_property(self, "scale:x", 1.0, duration / 2).set_ease(Tween.EASE_OUT)
	await t.finished


func set_matched() -> void:
	matched = true
	mouse_default_cursor_shape = CURSOR_ARROW
	var t := create_tween()
	t.tween_property(self, "scale", Vector2(1.12, 1.12), 0.1)
	t.tween_property(self, "scale", Vector2.ONE, 0.12)
	t.tween_property(self, "modulate:a", 0.28, 0.3)


func wobble() -> void:
	var t := create_tween()
	for angle in [0.12, -0.12, 0.06, 0.0]:
		t.tween_property(self, "rotation", angle, 0.06)


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	var s := size.x / 100.0
	var font := get_theme_default_font()
	if face_up:
		var info: Dictionary = GameData.CARDS.get(card_type, {})
		var accent: Color = info.get("color", Color.WHITE)
		_face_box.border_color = accent
		draw_style_box(_face_box, rect)
		_draw_icon(card_type, Vector2(size.x / 2, size.y * 0.42), s, accent)
		draw_string(font, Vector2(0, size.y - 14 * s), info.get("name", ""),
				HORIZONTAL_ALIGNMENT_CENTER, size.x, int(17 * s), INK)
	else:
		_back_box.border_color = BACK_HOVER if hovered and not matched else BACK_BORDER
		draw_style_box(_back_box, rect)
		var c := size / 2
		var d := PackedVector2Array([c + Vector2(0, -30) * s, c + Vector2(22, 0) * s,
				c + Vector2(0, 30) * s, c + Vector2(-22, 0) * s])
		draw_colored_polygon(d, BACK_BORDER)
		draw_string(font, Vector2(0, c.y + 11 * s), "?", HORIZONTAL_ALIGNMENT_CENTER,
				size.x, int(32 * s), Color("ece6ff"))


func _poly(points: Array, c: Vector2, s: float, col: Color) -> void:
	var arr := PackedVector2Array()
	for p in points:
		arr.append(c + p * s)
	draw_colored_polygon(arr, col)


func _rect(from: Vector2, to: Vector2, c: Vector2, s: float, col: Color) -> void:
	draw_rect(Rect2(c + from * s, (to - from) * s), col)


func _draw_icon(t: String, c: Vector2, s: float, col: Color) -> void:
	var dark := col.darkened(0.35)
	match t:
		"sword":
			_poly([Vector2(0, -40), Vector2(7, -30), Vector2(7, 12), Vector2(-7, 12), Vector2(-7, -30)], c, s, col)
			_rect(Vector2(-1.5, -32), Vector2(1.5, 10), c, s, col.lightened(0.35))
			_rect(Vector2(-20, 12), Vector2(20, 19), c, s, dark)
			_rect(Vector2(-4, 19), Vector2(4, 34), c, s, Color("6b4a2b"))
			draw_circle(c + Vector2(0, 37) * s, 6 * s, dark)
		"bolt":
			_poly([Vector2(8, -38), Vector2(-16, 4), Vector2(-2, 4), Vector2(-10, 38),
					Vector2(18, -6), Vector2(3, -6), Vector2(14, -38)], c, s, col)
		"shield":
			_poly([Vector2(-26, -30), Vector2(26, -30), Vector2(26, 2), Vector2(0, 34), Vector2(-26, 2)], c, s, dark)
			_poly([Vector2(-19, -23), Vector2(19, -23), Vector2(19, 0), Vector2(0, 25), Vector2(-19, 0)], c, s, col)
			_rect(Vector2(-3, -23), Vector2(3, 25), c, s, dark)
		"potion":
			draw_circle(c + Vector2(0, 10) * s, 24 * s, dark)
			draw_circle(c + Vector2(0, 12) * s, 20 * s, col)
			_rect(Vector2(-7, -24), Vector2(7, -10), c, s, dark)
			_rect(Vector2(-10, -32), Vector2(10, -24), c, s, Color("8a6440"))
			draw_circle(c + Vector2(-8, 4) * s, 5 * s, col.lightened(0.5))
		"coin":
			draw_circle(c, 28 * s, dark)
			draw_circle(c, 23 * s, col)
			draw_circle(c, 15 * s, col.lightened(0.25))
			_rect(Vector2(-3, -12), Vector2(3, 12), c, s, dark)
		"skull":
			draw_circle(c + Vector2(0, -6) * s, 25 * s, Color(0.88, 0.86, 0.8))
			_rect(Vector2(-15, 10), Vector2(15, 28), c, s, Color(0.88, 0.86, 0.8))
			draw_circle(c + Vector2(-10, -6) * s, 7 * s, INK)
			draw_circle(c + Vector2(10, -6) * s, 7 * s, INK)
			_poly([Vector2(0, 3), Vector2(4, 10), Vector2(-4, 10)], c, s, INK)
			for x in [-8, 0, 8]:
				_rect(Vector2(x - 1, 18), Vector2(x + 1, 28), c, s, INK)
