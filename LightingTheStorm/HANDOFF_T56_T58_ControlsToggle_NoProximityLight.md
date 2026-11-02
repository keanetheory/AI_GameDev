# HANDOFF - T56, T58: C toggles the controls list; no interior lighting from outside

## 1. Task and goal

- T56 (score 7, Gameplay / UI agent): "Toggle the controls list with C". Creator, 30 Oct 2026: "put a 'toggle controls (c)' prompt. if the player hits c it shrinks the control view to just 'controls (c)'". Add a `toggle_controls` input action (physical C), show it in the list, remember the choice for the session and across a restart, keep it working while paused and at the helm, check C does not clash, and extend `test_guidance_hud.gd` and QA S19.
- T58 (score 7, Lighting agent): "Remove the automatic lighting of the lighthouse when the player steps close to it". Creator, 30 Oct 2026: "remove the auto lighting of the lighthouse when you step close to it". The lighthouse should be lit by the phase lighting, not by the player's distance, within `max_dynamic_lights` 18.

Neither lists a requirement id. Commit 0158cad (31 Oct 2026), which also holds T46 (see `HANDOFF_T46_T47_Stairwell.md`). Note written 2 Nov 2026 to close R21; `HANDOFF_T54_T55_Guidance.md` section 4b already records T56 briefly.

## 2. Files changed

T56:
- `project.godot`: new input action `toggle_controls` (physical key C).
- `data/world/controls.json`: `collapsed_label` "Controls"; a "Hide controls" row in both ON_FOOT and AT_HELM.
- `scripts/ui/guidance_hud.gd`: `static var controls_open` (a static on the script, so it outlives a level reload); `_unhandled_input` toggles on the action; `_apply_open()` shows the full list or one "Controls (C)" line, with the key name read from the input map.
- `tools/test_guidance_hud.gd`: shrink, second press, key name, a new HUD keeping it collapsed. `QA_SCENARIOS.md` S19 updated.

T58:
- `scripts/world/interior_lights.gd`: the interior lights only come on while the player is inside the building (`GameState.player_inside_building()`) or on the upper floors (above the ground floor and within 14 m of the tower). Cause: from outside, the hall lights faded up near the door and washed the front wall and steps orange. A level without GameState keeps the old distance rule.
- `tools/test_interior_lights.gd`: a "front step" spot, and no interior light for any outside spot. `tools/test_room_lights.gd`: the player stands on a real floor. `QA_SCENARIOS.md` S20 added.

Not changed: `lighting_rig.gd`, `lighting_spec.json`, the beacon.

## 3. How to run and test

From `LightingTheStorm/` (creator's binary: `C:\Users\pmkea\Downloads\Godot_v4.3-stable_win64.exe\Godot_v4.3-stable_win64_console.exe`):

```
godot --headless --path . --script res://tools/test_guidance_hud.gd
godot --headless --path . --script res://tools/test_interior_lights.gd
godot --headless --path . --script res://tools/test_room_lights.gd
godot --headless --path . --script res://tools/test_slice_playthrough.gd
```

In the game: press C to shrink the controls list to "Controls (C)", again to open it. Walk up to the front door at night: the front wall should stay unlit until you step in.

## 4. Observed behaviour

Run by me on 2 Nov 2026 (Godot 4.3.stable, at eba7a35):
- `test_guidance_hud.gd`: `RESULT: OK (0 failed)`, 27 PASS: "the list itself says C hides the controls", "pressing C shrinks the list to just "Controls (C)" (39 px tall)", "pressing C again opens the full list", a restart (new HUD) keeps it collapsed.
- `test_interior_lights.gd`: ALL PASSED. Outside the door, on the front step and far out on the island: 0 interior lights lit. Entry hall, boiler room, stairs: 6 lit, 2 shadowed. Lamp room: 4 lit.
- `test_room_lights.gd`, `test_slice_playthrough.gd`: OK.
- By reading: `project.godot` binds physical C once (to `toggle_controls` only); no script tests `KEY_C`; there are no `LineEdit` or `TextEdit` controls in the scenes or UI scripts, so C cannot clash with typing. `guidance_hud.gd` sets `PROCESS_MODE_ALWAYS`, so C works while paused.

## 5. Not verified

- C pressed in a running game, while paused and at the helm (the test calls `_unhandled_input` directly, not through the real input path).
- The 45-second dimming was kept, not replaced; the task said "replace ... or keep the dim only while open: ask". I found no record that the creator was asked.
- The look of the front of the lighthouse by night as the player walks up and steps in (fade-up timing), and whether the upper-floor rule (above the ground floor, within 14 m) ever lights the interior for a player on the gallery or outside stairs.

## 6. Licences and provenance

None. No external assets.

## 7. Interface or contract changes proposed

PROPOSED: the input action `toggle_controls` (physical C) and the `collapsed_label` field in `controls.json`. No events or phases changed.

## 8. Open creator decisions

- Keep the 45-second dim as well as C, or let C replace it (T56 asked for this to be put to the creator)?
- Should the collapsed choice also survive quitting the game (it is session-only now, not in the settings file)?
