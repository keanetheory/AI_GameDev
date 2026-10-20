# Lighthouse - Exterior Assessment Agent: assessment of existing work

- knowledge up to date; 51 docs read, 41 hard rules, 5 open questions held
- Feedback goes to: lighthouse_interior_creator, island_creator
- Failing checks: **0**

**Mandate:** Assess the existing lighthouse exterior model (lighthouse_exterior_v3.glb) against the lore, the GDD and the lighthouse concept art, and report what the Lighthouse Interior and Island creators must respect: the true dimensions, the solid house-to-tower wall that still needs carving, the door, the silhouette as the beacon landmark, and mesh and texture health. There is no exterior creator in this batch, so this agent reviews the existing asset and the plan of any creator whose work touches it.

| ID | Score (1-10) | Result | Evidence |
|---|---|---|---|
| LIG-01 | 9 | PASS | lighthouse_exterior_v3.glb: 7.69 MB, 39,978 tris, 1 meshes (empty 0, unreferenced 0), hole loops 0 (open edges 0.0%), degenerate 0, textures [[2048, 2048]] (~22.3 MB VRAM) |
| LIG-02 | 8 | PASS | LightingTheStorm/Assets/Models/lighthouse/interior/lighthouse_greybox_v3_alignment.json exists |
| LIG-03 | 8 | PASS | LightingTheStorm/Assets/Models/lighthouse/interior/exterior_door_measured.json exists |
| LIG-04 | 5 | PASS | LightingTheStorm/scenes/Level.tscn: 1 nodes match /Lighthouse/ (need >= 1) |

## Open questions this assessor will not let anyone settle silently

- | The lighthouse | Single building | Guards the approach to the Saltgate. During eclipses it is the only true light by which ships can see the rocks. | TBD | Stone and mortar, battered but robust. Hau  (Docs/Lore Build/regions/reg_bracken_isle.md:23)
- | Fort Kestrel | Fortress | Guards the western coast, about one mile west of the lighthouse | TBD | Manned and active. Lit and flying flags, but no one visible on the walls. |  (Docs/Lore Build/regions/reg_calder_coast.md:23)
- | Fort Heron | Fortress | Guards the mouth of the Marrow, about one mile east of the lighthouse | TBD | Manned and active. Lit and flying flags, but no one visible. The Marrow is too small for the pas  (Docs/Lore Build/regions/reg_calder_coast.md:24)
- - **The quays:** the player lands here with Arthur to retrieve the replacement beacon burner. The exact storage location is TBD.  (Docs/Lore Build/regions/reg_saltgate.md:27)
- TBD (coal supply for the lighthouse engine, fresh water on Bracken Isle).  (Docs/Lore Build/world/geography.md:41)