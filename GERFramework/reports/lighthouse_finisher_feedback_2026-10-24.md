# Lighthouse Finisher: creator playtest feedback (2026-10-24 evening), to fix FIRST on 2026-10-25

**Plan agreed with the creator:** cover off this feedback at the start of tomorrow's session, then run the final assessment (LHF-16 regression, LHF-17 offline checks and both assessors' re-score, LHF-18 handoff and fallbacks). Nothing below is fixed yet. FAL spend is $5.25 of $7.80 ($2.55 left); none of this should need FAL.

The 20 screenshots are in `lighthouse_feedback_2026-10-24/` (1.png to 20.png; two are .webp). Items 14 and 15 came later with screenshots 19 and 20. The creator's list numbers screenshots loosely, so each item below says what it is about and **which screenshots I think show it (a guess, to confirm in the session)**.

## The list (the creator's words, then my first read)

| # | Feedback | First read: where to look (hypotheses, NOT confirmed) |
|---|---|---|
| 1 | There's a strange blue "disc" on the lighthouse | Screenshot 1 shows a pale green-blue elliptical band across the tower's outside, partway up. Suspects: a ring or disc mesh at that height seen from outside (a landing ring, the L2 ring, `L2_TowerRing`/lamp-green material, a light card pool, or the window light pool drawn through the wall). Find it with the audit's mesh list by height. |
| 2 | Missing textures over the door | The door surround or the wall above it: screenshot 2/3 area. Suspects: the opening kit's flat-colour stone material on the door arch (`flat_albedo`), the fanlight glass, or the baked texture missing where the carve left the wall. |
| 3 | The basement stairs need one more step at the same level as the floor, so the player can't fall straight down | `spiral_down.gd`: the top of the spiral (hall side). Add a final landing step flush with the ground floor (y 0.97) at the top, so the first tread isn't a drop from the hole's edge. Check with `test_spiral_down` (push-at-the-rail from 8 sides) plus a new fall test. |
| 4 | The start of the steps has an unnecessary gap between the steps and the wall | The tower stair's first steps (and/or the basement spiral foot): the visible tread covers radius 1.12 to 2.07 and a plain filler goes beyond; at landings the narrow steps leave a gap to the wall. `tower_shell.gd _stairs` (`StepFill_`), `stair_tread.gd`. |
| 5 | The L2 floor in general is really broken; this doorway looks awful and needs to be re-rendered | The L2 ring and the doorway between the tower and a house room (screenshots with the ragged frame, the sloped beam through the doorway). `rooms_tower.gd` (`_l2_ring`, `_doorframe`, `L1_TowerDoorFrame_*`) and the exterior's lumpy geometry showing round the opening. |
| 6 | The L2 floor in each of the rooms has disappeared | **Top suspect: `interior_culling.gd` (LHF-06, written today).** When the camera is above/inside the house footprint it hides whole levels, and the floor of a room could be on the wrong level (a slab at the boundary), or hidden while the player stands on the stair. First step tomorrow: switch culling off (`InteriorCulling` node) and see whether the floors return. Also check `roof_liner.gd` and the L1 floor slab (`L1_Floor`, y 5.2). |
| 7 | Some of the textures in T's room are cut | Ted's room (the keeper's quarters / L1): screenshots of the bed, desk and walls with flat triangular cut-outs. Suspects: the decimated hero props' textures or UV seams (bed, wardrobe, desk), the roof liner's holes (cells skipped), or the plaster lining. |
| 8 | The top of T's room looks like it has no walls | The gable walls above the knee wall at L1: **I noted this as not done in LHF-02** (the L1 ceiling liner follows the roof, but the gable ends have no lining). Needs gable wall panels and ceiling closure above the lining. |
| 9 | There's a leftover railing pole that needs to be removed from the steps | A vertical pole on a stair (screenshot of the window with the brown pole on the landing step). Suspects: a `StairRail_Post` that survived at a landing gap, or a `Lamp_StairRail` post. |
| 10 | Inconsistencies in the steps, and random island bits or objects jutting out of the wall | Floating wall-flaps and rocks in the tower wall (screenshots with angular brown/dark shards in the stone lining). These are exterior or island triangles poking through the lining (`probe_tower_intruders.gd` said 0, but it only probes the axis rays; the carve boxes may miss them), plus uneven tread heights. |
| 11 | There's a section of the stairs missing completely | A gap in the stair run (screenshot with a void between treads). Suspects: `STAIR_GAPS`/`LANDING_STEPS` narrow steps, the window-clearing rule in `tower_shell.gd _stairs` (`narrow = true` in front of the tower window above 13 m, which makes steps 0.176 thick and 2.07 reach but they should still be there), or culling. |
| 12 | The second-last screenshot is a window that's been implemented correctly; use it as the example for the others, including the light coming in | Screenshot 17 (the tall window with a mullion, stone reveals and a sea view with light). Make every window match it: reveal depth and stone, glass with a sky-lit look, a light pool on the floor (my `room_light_cards.gd` window pools exist for 8 windows, but several windows are not matching this). |
| 13 | There's a floating lightbulb in the lamp room that doesn't need to be there | The last screenshot (18): the bulb disc at the gallery rail on the lamp-room glass: `Lamp_RoomLamp` (`_wall_lamp(P, "Lamp_RoomLamp", 235.0, 2.6, FLOOR + 1.2, 1.2)` in `lantern.gd`), plus its halo card from `room_light_cards.gd`. Remove both (keep the light itself only if the room needs it). |

| 14 | The walls of the lighthouse are garbled, and there's a random window floating in space to the left of the main door | Screenshot 19 (a close view of the wall beside the door, from outside): dark box and slab shapes hanging off the wall, a window-like frame with nothing behind it. Suspects: my `exterior_openings.gd` masonry cells (`L1_west_Masonry` / `L1_back_Masonry`) or a window surround placed where the measured wall face fell back to a guessed plane (3 windows used the fallback: `T_stair_110_b`, `H_bed_west`, `H_wash_back`), so a surround floats off the wall; also the house-wall patches sitting on a median plane. The left of the door, seen from the dock, is the house's west wall: `H_bed_west`. |
| 15 | From the boat/sea the lighthouse looks really weird and the roof looks like it's floating in space; the windows also have a blue sheen now | Screenshot 20 (the lighthouse from the water). Suspects: (a) the **lamp-room/roof band**: I carved the gallery rail band (`carve_cylinders` y 18.45 to 19.9, r 4.25) and the old carves for the lantern; if the carve removed part of the tower shaft or cap geometry below the roof, the top looks detached; (b) the **ink outline** (`toon_outline.gdshader`) and cel shading acting on distant thin geometry; (c) the **blue sheen on windows**: my `room_light_cards.gd` sets the shared `glass` material's emission to the cold sky tint (`WINDOW_TINT`, 0.1 to 0.6 energy) so every pane glows blue, day and night, including seen from outside. Reduce or remove the emission, or restrict it to the inside. |

## STATUS, 2026-10-25 (fixes made in the morning session; all verified with shots and tests, 18 of 18 lighthouse tests and the audit gate pass)

| # | Result |
|---|---|
| 1 blue disc | **Fixed.** It was a floor light-pool quad of mine that, in the tower, reached out through the wall (found by listing every mesh that crosses the tower wall). Pools are now fitted inside their room (`room_light_cards.gd _fit_inside`). |
| 2 door textures | **Fixed.** A black mass above the door was my own front-wall masonry patch, wound the wrong way for Godot (lit from behind). Winding now follows the outward direction. The fanlight glass was also culled from outside; it is now two-sided and lit amber. The stone lintel still hides the lower half of the fanlight at low angles. |
| 3 basement stair top step | **Fixed.** A step flush with the hall floor (top at 10.58) before the first tread (`spiral_down.gd`, test checks the height). |
| 4 gap at the start of the steps | **Fixed.** The first narrow steps are filled out to the wall beyond the doorway. |
| 5 L2 doorway | **Mostly fixed.** The sloped beam through the L1 tower doorway (a rafter past the east wall) is gone; the wall opening is 1.3 m, matching its frame. A few ragged exterior-model flaps remain beside the doorway. |
| 6 missing floors | **Fixed.** My culling filed the first-floor slab (1.25 m thick) under the ground floor by its centre and hid the floor you stood on. It now files by the bottom edge; a test checks the floor stays drawn. |
| 7 cut textures in Ted's room | **Fixed.** A winding bug in my bevelled-box code left a triangular wedge out of every furniture box. |
| 8 no walls at the top of Ted's room | **Fixed.** Plaster gable panels close both ends of the roof (`trim.gd _gables`). |
| 9 stray pole | **Fixed** (the brass feed pipe standing on the L2 landing, removed; the test checks it stays gone). The brown diagonal pole across the L1 doorway in screenshot 17 was a rafter, also removed. |
| 10 shards in the wall | **Fixed.** The tower radius table had no data over the carved clearing at 15.5 to 17.5 m, so the lining sat too far out; it now uses the nearest measured radius. |
| 11 missing stair section | **Fixed.** The five steps in front of the landing window were deliberately narrow and left a void to the wall; they are filled either side of the window's own sector. |
| 12 windows like screenshot 17 | **Done for all 9** (the tower landing window at bearing 147 now gets the same reveals, mullion, glass, stone surround and floor light as the others; its floating wooden frame is gone). |
| 13 floating bulb | **Fixed.** The lamp-room wall lamp is removed. |
| 14 garbled walls, window floating left of the door | **Fixed.** The house's reveal boxes were 1.05 m deep on a wall as thin as 0.55 m and stuck out through it; they now stop inside the real face. The first-floor shell is now closed in stone wherever the exterior is missing, including the corner. The "window" itself was the 1.2 x 1.45 ground-floor carve's wooden frame, removed. |
| 15 roof looks floating from the sea; blue sheen on windows | **Fixed.** The lantern glass was 14% opaque, so the band under the roof read as empty sky; the lantern now has a denser pane, 24 mullions, three glazing rings and heavy sill and head rings. The blue sheen was my light-card code making the shared glass glow; that is removed. |

Not done: the ragged flaps of the exterior mesh at the sides of the L1 tower doorway; the stone lintel above the front door still covers most of the amber fanlight at street level.

New tools: `probe_pixel.gd` (which node is under a pixel of a shot), `probe_outside.gd`, `probe_wall_planes.gd`, `probe_window_face.gd`, `probe_tower_outside.gd`, `probe_greybox_tower.gd`; `shot.gd` gained SHOT_TORCH and SHOT_HIDE; `LHF_NO_CULL=1`, `LHF_NO_PATCH=1` triage switches.

## Suggested order for tomorrow
1. **Triage first (30 minutes):** switch culling off and re-shoot #6 and #11; take fresh shots at each reported spot from the same cameras, with a torch (`SHOT_TORCH=1`), and confirm which screenshot is which item.
2. Cheap, certain fixes: #13 (remove the lamp-room bulb), #9 (stray pole), #3 (extra step at the basement stair top), #4 (gap).
3. Exterior look: #14 (garbled walls, floating window) and #15 (the lighthouse from the sea: check the top band first). Then wall and stair geometry: #10 (intruders), #11 (missing run), #5 (L2 doorway re-render), #8 (gable walls), #7 (cut textures).
4. Windows: #12 (and the blue sheen, #15), copy screenshot 17's treatment to all 8, then #2 and #1.
5. Add regression tests for each (a fall test for #3, a no-gap test for the stairs, a floor-present test for #6) and re-run the 18 lighthouse tests plus `audit_lighthouse.gd -- check`.
6. Then the final assessment (LHF-16 to LHF-18).

## Context for whoever picks this up
- State of the work: `reports/lighthouse_finisher_work.md` (passes 1 to 9), plan `reports/lighthouse_finisher_plan.md`, FAL ledger `reports/lighthouse_finisher_fal_ledger.json`.
- Run the tests with the Godot console exe and `--headless --script res://tools/<test>.gd`; `shoot.sh` and `shoot_house.py` take stills (`SHOT_TORCH=1` for a torch, `SHOT_INTERIOR=1` for interior lights).
- Known trap: a headless test must not `await` inside `_physics_process` (it quits early and falsely passes).
- Many of these issues come from the same few places: the exterior mesh's ragged geometry showing round carved openings, the tower lining/stairs (`tower_shell.gd`, `rooms_tower.gd`), and today's culling and light cards.

## Round 3, 2026-10-25 (after the morning fixes; screenshots 21 to 27)
| # | Feedback |
|---|---|
| 16 | The outside of the lighthouse is now cut: replace that with wall consistent with the rest (screenshots 25, 26). |
| 17 | Smooth the external wall around the main entrance door (screenshot 26). |
| 18 | The internal colours look good but get washed out when further away: make the textures consistently visible (the lighthouse is the hero prop). |
| 19 | The panelling in the walls of the L2 level flickers in and out of view: always there (screenshots 22, 23, 24: sawtooth edges where the dark panelling meets the plaster). |
| 20 | Rain is coming down in the L2 room (screenshot 21). |
| 21 | The door frame to the L2 room is garbled: make it fit the angle of the internal room (screenshot 27). |

### Round 3 status (2026-10-25; 18 of 18 tests and the budget gate pass)
| # | Result |
|---|---|
| 16 outside "cut" | **Fixed in colour and shape.** The new masonry was a clean bright cream beside a dark, weathered wall (the baked texture's median brightness is about 22%). It now uses the wall's own colour with blotchy weathering, so patches blend in. |
| 17 smooth wall round the main door | **Done.** Two flat coursed-stone panels stand at the front-most lump either side of the door, up to the first-floor slab, with a clean stone passage (two reveals, a soffit and a floor) back to the door (`exterior_openings.gd _front_facade`). The upper storey's own wall is untouched. |
| 18 washed-out colours at distance | **Fixed.** Measured first: brightness fell from 0.64 at 1.8 m to 0.12 at 7.4 m because only 6 lights are live and each reaches a few metres; fog was a small part. Every interior surface now gives off a gentle amber fill of its own colour (`toon_look.gd fill`, 0.13) and ignores the distance fog. At 7.4 m the wall is now 0.26 and still warm. A neutral fill was tried first and greyed everything, so it is amber-tinted. The arc lamp's lens is excluded so it stays dark until the burner is fitted. F8 turns it all off. |
| 19 L1 panelling flicker | **Fixed.** The wall panels were coplanar with their walls on the thin axis (z-fighting); they now stand 3 cm proud on both faces. A test checks it for every panel. |
| 20 rain in the room | **Fixed.** The L2 ring and the stairwell out to the wall were not covered (three squares left pockets); it is now eight bars through the axis, and the first-floor attic up under the ridge is covered too. Tested at 192 ring points. Not verified: the GPU actually hiding the drops (headless has no GPU). |
| 21 doorway frame | **Fixed.** It was the east wall's plaster sheet poking through the tower lining beside the frame, plus a partition end. The sheet now starts where the lining hides it, the doorway has plaster reveals and a head, and the jambs are wider. |

Known: a small ragged stub remains at the bottom-right of the L1 doorway seen from the tower; the old exterior wall left of the facade is still the lumpy original.
