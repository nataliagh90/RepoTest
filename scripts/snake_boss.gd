class_name SnakeBoss
extends Control
## The boss: a snake too lazy to crawl, riding a motorized cart.
## Placeholder pixel art from Sprites, animated a few frames per second.

const FPS := 8.0

var _time := 0.0
var _frame := 0


func _ready() -> void:
	var frames: Array = Sprites.snake_frames()
	custom_minimum_size = frames[0].get_size() * Sprites.PX
	mouse_filter = MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	_time += delta
	var f := int(_time * FPS) % Sprites.SNAKE_FRAMES
	if f != _frame:
		_frame = f
		queue_redraw()


func _draw() -> void:
	var tex: Texture2D = Sprites.snake_frames()[_frame]
	draw_texture_rect(tex, Rect2(Vector2.ZERO, tex.get_size() * Sprites.PX), false)
