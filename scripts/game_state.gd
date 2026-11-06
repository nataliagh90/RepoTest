extends Node
## Autoloaded as "Game". Holds the current run (player stats, floor, gold,
## upgrades), builds the shared UI theme and moves between scenes.

const MAX_DEPTH := 10
const SHOP_AFTER_DEPTHS := [3, 7]

const SCENE_MENU := "res://scenes/main_menu.tscn"
const SCENE_BATTLE := "res://scenes/battle.tscn"
const SCENE_REWARD := "res://scenes/reward.tscn"
const SCENE_SHOP := "res://scenes/shop.tscn"
const SCENE_END := "res://scenes/game_over.tscn"

var rng := RandomNumberGenerator.new()
var run_seed := 0

# Run progress
var depth := 1
var gold := 0
var upgrades: Array[String] = []
var run_won := false
var killed_by := ""
var last_reward := {}

# Player stats (upgrades add to these by name)
var max_hp := 30
var hp := 30
var sword_damage := 4
var block_gain := 3
var potion_heal := 4
var coin_gain := 3
var combo_bonus := 1
var peek_time := 1.5
var enemy_timer_bonus := 0
var thorns := 0
var lifesteal := 0

var ui_theme: Theme


func _ready() -> void:
	ui_theme = build_theme()
	new_run()


func new_run(seed_value: int = 0) -> void:
	if seed_value == 0:
		rng.randomize()
	else:
		rng.seed = seed_value
	run_seed = rng.seed
	depth = 1
	gold = 0
	upgrades.clear()
	run_won = false
	killed_by = ""
	last_reward = {}
	max_hp = 30
	hp = max_hp
	sword_damage = 4
	block_gain = 3
	potion_heal = 4
	coin_gain = 3
	combo_bonus = 1
	peek_time = 1.5
	enemy_timer_bonus = 0
	thorns = 0
	lifesteal = 0


# --- Run logic (no scene changes; the tests call these directly) ---

func is_boss_depth(d: int = depth) -> bool:
	return GameData.BOSSES.has(d)


func enemy_for_depth(d: int) -> Dictionary:
	if GameData.BOSSES.has(d):
		return GameData.BOSSES[d].duplicate(true)
	var tier := 1 if d < 5 else 2
	var pool: Array = GameData.ENEMIES.filter(func(e): return e["tier"] == tier)
	var e: Dictionary = pool[rng.randi() % pool.size()].duplicate(true)
	var first_floor_of_tier := 1 if tier == 1 else 6
	var hp_scale := 1.0 + 0.12 * (d - first_floor_of_tier)
	e["hp"] = int(round(e["hp"] * hp_scale))
	return e


## Gives the rewards for winning a battle and returns what was given.
func grant_victory(combat: Combat) -> Dictionary:
	var g := 6 + depth * 2
	if combat.enemy.get("boss", false):
		g += 15
	var heal_amount := mini(4, max_hp - hp)
	gold += g
	hp += heal_amount
	last_reward = {"enemy": combat.enemy["name"], "gold": g, "heal": heal_amount, "turns": combat.turns}
	return last_reward


func roll_upgrades(count: int) -> Array[Dictionary]:
	var pool: Array = GameData.UPGRADES.duplicate()
	var result: Array[Dictionary] = []
	while result.size() < count and not pool.is_empty():
		result.append(pool.pop_at(rng.randi() % pool.size()))
	return result


func apply_upgrade(u: Dictionary) -> void:
	var stat: String = u["stat"]
	set(stat, get(stat) + u["amount"])
	if stat == "max_hp":
		hp = mini(max_hp, hp + int(u["amount"]))
	upgrades.append(u["name"])


func heal(amount: int) -> void:
	hp = mini(max_hp, hp + amount)


func shop_comes_next() -> bool:
	return depth in SHOP_AFTER_DEPTHS


# --- Scene flow ---

func goto(path: String) -> void:
	get_tree().change_scene_to_file.call_deferred(path)


func start_new_run() -> void:
	new_run()
	goto(SCENE_BATTLE)


func on_battle_won(combat: Combat) -> void:
	grant_victory(combat)
	if depth >= MAX_DEPTH:
		run_won = true
		goto(SCENE_END)
	else:
		goto(SCENE_REWARD)


func on_battle_lost(combat: Combat) -> void:
	run_won = false
	killed_by = combat.enemy["name"]
	goto(SCENE_END)


func after_reward() -> void:
	if shop_comes_next():
		goto(SCENE_SHOP)
	else:
		next_floor()


func next_floor() -> void:
	depth += 1
	goto(SCENE_BATTLE)


# --- Shared look ---

func build_theme() -> Theme:
	var t := Theme.new()
	t.default_font_size = 20
	t.set_stylebox("normal", "Button", _box(Color("2b2340"), Color("6b5b95")))
	t.set_stylebox("hover", "Button", _box(Color("3a2f57"), Color("b9a5ef")))
	t.set_stylebox("pressed", "Button", _box(Color("1f1930"), Color("b9a5ef")))
	t.set_stylebox("disabled", "Button", _box(Color("1b1822"), Color("34303e")))
	var focus := _box(Color(0, 0, 0, 0), Color("e0d4ff"))
	focus.draw_center = false
	t.set_stylebox("focus", "Button", focus)
	t.set_color("font_color", "Button", Color("ece6ff"))
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_disabled_color", "Button", Color("6a6475"))
	t.set_stylebox("panel", "PanelContainer", _box(Color("1c1729"), Color("3d3357")))
	t.set_color("font_color", "Label", Color("ece6ff"))
	t.set_stylebox("background", "ProgressBar", _box(Color("0e0b14"), Color("3d3357"), 0))
	return t


func _box(bg: Color, border: Color, margin: int = 12) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = margin
	sb.content_margin_right = margin
	sb.content_margin_top = margin * 0.66
	sb.content_margin_bottom = margin * 0.66
	return sb


## Small helpers the scenes share for building UI in code.
func make_label(text: String, font_size: int = 20, color: Color = Color("ece6ff")) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	return l


func make_background(parent: Control) -> void:
	var bg := ColorRect.new()
	bg.color = Color("120e1a")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(bg)
