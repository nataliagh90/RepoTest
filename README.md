# Bird Memory (working title)

A small, weird and funny memory game made with **Godot 4.3+** (GDScript).

The board is full of identical eggs. Click an egg to hatch it and see the bird
inside, then click a second egg. If the two birds are the same color they stay
out; if not, they hide back in their eggs. Find every pair to win.

All art is **placeholder** drawn in code, meant to be replaced later.

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
scripts/egg_spot.gd       One nest + egg + bird (placeholder drawing, animations)
tests/test_runner.gd      Headless tests for the rules
IDEAS.md                  Ideas list for future design decisions
```

Easy knobs in `scripts/main.gd`: `PAIRS` (number of bird pairs), `COLUMNS`,
and `MISMATCH_DELAY` (how long a wrong pair stays visible).

## Tests

```bash
godot --headless --path . -s tests/test_runner.gd
```
