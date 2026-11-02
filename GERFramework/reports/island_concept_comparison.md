# Bracken Isle: concept art comparison (ISL-06)

Compared 2 November 2026 by the Island Creator Agent against in-engine captures of the real level (Godot render, not a mock-up).

- Concept: `ConceptArt/island/front view of island.png`, `Rear rocky island with stair and dock-1.png`, `Left-side view of craggy island dock-3.png`, `Right-Side View of Craggy Island Dock-2.png`.
- Captures: `GERFramework/shots/island/concept_front_ISLAND.png`, `concept_rear_ISLAND.png`, `concept_left_ISLAND.png`, `concept_right_ISLAND.png`: the same raised three-quarter angles (110 m out, 60 m up, 45 degree lens), with the front view taken along the line from the island's centre to the harbour, as the concept's front view looks at its dock. ISLAND phase, distance fog off so the whole rock reads (`tools/shot_phase.gd ... views=cmp_front,cmp_rear,cmp_left,cmp_right nofog`). Close-ups from the ISL-04 set (`isl_dock_*`, `isl_path_*`, `isl_gallery_*`) were used for the dock, stair, path and gate.
- Size: `LightingTheStorm/tools/measure_island_footprint.gd` (new, headless): the Island mesh AABB and the footprint above the waterline, found with rays on a 1 m grid.

Lore: "roughly 330 m long and 140 m wide" (`Docs/Lore Build/regions/reg_bracken_isle.md`; also `world/geography.md`); "a single narrow path from a small timber dock winding between jagged black rocks, an iron gate across the path, a few wind-bent trees, tattered amber and gold flags"; the dock "the only safe landing, facing the Saltgate".

## Measured size

| | Lore | Built |
|---|---|---|
| Mesh AABB (Island node) | | 90.0 m x 89.5 m, 17.9 m high (y -1.2 to 16.7) |
| Footprint above the waterline (y 0.4) | 330 m x 140 m (about 2.4 : 1) | 82 m (x) x 86 m (z); longest 91 m at a bearing of 40 degrees, 78 m across it (about 1.2 : 1); about 2,000 m2 above water |
| Highest rock | | 16.5 m, at (17, 16) |

The island is imported at a 90 m footprint (`tools/import_scale_pivot.gd`, `TARGET_FOOTPRINT_M["island"] = 90.0`). It is about a quarter of the lore's length, under two thirds of its width, and nearly round.

## Differences

| # | Aspect | Concept / lore | Built | Verdict |
|---|---|---|---|---|
| 1 | Size | Lore 330 x 140 m. The concept shows a long, roughly rectangular table of rock | 91 x 78 m, nearly round (import script scales it to 90 m) | **To decide: creator.** Scaling the rock by about 3.6x would move the dock, stair, gate, lighthouse ground, spray ring, colliders and the boat's route (Level.tscn, wave sheltering, ship lanes), and the 1-minute walk would become several minutes. Two cheap ways out: (a) change the lore to "roughly 90 m across" (it is a lighthouse rock, and the slice plays well at this size), or (b) keep the lore and treat the playable rock as the lighthouse end of a longer island, extended by background rock that the player cannot reach. Not changed |
| 2 | Shape and proportion | Long table with a broad flat top, cliffs all round | Round table, flat mossy top, cliffs all round | Follows from #1. **Accepted** for the slice: the cliff-and-table character matches |
| 3 | Cliffs | Tall pale-grey columnar cliffs with gold lichen, jagged pinnacles on the rim | Pale-grey columnar cliffs with pinnacles on the rim (`concept_rear_ISLAND.png` is the closest match) | **Match** |
| 4 | Top | Olive moss and grass over the whole top, small boulders, faint worn paths | Olive-yellow moss on the plateau with rock spikes. Under the toon look and moonlight it reads more yellow than the concept's olive | **Accepted**: the toon look and moonlight are the creator's (ISL-13); the concept is lit by flat daylight |
| 5 | Outlying rocks and surf | A ring of small rocks in white surf all round | Small rocks round the waterline, a spray ring (ISL-05), sea stacks farther out | **Match** in spirit; the surf is spray bursts, not a continuous foam line (the Wave agent's sea) |
| 6 | Buildings | None: the concept is the bare rock | The lighthouse and keeper's house stand on the high ground on a dark rock plinth (the lighthouse model's own base), which breaks the moss top (`concept_rear_ISLAND.png`) | **Accepted**: the lore puts the lighthouse there. The dark plinth is the lighthouse model's; if it should read as moss-topped rock, that is lighthouse work, not the island's |
| 7 | Dock | A stone-walled U-shaped quay at the cliff foot, a timber walkway on posts, **two timber gates** at the quay mouth | A stone quay (`dock_harbour.glb`) against the rock, two timber jetties on piers, two moored boats, two gas lampposts. No gates at the quay | **Accepted**: the lore has one lockable gate, on the path, and two more gates at the quay would muddle the gate puzzle (Arthur and Daniel at the gate). The quay and jetties sit correctly (ISL-07) |
| 8 | Dock direction | Lore: "facing the Saltgate" | The harbour is on the Saltgate (+z) side of the island, at its south-west corner, but the jetties open west (-x): the boat turns about 90 degrees after leaving | **Accepted, noted for the creator**: it is on the Saltgate side, the boat route and wave shelters are tuned to it, and moving it is a Level.tscn and route change. If "facing" should be literal, it is a creator decision |
| 9 | Stair | One straight stone stair cut into the cliff from the quay to the top (front and side views) | A straight stone stair (`HarbourStairs`) from the back of the quay to the plateau in three flights with landings and side walls (`isl_dock_ISLAND.png`) | **Match**. The built stair stands proud of the cliff on its own walls more than the concept's cut-in stair. Accepted (ISL-07: the route works and reads) |
| 10 | Path hugging jagged rock | A worn path crosses the moss between rock outcrops | From the stair top through the gate, about 20 m over the moss to the lighthouse door, with rock outcrops on both sides (`isl_path_ISLAND.png`). No worn track is painted on the moss | **Accepted**: the route reads (ISL-07, ISL-14), and the jagged rock either side keeps the player on it. A worn-track decal is cheap but optional, so it is left for the creator ("minor set pieces: keep simple") |
| 11 | Gate | None on the path (the concept's gates are at the quay) | An iron gate at the stair top (`IslandGate`, (-16.25, 9.95, 9.85)), tied into the rock both sides (ISL-14) | **Accepted**: the lore asks for an iron gate across the path; the concept predates it |
| 12 | Trees | None in the concept; the lore has "a few wind-battered trees" (species TBD) | None | **To decide: creator**: the species is TBD in the lore, and a tree model needs FAL credits (not spent here) |
| 13 | Flags | Lore: "tattered amber and gold flags" | The one flag in the level (`scripts/world/flag.gd`) stands at the Saltgate (10, 3.2, 546); none on the island | **Noted**: not part of the concept; for the creator if the flags should be on the island |
| 14 | Lighting | Flat grey daylight | Night: a low moon behind the lighthouse, storm sky, fog, rain (ISL-04) | **Accepted**: the game's lighting spec. The front (dock) face is in the moon's shadow, so from the sea it reads as a silhouette, as the spec intends |

## Cheap fixes made

None. Every difference is either accepted (with its reason above) or needs a decision that is not the island's to make (size, trees, flags, dock direction), and every fix would mean a Level.tscn edit (owned by the ISL-09 session today), FAL credits, or another agent's file. Nothing in the island's own files (materials, collider, reactions) differs from the concept in a way a cheap change would close.

## For the creator

1. **Size (#1)**: keep 90 m and change the lore line, or keep 330 x 140 m in the lore and add background rock? This agent recommends changing the lore to "roughly 90 m across" (geography.md and reg_bracken_isle.md).
2. **Trees (#12)**: none, or a few? If a few, which species? (A FAL model would be needed.)
3. **Dock facing (#8)**: is "on the Saltgate side" enough, or should the jetties open towards the Saltgate?
4. Optional: a worn track on the moss from the gate to the door (#10), and flags (#13).

## Creator decisions, 2 Nov 2026

1. **Island size:** fine as it is (about 90 m across). Accepted; the island is not rescaled and nothing is added.
2. **Trees:** none on the island.
3. **Dock facing:** the west-facing jetties are acceptable.
4. Worn track and island flags: not requested.
