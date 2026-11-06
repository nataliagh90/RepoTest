class_name Combat
extends RefCounted
## Rules for a single memory battle, with no nodes or UI.
##
## The battle scene renders this state and the test suite drives it directly.
## Each call to pick() returns a list of event dictionaries describing what
## happened, in order, so the UI can animate them one by one.

var player  # The Game autoload (or any object with the same stat properties).
var rng: RandomNumberGenerator
var enemy: Dictionary = {}
var cards: Array[Dictionary] = []  # {"type": String, "matched": bool}
var pending := -1  # Index of the first card flipped this turn, or -1.
var combo := 0
var block := 0
var turns := 0
var boards_dealt := 0
var finished := false
var won := false


func _init(p_player, p_enemy: Dictionary, p_rng: RandomNumberGenerator) -> void:
	player = p_player
	rng = p_rng
	enemy = p_enemy.duplicate(true)
	enemy["max_hp"] = enemy["hp"]
	enemy["timer_max"] = int(enemy["timer"]) + int(player.enemy_timer_bonus)
	enemy["timer"] = enemy["timer_max"]
	deal_board()


func has_trait(t: String) -> bool:
	return t in enemy.get("traits", [])


func pair_count() -> int:
	var d: int = player.depth
	if d <= 3:
		return 6
	if d <= 6:
		return 8
	return 10


func skull_damage() -> int:
	return 2 + int(player.depth / 4.0)


func deal_board() -> void:
	var types: Array[String] = ["sword", "sword"]  # Every board has some offence.
	var pairs := pair_count()
	while types.size() < pairs:
		types.append(_weighted_card())
	if has_trait("cursed"):
		types.append_array(["skull", "skull"])
	cards.clear()
	for t in types:
		cards.append({"type": t, "matched": false})
		cards.append({"type": t, "matched": false})
	_shuffle(cards)
	pending = -1
	boards_dealt += 1


func can_pick(i: int) -> bool:
	return not finished and i >= 0 and i < cards.size() and not cards[i]["matched"] and i != pending


func pick(i: int) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	if not can_pick(i):
		return events
	events.append({"type": "flip", "index": i, "card": cards[i]["type"]})
	if pending == -1:
		pending = i
		return events

	var a := pending
	pending = -1
	turns += 1
	var ta: String = cards[a]["type"]
	var tb: String = cards[i]["type"]
	if ta == tb:
		cards[a]["matched"] = true
		cards[i]["matched"] = true
		events.append({"type": "match", "a": a, "b": i, "card": ta, "combo": combo})
		_apply_card(ta, events)
		combo += 1
	else:
		combo = 0
		events.append({"type": "mismatch", "a": a, "b": i})
		if ta == "skull" or tb == "skull":
			_damage_player(skull_damage(), events, "curse")

	if not finished:
		_tick_enemy(events)
	if not finished and _board_cleared():
		deal_board()
		events.append({"type": "new_board"})
	return events


func _apply_card(t: String, events: Array[Dictionary]) -> void:
	var bonus: int = combo * int(player.combo_bonus)
	match t:
		"sword":
			_damage_enemy(int(player.sword_damage) + bonus, events, "sword")
			if not finished and int(player.lifesteal) > 0:
				_heal(int(player.lifesteal), events)
		"bolt":
			_damage_enemy(int(player.sword_damage) + 2 + bonus, events, "bolt")
			enemy["timer"] += 1
			events.append({"type": "stall"})
		"shield":
			var amount: int = int(player.block_gain) + bonus
			block += amount
			events.append({"type": "block", "amount": amount})
		"potion":
			_heal(int(player.potion_heal) + bonus, events)
		"coin":
			var g: int = int(player.coin_gain) + bonus
			player.gold += g
			events.append({"type": "gold", "amount": g})
		"skull":
			events.append({"type": "cleanse"})


func _heal(amount: int, events: Array[Dictionary]) -> void:
	var before: int = player.hp
	player.hp = mini(int(player.max_hp), before + amount)
	events.append({"type": "heal", "amount": player.hp - before})


func _damage_enemy(amount: int, events: Array[Dictionary], source: String) -> void:
	enemy["hp"] = maxi(0, int(enemy["hp"]) - amount)
	events.append({"type": "enemy_hit", "amount": amount, "source": source})
	if enemy["hp"] == 0:
		finished = true
		won = true
		events.append({"type": "victory"})


func _damage_player(amount: int, events: Array[Dictionary], source: String) -> void:
	var absorbed := mini(block, amount)
	block -= absorbed
	var taken := amount - absorbed
	player.hp = maxi(0, int(player.hp) - taken)
	events.append({"type": "player_hit", "amount": taken, "blocked": absorbed, "source": source})
	if player.hp == 0:
		finished = true
		won = false
		events.append({"type": "defeat"})


func _tick_enemy(events: Array[Dictionary]) -> void:
	enemy["timer"] -= 1
	if enemy["timer"] > 0:
		return
	enemy["timer"] = enemy["timer_max"]
	events.append({"type": "enemy_attack"})
	_damage_player(int(enemy["atk"]), events, "enemy")
	if finished:
		return
	if int(player.thorns) > 0:
		_damage_enemy(int(player.thorns), events, "thorns")
		if finished:
			return
	if has_trait("regen"):
		var before: int = enemy["hp"]
		enemy["hp"] = mini(int(enemy["max_hp"]), before + 3)
		events.append({"type": "regen", "amount": int(enemy["hp"]) - before})
	if has_trait("enrage"):
		enemy["atk"] += 1
		events.append({"type": "enrage"})
	if has_trait("shuffle"):
		_shuffle_face_down()
		events.append({"type": "shuffle"})


func _shuffle_face_down() -> void:
	var slots: Array[int] = []
	var types: Array = []
	for i in cards.size():
		if not cards[i]["matched"] and i != pending:
			slots.append(i)
			types.append(cards[i]["type"])
	_shuffle(types)
	for k in slots.size():
		cards[slots[k]]["type"] = types[k]


func _board_cleared() -> bool:
	for c in cards:
		if not c["matched"]:
			return false
	return true


func _weighted_card() -> String:
	var total := 0
	for w in GameData.CARD_WEIGHTS.values():
		total += w
	var roll := rng.randi_range(1, total)
	for t in GameData.CARD_WEIGHTS:
		roll -= GameData.CARD_WEIGHTS[t]
		if roll <= 0:
			return t
	return "sword"


func _shuffle(arr: Array) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp
