# Island Creator Agent: prioritised plan

- Assessor: **Island Assessment Agent** (knowledge up to date)
- Phase: **awaiting_approval** | plan review loops used: 1 of 3
- Blocking findings left: **0**

**Mission:** Make Bracken Isle (the rock the lighthouse sits on) complete, clean, fast to load, correctly lit by the Lighting agent in every phase, and reactive to the storm, so the creator never meets a hole, an empty mesh or a pop-in while playing.

## Objectives (10 = absolute must)

| ID | Score | Objective | Needs you | Baseline today |
|---|---|---|---|---|
| ISL-01 | **10** | Audit every island mesh in use for empty, hollow, unreferenced and holed geometry, then repair |  | passing |
| ISL-02 | **10** | Prove the island collider matches the visible rock: no fall-through, no invisible walls |  | failing |
| ISL-03 | **9** | Set an island load-time and memory budget, measure it headless, and cut cost until it is met |  | failing |
| ISL-04 | **9** | With the Lighting agent, verify the island is lit properly in ISLAND, OUTBOUND, RETURN and BEACON_RELIT |  | needs_human |
| ISL-05 | **8** | Make the island react to storm phase and sea state: wet rock, shoreline spray, darker faces |  | failing |
| ISL-06 | **8** | Compare the island to the concept art and list every deliberate difference |  | failing |
| ISL-07 | **7** | Check the dock, path and gate sit correctly on the rock and read as the only safe route |  | needs_human |
| ISL-08 | **7** | Run the offline AI Crew over the island FAL submissions and record the result |  | passing |
| ISL-09 | **6** | Keep the island cheap when seen from the sea and from the Saltgate: visibility ranges and distant LOD |  | failing |
| ISL-10 | **5** | Import hygiene: textures at 2048, provenance records, import notes |  | passing |
| ISL-11 | **4** | Decide what to do with the legacy island meshes (8-island.glb, 8-island-collider.glb, island_plateau.glb) | YES | decision pending |

## Detail

### ISL-01 [10/10] Audit every island mesh in use for empty, hollow, unreferenced and holed geometry, then repair
Level.tscn instances island_craggy.glb four times (Island, RockPatchSE, RockPatchSE2, RockPatchNE). Run the offline mesh audit (ger.py audit) on it and on any island mesh the scene or scripts load. Baseline already measured: island_craggy.glb is 200k triangles, 0 hole loops, 0 empty meshes. Check the RockPatch placements too: the patches must overlap the main island without exposing back faces or gaps where they meet. Repair anything found; do not regenerate via FAL without the creator's approval.

- Why this score: The creator named it a must; a hole in the rock is visible from the boat and the window. Not 9 because the active mesh already audits clean, so the work is proving it and keeping it that way; not lower because it gates every other island objective.
- Done when: mesh audit shows zero empty or unreferenced meshes and zero hole loops on every island mesh in use; the four instances show no visible seams or gaps in an in-engine sweep
- Owner: Island Creator Agent | works with: Offline AI Crew
- Depends on: nothing
- Baseline evidence:
  - island_craggy.glb: 13.04 MB, 199,968 tris, 1 meshes (empty 0, unreferenced 0), hole loops 0 (open edges 0.0%), degenerate 0, textures [[2048, 2048]] (~22.3 MB VRAM)
  - LightingTheStorm/scenes/Level.tscn: 4 nodes match /Island|RockPatch.*/ (need >= 4)

### ISL-02 [10/10] Prove the island collider matches the visible rock: no fall-through, no invisible walls
Write a headless Godot test (tools/test_island_coverage.gd) that casts a grid of vertical rays over the walkable island and the path from dock to lighthouse door, and fails if any ray passes through where the visual mesh exists or hits an invisible wall above the visual. The island visual is high-poly; the collider is built by collider_builder.gd, so test the built collider, not the source mesh. Include the gate and the dock landing.

- Why this score: A collider hole is a soft-lock or a fall into the sea on the player's first walk. Not 9: it breaks the playable slice, not just its look.
- Done when: tools/test_island_coverage.gd exists and passes headless; zero gaps and zero invisible walls on the dock-to-door path
- Owner: Island Creator Agent | works with: Experience (Player Movement + QA agents)
- Depends on: ISL-01
- Baseline evidence:
  - LightingTheStorm/tools/test_island_coverage.gd is missing
  - LightingTheStorm/scripts/world/collider_builder.gd: /Concave|trimesh|create_trimesh/ matched 8 (need >= 1)
  - Run the coverage test with the Godot console exe (see GOA readme for the command).

### ISL-03 [9/10] Set an island load-time and memory budget, measure it headless, and cut cost until it is met
Proposed budget (creator to confirm): island contribution to level load under 2 s on the creator's machine, island mesh under 15 MB, island textures 2048 px (see memory note on 4096 to 2048 downscale), and shared mesh data across the four instances (instance one PackedScene, do not re-import). Write tools/measure_load_time.gd that times loading the island scene headless and prints the numbers. If over budget: decimate, bake, or share resources, in that order. The offline audit gives a proxy (MB, triangles, texture memory) before Godot is run.

- Why this score: The creator named quick loading a must. Not 10 because the slice still runs if it is slow; not 8 because four 200k-triangle instances and 4096 textures elsewhere make this a real risk.
- Done when: tools/measure_load_time.gd exists and reports island load time; island mesh <= 15 MB, <= 250k triangles, textures <= 2048 px; measured load time inside the budget the creator confirmed
- Owner: Island Creator Agent | works with: Asset agent
- Depends on: ISL-01
- Baseline evidence:
  - island_craggy.glb: 13.04 MB, 199,968 tris, 1 meshes (empty 0, unreferenced 0), hole loops 0 (open edges 0.0%), degenerate 0, textures [[2048, 2048]] (~22.3 MB VRAM)
  - LightingTheStorm/tools/measure_load_time.gd is missing

### ISL-04 [9/10] With the Lighting agent, verify the island is lit properly in ISLAND, OUTBOUND, RETURN and BEACON_RELIT
For each phase in lighting_spec.json, capture the island from the dock, the path, the window and the sea approach. Check: matte stone with no metallic or emissive leaks, shadows land on the rock, the beacon sweep catches the island rocks, fog density keeps hazards legible, and the dynamic light budget (max_dynamic_lights, max_shadow_casters) is respected. Any change to the rig goes through the Lighting agent; this agent reports and fixes island materials only.

- Why this score: The creator named correct lighting a must and the GDD requires the beacon and hazards to stay legible at every phase. Not 10 because the rig already exists and this is verification plus fixes.
- Done when: one screenshot per phase per viewpoint is saved and reviewed; no lighting_rig change is made without the Lighting agent; dynamic lights stay inside the lighting_spec budget
- Owner: Island Creator Agent | works with: Lighting agent
- Depends on: ISL-01
- Baseline evidence:
  - LightingTheStorm/scripts/world/lighting_rig.gd: /ISLAND|OUTBOUND|RETURN|BEACON_RELIT/ matched 39 (need >= 4)
  - LightingTheStorm/data/world/lighting_spec.json: /max_dynamic_lights/ matched 1 (need >= 1)
  - Open Level.tscn and compare each phase (debug keys F5-F8 jump phases).

### ISL-05 [8/10] Make the island react to storm phase and sea state: wet rock, shoreline spray, darker faces
Add scripts/world/island_reactions.gd that listens to the phase change and, once it exists, the Wave agent's sea-state value, and adjusts rock wetness (roughness and albedo darkening), shoreline spray particles at the waterline, and surf audio anchors. Cheap by design: material parameters and one or two particle systems, no extra dynamic lights.

- Why this score: The creator asked that the island react and act accordingly. Not 9 because the slice plays without it and it needs the Wave agent's sea state to be final.
- Done when: island visibly changes between ISLAND and RETURN; no extra dynamic lights are added; the effect scales down under the reduced hazard-intensity preset
- Owner: Island Creator Agent | works with: Wave Creator Agent, Lighting agent, Sound agent
- Depends on: ISL-04
- Baseline evidence:
  - LightingTheStorm/scripts/world/island_reactions.gd is missing
  - Compare ISLAND and RETURN in Godot.

### ISL-06 [8/10] Compare the island to the concept art and list every deliberate difference
Side by side: front, left, right and rear concept views against in-engine captures from the same angles. Check the dock, the stair at the rear, the path hugging jagged rock, the gate position (Level.tscn), the 330 m by 140 m footprint from the lore. List differences as accepted or to-fix.

- Why this score: Art direction is locked by the concept art, and the interior and lighthouse work link back to this footprint. Not 9 because differences are cheap to accept or fix once listed.
- Done when: a comparison note exists listing each difference as accepted or fixed
- Owner: Island Creator Agent
- Depends on: nothing
- Baseline evidence:
  - GERFramework/reports/island_concept_comparison.md is missing

### ISL-07 [7/10] Check the dock, path and gate sit correctly on the rock and read as the only safe route
Verify the dock zone, the path width and the gate sit on the rock surface with no floating or buried pieces, jagged rock flanks the path so the player stays on it, and Level Layout agent anchors for the gate, the window view and the rowboat mooring are unchanged.

- Why this score: Lore says jagged rocks on either side force everyone onto the path; the gate is a story beat. Not 8 because layout was already blocked out and is playable.
- Done when: no floating or buried dock, path or gate piece; player cannot leave the path onto unsafe rock
- Owner: Island Creator Agent | works with: Level Layout agent, Player Movement agent
- Depends on: ISL-02
- Baseline evidence:
  - LightingTheStorm/scenes/Level.tscn: 4 nodes match /Harbour.*|DockZoneLighthouse.*/ (need >= 2)
  - Walk dock to door in Godot.

### ISL-08 [7/10] Run the offline AI Crew over the island FAL submissions and record the result
Run main_asset.py --check-only on the island submissions (island_craggy_hunyuan_v3.fal.json, island_hunyuan_v3.fal.json). Record results. A regeneration, if ever needed, is a creator decision (FAL credits).

- Why this score: Keeps any future regeneration inside the locked style guide at zero token cost. Not higher because it checks prompts, not the shipped mesh.
- Done when: offline asset check passes on the island submissions
- Owner: Island Creator Agent | works with: Offline AI Crew, Asset agent
- Depends on: nothing
- Baseline evidence:
  - python main_asset.py sample_submissions/island_craggy_hunyuan_v3.fal.json --check-only -> rc 0:           - source_image not found: ../../ConceptArt/island/new_island/Right-Side View of Craggy Island Dock-2.png |  | [asset] 0 approved, 1 need revision. Output: C:\GameDev\AI_GameDev\GERFramework\state\crew_out

### ISL-09 [6/10] Keep the island cheap when seen from the sea and from the Saltgate: visibility ranges and distant LOD
Set visibility ranges and an LOD or lower-detail stand-in for the island beyond the distances where the detail is invisible; keep the silhouette and the beacon landmark intact.

- Why this score: The island is the destination landmark on the return, but full-detail rendering at 1.5 km wastes frame time. Not 7 because the load budget (ISL-03) comes first.
- Done when: silhouette is unchanged at distance; frame time on the return approach does not rise as the island comes into view
- Owner: Island Creator Agent | works with: Lighting agent
- Depends on: ISL-03
- Baseline evidence:
  - LightingTheStorm/scenes/Level.tscn: /visibility_range|lod/ matched 0 (need >= 1)

### ISL-10 [5/10] Import hygiene: textures at 2048, provenance records, import notes
Confirm island textures are 2048 px, the .fal_result.json provenance exists, and the import settings (scale, pivot, collision) are written in the asset notes.

- Why this score: Project convention: v3 GLBs ship 4096 textures and are downscaled to 2048; every asset has a provenance record. Not higher because island_craggy already meets it.
- Done when: textures <= 2048 px; provenance record present
- Owner: Island Creator Agent | works with: Asset agent
- Depends on: nothing
- Baseline evidence:
  - island_craggy.glb: 13.04 MB, 199,968 tris, 1 meshes (empty 0, unreferenced 0), hole loops 0 (open edges 0.0%), degenerate 0, textures [[2048, 2048]] (~22.3 MB VRAM)
  - LightingTheStorm/Assets/Models/island/island_craggy.fal_result.json exists

### ISL-11 [4/10] Decide what to do with the legacy island meshes (8-island.glb, 8-island-collider.glb, island_plateau.glb)
Level.tscn does not reference them. They total about 80 MB. Options: archive them under LightingTheStorm/archive, delete them, or keep them. Deleting is the creator's call.

- Why this score: Dead weight in the repo, and the audit shows 8-island.glb has 562 hole loops (13.9% open edges) and a 692-loop collider; they are not used by Level.tscn today. Not higher because nothing in play touches them.
- Done when: the creator has chosen archive, delete or keep
- Owner: Island Creator Agent | works with: Creator
- Depends on: nothing
- Baseline evidence:
  - LightingTheStorm/scenes/Level.tscn: /8-island|island_plateau/ matched 0 (need >= 0 and <= 0)
- **Decision for you:** Archive, delete or keep 8-island.glb (23.5 MB, holed), 8-island-collider.glb and island_plateau.glb (29.6 MB)? Recommendation: archive, because they are unused and one has real holes.

## Questions for you

- **ISL-11**: Archive, delete or keep 8-island.glb (23.5 MB, holed), 8-island-collider.glb and island_plateau.glb (29.6 MB)? Recommendation: archive, because they are unused and one has real holes.

## Review history

### Loop 1 (2026-10-20T15:05:30+00:00)
- no findings
