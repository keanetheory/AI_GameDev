# Lighting the Storm: release requirements (itch.io)

What the game needs to run, and what we need before it goes on itch.io. Written 3 Nov 2026 from a Windows export of branch
`dialogueandmusic` (commit 21cdacc plus the icon). Re-measure before each release: the numbers below were taken at the opening
area only.

## Release format

**A Windows download, not a web build** (creator, 3 Nov 2026: the web build loses the game's look). On itch.io:
Kind of project **Downloadable**, upload the zip, tick **Windows** on the file.

The web build is parked. For the record of why (in case it is picked up again): the browser uses Godot's Compatibility renderer,
so there is no ink outline and the interior and sky are darker; `index.pck` is 378 MB against itch.io's 200 MB per-file HTML5
limit (500 MB total, 1,000 files); and in Chrome the level never appeared on this laptop's integrated GPU (the WebGL context was
lost and rebuilt three times as the level loaded). The likely cause is texture memory: 80 of 99 textures are imported lossless,
about 810 MB of GPU memory uncompressed, about 320 MB if GPU-compressed. The ink outline shader and the per-instance glow-card
shader also fail to compile on that renderer. Export preset "Web" is kept in `LightingTheStorm/export_presets.cfg` (untracked).

## System requirements (for the itch.io page)

**Minimum** (playable, about 30 fps)
- Windows 10 or 11, 64-bit
- A graphics card with Vulkan support; about the floor is a recent Intel integrated GPU (Iris Xe, or 12th-gen UHD and newer)
- 2 GB video memory (dedicated or shared)
- 4 GB RAM
- 900 MB free disk space to unpack (450 MB once installed)

**Recommended** (60 fps)
- GeForce GTX 1060 / GTX 1650, Radeon RX 580 or better, 4 GB video memory
- 8 GB RAM

Measured on one laptop (i9-14900HX, 32 GB RAM, 1600x900 window, the exported release build, 3 Nov 2026):

| | NVIDIA RTX 4070 Laptop | Intel integrated (same laptop, `--gpu-index 1`) |
|---|---|---|
| Renderer | Vulkan, Forward+ | Vulkan, Forward+ |
| Frame rate, opening view | 240 (the cap) | 34 to 36 |
| Video memory in use | about 0.65 to 0.9 GB (includes the desktop's) | shared |
| Peak system memory | 910 MB | |

Not yet measured: the lighthouse interior (the heaviest part, about 858k triangles), the storm crossing, the Saltgate, or any
other machine. The "recommended" cards are an estimate scaled from the two runs above. GPUs without Vulkan fall back to
Godot's OpenGL renderer (the web look) - untested on desktop. The Playtest QA agent (T53) is to measure the whole route.

## Building the download

From `LightingTheStorm/`, with the Godot 4.3 editor's console exe (export templates 4.3.stable are installed in
`%APPDATA%\Godot\export_templates\4.3.stable`):

```bash
godot --headless --path . --export-release "Windows Desktop" ../build/windows/LightingTheStorm.exe
python -I tools/set_exe_icon.py ../build/windows/LightingTheStorm.exe Assets/UI/app_icon.ico
```

Then zip `build/windows/` as `LightingTheStorm/LightingTheStorm.exe` and `LightingTheStorm/LightingTheStorm.pck` into
`build/LightingTheStorm_windows.zip`. The `.exe` and `.pck` must stay side by side.

- The export prints `Could not create child process: rcedit`: Godot cannot stamp the icon and version into the exe without
  rcedit. Harmless; `set_exe_icon.py` puts the icon on instead. The version and product name are not set.
- `export_presets.cfg` and `build/` are not in git; the preset is "Windows Desktop", all resources plus `*.json`, `tools/` and
  the incoming page images excluded, the pck beside the exe (not embedded).
- The game icon is `Assets/UI/app_icon.png` / `.ico`, cropped from `ConceptArt/lighthouse/Gothic lighthouse side elevation-4.png`
  (project.godot `config/icon` and `config/windows_native_icon`).

Last build: exe 84 MB, pck 379 MB, zip 379 MB (assets are already compressed, so zipping saves almost nothing).

## Size limits

itch.io's help pages do not state the download limit. As far as we know it is 1 GB per file through the website, larger with
itch.io's `butler` upload tool or on request to itch.io support. Check before the first upload. The current zip (379 MB) fits.

## Before uploading

- [ ] Every headless test passes (`LightingTheStorm/tools/test_*.gd`, including `test_slice_playthrough.gd` and its `-- fail` run)
- [ ] A fresh export, the icon applied, the zip unpacked and played from the unpacked folder on both GPUs
- [ ] Credits and licences complete (T62), on the itch.io page and in the game if any licence requires it:
  - Music: **"Music by KeaneTheory"** (`LightingTheStorm/Assets/Audio/music/SOURCES.md`)
  - Meshy models: **CC BY 4.0**, credit Meshy AI and each model's title
  - FAL / Hunyuan3D models: commercial terms **still to confirm** (the creator's account terms)
  - ElevenLabs voices: commercial use depends on the account's plan - **to confirm**
  - ChatGPT-generated images (the lighthouse pages and posters): terms **to confirm**
  - Godot Engine: MIT licence; its notice must ship with the game
  - Fonts and any other third-party files: list them
- [ ] The itch.io page: description, controls, the system requirements above, screenshots, a cover image
- [ ] The commit that was built is tagged in git
- [ ] Windows SmartScreen will warn about an unrecognised app (the exe is not code-signed): say so on the page ("More info,
      then Run anyway")
