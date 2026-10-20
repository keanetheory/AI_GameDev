# Saltgate Creator Agent: prioritised plan

- Assessor: **Saltgate Assessment Agent** (knowledge up to date)
- Phase: **awaiting_approval** | plan review loops used: 1 of 3
- Blocking findings left: **0**

**Mission:** Polish the Saltgate, the abandoned harbour district: the huts, warehouses, quays and port. Make stepping off the boat smooth, and make the port grow out of the cliffside instead of sitting against it, while keeping the lore (dark, abandoned, eerie, tattered amber and gold flags, no people) intact.

## Objectives (10 = absolute must)

| ID | Score | Objective | Needs you | Baseline today |
|---|---|---|---|---|
| SLT-01 | **10** | Make stepping off the boat and walking onto the quay smooth |  | failing |
| SLT-02 | **10** | Integrate the port seamlessly into the cliffside |  | failing |
| SLT-03 | **9** | Audit the quay and dock meshes for empty, hollow and holed geometry, then repair |  | passing |
| SLT-04 | **9** | Inventory and polish the huts, warehouses and port structures |  | failing |
| SLT-05 | **9** | Decide the polish scope: the GDD keeps the Saltgate minimal until the prototype is complete | YES | decision pending |
| SLT-06 | **8** | Light the Saltgate with the Lighting agent: dark windows, amber flags, the glow of Saint Calder |  | needs_human |
| SLT-07 | **8** | Keep the burner pickup findable and honest to canon |  | passing |
| SLT-08 | **7** | Set a Saltgate load-time and memory budget and meet it |  | failing |
| SLT-09 | **7** | Run the offline AI Crew canon and asset checks on the Saltgate |  | passing |
| SLT-10 | **6** | Place audio anchors for the Saltgate: creaking timber, loose shutters, rigging, distant city hum |  | failing |
| SLT-11 | **5** | Compare the Saltgate to the quay and dock concept art and list every deliberate difference |  | failing |

## Detail

### SLT-01 [10/10] Make stepping off the boat and walking onto the quay smooth
Play the exact sequence: boat auto-docks in the DOCK_PORT zone, Q steps ashore, the player walks to the quay and on to the burner. Measure: gap and height between the boat deck, the quay edge and the first walkable surface, the player step-up and floor-snap limits from the player movement spec, camera behaviour during the step, and whether the boat ever moves under the player. Add tools/test_disembark.gd to automate it headless with the Player capsule, and repeat it several times because arrival flakiness has bitten this project before. Work with the Experience agents (Player Movement and QA) and the World crew's dock-zone spec.

- Why this score: Named a must by the creator, and it is the player's first moment in the second half of the slice. Not 9 because a snag or gap here breaks the experience on every playthrough.
- Done when: tools/test_disembark.gd exists and passes 8 of 8 consecutive runs; no snag, no floating step, no camera jump when stepping ashore; the creator walks it and signs it off
- Owner: Saltgate Creator Agent | works with: Experience (Player Movement + QA agents), World crew (Boat, Player Movement, Lighting), Canon and Review Orchestrator
- Depends on: nothing
- Baseline evidence:
  - LightingTheStorm/scenes/Level.tscn: 1 nodes match /DockZonePort/ (need >= 1)
  - LightingTheStorm/tools/test_disembark.gd is missing
  - Creator plays the crossing and steps ashore.

### SLT-02 [10/10] Integrate the port seamlessly into the cliffside
The quay is three instances of saltgate_quay.glb (Saltgate, SaltgateWest, SaltgateEast) set against the cliff modules. Agree the joint with the Cliffside agent in GERFramework/contracts/port_cliff_joint.md, then build the port side: quay stone runs into and under the cliff base, a retaining wall or rock outcrop hides the junction, the stair and ramp start at the same material as the cliff, and the waterline edge is one continuous rock-and-stone line. No floating edge, no gap you can see light through, no visible instance boundary between the three quay copies.

- Why this score: Named a must by the creator. Not 9 because a visible seam between port and cliff is seen on both crossings and on the walk up.
- Done when: contract file exists and is met by both agents; no gap, floating edge or material break between port and cliff from the boat, the quay and the walkway; no visible boundary between the three quay instances
- Owner: Saltgate Creator Agent | works with: Cliffside Creator Agent
- Depends on: nothing
- Baseline evidence:
  - GERFramework/contracts/port_cliff_joint.md is missing
  - LightingTheStorm/scenes/Level.tscn: 11 nodes match /Saltgate.*|CliffWall\d/ (need >= 6)
  - Inspect the joint from the boat, the quay and the first ramp step.

### SLT-03 [9/10] Audit the quay and dock meshes for empty, hollow and holed geometry, then repair
Baseline: saltgate_quay.glb (30.9 MB, 249k triangles, one mesh) and dock_harbour.glb audit clean with 0 hole loops. dock_landing.glb is 25.6 MB. Re-run after every change. Because the quay is one baked mesh, hollowness shows as open doorways and windows with nothing behind them, which the audit cannot detect; that is covered visually in SLT-04.

- Why this score: Same quality bar as the island and cliffs; the huts are where hollow interiors show. Not 10 because the baseline meshes audit clean.
- Done when: zero empty meshes and zero hole loops on every Saltgate and dock mesh in use
- Owner: Saltgate Creator Agent | works with: Offline AI Crew
- Depends on: nothing
- Baseline evidence:
  - saltgate_quay.glb: 30.9 MB, 248,958 tris, 1 meshes (empty 0, unreferenced 0), hole loops 0 (open edges 0.0%), degenerate 0, textures [[4096, 4096]] (~89.3 MB VRAM)
  - dock_harbour.glb: 7.73 MB, 91,022 tris, 1 meshes (empty 0, unreferenced 0), hole loops 0 (open edges 0.0%), degenerate 0, textures [[2048, 2048]] (~22.3 MB VRAM)

### SLT-04 [9/10] Inventory and polish the huts, warehouses and port structures
saltgate_quay.glb is a single 249k-triangle mesh, so individual huts cannot be edited as they are. Inventory what is in it (huts, warehouses, piers, cranes) into Assets/Models/saltgate/saltgate_inventory.json with bounds, then polish in the cheapest order: material and texture passes (salt crust, rot, moss), closing open doorways and windows with dark inset cards so nothing reads as a hollow shell, adding broken shutters, boarded windows and rusted fittings as small props, and tattered amber-and-gold flags per the lore. Splitting the mesh into per-structure pieces or regenerating individual huts through FAL is a cost and scope decision for the creator (SLT-05), not an assumption.

- Why this score: Named by the creator. Not 10 because it depends on the scope decision SLT-05; the GDD keeps the Saltgate minimal until the prototype is complete.
- Done when: saltgate_inventory.json lists every structure; no open doorway or window shows an empty void in a close-up sweep; each hut reads as abandoned 1800s harbour against the concept art
- Owner: Saltgate Creator Agent | works with: Asset agent, Canon and Review Orchestrator
- Depends on: SLT-05
- Baseline evidence:
  - LightingTheStorm/Assets/Models/saltgate/saltgate_inventory.json is missing
  - Close-up sweep of every structure in Godot.

### SLT-05 [9/10] Decide the polish scope: the GDD keeps the Saltgate minimal until the prototype is complete
Options: (a) polish now, with materials, closed openings and props only, no new FAL generations; (b) polish now including regenerating or splitting huts, which spends credits; (c) wait until the prototype is complete. Huts stay closed shells in every option; enterable interiors are not in the GDD.

- Why this score: The GDD and Technical Strategy say the Saltgate is minimal until the prototype is complete; this work is the creator overriding or timing that. It gates the cost of SLT-04. Not 10 because there is a safe default.
- Done when: the creator has chosen a scope
- Owner: Saltgate Creator Agent | works with: Creator, Canon and Review Orchestrator
- Depends on: nothing
- Baseline evidence:
  - Docs/GDD/Final_GDD_Post_Review/Technical Strategy.md: /Saltgate kept minimal/ matched 1 (need >= 1)
- **Decision for you:** Polish now (a) without FAL spend, (b) with FAL regeneration or mesh splitting, or (c) wait? Recommendation: (a) now, with (b) offered per hut after you see the result. Also confirm huts stay closed shells.

### SLT-06 [8/10] Light the Saltgate with the Lighting agent: dark windows, amber flags, the glow of Saint Calder
Check OUTBOUND and RETURN: windows stay dark, flags catch the amber, the city glow silhouettes the roofline, and the dock zone and burner pickup are readable without a quest marker. Stay inside the dynamic light budget.

- Why this score: Lore says almost no light, with the distant electric glow of Saint Calder over the rooftops; the burner and the dock must still be findable. Not 9 because the rig exists and this is verification.
- Done when: captures per phase reviewed; burner and dock readable without markers; light budget respected
- Owner: Saltgate Creator Agent | works with: Lighting agent
- Depends on: nothing
- Baseline evidence:
  - LightingTheStorm/data/world/lighting_spec.json: /saint_calder/ matched 3 (need >= 1)
  - Capture OUTBOUND and RETURN at the quay.

### SLT-07 [8/10] Keep the burner pickup findable and honest to canon
The lore says the exact storage location is TBD, so this agent must not invent a story reason; it makes the existing placeholder readable by sightline, light and a small amount of set dressing, and records the location as a placeholder for the creator to lock.

- Why this score: It is the objective of the whole outbound crossing. Not 9 because the pickup already exists and works.
- Done when: the pickup is reachable by a smooth walk from the dock; no story is invented about why the burner is there
- Owner: Saltgate Creator Agent | works with: Gameplay / Systems agent, Canon and Review Orchestrator
- Depends on: SLT-01
- Baseline evidence:
  - LightingTheStorm/scenes/Level.tscn: 1 nodes match /BurnerPickup/ (need >= 1)
  - LightingTheStorm/scripts/world/burner_pickup.gd exists

### SLT-08 [7/10] Set a Saltgate load-time and memory budget and meet it
Baseline: saltgate_quay.glb 30.9 MB, 249k triangles, 4096 texture. Proposed budget (creator to confirm): each mesh under 15 MB with 2048 textures, the three instances share one resource, and the timing is measured with tools/measure_load_time.gd.

- Why this score: The quay mesh is instanced three times at 31 MB with a 4096 texture, and dock_landing is 25.6 MB. Not 8 because it does not stop the slice.
- Done when: each Saltgate mesh <= 15 MB and <= 2048 px; measured load time inside the confirmed budget
- Owner: Saltgate Creator Agent | works with: Asset agent
- Depends on: SLT-03
- Baseline evidence:
  - saltgate_quay.glb: 30.9 MB, 248,958 tris, 1 meshes (empty 0, unreferenced 0), hole loops 0 (open edges 0.0%), degenerate 0, textures [[4096, 4096]] (~89.3 MB VRAM)  FAIL: 30.9 MB > limit 15; 4,096 px texture > limit 2,048; 89.3 MB VRAM > limit 30
  - dock_landing.glb: 25.59 MB, 74,504 tris, 1 meshes (empty 0, unreferenced 0), hole loops 0 (open edges 0.0%), degenerate 0, textures [[4096, 4096]] (~89.3 MB VRAM)  FAIL: 25.59 MB > limit 15; 4,096 px texture > limit 2,048
  - LightingTheStorm/tools/measure_load_time.gd is missing

### SLT-09 [7/10] Run the offline AI Crew canon and asset checks on the Saltgate
Run main_asset.py --check-only on saltgate_hunyuan_v3.fal.json. Confirm: no people, flags are tattered amber and gold, nothing explains why the port was abandoned.

- Why this score: Keeps the work inside the locked style guide and canon at zero token cost. Not higher because it checks prompts and records, not shipped meshes.
- Done when: offline asset check passes; canon review notes recorded
- Owner: Saltgate Creator Agent | works with: Offline AI Crew, Canon and Review Orchestrator
- Depends on: nothing
- Baseline evidence:
  - python main_asset.py sample_submissions/saltgate_hunyuan_v3.fal.json --check-only -> rc 0: [asset] saltgate_quay (saltgate): APPROVE, 0 finding(s) |  | [asset] 1 approved, 0 need revision. Output: C:\GameDev\AI_GameDev\GERFramework\state\crew_out

### SLT-10 [6/10] Place audio anchors for the Saltgate: creaking timber, loose shutters, rigging, distant city hum
Add Marker3D anchors named by sound type on the quay for the Sound agent to attach to. No audio is authored here.

- Why this score: The lore's audio direction depends on specific physical sources. Not 7 because audio is placeholder at Gate 1.
- Done when: anchors exist and are listed for the Sound agent
- Owner: Saltgate Creator Agent | works with: Sound agent
- Depends on: nothing
- Baseline evidence:
  - LightingTheStorm/scenes/Level.tscn: 0 nodes match /SaltgateAudio.*/ (need >= 3)

### SLT-11 [5/10] Compare the Saltgate to the quay and dock concept art and list every deliberate difference
Compare silhouettes and materials of the quay, the timber quay end, the workshop rear and the dock front against captures from the same angles.

- Why this score: Art direction is locked by the concept art. Not higher because differences are cheap once listed.
- Done when: a comparison note lists each difference as accepted or fixed
- Owner: Saltgate Creator Agent
- Depends on: nothing
- Baseline evidence:
  - GERFramework/reports/saltgate_concept_comparison.md is missing

## Questions for you

- **SLT-05**: Polish now (a) without FAL spend, (b) with FAL regeneration or mesh splitting, or (c) wait? Recommendation: (a) now, with (b) offered per hut after you see the result. Also confirm huts stay closed shells.

## Review history

### Loop 1 (2026-10-20T14:25:34+00:00)
- no findings
