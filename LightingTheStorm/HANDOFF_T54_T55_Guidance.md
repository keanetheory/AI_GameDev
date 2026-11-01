# HANDOFF - T54 and T55: the goal tracker and the on-screen controls

## 1. Task and goal

Creator, 30 Oct 2026: keep a goal tracker in the upper right of the screen so the player knows what to do, and display the controls in the lower right. Serves a first-time player who has no markers (Pillar 3 still holds: guidance is spoken by Ted and Arthur; the tracker only repeats the current job in plain text and never shows time; Decisions A35).

## 2. Files changed

New:
- `scripts/ui/guidance_hud.gd`: one `CanvasLayer` that GameState creates inside the level (like the outcome screen), so a restart gives a fresh one.
- `data/world/goals.json`: 19 goals in story order, each with the story event that completes it (`done_on`).
- `data/world/controls.json`: the control rows for `ON_FOOT` and `AT_HELM`.
- `tools/test_guidance_hud.gd` (23 checks), `tools/shot_hud.gd` (a still of the real level with the HUD).

Edited: `scripts/core/game_state.gd` (creates the HUD, `guidance()`), `scripts/ui/subtitle_ui.gd` (the "Journal updated" note moved below the tracker, no longer cut off at the screen edge; the subtitle width narrowed from 1100 to 840 px so it clears the controls list), `QA_SCENARIOS.md` (S18, S19), the GDD (Exec Summary Pillar 3 line, Decisions item 21 / A35).

## 3. How to run and test

```bash
godot --headless --path . --script res://tools/test_guidance_hud.gd
godot --path . --resolution 1280x720 --script res://tools/shot_hud.gd -- out.png ON_FOOT GAME_STARTED,LIGHTHOUSE_ENTERED
```

## 4. Observed behaviour

- The goal shown is the one after the latest goal whose `done_on` event has fired, so a player who skips ahead is never shown a goal behind them. When a goal is done, a tick and the old text stay for 1.4 s, then the next goal fades in. It starts on "Knock on the lighthouse door", ends on "Stand back and watch the light" and hides when the attempt resolves (the Failed screen and the win card take over).
- The controls list is built from the input map (key names follow the player's keyboard layout), so a rebound key changes it. On foot: WASD move, mouse look, Shift sprint, Space jump, E interact, J journal, P pause, Esc free the mouse. At the helm (the player seated in the launch): A / D steer, E cast off, Q step ashore, J, P. The debug keys are not listed. It is at full strength for 45 s, dims to half, and comes back for 6 s whenever the mode changes.
- A render of the real level at 1280 x 720 shows the tracker upper right, the controls lower right, the subtitles centred clear of both and the "Journal updated" note under the tracker.

## 4b. Follow-up (31 Oct 2026, T56)

C (the new `toggle_controls` input action, physical key C) shrinks the controls list to one small "Controls (C)" line and opens it again. The list itself now ends with "C  Hide controls". The choice is a static on the script, so it survives a restart. Tested in `test_guidance_hud.gd`.

## 5. Not verified

- Not played: legibility over the bright sky and the dark interior, the pace of the goals, and whether the wording reads right in Ted's world.
- Only 16:9 at 1280 x 720 was rendered; other aspect ratios use the same corner anchoring but were not looked at.
- Goal wording is the Gameplay agent's draft; the Tuesday dialogue review (T50, T52) is the place to settle it.

## 6. Licences and provenance

None: the default font, no new assets.

## 7. Interface or contract changes proposed

`GameState.guidance()` returns the HUD node. No event, phase or dialogue changes.

## 8. Open creator decisions

- Whether the controls should dim after the first minute (built) or stay at full strength, or be toggled with a key.
- Whether to show the goal for the optional `WINDOW_LOOKED` or the coal-half way beats (left out: one goal per phase step keeps it short).
