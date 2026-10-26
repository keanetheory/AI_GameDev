# Lighthouse Finisher Agent: prioritised plan

- Assessor: **Lighthouse - Interior Assessment Agent** (re-read the docs (2 changed))
- Phase: **awaiting_approval** | plan review loops used: 1 of 3
- Blocking findings left: **0**

**Mission:** Finish the whole lighthouse, inside and out, to a realistic yet cel-shaded standard: no exterior mesh inside the interior, no rain indoors, consistent believable stairs, optimised geometry and polygon counts, real props, reset posters, a living boiler fire, and refined close-up walls.

## Objectives (10 = absolute must)

| ID | Score | Objective | Needs you | Baseline today |
|---|---|---|---|---|
| LHF-01 | **10** | Baseline audit and a fixed before/after shot set |  | needs_human |
| LHF-02 | **10** | Stop the exterior mesh showing inside the interior |  | passing |
| LHF-03 | **10** | No rain inside the lighthouse |  | needs_human |
| LHF-04 | **10** | One realistic stair standard, applied to every staircase |  | passing |
| LHF-05 | **10** | Boiler: living flames in place of the red slab |  | passing |
| LHF-06 | **9** | Geometry and polygon optimisation |  | passing |
| LHF-07 | **9** | Room-by-room rebuild of the poorly rendered rooms |  | needs_human |
| LHF-08 | **9** | Replace greybox props with real models or well-made procedural props | YES | decision pending |
| LHF-09 | **9** | Reset the Flighted posters | YES | decision pending |
| LHF-10 | **9** | Cel-shaded look for the whole lighthouse | YES | decision pending |
| LHF-11 | **8** | Exterior walls: close-up realism | YES | decision pending |
| LHF-12 | **8** | Windows, doors and thresholds: one consistent opening kit |  | needs_human |
| LHF-13 | **8** | Lamp room and gallery finish |  | needs_human |
| LHF-14 | **8** | Per-room lighting and materials pass |  | needs_human |
| LHF-15 | **7** | Architectural trim: ceilings, floors, skirting, cornices, joists |  | needs_human |
| LHF-16 | **7** | Regression: every lighthouse test stays green |  | needs_human |
| LHF-17 | **6** | Offline asset and canon checks, and the assessors' final score |  | needs_human |
| LHF-18 | **5** | Handoff, changelog and fallbacks |  | needs_human |

## Detail

### LHF-01 [10/10] Baseline audit and a fixed before/after shot set
Measure the exterior GLB, the v3 greybox and the code-built interior: triangles, meshes, draw calls, materials, texture sizes, node count per room (tools/measure_load_time.gd, tools/inspect_lighthouse.gd and `ger.py audit`). Record a fixed camera shot set with tools/shot_scene.gd: every room, the stairwell at four heights, the lamp room, the door from outside, and four close-ups of the tower and house walls. Write GERFramework/reports/lighthouse_finisher_baseline.md and keep the PNGs for the final comparison.

- Why this score: Every later score is judged against it; without a baseline 'looks better' is opinion. Not 9 because it changes nothing in the game itself.
- Done when: baseline report with per-room triangle and draw-call counts; fixed shot list with images saved; every existing lighthouse test result recorded as the green baseline
- Owner: Lighthouse Finisher Agent | works with: Lighthouse - Exterior Assessment Agent, Lighthouse - Interior Assessment Agent, QA agent
- Depends on: nothing
- Baseline evidence:
  - Verified by the headless tests and fixed-camera shots named in the acceptance list.

### LHF-02 [10/10] Stop the exterior mesh showing inside the interior
Find every exterior (and island) triangle that sits inside the interior volume. The probes tools/probe_shards.gd, probe_tower_intruders.gd and probe_shell.gd already exist; extend them into a repeatable audit across all rooms and the stairwell. Fix by baking: carve the intruders out with the existing carve_oriented_any / carve_cylinders_any (collider_builder), or split the exterior into an outer skin plus a clean inner liner, so the interior is lined by interior geometry only. tower_radii.json and the window data stay the single sources for the wall profile. The exterior silhouette from outside must not change (compare shots). Throughout, the interior must still match the exterior model: floors, footprint and the measured door stay on the greybox alignment JSON values.

- Why this score: Named by the creator. Exterior triangles inside rooms break every view in the building. Not 9: it ruins the first thing the player sees indoors.
- Done when: probe reports zero exterior triangles inside any interior volume; exterior silhouette from outside unchanged against the baseline shots; test_interior_walk and test_spiral_down still pass; interior footprint still fits inside the exterior walls (match the exterior model's alignment JSON)
- Owner: Lighthouse Finisher Agent | works with: Lighthouse - Exterior Assessment Agent, Lighthouse Interior Creator Agent, Lighthouse - Interior Assessment Agent
- Depends on: nothing
- Baseline evidence:
  - LightingTheStorm/tools/probe_shards.gd exists

### LHF-03 [10/10] No rain inside the lighthouse
Find the rain emitter (scripts/world/lighting_rig.gd, wave_system.gd and the weather settings) and make it indoor-aware: rain follows the player but is suppressed, faded or clipped while the player is inside the lighthouse volume (zone_trigger.gd Area3D zones already exist), with a short fade at the door, and still visible through open windows and the lamp-room glass. Optional storm detail: a few drips from window sills, with the Sound agent adding the matching emitters. Never raise the dynamic-light or particle budget.

- Why this score: Named by the creator. Rain through a roof is the loudest 'unfinished' signal in the building. Not 9: it shows from the first step inside.
- Done when: headless test: zero rain particles inside the interior volume at maximum storm; rain still falls outside, and at the open door threshold it fades rather than pops; rain stays correct in every phase
- Owner: Lighthouse Finisher Agent | works with: Lighting agent, Sound agent, QA agent
- Depends on: nothing
- Baseline evidence:
  - Verified by the headless tests and fixed-camera shots named in the acceptance list.

### LHF-04 [10/10] One realistic stair standard, applied to every staircase
Write one stair spec (rise about 0.18 m, going about 0.26 m, nosing, 2.0 m minimum headroom, handrail only where the style needs it) in a data file, and a stair builder every staircase uses: the tower spiral, the basement spiral (spiral_down.gd), the house stairs and landing steps. Real stonework: solid wedge treads that bear into the wall, worn nosings and dips, a central newel or open eye, chamfered edges, landing windows. One continuous mesh per step is kept; collision stays smooth enough to walk. Keep the measured tower radius table.

- Why this score: Named by the creator: the steps are inconsistent and unrealistic. Not 9: stairs are walked on every run of the loop.
- Done when: every staircase step rise and going within 5 percent of the spec, measured by a test; headroom at least 2.0 m the full length of every stair; a stair walk test goes up and down every staircase without catching; shots of every staircase against the concept art
- Owner: Lighthouse Finisher Agent | works with: Lighthouse Interior Creator Agent, Lighthouse - Interior Assessment Agent, Level Layout agent, QA agent
- Depends on: nothing
- Baseline evidence:
  - LightingTheStorm/scripts/world/interior/tower_shell.gd exists

### LHF-05 [10/10] Boiler: living flames in place of the red slab
Replace the glow quad (coal_job.gd fire_glow, the firebox door glow) with a cel-shaded fire: a firebox ember bed (stepped emissive coals), 3-4 layered flame cards with a scrolling, stepped-alpha flame shader (or a small GPUParticles3D inside budget), a flickering OmniLight3D with a toon-stepped flicker, drifting sparks and a little heat shimmer at the door. The fire reads low before coal, grows with each of the six loads (existing coal_job states) and is full when the dynamo runs. Keep the node names the coal job drives. Hand the crackle emitter anchor to the Sound agent.

- Why this score: Named by the creator. The boiler is the first hands-on job; a red slab undercuts it. Not 9: the player watches this fire every crossing.
- Done when: no flat red slab remains; the flames move in the shots; fire intensity follows the coal job loads 0 to 6; light count and budget unchanged (test_interior_budget passes); test_coal_job passes
- Owner: Lighthouse Finisher Agent | works with: Lighting agent, Sound agent, Gameplay / Systems agent, Asset agent
- Depends on: nothing
- Baseline evidence:
  - LightingTheStorm/scripts/world/interior/coal_job.gd exists

### LHF-06 [9/10] Geometry and polygon optimisation
Using the LHF-01 baseline: remove hidden faces (backs of boxes against walls, floors under floors), merge static meshes per room by material, use MultiMesh for repeated props (barrels, crates, books, balusters), share materials, set visibility ranges and room-level culling, keep collision to simple shapes, decimate any FAL mesh over budget. Set a triangle and draw-call budget per room and for the whole lighthouse and report before/after.

- Why this score: Named by the creator. A cheaper building is what lets the extra detail fit. Not 10: it supports the look rather than fixing a visible fault.
- Done when: per-room budget set and met; draw calls and triangles lower than the baseline with no visible loss; load time not worse than the baseline (measure_load_time)
- Owner: Lighthouse Finisher Agent | works with: Lighthouse Interior Creator Agent, Asset agent, QA agent
- Depends on: nothing
- Baseline evidence:
  - LightingTheStorm/tools/test_interior_budget.gd exists

### LHF-07 [9/10] Room-by-room rebuild of the poorly rendered rooms
Score each room against the Interior Plan V4 and the concept art with a rubric (surfaces, trim, dressing, lighting, scale, story read), then rebuild from the lowest score: basement, boiler room, coal store, entry vestibule and hallway, keeper's office, storage room, keeper's quarters (L1), control landing (L2), tower stair landings, lamp room. Each room ends with 3 hero shots and a score of at least 7.

- Why this score: Named by the creator: some rooms are poorly rendered. Not 10: depends on LHF-02, 04 and 08 landing first.
- Done when: rubric table for every room written to reports; every room scores 7 or more in the assessor's re-score; 3 hero shots per room saved
- Owner: Lighthouse Finisher Agent | works with: Lighthouse Interior Creator Agent, Lighthouse - Interior Assessment Agent, Asset agent, Lighting agent, Level Layout agent
- Depends on: nothing
- Baseline evidence:
  - Verified by the headless tests and fixed-camera shots named in the acceptance list.

### LHF-08 [9/10] Replace greybox props with real models or well-made procedural props
List every prop in rooms_house.gd and rooms_tower.gd that is still a primitive box or cylinder (beds, desk, shelves, chart table, stove, tub, crates, barrels, coats, tools, books, paperwork). First reuse the models already in Assets/Models/prop (lhi_boiler, lhi_arc_lamp, lhi_coal_shovel, lhi_flighted_poster, the burner models) where they fit, then build the rest as cheap bevelled or lathed procedural meshes with proper materials. Where a FAL model is truly better, write the submission and run only `main_asset.py --check-only`; real generation waits for the creator. 2048 texture rule applies; collision boxes and interaction anchors are kept.

- Why this score: Named by the creator: some props are basic greybox. Not 10: FAL generation costs credits and needs the creator's go-ahead.
- Done when: no primitive-box furniture left in any room; new .glb files have the import script set and 2048 textures; anchors and collision unchanged (test_interior_anchors passes)
- Owner: Lighthouse Finisher Agent | works with: Asset agent, Lighthouse Interior Creator Agent, Canon and Review Orchestrator
- Depends on: nothing
- Baseline evidence:
  - Verified by the headless tests and fixed-camera shots named in the acceptance list.
- **Decision for you:** May I run real FAL generation (costs credits) for props where procedural meshes are not good enough, or stay with reused models and procedural props only?

### LHF-09 [9/10] Reset the Flighted posters
Remove the current posters (rooms_house.gd _poster; poster.gd stays as the interaction) and rebuild: crude black, silver and navy letterpress on aged paper (prompts in Docs/Lore Build/factions/fac_flighted.md), a dark sphere eclipsing a silver moon over waves, the slogans THEY BRING THE STORMS and THEY CHANGE THE SEASONS, three sizes (0.72 x 1.0 m base), pasted with torn corners, wheat-paste drips, curl and overlap, decal depth so nothing z-fights, placed where the sightlines make the player see them. Use the lhi_flighted_poster model or a decal with a hand-made texture. Ask the creator if the poster count or placement should differ.

- Why this score: Named by the creator. Posters are the canon dread in the entry. Not 10: they are small, but they are the first lore the player reads.
- Done when: old posters removed; posters match the canon faction brief, with no retired brand text; no z-fighting at any viewing angle; poster interaction still works
- Owner: Lighthouse Finisher Agent | works with: Asset agent, Canon and Review Orchestrator, Lighthouse Interior Creator Agent, Lighthouse - Interior Assessment Agent
- Depends on: nothing
- Baseline evidence:
  - Verified by the headless tests and fixed-camera shots named in the acceptance list.
- **Decision for you:** How many posters, where, and any slogans beyond the two canon lines? Should they stay readable up close (legible text) or be pure graphic?

### LHF-10 [9/10] Cel-shaded look for the whole lighthouse
Agree one toon look with the Lighting agent so interior and exterior match: stepped light ramp, a restrained ink outline on large silhouettes and props (none on fine stonework), the desaturated stone palette from the style guide with amber and gold accents, painted-grain textures. Build it as one shared material set (interior kit.gd and the exterior) and a before/after sample for the creator to approve before applying everywhere.

- Why this score: Named by the creator: realistic yet cel-shaded. The look decision is the creator's. Not 10: it multiplies the others rather than fixing a fault.
- Done when: the creator signs off a sample room; interior and exterior share the same toon ramp; performance not worse than the baseline
- Owner: Lighthouse Finisher Agent | works with: Lighting agent, Asset agent, Lighthouse - Exterior Assessment Agent
- Depends on: nothing
- Baseline evidence:
  - Verified by the headless tests and fixed-camera shots named in the acceptance list.
- **Decision for you:** Approve the toon look sample (ramp steps, outline weight, palette) before it is applied to the whole lighthouse.

### LHF-11 [8/10] Exterior walls: close-up realism
From the baseline close-ups: add close-range stone detail (a triplanar stone, mortar and weathering overlay, a height or normal map, a streak and salt-stain mask) blended in only within a few metres, bevel and reveal the window and door openings, add the stringcourses, lintels, sills and base plinth the concept art shows, clean stretched or smeared texture areas. Keep the silhouette and the 2048 texture. If the baked texture is the problem, regenerating the exterior with FAL costs credits and stays the creator's call.

- Why this score: Named by the creator. Not 9: the exterior reads from the sea; the close-up only matters at the door and walkway.
- Done when: close-up shots of tower and house walls show mortar, bevel and weathering; the silhouette at distance matches the baseline; exterior mesh_audit passes
- Owner: Lighthouse Finisher Agent | works with: Lighthouse - Exterior Assessment Agent, Asset agent, Lighting agent
- Depends on: nothing
- Baseline evidence:
  - lighthouse_exterior_v3.glb: 7.69 MB, 39,978 tris, 1 meshes (empty 0, unreferenced 0), hole loops 0 (open edges 0.0%), degenerate 0, textures [[2048, 2048]] (~22.3 MB VRAM)
- **Decision for you:** If painted close-up detail cannot fix the exterior walls, do you want the exterior regenerated with FAL (credits), or kept as the v3 baked texture with overlays only?

### LHF-12 [8/10] Windows, doors and thresholds: one consistent opening kit
Make every opening share a kit that reads the same from both sides: stone reveals with thickness matching the wall, sills and lintels, iron mullions and believable glass, door frame, threshold stone and the door. Driven by data/world/lighthouse_windows.json and the bake tools.

- Why this score: Openings are where inside meets outside, and where the two models currently disagree. Not 9: only eight windows plus the door.
- Done when: all eight windows and the main door use the kit from both sides; no gap, light leak or see-through between wall and frame; test_sightlines still passes
- Owner: Lighthouse Finisher Agent | works with: Lighthouse Interior Creator Agent, Lighthouse - Exterior Assessment Agent, Lighting agent
- Depends on: nothing
- Baseline evidence:
  - Verified by the headless tests and fixed-camera shots named in the acceptance list.

### LHF-13 [8/10] Lamp room and gallery finish
Finish the lantern room: Fresnel lens bands, the arc lamp, iron glazing bars, gallery rail and floor, a clear view over the landscape, a lit-beacon look with the Lighting agent. Keep the LampSocket and the Lens_* node names the lamp scripts use.

- Why this score: The end of the crossing loop must look like a payoff. Not 9: it is visited once per loop.
- Done when: test_lamp_fit passes; lens, glass and rail shots against concept art; view is unobstructed to the ship route and island rock
- Owner: Lighthouse Finisher Agent | works with: Lighting agent, Asset agent, Gameplay / Systems agent
- Depends on: nothing
- Baseline evidence:
  - Verified by the headless tests and fixed-camera shots named in the acceptance list.

### LHF-14 [8/10] Per-room lighting and materials pass
With the Lighting agent: per-room light plans (amber lamps, cold window light, firelight), light cards and emissive materials in place of extra dynamic lights, correct for every phase, never exceeding the interior light budget.

- Why this score: Light sells the dread and the dynamic-light budget is hard. Not 9: the Lighting agent owns the rig; the finisher only tunes room kit.
- Done when: test_interior_lights and test_interior_budget pass; each room's light reads in ISLAND, OUTBOUND, RETURN and BEACON_RELIT
- Owner: Lighthouse Finisher Agent | works with: Lighting agent, QA agent
- Depends on: nothing
- Baseline evidence:
  - Verified by the headless tests and fixed-camera shots named in the acceptance list.

### LHF-15 [7/10] Architectural trim: ceilings, floors, skirting, cornices, joists
Add beams and joists that respect the stairwell, stained ceiling plaster, skirting boards, door and window architraves, floor board or flagstone layouts per room, chimney breast and flue, stove pipes, cables and pipes in the basement.

- Why this score: Trim is what makes a room read as built rather than boxed. Not 8: no gameplay effect.
- Done when: each room has ceiling, skirting and a floor pattern; no joist crosses the stairwell
- Owner: Lighthouse Finisher Agent | works with: Lighthouse Interior Creator Agent, Lighthouse - Interior Assessment Agent
- Depends on: nothing
- Baseline evidence:
  - Verified by the headless tests and fixed-camera shots named in the acceptance list.

### LHF-16 [7/10] Regression: every lighthouse test stays green
Run test_interior_walk, test_spiral_down, test_coal_job, test_lamp_fit, test_interior_anchors, test_interior_lights, test_interior_budget, test_sightlines, test_door and every new stair, rain and fire test after each objective and again at the end. Add a visual regression: fixed cameras, fail on black areas or missing floor.

- Why this score: The finish must not break the walk, the coal job or the lamp fit. Not 8: the other objectives' acceptance also enforces it.
- Done when: all tests pass at the end; visual regression passes
- Owner: Lighthouse Finisher Agent | works with: QA agent, Lighthouse Interior Creator Agent, Lighthouse - Interior Assessment Agent
- Depends on: nothing
- Baseline evidence:
  - Verified by the headless tests and fixed-camera shots named in the acceptance list.

### LHF-17 [6/10] Offline asset and canon checks, and the assessors' final score
Run `main_asset.py <submission> --check-only` on every new submission and the Canon and Review Orchestrator offline, then ask both assessors for a final score against the baseline.

- Why this score: Closes the loop with the crew. Not 7: advisory.
- Done when: offline checks recorded; both assessors have re-scored with zero BLOCK
- Owner: Lighthouse Finisher Agent | works with: Canon and Review Orchestrator, Asset agent, Lighthouse - Exterior Assessment Agent, Lighthouse - Interior Assessment Agent
- Depends on: nothing
- Baseline evidence:
  - Verified by the headless tests and fixed-camera shots named in the acceptance list.

### LHF-18 [5/10] Handoff, changelog and fallbacks
Keep v-numbered fallbacks of everything overwritten, write GERFramework/reports/lighthouse_finisher_work.md (what changed, what only the Godot editor can verify), and update the Lighthouse Agent Crew task list.

- Why this score: Keeps the work recoverable. Not 6: housekeeping.
- Done when: fallbacks exist; work report written
- Owner: Lighthouse Finisher Agent | works with: Lighthouse Interior Creator Agent
- Depends on: nothing
- Baseline evidence:
  - Verified by the headless tests and fixed-camera shots named in the acceptance list.

## Questions for you

- **LHF-08**: May I run real FAL generation (costs credits) for props where procedural meshes are not good enough, or stay with reused models and procedural props only?
- **LHF-09**: How many posters, where, and any slogans beyond the two canon lines? Should they stay readable up close (legible text) or be pure graphic?
- **LHF-10**: Approve the toon look sample (ramp steps, outline weight, palette) before it is applied to the whole lighthouse.
- **LHF-11**: If painted close-up detail cannot fix the exterior walls, do you want the exterior regenerated with FAL (credits), or kept as the v3 baked texture with overlays only?

## Review history

### Loop 1 (2026-10-24T16:32:13+00:00)
- no findings
