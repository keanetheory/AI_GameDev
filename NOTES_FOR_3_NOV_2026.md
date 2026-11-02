# Notes for Tuesday 3 November 2026

Written at the end of Monday 2 November. Branch **`Monday2ndEvening`** (pushed to origin, no PR yet). `main` has everything up to PR #23.

## Still running when these notes were written

- **The 12 FAL props are being installed by an agent** (T69): backups, texture downscale, Blender decimation, `hero_props.gd` entries, the STEAM plate moved next to the gauge, and the free fixes (reuse the oilskin coat and pendant lamp, hide the linen and the tub tap). Its changes are **not committed**. First job tomorrow: read its report and screenshots, check each prop in place, run `audit_lighthouse.gd -- check` and the tests, then commit.
- If a prop came out unusable it was left as a greybox. Re-rolls are $0.375 each and **about $1.60 is left on FAL** (confirm on the dashboard). The creator decides re-rolls.

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

T50 (8), T53 (8), T62 (7), T51 (6), T69 props install (6, in progress), T57 (5), T18 (4), T61 load time (4), T68 lighting follow-ups (4), T65 handoff loose ends (3). Goal progress 90% (17 of 21 requirements met).

## FAL

Paid in $40.00; spent $38.40 ($33.90 to 1 Nov, $4.50 tonight for 12 props); about $1.60 left. Ledger: `GERFramework/reports/lighthouse_finisher_fal_ledger.json`; audit: `Game Audit/FAL_SPEND.md`.
