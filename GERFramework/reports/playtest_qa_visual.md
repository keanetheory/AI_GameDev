# Playtest QA: visual sweep of fixed views (QA-06)

3 Nov 2026, Playtest QA agent. 18 new views (`qa_*`) added to `LightingTheStorm/tools/visual_views.json` (backup of the old list: `GERFramework/reports/backups/visual_views_v1_2026-11-03.json`), each with an `env` field for what the view needs: the interior lights (SHOT_INTERIOR), Ted at the door (SHOT_INTRO), Arthur aboard (SHOT_BOARD), the rowboat (SHOT_ROWBOAT), the sailors on their route (SHOT_NPC), the hazards and the ship (SHOT_CROSSING, SHOT_SHIP), and a new SHOT_CAST that stands Ted, Arthur or Daniel at a spot facing the camera (`tools/shot_qa.gd`, which extends shot.gd). All 39 views were rendered with `bash LightingTheStorm/tools/visual_sweep_qa.sh` (editor build, NVIDIA GPU) and scored by `visual_check.py --no-render`.

- Scores: `GERFramework/reports/visual_check.md` (39 views: 29 pass, 10 fail).
- Contact sheet for the creator: `GERFramework/reports/playtest_qa_contact_sheet.png`; the pictures: `GERFramework/shots/<view>.png`.

## What the views show

| View | Score | By eye |
|---|---|---|
| qa_hall, qa_hall_arthur, qa_office, qa_store, qa_house_L1, qa_basement_back | pass (0 to 7% dark) | Lit, furnished, nothing missing; Arthur at his hall spot is well lit and clear of the walls |
| qa_lamp_ted | pass (10%) | Ted at the lamp, readable, a little dark against the glazing |
| qa_gate_sailors | pass (2%) | The gate and the sailors' approach; Arthur small but visible behind the leaf |
| qa_cross_return | pass (21%) | The storm, the hazards and the ship's lights read |
| qa_door_ted | FAIL (70%, 13 black cells) | **Ted is a near-black silhouette just inside the open door** at the greeting; the front of the house is almost black at night apart from the fanlight |
| qa_dock, qa_dock_rowboat, qa_launch_arthur | FAIL (59 to 72%) | Night at the dock: the launch and the rowboat read, but **Arthur aboard the launch cannot be made out**, and the sailors in the rowboat are dark shapes |
| qa_gate | FAIL (75%) | The gate from the dock side is a dark mass with the bars against the sky |
| qa_saltgate_quay, qa_cross_out | FAIL (62%, 33%) | Dark night scenes; nothing missing, the quay timbers and the far coast read |
| lhi_lamp_out (old view) | FAIL (94%, all 48 cells black) | Black: rendered with no player in the lamp room, so the interior lights stay off. A person standing there gets the lights; a tooling fault, not a game fault (it needs SHOT_INTERIOR=1) |
| slt_landing, slt_link_ramp (old views) | FAIL (35%, 33%) | Just over the 25% limit; by eye they look right (the hut's shadowed wall). The limit is coarse for night views |
| qa_basement_daniel, qa_stairs_ted | pass, but **not a valid check** | The framing missed: Daniel and Ted are out of shot (the camera faces a wall). To retake with a wider angle |

No missing meshes were seen in any view, and no character is clipping into a wall in the views where they are in shot (hall, lamp room, gate). The known fault (characters going dark in rooms whose lights the 6-light budget has switched off) did not show in these views: every interior view had its room's lights on because the camera stood in it.

## Findings

| Finding | Severity | Owner | Backlog |
|---|---|---|---|
| Characters read as near-black at night outdoors and in the doorway: Ted at the greeting (the first face the player sees), Arthur aboard the launch, the sailors in the rowboat | 5 | Lighting agent | T82 |
| Tooling: visual_check.py ignores a view's `env` (so a plain run renders the qa_ views without their lights and characters: use visual_sweep_qa.sh); shot.gd's HUD hiding runs before the HUD exists, so the goal tracker, the controls list and the "Lighting:" label are in every picture; lhi_lamp_out needs SHOT_INTERIOR; three cast views to reframe; the 25% dark limit fails dark-but-correct night views | 3 | QA agent (visual_check.py, shot.gd are theirs); Playtest QA reframes its views | T84 |
