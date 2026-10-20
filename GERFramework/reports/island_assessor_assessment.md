# Island Assessment Agent: assessment of existing work

- knowledge up to date; 51 docs read, 60 hard rules, 14 open questions held
- Feedback goes to: island_creator
- Failing checks: **0**

**Mandate:** Hold the Island Creator Agent to the lore and the GDD for Bracken Isle: no holes, no empty or unreferenced meshes, a collider that matches what the player sees, a quick load, correct lighting in every phase, and a faithful read of the island concept art. Review the plan first, then the finished work, using only the offline AI Crew and deterministic checks.

| ID | Score (1-10) | Result | Evidence |
|---|---|---|---|
| ISL-01 | 4 | PASS | island_craggy.glb: 13.04 MB, 199,968 tris, 1 meshes (empty 0, unreferenced 0), hole loops 0 (open edges 0.0%), degenerate 0, textures [[2048, 2048]] (~22.3 MB VRAM) |
| ISL-02 | 4 | PASS | LightingTheStorm/scenes/Level.tscn: 4 nodes match /Island/RockPatch.*/ (need >= 4) |

## Open questions this assessor will not let anyone settle silently

- - **backstory:** caught in the storm and sought shelter on Bracken Isle. Why he and Daniel were out on the water is TBD (smugglers?).  (Docs/Lore Build/characters/chr_arthur.md:53)
- | [[cul_calder_city]] | Distrust and resentment (Ted: "new money toffs") | TBD. Linked to the city abandoning the Saltgate? |  (Docs/Lore Build/cultures/cul_coastfolk.md:76)
- | 2 | `GATE_APPROACHED` | `ARTHUR_S2_02` | `ARTHUR_S2_01` | "We mean no harm" reads wary and may hint at a reason for being on the water (open decision). |  (Docs/Lore Build/dialogue/DIALOGUE_OPENING_CREATOR_PICKS.md:29)
- - **Size and terrain:** roughly 330 m long and 140 m wide (about three football pitches by two). Rocky and windswept, with a few wind-battered trees that flower in spring (species TBD).  (Docs/Lore Build/regions/reg_bracken_isle.md:17)
- | The lighthouse | Single building | Guards the approach to the Saltgate. During eclipses it is the only true light by which ships can see the rocks. | TBD | Stone and mortar, battered but robust. Hau  (Docs/Lore Build/regions/reg_bracken_isle.md:23)
- - **The gate:** a lockable gate on the path to keep intruders out. After feeding the boiler, the player opens it for Arthur and Daniel. What it was originally built to keep out is TBD.  (Docs/Lore Build/regions/reg_bracken_isle.md:29)
- - Prevailing wind direction: TBD. It should match the lean of Bracken Isle's trees.  (Docs/Lore Build/world/geography.md:33)
- TBD (coal supply for the lighthouse engine, fresh water on Bracken Isle).  (Docs/Lore Build/world/geography.md:41)