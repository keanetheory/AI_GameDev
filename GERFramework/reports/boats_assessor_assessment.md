# Boats - Assessment Agent: assessment of existing work

- knowledge up to date; 51 docs read, 60 hard rules, 5 open questions held
- Feedback goes to: Boat / Physics agent, wave_creator
- Failing checks: **2**

**Mandate:** Assess the steam launch and the rowboat (models, controller, spec) against the lore, the GDD and the boat concept art: one fixed speed, A/D steering only, auto-docking, collision recovery, the cargo slot, the water_push tide hook, and the boat riding the sea surface. Flags conflicts between the GDD and the spec. There is no Boats creator in this batch: feedback goes to the existing Boat / Physics agent and to the Wave creator where the sea is involved.

| ID | Score (1-10) | Result | Evidence |
|---|---|---|---|
| BOA-01 | 7 | FAIL | boat_launch.glb: 23.84 MB, 99,702 tris, 1 meshes (empty 0, unreferenced 0), hole loops 0 (open edges 0.0%), degenerate 0, textures [[4096, 4096]] (~89.3 MB VRAM)  FAIL: 4,096 px texture > limit 2,048 |
| BOA-02 | 7 | FAIL | rowboat.glb: 7.37 MB, 60,000 tris, 1 meshes (empty 0, unreferenced 0), hole loops 1268 (open edges 43.7%), degenerate 0, textures [[2048, 2048]] (~22.3 MB VRAM)  FAIL: 1,268 hole loops > limit 0 |
| BOA-03 | 9 | PASS | LightingTheStorm/scripts/world/boat.gd: /water_push/ matched 3 (need >= 2) |
| BOA-04 | 9 | PASS | LightingTheStorm/data/world/boat_spec.json: /"waves_enabled"/ matched 1 (need >= 1) |
| BOA-05 | 6 | PASS | python main_asset.py sample_submissions/boat_hunyuan_v3.fal.json --check-only -> rc 0: [asset] boat_launch (boat): APPROVE, 0 finding(s) /  / [asset] 1 approved, 0 need revision. Output: C:\GameDev\AI_GameDev\GERFramework\state\crew_out |

## Open questions this assessor will not let anyone settle silently

- - **The quays:** the player lands here with Arthur to retrieve the replacement beacon burner. The exact storage location is TBD.  (Docs/Lore Build/regions/reg_saltgate.md:27)
- 9. Outbound crossing penalties. With no deadline before the return crossing, collisions on the outbound crossing cost no deadline time. Decide what they cost instead (for example a slowdown or recover  (Docs/GDD/Final_GDD_Post_Review/Supporting_Documentation/Decisions to be made.md:49)
- Ted reacts from the lamp room by voice. If the burner is fitted first, the win state shows the ship sailing safely past the rocks and into port, again from the lamp room. Gate 1 fail returns to the st  (Docs/GDD/Final_GDD_Post_Review/Technical Strategy.md:92)
- • Two weather channels (Decision B). Perceptual channel (wind, rain, lightning, thunder, ship’s lights, sky mood) follows elapsed time. Hazard channel (density, route width, hazard visibility) follows  (Docs/GDD/Final_GDD_Post_Review/What's Changed.md:88)
- • Sequence. Expanded to ten steps: orchestrators write the briefs; Ted is locked by week 3; Hazard Forecast joins the steering spike; Story/Fail-State implements the fail-state contract before week 5   (Docs/GDD/Final_GDD_Post_Review/What's Changed.md:136)