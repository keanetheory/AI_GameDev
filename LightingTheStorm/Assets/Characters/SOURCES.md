# Character models: source and licence

All three characters (31 Oct 2026) are FAL Hunyuan3D v3 meshes made from the creator's own concept art, rigged on the Meshy website
with its Mixamo-named skeleton, then given a jaw bone and a 2048 texture here. See `LightingTheStorm/HANDOFF_Characters_FAL.md`.

How each one was made:

1. Concept views (`ConceptArt/characters/newted`, `arthur`, `daniel`), front and back cropped to the same height and baseline on a
   flat grey (`prepared/`). Side views are left out (Ted's showed the coat closed; front and back are enough for Hunyuan).
2. `AIAgentCrew/main_asset.py <submission> --check-only`, then `AIAgentCrew/main_fal.py <submission> --go --textured --face-count 60000`
   (submissions in `AIAgentCrew/sample_submissions/characters/`, about $0.68 each). Output: `Assets/Models/character_texture/<name>_fal_v3.glb`.
3. Rigged and animated on the Meshy website; the download is `source/meshy_<name>_fal_all_animations.glb`.
4. `blender -b -P tools/add_jaw_bone.py -- <download> <out.glb> <jaw settings below> --test-pose`
5. Arthur and Daniel only: `blender -b -P tools/copy_clips.py -- <ted with jaw>.glb <out.glb> <out_idle.glb> Idle_3` (Ted's idle).
6. Copy to `Assets/Characters/<name>.glb`, then `python tools/downscale_glb_texture.py Assets/Characters/<name>.glb` (keeps the 4k
   copy as `source/<name>_4k_texture.glb`). Godot extracts the texture as `<name>_texture_20250901.png`.

- **Ted (`ted.glb`):** 60,080 triangles, 66 bones with fingers plus the jaw, 1.83 m. Clips: `Idle_3`, `Walking`, `Running`. No
  talking clip, so he idles while his jaw moves (add one in Meshy and set `talk_clip` in `npc.gd` to use it). Jaw:
  `--hinge_up 0.3 --hinge_front 0.2 --mouth 0.17 --chin -0.09 --fwd0 0.3 --fwd1 0.44` (the beard drops with it).
- **Arthur (`arthur.glb`):** 60,080 triangles, Mixamo body bones without fingers plus Meshy's extra `Bone_0xx` bones (rope and pouch),
  1.78 m. Clips: `Idle_3` (copied from Ted), `Idle_03` (his own: a stretch with his hands at his head, not used), `Walking`, `Running`,
  `Chair_Sit_Idle_M`. No talking clip. Jaw: `--hinge_up 0.2 --hinge_front 0.3 --mouth 0.04 --chin -0.27 --fwd0 0.36 --fwd1 0.5`.
- **Daniel (`daniel.glb`):** 60,080 triangles, body bones without fingers plus two extra (satchel), 1.66 m. Clips: `Idle_3` (copied
  from Ted), `Walking`, `Running`, `Talk_Passionately`, `Sit_Cross_Legged`. Jaw: `--hinge_up 0.15 --hinge_front 0.25 --mouth -0.01
  --chin -0.21 --fwd0 0.3 --fwd1 0.45` (beardless, so the movement is small).
- **Jaw settings** are fractions of the head length from the Head bone, measured from each face's profile (nose, mouth line, chin);
  the tool's defaults fit none of these heads. `jaw_lipsync.gd` drives the bone (opens up to 18 degrees, about 13 in the tests).
- **Licence:** the meshes come from FAL (Hunyuan3D v3) from our own concept art; confirm FAL's commercial terms before release.
  The rig and clips come from Meshy, CC BY 4.0 (creator, 2 Nov 2026): credit Meshy AI for the rigging and animation; the earlier Meshy community-model credits ("Ironclad Mariner", "The Dockside Outlaw",
  "The Red-Capped Wayfarer") no longer apply to the models in use.
- **Originals** (git-ignored): `source/meshy_*_fal_all_animations.glb` and `source/*_4k_texture.glb`, backed up to
  `C:\bkupConceptArt\FAL_3D_Models\Characters\`. The FAL test meshes are in `C:\bkupConceptArt\FAL_3D_Models\character_texture\`.

## Earlier models (30 Oct 2026, replaced)

Meshy community models on the same Mixamo skeleton: Ted "Ironclad Mariner" (`source/meshy_ironclad_mariner_all_animations.glb`),
Arthur "The Dockside Outlaw" (`source/meshy_dockside_outlaw_all_animations.glb`, 4k copy `source/arthur_dockside_4k_texture.glb`),
Daniel "The Red-Capped Wayfarer" (`source/meshy_red_capped_wayfarer_all_animations.glb`, 4k copy `source/daniel_wayfarer_4k_texture.glb`).
They are in git history (commit 6ce14b1 and before) and in the backup folder. The rigged Ted before those is `source/ted_old_rig.glb`.
