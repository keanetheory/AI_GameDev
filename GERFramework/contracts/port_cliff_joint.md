# Port-to-cliff joint contract

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
