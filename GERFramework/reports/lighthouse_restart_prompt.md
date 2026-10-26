# Lighthouse restart prompt (paste into a fresh session)

Suggested model: Fable 5.1 or Opus 5.5 for diagnosis and the shell rebuild plan; Sonnet 5.5 is fine for implementation once failing tests and a plan exist.

```
You are finishing the Saint Calder lighthouse in LightingTheStorm (Godot 4.3, Forward+).
Read first, in this order: GERFramework/reports/lighthouse_finisher_work.md,
GERFramework/reports/lighthouse_finisher_feedback_2026-10-24.md (all three rounds),
and the memory note lighthouse-finisher-approval. Do not change the engine version.
FAL budget: $5.25 of $7.80 spent; do not spend more without telling me the exact amount.

GOAL
The lighthouse is the hero prop of the game. It must be: observable and consistent from
any distance (silhouette, material, roof seated on the walls); consistently lit in every
room at any distance, including the basement; free of any mesh clipping through another;
and built from doorways, stairs, windows and props that follow real-world scale and
clearances. Cel-shaded style (approved) stays.

WHAT IS KNOWN TO BE WRONG (still, after many fixes)
- Rain still comes through the roof on the L2 floor. My hypothesis (unverified): rain
  spawns ~12 m above the camera, which at L2 can be INSIDE the shelter volumes, and a
  particle that starts inside a GPUParticlesCollisionBox3D is never "hit".
- The basement is still washed out. It was never measured; the lighting fix was tuned on
  the ground floor only.
- Repeated churn: fixes keep creating new clipping because a code-built interior (about
  1,200 boxes, patches, carves, light cards) is layered on a generated exterior mesh that
  has holes and torn edges.

RULES
1. One root cause at a time. Before changing anything, reproduce the fault with a test or
   measurement that currently FAILS, and show me its output. If you cannot make it fail,
   you have not found the fault.
2. No symptom patches. Never hide a fault with a new mesh, carve, patch or light card.
   Fix the layer that is wrong, or remove that layer.
3. After each fix: run the full lighthouse test suite and the clipping audit, then commit
   (small commits). If anything else regresses, revert and tell me.
4. Judge visuals with numbers, not by eye: lighting = mean brightness and saturation of
   fixed wall samples at 2, 4, 6, 8 m in EVERY room including the basement; rain = a test
   proving no drop is drawn inside any interior volume. Headless runs cannot render
   particles, so the rain test must be a CPU check of spawn positions and volumes, or run
   in a windowed render with captured frames.
5. No new features. If something unrelated looks wrong, list it, do not fix it.
6. Never write a headless test that awaits inside _physics_process (it quits early and
   falsely passes).

ORDER
A. Build the missing tools first: (1) a clipping audit (no mesh inside another layer's
   solid, no interior geometry outside the walls, nothing crossing a wall, doorways and
   props at real-world scale and clearance), (2) a lighting probe (per room, by distance),
   (3) a rain probe (spawn positions vs interior volumes, and drawn drops vs volumes).
B. Rain: find where rain spawns relative to the interior volumes at the L2 ring, stairwell
   and attic, fix the cause, prove it with the probe.
C. Lighting: make the interior consistent at any distance and in every room. Prefer baked
   lighting (LightmapGI or VoxelGI) over adding live lights; the interior currently has 6
   live lights at a time, which is what makes far walls fall dark.
D. THE SHELL DECISION (do this before more patching): the generated exterior is the
   source of the clipping. Propose, and after my approval build, ONE clean authored
   modular shell in Blender (use the Blender tools): thick walls with real window and door
   openings, stairs to the real-world standard in data/world/stair_spec.json, floors,
   rooms, the lantern, roof seated on the walls. Export it as a single glb, keep the
   existing props (hero props, boiler fire, posters, lamp) and the cel look on top, and
   retire the patches, carves, masonry quads and light-card hacks that only existed to hide
   the old shell. Keep v-numbered fallbacks of anything replaced.
E. Exterior consistency from distance: silhouette, material continuity, roof seated.
F. Only then re-run the final assessment (LHF-16 to LHF-18).

REPORT after each step: the failing output before, the passing output after, the commit.
Stop and ask me if a fix needs the shell rebuilt instead of patched.
```
