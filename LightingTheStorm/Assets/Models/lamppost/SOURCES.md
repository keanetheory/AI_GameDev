# Lamppost model: source and licence

- **Model (current, 30 Oct 2026):** "Verdigris Lantern", generated with Meshy AI (file `Meshy_AI_Verdigris_Lantern_1030135804_texture.glb`). It replaced the first model, "Vintage Gas Street Lamp" (`Meshy_AI_Vintage_Gas_Street_La_1029174310_texture.glb`), which is kept in `source/` as `meshy_street_lamp_original.glb`.
- **Licence:** Creative Commons Attribution 4.0 International (CC BY 4.0). The creator confirmed it for the first model; the new one comes from the same Meshy account, so the same licence is assumed (confirm on the Meshy page).
- **Attribution required:** credit Meshy AI and the model titles ("Verdigris Lantern") in the game's credits.
- **Changes made:** decimated from 454,362 to 30,000 triangles (Blender, `tools/decimate_glb.py`), textures downscaled from 2048 to 1024, scaled to 3.4 m with the pivot at the base centre (`tools/import_scale_pivot.gd`). The unmodified originals are in `source/` (git-ignored) and backed up in `C:\bkupConceptArt\FAL_3D_Models\lamppost\`.
- **Lamp head:** the frosted glass is centred 2.96 m up the post; `data/world/lampposts.json` puts the light and the glowing head there.
