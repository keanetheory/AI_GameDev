# HANDOFF - T08: win and fail outcomes (foghorn, grounding, silence, Failed screen with reason, restart)

## 1. Task and goal

Resolve WIN or FAIL exactly once. FAIL: foghorn, the ship runs onto the rock while the game does not wait, silence, then a "Failed" screen with a short reason line, and the slice restarts. WIN: the saved ship sails past the rocks into port. Serves R13 and R14 (restart); builds on T07/T31 (the ship and the deadline) and T14 (the audio).

## 2. Files changed

New:
- `scripts/ui/outcome_screen.gd`: the Failed screen and the win card (a CanvasLayer created by GameState with the level).
- `data/world/outcome_screens.json`: the wording and timings. **Placeholder wording**.
- `tools/test_outcome_screen.gd` (17 checks), `tools/shot_outcome.gd` (render check).

Edited:
- `scripts/core/game_state.gd`: creates the outcome screen after the mixer; `outcome_screen()` accessor.
- `scripts/world/passenger_ship.gd`: `cleared_rock` signal (a saved ship is 60 m past the rock); a saved ship now sails at 3x its approach speed (`saved_speed_factor` in `ship_route.json`), so the win card does not wait minutes. `tools/test_ship_route.gd` still passes (closest the hull comes to rock or island is 18 m at every fit time).
- `data/dialogue/dialogue_opening.json`: `TED_F_03` (the reason line) has a 9 s pause so it starts as the ship strikes (about 13.6 s after `SHIP_FAIL`), after `TED_F_01`.
- `tools/test_subtitles.gd`: its fake level now holds a boat. It had been failing since GameState began treating only boat-holding scenes as the game (not caused by this work).

Not touched: the lamp socket, the interior, the Title and Settings scenes, any audio asset.

## 3. How to run and test

```bash
godot --headless --path . --script res://tools/test_outcome_screen.gd
godot --path . --write-movie out.png --fixed-fps 10 --quit-after 40 --script res://tools/shot_outcome.gd -- FAIL   # or WIN
```

The fail timeline (game time, after the deadline runs out): 0 s `SHIP_FAIL`, `TED_F_01` plays and the foghorn sounds; 5.1 and 10.1 s more blasts; about 12 s `TED_F_03`; 13.6 s the ship strikes and the impact plays; 18.6 s both audio buses fade to silence over 2 s; 22.0 s the Failed screen fades in. Enter, Space, R or a left click restarts (after a 1 s grace so a held key cannot skip it); `GameState.restart()` reloads the level and clears the attempt, including the deadline and the audio buses.

The win timeline: the burner is fitted, `SHIP_WIN` follows 4.5 s later (lamp_socket.gd), the saved ship steers off and sails on at 3x speed; once it is 60 m past the rock plus 3 s the win card shows ("The light holds"). Enter or Space plays again, Esc goes to the Title scene.

## 4. Observed behaviour

`test_outcome_screen.gd`: OK, 0 failed. Nothing shows before an outcome or while the ship is still running onto the rock; the screen waits for the audio silence, then shows "Failed" with the reason line and fades in; input during the grace time is ignored; a later `SHIP_WIN` cannot change a fail; Enter restarts (attempt number rises, state cleared); the next attempt has a fresh, hidden screen; the win card never shows before the saved ship has cleared the rock, then shows; Space restarts. The rendered Failed screen (stand-in background) is legible: title, reason line and prompt centred on a dark veil. Also passing after this change: the deadline, audio, game-state, lamp-fit, subtitle, debug-flag and ship-route tests.

## 5. Not verified

- Not played end to end in the real level with a real player: the full sequence (deadline, foghorn over the sea, crash, silence, screen) has only been run in a stand-in level with time stepped by hand.
- The 22 s from expiry to screen, the 9 s pause on `TED_F_03`, and whether Ted's lines land on the strike (the dialogue loader times its pauses on real time and the reading-time estimate) need a play.
- The screen's look is a plain veil and text; the win card is minimal. The break-up is still list-and-sink (no split hull).
- Gamepad input on the screens (there is no controller in this iteration, A21).
- A fail while the player is on the stairs or in the basement (no window sightline) has not been walked; it relies on the audio carrying the fail (A26).

## 6. Licences and provenance

None new.

## 7. Interface or contract changes proposed

PROPOSED: `GameState.outcome_screen()`; `ship.cleared_rock`; the win card as an end state for Gate 1. No new event IDs.

## 8. Open creator decisions

- **Wording.** The Failed screen's reason line ("The burner did not reach the lamp in time, and the ship ran aground.") and the win card ("The light holds") are placeholders. The GDD asks for a short reason line; Ted's voiced line (A20) is the spoken one.
- **Win presentation.** The GDD says only that the ship sails safely into port and Ted reacts (`TED_S5_01/02`). Is a win card wanted at all, or a return to the title?
- **Saved ship speed.** 3x so the win resolves in about 45 s; slower is possible, but the card then waits longer.
