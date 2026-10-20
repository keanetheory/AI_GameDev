# Wave Creator Agent: prioritised plan

- Assessor: **Waves - Assessment Agent** (knowledge up to date)
- Phase: **awaiting_approval** | plan review loops used: 1 of 3
- Blocking findings left: **0**

**Mission:** Own the tides and waves as an independent system. Work with the creator to define and design how sea state changes across the crossings, then build it behind the existing water_push hook: the first crossing is easy and simple, the last is hectic and stormy, waves can be switched off, and nothing new is added to the one-control boat.

## Objectives (10 = absolute must)

| ID | Score | Objective | Needs you | Baseline today |
|---|---|---|---|---|
| WAV-01 | **10** | Record the wave design workshop decisions (D1-D10 answered 2026-10-20) |  | passing |
| WAV-02 | **10** | Write the sea-state curve as data (wave_spec.json) from decisions D1, D5, D8, D9, D10 |  | failing |
| WAV-03 | **10** | Clear the canon gate: update canon.py, validators.py, schemas.py and world_canon.py so they no longer reject waves |  | failing |
| WAV-04 | **9** | Parameterise the sea by sea state, keeping wave_height() as the single source the shader and the boat share |  | failing |
| WAV-05 | **9** | Drive water_push from the sea state: set, drift and gust, never a new control |  | failing |
| WAV-06 | **9** | Prove the difficulty shape with a headless crossing test: easy outbound, hectic return |  | failing |
| WAV-07 | **9** | Add the waves on/off setting and the reduced hazard-intensity preset (multiplier 0.6) |  | failing |
| WAV-08 | **8** | Drive the sea from route position outbound and the deadline clock on the return, through GameState |  | failing |
| WAV-09 | **8** | Add sheltered zones: calm the water at both docks and in the lee of the island and quay (D7, D10) |  | failing |
| WAV-10 | **8** | Apply the crossing speed decision: 8 m/s held as data (D4) |  | failing |
| WAV-13 | **8** | Implement the wave-hit consequence: nothing outbound, slow-down and water in the boat on the return (D3) |  | failing |
| WAV-11 | **7** | Hand sea-state hooks to the Lighting and Sound agents and the island shoreline |  | failing |
| WAV-14 | **7** | Show the eclipse link in the sky as the return sea rises (D6) | YES | decision pending |
| WAV-12 | **6** | Add QA scenarios with waves on and off |  | failing |

## Detail

### WAV-01 [10/10] Record the wave design workshop decisions (D1-D10 answered 2026-10-20)
GERFramework/workshops/wave_design_workshop.md proposes six sea states (0 calm to 5 storm), the per-crossing and per-phase curve (first crossing easiest, last crossing most stormy), what each parameter does, and the open questions that are the creator's to answer. Run it as a conversation, edit the proposal with the creator, and record each answer in the workshop file under 'Decisions' as lines '- D1: ...' to '- D10: ...' (the check counts them). DONE 2026-10-20: D1-D10 answered in the workshop file.

- Why this score: The creator asked to define and design the tides together; everything else is built from these decisions. Not 9 because no wave code should be written before them.
- Done when: every question in the workshop has a recorded answer or is explicitly deferred by the creator; the curve numbers are agreed
- Owner: Wave Creator Agent | works with: Creator
- Depends on: nothing
- Baseline evidence:
  - GERFramework/workshops/wave_design_workshop.md exists
  - GERFramework/workshops/wave_design_workshop.md: /^- D\d+:/ matched 10 (need >= 10)

### WAV-02 [10/10] Write the sea-state curve as data (wave_spec.json) from decisions D1, D5, D8, D9, D10
JSON laid out like boat_spec.json: sea states 0-5 (height, wavelength, speed, direction, gustiness, push peak, per the workshop table), a per-phase table (ISLAND 1, OUTBOUND 1 to 2 by route progress, quay 1, RETURN 3 to 5 by deadline clock, dock zones fade to 2, BEACON_RELIT 4 to 3), shelter zones, the reduced-preset multiplier 0.6, and the crossing speed 8 m/s as a data field. Every number is data. Outbound ramps by route position; return by the deadline clock.

- Why this score: It is the creator's stated intent made tunable. Not 9 because the whole system reads from it.
- Done when: wave_spec.json exists and validates; outbound maximum is state 2, below the start of the return (3); return reaches state 5 by the narrows under the island; reduced multiplier is 0.6 and speed is 8 m/s, both as data
- Owner: Wave Creator Agent | works with: World crew (Boat, Player Movement, Lighting)
- Depends on: WAV-01
- Baseline evidence:
  - LightingTheStorm/data/world/wave_spec.json is missing

### WAV-03 [10/10] Clear the canon gate: update canon.py, validators.py, schemas.py and world_canon.py so they no longer reject waves
canon.py says wave hazards are NOT approved; validators.py rejects 'wave' hazards; schemas.py has no wave hazard type; world_canon.py says waves are not part of the boat and waves_enabled must be false. Change them to the approved design from WAV-01 and keep waves_enabled as the switch. Also record the creator's decision in the GDD's Decisions log (Decision 20) and in Docs/Lore Build/world/changelog.md. Do not touch the GDD text without the creator's say-so.

- Why this score: Four files still say waves are an unapproved stretch goal and would block or contradict the new spec. Not 9 because the crews would reject every wave-related output until fixed.
- Done when: no AI Crew file contradicts the approved wave design; the offline crews still pass with waves enabled and disabled; Decision 20 is recorded
- Owner: Wave Creator Agent | works with: Canon and Review Orchestrator, Offline AI Crew
- Depends on: WAV-01
- Baseline evidence:
  - AIAgentCrew/canon.py: /NOT approved/ matched 1 (need >= 1 and <= 0)
  - AIAgentCrew/world_canon.py: /Waves are NOT approved/ matched 1 (need >= 1 and <= 0)

### WAV-04 [9/10] Parameterise the sea by sea state, keeping wave_height() as the single source the shader and the boat share
sea.gd keeps wave_height() and the matching two shader lines as the one place the wave shape lives. Add a sea-state input (amplitude, wavelength, speed, direction, choppiness) smoothed over a few seconds so state changes never pop. Keep the shader and wave_height() in step, as the file's own comment demands.

- Why this score: The boat already rides Sea.wave_height; making that one function depend on sea state makes the visible sea, the boat and the tide agree. Not 10 because the curve and decisions come first.
- Done when: Sea exposes a smoothed sea state; shader and wave_height() use the same parameters; no visible pop when the state changes
- Owner: Wave Creator Agent | works with: Boat / Physics agent
- Depends on: WAV-02
- Baseline evidence:
  - LightingTheStorm/scripts/world/sea.gd: /sea_state|amplitude/ matched 0 (need >= 1)
  - LightingTheStorm/scripts/world/sea.gd: /wave_height/ matched 4 (need >= 2)

### WAV-05 [9/10] Drive water_push from the sea state: set, drift and gust, never a new control
Compute water_push from the sea state (D2): a steady set growing with state, gusts at states 4 and 5, and a small broadside nudge. Outbound push is small (a lean, D9) and never causes a hit. On the return the set pushes toward the rocks and the player holds a correction (D10), but the push is always below steering authority so the safe route stays reachable.

- Why this score: The one-control promise holds and the hook exists for exactly this. Not 10 because it depends on the curve and the sea parameters.
- Done when: water_push is zero at sea state 0 and scales with state; with an average player's steering the safe route is always reachable at every state; no new input action is added
- Owner: Wave Creator Agent | works with: Boat / Physics agent
- Depends on: WAV-04
- Baseline evidence:
  - LightingTheStorm/scripts/world/boat.gd: /water_push/ matched 3 (need >= 2)
  - LightingTheStorm/scripts/world/boat.gd: /sea_state|Sea\.state/ matched 0 (need >= 1)

### WAV-06 [9/10] Prove the difficulty shape with a headless crossing test: easy outbound, hectic return
Extend tools/test_boat.gd into tools/test_wave_crossings.gd: a scripted steering bot with limited skill sails both legs at each sea state and records lateral drift, hazard hits and time off the safe line. Assert outbound hits stay at or near zero and return disturbance is meaningfully higher, with numbers printed. The creator then plays both legs and signs off the feel.

- Why this score: The creator's goal is a feel, so it must be measured: an unmeasured curve will drift. Not 10 because feel still needs a human playtest.
- Done when: tools/test_wave_crossings.gd exists and passes; outbound disturbance is below an agreed ceiling and return disturbance is above an agreed floor; creator signs off the feel
- Owner: Wave Creator Agent | works with: QA agent, Creator
- Depends on: WAV-05
- Baseline evidence:
  - LightingTheStorm/tools/test_wave_crossings.gd is missing
  - Creator plays outbound then return.

### WAV-07 [9/10] Add the waves on/off setting and the reduced hazard-intensity preset (multiplier 0.6)
One setting turns waves off (sea still moves for atmosphere, water_push zero). The reduced hazard-intensity preset multiplies push and wave height by 0.6 (D8). waves_enabled in boat_spec.json is the persistent switch.

- Why this score: GDD accessibility rules require the reduced hazard-intensity preset to lower wave intensity, and the crossing must work without waves. Not 10 because the base system comes first.
- Done when: waves off gives a fair crossing in the crossing test; reduced preset applies exactly 0.6 to push and height
- Owner: Wave Creator Agent | works with: Boat / Physics agent, QA agent
- Depends on: WAV-05
- Baseline evidence:
  - LightingTheStorm/data/world/boat_spec.json: /"waves_enabled"/ matched 1 (need >= 1)
  - LightingTheStorm/scripts/world/sea.gd: /waves_enabled|intensity/ matched 0 (need >= 1)

### WAV-08 [8/10] Drive the sea from route position outbound and the deadline clock on the return, through GameState
D5: OUTBOUND sea state follows route progress along the leg; RETURN follows the hidden deadline clock started by RETURN_DEPARTED, the same clock that sets lighting. Restart or reload restores sea state with elapsed time (GDD retry rule). Phase changes ISLAND, OUTBOUND, RETURN, BEACON_RELIT apply the D1 values with no pop.

- Why this score: The sea must follow the story: ISLAND calm, OUTBOUND gentle, RETURN building with the deadline. Not 9 because it depends on the curve and GameState already exists.
- Done when: sea state changes at phase boundaries with no pop; reload restores sea state with elapsed time
- Owner: Wave Creator Agent | works with: Gameplay / Systems agent, Lighting agent
- Depends on: WAV-02
- Baseline evidence:
  - LightingTheStorm/scripts/core/game_state.gd exists
  - LightingTheStorm/scripts/world/sea.gd: /GameState|phase/ matched 0 (need >= 1)

### WAV-09 [8/10] Add sheltered zones: calm the water at both docks and in the lee of the island and quay (D7, D10)
Fade water_push and wave height to about state 1-2 inside DockZoneLighthouse and DockZonePort and in the lee of the island and the quay. This gives the relief near the island on the return (D10) and keeps docking reliable at state 5. The fade must not read as a hard boundary.

- Why this score: Auto-docking is a promised mechanic and a storm return must never make the final approach impossible. Not 9 because it only matters once the push is strong.
- Done when: docking succeeds at every sea state in the crossing test; the fade is not visible as a hard boundary
- Owner: Wave Creator Agent | works with: Boat / Physics agent
- Depends on: WAV-05
- Baseline evidence:
  - LightingTheStorm/scripts/world/sea.gd: /dock_zone|DockZone|calm/ matched 0 (need >= 1)

### WAV-10 [8/10] Apply the crossing speed decision: 8 m/s held as data (D4)
Creator chose 8 m/s, as data, to be confirmed after playtest. Change boat_spec.json speed_mps and boat.gd speed to read it, update world_canon.py (which says 3 m/s is a confirmed decision), and propose a Decision 24 update for the GDD (it says 10 m/s) for the creator to approve; do not edit the GDD without their say-so. Re-check dock approach speed, collision recovery and the steering handling checks at 8 m/s, because turn rate and drift were tuned at 3 m/s.

- Why this score: It sets the crossing length (1,500 m takes 500 s at 3 m/s, 150 s at 10 m/s) and so the wave periods, the ramp and the deadline pressure. Not 9 because a default lets the workshop proceed.
- Done when: boat.gd, boat_spec.json and world_canon.py all say 8 m/s and read it from data; steering handling checks pass at 8 m/s; a Decision 24 update is proposed to the creator
- Owner: Wave Creator Agent | works with: Creator, Boat / Physics agent, Canon and Review Orchestrator
- Depends on: WAV-02
- Baseline evidence:
  - LightingTheStorm/data/world/boat_spec.json: /"speed_mps": 8/ matched 0 (need >= 1)

### WAV-13 [8/10] Implement the wave-hit consequence: nothing outbound, slow-down and water in the boat on the return (D3)
On the return, a broadside wave hit causes a brief speed loss and adds water to the boat; no capsize. Outbound wave hits cost nothing, and no wave hit costs deadline time on the outbound (GDD). Recovery uses the existing collision recovery path in boat.gd. Water in the boat is visual and audio feedback unless the creator later adds bailing.

- Why this score: It is the cost of a hit, so it defines how the return feels. Not 9 because the sea and push come first.
- Done when: outbound wave hit has no penalty; return wave hit slows the boat briefly and shows water in the boat; no new input is added
- Owner: Wave Creator Agent | works with: Boat / Physics agent, Sound agent
- Depends on: WAV-05
- Baseline evidence:
  - LightingTheStorm/scripts/world/boat.gd: /wave_hit|wave_penalty/ matched 0 (need >= 1)

### WAV-11 [7/10] Hand sea-state hooks to the Lighting and Sound agents and the island shoreline
Expose one signal (sea_state_changed) and one value (Sea.state) that the Lighting agent, the Sound agent and the Island agent's island_reactions.gd read. This agent does not edit their files. Include the eclipse-link value for WAV-14.

- Why this score: Waves only read if rain, wind, fog, lightning, surf and spray rise with them. Not 8 because the system is playable without it.
- Done when: signal and value exist and are documented in the workshop file; each receiving agent has acknowledged the contract
- Owner: Wave Creator Agent | works with: Lighting agent, Sound agent, Island Creator Agent
- Depends on: WAV-04
- Baseline evidence:
  - LightingTheStorm/scripts/world/sea.gd: /signal sea_state_changed/ matched 0 (need >= 1)

### WAV-14 [7/10] Show the eclipse link in the sky as the return sea rises (D6)
As the return's sea state rises the supermoon is visibly covered or dimmed, driven by the same deadline clock. This touches the 2026-10-16 decision that the moon is a bright supermoon for now and the Flighted ship that eclipses it is added later, so the Canon and Review Orchestrator must confirm it first, and the Lighting agent builds it. The Wave agent supplies only the sea-state signal.

- Why this score: The creator chose to show the cause visibly. Not 8 because it touches a canon decision and needs the Lighting agent. Not lower because it is a stated choice.
- Done when: Canon and Review Orchestrator has confirmed the visual does not settle open eclipse lore; the Lighting agent has built it from the sea-state signal
- Owner: Wave Creator Agent | works with: Lighting agent, Canon and Review Orchestrator, Creator
- Depends on: WAV-11
- Baseline evidence:
  - Canon sign-off, then Lighting agent capture of the return.
- **Decision for you:** Confirm D6 is compatible with the 2026-10-16 supermoon decision: the moon dims or is covered on the return without showing the Flighted ship or explaining the eclipse. Recommendation: a dimming cloud-and-shadow cover only, no sphere visible yet.

### WAV-12 [6/10] Add QA scenarios with waves on and off
List repeatable scenarios: each leg at each sea state, waves off, reduced preset, reload mid-return, dock at state 5. Write them in the QA scenario list. Add: outbound has no wave hits at any position; return hits slow the boat; speed 8 m/s; reduced preset 0.6.

- Why this score: The roster gives the QA agent 'checks with waves on and off'. Not 7 because it documents what WAV-06 and WAV-07 already test.
- Done when: scenario list exists and each scenario names its pass condition
- Owner: Wave Creator Agent | works with: QA agent
- Depends on: WAV-07
- Baseline evidence:
  - GERFramework/reports/wave_qa_scenarios.md is missing

## Questions for you

- **WAV-14**: Confirm D6 is compatible with the 2026-10-16 supermoon decision: the moon dims or is covered on the return without showing the Flighted ship or explaining the eclipse. Recommendation: a dimming cloud-and-shadow cover only, no sphere visible yet.

## Review history

### Loop 1 (2026-10-20T14:39:06+00:00)
- no findings
