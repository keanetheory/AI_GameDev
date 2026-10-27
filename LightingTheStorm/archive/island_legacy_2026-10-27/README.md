# Legacy island (archived 2026-10-27)

Island Creator ISL-11; the creator chose "archive" on 2026-10-26 and "Archive the old models" on 2026-10-27. Nothing in the game loads these:
Level.tscn uses Assets/Models/island/island_craggy.glb.

- environment/: the first web-viewer island, 8-island.glb (23.5 MB, 562 hole loops), its collider and textures, and the old gate 1-gate.glb
  (replaced by Assets/Models/island/island_gate.glb).
- models/: island_plateau.glb (29.6 MB, FAL), replaced by island_craggy (see island_craggy.fal_result.json notes).
- scenes/: Level_old_island.tscn.bak, the level before the craggy island.

Still pointing at the old paths: the legacy web viewer (Assets/Island/scene.json) and tools/island/find_escapes.mjs, test_only_way_in.mjs,
test_walk_route.mjs. They were for the old island and are not part of the Godot game. The Godot .import files were dropped (archive/ has a .gdignore).
