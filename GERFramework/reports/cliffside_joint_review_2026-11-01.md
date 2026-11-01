# Cliffside review of port-to-cliff joint contract v3 (read-only, 2026-11-01)

Scope: read the contract (v3), `Level.tscn` and the state records. No scene, mesh or script was edited and no test or Godot run was done, because another session has uncommitted Saltgate work in the tree (T49: `Level.tscn`, `boat.gd`, `burner_pickup.gd`, `saltgate_hut.gd`, and a deleted baked quay collider).

## Verdict on the v3 changes (1 to 3)

| Change | Cliffside view |
|---|---|
| 1. Landing moved to timber deck, y 3.12 | Accept in principle. Deck is 0.12 m above the walkway quay end (3.0), inside the 0.4 m step-up. |
| 2. Berth moved z 527 to 531.5 | Accept. Not a Cliffside value. `Level.tscn` now shows `DockZonePort` at (6, 0.15, 531.5). |
| 3. `BoardwalkLink` moved to x 4.85, 1.6 m wide | Accept. Top within 0.13 m of the walkway floor, largest walked step 0.08 m. |
| 4. Boardwalk ends, walkway, cliff modules, `bake_walkway.gd` output untouched | Confirmed by the contract. Not re-checked by a run. |

## Stale after T49 (do not rely on v3 until rewritten)

- v3 describes a raised, walled stone plinth and a dock landing beside it. T49 (19c5aa7 and later work) carved out the pier head and steps and put `SaltgateHut` at dock level (5.07, 4.4, 539.6) with `SaltgateHutSteps` and a plank deck. The v3 table rows for the landing and plinth need rewriting.
- The quay collider was rebaked. The ray-probe results (taper x 30 to 46 clear of quay geometry, boardwalk-end heights) were measured on the old mesh and must be re-run.
- The contract says the burner sits on the plinth. It is now inside the hut (creator accepted 2026-11-01).

## Still open for the joint

1. Quay stands on piles 2 to 3 m in front of the walkway ledge and cliff foot, so it does not yet grow out of the cliff (SLT-02 and CLF-06 acceptance).
2. Proposed build: extend CLF-15 cove base dressing (`scripts/world/cliff_dressing.gd`) at the main cove so rubble and rock run from the cliff foot to the quay piles, with the waterline as one rock-and-stone line. Keep the boat route and the landing strip and hut approach clear.
3. Rule 7 check: the CLF-15 change touches the area near the quay, so the Saltgate side must review it in turn.

## Wait list (until the other session is committed)

- Rewrite contract as v4 from the post-T49 state.
- Re-run `test_disembark.gd`, `test_cliffwalk.gd`, `test_walkway_continuity.gd`, `test_cliff_clean.gd` and the seam ray tests.
- Build the cove base dressing joint, then close CLF-06 and SLT-02.
