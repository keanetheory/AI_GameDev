# Cliffside: recommendations (2026-10-20)

Status: proposals for the creator to approve. Nothing here has been built. Each new task would go through the normal loop (assessor review, then your all clear).

## 1. What your screenshots show, and the measured cause

All three reproduced in the real renderer from the same viewpoints (`GERFramework/shoot.sh`).

| Your image | What it is | Cause | Who caused it |
|---|---|---|---|
| 1: black stepped wall behind the path | The back of the rock "plug" wall I added to stop see-through. It stands above the plateau at the top end, and from behind it is unlit and black. Its top edge is stepped because it is built one metre at a time. | The plug's top is `max(floor + 4 m, cliff top - 0.6 m)`. Near the top of the ramp the floor is almost at the cap, so the plug rises about 4 m above the ground. | My last fix |
| 2 and 3: yellow ribbon over the walkway, dark void beneath, torn spiky edge | The grassy top of the cliff, left hanging over the cutting as a thin sheet. | The cliff modules are single-skin shells with no thickness. The cut deletes triangles and keeps whatever it doesn't catch, so strips of the grass cap survive over the cut and show their torn edges. | The cutting approach (present since before this session's fixes; my fixes made the walkway visible enough to see it) |
| 3: pale block at right | Part of another window in your screenshot. | Not the game. | n/a |

My tests passed because they looked from inside the cutting and by ray, never from the plateau or at the grass cap. Rays do not see "black".

## 2. The root problem

The walkway is made by cutting triangles out of 150,000-triangle, single-skin AI-generated cliff meshes at load time, then patching what is left (copy wall, plug, toe, shelf, spike pushes). Every patch cures one artefact and exposes another. More patches will not converge. It also costs about 2.5 s of the level's load time.

## 3. Recommendation: stop cutting, and build coves (also resolves CLF-09)

You are happy for coves to replace the one straight wall. That gives us the clean fix: **build the walkway into the cove's back wall as its own closed piece, and place the existing cliff modules around it uncut.**

### New tasks (proposed, with scores)

| ID | Score | Task | Why this score |
|---|---|---|---|
| CLF-12 | 10 | **Stop-gap for the two visible faults now**: lower the plug well below the plateau and end it earlier; delete the cap ribbons over the cut. | They are visible on the main walk and a regression I introduced. Not a long-term fix, but it takes under an hour and makes the current build clean. |
| CLF-13 | 9 | **Replace the runtime cut with a baked, closed walkway module**: floor, back wall with real rock relief (columns), shelf, toe and a proper end cap, all in the cliff's own material, with collision. Built once, not at load. | Removes the whole class of bug and the 2.5 s carve. |
| CLF-14 | 9 | **Coves layout**: re-place the ten cliff modules as a coastline of headlands and coves (the two headland modules face the sea; wall modules curve inland to make coves), with the Saltgate quay and the walkway in the main cove. Make the layout data-driven (one table, not ten hand-placed nodes). | Your decision, and what the concept art shows. Highest-risk change, so it comes before the dressing. |
| CLF-15 | 8 | **Cove base dressing**: rubble and scree at the cliff foot, a few sea stacks at the headland bases, spray hooks for the Wave agent. | The concept art's missing foot detail. |
| CLF-16 | 7 | **Slimmer pines and a softer path edge** to replace the stylised cones near the path and cliff edge. | Closest remaining gap to the concept art. |
| CLF-17 | 6 | **Visual regression check**: render fixed camera positions along the walkway, the top junction and the path, and fail if any frame has a large black area or a missing-ground gap. | This is what my tests lacked. |
| CLF-09 | (done, amended) | Comparison note updated: coves are now accepted. | |

### Order and dependencies

1. CLF-12 now (clean build while the rest is designed).
2. CLF-14 coves layout first, because CLF-13 must be built to the cove's back wall shape.
3. CLF-13 walkway module, then CLF-15 and CLF-16 dressing, with CLF-17 added early so each step is checked visually.

### What the coves must not break

- **The boat route.** The channel runs along z about 18 to 527. Coves must recede inland (higher z). Headlands must not protrude into the route. The sea-stack hazards keep their positions.
- **The Saltgate joint** (`contracts/port_cliff_joint.md`): the quay sits inside the main cove, and the joint heights stay as agreed.
- **Lore**: the Saltgate is a natural harbour with a clear channel; coves fit.

## 4. Alternatives, in case you prefer them

| Option | What | Verdict |
|---|---|---|
| A. Only CLF-12 | Fix the two visible faults, keep the straight wall | Cheap. The dark slits between columns and the load cost stay. Good as a first step in any case. |
| B. Baked clean cut, keep the straight wall | Clip the cliff modules with a proper offline slicer, cap the cut, export a new GLB | Robust and fixes load time, but gives no coves. |
| C. Coves plus baked walkway (recommended) | CLF-12, 14, 13, 15, 16, 17 | Fixes the root cause and gets the concept coastline. Largest effort. |

## 5. Decisions I need from you

1. Approve **Option C** (or A or B).
2. **How many coves?** Recommendation: two or three: one main cove (quay and walkway) and one or two smaller ones, with headlands between.
3. **Cliff height and the walkway**: keep the climb to the same cliff-top height (about 38 m), or lower it in the coves? Recommendation: keep.
4. Can I start CLF-12 now as an immediate fix before the rest is approved?
