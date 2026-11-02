# HANDOFF - T20, T32: QA scenario list and the whole-slice playthrough test

## 1. Task and goal

T20 (score 5, QA agent): "QA scenario list and automated state-transition checks for the Gate 1 slice". Write a reproducible scenario list covering each phase transition, the clock starting once, the exactly-once outcome, restart, each fail expiry location and a keyboard/controller pass, with headless GDScript checks beside `tools/test_boat.gd` where practical. Serves R15, R13, R14.

T32 (score 10, Gameplay / Systems agent): "Burner fit: carry the burner up to the lamp and fit it (BURNER_FITTED, BEACON_RELIT)". The fit itself is checked by `tools/test_lamp_fit.gd`; this commit adds the end-to-end proof that the fit closes the slice. Serves R12, R13.

Backlog result (31 Oct 2026): `QA_SCENARIOS.md` (17 scenarios, known gaps) and `tools/test_slice_playthrough.gd` (the whole win, and `-- fail` for the failure and restart), both passing. This note was written afterwards (2 Nov 2026) to close R21; the work is commit 5e08762 (30 Oct 2026).

## 2. Files changed

- `QA_SCENARIOS.md` (new): 17 scenarios (S01-S17), each with the expected result, the headless test that covers it and what only a person can judge; a "Known gaps" list. Later commits added S18-S20 (0158cad) and updated the deadline line (eba7a35).
- `tools/test_slice_playthrough.gd` (new, 330 lines): a scripted player plays the whole slice in the real `Level.tscn` at 8x through the real GameState and every director (intro, sailors, diagnosis, boarding, crossing, deadline, audio, outcome screen). The boat is put on its route and the real auto-docking docks it.
- `readme.md`: one line pointing at the playthrough test.
- `GoalOrientedAgent/state/backlog.json` and `BACKLOG.md`: T20 and T32 marked done.
- Not changed: any game script, scene or data file.

## 3. How to run and test

From `LightingTheStorm/` (the creator's binary is `C:\Users\pmkea\Downloads\Godot_v4.3-stable_win64.exe\Godot_v4.3-stable_win64_console.exe`):

```
godot --headless --path . --script res://tools/test_slice_playthrough.gd            # S01, the win
godot --headless --path . --script res://tools/test_slice_playthrough.gd -- fail    # S02, the failure and the restart
godot --headless --path . --script res://tools/test_lamp_fit.gd                     # T32, the fit on its own
```

Each prints PASS/FAIL lines and `RESULT: OK (0 failed)`, and exits 1 on any failure. Other agents: when a change touches the phase machine, an event, a director or the level layout on the route, run both playthroughs; add new scenarios to `QA_SCENARIOS.md` with the test that covers them.

## 4. Observed behaviour

Run by me on 2 Nov 2026 (Godot 4.3.stable, Windows, branch Monday2ndWork at eba7a35, so with the 180 s deadline):
- `test_slice_playthrough.gd`: `RESULT: OK (0 failed)`, 40 PASS, exit 0, 46 s wall time. All 25 story events once each in order; the phases went forward one at a time from SHELTER_AND_GATE to RESOLUTION; the deadline was 43% used at the fit; SHIP_WIN and the win card.
- `test_slice_playthrough.gd -- fail`: `RESULT: OK (0 failed)`, 32 PASS, exit 0, 49 s. Outcome FAIL, phase RESOLUTION; the ship struck; the Failed screen with its reason line; Ted's fail lines held while on the boat; Enter reloads the level, starts at the shut door with nothing fired, a fresh clock and sea.
- `test_lamp_fit.gd`: `RESULT: OK (0 failed)`, 32 PASS.
- Every level-loading test prints about 1,940 `ERROR: Parameter "m" is null` lines (`mesh_get_surface_count` in the headless dummy renderer) and ten "Not supported by this display server". They do not affect the results; I did not trace their source.

## 5. Not verified

- The playthrough puts the boat on its route; nobody steering by hand along the safe lane is tested (listed in the known gaps).
- Pacing, feel and whether each beat is understood without a marker: the "Manual" column of `QA_SCENARIOS.md`. No keyboard/controller pass has been done; there is no controller mapping test.
- S03 (deadline expiring with the player in the lamp room, on the stairs, in the hall) is covered only by sightline and outcome tests, not by a run that stands the player in each place.
- IDLE_STEP_1 (the coal nudges) has no automated check.
- `QA_SCENARIOS.md` S11 still says a return collision charges "5 s" and steering at "8 m/s"; T19 changed the cost to 10 s on 2 Nov 2026 (the Known gaps line was updated, the S11 row was not).

## 6. Licences and provenance

None. No external assets were added.

## 7. Interface or contract changes proposed

None. The test only uses existing events and GameState calls.

## 8. Open creator decisions

- A real-player pacing run (first-time player: 10 to 15 minutes?) is still to be done; T60 covers the deadline part of it.
- Should the stale S11 row (5 s, 8 m/s) be corrected by whoever next edits `QA_SCENARIOS.md`?
- Is a controller pass wanted for Gate 1, or keyboard and mouse only?
