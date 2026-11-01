# HANDOFF - Characters regenerated on FAL: Ted, Arthur and Daniel

## 1. Task and goal

Creator, 31 Oct 2026: the Meshy community models lacked detail and quality for riggable characters. Test whether a FAL generation
from our own concept art is better, then regenerate all three and bring them into the game with jaws. Result: FAL Hunyuan3D v3 gave
clearly sharper faces, buttons, belts and boots than the Meshy models (60k triangles, 4096 texture), so all three are replaced.

## 2. Files changed

New:
- `tools/copy_clips.py`: copies named clips between Meshy (Mixamo) rigs in Blender; used to give Arthur and Daniel Ted's `Idle_3`.
- `AIAgentCrew/main_fal_rig.py`: rigs a FAL mesh with FAL's `fal-ai/meshy/rigging` (tested on Ted, not used in the end: see 8).
- `AIAgentCrew/sample_submissions/characters/{ted,arthur,daniel}_hunyuan_v3.fal.json` and the concept views in
  `ConceptArt/characters/{newted,arthur,daniel}/` with their `prepared/` crops.
- `Assets/Characters/<name>_texture_20250901.png` (Godot's extracted 2048 textures).

Edited:
- `Assets/Characters/{ted,arthur,daniel}.glb` replaced. The old extracted textures (`*_texture_0*.png`, `*_normal.png`) are removed.
- `scripts/character/npc.gd` LOOKS: Ted has no `talk_clip`, Arthur's idle is `Idle_3` with no `talk_clip`, Daniel has `Idle_3` and
  `Talk_Passionately` (no frozen `pose_clip` any more).
- `tools/test_{ted,arthur,daniel}_anim.gd` updated to the new clips.
- `Assets/Characters/SOURCES.md`: how each model was made, the jaw settings, licence notes.
- `AIAgentCrew/main_fal.py` records `model_url` in the result JSON (needed by `main_fal_rig.py`).
- `.gitignore`: the new originals in `Assets/Characters/source/` and `Assets/Models/character_texture/*.glb`.

## 3. How to run and test

```bash
godot --headless --path . --script res://tools/test_ted_anim.gd
godot --headless --path . --script res://tools/test_arthur_anim.gd
godot --headless --path . --script res://tools/test_daniel_anim.gd
godot --path . --script res://tools/shot_ted.gd -- out.png full ARTHUR [sit]     # a still; "close" for the head
```

The full pipeline (concept views to game model) is listed step by step in `Assets/Characters/SOURCES.md`.

## 4. Observed behaviour

- All three tests pass with no failures. Each jaw opens about 13 degrees while the character's line plays and
  is shut when silent; no clip has a jaw track.
- In-game stills: all three face -Z, stand in `Idle_3` with their hands at their sides, and keep their heights (1.83, 1.78, 1.66 m).
  Seated on a 0.45 m box, Arthur's coat bunches between his knees and Daniel's hands sit a little oddly in the cross-legged clip.
- Jaw renders (Blender, 18 degrees): Ted's beard drops visibly, Arthur's goatee lengthens; Daniel's chin moves only a little (no
  beard and a painted mouth, as before).
- Each `test_*_anim.gd` run also prints two engine errors (`!is_inside_tree()` at spawn, `Parameter "m" is null` near the end).
  The tests still pass. It was not checked whether they appeared before this change.

## 5. Not verified

- Not seen in the running level: the opening with Ted at the door, the sailors' walk-in, Arthur and Daniel seated in the rowboat and
  the launch (plank heights `bench_m` / `sit_hold_frac` were tuned on the old models), or the faces under the game's lighting.
- Ted's `Idle_3` on Arthur and Daniel was checked by hand heights and stills, not watched in motion.
- The coat and the hanging gear (Arthur's rope coil, Daniel's satchel) are skinned to the legs by Meshy, so they stretch when walking.
  Watch a walk before calling it done.

## 6. Licences and provenance

Meshes: FAL Hunyuan3D v3 (`fal-ai/hunyuan3d-v3/image-to-3d`) from the creator's own ChatGPT concept images. Rig and clips: the
Meshy website. Confirm both services' commercial terms before release. The old Meshy community credits no longer apply. FAL spend
for this work about $3.70 (Ted $0.68 + $0.32 FAL rig test, Arthur and Daniel twice at $0.68 each).

## 7. Interface or contract changes proposed

None. `npc.gd` reads the same LOOKS keys; only clip names changed.

## 8. Open creator decisions

- **Unpushed history:** the three earlier commits on this branch (71bed7c, 2579259, 8dc00ea, made "as found" by another session)
  add about 170 MB of FAL test GLBs and a Meshy download. This commit stops tracking them, but they are still in those commits.
  Before pushing, decide whether to rewrite those three commits without the GLBs (they are backed up in C:\bkupConceptArt).
- **Talking clips:** Ted and Arthur have none, so they idle while they speak. Add `Stand_Talking_Angry` (Ted) and
  `Talk_with_Right_Hand_Open` (Arthur) in Meshy and re-download, or copy one across with `tools/copy_clips.py`.
- **Lore:** the new concepts differ from `Docs/Lore Build/characters`. Arthur is middle-aged with a cap, goatee, rope and pouch;
  the lore has him old and slim with no equipment. Daniel is slight and young with brown hair; the lore has him strong and heavy
  with black hair. Update `chr_arthur.md` / `chr_daniel.md` if the new look is intended.
- **Arthur's eyes** came out pale, almost white; a texture touch-up if it shows at game distance.
- **FAL rigging vs Meshy website:** FAL's `fal-ai/meshy/rigging` gives a 24-bone skeleton with no fingers, no jaw and different
  names, so it cannot share the clips or `add_jaw_bone.py`. Rig on the Meshy website (as done here) for game characters.
