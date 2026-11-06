extends SceneTree
## Headless tests for the memory rules.
##   godot --headless --path . -s tests/test_runner.gd

var failures := 0


func _initialize() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var b := MemoryBoard.new(6, rng)

	var counts := {}
	for id in b.slots:
		counts[id] = counts.get(id, 0) + 1
	_check(b.slots.size() == 12, "6 pairs make 12 eggs")
	_check(counts.values().all(func(c): return c == 2), "every bird appears exactly twice")

	var a := b.slots.find(0)
	var a2 := b.slots.rfind(0)
	var other := b.slots.find(1)
	_check(b.pick(a)["result"] == "first", "first egg of a turn")
	_check(not b.can_pick(a), "can't pick the same egg twice")
	_check(b.pick(other)["result"] == "mismatch", "different birds don't match")
	b.pick(a)
	_check(b.pick(a2)["result"] == "match", "same birds match")
	_check(not b.can_pick(a) and not b.can_pick(a2), "matched eggs can't be picked")

	# Play the rest perfectly and check the game ends.
	for id in range(1, 6):
		b.pick(b.slots.find(id))
		b.pick(b.slots.rfind(id))
	_check(b.is_complete(), "finding all pairs completes the game")

	print("\nALL TESTS PASSED" if failures == 0 else "\n%d TEST(S) FAILED" % failures)
	quit(1 if failures > 0 else 0)


func _check(cond: bool, msg: String) -> void:
	print(("  ok   " if cond else "  FAIL ") + msg)
	if not cond:
		failures += 1
