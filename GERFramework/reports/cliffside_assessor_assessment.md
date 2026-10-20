# Cliffside Assessment Agent: assessment of existing work

- knowledge up to date; 51 docs read, 48 hard rules, 7 open questions held
- Feedback goes to: cliffside_creator, saltgate_creator
- Failing checks: **2**

**Mandate:** Hold the Cliffside Creator Agent to the lore, the GDD and the cliff concept art: no empty or hollow meshes, no gaps between cliff modules, a quick load, a walkway from the Saltgate to the cliff top that is made of the same rock as the cliff (not a separate ramp), and trees and path integrated into the rock. Offline AI Crew and deterministic checks only.

| ID | Score (1-10) | Result | Evidence |
|---|---|---|---|
| CLI-01 | 8 | FAIL | cliff_wall.glb: 26.04 MB, 150,000 tris, 1 meshes (empty 0, unreferenced 0), hole loops 0 (open edges 0.0%), degenerate 0, textures [[4096, 4096]] (~89.3 MB VRAM)  FAIL: 4,096 px texture > limit 2,048 |
| CLI-02 | 8 | FAIL | cliff_headland.glb: 26.29 MB, 149,916 tris, 1 meshes (empty 0, unreferenced 0), hole loops 0 (open edges 0.0%), degenerate 0, textures [[4096, 4096]] (~89.3 MB VRAM)  FAIL: 4,096 px texture > limit 2,048 |
| CLI-03 | 4 | PASS | LightingTheStorm/scenes/Level.tscn: 10 nodes match /CliffWall\d/Headland\d/CapEast/ (need >= 10) |

## Open questions this assessor will not let anyone settle silently

- | [[cul_calder_city]] | Distrust and resentment (Ted: "new money toffs") | TBD. Linked to the city abandoning the Saltgate? |  (Docs/Lore Build/cultures/cul_coastfolk.md:76)
- - **Size and terrain:** roughly 330 m long and 140 m wide (about three football pitches by two). Rocky and windswept, with a few wind-battered trees that flower in spring (species TBD).  (Docs/Lore Build/regions/reg_bracken_isle.md:17)
- | The lighthouse | Single building | Guards the approach to the Saltgate. During eclipses it is the only true light by which ships can see the rocks. | TBD | Stone and mortar, battered but robust. Hau  (Docs/Lore Build/regions/reg_bracken_isle.md:23)
- - **The gate:** a lockable gate on the path to keep intruders out. After feeding the boiler, the player opens it for Arthur and Daniel. What it was originally built to keep out is TBD.  (Docs/Lore Build/regions/reg_bracken_isle.md:29)
- - Prevailing wind direction: TBD. It should match the lean of Bracken Isle's trees.  (Docs/Lore Build/world/geography.md:33)
- 9. Outbound crossing penalties. With no deadline before the return crossing, collisions on the outbound crossing cost no deadline time. Decide what they cost instead (for example a slowdown or recover  (Docs/GDD/Final_GDD_Post_Review/Supporting_Documentation/Decisions to be made.md:49)
- Ted reacts from the lamp room by voice. If the burner is fitted first, the win state shows the ship sailing safely past the rocks and into port, again from the lamp room. Gate 1 fail returns to the st  (Docs/GDD/Final_GDD_Post_Review/Technical Strategy.md:92)