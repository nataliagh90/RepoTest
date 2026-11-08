# Ideas

A parking lot for game ideas. Nothing here is decided until we talk it
through and you pick it. Items marked **(built)** are in the game.

## Core mechanics

- **(built)** Boss with an HP bar: every matched pair damages the boss.
- **(built)** Two kinds of mistakes: (1) opening two eggs for the first time
  that don't match (exploring, not your fault, free), and (2) mismatching when
  you could have known better (forgetting). Only (2) costs one of your
  3 allowed mistakes.
- Original budget idea: tries = worst case for a perfect memory
  (2 x pairs - 1, e.g. 11 for 6 pairs) + allowed mistakes. Concern: might be
  too easy; test it and add spice later.

## Power-ups (help the player)

- **Cracked egg marker:** once an egg has been opened, it stays with a broken
  piece so you can tell you already opened it. It should still offer what is
  inside.
- **Stronger hits:** something that increases the damage a match deals.
  **Parked:** right now clearing the board always kills the snake
  (HP = pairs x damage), so there's no problem for it to solve yet.
- **"Not this color" marks:** after a blind egg fails to match, it gets marked
  with the colors it is *not* (e.g. "not red"), so you don't have to keep
  track yourself. (Came out of sparring; the base game shows nothing.)
  To keep it from doing the remembering for you: show the marks only
  briefly (e.g. 3 seconds), when the player chooses to use it, then hide
  them. (Undecided.)

## Progression (being discussed)

- **Losing sends you back to level 1** (roguelike run). Back/Skip are a
  designer tool for testing only, not for players.
- **Shop**, roguelike style: it could appear after each level, or (current
  favorite) when the player loses. Still open: what currency the player
  earns. Power-ups you buy come with you into the next try (after a loss
  sends you back to level 1).
- **Power-ups as chosen difficulty:** buying help is the player's choice of
  difficulty, not a trap. Don't punish players who want help. The copy
  should make this clear, so players think "I can tune my difficulty", not
  "the game pushed me into this and now it's boring".
  The message goes in the shop. References to look at: Celeste's Assist
  Mode, Hades' God Mode, Bastion's Shrine idols.
- Ways to keep power-ups from flattening the game (undecided): a limited
  number of uses, or making them hard to get (level, points...).
- **Power-ups are packs whose uses refresh** (decided), not one-time
  potions: it fits the player choosing their own difficulty, and avoids
  hoarding. **Uses refresh every run** (decided), so the player spreads
  them over the 4 levels. To watch while testing: players saving charges
  "for later" and never using them.
- **The shop starts small:** only the Assists we already have. More get
  added later, once the game creates the need for them.
- **The help is called "Assist"** in the shop (term players know from
  Celeste's Assist Mode).
- **Turning difficulty up** (idea): a dial the other way, like Bastion's
  Shrine idols or Hades' Pact of Punishment. Not discussed yet.
- Open topic: how the player activates a power-up and how it shows in the
  HUD.
- Rule of thumb from sparring: offer a power-up once the player has felt the
  problem it solves, not before.

## Boss tricks (make it harder)

- **(built)** **Swap:** the boss swaps two eggs you've already opened (shown:
  the eggs hop over). They keep their "already opened" status, so a mismatch
  on them still costs a mistake. Levels 2 and 4.
- **(built)** **Secret blind eggs:** 2 eggs are secretly blindfolded from the
  start. You only find out when you open one, and you never see its color
  (a matched pair reveals it). Discovering one is free; after that, any
  mismatch involving it is a gamble and costs a mistake. Strategy: leave
  blind eggs for last and deduce them by elimination. Levels 3 and 4.
  (Replaced an earlier version where the boss blinded eggs you'd already
  opened.)
- To watch while testing: with only 1-2 blind eggs, "leave it for last" may
  make them too easy.
- **Hidden mistakes:** the boss hides how many mistakes you have left.
- Fewer allowed mistakes on later levels.

## Style and boss personality

- **(built)** **Sassy boss on memory slips:** when you mess up a pair of eggs that were
  already opened, the boss laughs at you or makes a sassy comment.
- **Mock wasteful play:** e.g. starting a turn with an egg you've already seen
  while unopened eggs remain. Not a memory slip, just inefficient; the boss
  can still make fun of it.
- **The motorized snake:** a snake too lazy to crawl, so it installed wheels.
  Room for a backstory.

## Characters / levels

- Characters change every level. Level 1 is birds hatching from eggs.

## Art and feel

- Weird and funny. Vibes inspired by Dicey Dungeons and Thank Goodness You're
  Here (inspiration only, no copying). Current art is placeholder.
