class_name SnakeBoss
extends Control
## The boss: a snake too lazy to crawl, riding a motorized cart.
## Placeholder pixel art from Sprites, animated a few frames per second.

const FPS := 8.0

var _time := 0.0
var _frame := 0
var _shake := 0  # Art pixels, while being hit.


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


## Flash red and jolt when a bullet lands.
func hit() -> void:
	modulate = Color(1.0, 0.35, 0.35)
	_shake = 1 if _shake <= 0 else -1
	queue_redraw()
	var t := create_tween()
	t.tween_property(self, "modulate", Color.WHITE, 0.15)
	t.tween_callback(func():
		_shake = 0
		queue_redraw())


func _draw() -> void:
	var tex: Texture2D = Sprites.snake_frames()[_frame]
	var at := Vector2(_shake * Sprites.PX, 0)
	draw_texture_rect(tex, Rect2(at, tex.get_size() * Sprites.PX), false)
