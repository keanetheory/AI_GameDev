# Storm Crossing Crew — for *Lighting the Storm*

**Game:** *Lighting the Storm* — a first-person, single-player atmospheric folk-horror adventure for PC, built in Godot 4 with GDScript.

**What this crew produces:** the game data for the **return crossing** of the Gate 1 vertical slice — the boat run from the Saltgate quays back to the Bracken Isle lighthouse with the replacement beacon burner aboard. One run of the crew outputs `return_crossing.json`, which the game loads directly, plus the `HANDOFF.md` and `REPORT.md` notes the creator uses to review the work before merging it.

## The story these crews serve

The creator fixed the story beats on 2026-10-16. They live in `canon.py` (`STORY_BEATS`) and every crew's canon text includes them, so no agent can reorder the game:

1. **Arrival.** The player, Isaac, starts outside the lighthouse. Ted opens the door ("You're the new guy, then") and Isaac comes in.
2. **Coal.** After a beat, Ted sends Isaac to the basement to shovel coal into the boiler.
3. **The sailors.** Arthur and Daniel moor their rowboat at the dock; Isaac opens the island gate on the path to let them in. Daniel stays in the basement.
4. **The burner.** The dynamo runs but the beacon stays dark. Ted takes Isaac up to the lantern room, finds the burner broken and says a new one is needed.
5. **First crossing.** Isaac takes the steam launch across the Gullwater with Arthur and retrieves the replacement burner from the Saltgate quays.
6. **The storm escalates** on the way back.
7. **The race.** Isaac must reach the lighthouse and fit the burner to the beacon before the passenger ship runs aground.

| Beats | Covered by |
|---|---|
| 1-5 | Opening Dialogue Crew (step 1 = beats 1-2, step 2 = beat 3, step 3 = beats 4-5); creator picks in `sample_output_picked/` |
| 5-7 | World crew (`OUTBOUND`, `RETURN` and `BEACON_RELIT` lighting phases; the boat's two legs) |
| 6-7 | Storm Crossing Crew (the return crossing data and Arthur's calls) |
| 7 (fail and win) | Story / Fail-State agent (role defined, not built yet) |

Words fixed by the beats: the part is **the burner** (never "lamp head"); the destination is **the Saltgate** (never "the outpost"); the fail is the ship **running aground**.

## Why the game needs this

In *Lighting the Storm*, Isaac steers a powered boat with one control at one fixed speed while Arthur, an old seaman, shouts directions over the storm. The return crossing is where the hidden ship deadline is running, so it is the part of the game where the design rules matter most. The design documents set several hard rules for it:

- Hazard density, route width and visibility must rise with route position, never with elapsed time (the "storm split").
- There is one shared hazard forecast with a single safe-route signal per segment, and Arthur's calls must never disagree with it.
- Only rocks, reefs, buoys and debris are allowed. Waves are an unapproved stretch goal, and route branching is deferred.
- There is no visible timer. Every collision is recoverable to a safe point.

Getting the hazard layout, the safe route and Arthur's lines to agree by hand is fiddly and easy to break whenever one piece is tuned. This crew generates all three together from one brief, checks them against each other and against the design pillars, and hands the creator a package that is consistent by construction. Regenerating it for a different difficulty preset (`standard` or `assist`) or route length is one command.

## The agents

The design submission (*Lighting the Storm - Design Submission*, updated 1 October 2026) defines **ten worker roles, each owning one department, overseen by two orchestrators**. The full roster is in `roles.py`. These are roles, not twelve agents running at once, and only the developer merges their work.

| Role | Kind | Owns | Review gate |
|---|---|---|---|
| **Production Orchestrator** * | Orchestrator | Task briefs, dependency order, event IDs and contracts, integrated build | Escalates on a missed exit test, contract change, task conflict or week 5 slip |
| **Canon and Review Orchestrator** * | Orchestrator | Pillar, scope-rule and decisions-log checks; the decisions log | Escalates on a canon question or a failed pillar test |
| **Boat / Physics agent** | Worker | Boat scene, controller, tuning resource | Developer plays the week-2 steering spike (go/no-go) |
| **Level Layout agent** | Worker | Greybox scenes, anchors | Traversal and sightline checks in the engine |
| **Gameplay / Systems agent** | Worker | Phase controller, save state, repairs, deadline | 10-minute slice plays end to end |
| **Hazard Forecast agent** * | Worker | Shared forecast, safe-route signal | Arthur's calls never disagree with the world |
| **Story / Fail-State agent** | Worker | Fail presentation, ship reveal, Ted's lamp staging | A tester can say why they failed from every expiry location |
| **Lighting agent** | Worker | Light rigs, visibility presets | Beacon and hazards legible at every phase |
| **Sound agent** | Worker | Audio banks, mix states | Arthur's warnings audible at peak storm |
| **Asset agent** | Worker | Source meshes, import settings | Assets import cleanly, fit the reference sheet |
| **Dialogue agent** * | Worker | Dialogue and journal data | Developer approves voice and lore before recording |
| **QA agent** | Worker | Scenario list, bug reports | Developer reproduces and prioritises each finding |

\* = runs in the return-crossing crew below. The other eight are in the roster but are not needed to generate this data.

### The return-crossing crew (four of the twelve)

They run in sequence, and each one's output is validated before the next can start.

| # | Agent | Input | Output | Why the pipeline breaks without it |
|---|---|---|---|---|
| 1 | **Production Orchestrator** | Creator goal, preset, segment count, canon | `CrossingBrief`: segment IDs, length, hazard density, route width, minimum visibility, boat speed, Arthur's call lead distance, constraints | Nobody defines the segments, tuning or difficulty curve. Agent 2 has nothing to place hazards into. |
| 2 | **Hazard Forecast agent** | `CrossingBrief` | `HazardForecast`: one safe lane per segment, hazards (type, lane, distance, readability cue), recovery safe points | There is no safe-route signal, so Arthur has nothing to call and the game has nothing to spawn. |
| 3 | **Dialogue agent** | `CrossingBrief` + `HazardForecast` | `ArthurCallSheet`: one shouted call per segment that matches its safe lane, subtitles, the arrival line ("go, go, go — don't wait for me") | The player gets no guidance. Pillar 3 says guidance comes from Arthur, not from markers. |
| 4 | **Canon and Review Orchestrator** | All three handoffs | `ReviewReport`: four pillar checks, Decisions-log checks, PASS/REVISE verdict, open creator decisions, handoff summary | The integrator refuses to write game data without a review, and `HANDOFF.md` has no verdict or evidence. |

**How the agents coordinate.** Every task has a CrewAI guardrail (`validators.py`). When an agent's output breaks the contract, for example when Arthur says "right" where the forecast's safe lane is "left", the specific error is sent back to that agent and it retries, up to three times. Validated outputs are stored in a shared state and passed on as context to later agents. After the crew finishes, `integrator.py` runs every check again end to end before it writes any game data.

## Architecture

The same diagram is in `crew_architecture.mermaid`.

```mermaid
flowchart TD
    subgraph IN["Inputs"]
        GOAL["Creator goal<br/>--preset, --segments"]
        CANON["canon.py<br/>pillars, Decisions log, stable IDs<br/>(from Exec Summary, Technical and AI Agent Strategy)"]
    end

    subgraph CREW["Storm Crossing Crew (CrewAI, Process.sequential)"]
        A1["Agent 1: Production Orchestrator<br/>IN: goal + canon<br/>OUT: CrossingBrief<br/>segments, density, width, speed, call lead"]
        G1{{"Guardrail 1<br/>schema + density rises,<br/>width narrows, no waves"}}
        A2["Agent 2: Hazard Forecast agent<br/>IN: CrossingBrief<br/>OUT: HazardForecast<br/>one safe lane + hazards per segment"]
        G2{{"Guardrail 2<br/>no hazard in safe lane,<br/>IDs, counts never fall"}}
        A3["Agent 3: Dialogue agent<br/>IN: CrossingBrief + HazardForecast<br/>OUT: ArthurCallSheet<br/>one call per segment + arrival line"]
        G3{{"Guardrail 3<br/>call direction = safe lane,<br/>lead distance, no timer words"}}
        A4["Agent 4: Canon and Review Orchestrator<br/>IN: brief + forecast + calls<br/>OUT: ReviewReport<br/>4 pillar checks, Decisions-log checks, verdict"]
        G4{{"Guardrail 4<br/>verdict consistent<br/>with checks"}}
    end

    INT["integrator.py<br/>re-runs all contract checks,<br/>merges handoffs"]

    subgraph OUT["Outputs for Lighting the Storm"]
        JSON["return_crossing.json<br/>Godot game data"]
        HO["HANDOFF.md + REPORT.md<br/>creator review notes"]
        GD["godot/crossing_loader.gd<br/>hazard spawns, Arthur calls,<br/>RETURN_ARRIVED"]
    end

    GOAL --> A1
    CANON --> A1 & A2 & A3 & A4
    A1 --> G1
    G1 -- "fail: errors fed back, retry" --> A1
    G1 -- "pass: CrossingBrief" --> A2
    A2 --> G2
    G2 -- "fail: retry" --> A2
    G2 -- "pass: HazardForecast" --> A3
    G1 -. "CrossingBrief (context)" .-> A3
    A3 --> G3
    G3 -- "fail: retry" --> A3
    G3 -- "pass: ArthurCallSheet" --> A4
    G1 -. "brief" .-> A4
    G2 -. "forecast" .-> A4
    A4 --> G4
    G4 -- "fail: retry" --> A4
    G4 -- "pass: ReviewReport" --> INT
    INT --> JSON & HO
    JSON --> GD
```

## Running it

```bash
pip install -r requirements.txt

# 1. Smoke test, no API key needed: the full CrewAI pipeline runs with a scripted LLM
python main.py --offline

# 2. Real run: copy .env.example to .env and add your ANTHROPIC_API_KEY
python main.py
python main.py --preset assist --segments 4 --out output_assist
```

| Flag | Default | Meaning |
|---|---|---|
| `--offline` | off | Use `offline_llm.py` (deterministic, no key) instead of a real model |
| `--preset` | `standard` | `standard` or `assist` (the reduced hazard-intensity preset) |
| `--segments` | `5` | Route segments, 3–8 |
| `--goal` | Gate 1 return-crossing goal | The creator's goal text given to the Production Orchestrator |
| `--out` | `output` | Output folder |
| `--quiet` | off | Hide CrewAI's verbose agent logs |

You can switch models with `CREW_MODEL` in `.env`. Any CrewAI/LiteLLM model string works, for example `openai/gpt-4o-mini` with `OPENAI_API_KEY` set.

**Offline mode** exists so the crew can be run and marked without an API key. It still runs the real CrewAI agents, tasks, context passing and guardrails. Only the model's text is scripted. On purpose, the Dialogue agent gets one call wrong on its first attempt. The console then shows `Guardrail blocked (attempt 1/4) ... ARTHUR_RET_02 says 'right' but the forecast safe lane for SEG_02 is 'left'`, followed by the corrected retry, so you can see the agents coordinating. The creative content in a real run comes from the LLM.

## Output

```
output/
├── return_crossing.json      # loaded by the game
├── HANDOFF.md                # 8 fixed headings from the AI Agent Strategy
├── REPORT.md                 # orchestrator report, fixed headings
└── handoffs/                 # each agent's validated output, for traceability
    ├── 01_brief.json
    ├── 02_forecast.json
    ├── 03_calls.json
    └── 04_review.json
```

`return_crossing.json` holds the tuning values (fixed boat speed, call lead, route length, `waves_enabled: false`) and the stable event IDs (`RETURN_DEPARTED`, `SEGMENT_ENTERED`, `HAZARD_COLLISION`, `RECOVERY`, `RETURN_ARRIVED`). For each segment it gives the safe lane, the recovery point, the hazards with their absolute route positions, and Arthur's call with its trigger position. `sample_output/` contains a complete offline run.

**Using it in Godot 4:** copy the JSON to `res://data/` and attach `godot/crossing_loader.gd` to the sea scene. Each physics frame, call `advance(route_m)`. The loader emits `arthur_call`, `segment_entered` and `return_arrived` signals and provides `hazards()` for the spawner. `reset_for_restart()` supports the Gate 1 "fail, then restart the slice" model.

## The Opening Dialogue Crew (second pipeline)

A second crew writes the Gate 1 **opening dialogue** for Ted, Arthur and Daniel: step 1 *Arrive and feed the boiler* (story beats 1-2), step 2 *Let the sailors in* (beat 3) and step 3 *Fetch a new burner* (beats 4-5: Ted finds the burner broken, then the Saltgate crossing). It uses the same roster, the same schema + validator + guardrail pattern and the same offline mode as the crossing crew. Three of the twelve roles run:

| # | Agent | Input | Output | Guardrail (validators.py) |
|---|---|---|---|---|
| 1 | **Production Orchestrator** | Creator goal + canon | `DialogueBrief`: steps, every event ID, word limit, player term, constraints | `check_dialogue_brief`: player term is the creator's, steps 1-3, `BOARDING_THRESHOLD` exists |
| 2 | **Dialogue agent** | `DialogueBrief` | `OpeningDialogue`: lines, alternates, nudge ladders, assist hints, journal | `check_dialogue`: word limit, no timer words or numbers, no 'apprentice', no early ship, 'burner' not 'lamp head', no supernatural confirmation, 'SPEAKER:' subtitles, tiers, groups, coverage |
| 3 | **Canon and Review Orchestrator** | Brief + dialogue | `ReviewReport` (reused) | `check_review` (reused) |

```mermaid
flowchart TD
    subgraph IN["Inputs"]
        GOAL["Creator goal<br/>(steps 1-3, player is 'Isaac')"]
        CANON["canon.py<br/>voices, steps, event IDs, dialogue rules<br/>(from GDD + Lore Build)"]
    end

    subgraph CREW["Opening Dialogue Crew (CrewAI, Process.sequential)"]
        A1["Agent 1: Production Orchestrator<br/>IN: goal + canon<br/>OUT: DialogueBrief"]
        G1{{"Guardrail 1<br/>player term, steps 1-3,<br/>events include BOARDING_THRESHOLD"}}
        A2["Agent 2: Dialogue agent<br/>IN: DialogueBrief<br/>OUT: OpeningDialogue<br/>lines, nudge ladders, alternates, journal"]
        G2{{"Guardrail 2 (check_dialogue)<br/>word limit, no timer words, no 'apprentice',<br/>no early ship, burner not lamp head,<br/>tiers, groups, coverage"}}
        A3["Agent 3: Canon and Review Orchestrator<br/>IN: brief + dialogue<br/>OUT: ReviewReport"]
        G3{{"Guardrail 3<br/>verdict consistent with checks"}}
    end

    INT["dialogue_integrator.py<br/>re-runs all checks, writes files"]

    subgraph OUT["Outputs"]
        JSON["dialogue_opening.json<br/>Godot game data"]
        MD["DIALOGUE_OPENING.md<br/>creator review list"]
        LOG["run_log.json + HANDOFF.md + REPORT.md<br/>every guardrail attempt"]
    end

    GOAL --> A1
    CANON --> A1 & A2 & A3
    A1 --> G1
    G1 -- "fail: errors fed back, retry" --> A1
    G1 -- "pass" --> A2
    A2 --> G2
    G2 -- "fail: errors fed back, retry" --> A2
    G2 -- "pass: OpeningDialogue" --> A3
    A3 --> G3
    G3 -- "fail: retry" --> A3
    G3 -- "pass" --> INT
    INT --> JSON & MD & LOG
```

```bash
python main_dialogue.py --offline                      # no API key: scripted model, real agents and guardrails
python main_dialogue.py                                # a real model writes the lines
python main_dialogue.py --offline --max-words 12       # negative test: the checks block it and no game data is written
python main_dialogue.py --offline --godot-dir ../../../LightingTheStorm   # also copies the JSON into the game project
```

Offline mode replays `offline_dialogue_draft.json` (the 62-line draft, in the canon beat order since 2026-10-16). As with the crossing crew, its first attempt deliberately contains faults (an 'apprentice', an early mention of the ship, a 'lamp head') so the console shows `Guardrail blocked (attempt 1/4)` and the corrected retry. Use `--no-demo-errors` to skip that. Every attempt is recorded in `run_log.json`. `sample_output_dialogue/` holds a complete run plus the negative test.

**Live runs.** Set `ANTHROPIC_API_KEY` in `.env`. If Anthropic answers 400 about a workspace, also set `ANTHROPIC_WORKSPACE_ID` (the key is not workspace-scoped). If it answers 404 for the model, set `CREW_MODEL` to one your workspace has (for example `anthropic/claude-sonnet-5-5`). A REVIEW verdict of REVISE still writes files, but marks the JSON `needs_revision` and lists the reviewer's issues; read them before using the lines. `sample_output_live/` holds the first live run.

**Revision loop.** If the reviewer returns REVISE, the crew does not stop: its failed checks and issues go back to the Dialogue agent (`dialogue_revision.py`), the corrected dialogue goes through the same `check_dialogue` guardrail, and the Canon and Review Orchestrator re-reviews it (up to `--max-revisions`, default 2). Superseded rounds are kept in `handoffs/history_round*`. Two checks were added after the first live run: a line's `step` must equal its trigger event's step, and a reviewer's "all N lines" claims must match the data. `python main_dialogue.py --revise-from sample_output_live --out sample_output_live_revised` continues a saved run; `--simulate-revise` (offline) tests the loop for free. `sample_output_live_revised/` holds the live run after one revision (verdict PASS, 14 of 14 checks).

**Creator picks and the story beats.** The game's dialogue is the creator's line-by-line picks, not a raw crew run. `apply_creator_picks.py` keeps one line per group from `sample_output_live_revised/`, then `story_beats.py` puts the lines in the canon beat order (2026-10-16: the arrival line at the door, TED_S1_03 moved to `LIGHTHOUSE_ENTERED`, the burner lines moved to step 3, the new TED_S3_00 on `BEACON_STILL_DARK`, `OUTPOST_REACHED` renamed `SALTGATE_REACHED`). Lines keep their IDs, so voice and subtitle references stay valid. The result goes to `sample_output_picked/` (40 lines, deterministic review PASS):

```
python apply_creator_picks.py --install                       # also writes LightingTheStorm/data/dialogue/dialogue_opening.json
python ../LightingTheStorm/tools/build_character_pages.py     # Docs/Lore Build/dialogue pages from the picked set
python ../LightingTheStorm/tools/build_illustration.py        # the opening-dialogue flow illustration
```

The rewritten lines (TED_S1_01, TED_S1_09, TED_S1_10, TED_S1_11, TED_S3_02, ARTHUR_S3_04) and the new TED_S3_00 still need a Dialogue agent and Canon re-review before recording.

## The Voice Casting Crew and the ElevenLabs sender (fifth pipeline)

The **Sound agent** writes a voice casting for Ted, Arthur and Daniel (voice descriptions, delivery and per-line direction) from the opening dialogue, and the Canon and Review Orchestrator checks it (`voice_crew.py`, `voice_schemas.py`, `voice_validators.py`, `voice_integrator.py`). `python main_voice.py --offline` runs it with the scripted model; `--dialogue` picks the dialogue file to cast (default: `sample_output_picked/`).

`main_elevenlabs.py` sends the casting to ElevenLabs in three stages, each a dry run unless `--send` is given: `design` (voice previews), `save` (the picked previews into the voice library, writing `elevenlabs/voices.json`) and `tts` (line audio, spends credits, into `elevenlabs/lines/<LINE_ID>.mp3`). `voice_output_picked_live/` holds the creator's picked casting and audio.

**Stale audio (2026-10-16):** the story-beat revision rewrote six lines that already have audio in `voice_output_picked_live/elevenlabs/lines/` (TED_S1_01, TED_S1_09, TED_S1_10, TED_S1_11, TED_S3_02, ARTHUR_S3_04), and TED_S3_00 has none. Regenerate them with `tts` once the new lines are approved. The game does not play line audio yet.

## The Asset agent and the World Crew (third and fourth pipelines)

Two more pipelines, built for the Godot environment and the FAL asset work. Same pattern as the others: schema + deterministic checks + CrewAI guardrails + an offline mode.

| Pipeline | Agents | Run | Output |
|---|---|---|---|
| **Asset review** | **Asset agent** | `python main_asset.py sample_submissions --offline` | `asset_reviews/<id>.review.json`, `<id>.approved_prompt.txt`, `summary.json` |
| **World crew** | **Boat / Physics agent**, **Player Movement agent** (new role), **Lighting agent**, then the Canon and Review Orchestrator | `python main_world.py --offline` | `world_output/boat_spec.json`, `player_movement_spec.json`, `lighting_spec.json`, `HANDOFF.md`, `REPORT.md` |

**Asset agent.** Run it on every FAL submission before you spend a generation. A submission is a `*.fal.json` file (`asset_id`, `category`, `fal_model`, `prompt`, `negative_prompt`, optional `source_image`, `notes`; see `sample_submissions/`). The checks read `Docs/Lore Build/world/style_guide.md` live (`style_guide.py`), so editing the guide changes what is approved:

- the prompt uses the guide's style descriptors (cel shading plus at least three of four groups);
- no reference touchstones, "in the style of", artist names, photoreal, modern or sci-fi wording, or the retired name Brusskania;
- nothing from the guide's global negative list appears in the positive prompt, and the negative prompt contains all of them;
- any `#hex` colour is in the guide palette; Saint Calder prompts carry amber, gold and "gothic";
- if `source_image` is given, Pillow checks it is muted, dark and near the palette (all 31 concept images pass).

The agent writes a verdict, a repaired prompt and negative prompt, the Godot folder for the category (`res://Assets/Models/<category>/`) and import notes (scale, pivot, collision, materials). The guardrail refuses an APPROVE when the checks found problems and refuses a revised prompt that still breaks the guide. `python main_asset.py <files> --check-only` runs just the deterministic checks without any model.

**Boat / Physics agent.** One fixed speed, steered only by **A and D** (`move_left`, `move_right`); W and S do nothing. The spec covers the OUTBOUND leg `DOCK_LIGHTHOUSE -> DOCK_PORT` (the Saltgate quays) and the RETURN leg back, waypoints, steering response and a rudder that returns to centre, automatic docking zones, collision recovery and handling checks. `waves_enabled` is the waves on/off switch (waves approved 2026-10-20) and `tide_hook` names the `water_push` hook the Wave Creator Agent drives.

**Player Movement agent.** Walking and turning tuning (unsmoothed mouse look, delta-time movement, simultaneous move and turn, slope and step limits from the real island collider) plus seven glitch checks (slopes, lips, turning while moving, corners, falling through, frame rate, camera), each with a repeatable test. `tools/debug_walk.gd` in the Godot project is one such test.

**Lighting agent.** Four phases (ISLAND, OUTBOUND, RETURN, BEACON_RELIT), each with clouds, rain and lightning: ominous clouds gathering and dry on the island, darker and fuller with rain starting on the outbound crossing, darker skies with lightning between the clouds from the return on. A huge silver supermoon lights both crossings through a gap in the cloud (the Flighted ship that eclipses it comes later). Lightning is flash-rate capped at 3 per second, reveals hazards and is driven by phase and route position, never elapsed time. Also covered: the lighthouse beacon, arc lamp, steam glow and windows, the boat lamp, and distant Saint Calder (amber and gold only; its lit windows are just visible from the lighthouse and more obvious from the Saltgate). Every colour must be in the style guide palette and no light may be a navigation marker.

The phases follow the story beats: ISLAND covers beats 1-4, OUTBOUND beat 5, RETURN beat 6 and BEACON_RELIT beat 7. The storm stays near full strength once the beacon is relit. The supermoon sits low on the far side of the lighthouse from the Saltgate, so it lights the crossings and leaves Saint Calder dark; Saint Calder's lit windows flicker (a creator test). On the RETURN only, lightning shows a forked bolt that strobes the cloud around it 2-4 times per strike (the flicker stays in that cloud; the one scene-wide flash per strike stays inside the photosensitivity cap), and a second, darker, part-transparent cloud layer drifts slowly across the sky and the moon and is lit through by the strikes. The checks in `world_validators.py` enforce all of this, and the title splash screen is the look reference.

**In Godot,** `LightingTheStorm/scripts/world/lighting_rig.gd` (a `LightingRig` node in `Level.tscn`) reads `data/world/lighting_spec.json` and builds the moonlight, the storm sky (`storm_sky.gdshader`), rain, lightning and Saint Calder's windows. The phase follows the boat (it blends to OUTBOUND when the boat leaves the island and to RETURN when it leaves the Saltgate); F5-F8 jump to a phase for testing. `python main_world.py --offline --godot-dir ../LightingTheStorm` copies the specs into `data/world/`.

**FAL sender.** `main_fal.py` sends an approved `*.fal.json` submission to FAL (Hunyuan3D) and saves the model under `LightingTheStorm/Assets/Models/<category>/`. It is a dry run unless `--go` is given; run `main_asset.py --check-only` on the submission first. Hunyuan3D v3 returns 4096 textures: downscale them with `LightingTheStorm/tools/downscale_glb_texture.py`.

Offline mode makes the first Boat attempt press a throttle key and the first Lighting attempt use a neon colour, so you can see the guardrails block and the agents retry. Pass `--no-demo-errors` to skip that. On Windows, set `PYTHONIOENCODING=utf-8` to silence harmless console encoding noise from CrewAI's live display.

### Tide / Wave agent: built (2026-10-20)

The Wave Creator Agent now exists in `GERFramework/` (specs in `LightingTheStorm/data/world/wave_spec.json`). The reminder below is kept for history.

### Reminder (history): build the Tide / Wave agent next

The **Tide / Wave agent is deliberately not built yet.** Build it once there is a traversable Godot level (the lighthouse island with the player walking and the boat crossing). The waves in the crossing are a game mechanic, but the rules still say otherwise, so do these first:

1. Update `canon.py`, `validators.py` (`check_brief`) and `schemas.py` (`HazardType`) so waves are approved and say how a tide affects the crossing (the lore says the eclipse makes tides more aggressive).
2. Add the agent to `roles.py` and run it in the crossing crew next to the Hazard Forecast agent, so Arthur's calls and the safe lane read the tide schedule.
3. Connect it to the boat's `tide_hook` and set `waves_enabled` to true only then.
4. Replace the cosmetic wave shader in `LightingTheStorm/scripts/world/sea.gd` with one driven by the same tide data.

## Files

| File | Purpose |
|---|---|
| `main.py` | CLI entry point: picks the LLM, runs the crew, writes outputs |
| `roles.py` | The full 12-role roster from the design submission |
| `crew.py` | The four crossing agents, their tasks, context links and guardrails |
| `schemas.py` | Pydantic contracts for every handoff |
| `validators.py` | Deterministic cross-checks (the game's rules as code) |
| `canon.py` | Canon taken from the three design documents, plus the creator's `STORY_BEATS` |
| `story_beats.py` | Puts an opening-dialogue line set in the canon beat order (used by `apply_creator_picks.py`) |
| `apply_creator_picks.py` | Builds the game's dialogue from the creator's picks; `--install` copies it into the game |
| `integrator.py` | Final checks; writes game data, HANDOFF.md and REPORT.md |
| `offline_llm.py` | Scripted LLM for runs without a key |
| `godot/crossing_loader.gd` | Reads the output in the game |
| `crew_architecture.mermaid` | Architecture diagram |
| `dialogue_crew.py` | The three dialogue agents, their tasks, context links and guardrails |
| `dialogue_integrator.py` | Final checks; writes `dialogue_opening.json`, the review list, HANDOFF.md, REPORT.md, run_log.json |
| `main_dialogue.py` | CLI for the dialogue crew |
| `offline_dialogue_llm.py`, `offline_dialogue_draft.json` | Scripted model and the draft it replays |
| `dialogue_crew_architecture.mermaid` | Dialogue crew diagram |
| `style_guide.py` | Reads `style_guide.md` and runs the prompt and image style checks |
| `world_schemas.py`, `world_validators.py`, `world_canon.py` | Contracts, checks and canon for the Asset, Boat, Player Movement and Lighting agents |
| `asset_crew.py`, `main_asset.py` | The Asset agent and its CLI |
| `world_crew.py`, `main_world.py` | The Boat, Player Movement and Lighting agents plus reviewer, and their CLI |
| `offline_world_llm.py`, `llm_factory.py` | Scripted model for both new crews; real model setup |
| `sample_submissions/` | FAL submissions (examples and the real island, dock and model jobs) |
| `main_fal.py` | Sends an approved FAL submission and saves the model into the game |
| `voice_crew.py`, `main_voice.py`, `voice_*.py` | The Voice Casting crew, its contracts, checks and output |
| `main_elevenlabs.py` | Sends the voice casting to ElevenLabs (design, save, tts) |

## Scope and limits

The crew follows the game's own rules for agents: it only proposes, and the creator reviews and merges. It does not decide the open canon questions (exact collision time cost, deadline length, pause exploits, the final retry and save model). Those are carried into `HANDOFF.md`. Steering feel, hazard readability in engine and Arthur's voice performance still need human playtesting.
