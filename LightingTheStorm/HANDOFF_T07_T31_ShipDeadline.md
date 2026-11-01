# HANDOFF - T31 and T07: the passenger ship's lane, the grounding rock, and the hidden ship deadline

## 1. Task and goal

- **T31:** a placeholder passenger ship with lights, a path from the horizon towards the port that the deadline drives, a grounding rock next to the island that the lamp room can see, and a safe pass on a win.
- **T07:** a hidden numeric ship deadline (no UI) that starts on `RETURN_DEPARTED`, stops in menus and on pause (P), fires `SHIP_FAIL` once when it runs out, with a debug time scale and event log. The ship is spawned at run time from GameState, so `Level.tscn` carries neither.

Serves R10 (hidden deadline), R11 (storm split: the sea now reads `GameState.deadline_progress()`), R13 (fail presentation inputs for T08), R05 (the ship appears at the horizon).

The old premise "the ship sits across the launch's route south" is gone: the static `PassengerShip` node (broadside at 5.14, -2.4, 66.5) was removed from `Level.tscn`.

## 2. Files changed

New:
- `data/world/ship_route.json`: deadline length (210 s placeholder), the ship's lane (approach, commit distance, safe lane), the grounding rock, the crash and the placeholder lights. Everything is tunable here.
- `scripts/world/ship_route.gd`: path maths (no nodes).
- `scripts/world/passenger_ship.gd`: the ship (model, lit windows, navigation lights, lanterns and spill (T44), movement, crash). Signals `impact`, `passed`.
- `scripts/core/ship_deadline.gd`: the clock, the P key, the debug time scale, the event log; owns the ship.
- `tools/test_ship_route.gd` (T31) and `tools/test_ship_deadline.gd` (T07); `tools/probe_ship_route.gd` prints the island, rock and ship bounds used to lay the lane out.

Edited:
- `scripts/core/game_state.gd`: creates the director when the level is ready, `deadline_progress()` (-1 until the clock starts; wave_system.gd already called it), `deadline()`, F10 dump also prints the deadline log, restart un-pauses.
- `scenes/Level.tscn`: removed the `PassengerShip` node and its `ext_resource`.
- `tools/shot.gd`: `SHOT_SHIP=<0..1>` or `crash:<s>` shows the ship (render check).

Deliberately not touched: lamp_socket.gd, the interior, the island, Level.tscn beyond the one node.

## 3. How to run and test

```bash
godot --headless --path . --script res://tools/test_ship_route.gd     # lane, crash, win pass, lamp-room sightline (about 40 s)
godot --headless --path . --script res://tools/test_ship_deadline.gd  # clock, pause, time scale, fail, win, restart
```

In the game (debug builds): P pauses and resumes (clock and ship freeze). Page Up / Page Down step the deadline's time scale (0.25 to 16), Home resets it; or `-- --deadline-scale=8`. F10 dumps the event log and the deadline log. `GameState.deadline().add_penalty(seconds)` is the hook for T19's collision costs (nothing calls it yet).

How other systems use it: read `GameState.deadline_progress()` (0..1, -1 before the clock); connect `GameState.deadline().ship.impact` to time the foghorn, the crash audio and Ted's `TED_F_01` (T08); `ship.passed` marks the ship safe in port.

The lane (revised 29 Oct 2026 after the creator's first play): the ship appears once the boiler is fed (`BOILER_FED`; also on `LAMP_ROOM_ENTERED`, `BURNER_DIAGNOSED`, `BOARDING_THRESHOLD`, `SHIP_SIGHTED` or `BOAT_CAST_OFF`, whichever comes first) out to the **north-east** at (700, -250), so it is in view from the lamp room when Ted names it and sits to the right of the player on the return crossing. It holds there with its lights on. On `RETURN_DEPARTED` it comes in towards the island's east side at about 3.1 m/s, turns at (132, 28) and runs straight onto the grounding rock (`SeaStack1`, 24, 125). At the deadline (progress 1) it has 43 m to go and can no longer turn; about 13.6 s later it strikes the rock and rides up, lists, sinks and its lights die. If the burner is fitted first the clock freezes and the ship keeps to the lane as far as (132, 28), then steers (8 deg/s, at 3x speed) through (112, 190) and on to Saint Calder, passing the rock on its east side; `SHIP_WIN` follows 4.5 s after the fit (lamp_socket.gd). Its lights were reworked in T44 (1 Nov 2026, below).

## 4. Observed behaviour

- `test_ship_route.gd`: OK, 0 failed. The approach lane keeps the hull 26 m off the island and every other stack; the bow meets the rock face (gap 0.2 m); with the beacon lit at 0, 25, 50, 80, 95, 99 and 100 % the ship reaches port with at least 17.9 m of clear water; the lamp room sees the rock face, the impact, the bow strike, 47 of 47 sampled lane points, the safe pass and the ship's starting lights (a control ray under the island is correctly reported blocked).
- `test_ship_deadline.gd`: OK, 0 failed (31 checks): hidden until boarding, inactive before the return, starts once, P pauses and resumes, the time scale and penalty work, expiry fires `SHIP_FAIL` exactly once and the ship crashes with one `impact`, a later `SHIP_WIN` cannot flip it, a restart gives a fresh clock, BURNER_FITTED freezes the clock and the ship reaches port, pausing after the outcome does nothing.
- Render check (`tools/shot.gd`): the ship's hull and lit windows read from the lamp room; at the crash the ship lies on the rock's east flank, listing.

**Correction, 29 Oct 2026:** the lamp-room sightline checks were first run from an eye height of 20.8 m, which is the tower landing below the lamp room. The lamp is at 29.1 m (`ANCHOR_lamp_stand` 27.5 plus 1.6); the test now uses that and still passes every lamp-room check.

## 5. Not verified

- Feel: whether 3 min 30 s with a ship at 4.4 m/s reads as urgent; whether the ship is easy enough to spot from the boat on the return crossing. Needs a play.
- The ship's lights at the real horizon (900 m): checked in stills at 150 m (lamp room) and 560 m (sea level), not yet at 900 m.
- Windows are placeholder discs on a grid, not placed against the model's real window rows.
- The break-up is a list-and-sink, not a split hull; the real break-up needs art (T08).
- Paused state has no on-screen cue (no UI by design); the mouse is released while paused.
- Pause exploits (B6) are not examined; nothing stops the player pausing between jobs on the return.
- The full `Level.tscn` was not re-run through the audio, foghorn or Failed screen (T08, T14 do not exist yet).

## 6. Licences and provenance

None new. The ship model is `Assets/Models/boat/passenger_ship.glb` (FAL, 26 Oct 2026, see the earlier handoff).

## 7. Interface or contract changes proposed

PROPOSED, none yet accepted:
- `GameState.deadline_progress()` and `GameState.deadline()` as the public deadline API.
- `ship.impact` and `ship.passed` signals for T08.
- No new event IDs. `LAMP_ROOM_REENTERED` is accepted (Decisions A17) but nothing emits it yet.

## 8. Open creator decisions

- **The grounding rock.** The GDD says "a rock right next to the island". The nearest existing sea stack is `SeaStack1`, about 80 m off the island's south shore and beside the player's return route. Is that near enough, or should a new rock be placed closer to the island (new art)?
- **The ship's lane.** East side of the island, so the lamp room, the dock and the return crossing all see it. Acceptable?
- **Deadline length and ship speed** are placeholders (210 s, 4.4 m/s); the final values come from playtests (B4).
- **Grounding time.** After the deadline the ship needs 13.6 s to strike (the commit distance, 60 m). T08 can time the foghorn, `TED_F_01` and the Failed screen on it, or the distance can be shortened.

## T44 update (1 Nov 2026): the ship lit properly

The floating sphere lights are gone. `passenger_ship.gd` now builds, from the `lights` block of `ship_route.json`:

- **Windows:** 188 small emissive panes laid flat on the model's own hull and superstructure. At load it casts rays at the mesh (about 0.25 s) for each row: two porthole rows in the black hull, the promenade and upper tier on both sides, and the superstructure's forward face, bridge and after face (so she shows lit windows bow-on). Panes that would sit on a post or lifeboat, or in a gap, are dropped, and some cabins are dark. Additive, fog-proof, and each pane grows in its own plane with distance (`grow_per_m`, `grow_max`) so the decks run together at range.
- **Navigation lights and lanterns:** white masthead lights on the fore (28.4 m) and aft (30.9 m) mast tops, red and green sidelights in the bridge-wing lanterns, a white stern light, and the two globe lanterns fore and aft lit as deck lamps. Each shows only in its real sector (masthead 225 deg ahead, sidelights 112.5 deg each side, stern 135 deg astern) and has a soft glow that grows with distance (`halo_per_m`, up to `halo_max_m`).
- **Spill:** two warm OmniLights just off the hull, live only while the camera is within 160 m (the launch near the crash), so they stay inside `max_dynamic_lights`.
- **Crash:** one `power` shader parameter fades every window and lamp with a flicker over `lights_out_s`; the spill fades with them.

Renders checked: side-on at 80 m, bow-on at 70 m, the lamp room at 150 m, sea level at 560 m, beacon relit, and the crash at 2, 12 and 30 s. Tests: test_ship_route, test_ship_deadline, test_outcome_screen, test_lampposts, test_slice_playthrough all OK.
