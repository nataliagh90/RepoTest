class_name SnakeBoss
extends Control
## The boss: a snake too lazy to crawl, riding a motorized cart.
## PLACEHOLDER ART drawn with shapes; replace with real sprites later.

const OUTLINE := Color("2b1d2e")
const SKIN := Color("7bc950")
const SKIN_DARK := Color("4f9a2f")
const BELLY := Color("e9f5a3")
const CART := Color("e2483d")
const WHEEL := Color("3a3a48")
const OUTLINE_W := 4.0

var _time := 0.0


func _ready() -> void:
	custom_minimum_size = Vector2(320, 260)
	mouse_filter = MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var s := size.x / 320.0
	var bob := sin(_time * 18.0) * 1.5  # Engine rumble.
	var base := Vector2(size.x / 2, size.y - 40 * s)

	# Exhaust puffs
	for k in 3:
		var t := fmod(_time * 0.8 + k / 3.0, 1.0)
		var p := base + Vector2(-140 + -30 * t, -40 - 25 * t) * s
		draw_circle(p, (6 + 10 * t) * s, Color(0.85, 0.85, 0.85, 1.0 - t))

	# Cart
	var cart := Rect2(base + Vector2(-120, -52 + bob) * s, Vector2(240, 34) * s)
	draw_rect(cart, CART)
	draw_rect(cart, OUTLINE, false, OUTLINE_W)
	draw_rect(Rect2(base + Vector2(-134, -44 + bob) * s, Vector2(16, 10) * s), WHEEL)  # Exhaust pipe

	# Wheels with spinning spokes
	for x in [-80, 0, 80]:
		var c := base + Vector2(x, -8) * s
		draw_circle(c, 22 * s, OUTLINE)
		draw_circle(c, 18 * s, WHEEL)
		for k in 3:
			var a := _time * 8.0 + k * TAU / 3.0
			draw_line(c, c + Vector2(cos(a), sin(a)) * 16 * s, Color("9a9aa8"), 3 * s)
		draw_circle(c, 5 * s, Color("cfcfd8"))

	# Coiled body sitting on the cart
	var body_y := base.y - 70 * s + bob * s
	for k in range(9):
		var x := -100 + k * 20
		var y := sin(k * 0.9 + _time * 2.0) * 6
		var c := Vector2(base.x + x * s, body_y + y * s)
		draw_circle(c, 21 * s, OUTLINE)
		draw_circle(c, 18 * s, SKIN if k % 2 == 0 else SKIN_DARK)

	# Neck rising up to the head
	var neck := [Vector2(80, -80), Vector2(92, -110), Vector2(96, -140)]
	for p in neck:
		var c: Vector2 = base + (p + Vector2(0, bob)) * s
		draw_circle(c, 19 * s, OUTLINE)
		draw_circle(c, 16 * s, SKIN)

	# Head
	var head := base + Vector2(90, -175 + bob) * s
	_ellipse(head, Vector2(44, 32) * s, SKIN)
	draw_colored_polygon(_ellipse_pts(head + Vector2(0, 14) * s, Vector2(30, 12) * s), BELLY)
	# Smug half-closed eyes
	for ex in [-16, 18]:
		var e := head + Vector2(ex, -8) * s
		_ellipse(e, Vector2(11, 11) * s, Color.WHITE)
		draw_circle(e + Vector2(3, 2) * s, 5 * s, OUTLINE)
		draw_rect(Rect2(e + Vector2(-13, -13) * s, Vector2(26, 11) * s), SKIN)  # Lazy eyelid
		draw_line(e + Vector2(-12, -2) * s, e + Vector2(12, -2) * s, OUTLINE, 3 * s)
	# Flicking forked tongue
	if fmod(_time, 2.0) < 0.35:
		var m := head + Vector2(-40, 12) * s
		draw_line(m, m + Vector2(-22, 0) * s, Color("e2483d"), 4 * s)
		draw_line(m + Vector2(-22, 0) * s, m + Vector2(-30, -6) * s, Color("e2483d"), 3 * s)
		draw_line(m + Vector2(-22, 0) * s, m + Vector2(-30, 6) * s, Color("e2483d"), 3 * s)


func _ellipse_pts(c: Vector2, r: Vector2) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for k in 32:
		var a := TAU * k / 32
		pts.append(c + Vector2(cos(a) * r.x, sin(a) * r.y))
	return pts


func _ellipse(c: Vector2, r: Vector2, fill: Color) -> void:
	var pts := _ellipse_pts(c, r)
	draw_colored_polygon(pts, fill)
	pts.append(pts[0])
	draw_polyline(pts, OUTLINE, OUTLINE_W, true)
