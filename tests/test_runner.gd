extends SceneTree
## Headless tests for the memory rules.
##   godot --headless --path . -s tests/test_runner.gd

var failures := 0


func _initialize() -> void:
	_test_pairs_and_matching()
	_test_mistakes()
	_test_losing()
	print("\nALL TESTS PASSED" if failures == 0 else "\n%d TEST(S) FAILED" % failures)
	quit(1 if failures > 0 else 0)


func _board(seed_value: int = 42) -> MemoryBoard:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return MemoryBoard.new(6, 3, rng)


func _test_pairs_and_matching() -> void:
	print("Matching")
	var b := _board()
	var counts := {}
	for id in b.slots:
		counts[id] = counts.get(id, 0) + 1
	_check(b.slots.size() == 12, "6 pairs make 12 eggs")
	_check(counts.values().all(func(c): return c == 2), "every bird appears exactly twice")
	_check(b.boss_hp == 60, "boss starts with 6 x 10 HP")

	var a := b.slots.find(0)
	_check(b.pick(a)["result"] == "first", "first egg of a turn")
	_check(not b.can_pick(a), "can't pick the same egg twice")
	_check(b.pick(b.slots.rfind(0))["result"] == "match", "same birds match")
	_check(b.boss_hp == 50, "a match deals 10 damage")
	for id in range(1, 6):
		b.pick(b.slots.find(id))
		b.pick(b.slots.rfind(id))
	_check(b.is_complete() and b.boss_hp == 0, "finding all pairs defeats the boss")


func _test_mistakes() -> void:
	print("Mistakes")
	var b := _board()
	# Two never-seen eggs that don't match: exploring, free.
	var r := b.pick(b.slots.find(0))
	r = b.pick(b.slots.find(1))
	_check(r["result"] == "mismatch" and not r["mistake"], "mismatching two new eggs is free")
	_check(b.mistakes_left == 3, "no mistake spent while exploring")

	# Open a new egg whose partner we've already seen, then miss: forgetting.
	b.pick(b.slots.rfind(0))  # partner of the first 0 was seen
	r = b.pick(b.slots.find(2))
	_check(r["mistake"], "missing a pair you had already seen is a mistake")
	_check(b.mistakes_left == 2, "a mistake spends one pip")

	# New egg, then pick an egg you already know is different: also a mistake.
	var b2 := _board()
	b2.pick(b2.slots.find(0))
	b2.pick(b2.slots.find(1))  # both seen now, free
	b2.pick(b2.slots.find(3))  # new egg, partner unseen
	r = b2.pick(b2.slots.find(1))  # known to be a different bird
	_check(r["mistake"], "pairing with an egg you knew was different is a mistake")


func _test_losing() -> void:
	print("Losing")
	var b := _board()
	var x := b.slots.find(0)
	var y := b.slots.find(1)
	b.pick(x)
	b.pick(y)  # exploring, free
	for k in 3:
		b.pick(x)
		b.pick(y)  # both seen: a mistake each time
	_check(b.mistakes_left == 0 and not b.lost, "3 mistakes use up every pip but you're still alive")
	b.pick(x)
	b.pick(y)
	_check(b.lost and b.is_over(), "the 4th mistake loses the game")
	_check(not b.can_pick(b.slots.find(2)), "no picking after the game is over")


func _check(cond: bool, msg: String) -> void:
	print(("  ok   " if cond else "  FAIL ") + msg)
	if not cond:
		failures += 1
