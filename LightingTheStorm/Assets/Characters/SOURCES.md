# Character models: source and licence

- **Ted (`ted.glb`, 30 Oct 2026):** Meshy "Ironclad Mariner" (file `Meshy_AI_Ironclad_Mariner_All_Animations.glb`), rigged with Meshy's Mixamo-named skeleton (66 bones, fingers, no jaw bone) and textured at 2048. 51,111 triangles. Clips: `Idle_3`, `Walking`, `Running`, `Stand_Talking_Angry`, `Talk_Passionately`. The model faces +Z, so `npc.gd` turns it 180 degrees (`model_yaw_deg`).
- **Licence:** the same Meshy terms as the lamppost models (CC BY 4.0 assumed, confirm on the Meshy page): credit Meshy AI and the title "Ironclad Mariner" in the game's credits.
- **Originals:** `source/meshy_ironclad_mariner_all_animations.glb` (git-ignored) and `C:\bkupConceptArt\FAL_3D_Models\Characters\`. The earlier rigged Ted (with a jaw bone, `jaw_lipsync.gd`) is `source/ted_old_rig.glb`.
- **Jaw:** the new rig has no `mixamorig:Jaw` bone, so `jaw_lipsync.gd` cannot drive it. It is not used by the game yet; add a jaw bone in Blender if lip-sync is wanted.
