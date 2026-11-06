# Bird Memory (working title)

A small, weird and funny memory game made with **Godot 4.3+** (GDScript).

The board is full of identical eggs. Click an egg to hatch it and see the bird
inside, then click a second egg. If the two birds are the same color they stay
out and hurt the boss, a lazy snake riding a motorized cart. If not, they
hide back in their eggs.

Mismatching two eggs you'd never seen is free (that's just exploring). A
mismatch you could have avoided, because you'd already seen one of the eggs
involved or the right partner, costs one of your 3 allowed mistakes. The
4th one loses the game, after the snake says something sassy.

There are 4 levels: no tricks, then the snake **swaps** eggs you've opened,
then 2 eggs are **secretly blindfolded** (you never see their color; opening
one the first time is free, gambling with it later costs a mistake), then both. Use **Back** / **Skip** at the top to jump between levels.

All art is **placeholder pixel art** generated in code (`scripts/sprites.gd`),
meant to be replaced later by hand-drawn sprites of the same size. Each art
pixel is shown 5x5 on screen (`Sprites.PX`).

The text uses [Pixelify Sans](https://github.com/eifetx/Pixelify-Sans)
(SIL Open Font License, see `fonts/PixelifySans-OFL.txt`).

## Running it

1. Install [Godot 4.3 or newer](https://godotengine.org/download) (standard
   build, not .NET).
2. In Godot, click **Import** and select this folder's `project.godot`.
3. Press **F5** to play.

## Project layout

```
scenes/main.tscn          The game screen
scripts/main.gd           Builds the board, handles clicks, shows the win message
scripts/memory_board.gd   The memory rules, with no visuals
scripts/egg_spot.gd       One nest + egg + bird (draws sprites, animations)
scripts/snake_boss.gd     The motorized snake boss (animated sprite)
scripts/sprites.gd        Placeholder pixel art, generated in code
scripts/pixel_canvas.gd   Helper for painting low-res pixel images
fonts/                    Pixel font + its license
tests/test_runner.gd      Headless tests for the rules
IDEAS.md                  Ideas still being discussed
BACKLOG.md                Decided work, in order
```

Levels are listed in `LEVELS` in `scripts/main.gd`; trick timing (first
turn, cooldown, chance, max per level) is at the top of
`scripts/memory_board.gd`. Other knobs in `scripts/main.gd`: `PAIRS`, `MISTAKES_ALLOWED`, `COLUMNS`,
`MISMATCH_DELAY`, `SLIP_LINES`, `SWAP_LINES`, `BLIND_LINES` and `LOSE_LINES` (the snake's lines). Damage per match
is `DAMAGE_PER_MATCH` in `scripts/memory_board.gd`.

## Tests

```bash
godot --headless --path . -s tests/test_runner.gd
```
