# things to work on next

Known rough edges in the level, with where they come from and what would fix them.

## 1. Jagged teeth along the base of the cliff walkway's rock wall

**What you see:** a band of jagged grey slivers sticks up along the bottom of the rock wall on the cliff walkway, where the wall meets the floor.

**Why:** `scripts/world/mainland.gd` cuts the walkway out of the cliff meshes by removing whole triangles whose centre falls inside the cut volume, and the wall is a copy of the removed cliff faces set back from the edge. The cliff's triangles are large and uneven, so triangles that straddle the floor line are either kept (poking up into the walkway) or copied (leaving a ragged bottom edge on the wall).

**Ideas:**
- Clip the triangles properly at the floor plane instead of keeping or dropping whole triangles.
- Or hide the junction with a rubble or stone skirt strip along the foot of the wall.
- Or push the wall copy's bottom vertices down below the floor so the edge is buried.

## 2. The walkway is very dark

**What you see:** at the game's own lighting the ledge, its floor and the rock wall read almost black. (My review screenshots used an extra fill light, so they looked brighter than the game really is.)

**Why:** the level's sun, ambient light and fog are dim and cold by design. The walkway floor and walls are vertex-coloured and fairly dark to start with, and the cut sits in the shadow of the cliff above it.

**Ideas:**
- Lighten the floor colour and the vertex tones in `_build_gallery()` in `mainland.gd`.
- Add a few warm lanterns or lamp posts along the ledge. The Lighting agent's spec in `AIAgentCrew/world_output/lighting_spec.json` should say what light sources fit the setting.
- Check it against the final lighting pass before changing the colours much.

## 3. Level load time

**What you see:** the level takes noticeably longer to load than before the mainland work. In headless runs it went from about 7 s to about 10 s, and it is probably worse on a slower machine. It happens every time the scene loads, including in the editor.

**Why:** `mainland.gd` does a lot of work in `_ready()`:
- It measures the real cliff-top heights by walking every face of the cliff meshes (`_measure_tops()`).
- It carves the walkway out of three large cliff meshes and builds a copy of the removed rock (`_carve_mesh()`), roughly 22,000 triangles.
- It builds concave (exact) collision for the carved cliffs, the rock wall copy, the walkway floor and the plateau terrain.
- It generates the terrain, roads and about 2,600 trees from code.
- The island also carves its old dock out of the mesh on every load (`collider_builder.gd`).

**Ideas:**
- Bake the result: save the carved cliff meshes and the cliff-top height table into the project, so nothing is measured or cut at load time.
- Keep the code builders for the editor only, and load the baked meshes in the game.
- Build the collision offline too (for example as `.res` shapes).
- Cut the triangle counts of the cliff pieces and the generated models before baking, which also reduces collision cost.
