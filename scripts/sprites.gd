class_name Sprites
extends RefCounted
## PLACEHOLDER PIXEL ART, generated in code (no image files).
## Style: NES-like. A limited palette, no outlines (shapes read through
## 3-tone shading), chunky pixels. Every sprite is painted at low resolution
## and shown scaled up by PX, so it can later be replaced by hand-drawn
## sprites of the same size.

const PX := 5  # Screen pixels per art pixel.

# --- Palette (picked from / close to the NES colour set) ---
const BLACK := Color("000000")
const WHITE := Color("fcfcfc")
const GREY_LIGHT := Color("bcbcbc")
const GREY := Color("7c7c7c")
const GREY_DARK := Color("404040")

const EGG := Color("fce0a8")
const EGG_LIGHT := Color("fcfcfc")
const EGG_SHADE := Color("e4b880")
const EGG_SPOTS := Color("c89058")
const NEST := Color("ac7c00")
const NEST_DARK := Color("503000")
const NEST_LIGHT := Color("e4a000")
const BEAK := Color("fca044")
const BEAK_DARK := Color("e45c10")
const BLINDFOLD := Color("000000")
const CLOUD := WHITE
const CLOUD_SHADE := Color("a4e4fc")

const BIRD_COLORS: Array[Color] = [
	Color("d82800"),  # red
	Color("3cbcfc"),  # light blue
	Color("f8b800"),  # yellow
	Color("00a800"),  # green
	Color("6844fc"),  # purple
	Color("fc7460"),  # salmon
	Color("f878f8"),  # pink
	Color("00e8d8"),  # cyan
	Color("b8f818"),  # lime
	Color("0058f8"),  # blue
	Color("a05000"),  # brown
	Color("fcfcfc"),  # white
]

const RIFLE_WOOD := Color("ac7c00")
const RIFLE_WOOD_DARK := Color("503000")
const RIFLE_METAL := Color("404040")
const RIFLE_SHINE := Color("bcbcbc")
const RIFLE_MAG := Color("e45c10")
const FLASH_OUTER := Color("fc7400")
const FLASH_INNER := Color("fcf0a0")
const BULLET := Color("fcd858")

const SNAKE := Color("00a800")
const SNAKE_LIGHT := Color("58d854")
const SNAKE_DARK := Color("005800")
const SNAKE_BELLY := Color("b8f8b8")
const CART := Color("d82800")
const CART_LIGHT := Color("f87858")
const CART_DARK := Color("881400")
const TONGUE := Color("f83800")

# Lair (background) colours: dark and low-contrast so the eggs pop.
const MORTAR := Color("140c14")
const BRICK := Color("3c1c20")
const BRICK_ALT := Color("4c2428")
const FLOOR := Color("2c2c34")
const FLOOR_LINE := Color("4c4c58")
const OIL := Color("18181e")

static var _cache := {}


static func _cached(key: String, build: Callable) -> Variant:
	if not _cache.has(key):
		_cache[key] = build.call()
	return _cache[key]


# --- Nest: 28 x 9 ---

static func nest() -> ImageTexture:
	return _cached("nest", func():
		var c := PixelCanvas.new(28, 9)
		c.shaded_ellipse(14, 4.5, 13.5, 4.2, NEST, NEST_DARK, NEST_LIGHT)
		for y in c.h:
			for x in c.w:
				if (x + 2 * y) % 5 == 0:
					c.paint_inside(x, y, NEST_DARK)
				elif (x * 3 + y) % 11 == 0 and y < 4:
					c.paint_inside(x, y, NEST_LIGHT)
		return c.texture())


# --- Egg: 18 x 23 ---

static func egg(blindfolded: bool = false) -> ImageTexture:
	return _cached("egg_%s" % blindfolded, func():
		var c := PixelCanvas.new(18, 23)
		c.shaded_ellipse(8.5, 13.5, 7, 8, EGG, EGG_SHADE, EGG_LIGHT, 11)
		for p in [Vector2i(6, 8), Vector2i(10, 11), Vector2i(5, 15), Vector2i(9, 17), Vector2i(7, 12)]:
			c.paint_inside(p.x, p.y, EGG_SPOTS)
		if blindfolded:
			for y in range(10, 13):
				for x in c.w:
					c.paint_inside(x, y, BLINDFOLD)
			# The knot sticking out on the right
			for p in [Vector2i(16, 9), Vector2i(17, 8), Vector2i(16, 12), Vector2i(17, 13)]:
				c.px(p.x, p.y, BLINDFOLD)
		return c.texture())


# --- Hatched bird in its shell: 28 x 26 ---
# A blind egg hatches a "?" cloud instead of a bird, so its color stays secret.
# A matched bird is "armed": it holds an AK-47 pointing right, at the snake.

const MUZZLE := Vector2i(27, 14)  # Where the barrel ends, in bird-sprite pixels.


static func bird(bird_id: int, blind: bool = false, armed: bool = false) -> ImageTexture:
	var key := "bird_blind" if blind else "bird_%d_%s" % [bird_id, armed]
	return _cached(key, func():
		var c := PixelCanvas.new(28, 26)
		if blind:
			_paint_cloud(c)
		else:
			_paint_bird(c, BIRD_COLORS[bird_id % BIRD_COLORS.size()])
		_paint_bottom_shell(c)
		if armed and not blind:
			_paint_rifle(c)
		return c.texture())


static func _paint_bird(c: PixelCanvas, col: Color) -> void:
	var dark := col.darkened(0.35)
	var light := col.lightened(0.4)
	# Tuft
	for p in [Vector2i(10, 4), Vector2i(12, 3), Vector2i(13, 4), Vector2i(15, 4), Vector2i(12, 4)]:
		c.px(p.x, p.y, dark)
	# Body with shading, belly, wing
	c.shaded_ellipse(13, 12.5, 7.5, 7.5, col, dark, light)
	c.ellipse(13, 15.5, 4.5, 2.8, col.lightened(0.55))
	c.ellipse(8, 13.5, 2.5, 3.5, dark)
	# Big silly eye
	c.ellipse(16, 10, 2.6, 2.6, WHITE)
	c.rect(16, 9, 2, 2, BLACK)
	# Beak
	c.rect(20, 11, 3, 1, BEAK)
	c.rect(20, 12, 4, 1, BEAK)
	c.rect(20, 13, 2, 1, BEAK_DARK)
	# Shell hat
	c.shaded_ellipse(14, 6, 5.5, 3.5, EGG, EGG_SHADE, EGG_LIGHT, -1.0, 0, 5)


static func _paint_cloud(c: PixelCanvas) -> void:
	# Puffy cloud made of overlapping circles, shaded along the bottom.
	for puff in [Vector3(7, 13, 4.5), Vector3(11, 8.5, 5), Vector3(17, 9, 4.5), Vector3(20, 13, 4), Vector3(13.5, 14, 6)]:
		c.ellipse(puff.x, puff.y, puff.z, puff.z, CLOUD)
	for y in range(13, 20):
		for x in c.w:
			if c.is_filled(x, y) and not c.is_filled(x, y + 2):
				c.px(x, y, CLOUD_SHADE)
	# A big "?" in the middle
	var q := [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 1), Vector2i(3, 2),
			Vector2i(2, 3), Vector2i(1, 4), Vector2i(1, 5), Vector2i(1, 7)]
	for p in q:
		c.px(11 + p.x, 6 + p.y, BLACK)


static func _paint_bottom_shell(c: PixelCanvas) -> void:
	# Bottom half of the shell with a zigzag top edge. The rim is the shade
	# colour, so the shell reads without an outline.
	for x in range(4, 23):
		var top := 17 + (1 if int(x / 2.0) % 2 == 1 else 0)
		for y in range(top, 25):
			var dx := (x + 0.5 - 13.0) / 9.0
			var dy := (y + 0.5 - 17.0) / 7.5
			if dx * dx + dy * dy > 1.0:
				continue
			var col := EGG
			if y == top or dx > 0.55 or dy > 0.8:
				col = EGG_SHADE
			elif dx < -0.6:
				col = EGG_LIGHT
			c.px(x, y, col)


static func _paint_rifle(c: PixelCanvas) -> void:
	c.rect(3, 15, 5, 2, RIFLE_WOOD)  # Stock
	c.rect(3, 16, 5, 1, RIFLE_WOOD_DARK)
	c.rect(8, 14, 8, 3, RIFLE_METAL)  # Body
	c.rect(8, 14, 8, 1, RIFLE_SHINE)
	c.rect(15, 14, 4, 2, RIFLE_WOOD)  # Handguard
	c.rect(19, 14, 8, 1, RIFLE_METAL)  # Barrel
	c.rect(19, 13, 5, 1, RIFLE_METAL)  # Gas tube
	c.px(25, 13, RIFLE_METAL)  # Front sight
	c.px(9, 17, RIFLE_METAL)  # Grip
	c.px(9, 18, RIFLE_METAL)
	# Curved magazine
	for p in [Vector2i(12, 17), Vector2i(13, 17), Vector2i(12, 18), Vector2i(13, 18),
			Vector2i(13, 19), Vector2i(14, 19), Vector2i(14, 20), Vector2i(15, 20)]:
		c.px(p.x, p.y, RIFLE_MAG)


static func muzzle_flash() -> ImageTexture:
	return _cached("flash", func():
		var c := PixelCanvas.new(5, 5)
		for p in [Vector2i(2, 0), Vector2i(0, 2), Vector2i(4, 2), Vector2i(2, 4),
				Vector2i(1, 1), Vector2i(3, 1), Vector2i(1, 3), Vector2i(3, 3)]:
			c.px(p.x, p.y, FLASH_OUTER)
		c.rect(1, 2, 3, 1, FLASH_INNER)
		c.rect(2, 1, 1, 3, FLASH_INNER)
		return c.texture())


# --- Motorized snake: 70 x 52, animated ---

const SNAKE_FRAMES := 8


static func snake_frames() -> Array:
	return _cached("snake", func():
		var frames := []
		for f in SNAKE_FRAMES:
			frames.append(_snake_frame(f))
		return frames)


static func _snake_frame(f: int) -> ImageTexture:
	var c := PixelCanvas.new(70, 52)
	var bob := f % 2  # Engine rumble: the snake and cart jiggle by one pixel.

	# Exhaust puffs (behind everything)
	for k in 3:
		var t := fmod(f / float(SNAKE_FRAMES) + k / 3.0, 1.0)
		var r := 1.0 + 2.0 * t
		c.ellipse(4.0 - 4.0 * t, 33.0 - 6.0 * t, r, r, Color(GREY_LIGHT, 1.0 - 0.7 * t))

	# Coiled body: alternating light/dark bands
	for k in 9:
		var x := 14.0 + k * 5.0
		var y := 29.0 + bob + roundf(sin(k * 0.9 + f * TAU / SNAKE_FRAMES) * 1.0)
		if k % 2 == 0:
			c.shaded_ellipse(x, y, 4.0, 4.0, SNAKE, SNAKE_DARK, SNAKE_LIGHT)
		else:
			c.shaded_ellipse(x, y, 4.0, 4.0, SNAKE_DARK, SNAKE_DARK.darkened(0.3), SNAKE)
	# Neck
	for p in [Vector2(56, 24), Vector2(58.5, 19.5), Vector2(59.5, 15)]:
		c.shaded_ellipse(p.x, p.y + bob, 3.5, 3.5, SNAKE, SNAKE_DARK, SNAKE_LIGHT)
	# Head
	var hy := 9.0 + bob
	c.shaded_ellipse(58, hy, 9.5, 6.5, SNAKE_LIGHT, SNAKE, WHITE.lerp(SNAKE_LIGHT, 0.6))
	c.ellipse(58, hy + 3.5, 6.0, 2.2, SNAKE_BELLY)
	# Smug half-closed eyes: white bottom half, heavy black lid on top
	for ex in [53, 61]:
		c.rect(ex, int(hy) - 1, 3, 2, WHITE)
		c.px(ex + 1, int(hy), BLACK)
		c.rect(ex - 1, int(hy) - 2, 5, 1, BLACK)
	# Flicking tongue on some frames
	if f in [2, 3]:
		var ty := int(hy) + 2
		c.rect(44, ty, 5, 1, TONGUE)
		c.px(43, ty - 1, TONGUE)
		c.px(43, ty + 1, TONGUE)

	# Cart
	c.rect(10, 34 + bob, 52, 6, CART)
	c.rect(10, 34 + bob, 52, 1, CART_LIGHT)
	c.rect(10, 39 + bob, 52, 1, CART_DARK)
	c.rect(6, 36 + bob, 4, 2, GREY)  # Exhaust pipe
	c.px(6, 36 + bob, GREY_LIGHT)
	# Wheels with a spinning spoke
	for wx in [19, 36, 53]:
		c.ellipse(wx, 44, 4.5, 4.5, BLACK)
		c.ellipse(wx, 44, 2.2, 2.2, GREY_DARK)
		c.px(wx, 44, GREY_LIGHT)
		var a := f * TAU / SNAKE_FRAMES
		c.px(wx + roundi(cos(a) * 3.2), 44 + roundi(sin(a) * 3.2), GREY)
		c.px(wx + roundi(cos(a + PI) * 3.2), 44 + roundi(sin(a + PI) * 3.2), GREY)
	return c.texture()


# --- The snake's lair: full-screen background, 256 x 144 ---
# A biker's garage: brick wall, string lights, a painted winged-wheel emblem,
# a parked chopper, a stack of tires and oil stains on the floor. (Generic,
# no real brand.)

const LAIR_SIZE := Vector2i(256, 144)
const LAIR_FLOOR_Y := 122


static func lair() -> ImageTexture:
	return _cached("lair", func():
		var c := PixelCanvas.new(LAIR_SIZE.x, LAIR_SIZE.y)
		_paint_bricks(c)
		_paint_floor(c)
		_paint_string_lights(c)
		_paint_emblem(c, 128, 15)
		_paint_tires(c, 4, LAIR_FLOOR_Y + 1)
		_paint_chopper(c, 186, c.h - 2)
		return c.texture())


static func _paint_bricks(c: PixelCanvas) -> void:
	c.rect(0, 0, c.w, LAIR_FLOOR_Y, MORTAR)
	for row in range(0, int(LAIR_FLOOR_Y / 5.0) + 1):
		var y := row * 5
		var shift := 0 if row % 2 == 0 else 6
		for bx in range(-12, c.w, 12):
			var col := BRICK if (int(bx / 12.0) + row) % 3 != 0 else BRICK_ALT
			c.rect(bx + shift + 1, y + 1, 11, 4, col)


static func _paint_floor(c: PixelCanvas) -> void:
	c.rect(0, LAIR_FLOOR_Y, c.w, c.h - LAIR_FLOOR_Y, FLOOR)
	c.rect(0, LAIR_FLOOR_Y, c.w, 1, FLOOR_LINE)
	for spot in [Vector3(60, 134, 9), Vector3(150, 139, 12), Vector3(110, 129, 5)]:
		c.ellipse(spot.x, spot.y, spot.z, spot.z * 0.3, OIL)


static func _paint_string_lights(c: PixelCanvas) -> void:
	var bulbs := [Color("f8b800"), Color("f83800"), Color("00a800"), Color("3cbcfc")]
	for x in c.w:
		var y := 4 + roundi(sin(x * TAU / 64.0) * 2.0)
		c.px(x, y, BLACK)
		if x % 16 == 8:
			var col: Color = bulbs[int(x / 16.0) % bulbs.size()]
			c.rect(x - 1, y + 1, 2, 2, col)
			c.px(x - 1, y + 1, col.lightened(0.5))


## A painted wheel with wings, the classic biker-garage wall art.
static func _paint_emblem(c: PixelCanvas, cx: int, cy: int) -> void:
	var paint := Color("881400")
	var paint_light := Color("d82800")
	# Wings: stacked feathers getting shorter towards the bottom.
	for k in 4:
		var length := 22 - k * 4
		var y := cy - 3 + k * 2
		c.rect(cx - 7 - length, y, length, 1, paint_light if k % 2 == 0 else paint)
		c.rect(cx + 7, y, length, 1, paint_light if k % 2 == 0 else paint)
	# Wheel
	c.ellipse(cx, cy, 7, 7, paint)
	c.ellipse(cx, cy, 5, 5, MORTAR)
	c.ellipse(cx, cy, 1.5, 1.5, paint_light)
	for a in [0.0, PI / 2, PI / 4, 3 * PI / 4]:
		c.line(cx + roundi(cos(a) * 5), cy + roundi(sin(a) * 5),
				cx - roundi(cos(a) * 5), cy - roundi(sin(a) * 5), paint)


static func _paint_tires(c: PixelCanvas, x: int, floor_y: int) -> void:
	for k in 3:
		var y := floor_y - 3 - k * 5
		c.rect(x, y, 14, 5, BLACK)
		c.rect(x + 1, y + 1, 12, 1, GREY_DARK)
		c.rect(x + 5, y + 2, 4, 1, GREY_DARK)


static func _paint_chopper(c: PixelCanvas, x: int, ground: int) -> void:
	var chrome := GREY_LIGHT
	# Wheels
	for wx in [x + 8, x + 56]:
		c.ellipse(wx, ground - 7, 7, 7, BLACK)
		c.ellipse(wx, ground - 7, 4, 4, GREY_DARK)
		c.ellipse(wx, ground - 7, 1.5, 1.5, chrome)
	# Long front fork and handlebars
	c.line(x + 56, ground - 7, x + 44, ground - 26, chrome)
	c.line(x + 55, ground - 7, x + 43, ground - 26, chrome)
	c.line(x + 43, ground - 26, x + 40, ground - 30, chrome)
	c.rect(x + 38, ground - 31, 4, 1, chrome)
	# Frame
	c.line(x + 8, ground - 7, x + 28, ground - 12, GREY_DARK)
	c.line(x + 28, ground - 12, x + 44, ground - 22, GREY_DARK)
	c.line(x + 18, ground - 18, x + 44, ground - 23, GREY_DARK)
	# Engine
	c.rect(x + 22, ground - 16, 10, 6, GREY)
	c.rect(x + 22, ground - 16, 10, 1, chrome)
	c.rect(x + 24, ground - 20, 2, 4, GREY)
	c.rect(x + 28, ground - 20, 2, 4, GREY)
	# Exhaust pipes
	c.rect(x + 2, ground - 9, 24, 1, chrome)
	c.rect(x + 2, ground - 11, 22, 1, chrome)
	# Teardrop tank with flames
	c.shaded_ellipse(x + 34, ground - 23, 8, 3.5, CART, CART_DARK, CART_LIGHT)
	for p in [Vector2i(29, -23), Vector2i(30, -24), Vector2i(31, -23), Vector2i(32, -22),
			Vector2i(33, -24), Vector2i(34, -23)]:
		c.px(x + p.x, ground + p.y, Color("f8b800"))
	# Seat and sissy bar
	c.rect(x + 18, ground - 22, 9, 2, BLACK)
	c.line(x + 14, ground - 20, x + 12, ground - 30, chrome)


# --- UI bits ---

static func pip(on: bool) -> ImageTexture:
	return _cached("pip_%s" % on, func():
		var c := PixelCanvas.new(6, 6)
		if on:
			c.rect(0, 0, 6, 6, CART)
			c.rect(0, 0, 6, 1, CART_LIGHT)
			c.rect(0, 0, 1, 6, CART_LIGHT)
			c.rect(0, 5, 6, 1, CART_DARK)
			c.rect(5, 0, 1, 6, CART_DARK)
		else:
			c.rect(0, 0, 6, 6, GREY_DARK)
		return c.texture())
