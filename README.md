# Mnemos

A roguelike memory dungeon made with **Godot 4.3+** (GDScript). Every battle is
a memory card game: flip two cards per turn, and matching pairs trigger their
effect. Fight through 10 floors, pick boons, shop, and beat two bosses. If you
die, the run is over.

## How to play

| Card   | Effect when matched                              |
|--------|--------------------------------------------------|
| Strike | Deal damage                                      |
| Bolt   | Deal more damage and delay the enemy's attack    |
| Guard  | Gain block (absorbs the next damage you take)    |
| Potion | Heal                                             |
| Gold   | Gain gold to spend at the merchant               |
| Curse  | Harmless when matched, but flipping one and missing hurts you |

- Each turn (two flips) ticks the enemy's countdown. At zero it attacks.
- Matches in a row build a **combo** that boosts every effect.
- When the board is cleared, a new one is dealt and you briefly **peek** at it.
- Enemies have traits: *shuffle* (moves your face-down cards), *cursed*
  (adds Curse cards), *regen* and *enrage*.
- Floors 5 and 10 are bosses. A merchant appears after floors 3 and 7.

## Running it

1. Install [Godot 4.3 or newer](https://godotengine.org/download) (the standard
   build, not .NET).
2. Open Godot, click **Import**, and select this folder's `project.godot`.
3. Press **F5** to play.

## Project layout

```
project.godot          Engine settings; registers the Game autoload
scenes/                One small scene per screen (UI is built in code)
scripts/
  game_data.gd         All content and numbers: cards, enemies, bosses, boons
  combat.gd            Battle rules with no UI; returns events for the view
  game_state.gd        "Game" autoload: run state, stats, scene flow, theme
  card_view.gd         A card drawn with shapes, plus flip animations
  battle.gd            Battle screen: renders Combat and animates its events
  main_menu.gd, reward.gd, shop.gd, game_over.gd
tests/test_runner.gd   Headless tests and a balance simulation
```

Rules (`combat.gd`) are kept apart from visuals (`battle.gd`). That means you
can change how things look without breaking gameplay, and the tests can play
thousands of turns in seconds.

## Tests and balancing

```bash
godot --headless --path . -s tests/test_runner.gd
```

The test runner checks the rules, then plays 200 full runs each with bots of
different memory skill. Current results:

| Bot memory | Win rate |
|------------|----------|
| Perfect    | ~88%     |
| 70%        | ~50%     |
| 40%        | ~8%      |

To rebalance, edit the numbers in `scripts/game_data.gd` (enemies, upgrades)
or the starting stats in `game_state.gd`, then rerun the simulation.

## Ideas for next steps

- Art and sound: swap the drawn card icons for sprites and add sound effects.
- A branching map (battle / elite / shop / rest) instead of a straight line.
- More card types (poison, freeze, wildcard) and more enemy traits.
- Save and continue, unlockable starting characters, and a daily seed.
- Export to Web so the game can be played in a browser.
