class_name MemoryBoard
extends RefCounted
## The rules of the memory game, with no visuals.
## Each slot holds a bird id; every id appears exactly twice.
##
## Mistakes: a mismatch only counts as a mistake when the player could have
## known better, i.e. when
##   - the second egg had already been seen before (you knew it wasn't a
##     match), or
##   - the partner of the first egg had already been seen (you could have
##     matched it).
## Mismatching two eggs you'd never seen is just exploring and is free.

const DAMAGE_PER_MATCH := 10

var slots: Array[int] = []
var matched: Array[bool] = []
var seen: Array[bool] = []  # Has this egg been opened at least once?
var first := -1  # Slot opened first this turn, or -1.
var pairs_found := 0
var pair_count := 0

var boss_max_hp := 0
var boss_hp := 0
var mistakes_allowed := 0
var mistakes_left := 0
var lost := false


func _init(p_pair_count: int, p_mistakes_allowed: int, rng: RandomNumberGenerator) -> void:
	pair_count = p_pair_count
	mistakes_allowed = p_mistakes_allowed
	mistakes_left = p_mistakes_allowed
	boss_max_hp = pair_count * DAMAGE_PER_MATCH
	boss_hp = boss_max_hp
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
	seen.resize(slots.size())
	seen.fill(false)


func can_pick(i: int) -> bool:
	return not is_over() and i >= 0 and i < slots.size() and not matched[i] and i != first


func partner_of(i: int) -> int:
	for k in slots.size():
		if k != i and slots[k] == slots[i]:
			return k
	return -1


## Opens slot i. Returns {"result": "first"} for the first egg of a turn,
## or {"result": "match"/"mismatch", "a": int, "b": int, "mistake": bool}
## for the second.
func pick(i: int) -> Dictionary:
	if not can_pick(i):
		return {"result": "invalid"}
	if first == -1:
		first = i
		seen[i] = true
		return {"result": "first"}

	var a := first
	first = -1
	var second_was_seen := seen[i]
	seen[i] = true
	if slots[a] == slots[i]:
		matched[a] = true
		matched[i] = true
		pairs_found += 1
		boss_hp = maxi(0, boss_hp - DAMAGE_PER_MATCH)
		return {"result": "match", "a": a, "b": i, "mistake": false}

	var mistake := second_was_seen or seen[partner_of(a)]
	if mistake:
		if mistakes_left == 0:
			lost = true
		else:
			mistakes_left -= 1
	return {"result": "mismatch", "a": a, "b": i, "mistake": mistake}


func is_complete() -> bool:
	return boss_hp == 0


func is_over() -> bool:
	return lost or is_complete()
