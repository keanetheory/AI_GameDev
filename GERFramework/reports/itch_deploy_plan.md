# itch.io Deployment Agent: prioritised plan

- Assessor: **itch.io Deployment Assessment Agent** (knowledge up to date)
- Phase: **awaiting_approval** | plan review loops used: 1 of 3
- Blocking findings left: **0**

**Mission:** Turn the slice into a Windows download on itch.io that installs and runs first time, credits every third-party asset properly, and can be rebuilt the same way for every release; prepare everything up to the upload, and upload only when the creator says so, from their own account. The web build stays parked (creator, 3 Nov 2026).

## Objectives (10 = absolute must)

| ID | Score | Objective | Needs you | Baseline today |
|---|---|---|---|---|
| DEP-01 | **10** | A one-command Windows build: export, icon, smoke test and a versioned zip |  | failing |
| DEP-02 | **10** | Credits and licences complete for every third-party asset (T62) | YES | decision pending |
| DEP-03 | **9** | The pre-upload gate: tests green, both GPUs smoke-tested, sizes within limits, the built commit tagged |  | failing |
| DEP-04 | **8** | The itch.io page kit: description, controls, requirements, screenshots and a cover image |  | failing |
| DEP-05 | **8** | Upload with itch.io's butler tool, only on the creator's go-ahead and from their account | YES | decision pending |
| DEP-06 | **5** | The game's name and version in the exe's file details | YES | decision pending |
| DEP-07 | **4** | Propose graphics options for lower-end PCs (resolution scale, shadows, a low preset) |  | needs_human |
| DEP-08 | **2** | Keep the parked web build's notes current, and do nothing with it |  | passing |

## Detail

### DEP-01 [10/10] A one-command Windows build: export, icon, smoke test and a versioned zip
tools/build_windows.py: export with the 'Windows Desktop' preset, put the icon on with tools/set_exe_icon.py, start the exported exe and capture frames of the level (as the 3 Nov smoke test did), check the exe and pck sizes, and zip build/windows into build/LightingTheStorm_windows_<version>.zip with the game in a LightingTheStorm folder. It stops on any failure.

- Why this score: Every release must be rebuilt the same way, and today it is four manual steps in requirements.md. Not 9 because a wrong or half-built zip is the most likely release fault.
- Done when: one command produces a zip that unpacks and runs; it stops with a clear message if the export, the icon or the smoke test fails
- Owner: itch.io Deployment Agent | works with: Playtest QA Agent
- Depends on: nothing
- Baseline evidence:
  - LightingTheStorm/tools/build_windows.py is missing

### DEP-02 [10/10] Credits and licences complete for every third-party asset (T62)
Build Docs/Deploy/CREDITS.md from the asset provenance: each Meshy model (CC BY 4.0: credit Meshy AI and the model's title), the FAL / Hunyuan3D models, the ElevenLabs voices, the ChatGPT-generated pages and posters, the music (KeaneTheory), Godot Engine (its MIT notice must ship with the game), the fonts and any other files. Say for each whether its licence requires a credit in the game as well as on the page, and add an in-game credits screen only if one does.

- Why this score: CC BY requires attribution, and unknown terms on the AI-generated assets are the main release risk. Not 9 because the game cannot be published honestly without it.
- Done when: every asset in the build has a source and a licence line; the creator has confirmed the terms of their FAL, ElevenLabs and OpenAI accounts
- Owner: itch.io Deployment Agent | works with: Asset agent, Sound agent, Creator
- Depends on: nothing
- Baseline evidence:
  - Docs/Deploy/CREDITS.md is missing
  - Docs/Deploy/CREDITS.md is missing
- **Decision for you:** Confirm the commercial terms of your FAL (Hunyuan3D), ElevenLabs and OpenAI (ChatGPT images) accounts, and whether the game is free or paid on itch.io (some plans differ for commercial use). Recommendation: check each account's current terms page before the first upload and record the plan in CREDITS.md.

### DEP-03 [9/10] The pre-upload gate: tests green, both GPUs smoke-tested, sizes within limits, the built commit tagged
A checklist the agent runs and records: the Playtest QA suite passes; the fresh zip is unpacked and played on the NVIDIA and the Intel integrated GPU; the zip and its files are within itch.io's download limit (confirm the current limit); the version number is bumped; the commit built is tagged in git (the creator pushes).

- Why this score: Stops a broken or untraceable build going out. Not 10 because it depends on DEP-01 and the QA suite, which carry the 10s.
- Done when: a dated gate record with each item ticked or failed; no upload is prepared on a failed gate
- Owner: itch.io Deployment Agent | works with: Playtest QA Agent
- Depends on: DEP-01
- Baseline evidence:
  - GERFramework/reports/itch_release_gate.md is missing

### DEP-04 [8/10] The itch.io page kit: description, controls, requirements, screenshots and a cover image
Docs/Deploy/ITCH_PAGE.md: the short and the long description (in the game's voice, checked by the Style Guide agents), the controls, the system requirements from requirements.md, the SmartScreen note, content notes and tags; five screenshots and a 630x500 cover from in-game views (shoot.sh), all in Docs/Deploy/page/.

- Why this score: The page is the first thing a player sees. Not 9 because the game can go up with a plain page and be improved later.
- Done when: page text the creator has approved; five screenshots and a cover image
- Owner: itch.io Deployment Agent | works with: Creator
- Depends on: DEP-02
- Baseline evidence:
  - Docs/Deploy/ITCH_PAGE.md is missing

### DEP-05 [8/10] Upload with itch.io's butler tool, only on the creator's go-ahead and from their account
Prepare the butler command (channel 'windows', the version from DEP-01) and the steps for the creator to log in to butler themselves. The agent never logs in, never holds the creator's credentials, and never runs the push without the creator's explicit go-ahead in chat.

- Why this score: Publishing is hard to undo and is the creator's account. Not 9 because the creator can also upload the zip by hand on the itch.io site.
- Done when: the command and the steps written down; the push run only after the creator's go-ahead, or done by the creator
- Owner: itch.io Deployment Agent | works with: Creator
- Depends on: DEP-03
- Baseline evidence:
  - the creator confirms the upload was done (by butler or on the itch.io site) and the page is live
- **Decision for you:** Upload with butler (repeatable and keeps versions, but you log in to it once) or by hand on the itch.io website? Free or paid, and public, restricted (testers only) or a draft first? Recommendation: butler, and a restricted page first so friends can test before it goes public.

### DEP-06 [5/10] The game's name and version in the exe's file details
Either install rcedit (Electron's small tool on GitHub) and point Godot at it, which also stamps the icon, or extend tools/set_exe_icon.py to write the version resource.

- Why this score: Windows shows the exe as a generic Godot program; it is cosmetic. Not 6 because nothing breaks without it.
- Done when: the exe's Properties show Lighting the Storm and the version
- Owner: itch.io Deployment Agent | works with: Creator
- Depends on: DEP-01
- Baseline evidence:
  - the exe's Properties > Details show the product name and the version
- **Decision for you:** Download rcedit (about 1 MB, from Electron's GitHub releases) or keep everything in the project's own script? Recommendation: rcedit, the tool Godot expects.

### DEP-07 [4/10] Propose graphics options for lower-end PCs (resolution scale, shadows, a low preset)
From QA-03's measurements, propose the options and their expected effect; the owner agents build them if the creator approves.

- Why this score: Integrated graphics ran the opening at about 35 fps; a low preset could lift weak PCs to 60. Not 5 because it is game work for the Lighting and Gameplay agents; this agent only proposes it, with the QA numbers.
- Done when: a proposal with measured numbers, handed to the owner agents
- Owner: itch.io Deployment Agent | works with: Lighting agent, Gameplay / Systems agent
- Depends on: DEP-03
- Baseline evidence:
  - the proposal is in the backlog with its owner

### DEP-08 [2/10] Keep the parked web build's notes current, and do nothing with it
requirements.md says why the web build was parked (the renderer, the 378 MB pck against the 200 MB limit, the lost WebGL context on integrated graphics, the two shaders). Update it only if the facts change; no web export work without the creator.

- Why this score: Parked by the creator on 3 Nov 2026 because the game's look suffers in the browser. Not 3 because it should not take time from the download.
- Done when: the notes in requirements.md are current
- Owner: itch.io Deployment Agent | works with: Creator
- Depends on: nothing
- Baseline evidence:
  - requirements.md: /web build is parked/ matched 1 (need >= 1)

## Questions for you

- **DEP-02**: Confirm the commercial terms of your FAL (Hunyuan3D), ElevenLabs and OpenAI (ChatGPT images) accounts, and whether the game is free or paid on itch.io (some plans differ for commercial use). Recommendation: check each account's current terms page before the first upload and record the plan in CREDITS.md.
- **DEP-05**: Upload with butler (repeatable and keeps versions, but you log in to it once) or by hand on the itch.io website? Free or paid, and public, restricted (testers only) or a draft first? Recommendation: butler, and a restricted page first so friends can test before it goes public.
- **DEP-06**: Download rcedit (about 1 MB, from Electron's GitHub releases) or keep everything in the project's own script? Recommendation: rcedit, the tool Godot expects.

## Review history

### Loop 1 (2026-11-03T15:39:58+00:00)
- no findings
