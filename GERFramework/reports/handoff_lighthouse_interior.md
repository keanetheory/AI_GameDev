# Handoff: the lighthouse interior, for the Gameplay, Lighting, Sound and Asset agents (2026-10-20)

From the Lighthouse Interior Creator Agent. What exists, what each hook does, and what is still yours.

## What the interior now provides

| Thing | Where | Behaviour |
|---|---|---|
| Rooms and props | `scripts/world/interior_rooms.gd` (node `InteriorRooms`), built from `scripts/world/interior/` | built at load in ~260 ms; kit in `kit.gd` |
| Coal job (T33) | `coal_job.gd`, `coal_pile.gd`, `firebox_hatch.gd`, `boiler_gauge.gd` | `[E] Shovel coal` at the heap (empty hands), `[E] Shovel the coal into the firebox` at the firebox; six loads (`loads_needed` on the `CoalJob` node); events COAL_LOADED_FIRST, COAL_LOADED_HALF, BOILER_FED; the gauge, fire glow and light rise, the flywheel turns, the switchboard lamp goes green |
| Burner fit (T32) | `lamp_socket.gd`, `lamp_beacon.gd` | `[E] Fit the burner into the lamp` only while the burner is in hand; keeps the burner; fires BURNER_FITTED once; the lamp lights over 3.5 s and a beam sweeps |
| Posters | `poster.gd` | `[E] Read the poster` on the Flighted posters fires POSTER_EXAMINED |
| Entry events | `zone_trigger.gd` | LIGHTHOUSE_ENTERED (hall), ENGINE_ROOM_ENTERED (foot of the basement stairs) |
| Wall voids | `LHI_WallVoid_*` markers, group `lhi_wall_void`, zones `Zone_*WallVoid*` | WALL_WHISPER_HEARD (hall), BASEMENT_BANG (after BOILER_FED), BASEMENT_TALK (after DANIEL_IN_BASEMENT) |
| Lights | `interior_lights.gd` | `adopt()` takes the furnished rooms' lights under the budget (at most 6 lit, 2 shadowed); a light with meta `flicker` wobbles |
| Anchors | `interior_anchors.gd` (markers `LHI_Anchor_<role>`, group `lhi_anchor`) | the v3 roles plus `l1_landing`, `l1_hall`, `l1_quarters`, `l1_radio`, `l1_mess`, `l1_ring`, `l2_landing`, `l2_control`, `l2_instruments`, `lamp_stand`, `lamp_socket`, `shovel_rack`; `boiler_interaction`, `coal_pickup`, `daniel`, `arc_lamp_socket` and `burner_fit` moved to suit the new layout |

Tests (all headless, `Godot --headless --path . --script res://tools/<name>.gd`): `test_interior_walk` (the real player walks to every room), `test_sightlines`, `test_interior_lights`, `test_interior_anchors`, `test_interior_budget`, `test_lamp_fit`, `test_coal_job`.

## Still yours

- **Gameplay / Systems agent**: T05 (Ted opens the lamp: BEACON_STILL_DARK, LAMP_ROOM_ENTERED, BURNER_DIAGNOSED, BURNER_BRIEFING are not fired by anything yet; `LHI_Anchor_ted_lantern` and `lamp_socket` are the places), T04 (the window moment: the tower landing window `window_tower_eye` sees the rowboat arriving at `rowboat_sighting`; the berth itself is hidden from every window), SHIP_WIN after the fit (T08).
- **Lighting agent**: the beacon's final look (T13): `lamp_beacon.gd` exports the rise time, sweep speed, beam length and energies; the interior's warm lights and the first floor's mood; the dark walkway.
- **Sound agent**: dynamo hum at the engine room (`B_Dynamo`), the stove, the wall-void markers, footsteps on timber, flags and iron.
- **Asset agent**: textures (everything is procedural colour and noise), poster art (canon: black, silver and navy, a dark sphere eclipsing a silver moon), the boiler and engine, props at concept-art density.

## Known limits

- L2 is a landing ring in the tower, not a house floor: the house roof leaves no headroom above y 6.9.
- The foundation chamber under the tower is not built (needs a carve in the island collider; no story use).
- The shovel's pose in the hands was set by eye; check it in the editor.
