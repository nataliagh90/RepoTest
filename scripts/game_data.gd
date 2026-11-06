class_name GameData
extends RefCounted
## Static game content: cards, enemies, bosses and upgrades.
## Tweak numbers here to rebalance the game.

const CARDS := {
	"sword": {"name": "Strike", "color": Color(0.86, 0.33, 0.28), "desc": "Deal damage to the enemy."},
	"bolt": {"name": "Bolt", "color": Color(0.58, 0.42, 0.95), "desc": "Deal extra damage and delay the enemy's attack."},
	"shield": {"name": "Guard", "color": Color(0.33, 0.55, 0.86), "desc": "Gain block that absorbs damage."},
	"potion": {"name": "Potion", "color": Color(0.30, 0.72, 0.40), "desc": "Restore health."},
	"coin": {"name": "Gold", "color": Color(0.93, 0.70, 0.20), "desc": "Gain gold to spend in shops."},
	"skull": {"name": "Curse", "color": Color(0.45, 0.43, 0.40), "desc": "Missing a curse card hurts. Matching it is safe."},
}

## Relative chance of each card type when filling a board.
const CARD_WEIGHTS := {
	"sword": 34,
	"bolt": 12,
	"shield": 18,
	"potion": 16,
	"coin": 20,
}

const TRAITS := {
	"shuffle": "Shuffles your face-down cards when it attacks.",
	"cursed": "Adds Curse cards to the board.",
	"regen": "Heals when it attacks.",
	"enrage": "Hits harder after every attack.",
}

## Regular enemies. Tier 1 appears on floors 1-4, tier 2 on floors 6-9.
const ENEMIES := [
	{"name": "Slime", "hp": 14, "atk": 3, "timer": 3, "traits": [], "tier": 1},
	{"name": "Rat Swarm", "hp": 12, "atk": 2, "timer": 2, "traits": [], "tier": 1},
	{"name": "Goblin Thief", "hp": 16, "atk": 3, "timer": 3, "traits": ["shuffle"], "tier": 1},
	{"name": "Skeleton", "hp": 18, "atk": 4, "timer": 4, "traits": ["cursed"], "tier": 1},
	{"name": "Cave Troll", "hp": 32, "atk": 7, "timer": 4, "traits": ["regen"], "tier": 2},
	{"name": "Wraith", "hp": 28, "atk": 6, "timer": 3, "traits": ["cursed"], "tier": 2},
	{"name": "Trickster Imp", "hp": 26, "atk": 5, "timer": 3, "traits": ["shuffle"], "tier": 2},
	{"name": "Berserker", "hp": 30, "atk": 4, "timer": 3, "traits": ["enrage"], "tier": 2},
]

## Bosses keyed by floor number.
const BOSSES := {
	5: {"name": "The Mirror Knight", "hp": 46, "atk": 7, "timer": 4, "traits": ["shuffle", "enrage"], "boss": true},
	10: {"name": "Lich of Lost Memories", "hp": 80, "atk": 8, "timer": 4, "traits": ["cursed", "shuffle"], "boss": true},
}

## Boons offered after battles and sold in shops. "stat" is a property on
## the Game autoload that gets "amount" added to it.
const UPGRADES := [
	{"id": "whetstone", "name": "Whetstone", "desc": "+1 Strike damage", "stat": "sword_damage", "amount": 1, "cost": 30},
	{"id": "iron_skin", "name": "Iron Skin", "desc": "+2 block from Guard", "stat": "block_gain", "amount": 2, "cost": 25},
	{"id": "herbalism", "name": "Herbalism", "desc": "+2 healing from Potions", "stat": "potion_heal", "amount": 2, "cost": 25},
	{"id": "vitality", "name": "Vitality", "desc": "+8 max HP (and heal 8)", "stat": "max_hp", "amount": 8, "cost": 30},
	{"id": "greed", "name": "Greed", "desc": "+2 gold from Gold cards", "stat": "coin_gain", "amount": 2, "cost": 15},
	{"id": "third_eye", "name": "Third Eye", "desc": "Peek at the board +1s longer", "stat": "peek_time", "amount": 1.0, "cost": 25},
	{"id": "patience", "name": "Patience", "desc": "Enemies attack 1 turn later", "stat": "enemy_timer_bonus", "amount": 1, "cost": 40},
	{"id": "momentum", "name": "Momentum", "desc": "+1 bonus per combo step", "stat": "combo_bonus", "amount": 1, "cost": 35},
	{"id": "thorns", "name": "Thorns", "desc": "Deal 2 damage when hit", "stat": "thorns", "amount": 2, "cost": 30},
	{"id": "vampiric", "name": "Vampiric Edge", "desc": "Strikes heal you for 1", "stat": "lifesteal", "amount": 1, "cost": 35},
]

const HEAL_ITEM := {"name": "Bandages", "desc": "Restore 12 HP", "heal": 12, "cost": 15}
