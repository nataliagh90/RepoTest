extends SceneTree
## Headless tests for the memory rules.
##   godot --headless --path . -s tests/test_runner.gd

var failures := 0


func _initialize() -> void:
	_test_pairs_and_matching()
	_test_mistakes()
	_test_losing()
	_test_tricks()
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


func _test_tricks() -> void:
	print("Tricks")
	var b := _board()
	_check(b.maybe_trick(RandomNumberGenerator.new()).is_empty(), "level without tricks never tricks")

	# Swap keeps 'seen' with the egg, so a later mismatch is still a mistake.
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var s := MemoryBoard.new(6, 3, rng, ["swap"])
	var x := s.slots.find(0)
	var y := s.slots.find(1)
	s.pick(x)
	s.pick(y)
	s.swap(x, y)
	_check(s.slots[x] == 1 and s.slots[y] == 0, "swap moves the birds")
	_check(s.seen[x] and s.seen[y], "swapped eggs stay 'already opened'")
	var r := s.pick(x)
	r = s.pick(y)
	_check(r["mistake"], "mismatching swapped opened eggs is still a mistake")

	# Blind eggs: still a mistake if you'd seen them.
	var bl := MemoryBoard.new(6, 3, rng, ["blind"])
	var p := bl.slots.find(0)
	var q := bl.slots.find(1)
	bl.pick(p)
	bl.pick(q)
	bl.blind[q] = true
	bl.pick(p)
	r = bl.pick(q)
	_check(r["mistake"], "mismatching a blind egg you'd seen is still a mistake")

	# Tricks only target opened eggs, and respect timing limits.
	var ok_targets := true
	var max_tricks := 0
	var earliest := 99
	for seed_value in 200:
		var g := RandomNumberGenerator.new()
		g.seed = seed_value
		var t := MemoryBoard.new(6, 99, g, ["swap", "blind"])
		while not t.is_over():
			var unmatched: Array[int] = []
			for k in t.slots.size():
				if not t.matched[k]:
					unmatched.append(k)
			t.pick(unmatched[g.randi() % unmatched.size()])
			unmatched.erase(t.first)
			t.pick(unmatched[g.randi() % unmatched.size()])
			var seen_before := t.seen.duplicate()
			var trick := t.maybe_trick(g)
			if trick.is_empty():
				continue
			earliest = mini(earliest, t.turns)
			var targets: Array = [trick.get("a", -1), trick.get("b", -1), trick.get("egg", -1)]
			for k in targets:
				if k != -1 and not seen_before[k]:
					ok_targets = false
		max_tricks = maxi(max_tricks, t.tricks_done)
	_check(ok_targets, "tricks only ever hit eggs you've opened")
	_check(earliest >= MemoryBoard.TRICK_FIRST_TURN, "no tricks before turn %d" % MemoryBoard.TRICK_FIRST_TURN)
	_check(max_tricks <= MemoryBoard.TRICK_MAX and max_tricks > 0, "tricks happen, but at most %d per level" % MemoryBoard.TRICK_MAX)


func _check(cond: bool, msg: String) -> void:
	print(("  ok   " if cond else "  FAIL ") + msg)
	if not cond:
		failures += 1
