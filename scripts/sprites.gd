class_name Sprites
extends RefCounted
## PLACEHOLDER PIXEL ART, generated in code (no image files).
## Every sprite is painted at low resolution and shown scaled up by PX, so it
## can later be replaced by hand-drawn sprites of the same size.

const PX := 5  # Screen pixels per art pixel.

const OUTLINE := Color("2b1d2e")
const EGG := Color("fff4dc")
const EGG_SHADE := Color("ecdcbc")
const EGG_SPOTS := Color("d9c393")
const NEST := Color("b5793f")
const NEST_DARK := Color("7d4f26")
const BEAK := Color("ffb627")
const BLINDFOLD := Color("3d2a4a")
const CLOUD := Color("ffffff")
const CLOUD_SHADE := Color("cfe0ee")

const BIRD_COLORS: Array[Color] = [
	Color("ef5b5b"),  # red
	Color("4d9de0"),  # blue
	Color("ffd23f"),  # yellow
	Color("3bb273"),  # green
	Color("9b5de5"),  # purple
	Color("ff8c42"),  # orange
	Color("f15bb5"),  # pink
	Color("00bbbf"),  # teal
	Color("b8f818"),  # lime
	Color("2038ec"),  # dark blue
	Color("a0522d"),  # brown
	Color("fcfcfc"),  # white
]

const RIFLE_WOOD := Color("9c5a2a")
const RIFLE_METAL := Color("3c3c48")
const RIFLE_BARREL := Color("7c7c88")
const RIFLE_MAG := Color("b5541c")
const FLASH_OUTER := Color("fc7400")
const FLASH_INNER := Color("fcf0a0")
const BULLET := Color("fcd858")

const SNAKE := Color("7bc950")
const SNAKE_DARK := Color("4f9a2f")
const SNAKE_BELLY := Color("e9f5a3")
const CART := Color("e2483d")
const CART_DARK := Color("a8302a")
const WHEEL := Color("3a3a48")
const WHEEL_LIGHT := Color("9a9aa8")
const TONGUE := Color("e2483d")

static var _cache := {}


static func _cached(key: String, build: Callable) -> Variant:
	if not _cache.has(key):
		_cache[key] = build.call()
	return _cache[key]


# --- Nest: 28 x 9 ---

static func nest() -> ImageTexture:
	return _cached("nest", func():
		var c := PixelCanvas.new(28, 9)
		c.ellipse(14, 4.5, 13, 3.6, NEST)
		for y in c.h:
			for x in c.w:
				if (x + 2 * y) % 5 == 0:
					c.paint_inside(x, y, NEST_DARK)
		c.outline(OUTLINE)
		return c.texture())


# --- Egg: 18 x 23 ---

static func egg(blindfolded: bool = false) -> ImageTexture:
	return _cached("egg_%s" % blindfolded, func():
		var c := PixelCanvas.new(18, 23)
		c.ellipse(8, 13.5, 6.5, 7.5, EGG, 10.5)
		# Soft shade on the right side
		for y in c.h:
			for x in range(11, 15):
				if c.is_filled(x, y) and c.is_filled(x - 1, y) and not c.is_filled(x + 1, y):
					c.px(x, y, EGG_SHADE)
		for p in [Vector2i(6, 8), Vector2i(10, 11), Vector2i(5, 15), Vector2i(9, 17), Vector2i(7, 12)]:
			c.paint_inside(p.x, p.y, EGG_SPOTS)
		if blindfolded:
			for y in range(10, 13):
				for x in c.w:
					c.paint_inside(x, y, BLINDFOLD)
			# The knot sticking out on the right
			for p in [Vector2i(15, 10), Vector2i(16, 9), Vector2i(15, 12), Vector2i(16, 13), Vector2i(17, 13)]:
				c.px(p.x, p.y, BLINDFOLD)
		c.outline(OUTLINE)
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
		c.outline(OUTLINE)
		return c.texture())


static func _paint_rifle(c: PixelCanvas) -> void:
	c.rect(4, 15, 4, 2, RIFLE_WOOD)  # Stock
	c.rect(8, 14, 9, 2, RIFLE_METAL)  # Body
	c.rect(14, 14, 3, 1, RIFLE_WOOD)  # Handguard
	c.rect(17, 14, 10, 1, RIFLE_BARREL)  # Barrel
	c.px(25, 13, RIFLE_METAL)  # Front sight
	c.px(9, 16, RIFLE_METAL)  # Grip
	c.px(9, 17, RIFLE_METAL)
	# Curved magazine
	for p in [Vector2i(12, 16), Vector2i(13, 16), Vector2i(12, 17), Vector2i(13, 17),
			Vector2i(13, 18), Vector2i(14, 18), Vector2i(14, 19)]:
		c.px(p.x, p.y, RIFLE_MAG)
	# A wing tip gripping the gun
	c.px(10, 15, Color.WHITE.darkened(0.1))


static func muzzle_flash() -> ImageTexture:
	return _cached("flash", func():
		var c := PixelCanvas.new(5, 5)
		for p in [Vector2i(2, 0), Vector2i(0, 2), Vector2i(4, 2), Vector2i(2, 4),
				Vector2i(1, 1), Vector2i(3, 1), Vector2i(1, 3), Vector2i(3, 3)]:
			c.px(p.x, p.y, FLASH_OUTER)
		c.rect(1, 2, 3, 1, FLASH_INNER)
		c.rect(2, 1, 1, 3, FLASH_INNER)
		return c.texture())


static func _paint_bird(c: PixelCanvas, col: Color) -> void:
	var dark := col.darkened(0.28)
	var light := col.lightened(0.45)
	# Tuft
	for p in [Vector2i(10, 4), Vector2i(12, 3), Vector2i(13, 4), Vector2i(15, 4)]:
		c.px(p.x, p.y, dark)
	# Body, belly, wing
	c.ellipse(13, 12.5, 7.5, 7.5, col)
	c.ellipse(13, 15.5, 4.5, 3.0, light)
	c.ellipse(8, 13.5, 2.5, 3.5, dark)
	# Big silly eye
	c.ellipse(16, 10, 2.6, 2.6, Color.WHITE)
	c.rect(16, 9, 2, 2, OUTLINE)
	# Beak
	c.rect(20, 11, 3, 1, BEAK)
	c.rect(20, 12, 4, 1, BEAK)
	c.rect(20, 13, 2, 1, BEAK)
	# Shell hat
	c.ellipse(14, 6, 5.5, 3.5, EGG, -1.0, 0, 5)


static func _paint_cloud(c: PixelCanvas) -> void:
	# Puffy cloud made of overlapping circles, shaded along the bottom.
	for puff in [Vector3(7, 13, 4.5), Vector3(11, 8.5, 5), Vector3(17, 9, 4.5), Vector3(20, 13, 4), Vector3(13.5, 14, 6)]:
		c.ellipse(puff.x, puff.y, puff.z, puff.z, CLOUD)
	for y in range(15, 20):
		for x in c.w:
			if c.is_filled(x, y) and not c.is_filled(x, y + 2):
				c.px(x, y, CLOUD_SHADE)
	# A big "?" in the middle
	var q := [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 1), Vector2i(3, 2),
			Vector2i(2, 3), Vector2i(1, 4), Vector2i(1, 5), Vector2i(1, 7)]
	for p in q:
		c.px(11 + p.x, 6 + p.y, OUTLINE)


static func _paint_bottom_shell(c: PixelCanvas) -> void:
	# Bottom half of the shell with a zigzag top edge.
	for x in range(4, 23):
		var top := 17 + (1 if int(x / 2.0) % 2 == 1 else 0)
		for y in range(top, 25):
			var dx := (x + 0.5 - 13.0) / 9.0
			var dy := (y + 0.5 - 17.0) / 7.5
			if dx * dx + dy * dy <= 1.0:
				c.px(x, y, OUTLINE if y == top else EGG)


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

	# Coiled body
	for k in 9:
		var x := 14.0 + k * 5.0
		var y := 29.0 + bob + roundf(sin(k * 0.9 + f * TAU / SNAKE_FRAMES) * 1.0)
		c.ellipse(x, y, 4.0, 4.0, SNAKE if k % 2 == 0 else SNAKE_DARK)
	# Neck
	for p in [Vector2(56, 24), Vector2(58.5, 19.5), Vector2(59.5, 15)]:
		c.ellipse(p.x, p.y + bob, 3.5, 3.5, SNAKE)
	# Head
	var hy := 9.0 + bob
	c.ellipse(58, hy, 9.5, 6.5, SNAKE)
	c.ellipse(58, hy + 3.5, 6.0, 2.2, SNAKE_BELLY)
	# Smug half-closed eyes: white bottom half, lid line on top
	for ex in [53, 61]:
		c.rect(ex, int(hy) - 1, 3, 2, Color.WHITE)
		c.px(ex + 1, int(hy), OUTLINE)
		c.rect(ex - 1, int(hy) - 2, 5, 1, OUTLINE)
	# Flicking tongue on some frames
	if f in [2, 3]:
		var ty := int(hy) + 2
		c.rect(44, ty, 5, 1, TONGUE)
		c.px(43, ty - 1, TONGUE)
		c.px(43, ty + 1, TONGUE)

	# Cart
	c.rect(10, 34 + bob, 52, 6, CART)
	c.rect(10, 39 + bob, 52, 1, CART_DARK)
	c.rect(6, 36 + bob, 4, 2, WHEEL)  # Exhaust pipe
	# Wheels with a spinning spoke
	for wx in [19, 36, 53]:
		c.ellipse(wx, 44, 4.5, 4.5, WHEEL)
		c.px(wx, 44, WHEEL_LIGHT)
		var a := f * TAU / SNAKE_FRAMES
		c.px(wx + roundi(cos(a) * 2.6), 44 + roundi(sin(a) * 2.6), WHEEL_LIGHT)
		c.px(wx + roundi(cos(a + PI) * 2.6), 44 + roundi(sin(a + PI) * 2.6), WHEEL_LIGHT)

	c.outline(OUTLINE)

	# Exhaust puffs (no outline, they're smoke)
	for k in 3:
		var t := fmod(f / float(SNAKE_FRAMES) + k / 3.0, 1.0)
		var r := 1.0 + 2.0 * t
		c.ellipse(4.0 - 4.0 * t, 33.0 - 6.0 * t, r, r, Color(0.88, 0.88, 0.88, 1.0 - 0.7 * t))
	return c.texture()


# --- UI bits ---

static func pip(on: bool) -> ImageTexture:
	return _cached("pip_%s" % on, func():
		var c := PixelCanvas.new(6, 6)
		c.rect(1, 1, 4, 4, CART if on else Color(OUTLINE, 0.25))
		if on:
			c.px(1, 1, CART.lightened(0.4))
			c.outline(OUTLINE)
		return c.texture())
