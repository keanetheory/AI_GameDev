# Cliffside Creator Agent: prioritised plan

- Assessor: **Cliffside Assessment Agent** (knowledge up to date)
- Phase: **awaiting_approval** | plan review loops used: 1 of 3
- Blocking findings left: **0**

**Mission:** Make the Saint Calder cliffside complete, clean and fast to load, with the walkway from the Saltgate to the cliff top built as a continuation of the cliff stone itself, and with trees, path and props rooted into the rock so nothing looks placed on top of it.

## Objectives (10 = absolute must)

| ID | Score | Objective | Needs you | Baseline today |
|---|---|---|---|---|
| CLF-01 | **10** | Audit every cliff mesh and every module seam for empty, hollow and holed geometry, then repair |  | failing |
| CLF-02 | **10** | Make the walkway from the Saltgate to the cliff top an extension of the cliff stone mesh |  | needs_human |
| CLF-03 | **9** | Root trees, path edges and props into the rock so they read as natural, not placed |  | needs_human |
| CLF-04 | **9** | Set a cliffside load-time and memory budget, measure it headless, and cut cost until it is met |  | failing |
| CLF-05 | **9** | Prove there are no empty spots or collision gaps along the walkway, cliff top and plateau |  | failing |
| CLF-06 | **9** | Write the port-to-cliff joint contract with the Saltgate agent and build the cliff side of it |  | failing |
| CLF-07 | **8** | Verify cliff faces, wet rock and fog read in every phase with the Lighting agent |  | needs_human |
| CLF-08 | **8** | Decide where timber ends and rock begins on the walkway, and its width | YES | decision pending |
| CLF-09 | **7** | Compare the cliffside to the cliff and channel concept art and list every deliberate difference |  | failing |
| CLF-10 | **6** | Run the offline AI Crew over the cliff FAL submissions and record the result |  | passing |
| CLF-11 | **5** | Visibility ranges and distant LOD for the cliff line seen from the channel |  | failing |

## Detail

### CLF-01 [10/10] Audit every cliff mesh and every module seam for empty, hollow and holed geometry, then repair
Baseline: cliff_wall.glb and cliff_headland.glb are 150k triangles each with 0 hole loops and 0 empty meshes. The risk is where the ten placed pieces (CliffWall1-7, Headland1-2, CapEast) meet. Write tools/test_cliff_seams.gd to measure the gap between adjacent module bounds and any see-through crack along the line, and report each seam. Repair by overlapping, nudging or adding a rock filler, not by regenerating via FAL.

- Why this score: Named a must by the creator; a gap in a cliff wall is visible from every crossing. Not 9 because the two cliff meshes audit clean, so the live risk is the seams between the 10 placed modules.
- Done when: mesh audit: zero empty meshes, zero hole loops on both cliff meshes; tools/test_cliff_seams.gd exists and reports no seam gap above the agreed tolerance
- Owner: Cliffside Creator Agent | works with: Offline AI Crew
- Depends on: nothing
- Baseline evidence:
  - cliff_wall.glb: 26.04 MB, 150,000 tris, 1 meshes (empty 0, unreferenced 0), hole loops 0 (open edges 0.0%), degenerate 0, textures [[4096, 4096]] (~89.3 MB VRAM)
  - cliff_headland.glb: 26.29 MB, 149,916 tris, 1 meshes (empty 0, unreferenced 0), hole loops 0 (open edges 0.0%), degenerate 0, textures [[4096, 4096]] (~89.3 MB VRAM)
  - LightingTheStorm/tools/test_cliff_seams.gd is missing

### CLF-02 [10/10] Make the walkway from the Saltgate to the cliff top an extension of the cliff stone mesh
mainland.gd already cuts the harbour road into the cliff face as a ledge made from a copy of the cliff mesh and texture. Audit the whole run from the quay to the plateau for places that still read as a bolt-on: the start where timber boardwalks meet it, the stone stairs (stone_stairs.gd), the ramp surface material, the outer edge, the retaining wall, and the top where it meets the plateau. Every stone surface the player walks on uses the cliff's mesh and texture set, with the cliff's moss and cracks continuing across it, rock lip at the outer edge, and no flat planes with a different material.

- Why this score: Named a must by the creator, and it is the main walk of the second half of the slice. Not 9 because the road is already cut into a copy of the cliff mesh; what remains is every place it still reads as a separate object.
- Done when: from quay to cliff top every walked stone surface uses the cliff material and texture set; no visible seam, step or colour break between cliff face and walkway; the outer edge has a rock lip, not a hard cut
- Owner: Cliffside Creator Agent | works with: Saltgate Creator Agent, Level Layout agent
- Depends on: CLF-01
- Baseline evidence:
  - LightingTheStorm/scripts/world/mainland.gd: /COPY of the cliff mesh/ matched 1 (need >= 1)
  - Walk quay to cliff top in Godot; list each place the walkway reads as separate.

### CLF-03 [9/10] Root trees, path edges and props into the rock so they read as natural, not placed
mainland.gd scatters 2,600 trees on the plateau using the measured cliff-top heights. Check: no tree base floats or sinks relative to the rock or terrain, roots or rubble hide each base, trees keep off the road and ramp, the path edge breaks up into gravel, moss and fallen stone rather than a ruler-straight line, and props (flags, posts, lamps) sit on the rock with contact shadows or grounding decals. Vary scale and lean with wind from the sea.

- Why this score: Named a must by the creator. Not 10 because the walkway itself (CLF-02) comes first.
- Done when: no floating or buried trees in a sweep along the walkway and plateau edge; path edge has no hard straight line against the rock or ground
- Owner: Cliffside Creator Agent | works with: Lighting agent
- Depends on: CLF-02
- Baseline evidence:
  - LightingTheStorm/scripts/world/mainland.gd: /tree_count|tree_seed/ matched 5 (need >= 2)
  - Walk the walkway and plateau edge in Godot and look for floating or buried trees.

### CLF-04 [9/10] Set a cliffside load-time and memory budget, measure it headless, and cut cost until it is met
Baseline: cliff_wall.glb 26.0 MB, 150k triangles, 4096 texture (about 89 MB VRAM); cliff_headland.glb 26.3 MB, same. Proposed budget (creator to confirm): each cliff mesh under 15 MB with a 2048 texture (project convention), instances share one resource, the 2,600 trees are one MultiMesh, and the mainland carving and collision are baked instead of generated at load (GOA backlog T23). Write tools/measure_load_time.gd (shared with the Island agent) to time the cliffside headless.

- Why this score: Named a must by the creator. The baseline is the worst in the level: two 26 MB meshes with 4096 textures instanced ten times plus 2,600 trees generated at load. Not 10 because it does not stop the slice running.
- Done when: each cliff mesh <= 15 MB and <= 2048 px texture; mainland carving and collision are baked or the creator has accepted the load cost; measured cliffside load time inside the creator-confirmed budget
- Owner: Cliffside Creator Agent | works with: Asset agent
- Depends on: CLF-01
- Baseline evidence:
  - cliff_wall.glb: 26.04 MB, 150,000 tris, 1 meshes (empty 0, unreferenced 0), hole loops 0 (open edges 0.0%), degenerate 0, textures [[4096, 4096]] (~89.3 MB VRAM)  FAIL: 26.04 MB > limit 15; 4,096 px texture > limit 2,048; 89.3 MB VRAM > limit 30
  - cliff_headland.glb: 26.29 MB, 149,916 tris, 1 meshes (empty 0, unreferenced 0), hole loops 0 (open edges 0.0%), degenerate 0, textures [[4096, 4096]] (~89.3 MB VRAM)  FAIL: 26.29 MB > limit 15; 4,096 px texture > limit 2,048; 89.3 MB VRAM > limit 30
  - LightingTheStorm/scripts/world/mainland.gd: /MultiMesh/ matched 4 (need >= 1)
  - LightingTheStorm/tools/measure_load_time.gd is missing

### CLF-05 [9/10] Prove there are no empty spots or collision gaps along the walkway, cliff top and plateau
Write tools/test_walkway_continuity.gd: ray-sweep the ramp, the stairs, the lip and the plateau behind the cliff, and walk the Player capsule from the quay to the road to the city gate. Fail on any gap, any invisible wall, and any place the camera can see behind the cliff to empty sky or sea.

- Why this score: Named a must by the creator; a gap in the collider or a missing patch of ground behind the cliff is a fall-through or a visible void. Not 10 because the walk currently works end to end.
- Done when: tools/test_walkway_continuity.gd exists and passes headless; no camera angle from the walkway shows a void
- Owner: Cliffside Creator Agent | works with: Experience (Player Movement + QA agents)
- Depends on: CLF-02
- Baseline evidence:
  - LightingTheStorm/tools/test_walkway_continuity.gd is missing
  - Run the test and walk the route.

### CLF-06 [9/10] Write the port-to-cliff joint contract with the Saltgate agent and build the cliff side of it
Write GERFramework/contracts/port_cliff_joint.md with the Saltgate agent: joint position, heights, which mesh overlaps which, materials on both sides, collision handover, and who may change what. Then build the cliff side: the cliff base wraps behind and under the quay edge.

- Why this score: Two agents share one seam and the creator wants the port grown into the cliff; without a written contract each will move it. Not 10 because it supports CLF-02 and SLT-02 rather than being a deliverable itself.
- Done when: contract file exists and both creator agents list it as met; no gap, floating edge or material break at the joint
- Owner: Cliffside Creator Agent | works with: Saltgate Creator Agent
- Depends on: nothing
- Baseline evidence:
  - GERFramework/contracts/port_cliff_joint.md is missing

### CLF-07 [8/10] Verify cliff faces, wet rock and fog read in every phase with the Lighting agent
Capture the cliff from the channel and from the walkway in OUTBOUND, RETURN and BEACON_RELIT. Check roughness and wetness response, lightning catching ridges, fog depth, and that the moonlit supermoon colour reads on the slate. Report fixes to the Lighting agent; fix materials here.

- Why this score: The cliffs are the largest surface in the return crossing; they must catch lightning and the beacon without going flat or glowing. Not 9 because the rig exists and this is verification.
- Done when: captures reviewed per phase; no emissive leak, no flat shading
- Owner: Cliffside Creator Agent | works with: Lighting agent
- Depends on: CLF-01
- Baseline evidence:
  - LightingTheStorm/scripts/world/lighting_rig.gd: /OUTBOUND|RETURN|BEACON_RELIT/ matched 31 (need >= 3)
  - Capture each phase in Godot.

### CLF-08 [8/10] Decide where timber ends and rock begins on the walkway, and its width
Proposal: timber on the quay and piers only; from the first step off the quay the climb is cliff stone, cut 6 m wide as today (ROAD_W) with a rock lip. The boardwalk links stay on the quay only.

- Why this score: The creator wants the walkway to be stone, but the lore calls for rotting timber piers at the quay and the current build has wooden boardwalks at the start. Not higher because there is a safe default.
- Done when: the creator has chosen the boundary and width
- Owner: Cliffside Creator Agent | works with: Creator, Saltgate Creator Agent
- Depends on: nothing
- Baseline evidence:
  - LightingTheStorm/scripts/world/mainland.gd: /ROAD_W/ matched 3 (need >= 1)
- **Decision for you:** Does timber stop at the quay edge and stone start at the first step? Keep the 6 m width? Recommendation: yes to both.

### CLF-09 [7/10] Compare the cliffside to the cliff and channel concept art and list every deliberate difference
Compare module silhouettes, moss and slate colour, and the placement image (position of Saltgate and cliff terrain) against in-engine captures.

- Why this score: Art direction is locked by the concept art; the cliffs define the channel read. Not 8 because differences are cheap once listed.
- Done when: a comparison note lists each difference as accepted or fixed
- Owner: Cliffside Creator Agent
- Depends on: nothing
- Baseline evidence:
  - GERFramework/reports/cliffside_concept_comparison.md is missing

### CLF-10 [6/10] Run the offline AI Crew over the cliff FAL submissions and record the result
Run main_asset.py --check-only on cliff_wall_hunyuan_v3.fal.json and cliff_headland_hunyuan_v3.fal.json.

- Why this score: Keeps any future regeneration inside the style guide at zero token cost. Not higher because it checks prompts, not shipped meshes.
- Done when: offline asset check passes
- Owner: Cliffside Creator Agent | works with: Offline AI Crew, Asset agent
- Depends on: nothing
- Baseline evidence:
  - python main_asset.py sample_submissions/cliff_wall_hunyuan_v3.fal.json --check-only -> rc 0: [asset] cliff_wall (cliff_terrain): APPROVE, 0 finding(s) |  | [asset] 1 approved, 0 need revision. Output: C:\GameDev\AI_GameDev\GERFramework\state\crew_out

### CLF-11 [5/10] Visibility ranges and distant LOD for the cliff line seen from the channel
Add visibility ranges and a cheaper stand-in for far modules; keep the silhouette and the Saltgate gap readable.

- Why this score: The cliff line is seen along the whole crossing but needs only silhouette detail at distance. Not 6 because load time (CLF-04) comes first.
- Done when: no pop-in visible from the boat; frame time stable along the channel
- Owner: Cliffside Creator Agent
- Depends on: CLF-04
- Baseline evidence:
  - LightingTheStorm/scenes/Level.tscn: /visibility_range|lod/ matched 0 (need >= 1)

## Questions for you

- **CLF-08**: Does timber stop at the quay edge and stone start at the first step? Keep the 6 m width? Recommendation: yes to both.

## Review history

### Loop 1 (2026-10-20T14:25:24+00:00)
- no findings
