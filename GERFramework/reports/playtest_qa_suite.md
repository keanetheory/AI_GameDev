# Playtest QA: the headless suite and both full-slice playthroughs (QA-01)

3 Nov 2026, Playtest QA agent. Every `LightingTheStorm/tools/test_*.gd` (62 scripts) plus `test_slice_playthrough.gd` twice (the win, S01, and `-- fail`, S02), run with the one command from QA-09: `bash LightingTheStorm/tools/run_all_tests.sh -j 4`. The Godot editor was open throughout (PID 35512, the creator's session); it was not closed.

## Result

**Run B (the result of record, 16:40, 4 at a time, 373 s): 63 pass, 1 skipped, 0 fail of 64.** The skip is `test_wall_patch`, which reports SKIP by design ("the repaired exterior (v4) has no holes to patch; LHF_EXTERIOR=v3 runs this test").

Run A (15:46, 6 at a time, the first version of the runner) is kept for the record: `test_interior_budget` **failed** one check, `FAIL builds in under 2500 ms (2662)`, with six tests running beside it and the editor open; in run B it passed at **2498 ms**, 2 ms inside its limit. So the check is not a fault in the game but is too tight to be reliable under load (backlog T86). Run A also showed 27 "NO_RESULT" verdicts: that was the runner, not the tests (they report "ALL PASSED", PASS/FAIL lines or the walk reports, not "RESULT: OK"); the runner was fixed and run B re-ran everything. Run A's re-runs were stopped part way, so it has no second-run results.

The summary table of run B with the time of each test: `GERFramework/reports/playtest_qa_suite_table.md`.

## The two playthroughs (run B)

### test_slice_playthrough (S01, the win): PASS, 48 s
```
--- scenario: WIN (golden path) ---
PASS  the game waits at the door: nothing has started
PASS  the front door is shut and offers to be knocked
PASS  Ted opened the door before he greeted the player
PASS  no ship and no deadline yet
PASS  Ted walks up to the lamp room as he sends the player to the coal
PASS  shovelful 1 taken from the heap
PASS  shovelful 2 taken from the heap
PASS  shovelful 3 taken from the heap
PASS  shovelful 4 taken from the heap
PASS  shovelful 5 taken from the heap
PASS  shovelful 6 taken from the heap
PASS  the boiler is fed: phase SHELTER_AND_GATE, first and half loads reported
PASS  the unplanned ship is on the horizon once the boiler is fed
PASS  coming up to the gate: GATE_APPROACHED
PASS  opening the gate: GATE_OPENED
PASS  both sailors in: phase BEACON_DIAGNOSIS
PASS  Arthur said he would wait; Daniel has not spoken (the player is not in the basement)
PASS  briefed: phase BOARDING
PASS  cast off: phase OUTBOUND
PASS  at the quay: phase SALTGATE
PASS  Arthur: 'Hands off now ...' as the launch auto-docks
PASS  the burner is picked up and carried
PASS  burner aboard, under way: phase RETURN and the hidden clock runs
PASS  the whole crossing sailed on the safe lane without a collision
PASS  Arthur's five calls were made, in order
PASS  home: phase FINAL_REPAIR
PASS  'Hands off now ...' then Arthur's 'go go go'
PASS  the deadline is well short of running out (43%)
PASS  the burner is in the lamp for good and the player's hands are empty
PASS  SHIP_WIN: the outcome is WIN, phase RESOLUTION
PASS  the clock is frozen: the ship can no longer be lost
PASS  the win card shows once the saved ship is past the rock
PASS  Daniel has not spoken: the player has not been down to him
PASS  the first visit down to him: his first line
PASS  all 26 story events happened, once each, in the story's order
PASS  none fired twice
PASS  the phases went forward one at a time: ["SHELTER_AND_GATE", "BEACON_DIAGNOSIS", "BOARDING", "OUTBOUND", "SALTGATE", "RETURN", "FINAL_REPAIR", "RESOLUTION"]
PASS  no failure along the way
PASS  every moment had its line spoken (nothing left unspoken: [])
PASS  no line is still held (0: [])
RESULT: OK (0 failed)
```

### test_slice_playthrough -- fail (S02, the fail and the restart): PASS, 46 s
```
--- scenario: FAIL on the return crossing, then restart ---
PASS  the game waits at the door: nothing has started
PASS  the front door is shut and offers to be knocked
PASS  Ted opened the door before he greeted the player
PASS  no ship and no deadline yet
PASS  Ted walks up to the lamp room as he sends the player to the coal
PASS  shovelful 1 taken from the heap
PASS  shovelful 2 taken from the heap
PASS  shovelful 3 taken from the heap
PASS  shovelful 4 taken from the heap
PASS  shovelful 5 taken from the heap
PASS  shovelful 6 taken from the heap
PASS  the boiler is fed: phase SHELTER_AND_GATE, first and half loads reported
PASS  the unplanned ship is on the horizon once the boiler is fed
PASS  coming up to the gate: GATE_APPROACHED
PASS  opening the gate: GATE_OPENED
PASS  both sailors in: phase BEACON_DIAGNOSIS
PASS  Arthur said he would wait; Daniel has not spoken (the player is not in the basement)
PASS  briefed: phase BOARDING
PASS  cast off: phase OUTBOUND
PASS  at the quay: phase SALTGATE
PASS  Arthur: 'Hands off now ...' as the launch auto-docks
PASS  the burner is picked up and carried
PASS  burner aboard, under way: phase RETURN and the hidden clock runs
PASS  (fail scenario) the player now simply sails on and does nothing
PASS  the deadline ran out: outcome FAIL, phase RESOLUTION
PASS  the ship has struck; the Failed screen is still waiting for the silence
PASS  the Failed screen shows with its reason line
PASS  Ted's fail lines were queued (held while the player is on the boat, spoken once inside)
PASS  Enter restarts the slice: a new attempt with the state cleared
PASS  the level was reloaded
PASS  the new attempt starts at the shut door again, nothing fired
PASS  with a fresh clock and a fresh sea
RESULT: OK (0 failed)
```

## Notes

- `test_interior_budget` prints "every interior light is managed (39 of 25)": 39 managed of 25 counted reads wrong; the check passes, the message (or the count) needs a look (T86).
- Harmless headless noise in every log: `Parameter "m" is null` (the dummy renderer), the tangent warnings, "Not supported by this display server", the ObjectDB leak notice at exit.
- Not run: `check_interior_reach.gd` is not a test_ script; it was run for QA-04 (19 of 20 markers reached, see the exploratory report).
