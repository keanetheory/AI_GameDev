# Game Design Document — [Game Title]

> A working template for defining, building, and validating a game. Replace bracketed placeholders with project details. Delete prompts once answered, and mark irrelevant sections **Not applicable** with a short reason.

| Document field | Value |
| --- | --- |
| Game title | [Working title] |
| Document owner | [Name / role] |
| Version | [0.1] |
| Last updated | [YYYY-MM-DD] |
| Project phase | [Concept / prototype / production / release / live] |
| Document status | [Draft / in review / approved] |

## Table of contents

Each link opens a separate, editable Markdown section.

| Section | Contents |
| --- | --- |
| [01 — Game overview](01-game-overview.md) | Pitch, player fantasy, audience, platforms, and scope |
| [02 — Design pillars and player experience](02-design-pillars.md) | Design principles, intended emotions, accessibility goals, and success criteria |
| [03 — Core gameplay and controls](03-core-gameplay.md) | Gameplay loops, player actions, rules, controls, and camera |
| [04 — Game systems and mechanics](04-game-systems.md) | Detailed mechanics, states, interactions, AI, and balancing |
| [05 — Progression and economy](05-progression-and-economy.md) | Advancement, rewards, resources, unlocks, and tuning |
| [06 — Narrative, world, and characters](06-narrative-and-world.md) | Setting, story, cast, delivery, choices, and world rules |
| [07 — Levels and content](07-levels-and-content.md) | Content inventory, level briefs, encounters, pacing, and replayability |
| [08 — User experience and interface](08-ux-and-interface.md) | Player flows, screens, HUD, onboarding, and accessibility behavior |
| [09 — Art and animation](09-art-and-animation.md) | Visual direction, assets, animation, readability, and production rules |
| [10 — Audio and music](10-audio-and-music.md) | Sound direction, music, effects, dialogue, and audio behavior |
| [11 — Technical design and platforms](11-technical-design.md) | Architecture, performance, saves, tooling, and platform constraints |
| [12 — Multiplayer and social](12-multiplayer-and-social.md) | Sessions, networking behavior, matchmaking, communication, and moderation |
| [13 — Business model and release](13-business-and-release.md) | Pricing approach, distribution, launch scope, and release readiness |
| [14 — Production plan](14-production-plan.md) | Milestones, ownership, dependencies, scope, and risks |
| [15 — Testing and validation](15-testing-and-validation.md) | Playtests, QA, acceptance criteria, and feedback decisions |
| [16 — Analytics and live operations](16-analytics-and-live-operations.md) | Measurement, events, updates, support, and service operations |
| [17 — Decisions, glossary, and references](17-decisions-and-references.md) | Decision history, terminology, open questions, and supporting links |

## How to use this document

1. Start with the overview, pillars, and core gameplay. Record assumptions explicitly.
2. Fill out the remaining sections to the level needed for the current milestone. Sections such as multiplayer and live operations may be not applicable.
3. Give mechanics and content stable IDs, such as `MEC-001` and `LVL-001`, and use those IDs across sections.
4. Keep each rule in one authoritative section and link to it elsewhere. Put unresolved decisions in Section 17.
5. Review related sections when a decision changes; update owners, dates, and status.

This file links to the section files; ordinary Markdown does not automatically embed their contents. Keep the files together so relative links continue to work.

## Document change log

| Date | Version | Sections changed | Summary | Author |
| --- | --- | --- | --- | --- |
| [YYYY-MM-DD] | [0.1] | [Sections] | [Change and reason] | [Name] |
