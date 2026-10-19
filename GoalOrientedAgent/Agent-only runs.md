# Agent-only runs

Work the Goal-Oriented Agent's workflow can do **on its own, without the Anthropic API**. These runs are done by a Claude Code session acting in the agent's role: it reads the backlog, plans, edits files and runs headless Godot tests, then records the result here and in `DEVLOG.md`. The agent's rule still applies: nothing that needs the Godot editor, a creator decision, or paid services is attempted.

**Status key:** DONE · IN PROGRESS · READY (nothing open blocks it) · WAITING (names what it needs) · CREATOR (a decision only you can make; the agent can only draft options)

**Source of truth for dependencies:** `GOA Dependency Order.md` and `state/backlog.json`. **Test command** (Godot 4.3 console build, from `LightingTheStorm/`):

```bash
"C:\Users\pmkea\Downloads\Godot_v4.3-stable_win64.exe\Godot_v4.3-stable_win64_console.exe" --headless --path . --script res://tools/<test>.gd
```

## Ground rules for these runs

1. **Smallest change that meets the task**, matching the surrounding GDScript.
2. **New files first.** Another session is working in the same project (the interior, the door, the burner pickup), so these runs add new scripts and tests and avoid editing files that have uncommitted changes from someone else. Hooking a new system into an existing scene or script is listed as a separate step and flagged.
3. **Every run ends with a headless test** that passes, or a clear statement of what could not be verified.
4. **Honest verification.** Headless tests prove logic, not feel, looks or sightlines. Each run lists what you still have to check in the editor.
5. **Recorded.** Each finished run gets an entry in `DEVLOG.md` (files changed, decisions, what is left), and the task is updated in `state/backlog.json`.

## Runs

### Ready now

| Run | Task | Score | What it builds | Test | Status |
|---|---|---|---|---|---|
| A1 | **T03** Generic first-person interaction system | 9 | An `Interaction` autoload plus a reusable `Interactable` node: one prompt, one `interact` consumer, best-target choice by reach and facing, diegetic text only. The template for the boiler (T33), gate (T04), burner (T29/T32) and lamp. | `tools/test_interaction.gd` | **DONE** 2026-10-19: 18 checks pass |
| A2 | **T12** Subtitle and journal UI | 7 | A `CanvasLayer` autoload that shows speaker-attributed subtitles from `Dialogue.line_started`, and a handwritten-style journal from `journal_entry_added`. No timer, no markers. Assist hint stays off by default. | `tools/test_subtitles.gd` | **DONE** 2026-10-19: 20 checks pass |
| A3 | **T21** Gate the debug display | 3 | Hide the `Lighting: <phase>` label and the F5-F8 phase jumps in `lighting_rig.gd` unless a debug flag is on. | `tools/test_debug_flags.gd` (run with and without `-- --no-debug-ui`) | **DONE** 2026-10-19: 5 checks pass each way |
| A4 | **T22** Game readme and handoff template | 4 | Fill the empty `LightingTheStorm/readme.md` (engine 4.3, how to run, controls, event IDs, scene ownership, debug keys) and add a per-task `HANDOFF` template. | read-through against the code | **DONE** 2026-10-19: `LightingTheStorm/readme.md` and `HANDOFF_TEMPLATE.md` |
| A5 | Fold the burner and door prompts into the interaction system | n/a | `door.gd` and `burner_pickup.gd` each carry their own prompt label and reach test, and `door.gd` says T03 should absorb them. Convert them to `Interactable`. **Touches files the other session is editing, so it waits for its go-ahead.** | `test_door.gd`, `test_burner_pickup.gd` must still pass | **DONE** 2026-10-19: the other session landed; all related tests pass |

### Waiting on a dependency

| Run | Task | Score | What it builds | Waiting on |
|---|---|---|---|---|
| A6 | **T29** Carry system | 10 | Hold one item, stow it aboard the boat, survive a hazard hit, hand back ashore, release only into a valid socket. Note: the other session's `burner_pickup.gd` already covers the hold-in-hands half; read it first. | **DONE** 2026-10-19: `tools/test_carry.gd` passes 8 of 8 runs |
| A7 | **T28** Lamp socket, boiler, coal and gauge (greybox) | 9 | The props the later beats use. | T02 (interior, needs the editor) |
| A8 | **T33** Boiler coal job | 9 | `BOILER_FED` through the interaction system. | T02, T03, T28 |
| A9 | **T05** Lantern-room diagnosis | 9 | `BEACON_STILL_DARK` to `BURNER_BRIEFING` sequence. | T02, T04, T28, T30 |
| A10 | **T32** Burner fit | 10 | Fit the burner into the lamp socket: `BURNER_FITTED`, then `BEACON_RELIT`. | T02, T28, T29 |
| A11 | **T07** Hidden ship deadline | 10 | Internal numeric deadline with no UI, started once by `RETURN_DEPARTED`, with a debug time scale and event log. | T31 (ship route) |
| A12 | **T13** Storm cues follow elapsed time | 7 | Rain, lightning, wind and ship lights blend by elapsed deadline time; hazards stay on route position. | T07, T32 |
| A13 | **T11** Arthur aboard and the arrival beat | 7 | Arthur seated on the boat; `BOARDING_THRESHOLD`; the "go, go, go" line on `RETURN_ARRIVED`. | T30, T31 |
| A14 | **T10** Crew hazard forecast in the sea | 8 | Load `return_crossing.json` through `crossing_loader.gd`, spawn buoys and debris, play Arthur's calls as subtitles. | T12 is done, so **READY** (needs a boat route feed; check with the other session) |
| A15 | **T20** QA scenarios and state checks | 5 | Scenario list and headless transition checks beside the existing tests. | T08 |

### Drafting only (you decide)

| Task | What the agent can do |
|---|---|
| **T34** Discoveries content (B2), due Fri 23 Oct 2026 | Lay out options with their cost and effect on the pillars. |
| **T16** Ted's lamp-room line list | Propose a short list and the recording cost of each line. |
| **T19** Placeholder deadline length and penalties | Propose labelled placeholder numbers from the crossing time. |

### Not agent-only (needs you or the editor)

T02 interior, T30 NPC placements, T31 ship route, T04 rowboat and gate, T08 outcomes and the fail screen, T14 audio, T17 tuning, T18 voice lines (ElevenLabs credits), T23 baking, T24 walkway.

## Run log

| Run | Started | Finished | Result | Entry |
|---|---|---|---|---|
| A6 T29 | 2026-10-19 | 2026-10-19 | DONE, carry test 8 of 8 runs, all other tests pass | `DEVLOG.md`, T29 |
| A5 fold prompts | 2026-10-19 | 2026-10-19 | DONE, door, burner, interior, boat and state tests pass | `DEVLOG.md`, A5 |
| A4 T22 | 2026-10-19 | 2026-10-19 | DONE | `DEVLOG.md`, T22 |
| A3 T21 | 2026-10-19 | 2026-10-19 | DONE, 5 checks pass with the aids on and off | `DEVLOG.md`, T21 |
| A2 T12 | 2026-10-19 | 2026-10-19 | DONE, 20 headless checks pass | `DEVLOG.md`, 2026-10-19 T12 |
| A1 T03 | 2026-10-19 | 2026-10-19 | DONE, 18 headless checks pass; door, burner and game-state tests still pass | `DEVLOG.md`, 2026-10-19 T03 |

### Stability check: the carry test, 8 of 8 runs

The first version of `tools/test_carry.gd` failed about one run in eight. The cause was a real reach problem (the boat's cargo slot could not be reached from the lighthouse landing), not test noise. After the fix the test was run eight times in a row and passed every time (2026-10-19), and the other eight tests in `tools/` were run once each and passed (door, burner pickup, interaction, game state, subtitles, interior walk, boat, debug flags). The README summarises all six runs in its section "Agent-only runs: what the agent did on its own, with the creator's approval".
