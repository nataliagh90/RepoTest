extends SceneTree
## Headless tests and balance simulation.
##
##   godot --headless --path . -s tests/test_runner.gd
##
## Plays full runs with a bot whose memory can be tuned: 1.0 remembers every
## card it has seen, lower values forget cards at random, like a person.

const GameState := preload("res://scripts/game_state.gd")

var failures := 0


func _initialize() -> void:
	_test_data()
	_test_board_is_pairs()
	_test_match_and_mismatch()
	_test_enemy_attack_and_block()
	var perfect := _simulate("perfect memory", 1.0, 200)
	var good := _simulate("good memory (70%)", 0.7, 200)
	_simulate("poor memory (40%)", 0.4, 200)
	_check(perfect >= 0.85, "a perfect-memory bot should almost always win (got %.0f%%)" % (perfect * 100))
	_check(good > 0.1 and good < perfect, "a 70%%-memory bot should sometimes win (got %.0f%%)" % (good * 100))
	if failures == 0:
		print("\nALL TESTS PASSED")
	else:
		print("\n%d TEST(S) FAILED" % failures)
	quit(1 if failures > 0 else 0)


func _check(cond: bool, msg: String) -> void:
	if cond:
		print("  ok   ", msg)
	else:
		failures += 1
		print("  FAIL ", msg)


func _new_game(seed_value: int) -> Node:
	var g: Node = GameState.new()
	g.new_run(seed_value)
	return g


func _test_data() -> void:
	print("Data")
	for e in GameData.ENEMIES + GameData.BOSSES.values():
		for key in ["name", "hp", "atk", "timer", "traits"]:
			_check(e.has(key), "%s has '%s'" % [e.get("name", "?"), key])
		for t in e["traits"]:
			_check(GameData.TRAITS.has(t), "%s trait '%s' is described" % [e["name"], t])
	var g := _new_game(1)
	for u in GameData.UPGRADES:
		_check(u["stat"] in g, "upgrade %s targets a real stat" % u["id"])
	for t in GameData.CARD_WEIGHTS:
		_check(GameData.CARDS.has(t), "card '%s' has display data" % t)
	g.free()


func _test_board_is_pairs() -> void:
	print("Boards")
	var g := _new_game(7)
	for d in range(1, Game_MAX() + 1):
		g.depth = d
		var c := Combat.new(g, g.enemy_for_depth(d), g.rng)
		var counts := {}
		for card in c.cards:
			counts[card["type"]] = counts.get(card["type"], 0) + 1
		var all_even := true
		for k in counts:
			all_even = all_even and counts[k] % 2 == 0
		_check(all_even, "floor %d: every card type comes in pairs (%d cards)" % [d, c.cards.size()])
		_check(c.cards.size() <= 24, "floor %d: board fits the 6x4 grid" % d)
	g.free()


func _test_match_and_mismatch() -> void:
	print("Turns")
	var g := _new_game(3)
	var c := Combat.new(g, {"name": "Dummy", "hp": 99, "atk": 0, "timer": 99, "traits": []}, g.rng)
	var a := -1
	var b := -1
	for i in c.cards.size():
		for j in range(i + 1, c.cards.size()):
			if a == -1 and c.cards[i]["type"] == "sword" and c.cards[j]["type"] == "sword":
				a = i
				b = j
	c.pick(a)
	var events := c.pick(b)
	_check(c.cards[a]["matched"] and c.cards[b]["matched"], "matching two Strikes marks them matched")
	_check(c.enemy["hp"] == 99 - g.sword_damage, "a Strike deals sword_damage")
	_check(events.any(func(e): return e["type"] == "match"), "a match event is emitted")
	_check(c.combo == 1, "a match starts a combo")
	var x := -1
	var y := -1
	for i in c.cards.size():
		for j in c.cards.size():
			if x == -1 and not c.cards[i]["matched"] and not c.cards[j]["matched"] and c.cards[i]["type"] != c.cards[j]["type"]:
				x = i
				y = j
	c.pick(x)
	c.pick(y)
	_check(c.combo == 0 and not c.cards[x]["matched"], "a mismatch resets the combo")
	_check(c.turns == 2, "each pair of flips is one turn")
	g.free()


func _test_enemy_attack_and_block() -> void:
	print("Enemy")
	var g := _new_game(5)
	var c := Combat.new(g, {"name": "Dummy", "hp": 99, "atk": 5, "timer": 1, "traits": []}, g.rng)
	c.block = 3
	var hp_before: int = g.hp
	var picks := _mismatched_pair(c)
	c.pick(picks[0])
	c.pick(picks[1])
	_check(g.hp == hp_before - 2 and c.block == 0, "block absorbs damage before HP")
	g.free()


func _mismatched_pair(c: Combat) -> Array[int]:
	for i in c.cards.size():
		for j in c.cards.size():
			if c.cards[i]["type"] != c.cards[j]["type"] and c.cards[i]["type"] != "skull" and c.cards[j]["type"] != "skull":
				return [i, j]
	return [0, 1]


func Game_MAX() -> int:
	return GameState.MAX_DEPTH


# --- Simulation ---

func _simulate(label: String, memory: float, runs: int) -> float:
	var wins := 0
	var deaths := {}
	var total_turns := 0
	for r in runs:
		var result := _play_run(1000 + r, memory)
		total_turns += result["turns"]
		if result["won"]:
			wins += 1
		else:
			deaths[result["depth"]] = deaths.get(result["depth"], 0) + 1
	var keys := deaths.keys()
	keys.sort()
	var death_str := ", ".join(keys.map(func(k): return "F%d:%d" % [k, deaths[k]]))
	print("Sim  %-20s win %3.0f%%  avg turns/run %4d  deaths by floor [%s]" % [label, 100.0 * wins / runs, total_turns / runs, death_str])
	return float(wins) / runs


func _play_run(seed_value: int, memory: float) -> Dictionary:
	var g := _new_game(seed_value)
	var bot := RandomNumberGenerator.new()
	bot.seed = seed_value * 31
	var turns := 0
	var won := false
	while true:
		var c := Combat.new(g, g.enemy_for_depth(g.depth), g.rng)
		if not _bot_fight(c, bot, memory, g.peek_time):
			break
		turns += c.turns
		if not c.won:
			break
		g.grant_victory(c)
		if g.depth >= GameState.MAX_DEPTH:
			won = true
			break
		var choices: Array[Dictionary] = g.roll_upgrades(3)
		g.apply_upgrade(choices[bot.randi() % choices.size()])
		if g.shop_comes_next():
			while g.gold >= GameData.HEAL_ITEM["cost"] and g.hp < g.max_hp - 8:
				g.gold -= GameData.HEAL_ITEM["cost"]
				g.heal(GameData.HEAL_ITEM["heal"])
			for u in g.roll_upgrades(3):
				if g.gold >= u["cost"]:
					g.gold -= u["cost"]
					g.apply_upgrade(u)
		g.depth += 1
	var result := {"won": won, "depth": g.depth, "turns": turns}
	g.free()
	return result


## Returns false if the fight never ended (a bug).
func _bot_fight(c: Combat, bot: RandomNumberGenerator, memory: float, peek: float) -> bool:
	var known := {}  # card index -> type the bot remembers
	_memorize_peek(c, known, bot, memory, peek)
	var guard := 0
	while not c.finished:
		guard += 1
		if guard > 2000:
			_check(false, "fight against %s did not end" % c.enemy["name"])
			return false
		var first := -1
		var second := -1
		var pair := _known_pair(c, known)
		if not pair.is_empty():
			first = pair[0]
			second = pair[1]
		else:
			first = _random_choice(c, known, bot, -1)
		var events := c.pick(first)
		_observe(events, c, known, bot, memory, peek)
		if second == -1:
			var seen: String = c.cards[first]["type"]
			for i in known:
				if i != first and known[i] == seen and not c.cards[i]["matched"]:
					second = i
			if second == -1:
				second = _random_choice(c, known, bot, first)
		events = c.pick(second)
		_observe(events, c, known, bot, memory, peek)
	return true


func _observe(events: Array[Dictionary], c: Combat, known: Dictionary, bot: RandomNumberGenerator, memory: float, peek: float) -> void:
	for e in events:
		match e["type"]:
			"flip":
				if bot.randf() < memory:
					known[e["index"]] = e["card"]
			"match":
				known.erase(e["a"])
				known.erase(e["b"])
			"shuffle":
				known.clear()
			"new_board":
				known.clear()
				_memorize_peek(c, known, bot, memory, peek)


func _memorize_peek(c: Combat, known: Dictionary, bot: RandomNumberGenerator, memory: float, peek: float) -> void:
	var chance := clampf(peek * 0.15, 0.0, 1.0) * memory
	for i in c.cards.size():
		if bot.randf() < chance:
			known[i] = c.cards[i]["type"]


func _known_pair(c: Combat, known: Dictionary) -> Array:
	var by_type := {}
	for i in known:
		if c.cards[i]["matched"]:
			continue
		var t: String = known[i]
		if by_type.has(t):
			return [by_type[t], i]
		by_type[t] = i
	return []


func _random_choice(c: Combat, known: Dictionary, bot: RandomNumberGenerator, exclude: int) -> int:
	var unknown: Array[int] = []
	var any: Array[int] = []
	for i in c.cards.size():
		if i == exclude or c.cards[i]["matched"]:
			continue
		any.append(i)
		if not known.has(i):
			unknown.append(i)
	var pool := unknown if not unknown.is_empty() else any
	return pool[bot.randi() % pool.size()]
