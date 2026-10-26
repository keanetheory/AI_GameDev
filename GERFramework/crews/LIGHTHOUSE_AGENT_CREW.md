# Lighthouse Agent Crew

Everyone who touches the Saint Calder lighthouse, inside and out, working to one finish standard: realistic, cel-shaded, optimised, lore-correct. The Finisher leads the build; the two assessors score it; the Interior Creator keeps the gameplay logic intact; the AI Crew members are called on for their lanes.

## Rules

- Offline only: --check-only and the deterministic ger.py checks. No FAL, ElevenLabs or Anthropic API spend unless the creator says so in chat.
- Nothing is built before the creator's all clear (the GER approval gate). The Finisher's plan goes through review-plan first.
- The Interior Creator's gameplay logic (coal job, lamp fit, doors, anchors) is not rewritten by the Finisher; the Finisher replaces only the look and the geometry.
- Every change is held to the LHF-01 baseline shots and the lighthouse test suite staying green.

## Lighthouse Finisher Agent
_Lead builder: finishes the whole lighthouse. Its full objective list lives in agents/creators/lighthouse_finisher.json (LHF-01 to LHF-18)._

| ID | Score | Objective | Needs creator |
|---|---|---|---|
| LHF-01 | 10 | Baseline audit and a fixed before/after shot set |  |
| LHF-02 | 10 | Stop the exterior mesh showing inside the interior |  |
| LHF-03 | 10 | No rain inside the lighthouse |  |
| LHF-04 | 10 | One realistic stair standard, applied to every staircase |  |
| LHF-05 | 10 | Boiler: living flames in place of the red slab |  |
| LHF-06 | 9 | Geometry and polygon optimisation |  |
| LHF-07 | 9 | Room-by-room rebuild of the poorly rendered rooms |  |
| LHF-08 | 9 | Replace greybox props with real models or well-made procedural props | yes |
| LHF-09 | 9 | Reset the Flighted posters | yes |
| LHF-10 | 9 | Cel-shaded look for the whole lighthouse | yes |
| LHF-11 | 8 | Exterior walls: close-up realism | yes |
| LHF-12 | 8 | Windows, doors and thresholds: one consistent opening kit |  |
| LHF-13 | 8 | Lamp room and gallery finish |  |
| LHF-14 | 8 | Per-room lighting and materials pass |  |
| LHF-15 | 7 | Architectural trim: ceilings, floors, skirting, cornices, joists |  |
| LHF-16 | 7 | Regression: every lighthouse test stays green |  |
| LHF-17 | 6 | Offline asset and canon checks, and the assessors' final score |  |
| LHF-18 | 5 | Handoff, changelog and fallbacks |  |

## Lighthouse Interior Creator Agent
_Owner of the interior code, rooms and interaction logic. Its own list is LHI-01 to LHI-18 (agents/creators/lighthouse_interior_creator.json); the crew tasks below are the extra work the finish needs from it._

| ID | Score | Task | Pairs with |
|---|---|---|---|
| LHC-IC-1 | 9 | Hand the Finisher a map of every interior node, script and anchor name that must survive a re-skin (coal_job, firebox, Lens_*, LampSocket, LHI_Anchor_*, poster.gd) | LHF-05, LHF-08, LHF-09, LHF-13 |
| LHC-IC-2 | 8 | Expose the room builders (rooms_house.gd, rooms_tower.gd) so props and trim can be swapped per room without editing the logic | LHF-07, LHF-08, LHF-15 |
| LHC-IC-3 | 8 | Answer Finisher requests to change a room's collision or anchors, and re-run test_interior_walk, test_coal_job, test_lamp_fit and test_interior_anchors after each | LHF-04, LHF-16 |
| LHC-IC-4 | 6 | Retire LHI-18 (art handoff) in favour of the Finisher, and record what the Finisher took over | LHF-08, LHF-18 |

## Lighthouse - Interior Assessment Agent
_Scores the Finisher's interior work against the Interior Plan V4 blueprint, the GDD beats and the concept art. Read-only._

| ID | Score | Task | Pairs with |
|---|---|---|---|
| LHC-IA-1 | 10 | Add a finish rubric (surface, trim, dressing, lighting, scale, story read; 1-10 per room) and score every room from the LHF-01 baseline shots | LHF-01, LHF-07 |
| LHC-IA-2 | 9 | Check that no exterior triangle sits inside any interior volume (probe_shards, probe_tower_intruders) | LHF-02 |
| LHC-IA-3 | 9 | Measure every staircase against the stair spec: rise, going, headroom, walk test | LHF-04 |
| LHC-IA-4 | 9 | Verify the rain test (zero particles inside) and the fire follows the coal job loads | LHF-03, LHF-05 |
| LHC-IA-5 | 8 | Check posters against the Flighted canon brief and the retired-brand rule | LHF-09 |
| LHC-IA-6 | 8 | Re-score the room table after each Finisher loop; BLOCK only on a regression, a canon break or a failed test | LHF-07, LHF-16, LHF-17 |
| LHC-IA-7 | 6 | Extend work_checks: add the new stair, rain and fire tests and a per-room triangle budget check | LHF-06, LHF-16 |

## Lighthouse - Exterior Assessment Agent
_Scores the Finisher's exterior work and keeps the beacon silhouette intact. Read-only._

| ID | Score | Task | Pairs with |
|---|---|---|---|
| LHC-EA-1 | 10 | Record the exterior silhouette, wall close-ups and exterior tri/texture budget as the baseline, and refresh the measured dimensions and door facts | LHF-01 |
| LHC-EA-2 | 9 | Confirm the exterior silhouette is unchanged after the interior carve, from the sea and from the dock in every phase | LHF-02 |
| LHC-EA-3 | 8 | Score the close-up wall work: mortar, bevels, weathering, stretched texture, 2048 limit, mesh_audit | LHF-11 |
| LHC-EA-4 | 8 | Check every opening reads the same from both sides and with the measured door | LHF-12 |
| LHC-EA-5 | 7 | Write the finish assessment (reports/lighthouse_exterior_assessor_assessment.md) and add the finisher to its feedback list; flag any regeneration needing FAL credits as a creator decision | LHF-11, LHF-17 |

## AI Crew members (consulted, offline)
_Roster agents from AIAgentCrew/roles.py called for their lane. Run only with --check-only or the existing offline outputs._

| ID | Score | Task | Pairs with |
|---|---|---|---|
| LHC-AI-1 | 9 | Asset agent: Check-only submissions for new props, the exterior wall textures and the poster art; apply the 4096 to 2048 downscale rule and the import script | LHF-08, LHF-09, LHF-11 |
| LHC-AI-2 | 9 | Lighting agent: Agree the toon ramp and outline with the Finisher, decide indoor-rain rules and per-room light plans inside the dynamic-light budget | LHF-03, LHF-10, LHF-14 |
| LHC-AI-3 | 8 | Level Layout agent: Approve the stair spec, headroom and traversal, and re-check the two GDD sightlines | LHF-04, LHF-12 |
| LHC-AI-6 | 8 | QA agent: Own the fixed-camera shot set and the visual regression, and the green-test baseline | LHF-01, LHF-16 |
| LHC-AI-4 | 7 | Gameplay / Systems agent: Confirm the boiler, firebox, lamp and door interaction contracts survive the re-skin | LHF-05, LHF-13 |
| LHC-AI-7 | 7 | Canon and Review Orchestrator: Offline canon check of posters, signage and the Saint Calder brand | LHF-09, LHF-17 |
| LHC-AI-5 | 6 | Sound agent: Place the fire crackle, drip and machinery emitters at the anchors the Finisher provides | LHF-03, LHF-05 |
| LHC-AI-8 | 6 | Island Creator Agent: Answer carve requests where the rock meets the foundation and basement | LHF-02 |
