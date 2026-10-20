# Lighthouse Interior Creator Agent: prioritised plan

- Assessor: **Lighthouse - Interior Assessment Agent** (knowledge up to date)
- Phase: **awaiting_approval** | plan review loops used: 2 of 3
- Blocking findings left: **0**

**Mission:** Know lighthouse design and interior layout, and turn the current greybox into an interior that matches the exterior model's real dimensions and the Interior Plan V4 blueprint: the basement engine level, ground-floor entry and workspaces, keeper's quarters, control and diagnostics level, and the lantern room, linked by a walkable route and the two GDD sightlines.

## Objectives (10 = absolute must)

| ID | Score | Objective | Needs you | Baseline today |
|---|---|---|---|---|
| LHI-01 | **10** | Amend the greybox so it fits the exterior model's measured dimensions (greybox v4) |  | failing |
| LHI-02 | **10** | Build the slice-critical rooms from the blueprint: entry vestibule and hallway, stairs down, boiler room, tower stair, lantern room |  | failing |
| LHI-03 | **10** | Prove the interior route is walkable: collision, headroom, step height, no blocked doors |  | failing |
| LHI-04 | **9** | Prove the two GDD sightlines: the window to the dock and rowboat, and the lamp room to the ship route and island rock |  | needs_human |
| LHI-05 | **9** | Apply real lighthouse design to the interior: tapering walls, spiral stair with landing windows, lantern gallery, service levels below |  | failing |
| LHI-06 | **8** | Fit the interior lights inside the dynamic-light budget, with the Lighting agent |  | failing |
| LHI-07 | **8** | Add interaction anchors and set dressing markers: boiler, coal, door, window, arc lamp, burner socket, posters |  | failing |
| LHI-08 | **8** | Decide how far the upper floors go for the prototype: walk-through shells or sealed floors with stair landings | YES | decision pending |
| LHI-11 | **8** | Compare the interior to the blueprint and the lighthouse concept art, and run the offline canon and asset checks |  | failing |
| LHI-09 | **7** | Build the remaining blueprint rooms as greybox: keeper's quarters, control level, workshop, stores, foundation chamber, left hut, right annex |  | needs_human |
| LHI-10 | **6** | Place the crawlspace and wall voids for the whispers and bangs, as sound sources only |  | failing |

## Detail

### LHI-01 [10/10] Amend the greybox so it fits the exterior model's measured dimensions (greybox v4)
Read the v3 alignment JSON (scale 34.30 from the original GLB, tower centre (3.5, 3.6), main house centre (-3.73, 4.89) and long axis, ground floor y 0.97, basement floor y -2.0, lantern floor y 17.9, measured entry door at (-3.494, 0.97, 8.874) with its normal) and the exterior mesh. Build lighthouse_greybox_v4.glb plus a v4 alignment JSON: wall thickness tapering up the tower, the house footprint inside the exterior shell, the door opening matching the measured door, and floors at the measured heights. Fix what the v3 alignment file itself warns about: the exterior mesh has a solid house-to-tower wall that needs carving or collision regeneration, so the route from house to tower is not walkable yet. Keep v3 as the safe fallback.

- Why this score: Named a must by the creator; every other interior objective stands on a footprint that actually fits inside the exterior walls. Not 9 because a misfit is invisible until the player walks into a wall or out through one.
- Done when: lighthouse_greybox_v4.glb and its alignment JSON exist; every interior wall lies inside the exterior shell with a stated margin; the entry door opening matches the measured door within tolerance; v3 is kept unchanged
- Owner: Lighthouse Interior Creator Agent | works with: Lighthouse - Exterior Assessment Agent, Level Layout agent
- Depends on: nothing
- Baseline evidence:
  - LightingTheStorm/Assets/Models/lighthouse/interior/lighthouse_greybox_v4.glb is missing
  - LightingTheStorm/Assets/Models/lighthouse/interior/lighthouse_greybox_v4_alignment.json is missing
  - lighthouse_greybox_v3.glb: 0.12 MB, 4,480 tris, 184 meshes (empty 0, unreferenced 0), hole loops 0 (open edges 0.0%), degenerate 8, textures [] (~0.0 MB VRAM)

### LHI-02 [10/10] Build the slice-critical rooms from the blueprint: entry vestibule and hallway, stairs down, boiler room, tower stair, lantern room
From the Interior Plan V4 blueprint: G entry vestibule, hallway (posters and documents) and stairs down to the basement; B1 boiler room (shovel coal here), coal store, steam engine and dynamo; the tower stair (spiral) up to L3; L3 lantern gallery, arc lamp (broken at start) and maintenance space. Build to the blueprint's relative sizes and adjacencies, scaled to the v4 footprint, in greybox with clear volumes and doorways. Anything the blueprint does not show is marked as an addition for the creator to approve.

- Why this score: These are the rooms the GDD beats use: Ted opens the door, the coal job in the boiler room, the tower climb, the lantern diagnosis and the burner fit. Not 9 because without them the slice cannot be played.
- Done when: each listed room exists in the v4 greybox and matches the blueprint adjacency; the coal-to-lantern route is continuous; additions beyond the blueprint are listed
- Owner: Lighthouse Interior Creator Agent | works with: Level Layout agent, Gameplay / Systems agent
- Depends on: LHI-01
- Baseline evidence:
  - LightingTheStorm/Assets/Models/lighthouse/interior/lighthouse_greybox_v4.glb is missing
  - Compare each room against the blueprint legend.

### LHI-03 [10/10] Prove the interior route is walkable: collision, headroom, step height, no blocked doors
Generate collision for the v4 greybox (box or convex per part, not one giant trimesh). Write tools/test_interior_route.gd that walks the Player capsule door to hall to basement to tower stair to lantern room and fails on any block. Respect the player movement spec: step-up 0.4 m, floor angle 60 degrees; stair rise and run must fit inside it with headroom for the camera.

- Why this score: A blocked route stops the slice and the v3 alignment file says it is not certified walkable. Not 9 because the player cannot proceed at all if it fails.
- Done when: tools/test_interior_route.gd exists and passes headless 8 of 8 runs; stair rise <= step-up limit; every doorway clears the capsule and camera
- Owner: Lighthouse Interior Creator Agent | works with: Experience (Player Movement + QA agents)
- Depends on: LHI-02
- Baseline evidence:
  - LightingTheStorm/tools/test_interior_route.gd is missing
  - Run the route test and walk it.

### LHI-04 [9/10] Prove the two GDD sightlines: the window to the dock and rowboat, and the lamp room to the ship route and island rock
Place a window in the right room facing the dock and the rowboat mooring, and lamp-room windows all around with one view on the rock where the ship passes or crashes. Verify with a ray or camera check from the player eye height, in the v4 greybox in Level.tscn.

- Why this score: GDD decisions 22 and 26 make these load-bearing for two story beats and the fail presentation. Not 10 because the route (LHI-03) must exist first.
- Done when: from the window position a ray reaches the rowboat mooring unobstructed; from the lamp room a ray reaches the ship-route rock unobstructed
- Owner: Lighthouse Interior Creator Agent | works with: Level Layout agent
- Depends on: LHI-03
- Baseline evidence:
  - Run the sightline check and look from both windows in Godot.

### LHI-05 [9/10] Apply real lighthouse design to the interior: tapering walls, spiral stair with landing windows, lantern gallery, service levels below
Walls thick at the base and thinner at the top; a spiral stair around the tower core with a landing and small window every few turns; the lantern room on top with a surrounding gallery and a door onto it; engine, coal and stores below the entry floor; keeper's living space and the control level between. Record each design choice against the blueprint so the creator can see what is real-world lighthouse practice and what is from the plan.

- Why this score: The creator asked for an agent that knows lighthouse design. Not 10 because the greybox is a blockout and realism is secondary to the route.
- Done when: a design note maps each choice to the blueprint or to lighthouse practice; stair has landings and windows at regular heights
- Owner: Lighthouse Interior Creator Agent | works with: Lighthouse - Exterior Assessment Agent
- Depends on: LHI-02
- Baseline evidence:
  - GERFramework/reports/lighthouse_interior_design_notes.md is missing

### LHI-06 [8/10] Fit the interior lights inside the dynamic-light budget, with the Lighting agent
Baseline: Level.tscn has 15 interior OmniLight3D nodes (entry hall, basement, eight spiral-stair lights, the lantern) against a lighting_spec budget of max_dynamic_lights 8 and 2 shadow casters. Unless a script culls them by proximity the budget is exceeded. Compare light count and positions with the budget and decide per room which become baked or fake lighting. Per-room mood from the lore: dim, claustrophobic halls; warm firebox glow in the boiler room; the arc lamp the only strong source when lit. Use baked or cheap fake lighting for rooms the player is not in.

- Why this score: The scene already has 16 interior OmniLight3D nodes; the GDD budgets dynamic lights around the beacon and key hazards. Not 9 because lighting is already working.
- Done when: no more than 8 interior dynamic lights are live at once (or the creator raises the budget); per-room mood checked by capture
- Owner: Lighthouse Interior Creator Agent | works with: Lighting agent
- Depends on: LHI-03
- Baseline evidence:
  - LightingTheStorm/scenes/Level.tscn: /type="OmniLight3D"/ matched 15 (need >= 1 and <= 8)

### LHI-07 [8/10] Add interaction anchors and set dressing markers: boiler, coal, door, window, arc lamp, burner socket, posters
Marker3D anchors named by role in the v4 scene. Posters and documents praising the moon cycle and the Flighted (pillar and lore) as placeholder quads in the hallway. No story is added.

- Why this score: Other agents' tasks (coal job, lantern diagnosis, burner fit) need fixed places to attach to. Not 9 because anchors are cheap once the rooms exist.
- Done when: anchors exist and are listed for the Gameplay / Systems agent
- Owner: Lighthouse Interior Creator Agent | works with: Gameplay / Systems agent
- Depends on: LHI-02
- Baseline evidence:
  - LightingTheStorm/scenes/Level.tscn: 0 nodes match /LHI_Anchor_.*/ (need >= 6)

### LHI-08 [8/10] Decide how far the upper floors go for the prototype: walk-through shells or sealed floors with stair landings
Option A: build L1 and L2 as enterable greybox shells with their rooms. Option B: seal them, with a door and a landing on the stair, and build only the lantern room and the route. Option C: A for L2 (control, diagnostics) and B for L1. Cost rises with each room built and tested.

- Why this score: The blueprint has L1 (keeper's quarters) and L2 (control and diagnostics) between the entry floor and the lantern room; the slice route only needs the stair through them. Not higher because there is a safe default.
- Done when: the creator has chosen A, B or C
- Owner: Lighthouse Interior Creator Agent | works with: Creator
- Depends on: nothing
- Baseline evidence:
  - Creator picks A, B or C.
- **Decision for you:** Walk-through L1 and L2 (A), sealed with landings (B), or L2 only (C)? Recommendation: C, because L2 holds the diagnostics story and L1 can follow after the slice.

### LHI-11 [8/10] Compare the interior to the blueprint and the lighthouse concept art, and run the offline canon and asset checks
A comparison note against the blueprint legend and the three lighthouse concept views. Run main_asset.py --check-only on the lighthouse submissions.

- Why this score: Records every deliberate difference and keeps style and canon honest at zero token cost. Not higher because it documents rather than builds.
- Done when: comparison note exists; offline asset check passes
- Owner: Lighthouse Interior Creator Agent | works with: Offline AI Crew
- Depends on: nothing
- Baseline evidence:
  - GERFramework/reports/lighthouse_interior_concept_comparison.md is missing
  - python main_asset.py sample_submissions/lighthouse_hunyuan_v3.fal.json --check-only -> rc 0: [asset] lighthouse_exterior_v3 (lighthouse): APPROVE, 0 finding(s) |  | [asset] 1 approved, 0 need revision. Output: C:\GameDev\AI_GameDev\GERFramework\state\crew_out

### LHI-09 [7/10] Build the remaining blueprint rooms as greybox: keeper's quarters, control level, workshop, stores, foundation chamber, left hut, right annex
Per the depth chosen in LHI-08. B1 maintenance workshop, stores and foundation chamber; L1 kitchen and mess, sleeping quarters, wash room, radio and chart room, linen store; L2 electrical control room, instrument station, maintenance landing, tools; the left hut and right annex as closed storage volumes.

- Why this score: The creator asked for the blueprint's rooms; the GDD allows a greybox for Gate 1 and the slice does not need them. Not 8 because they do not block play.
- Done when: each room in the chosen scope exists with a doorway and collision; the route test still passes
- Owner: Lighthouse Interior Creator Agent | works with: Level Layout agent
- Depends on: LHI-08
- Baseline evidence:
  - Compare against the blueprint legend after LHI-08 is decided.

### LHI-10 [6/10] Place the crawlspace and wall voids for the whispers and bangs, as sound sources only
Hidden volumes behind walls with emitter markers for the Sound agent. The player cannot enter or see inside. Who is in the walls stays undecided.

- Why this score: Pillar 1 is a creepy haunted lighthouse where people hiding in the walls cause whispers and bangs; the blueprint shows crawlspace and wall voids at B1. Not 7 because audio is placeholder at Gate 1.
- Done when: void volumes and emitter markers exist and are listed for the Sound agent; no one is shown or named in the walls
- Owner: Lighthouse Interior Creator Agent | works with: Sound agent, Canon and Review Orchestrator
- Depends on: LHI-02
- Baseline evidence:
  - LightingTheStorm/scenes/Level.tscn: 0 nodes match /LHI_WallVoid_.*/ (need >= 3)

## Questions for you

- **LHI-08**: Walk-through L1 and L2 (A), sealed with landings (B), or L2 only (C)? Recommendation: C, because L2 holds the diagnostics story and L1 can follow after the slice.

## Review history

### Loop 1 (2026-10-20T14:25:31+00:00)
- [BLOCK] LHI-11: coverage [LHI-M3]: Concept art alignment (exterior and interior concept art) is covered only at 5; the assessor requires >= 8  -> raise LHI-11 to 8
- CREATOR CHANGE: LHI-11: raised 5 -> 8 (coverage [LHI-M3]: Concept art alignment (exterior and interior concept art) is covered only at 5; the assesso)

### Loop 2 (2026-10-20T14:25:31+00:00)
- no findings
