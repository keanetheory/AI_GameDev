# GER Framework

Five creator agents and seven assessment agents for *Lighting the Storm*, built on branch `GER-Framework-Build`.

**GER = Goals, Execution, Review.** Each agent lists prioritised objectives scored 1-10 (10 = absolute must, same rubric as the Goal-Oriented Agent), executes only after your all clear, and is reviewed by its assessor for at most three loops at each stage. (The brief did not define the letters; if you meant something else, only this paragraph and the roster text change.)

## The agents

| Creator agent | Reviewed by | Does |
|---|---|---|
| Island Creator | Island Assessment Agent | No holes or empty meshes, quick load, lit correctly by the Lighting agent, reacts to the storm |
| Lighthouse Interior Creator | Lighthouse - Interior Assessment Agent | Fits the greybox to the exterior model, builds the Interior Plan V4 rooms, walkable route, sightlines |
| Saltgate Creator | Saltgate Assessment Agent | Polishes the huts and port, smooth arrival off the boat, port grown into the cliffside |
| Cliffside Creator | Cliffside Assessment Agent | No gaps, quick load, walkway built from the cliff stone, trees and path rooted into the rock |
| Wave Creator | Waves - Assessment Agent | Tides and waves as an independent system; first crossing easy, last crossing stormy |

Two assessors have no creator in this batch and review existing work on request (`python ger.py assess <id>`): **Lighthouse - Exterior** (feedback to the Lighthouse Interior and Island creators) and **Boats** (feedback to the existing Boat / Physics agent and the Wave creator).

Full objective lists with scores: [AGENT_ROSTER.md](AGENT_ROSTER.md). Live plans: `reports/<creator>_plan.md`.

## The loop

```
plan (creator) -> assessor reviews -> creator revises -> ... (max 3 loops)
   -> YOU read the plan and give the all clear   <-- only you can do this
   -> creator executes -> assessor reviews the work -> creator fixes without asking you -> ... (max 3 loops)
   -> report to you; you decide what happens next
```

1. **Assessors read first.** `python ger.py ingest` has each assessor read the Lore Build and the final GDD (51 docs) and store its own understanding in `knowledge/<assessor>.json`: content hashes, the lines in its domain, the hard rules it holds work to, and the open questions it must not let anyone settle silently. It re-reads only what changed.
2. **Plan review.** `python ger.py review-plan <creator|all>`. The rubric blocks: a missing field, a score outside 1-10, no 10 anywhere, fewer than three distinct scores, a reference that does not exist, a forbidden term (Brusskania), a must-have scored lower than something it depends on, a coverage gap against the assessor's must-cover list, and a closed canon gate. The creator answers mechanically (raise an under-scored objective, add a missing one); anything it cannot fix is escalated to you. Nothing reaches you with a blocking finding unless it says so.
3. **Your all clear.** `python ger.py approve <creator> --quote "<your words>"`. `execute` and `review-work` refuse to run until this is recorded.
4. **Execute.** `python ger.py execute <creator>` prints the brief, top-down by score. Objectives marked "needs creator" are decisions for you; the agent asks.
5. **Work review.** `python ger.py review-work <creator>` re-runs every objective's check and the assessor's own independent checks, and writes `reports/<creator>_work.md`. Blocks go back to the creator agent, which fixes them without involving you. The fourth run is refused; what is left is reported to you.

## Offline by default

Assessment uses only the offline AI Crew and deterministic checks: Lore/GDD digests, the mesh auditor, file/scene/grep checks, and AIAgentCrew commands run with `--check-only` or `--offline`. No Anthropic, FAL or ElevenLabs call is made, and `crew_offline` checks without those flags are refused. **Only when you type "run an online assessment exercise"** may an assessor add model-based judgement, for that assessment only.

Note: the assessors and creators are also Claude Code agents (`.claude/agents/ger-*.md`, generated from the specs). Running one as a Claude Code agent uses that session's tokens; the rule inside each says to use the offline commands and only report what they return. For zero model spend, run the `ger.py` commands directly.

## Mesh auditor (the "no empty or hollow meshes" check)

`python ger.py audit <glb...>` parses GLB files with numpy only. It reports empty meshes, meshes no node uses, **hole loops** (after welding duplicate vertices, every ring of open edges; the game's generated meshes are closed shells, so any loop is a place you can see through), the open-edge percentage, degenerate triangles, file size and texture memory. It is proven against synthetic meshes with known holes in `tests/test_framework.py`.

Limits: it sees geometry, not intent. A doorway with nothing behind it is a closed mesh and needs a visual check. Load time is a proxy (MB, triangles, texture memory) until `tools/measure_load_time.gd` is written and run in Godot.

## Commands

```bash
python GERFramework/ger.py list
python GERFramework/ger.py ingest all
python GERFramework/ger.py review-plan all          # --reset starts a plan again from its spec
python GERFramework/ger.py show island_creator
python GERFramework/ger.py approve island_creator --quote "all clear"
python GERFramework/ger.py execute island_creator
python GERFramework/ger.py record island_creator ISL-01 done --note "audit clean"
python GERFramework/ger.py review-work island_creator
python GERFramework/ger.py assess boats_assessor
python GERFramework/ger.py export-agents            # regenerate .claude/agents and AGENT_ROSTER.md from the specs
python GERFramework/tests/test_framework.py
```

## Files

| Path | What |
|---|---|
| `agents/creators/*.json`, `agents/assessors/*.json` | The source of truth: objectives, scores, reasons, checks, collaborators, must-cover lists, canon gates |
| `ger_core/` | `spec`, `knowledge`, `meshaudit`, `checks`, `review`, `loop`, `export` |
| `state/<creator>.json` | Phase, loop counts, the revised plan, approval quote, per-objective records, history |
| `reports/` | Plan, work and assessment reports |
| `workshops/wave_design_workshop.md` | The tide and wave design conversation, with the questions only you can answer |
| `contracts/` | Written agreements between creator agents (the port-to-cliff joint) |
| `.claude/agents/ger-*.md` | The twelve Claude Code agent definitions |

## Waves

There was no wave agent. Waves were an unapproved stretch goal in the GDD (Decisions 20 and 24) and in `canon.py`, `validators.py`, `schemas.py` and `world_canon.py`. The Wave creator's spec records your instruction as clearing the `WAVES_DECISION20` gate (`gates_cleared` in `wave_creator.json`; set it to `false` to revoke). Objective WAV-03 rewrites the four canon files, and only after your all clear. The boat already exposes the hook (`water_push`) and the sea has one shared `wave_height()`.
