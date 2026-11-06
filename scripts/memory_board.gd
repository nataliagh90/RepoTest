class_name MemoryBoard
extends RefCounted
## The rules of the memory game, with no visuals.
## Each slot holds a bird id; every id appears exactly twice.

var slots: Array[int] = []
var matched: Array[bool] = []
var first := -1  # Slot opened first this turn, or -1.
var pairs_found := 0
var pair_count := 0


func _init(p_pair_count: int, rng: RandomNumberGenerator) -> void:
	pair_count = p_pair_count
	for id in pair_count:
		slots.append(id)
		slots.append(id)
	# Shuffle with the given rng so a board can be reproduced from a seed.
	for i in range(slots.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp := slots[i]
		slots[i] = slots[j]
		slots[j] = tmp
	matched.resize(slots.size())
	matched.fill(false)


func can_pick(i: int) -> bool:
	return i >= 0 and i < slots.size() and not matched[i] and i != first


## Opens slot i. Returns {"result": "first"} for the first egg of a turn,
## or {"result": "match"/"mismatch", "a": int, "b": int} for the second.
func pick(i: int) -> Dictionary:
	if not can_pick(i):
		return {"result": "invalid"}
	if first == -1:
		first = i
		return {"result": "first"}
	var a := first
	first = -1
	if slots[a] == slots[i]:
		matched[a] = true
		matched[i] = true
		pairs_found += 1
		return {"result": "match", "a": a, "b": i}
	return {"result": "mismatch", "a": a, "b": i}


func is_complete() -> bool:
	return pairs_found == pair_count
