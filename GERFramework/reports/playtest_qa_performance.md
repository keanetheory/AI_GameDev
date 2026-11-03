# Playtest QA: frame rate and memory along the route (QA-03)

3 Nov 2026, Playtest QA agent. Exported Windows release build `build/windows/LightingTheStorm.exe` (exported 3 Nov 14:58; no script, scene or data file has changed since, so it was not re-exported), 1600x900 window, laptop i9-14900HX, 32 GB, NVIDIA RTX 4070 Laptop (device 0) and the Intel Raptor Lake UHD integrated GPU (`--gpu-index 1`, "RaptorLake-S Mobile Graphics Controller", Vulkan 1.4).

Method: `LightingTheStorm/tools/perf_route.gd` loaded by the exported exe from disk (`--script C:/.../tools/perf_route.gd`): `-- static` puts the player at eight fixed points and turns a full circle over 8 s at each (the first second after each move is reported apart); `-- static twice` does the loop twice (a spike on both laps is not a first-sight shader compile); with no argument and `-- fail` it runs the full-slice playthrough at 1x speed and reports one segment per story event. Frame times are real time per rendered frame. Memory from outside (PowerShell: PeakWorkingSet64 and the GPU Process Memory counters, every 0.7 s). Six runs plus two two-lap runs; the raw output is in the scratchpad of this session, the table is reproducible with the commands above.

One caveat: a 30 s headless probe ran at the start of the first Intel playthrough (CPU load on the same chip); the other Intel runs had nothing else running.

## Per point (median fps, slowest whole second, spikes over 50 ms with the worst frame)

| Point | NVIDIA median fps | NVIDIA worst 1 s | NVIDIA spikes > 50 ms (worst ms) | Intel median fps | Intel worst 1 s | Intel spikes > 50 ms (worst ms) | Intel under 30? |
|---|---|---|---|---|---|---|---|
| front door | 239 | 232 | 0 (6) | 32 | 1 | 21 (1075) | worst second only |
| hall | 232 | 207 | 0 (9) | 23 | 16 | 62 (84) | **yes** |
| basement | 234 | 207 | 0 (7) | 24 | 16 | 62 (65) | **yes** |
| tower stairs | 233 | 200 | 0 (7) | 25 | 16 | 57 (67) | **yes** |
| lamp room | 231 | 195 | 0 (7) | 19 | 14 | 78 (96) | **yes** |
| lighthouse dock | 263 | 56 | 10 (169) | 26 | 11 | 50 (168) | **yes** |
| island gate | 239 | 234 | 0 (5) | 30 | 19 | 42 (68) | worst second only |
| Saltgate quay | 240 | 240 | 0 (5) | 25 | 24 | 0 (47) | **yes** |
| route: coal and boiler (basement) | 240 | 195 | 1 (232) | 27 | 21 | 3 (295) | **yes** |
| route: sailors arrive, at the window | 240 | 240 | 0 (6) | 27 | 26 | 4 (75) | **yes** |
| route: gate open, sailors walk in | 240 | 240 | 0 (6) | 34 | 32 | 3 (60) | no |
| route: lamp room diagnosis | 240 | 240 | 0 (6) | 22 | 21 | 17 (91) | **yes** |
| route: hall briefing, Arthur to the launch | 239 | 240 | 0 (6) | 26 | 25 | 2 (76) | **yes** |
| outbound crossing | 240 | 240 | 0 (6) | 26 | 25 | 1 (77) | **yes** |
| return crossing (win run, early in the deadline) | 240 | 240 | 0 (6) | 29 | 22 | 29 (102) | **yes** |
| return crossing in the storm, late in the deadline (fail run) | 241 | 240 | 0 (6) | 28 | 22 | 15 (76) | **yes** |
| the ship strikes, the Failed screen (fail run) | 241 | 3 | 3 (3831) | 29 | 3 | 9 (5777) | **yes** |
| the win (lamp room, the ship sails on) | 240 | 236 | 0 (12) | 18 | 17 | 1144 (105) | **yes** |

| Run | Peak system memory (working set) | GPU dedicated memory peak | GPU shared memory peak | Godot video memory (max) |
|---|---|---|---|---|
| NVIDIA RTX 4070 Laptop, static | 0 MB | 1161 MB | 342 MB | 1001 MB |
| NVIDIA RTX 4070 Laptop, static2 | 914 MB | 1161 MB | 348 MB | 1001 MB |
| NVIDIA RTX 4070 Laptop, win | 0 MB | 1161 MB | 346 MB | 1060 MB |
| NVIDIA RTX 4070 Laptop, fail | 947 MB | 1162 MB | 346 MB | 1060 MB |
| Intel integrated, static | 0 MB | 21 MB | 1337 MB | 1101 MB |
| Intel integrated, static2 | 1815 MB | 21 MB | 1337 MB | 1101 MB |
| Intel integrated, win | 2118 MB | 21 MB | 1596 MB | 1168 MB |
| Intel integrated, fail | 2102 MB | 21 MB | 1596 MB | 1168 MB |

The memory rows marked 0 MB are runs where the working-set sampler had not yet been fixed; the static2, win (Intel) and fail rows are good. 'Spikes over 50 ms' on the Intel GPU counts nearly every interior frame (the median frame is 40 to 55 ms there), so read the median and the worst second instead.

## Findings

| # | Finding | Evidence | Severity | Owner | Backlog |
|---|---|---|---|---|---|
| P1 | **Integrated graphics under 30 fps almost everywhere**: hall 23, basement 24, stairs 25, lamp room 19 (14 in the worst second), the crossings 22 to 29, the win 18. Only the island outdoors in the island lighting reaches 30 to 34. requirements.md's minimum ("about 30 fps" on recent Intel integrated) does not hold for this GPU. | table above | 8 | Lighting agent and Level Layout agent (interior cost), creator (the published minimum) | T79 |
| P2 | **Stutter standing in the moored launch at the lighthouse dock**: 10 to 15 frames of 160 to 170 ms in 8 s on the NVIDIA GPU, on both laps (so not a shader compile), and on the Intel GPU too; the worst second drops to 52 fps on the RTX 4070. The player there is not on the floor (y 0.66, inside the launch's hull). A headless check (`tools/probe_dock_hitch.gd`) points at physics: worst physics step 12 ms in the launch against 1.3 ms in the hall, and 24 ms with 145 slow physics frames in 6 s for a body dropped into the island collision beside the berth. | static and static-twice runs; probe_dock_hitch | 5 | Player Movement agent (the body against the launch and the island colliders) | T80 |
| P3 | **Restart freezes without a word**: Enter on the Failed screen reloads the level in one frame of 3.8 s (NVIDIA) / 5.8 s (Intel); the screen just stops. | fail runs, segment after SHIP_FAIL | 3 | Gameplay / Systems (outcome screen: a 'Loading' line before the reload) | T81 |
| P4 | **First-sight hitches**: one 230 to 295 ms frame when the boiler is fed (the rowboat and the ship appear) on both GPUs, and on the Intel GPU a 1.1 s freeze the first time the view turns at the front door after loading (not on the second lap). Godot 4.3 compiles pipelines on first use. | win and static runs | 4 | Lighting agent (a warm-up pass over the materials behind the title screen) | T85 |

Memory: about 0.9 to 0.95 GB peak system memory and 1.16 GB of dedicated video memory on the NVIDIA GPU; 1.8 to 2.1 GB working set and 1.6 GB of shared GPU memory on the Intel GPU (shared memory counts against system RAM, so a 4 GB machine is tight). Godot's own count of video memory is 1.0 to 1.17 GB on both. These fit the published 2 GB video memory / 4 GB RAM minimum, the RAM only just.

Not measured: other machines, an Iris Xe, a desktop GPU without Vulkan, loading time from a cold disk, the title screen.
