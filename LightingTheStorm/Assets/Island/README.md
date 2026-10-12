# Island and Lighthouse: static asset

The exterior of the Bracken Isle lighthouse for *Lighting the Storm*: a game-ready island with the lighthouse, keeper's cottage, a pier, a sea surface and a walkable route from the pier to the lighthouse. It is Artifact #3 in the [root README](../../../README.md).

## Files

| File | What it is |
|---|---|
| `environment/8-island.glb` | The island, lighthouse, cottage and pier. 150,000 triangles, 4096px textures, 22 MB. Boats removed; openings cut for the gate, the tunnel shaft and the exit stairs. |
| `environment/8-island-collider.glb` | Low-poly collision mesh (30,000 triangles), cut the same way, with extra detail kept along the walking route. |
| `environment/1-sea.glb` | Flat sea grid, 640 m across, 256 x 256 cells, ready to animate. No collider. |
| `environment/1-gangway.glb` | Placeholder plank gangway from the pier end to the gate. |
| `environment/1-gate.glb` | Placeholder double gate and stone frame. The "lockable" story gate. |
| `environment/4-tunnel.glb` | Placeholder tunnel: corridor, spiral stair shaft and exit stairs up to the original stone steps. |
| `environment/1-barriers.glb` | Invisible collision boxes that stop the player climbing the rock, so the gate is the only way up. |
| `scene.json` | How the viewer places all of the above (scale 45, sea level, gate non-solid for testing). |
| `images/lighthouse_front.png` | Front view of the source model. |
| `viewer_patch/image-blaster-viewer.patch` | The changes made to the Image Blaster viewer (`neilsonnn/image-blaster`) to show this scene and give it collision. |

World coordinates: metres, Y up. The island file is authored at about 1.9 units across and is scaled by 45 (so the tower is about 27 m tall) and placed at `[2.25, 22.275, -22.6]`. The other extras are already in world coordinates.

## Tools (`../../tools/island/`)

Blender 5.2 (`--background`) and Bun scripts. Some paths inside them are specific to the machine they were run on.

- `decimate_island.py`: removes the boats, cuts the openings, decimates to 150k (visual) and 30k (collider) while protecting the walking route, shrinks textures to 4096px.
- `make_gate_gangway.py`, `make_tunnel.py`, `make_sea.py`, `make_barriers.py`: build the extra models.
- `find_escapes.mjs`: finds where the pier area leaks onto the rock above it and writes the barrier positions.
- `test_walk_route.mjs`: drives a player-sized capsule through the real physics engine (Rapier) from the spawn to the lighthouse, with the gate open or solid.
- `test_only_way_in.mjs`: searches for any route to the summit that avoids the tunnel.
- `headless_viewer_capture.mjs`: opens the viewer in headless Chrome, takes screenshots and collects console output.

## Using it

1. Apply the viewer patch to a checkout of Image Blaster: `git apply image-blaster-viewer.patch` (run from the repo root).
2. Copy `environment/` and `scene.json` to `worlds/<name>/` in that checkout.
3. Run the viewer (`bun install`, then `bun run dev`), open the world, and click **Fly** in the top-left panel to switch to **FPS** (walking with collision).

In `scene.json`, set `"solid": true` on `lighthouse-gate` to lock the gate. Remove the whole `environmentModel` block to go back to the original splat.

## Limits

- The gangway, gate and tunnel are untextured placeholders. The tunnel interior is unlit and will be very dark in the viewer.
- The route was verified in a physics simulation and the viewer was loaded and inspected headlessly. It has not been walked by hand in the live viewer.
- A few tiny floating splinters remain where the boats were.
- The source model is a single fused mesh from Meshy, so the lighthouse, cottage and pier cannot be moved separately.
