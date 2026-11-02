# HANDOFF - T19, T38, T59: the 3-minute deadline and 10 s collision; the exterior wall patches as stone

## 1. Task and goal

- T19 (score 5, decision, Production Orchestrator): "Set a placeholder deadline length and write the crossing-penalty values". Serves R10 and R08. Creator, 2 Nov 2026: "collisions cost 10 seconds, deadline is 3 minutes, new task to test and confirm". The deadline goes from the 3:30 placeholder (Decisions A28) to 180 s; a return collision from 5 s to 10 s; outbound collisions still cost nothing. Confirming both in play is the new task T60 (open, needs a human play).
- T38 (score 4, Lighthouse Finisher): "Texture the lighthouse exterior's plain patches (back-west corner panels, fills under the back windows)". Creator, 27 Oct 2026: "add the plain patches to the backlog".
- T59 (score 6, Lighthouse Finisher with the creator): "Sort out the plain wall tiling at the back of the lighthouse". Creator, 30 Oct 2026. Done as one pass with T38.

Commit eba7a35 (2 Nov 2026, today). The creator approved the back wall, and on the front-west corner said "good for now" (closed; thin slab-underside slivers remain and can be reopened if they show in play).

## 2. Files changed

T19:
- `data/world/ship_route.json`: `deadline.length_s` 210 to 180, note marked PLACEHOLDER (T19, confirm in T60, final value from B4).
- `data/world/crossing_sequence.json`: `return_collision.penalty_s` 5 to 10.
- `scripts/core/ship_deadline.gd` (default `length_s` 180), `scripts/world/crossing_sequence.gd` (comment).
- `tools/test_ship_deadline.gd`, `test_audio_mixer.gd`, `test_crossing_sequence.gd`: assert the new values. `QA_SCENARIOS.md` known gaps line.

T38/T59:
- `scripts/world/exterior_wall_detail.gdshader`: finds the repair's one-texel patches (the UV does not change across the face) and, on near-vertical faces, paints them as stained coursed stone (`patch_col`) at every distance, lit with the face's own normal; roof fills and soffits keep their texel. No re-bake, no FAL spend.
- `scripts/world/exterior_openings.gd`: `_lining_skin()` puts a thin skin of the exterior stone on the outward faces of the L1 lining boxes and the floor slab's edges, where they stood out past the scanned wall at the front-west corner and glowed with the interior fill. Hidden wherever the real wall is in front.
- `tools/shot_cam.gd` (free-camera stills, needs a window), `tools/probe_house_gap.gd` (headless map of wall versus lining).

Same commit, not covered here: `Game Audit/` FAL spend notes, T17 closed.

## 3. How to run and test

From `LightingTheStorm/` (creator's binary: `C:\Users\pmkea\Downloads\Godot_v4.3-stable_win64.exe\Godot_v4.3-stable_win64_console.exe`):

```
godot --headless --path . --script res://tools/test_ship_deadline.gd
godot --headless --path . --script res://tools/test_crossing_sequence.gd
godot --headless --path . --script res://tools/test_audio_mixer.gd
godot --headless --path . --script res://tools/test_ship_route.gd
godot --headless --path . --script res://tools/test_slice_playthrough.gd
godot --headless --path . --script res://tools/test_toon_look.gd
godot --headless --path . --script res://tools/probe_house_gap.gd
godot --path . --script res://tools/shot_cam.gd -- out.png <cx> <cy> <cz> <tx> <ty> <tz>
```

For tuning in play: Page Up and Page Down scale the deadline (debug keys); F10 dumps the deadline log.

## 4. Observed behaviour

Run by me on 2 Nov 2026 (Godot 4.3.stable, at eba7a35):
- `test_ship_deadline.gd` (29 PASS, including the 180 s length), `test_crossing_sequence.gd` (40 PASS, "which costs 10 s on the deadline (10.0 s)"), `test_audio_mixer.gd` (26 PASS), `test_ship_route.gd` (21 PASS), `test_outcome_screen.gd` (17 PASS): all `RESULT: OK (0 failed)`.
- `test_slice_playthrough.gd`: OK, with 43% of the 180 s used at the fit (the boat is put on its route, so this is not a human time). `-- fail`: OK.
- `test_toon_look.gd`: ALL PASSED ("the exterior wall shader is on toon").
- `test_wall_patch.gd`: prints only `SKIP the repaired exterior (v4) has no holes to patch; LHF_EXTERIOR=v3 runs this test`. It does not test this work.
- `probe_house_gap.gd`: ran; the west wall still shows lining (`L`) between about y 5.3 and 7.8 m. The probe casts physics rays and the skins are visual only (no collider), so it cannot show whether the skins cover the lining. No automated test covers the shader patches or the skins.

## 5. Not verified

- T60: the 3:00 deadline and 10 s collision cost have not been played by a person (time left at the fit, whether the ship can still be saved after 2-3 collisions, whether it feels urgent but fair).
- The patches and skins were judged from stills by the creator; I did not render or look at them. The thin slab-underside slivers remain by agreement.
- The shader's one-texel test (`fwidth(UV) < 2e-6`) could misfire on a real face seen exactly edge-on or very close; not seen, not ruled out.
- `QA_SCENARIOS.md` S11 still says a return collision charges 5 s.

## 6. Licences and provenance

None. No external assets; `patch_col` and the stone skin reuse the existing exterior material.

## 7. Interface or contract changes proposed

None. The values changed are existing data fields. The deadline length stays a labelled placeholder until T60 and Decisions B4.

## 8. Open creator decisions

- T60: after playing, confirm or adjust `deadline.length_s` (180) and `return_collision.penalty_s` (10).
- Reopen the slab-underside slivers only if they show in play.
- Should S11 in `QA_SCENARIOS.md` be updated to 10 s?
