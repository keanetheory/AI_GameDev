Lighting the Storm — Token Costs and Feasibility

Status: planning estimate, 25 September 2026. Covers Claude token costs for building the 10-minute prototype and the 30-minute full game with AI assistance, then assesses whether either can be finished by a solo developer in 6 weeks. All figures are estimates; measure real usage after week 1 and re-forecast.

Pricing basis

Claude API list prices, per million tokens (MTok):

|Model          |Input |Output|Cache read|Cache write (≈1.25× input)|
|---------------|------|------|----------|--------------------------|
|Claude Fable 5.1|$10.00|$50.00|$0.25     |$12.50                    |
|Claude Opus 5.5|$4.00 |$20.00|$0.20     |$5.00                     |
|Claude Sonnet 5|$2.00 |$10.00|$0.20     |$2.50                     |
|Claude Haiku 4.5|$1.00|$5.00 |$0.10     |$1.25                     |

If you use Claude Code on a Pro or Max subscription instead of the API, you pay a flat monthly fee with usage limits rather than per token. The token volumes below still tell you how heavy your usage will be; at the prototype rate (about 20 million input tokens a working day), expect to need a higher-usage tier.

How the estimate is built

The unit is one agent task: a bounded job such as “implement the gate interaction” or “fix the boat clipping through rocks”, including reading files, editing, running the project, and fixing errors.

A typical medium task is assumed to be about 40 model turns with an average context of 60K tokens:
• Input: about 2.4M tokens, of which about 90% are cache reads, 7% cache writes, and 3% uncached.
• Output: about 40K tokens, including thinking.

Cost per medium task:

|Model          |Cost per task|
|---------------|-------------|
|Claude Fable 5.1|$5.36       |
|Claude Opus 5.5|$2.36        |
|Claude Sonnet 5|$1.40        |
|Claude Haiku 4.5|$0.70       |

Recommended mix: Opus 5.5 for most implementation and debugging (70%), Sonnet 5 for routine scripting, data, and docs (20%), and Haiku 4.5 for search, file sweeps, and formatting (10%). Blended cost: about $2.00 per task.

As the codebase grows, context grows. Full-game tasks after the prototype are assumed to average 90K context (about 3.6M input tokens per task), which raises the blended cost to about $2.67 per task.

Prototype (10 minutes, 6 weeks)

|Workstream                                  |Tasks|
|--------------------------------------------|-----|
|Planning and docs                           |15   |
|Project setup and asset pipeline            |10   |
|Boat, hazards, steering and tuning iterations|40  |
|Stretch: wave hazards, only if time allows  |15   |
|Greybox levels and sightlines               |20   |
|Interaction, repair, crash and gate         |30   |
|Jeff’s cues and placeholder dialogue        |20   |
|State machine, deadline, endings and save   |20   |
|Lighting, weather and audio integration     |30   |
|Bug fixing and integration                  |40   |
|Playtest analysis and tuning                |10   |
|Total                                       |250  |

Token volume: about 600M input tokens (roughly 540M cache reads, 42M cache writes, 18M uncached) and about 10M output tokens. That is roughly 8 tasks, 20M input tokens, and 330K output tokens per working day.

|Scenario                          |Estimated cost|
|----------------------------------|--------------|
|Recommended mix                   |about $500    |
|All Claude Opus 5.5               |about $590    |
|All Claude Sonnet 5               |about $350    |
|All Claude Fable 5.1              |about $1,340  |
|Range (150–400 tasks, $1.50–$3.50 each)|$250–$1,400|

Full game (30 minutes, including the prototype)

Additional work after the prototype:

|Workstream                                         |Tasks|
|---------------------------------------------------|-----|
|Remaining lighthouse repairs                       |40   |
|Outpost exploration and optional discoveries       |40   |
|Full dialogue, journal text and subtitles          |40   |
|Final art integration (import, materials, collision, LODs)|80|
|Final audio mix                                    |30   |
|Accessibility, settings and input remapping        |30   |
|Controller support                                 |15   |
|Checkpoints and save/load hardening                |25   |
|Weather and lighting polish, performance           |50   |
|Steam integration, builds, store text              |25   |
|QA and bug fixing                                  |150  |
|Playtest rounds and tuning                         |40   |
|Planning and docs                                  |20   |
|Total additional                                   |585  |

Token volume for the whole game: about 2.7 billion input tokens (overwhelmingly cache reads) and about 33M output tokens, across roughly 835 tasks.

|Scenario                     |Estimated cost (whole game)|
|-----------------------------|---------------------------|
|Recommended mix              |about $2,050               |
|All Claude Opus 5.5          |about $2,430               |
|All Claude Fable 5.1         |about $5,450               |
|Range                        |$1,000–$5,000              |

Costs not included

• AI image, 3D, music, sound, or voice generation tools, which are billed by their own vendors.
• Paid engine assets (for example an ocean package if you choose Unity).
• The Steam Direct app fee (currently $100 per game; check current terms).

How to keep costs down

• Keep prompts and project docs stable so caching works; most input should be cache reads.
• Give each agent a narrow task brief (as AI Agent Strategy requires) so contexts stay small.
• Use Sonnet 5 or Haiku 4.5 for routine work, and lower effort for simple tasks.
• Clear or restart sessions between unrelated tasks instead of letting context grow.

Feasibility: solo developer, 6 weeks, AI assistance

Assumptions: about 40 hours a week (240 hours total), Godot 4, greybox art and placeholder audio for the prototype.

What AI changes: it speeds up writing code, data, docs, and dialogue drafts, realistically by 1.3–2× on those tasks. It helps little with steering feel, visual readability, consistent 3D art, playtesting, and integration debugging, and every AI change still needs your review.

Prototype: feasible, with conditions

A shippable prototype here means a 10-minute greybox build you can hand to playtesters (for example through itch.io or a Steam Playtest), passing the prototype outcome checks in the Executive Summary. It is not a product to sell.

Verdict: achievable in 6 weeks, with moderate confidence, if all of these hold:
• The steering spike passes by the end of week 2. If it fails, the 6 weeks produce a steering prototype, not the full 10-minute slice.
• Scope is frozen to the prototype list in the Executive Summary.
• Greybox art, placeholder audio, and text or AI-placeholder voice only.
• Controller support is deferred if it threatens the schedule (Decisions to be made, item 10).
• You reserve week 6 for playtests with 3–5 new players and fixes.
• Wave hazards stay a stretch goal. The crossings are built around rocks, buoys, and debris, which removes the hardest technical work (wave shader and matching buoyancy) from the critical path. If waves are not built, the 15 stretch tasks above are saved (about $30).

Schedule: follow the six-week prototype schedule in Technical Strategy, which is the single source of truth. In short: week 1 setup, boat and hazards; week 2 steering go/no-go; week 3 both crossings; week 4 repair, crash, gate and Jeff; week 5 deadline and outcomes; week 6 playtests. Waves fit only into spare time from week 5 onwards.

Full game: not feasible in 6 weeks

A shippable full game means a 30-minute commercial Steam release with final art, audio, accessibility, and a store page. Estimated solo effort:

|Area                                                        |Weeks  |
|------------------------------------------------------------|-------|
|Prototype                                                   |6      |
|Remaining repairs, outpost exploration, discoveries         |3      |
|Art: three locations, props, boat, and Ted, Jeff and Daniel models and animation|6–8|
|Audio and voice                                             |2      |
|Dialogue writing and recording (or AI voice)                |1–2    |
|Lighting, weather polish and performance                    |2      |
|Accessibility, controller, settings, checkpoints            |2      |
|Steam integration, store page, trailer, capsule art         |2      |
|QA, playtests, bug fixing                                   |3–4    |
|Total                                                       |27–31  |

That is about 6–7 months solo. Buying stock asset packs for environments and characters, and using AI voice, could bring it to about 5 months. Steam also requires a public Coming Soon store page for at least two weeks before launch, plus review time for the store page and build, so plan the store page well before the end.

Recommendation

Commit the 6 weeks to the prototype only. Use its week-2 steering result and week-6 playtests to decide whether to fund the remaining 4–6 months of full-game work, and re-run this cost forecast with the real token usage from the prototype.
