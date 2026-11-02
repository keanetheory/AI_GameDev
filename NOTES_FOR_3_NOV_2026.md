# Notes for Tuesday 3 November 2026

Written at the end of Monday 2 November. Branch **`Monday2ndEvening`** (pushed to origin, no PR yet). `main` has everything up to PR #23.

## The 12 FAL props are installed (T69, committed late on 2 Nov)

All 12 are in place of their greyboxes, with the free fixes (two oilskin coats in the basement, the pendant lamp as the store bulb, the linen and tub tap hidden). Lighthouse audit: 858,296 triangles, 112 materials, 1,278 surfaces, 2,957 nodes, all inside the limits (none raised). Screenshots: the agent's contact sheet `props_contact.jpg` (session scratchpad). Check in play:

- **The pressure gauge** was hidden behind the water cistern (whose model hangs low), so the gauge was raised to about 2.2 m with the STEAM plate above it: about 0.5 m over eye height. Alternative: shrink and raise the cistern instead.
- **The coal bin front** model is a whole crate of coal squashed into the thin front: reads as a planked front with coal on top; re-roll only if it looks wrong.
- **The wall grilles** are turned upright (bars horizontal) and shallower; a bit of the black recess shows at one edge.
- **The rope coil** is 3,000 triangles (its fringe fell apart lower).
- **The oilskin coat** model was re-decimated from 16.3k to 3.5k triangles (used six times now); the old one is `source/lhi_oilskin_coat_16k.glb` and in git history.
- **Next to the engine-feed valve** (basement) a large white folded shape shows in the screenshot: identify it (smoke card? part of the engine model?).
- **A pale slanted board on the L2 landing** next to the rope: it was there before; check.

## The day's plan (from the backlog)

1. **T50, morning:** the music pieces and when each one plays (`data/world/audio_spec.json`, `audio_mixer.gd`), and the placeholder sound review. The dialogue lines and timings are done.
2. **T53, evening:** the playtest QA agents and the itch.io web deployment agent. The agent briefs need the creator's approval (the GER gate) before they run. The web build is also the first real measure of frame rate, load time and stutter in a browser, which should set the lighthouse's triangle and material limits.
3. Open the PR for `Monday2ndEvening` when the props are in.

## Things to look at in play

- **Difficulty** on the title screen (Easy 3:00, Medium 2:30, Hard 2:00). The default is Easy; decide whether new players should start on Medium.
- **The routes** (`tools/route_viewer.gd`, keys 1-4): Ted up the middle of the stairs, the sailors round the plateau boulder and in an arc to the door, Arthur facing down the hall, Arthur running to the launch.
- **The pages and posters** in the hall, office, first floor and store.
- **The props** once installed.

## Known problems and follow-ups

- **Arthur's left ankle** stretches when his trailing leg reaches back. The cause is his rig, not the walk clip (Ted's walk on Arthur's model does the same; Ted's own model does not). Tonight's fix shortens his stride a little (`npc.gd` `ease_bones`) so it is far less visible. **The proper fix is to re-rig Arthur in Meshy** (or repaint the left ankle weights in Blender) and then remove `ease_bones`.
- **A boulder on the plateau has little or no collision** (x -11.5..-9.5, z 6.5..8.5, between the gate and the lighthouse): the sailors walked through it. Their route now goes round it, but the player may be able to walk through it too. Island agent follow-up.
- **The STEAM plate** sat behind the boiler drum; the install agent was asked to move it with the gauge. Check it.
- **`test_interior_budget`'s build-time check** fails while the Godot editor is open (both with and without tonight's changes). Re-run it with the editor closed; if it still fails, it is T61 (load time).
- **Godot's `--import`** rewrites about 70 `.import` files with line-ending-only changes, and the 9 audio `.import` files are still modified. Leave them uncommitted (or settle line endings in `.gitattributes` once).
- **The original page images** are in `LightingTheStorm/Assets/Textures/interior/incoming/` (ignored by Godot, untracked) and backed up to `C:\bkupConceptArt\Lighthouse_Pages_2026-11-02`.

## Decisions waiting on the creator

- **T62 credits:** confirm FAL/Hunyuan3D and ChatGPT image terms for commercial use; the list goes on the itch.io page.
- **T51:** where the characters look during their lines (a walk-through, now the lines are final).
- **T57:** what goes in the journal.
- **T18:** re-recording the voice lines (now most of the script) against the ElevenLabs credits.
- **The lighthouse limits** (triangles 900k, materials 120): leave them until the web build has been measured.

## Open backlog (score order)

T50 (8), T53 (8), T62 (7), T51 (6), T69 props (6, installed: check in play), T57 (5), T18 (4), T61 load time (4), T68 lighting follow-ups (4), T65 handoff loose ends (3). Goal progress 90% (17 of 21 requirements met).

## FAL

Paid in $40.00; spent $38.40 ($33.90 to 1 Nov, $4.50 tonight for 12 props); about $1.60 left. Ledger: `GERFramework/reports/lighthouse_finisher_fal_ledger.json`; audit: `Game Audit/FAL_SPEND.md`.
