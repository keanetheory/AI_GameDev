Lighting the Storm — Engine Comparison

Status: input to Decisions to be made item 8 (engine), 25 September 2026. Compares Godot, Unity and Unreal for this project, then contrasts all three with Phaser. Licence terms change; check each vendor’s current terms before committing.

What this project needs from an engine

• First-person 3D with a stylised stormy sea that moves for atmosphere, and a boat steered past rocks, buoys, and debris. Waves that push the boat are a stretch goal, so a built-in ocean is useful but not essential.
• Night storm atmosphere: dynamic lights, rain, fog, and a sweeping beacon, all tuned for readability.
• Scripted sequences (crash through the window, gate, NPCs walking in) and a phase-based state machine.
• PC release on Steam, with controller support in the full game.
• A solo developer working with AI assistance, so how well AI tools can read and edit the project matters as much as raw engine power.

Godot 4

Pros
• Free and MIT-licensed: no royalties, fees, or revenue thresholds.
• Small, fast editor; quick to open, iterate, and export. Runs well on modest hardware.
• Scenes (.tscn) and resources (.tres) are plain text, so AI agents can read, diff, and edit them directly, not just the scripts. This is a real advantage for AI-assisted work.
• GDScript is simple and tightly integrated; C# is available if needed.
• Scene-based structure suits the compact locations and scripted interactions.
• Volumetric fog, SDFGI, and decent lighting are enough for a stylised storm.
• Steam integration is available through the community GodotSteam plugin.

Cons
• No built-in ocean or buoyancy. The core crossing only needs a visually moving sea shader plus a steered boat and colliders, which Godot handles well. If the wave stretch goal is built, you write the wave-height maths for the boat yourself, and Godot gives the least help with that.
• 3D rendering and tooling are less mature than Unity or Unreal; high-end atmosphere takes more manual work.
• Smaller asset library, and fewer ready-made water, weather, and first-person controller packages.
• AI models sometimes mix up Godot 3 and Godot 4 APIs, so generated code needs checking against the 4.x docs.
• Console ports need third-party porting services (not relevant for a PC-first release).

Unity (6.x)

Pros
• Mature 3D pipeline (URP/HDRP) with good lighting, post-processing, and particle tools.
• Large Asset Store: weather systems, first-person controllers, and established ocean and buoyancy packages (the last mainly useful if the wave stretch goal is built).
• C# has very large AI training coverage; AI assistants write Unity code fluently.
• Big community, tutorials, and answers for almost any problem.
• Steam integration through Steamworks.NET or Facepunch.Steamworks is well established.

Cons
• Licensing history (the 2023 runtime-fee episode, since cancelled) makes some developers wary. Unity Personal is free below a revenue threshold; check current terms.
• Heavier editor, longer import and compile times, larger builds.
• Scenes and prefabs are YAML with GUIDs; AI can read them, but safe editing is harder than with Godot’s text scenes. Most AI work stays in C# scripts.
• Good water assets are usually paid, and a render-pipeline choice (URP vs HDRP) must be made early.

Unreal Engine 5

Pros
• Best visual quality out of the box: Lumen lighting, volumetric clouds and fog, and a built-in Water plugin with buoyancy.
• Strongest fit for the storm atmosphere and the beacon lighting that pillars 1 (the light must return) and 2 (the storm sets the clock) depend on.
• Free to use; royalties only apply above a high lifetime revenue threshold per product (check current terms).
• First-person template and a mature cinematic and sequencing toolset.

Cons
• Blueprints are binary assets that AI cannot read or edit meaningfully. AI help is limited to C++, which has long compile times and is a harder language for a solo developer.
• Heavy editor and hardware demands; slow iteration on a modest PC.
• The built-in water is its main gameplay advantage here, but waves are now a stretch goal, and its realism-focused water may fight the readable, authored waves that pillar 4 (dread you can read) would need.
• Steep learning curve; the most engine complexity for the smallest game.
• Large build sizes for a 30-minute game.

Phaser, compared with the three 3D engines

Phaser is a 2D HTML5 game framework written in JavaScript/TypeScript. It is a very different tool from the other three.

Where Phaser is better
• Fastest possible iteration: edit code, refresh the browser. No editor, no import pipeline.
• JavaScript/TypeScript has the largest AI training coverage of any option; everything is code, so AI can build and change the whole game.
• Runs in any browser, which makes it trivial to share builds with playtesters (for example on itch.io).
• Free (MIT) and lightweight.

Where Phaser falls short for this game
• It is 2D. The brief is a first-person 3D adventure; Phaser would force a redesign to top-down or side-on, which breaks the “all viewpoints are first-person” rule and changes how the crash, gate, and ship outcome are presented.
• No 3D lighting, volumetric fog, or real-time beacon sweep. The beacon and storm atmosphere (pillars 1 and 2) would have to be rebuilt in 2D art and shaders, and pillar 3 (your hands, your eyes) could not be met at all.
• Adding 3D means bolting on Three.js or Babylon.js, at which point you are building your own engine.
• Steam release needs a desktop wrapper (Electron, NW.js, or Tauri), plus extra work for Steamworks and controller support.

When Phaser would make sense
• Only as a throwaway 2D steering sketch to test hazard layouts in a day or two, or if the game pivoted to a 2D web release.

Side-by-side

|Factor                         |Godot 4                   |Unity                          |Unreal 5                         |Phaser                          |
|-------------------------------|--------------------------|-------------------------------|---------------------------------|--------------------------------|
|First-person 3D                |Good                      |Very good                      |Excellent                        |Not supported (2D)              |
|Boat steering past hazards     |Straightforward           |Straightforward                |Straightforward                  |2D only                         |
|Wave hazards (stretch goal)    |Build it yourself         |Asset Store packages           |Built-in, realism-focused        |2D only                         |
|Storm atmosphere and lighting  |Adequate with effort      |Very good                      |Excellent                        |Poor                            |
|AI can edit scenes, not just code|Yes (text scenes)       |Partly (YAML)                  |No (binary Blueprints)           |Yes (all code)                  |
|AI fluency in the language     |Good (GDScript), with 3/4 API confusion|Excellent (C#)    |Good (C++), slower loop          |Excellent (JS/TS)               |
|Iteration speed                |Fast                      |Medium                         |Slow                             |Fastest                         |
|Cost and licence               |Free, MIT                 |Free below revenue threshold   |Free, royalty above high threshold|Free, MIT                      |
|Steam and controller           |Via GodotSteam plugin     |Mature                         |Built-in                         |Needs desktop wrapper           |
|Solo learning curve            |Low                       |Medium                         |High                             |Low                             |

Recommendation

1. Godot 4 is the best overall fit (as Technical Strategy proposes): fast iteration, no fees, and text scenes that AI agents can work on directly. With waves now a stretch goal, its main weakness (no built-in ocean) is off the critical path; build waves yourself only if the schedule allows.
2. Choose Unity instead if you already know C#. Its ocean packages are no longer a strong reason on their own, because the core crossing does not need them.
3. Avoid Unreal for this project: the visuals are the best, but Blueprints shut out AI help and the iteration cost is too high for a solo 6-week prototype.
4. Do not use Phaser for the game itself; it cannot deliver the first-person 3D brief. It is only worth considering for a one- or two-day 2D hazard-layout sketch.
