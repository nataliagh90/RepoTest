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
##
## Boss tricks:
##   - "swap": two eggs you've already opened trade places. Each egg keeps its
##     "seen" status, so mismatching them afterwards still counts as a mistake.
##   - "blind": BLIND_EGGS eggs are secretly blindfolded from the start. You
##     only find out when you open one, and you never see its color (it is
##     revealed when its pair is matched). Discovering a blind egg is free;
##     after that, any mismatch involving it is a gamble and costs a mistake.

const DAMAGE_PER_MATCH := 10

# Trick timing (placeholder numbers, tune freely).
const TRICK_FIRST_TURN := 3  # No tricks before this many turns.
const TRICK_COOLDOWN := 2  # Turns between two tricks.
const TRICK_CHANCE := 0.4  # Chance per turn once allowed.
const TRICK_MAX := 3  # Max swaps per level.
const BLIND_EGGS := 2  # How many eggs are secretly blind on "blind" levels.

var slots: Array[int] = []
var matched: Array[bool] = []
var seen: Array[bool] = []  # Has this egg been opened at least once?
var blind: Array[bool] = []  # Secretly blindfolded: never shows its color.
var first := -1  # Slot opened first this turn, or -1.
var first_was_known_blind := false
var pairs_found := 0
var pair_count := 0
var turns := 0

var boss_max_hp := 0
var boss_hp := 0
var mistakes_allowed := 0
var mistakes_left := 0
var lost := false

var tricks: Array = []  # Which tricks the boss may use this level.
var tricks_done := 0
var last_trick_turn := -100


func _init(p_pair_count: int, p_mistakes_allowed: int, rng: RandomNumberGenerator, p_tricks: Array = []) -> void:
	pair_count = p_pair_count
	mistakes_allowed = p_mistakes_allowed
	mistakes_left = p_mistakes_allowed
	tricks = p_tricks
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
	for arr in [matched, seen, blind]:
		arr.resize(slots.size())
		arr.fill(false)
	if "blind" in tricks:
		var eggs := range(slots.size())
		for n in mini(BLIND_EGGS, eggs.size()):
			blind[eggs.pop_at(rng.randi() % eggs.size())] = true


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
		first_was_known_blind = is_known_blind(i)
		var discovered := blind[i] and not seen[i]
		seen[i] = true
		return {"result": "first", "discovered_blind": discovered}

	var a := first
	first = -1
	turns += 1
	var second_was_seen := seen[i]
	var discovered_second := blind[i] and not seen[i]
	seen[i] = true
	if slots[a] == slots[i]:
		matched[a] = true
		matched[i] = true
		pairs_found += 1
		boss_hp = maxi(0, boss_hp - DAMAGE_PER_MATCH)
		return {"result": "match", "a": a, "b": i, "mistake": false, "discovered_blind": discovered_second}

	# You could have known better if: you gambled with a blind egg you already
	# knew about, the second egg was one you'd opened before, or the first egg
	# showed its color and you'd already seen (the color of) its partner.
	var p := partner_of(a)
	var mistake := first_was_known_blind or second_was_seen \
			or (not blind[a] and seen[p] and not blind[p])
	if mistake:
		if mistakes_left == 0:
			lost = true
		else:
			mistakes_left -= 1
	return {"result": "mismatch", "a": a, "b": i, "mistake": mistake, "discovered_blind": discovered_second}


## A blind egg you've already opened, so you know it's blind.
func is_known_blind(i: int) -> bool:
	return blind[i] and seen[i]


func is_complete() -> bool:
	return boss_hp == 0


func is_over() -> bool:
	return lost or is_complete()


# --- Boss tricks ---

## Opened eggs that are still in play (not matched, not currently open).
func opened_eggs() -> Array[int]:
	var result: Array[int] = []
	for k in slots.size():
		if seen[k] and not matched[k] and k != first:
			result.append(k)
	return result


## Called after each finished turn. Maybe swaps two opened eggs and returns
## {"trick": "swap", "a": int, "b": int}, or {} when the boss does nothing.
## (Blind eggs are set up at the start, see _init.)
func maybe_trick(rng: RandomNumberGenerator) -> Dictionary:
	if tricks.is_empty() or is_over() or first != -1 or tricks_done >= TRICK_MAX:
		return {}
	if turns < TRICK_FIRST_TURN or turns - last_trick_turn < TRICK_COOLDOWN:
		return {}
	if rng.randf() >= TRICK_CHANCE:
		return {}
	if not tricks.has("swap"):
		return {}
	var pairs := _swappable_pairs()
	if pairs.is_empty():
		return {}
	tricks_done += 1
	last_trick_turn = turns
	var pair: Array = pairs[rng.randi() % pairs.size()]
	var a: int = pair[0]
	var b: int = pair[1]
	swap(a, b)
	return {"trick": "swap", "a": a, "b": b}


## Pairs of opened eggs holding different birds (swapping two identical birds
## would change nothing).
func _swappable_pairs() -> Array:
	var eggs := opened_eggs()
	var result := []
	for x in eggs.size():
		for y in range(x + 1, eggs.size()):
			if slots[eggs[x]] != slots[eggs[y]]:
				result.append([eggs[x], eggs[y]])
	return result


## Two eggs trade places. Everything about an egg moves with it.
func swap(a: int, b: int) -> void:
	for arr in [slots, seen, blind]:
		var tmp = arr[a]
		arr[a] = arr[b]
		arr[b] = tmp
