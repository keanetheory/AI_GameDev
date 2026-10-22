# Saltgate: comparison with the concept art (SLT-11)

Saltgate Creator Agent, 2026-10-22. Captures are real renders of the level (`GERFramework/shoot.sh`), saved in `GERFramework/shots/`. Each difference is marked **accepted** (deliberate, kept), **fixed** (changed this run) or **open** (needs a decision or another agent).

| Concept | Matching capture |
|---|---|
| `ConceptArt/saltgate/Abandoned Stone Quay Port-1.png` (front, three-quarter from the sea) | `slt_concept_front.png`, `slt_approach_OUTBOUND.png` |
| `ConceptArt/saltgate/Right-end view of the timber quay-2.png` | `slt_concept_rightend.png`, `slt_joint_from_sea.png` |
| `ConceptArt/saltgate/Stone quay workshop, rear view-3.png` | `slt_joint_from_walkway.png` (the rear is against the cliff, so it is seen from the walkway above) |
| `ConceptArt/channel_scenes/position of both saltgate and the cliff terrain.png` | `slt_concept_front.png`, `slt_joint_west.png` |
| `ConceptArt/dock/new dock front on.png` | `slt_concept_dockfront.png` (this concept is the island's harbour, `dock_harbour.glb`, not the Saltgate) |

## What matches

- The silhouette of the baked quay: two stone cottages with red clay-tile roofs, the timber workshop, the walled stone yard (the "plinth" the burner stands on), the gallows-style crane post at the west end, timber piles with cross-bracing along the front, mossy rock rubble at the base.
- The palette is the style guide's muted stone grey and slate; nothing is bright except the flag.
- No people anywhere.

## Differences

| # | Difference | Status | Why |
|---|---|---|---|
| 1 | The concept is one quay. The level uses the same quay mesh three times (Saltgate, SaltgateWest, SaltgateEast) linked by boardwalks, so identical cottages repeat along the shore and can be seen from the approach. | **open** (creator) | Making the copies different means new meshes, splitting the quay or regenerating huts: that is SLT-04/05, which waits on your polish-scope decision. |
| 2 | The concept's workshop doorway glows warm. In the level every window and door is dark. | **accepted** | Lore: "almost no light, dark windows" (`reg_saltgate.md`). |
| 3 | The level adds a tall pole with a tattered amber-and-gold flag. The concept has none. | **accepted** | Lore: "tattered amber-and-gold standards of Saint Calder". |
| 4 | Roof holes and chain rails read less clearly than in the concept: the holes are small at night, and only a few rope rails show between the edge posts. | **accepted** for now | It is the baked mesh at night lighting; sharpening it is hut and port polish (SLT-04, waiting). |
| 5 | In the channel concept the quay nestles in a rocky cove at the cliff foot. In the level it stands on piles in open water, 2 to 3 m in front of the walkway ledge and the cliff foot, under a high straight-faced cliff. | **open** (Cliffside + Saltgate) | The coves layout already puts the quay in the main cove, but the main cove's back wall is still straight. Rubble and rock at the cliff foot between quay and ledge is the Cliffside agent's planned CLF-15 (cove base dressing); the Saltgate side should be agreed with it in the joint contract, not built on its own. See the run report. |
| 6 | The level adds timber boardwalks and a timber link ramp up to the cliff walkway. Not in the concept. | **accepted**, link ramp **fixed** | They connect the quay to the walkway (creator decision: timber on the quay and boardwalks, rock from the walkway on). This run moved the link ramp off two old piles that stood up through it. |
| 7 | Concept: the dock reads as a clear landing stage. Level (before this run): the player was put on top of the walled yard, 1.3 m above the deck, and the launch lay 5.7 m off the quay. | **fixed** | The landing is now on the timber deck beside the yard and the berth is 4.5 m closer, so the launch lies alongside (`slt_concept_front.png`, `berth` captures). |
| 8 | Island harbour (`new dock front on.png`): the stone U-shape with two timber jetties and posts is there, but at ISLAND lighting it reads very dark and small from the sea. | **accepted** here | Not a Saltgate asset; noted for the Island and Lighting agents. |
| 9 | A large pale smudge on the cliff face above the quay (upper left in `slt_approach_OUTBOUND.png` and `slt_concept_front.png`). Not in the concept. | **open** (Cliffside) | It sits on the cliff face well above the quay (the quay mesh tops out at y 9.8), so it is not Saltgate geometry. I have not traced its cause; reported for the Cliffside agent to check. |
