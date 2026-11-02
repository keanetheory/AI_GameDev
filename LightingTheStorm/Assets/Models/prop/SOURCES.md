# Prop models: source and licence

## Meshy (CC BY 4.0: attribution required)

- **`lhi_arc_lamp_open.glb`**: "Open Arc Lamp", generated with Meshy AI on 30 Oct 2026 from renders of the closed lamp (`ConceptArt/arc_lamp_open_reference/`, T39).
- **Licence:** Creative Commons Attribution 4.0 International (CC BY 4.0). The creator confirmed on 2 Nov 2026 that the Meshy models are CC BY 4.0.
- **Credit in the game's credits:** "Open Arc Lamp" by Meshy AI, CC BY 4.0.
- **Original:** `source/lhi_arc_lamp_open_original.glb` (git-ignored), backed up in `C:\bkupConceptArt\FAL_3D_Models\prop\`.

## FAL (Hunyuan3D v3), generated from our own prompts and concept art

Every other `lhi_*.glb` here, the two burners (`burner_broken.glb`, `burner_replacement.glb`) and the Saltgate hut (`slt_equipment_hut.glb` and its collision copy `slt_equipment_hut_col.glb`).
- **Source:** FAL's Hunyuan3D v3 text-to-3D and image-to-3D, run on the creator's FAL account (prompts in `AIAgentCrew/sample_submissions/`, costs in `GERFramework/reports/lighthouse_finisher_fal_ledger.json` and `Game Audit/FAL_SPEND.md`).
- **Licence:** generated output, not a third-party model, so no attribution is owed to an author. FAL's and Tencent Hunyuan3D's terms for commercial use of the output still need confirming before release (see `Game Audit/`).
- **Changes made:** decimated in Blender (`tools/decimate_props.gd`), textures downscaled to 2048 or less.
- **Originals:** `source/*_4k_texture.glb` and `source/*_full2k.glb` (git-ignored), backed up in `C:\bkupConceptArt\FAL_3D_Models\prop\` (2 Nov 2026).
