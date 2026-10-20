# Wave Creator Agent: work review

- Phase: **work_passed** | work review loops: 2 of 3
- Assessor: Waves - Assessment Agent

| ID | Score | Recorded | Checks | Title |
|---|---|---|---|---|
| WAV-01 | 10 | done | passing | Record the wave design workshop decisions (D1-D10 answered 2026-10-20) |
| WAV-02 | 10 | done | passing | Write the sea-state curve as data (wave_spec.json) from decisions D1, D5, D8, D9, D10 |
| WAV-03 | 10 | done | passing | Clear the canon gate: update canon.py, validators.py, schemas.py and world_canon.py so they no longer reject waves |
| WAV-04 | 9 | done | passing | Parameterise the sea by sea state, keeping wave_height() as the single source the shader and the boat share |
| WAV-05 | 9 | done | passing | Drive water_push from the sea state: set, drift and gust, never a new control |
| WAV-06 | 9 | done | needs_human | Prove the difficulty shape with a headless crossing test: easy outbound, hectic return |
| WAV-07 | 9 | done | passing | Add the waves on/off setting and the reduced hazard-intensity preset (multiplier 0.6) |
| WAV-08 | 8 | done | passing | Drive the sea from route position outbound and the deadline clock on the return, through GameState |
| WAV-09 | 8 | done | passing | Add sheltered zones: calm the water at both docks and in the lee of the island and quay (D7, D10) |
| WAV-10 | 8 | done | passing | Apply the crossing speed decision: 8 m/s held as data (D4) |
| WAV-13 | 8 | done | passing | Implement the wave-hit consequence: nothing outbound, slow-down and water in the boat on the return (D3) |
| WAV-11 | 7 | done | passing | Hand sea-state hooks to the Lighting and Sound agents and the island shoreline |
| WAV-14 | 7 | blocked | needs_human | Show the eclipse link in the sky as the return sea rises (D6) |
| WAV-12 | 6 | done | passing | Add QA scenarios with waves on and off |

## Feedback to the creator agent (act on every BLOCK without asking the user)

- none

## Needs the creator (decisions / in-editor checks)

- WAV-14: Confirm D6 is compatible with the 2026-10-16 supermoon decision: the moon dims or is covered on the return without showing the Flighted ship or explaining the eclipse. Recommendation: a dimming cloud-and-shadow cover only, no sphere visible yet.
- WAV-06: Creator plays outbound then return.
- WAV-14: Canon sign-off, then Lighting agent capture of the return.