# Saltgate Assessment Agent: assessment of existing work

- knowledge up to date; 51 docs read, 60 hard rules, 13 open questions held
- Feedback goes to: saltgate_creator, cliffside_creator
- Failing checks: **1**

**Mandate:** Hold the Saltgate Creator Agent to the lore (an abandoned, dark, eerie harbour district of Saint Calder), the GDD (Saltgate minimal until the prototype is complete; burner pickup; docking and disembarking) and the quay concept art: polished huts and port, a smooth boat-to-quay arrival, a port that grows out of the cliff, and canon respected (no people, no invented reason for abandonment). Offline AI Crew and deterministic checks only.

| ID | Score (1-10) | Result | Evidence |
|---|---|---|---|
| SAL-01 | 8 | FAIL | saltgate_quay.glb: 30.9 MB, 248,958 tris, 1 meshes (empty 0, unreferenced 0), hole loops 0 (open edges 0.0%), degenerate 0, textures [[4096, 4096]] (~89.3 MB VRAM)  FAIL: 4,096 px texture > limit 2,048 |
| SAL-02 | 4 | PASS | dock_harbour.glb: 7.73 MB, 91,022 tris, 1 meshes (empty 0, unreferenced 0), hole loops 0 (open edges 0.0%), degenerate 0, textures [[2048, 2048]] (~22.3 MB VRAM) |
| SAL-03 | 4 | PASS | LightingTheStorm/scenes/Level.tscn: 9 nodes match /Saltgate.*/Boardwalk.*/DockZonePort/BurnerPickup/ (need >= 7) |

## Open questions this assessor will not let anyone settle silently

- | [[cul_coastfolk]] | TBD (they abandoned the coast) | TBD |  (Docs/Lore Build/cultures/cul_calder_city.md:39)
- | [[cul_calder_city]] | Distrust and resentment (Ted: "new money toffs") | TBD. Linked to the city abandoning the Saltgate? |  (Docs/Lore Build/cultures/cul_coastfolk.md:76)
- 3. Ted and Arthur's relationship is TBD in the lore; the 'drowned by now' exchange (ARTHUR_S2_05, TED_S2_04) is flagged as a proposal only.  (Docs/Lore Build/dialogue/archive/2026-10-15_before_creator_picks/DIALOGUE_OPENING_FINAL.md:320)
- | The lighthouse | Single building | Guards the approach to the Saltgate. During eclipses it is the only true light by which ships can see the rocks. | TBD | Stone and mortar, battered but robust. Hau  (Docs/Lore Build/regions/reg_bracken_isle.md:23)
- | Fort Kestrel | Fortress | Guards the western coast, about one mile west of the lighthouse | TBD | Manned and active. Lit and flying flags, but no one visible on the walls. |  (Docs/Lore Build/regions/reg_calder_coast.md:23)
- | Fort Heron | Fortress | Guards the mouth of the Marrow, about one mile east of the lighthouse | TBD | Manned and active. Lit and flying flags, but no one visible. The Marrow is too small for the pas  (Docs/Lore Build/regions/reg_calder_coast.md:24)
- - **The quays:** the player lands here with Arthur to retrieve the replacement beacon burner. The exact storage location is TBD.  (Docs/Lore Build/regions/reg_saltgate.md:27)
- Formerly the city's harbour. Why it was abandoned is TBD (L5).  (Docs/Lore Build/regions/reg_saltgate.md:32)