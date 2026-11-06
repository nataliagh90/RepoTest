class_name PixelCanvas
extends RefCounted
## A tiny low-resolution image you paint pixel by pixel, then turn into a
## texture. Shown scaled up with nearest-neighbour filtering, it looks like
## pixel art.

var img: Image
var w := 0
var h := 0


func _init(p_w: int, p_h: int) -> void:
	w = p_w
	h = p_h
	img = Image.create(w, h, false, Image.FORMAT_RGBA8)


func px(x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < w and y < h:
		img.set_pixel(x, y, c)


func get_px(x: int, y: int) -> Color:
	if x >= 0 and y >= 0 and x < w and y < h:
		return img.get_pixel(x, y)
	return Color(0, 0, 0, 0)


func is_filled(x: int, y: int) -> bool:
	return get_px(x, y).a > 0.0


func rect(x: int, y: int, rw: int, rh: int, c: Color) -> void:
	for yy in range(y, y + rh):
		for xx in range(x, x + rw):
			px(xx, yy, c)


## Fills pixels whose centre lies inside the ellipse. top_ry (if > 0) gives
## the upper half a different height, e.g. for an egg shape. Rows outside
## [min_y, max_y] are skipped, which is handy for half shapes.
func ellipse(cx: float, cy: float, rx: float, ry: float, c: Color, top_ry := -1.0,
		min_y := -9999, max_y := 9999) -> void:
	for y in range(maxi(0, min_y), mini(h, max_y + 1)):
		for x in w:
			var dx := (x + 0.5 - cx) / rx
			var r := top_ry if top_ry > 0.0 and y + 0.5 < cy else ry
			var dy := (y + 0.5 - cy) / r
			if dx * dx + dy * dy <= 1.0:
				img.set_pixel(x, y, c)


## Recolours only pixels that are already filled (to paint inside a shape).
func paint_inside(x: int, y: int, c: Color) -> void:
	if is_filled(x, y):
		px(x, y, c)


## Draws a 1-pixel outline around every filled area.
func outline(c: Color) -> void:
	var copy := img.duplicate()
	for y in h:
		for x in w:
			if copy.get_pixel(x, y).a > 0.0:
				continue
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var nx: int = x + d.x
				var ny: int = y + d.y
				if nx >= 0 and ny >= 0 and nx < w and ny < h and copy.get_pixel(nx, ny).a > 0.0:
					img.set_pixel(x, y, c)
					break


func texture() -> ImageTexture:
	return ImageTexture.create_from_image(img)
