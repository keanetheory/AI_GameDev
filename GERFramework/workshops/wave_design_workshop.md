# Wave and Tide Design Workshop

Owner: Wave Creator Agent. Reviewer: Waves - Assessment Agent. Status: **proposal, nothing built.**

This is a conversation, not a spec. The agent proposes, you decide. Nothing in the game changes until you answer and approve the plan.

## What exists today

| Fact | Where |
|---|---|
| The sea is a 2000 m plane at y = -2.25 with a vertex-shader wave. The wave shape lives in one function, `Sea.wave_height(x, z, t)`, mirrored by two shader lines. | `scripts/world/sea.gd` |
| The boat rides that surface (heave, pitch, roll) with `wave_follow` = 1.0. | `scripts/world/boat.gd` |
| `water_push` (Vector2, m/s) is added to the boat's velocity every physics frame. It is zero. This is the hook. | `scripts/world/boat.gd:41` |
| `waves_enabled` is false in the boat spec. | `data/world/boat_spec.json` |
| Waves and tides are unapproved in four crew files. | `canon.py`, `validators.py`, `schemas.py`, `world_canon.py` |
| Lore: the eclipse covers the moon, tides turn aggressive and storms begin. In storms waves can throw a ship off course and onto the rocks. | `sys_eclipse.md`, `geography.md` |
| GDD: waves are a stretch goal and the first thing cut; crossings must work without them; the reduced hazard-intensity preset must lower wave intensity; a wave hit costs no deadline time on the outbound. | Technical Strategy, Decisions 20 and 24 |
| Phases: ISLAND, OUTBOUND, RETURN, BEACON_RELIT, each with its own cloud, fog and hazard-visibility values. | `data/world/lighting_spec.json` |
| Route: 1,500 m each way. 3 m/s today (about 8 min per leg); the GDD says 10 m/s (2.5 min per leg). | `boat_spec.json`, Decision 24 |

## Your goal, restated

The first crossing (outbound to the Saltgate) is **easier and simpler**. The last crossing (the return, with the burner and the ship closing) is **more hectic and stormy**. Waves never add a control: you still only steer with A and D.

## Proposed sea states

One number, the sea state, drives wave height, speed, push and the weather. Sea state is smoothed over a few seconds so it never pops.

| State | Name | Wave height (m) | Wavelength (m) | Push on the boat (m/s, peak) | Gusts | Feel |
|---|---|---|---|---|---|---|
| 0 | Glass | 0.1 | 40 | 0 | none | waves off, or the island lee |
| 1 | Ripple | 0.35 | 35 | 0.0 | none | the sea moves for atmosphere only (today's look) |
| 2 | Swell | 0.7 | 45 | 0.15 | none | a slow lean, forgiving |
| 3 | Chop | 1.2 | 30 | 0.4 | rare | you notice the sea and correct |
| 4 | Heavy | 1.9 | 28 | 0.8 | regular | rocks matter; you fight the set |
| 5 | Storm | 2.8 | 24 | 1.3 | frequent | hectic; the safe route is still reachable but only just |

These numbers are guesses to start the conversation. Today's shader amplitude is about 0.35 m, which is state 1.

## Proposed curve across the story

| Phase | Start | End | Reasoning |
|---|---|---|---|
| ISLAND | 1 | 1 | atmosphere only; nothing to fight |
| OUTBOUND (first crossing) | 1 | 2 | easy and simple: a gentle swell builds in the last third, no gusts, no push strong enough to matter |
| At the Saltgate quay | 1 | 1 | sheltered lee; calm for the stepping-ashore moment |
| RETURN (last crossing) | 3 | 5 | builds from chop to storm as the deadline runs down; storm by the narrows under the island |
| Final approach, dock zones | fades to 2 | fades to 2 | docking must stay reliable even in a storm |
| BEACON_RELIT | 4 | 3 | the storm eases as the beacon comes on, if you want the relief |

## How a wave acts on the boat

1. **Heave, pitch and roll** (the boat rides the surface). Already built.
2. **Set**: a steady push in one direction that grows with state (the tide).
3. **Gusts**: short pulses at states 4 and 5.
4. **Broadside nudge**: a small sideways kick when a wave hits the side of the hull.

The push is always smaller than steering authority, so the safe route is never unreachable.

## Questions only you can answer

Reply to each, or say "defer". The agent records your answers under **Decisions** below.

1. **Curve.** Is the table above the right shape: outbound 1 to 2, return 3 to 5? Should the return reach 5 or stop at 4?
2. **Does the sea push the boat?** Heave and roll only (looks rough, steers the same), or also push (changes where you end up)? Proposal: both, with the push capped below your steering.
3. **What does a wave hit cost?** Nothing, a slow-down, water in the boat, or a capsize and recovery? The GDD says a broadside wave hit could cause a capsize-and-recovery at a safe point, and costs no deadline time on the outbound.
4. **Crossing speed.** The boat is 3 m/s (about 8 minutes per leg). GDD Decision 24 says 10 m/s (about 2.5 minutes per leg). Which is right? Wave period and the ramp are tuned to this.
5. **Tide timing.** Does the sea state ramp by route position (how far along the leg), by elapsed time, or by the hidden deadline clock on the return? Proposal: route position outbound, deadline clock on the return.
6. **Eclipse link.** The eclipse makes tides aggressive. Should the return's high sea state be explained by the eclipse (supermoon covered), shown in the sky, or left unexplained?
7. **Sheltered water.** Calm in the lee of the island and at the quay (the proposal), or one sea everywhere?
8. **Reduced preset.** The GDD's reduced hazard-intensity preset must lower waves. By one step (state 5 becomes 4), or by a multiplier (push and height times 0.6)?
9. **Outbound easy enough?** What is the worst you want a first-time player to experience on the way out?
10. **Return hectic enough?** What should the player feel and fear on the way back that they do not on the way out?

## Decisions

Session 1, 2026-10-20 (creator answers):

- D1: Curve accepted as proposed: ISLAND 1, OUTBOUND 1 to 2, quay 1, RETURN 3 to 5, dock zones fade to 2, BEACON_RELIT 4 to 3 (BEACON_RELIT not discussed; stays as proposed).
- D2: Visual plus push. Heave, pitch and roll, plus set and gusts through `water_push`. Push always stays below A/D steering authority.
- D3: A wave hit costs nothing on the outbound. On the return: a brief slow-down and water in the boat. No capsize.
- D4: Crossing speed 8 m/s, held as data (not hard-coded), to be confirmed after playtest. Replaces 3 m/s in `boat.gd` and `boat_spec.json` and differs from GDD Decision 24 (10 m/s): both need updating at execution. At 8 m/s a 1,500 m leg is about 188 s, so ramps are defined by route progress, not minutes.

- D5: Outbound sea state follows route position (how far along the leg). Return follows the hidden deadline clock.
- D6: Show the eclipse link in the sky: the heavy return sea is visibly tied to the moon being covered. Needs the Lighting agent, and touches the 2026-10-16 canon decision that the moon is a bright supermoon for now and the Flighted ship is added later. To confirm with the Canon and Review Orchestrator before it is built.
- D7: Sheltered zones: waves and push fade near the island dock and the Saltgate quay.
- D8: Reduced hazard-intensity preset multiplies push and wave height by 0.6.

- D9: Worst outbound experience: a lean and some spray. Slow swell in the last third, small push, no wave hit, steering never feels fought.
- D10: Return should feel like fighting the sea (a steady set you correct against), gusts and surprises (sudden shoves at states 4 to 5), and relief near the island (calm in its lee). Extra poor visibility from waves was not chosen: fog and rain stay as set by the Lighting agent per phase.

- D11 (2026-10-20, after first look): amp up the waves on both legs. Amplitude, time scale, push and gusts raised at states 2 to 5; outbound now eases 1 to 2.5 starting at 40% of the leg (was 1 to 2 from 60%); return unchanged at 3 to 5. State 5 is now 5.2x the original wave height and pushes 0.68 of boat speed at a gust peak.

Workshop complete, session 1. Not yet approved for build: the Wave plan is awaiting the creator's all clear.

## Hooks the other agents read (built contract)

- `Sea.state` (static float 0 to 5, smoothed) and the signal `sea_state_changed(state)` on the Sea node (`scripts/world/sea.gd`). Read only; WaveSystem sets the target.
- `Sea.local_state(x, z)`: the sea state at a point after dock shelter.
- `Sea.waves_enabled` (on/off) and `Sea.intensity` (1.0, or 0.6 for the reduced preset). Public setters: `WaveSystem.set_waves_enabled(bool)` and `WaveSystem.set_reduced_preset(bool)`.
- Boat: `boat.water_push` (driven by WaveSystem), `boat.water_in_boat` (0 to 1), signal `wave_hit(water)`.
- **Lighting agent** (owes WAV-14): rain, wind, fog and lightning rate follow `Sea.state`; the dimming cover over the supermoon on the return follows `Sea.state` from 3 to 5. Dimming cover only: no sphere, no eclipse explanation (creator, 2026-10-20).
- **Sound agent:** wave and wind layers follow `Sea.state`; a `wave_hit` plays the slap and the water-in-boat cue.
- **Island Creator Agent:** shoreline spray and wet rock follow `Sea.state`.
- Tuning lives in `data/world/wave_spec.json`; the crossing speed is `boat_spec.json speed_mps`.
