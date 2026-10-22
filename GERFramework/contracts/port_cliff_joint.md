# Port-to-cliff joint contract

**Version 3, 2026-10-22 (Saltgate side added; awaiting the Cliffside agent's review of the changes listed under "Saltgate changes, 2026-10-22").** Version 2 follows unchanged below it.

## Saltgate answers, from measurement (2026-10-22)

Measured in the running level (headless ray probes and `tools/test_disembark.gd`, which walks the real Player capsule).

| Open question (v2) | Answer | Evidence |
|---|---|---|
| Do the steps at the quay end stay where they are? | **There are no stone steps at the Saltgate.** No `stone_stairs.gd` node exists there (the only one is `HarbourStairs` on the island). The "dock landing" at y 4.35 to 4.40 is the top of a raised, walled stone plinth standing on the timber quay (the burner sits on it), not a walk route. The quay deck the player walks on is timber at y 3.07 to 3.12, level with the west boardwalk (3.05) and the walkway's flat quay end (3.0, x 14 to 40). So no steps are needed: the quay meets the walkway through the west boardwalk and the timber link ramp (`BoardwalkLink`), and through the east boardwalk. Proposal: item 3 below becomes "the quay deck (y 3.1) meets the walkway through the boardwalks and the timber link ramp; no stone steps". | probe heights; `test_disembark` leg "boardwalk end to the cliff walkway": no drop, largest step 0.08 m |
| Are the three quay instances' east ends clear of the taper (x 30 to 46)? | **Yes, by measurement.** The main `Saltgate` instance's bounding box reaches x 48.3, but no quay geometry stands above the walkway floor anywhere in the taper: rays at 0.5, 1.5, 3 and 5 m behind the floor's front edge all hit the walkway floor (y 2.75 to 3.02) for x 30 to 46. `SaltgateEast` (x 71 to 139) and `SaltgateWest` (x -107 to -43) are well clear. | ray probe, x 46 to -12 every 2 m |
| If the coastline becomes coves, does the quay stay in the main cove? | **Yes.** `data/world/cliff_layout.json` (`coast_v1_three_coves`) already has the quay and the walkway in the MAIN cove (x -255 to 165). | layout file |

## Saltgate changes, 2026-10-22 (rule 7: the Cliffside agent to review)

1. **Dock landing** (a value in the table below): `DockZonePort.landing` moved from (6, 4.4, 538.5) on top of the plinth to (1.5, 3.12, 538.5) on the timber deck beside it. Stepping ashore no longer leaves the player on a block with a 1.4 m drop on every side. The table row should read "dock landing: timber deck, y 3.12".
2. **Berth** (not in the table): `DockZonePort` moved from z 527 to z 531.5, so the launch lies about 1.5 m off the quay's piles instead of 5.7 m, and the player can board from the landing (8.3 m, inside the 10 m board radius).
3. **Timber link ramp** (`BoardwalkLink`, not in the table, but its top end rests on the walkway floor): moved from x 3.2 (width 2.4, top (3.2, 4.9, 557.5)) to x 4.85 (width 1.6, top (4.85, 4.62, 557.9)). Two of the quay's own piles (tops at y 4.6) stood inside the old ramp, one through its foot at about (3.7, 553.4); a walker climbed onto them and dropped 0.65 m off. The new line runs between two piles. Its top overlaps the walkway floor by about 0.5 m and sits within 0.13 m of it across its width (largest step measured walking it: 0.08 m). `tools/test_cliffwalk.gd` (a Cliffside file) walks the old ramp line; see the run report for what was done about it.
4. **Not changed:** the ends of `BoardwalkWest` and `BoardwalkEast` (rule 2), the walkway, the cliff modules, `bake_walkway.gd` output.

## Still open after 2026-10-22

- The Cliffside agent's review of changes 1 to 3.
- The landing strip (the timber deck between the plinth, the hut north of it and the quay's edge piles) reaches the rest of the quay only through a gap about 0.75 m wide between a bollard and a stone block in the baked quay mesh. Widening it means editing the quay mesh or adding a structure, which is the creator's SLT-04/05 decision. It does not touch this joint.

---

# Version 2 (2026-10-20)

**Version 2, 2026-10-20.** Cliffside side written by the Cliffside Creator Agent. Saltgate side: the creator told us to start agreeing the joint with the Saltgate agent. The Saltgate agent's plan is still NOT approved for building, so this version records measured facts and the Saltgate-side answers as proposals; nothing on the Saltgate side has been built.

## Creator decisions that apply (2026-10-20)

- **Timber stops, stone starts.** Timber is on the quay and the boardwalks only. From the first step onto the walkway, every walked surface is cliff rock.
- **Walkway width:** 6 m (unchanged).
- Coves are welcome in place of the one straight cliff wall (see `reports/cliffside_recommendations.md`). Any cove layout must keep the quay inside a cove and this joint intact.

## Measured facts (probe of the running level)

| Where | Height | Notes |
|---|---|---|
| Walkway floor at its quay end (x 46 to 16) | y = 3.00 | `RAMP` first control point |
| Timber boardwalk deck (z about 555, x 36 to 70) | y = 2.67 to 2.77 | falls slowly eastward |
| Quay stone landing (z about 558 at x = 70, and the dock landing) | y = 4.35 to 4.40 | 1.35 m above the walkway floor |
| Walkway start | x = 46, z about 561.3 | `GAL_X0` |
| Taper (cut grows from nothing to full depth) | x = 46 to 30 | `GAL_FLARE` |
| Quay instances | Saltgate (15, -1.6, 549.9), SaltgateEast (105, -1.6, 546.6), SaltgateWest (-75, -1.6, 545.6) | `Level.tscn` |

So today the boardwalk deck is 0.25 to 0.3 m below the walkway floor where they meet (inside the player's 0.4 m step-up, which is why the walk tests pass), and the quay stone is 1.35 m above it.

## Proposed agreement

1. **Height at the seam:** the walkway floor's first 6 m ramps from the boardwalk deck height (y 2.75) up to 3.0, so there is no step. *Cliffside agent builds this.*
2. **Overlap:** the floor runs 1 m under the boardwalk's end. *Saltgate agent does not move the boardwalk ends without telling the Cliffside agent.*
3. **Quay stone to walkway:** the quay stone (y 4.4) meets the walkway through the stone steps (`stone_stairs.gd`) at the quay end. *Open: the Saltgate agent owns these steps. Proposal: it keeps them and the Cliffside agent matches the rock to them.*
4. **Material:** timber to the first step, cliff rock after it. *Decided.*
5. **Collision:** one continuous surface on layer 1 from the boardwalk to the cliff top. No invisible lips.
6. **Seam dressing:** stonework and props may cover the seam but must not hide it with a flat plane.
7. **Change rule:** a change to any value in the table or the files named needs the other agent's review.

## Still open for the Saltgate agent

- Confirm the steps at the quay end stay where they are.
- Confirm the three quay instances' east ends are clear of the taper (x 30 to 46).
- Confirm that if the coastline becomes coves, the quay stays in the main cove.
