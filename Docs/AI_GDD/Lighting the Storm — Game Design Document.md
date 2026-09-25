# Lighting the Storm — Game Design Document

Sep 22, 2026 · @Paul · Updated Sep 25, 2026

*An apprentice lighthouse keeper must repair a failing tower, let two shipwrecked sailors in from the storm, and cross a worsening sea for the one part that can't be fixed on site — before an oncoming passenger ship is lost on the rocks.*

## Concept Overview

You play the newly arrived apprentice to Ted, keeper of a remote, storm-battered lighthouse on Bracken Isle. On your first night on the job, working through the building's failing systems under Ted's direction, the one part that won't come right is the beacon itself — it keeps flickering and cutting out. Then Ted spots a rowboat being driven onto the rocks by the weak light and calls you to the window, where you watch it crash onto Bracken Isle. He sends you to open the lighthouse gate, and the two survivors make their way inside. With one of them, Jeff, you cross a worsening sea to fetch the beacon's replacement burner from an abandoned port — and get back before a passenger ship on the horizon runs onto the same rocks in the dark.

**Genre:** Atmospheric survival-exploration with mechanical puzzle-solving and a tense boat-navigation set piece. Single-player, narrative-driven, about 30 minutes for a full playthrough (about 10 minutes for the first playable prototype).

**Tone:** Slow-burn dread rather than jump scares — isolation, wrongness, and a storm that sets the clock.

**Comparable titles:** *Dredge* (boat-as-threat, folk horror), *Firewatch* (lone caretaker, isolation), *Return of the Obra Dinn* (mood and restraint), *Iron Lung* (claustrophobic dread), *Subnautica* (pressure of the deep).

**Platform:** PC (Steam) first, controller-supported; console port feasible post-launch.

**Viewpoint:** First-person throughout. There are no cutaway or exterior cameras; the crash, the ship, and the ending are all seen from where the player stands.

## Design Pillars

Every system and story beat should be checked against these:

- **The light must return.** Everything leads back to the beacon. It's what you repair, it guides you home across the water, and it decides whether the ship lives. *Test:* does this feature connect to getting the light back, or to what happens if it fails? *Rules out:* side activities, collectables, or systems that don't feed the beacon or the night's stakes.
- **The storm sets the clock.** Pressure comes from the world — the approaching ship's lights, worsening weather, falling visibility, rocks in the dark — never from a timer, a meter, or an enemy. *Test:* can the player feel time running out without any UI? *Rules out:* countdown displays, combat, monsters, and failure that comes from anything other than the environment and time.
- **Your hands, your eyes.** Everything is first-person and physical. You fix things with your hands, you watch the crash through the window, and you see the ship's fate from where you stand. Guidance comes from people — Ted and Jeff — not markers. *Test:* is this happening to the player in the world, or being shown to them? *Rules out:* cutscenes from other cameras, quest arrows, crafting menus, and abstract puzzle screens.
- **Dread you can read.** Sustained unease and ambiguity, never jump scares or a confirmed monster — but the player always knows what to do and why they failed: one steering control, clear hazards, fair and recoverable mistakes. If a moment relies on a sudden loud noise to land, cut it. *Test:* does this add unease without adding confusion? *Rules out:* shock stingers, explaining the supernatural, unreadable hazards, and mistakes that end the run without warning.

**Scope rule: small world, read closely.** One lighthouse, one stretch of sea, one outpost — built for repeated, attentive passes rather than breadth, with no new major locations. Depth of detail beats size of map.

## Core Gameplay Loop

The loop mirrors a single, worsening night on duty, tightened to fit a 30-minute playthrough, with Ted present from the start and two shipwrecked sailors drawn into it partway through:

1. Make mechanical fixes to the lighthouse — Ted puts the apprentice to work, barking which system is broken and roughly where to find its part; exploration and light puzzle-solving follow his directions.
2. Open the lighthouse gate so Jeff and Daniel can enter — with everything else repaired, the beacon is still flickering; Ted spots a rowboat being driven onto the rocks, calls the apprentice to the window to watch it crash onto Bracken Isle, then tells them to open the gate. The two survivors make their own way inside. Ted explains that the burner must be fetched from the abandoned port.
3. Meet Jeff at the engine boat to start retrieving the burner — boarding starts the hidden countdown to the passenger ship's arrival, which Jeff spells out bluntly the moment you climb in.
4. Pilot the boat to the abandoned port — steering past rocks, buoys, and debris in the storm, guided by Jeff's shouted directions.
5. Pick up the burner.
6. Pilot the boat back to the lighthouse — a harder return crossing, with denser hazards and lower visibility as the storm peaks.
7. Get to the lighthouse and fit the burner — the climax, a race against a visible, oncoming light on the horizon.
8. Win or fail — the ship sails calmly into port if the beacon is restored in time; otherwise it runs aground.

This full loop plays once across the main story, in about 30 minutes. See **Difficulty & Progression** below for how Ted's and Jeff's assistance scale.

## Setting & Atmosphere

The game is set at a fictional lighthouse, **Bracken Isle Light**, on **Bracken Isle**, a small, rocky island off an isolated stretch of North Atlantic coastline, drawing on 19th-century lighthouse-keeping practice rather than a specific real location. The storm is both weather and pressure: it drives the pacing of every system, and its approach is always visible and audible before it's mechanically felt.

The lighthouse itself should feel subtly wrong rather than overtly haunted: corridors that don't quite match the tower's exterior silhouette, a logbook whose entries trail off mid-sentence, a fog that seems to hang around the building longer than the wind should allow. The design intent is **folk-horror ambiguity** — never a confirmed monster. This is a permanent design decision, not a placeholder: the wrongness stays open to interpretation for good, so players are still asking questions after the credits roll rather than getting a final answer.

**Environmental horror devices.** This is built concretely through: faulty, flickering lighting fixtures that never quite behave; strange symbols scored or painted into walls and beams; odd posters left up long past their relevance; and small shrines to deities or organisations the player doesn't recognise, tucked into corners of the building. None of it is explained outright — it should read as things the lighthouse, or whoever was last here, left behind.

**Sound:** constant wind and rain, a foghorn motif, creaking metal, and occasional unexplained sounds (a bell buoy, something breaching far off) that are never explained on-screen.

**Light:** warm oil-lamp glow indoors against cold blue-grey storm light outside, with the lighthouse's beam itself as the game's central visual anchor — visible from every exterior location and the thing the player is ultimately fighting to keep alive.

## Narrative & Story Beats

**Opening.** The apprentice arrives at the lighthouse, where Ted is already hard at work. He puts them straight onto routine checks, barking directions to broken parts — the player's first taste of how he communicates.

**Inciting incident.** With every other system repaired, the beacon itself is still flickering and cutting out. Checking it, Ted spots a rowboat being driven onto the rocks by the weak light and calls the apprentice to the window. They watch, in first person, as it crashes onto Bracken Isle.

**The gate.** Ted tells the apprentice to open the lighthouse gate. The two survivors, Jeff and Daniel, make their own way up from the wreck and into the lighthouse — no escort, no rescue mission.

**Departure.** Inside, Ted explains the beacon: the burner can't be repaired on site, it has to be fetched from the abandoned port across the water. Jeff grudgingly agrees to go; Daniel stays behind. The moment the apprentice climbs into the engine boat, Jeff names the real risk out loud — a passenger ship is out there, and the clock is now running.

**Outbound crossing.** Guided by Jeff's shouted directions, the player reaches the port/outpost. Environmental storytelling there raises questions about what happened to the people who were here.

**Return crossing.** Worse conditions, the burner now aboard as fragile cargo, Jeff's calls continuing as the storm peaks.

**Climax.** Fitting the burner and restoring the beacon as the passenger ship's lights visibly close on the rocks.

**Endings:**

- Win — the beacon is lit in time and the ship sails calmly into port; Ted's guarded relief hints there's more behind his gruffness than the job.
- Fail — the deadline runs out and the ship runs aground; the player and Ted have to live with it together. What happens after the fail state (retry or restart) is an open decision (see Decisions to be made).

Ideas beyond this scope, including a hidden coda about the symbols and shrines, are kept in **Dreams for the game**.

## Characters

**The Apprentice (player).** New to the post, thrown into sole charge of the light when the storm hits and Ted needs help. Characterised through action and light interior monologue rather than dialogue trees.

**Ted — The Lighthouse Keeper.** Keeper and guardian of the beacon, late 50s, thirty years in the tower — the machinery and the sea are more familiar to him than people. Burly and weather-beaten, gruff and blunt, with little patience for foolishness; he initially regards the player as just another problem washed in by the sea. His reserve should read as earned, not cruel — underneath it is a tired sense of responsibility and a guarded concern for anyone caught in the lighthouse's failing protection. In play, he's mostly heard rather than seen: barking directions at the apprentice from elsewhere in the building as they work through repairs. (Proposed: Ted is present and speaks live; confirm before recording dialogue — see Decisions to be made.)

**The Seamen.** Two men aboard a rowing boat that crashes onto Bracken Isle after the beacon fails to warn them in time. The player opens the gate for them and they make their own way inside. Jeff then crosses with the player; Daniel stays at the lighthouse.

- **Daniel — The Younger Seaman (30s).** Shaken by the crash and just glad to be alive. He stays at the lighthouse while the apprentice and Jeff make the crossing.
- **Jeff — The Older Seaman (60s).** A lifetime at sea has left him hard, suspicious, and openly unimpressed by the lighthouse or anyone in it; coarse, sweary, and unhappy about helping. His instinct is still to keep people alive when things go bad, and a rare flash of that briefly breaks his hostility and hints he knows something about earlier arrivals. As the player's boat companion, he offers only verbal warnings — no light, just his voice cutting through the storm — and he's the one who spells out, bluntly, exactly how much trouble you're both in the moment you board.

## Lighthouse Repair Mechanics

The lighthouse runs on interdependent systems: the lamp/optic assembly, the clockwork rotation mechanism, the fuel and fog-signal lines, and structural stormproofing (shutters, seals). Each broken system is fixed through a short, diegetic, first-person puzzle — rewire a junction box, swap a gear, patch a leak — using a small, fixed toolkit rather than a crafting menu. The prototype uses one repair; the full game uses the full set.

**Ted's guidance.** As the player works through each broken system, Ted barks directions from wherever he is in the building — naming the part and roughly where to find it. This is the game's first assist mechanism, and its verbosity scales with a preset difficulty level: specific on lower difficulties, sparser or silent on higher ones.

The player's journal doubles as an objective tracker: a running, handwritten-feeling checklist of what's broken, updated as systems are diagnosed. Fixing a system often opens access to a new area (repairing the winch opens the hatch to the boat dock, for example), giving the single building light Metroidvania-style gating without needing a large map.

Once every other system is fixed, the beacon itself is left as the outlier: it still flickers and cuts out no matter what's done to it. That unresolved flicker is what draws Ted's attention outward — spotting the rowboat being driven onto the rocks by the weak light — turning a mechanical dead end directly into the game's inciting incident, rather than a quest marker telling the player where to go next.

## Sea Crossing & Boat Navigation

The player pilots a small engine-driven boat at one fixed speed: the motor supplies steady propulsion on its own, so the player's whole focus is steering. There's no oar mechanic and no throttle to juggle; one control, steering, past rocks, reefs, buoys, and floating debris along a route that narrows and darkens as the storm worsens. The sea surface moves for atmosphere but does not push the boat.

**Stretch goal: wave hazards.** If the schedule allows, waves that push and roll the boat — reacting to wind direction and storm intensity, skill-expressive in the vein of *Dredge*'s boat handling — are layered on top. The crossings must work fully without them; they are the first thing cut if the schedule slips.

**Companion assist.** Jeff calls out verbal warnings about obstacles and the safe line through them. Like Ted's guidance, how much he helps fluctuates with a preset difficulty level.

**Risk states:** a collision with a rock or debris (or a broadside wave, if built) takes on water, slows the boat, or causes a brief capsize and recovery, all costing time; on the return leg, mishandling can knock the fragile burner loose, costing time to recover it. Proposed: the burner is never permanently lost, and a bailing mini-mechanic is added only if playtests show it helps (see Decisions to be made).

**Navigation aids:** a compass, the lighthouse beam itself as a guiding light when facing home, and silhouettes of buoys and rocks as obstacles to read in low visibility.

Storm intensity should climb across the crossing and peak on the return leg, so the return trip is mechanically and emotionally the harder of the two — the same water, now working against the player instead of merely being crossed.

## Tension & Escalation Systems

The central pressure mechanic is a countdown the player never sees as a number, and it doesn't start until the player boards the boat for the outbound crossing — flagged in that moment by Jeff. Everything before that (the repairs, the crash, the gate) plays at its own pace, free of pressure. Once underway, it's the approaching passenger ship's lights on the horizon, and storm intensity communicated through environmental cues — wind volume, rain density, sea swell, visibility — rather than a meter or timer UI. It is the only timer in the game: the same deadline keeps running through both crossings, the pickup, and the final repair.

Most failures should be soft: a collision costs time rather than ending the run, keeping the player in flow and in the fiction rather than bouncing them to a menu. The exception is the deadline itself, which is a true fail state — missing it means the passenger ship runs aground — so the ending means something. There is no combat anywhere in the design; every threat is a matter of timing and navigation, never confrontation.

**Escalation curve:** Act 1, the lighthouse (calm, tutorialised, interrupted by the rowboat crash) → Act 2, the outbound crossing (moderate) → Act 3, the return crossing (severe — the hardest skill test in the game) → Climax, a multi-step repair under duress, still against the same running deadline.

## World & Location Design

Three locations, kept small and largely linear to fit a lean production:

1. **The Lighthouse.** Vertical and multi-floor — generator/basement, living quarters, spiral stair, lamp room — designed for the repeated pass-throughs the player will make as they diagnose and repair systems. Includes the window that frames the crash and the gate the survivors come through.
2. **The Sea.** An open-water traversal space bounded by readable landmarks — rocks, buoys, the wrecked rowboat's remains — plus the escalating passenger ship on the horizon that anchors the endgame.
3. **The Port/Outpost.** A small, self-contained abandoned fishing village or supply depot onshore, holding the burner and the game's strongest environmental storytelling about what happened there.

Keeping the world to one building, one short stretch of coastline, and one small outpost is a deliberate scope decision — it lets the whole game be built and polished by a solo developer, rather than needing an open world or a larger team.

## Art & Audio Direction

**Visual.** Painterly, low-poly or hand-painted-realist style with a restrained palette — oil-lamp amber against storm blue-grey — and heavy use of fog and rain particle effects. The beacon's sweeping beam and its dynamic lighting should be the game's recurring hero visual, the one thing on screen the player is always aware of. Reference points: *Return of the Obra Dinn*'s restraint (not its 1-bit style), *Dredge*'s silhouette-driven horror, *Firewatch*'s warm/cold contrast.

**Audio.** Diegetic-first sound design — wind, rain, groaning timber, a distant foghorn, radio static — with a sparse ambient score that swells only at story beats. No jump-scare stingers; the goal is sustained dread, not shocks. The apprentice has little or no voiced dialogue (perhaps wordless breathing or vocalisation under stress). Ted speaks live (Proposed); earlier keepers are heard only through recordings and journal text.

## Difficulty & Progression

The main story is a single linear playthrough of about 30 minutes. Difficulty here is primarily a pacing and tension curve rather than a skill gate, keeping the game accessible to narrative-adventure players. A single preset difficulty level governs both assist mechanisms throughout — how specific Ted's barked directions are, and how much help Jeff's warnings give on the water — as well as how much it can soften hazard intensity (and wave intensity, if built) for players who want the story without the harder boat sections, without altering narrative outcomes.

Replayability comes from the win and fail endings and hidden journal fragments that recontextualise the keeper's fate. Larger replay ideas — a companion choice with Daniel as an alternative guide, a hidden coda, and the Full Gale New Game+ mode — are kept in **Dreams for the game**.

## Scope & Platform

This document assumes a solo-developer project: a tight, roughly 30-minute narrative experience across three locations, targeting PC via Steam, with a 10-minute prototype built first over about 6 weeks. Engine options are compared in **Engine Comparison**; Godot 4 is the current proposal.

The boat-navigation system — steering feel against readable hazards — is the single biggest technical risk and time cost in the design, and the one system a solo developer can least afford to get wrong. Reducing it to a single steering control at one fixed speed, and making wave physics a stretch goal, cuts the surface area of that risk, but it should still be prototyped first, before any other system, since the whole game hinges on whether it's fun to steer.

## AI-Assisted Production: Agent Roles

Since this is a solo-developer project, AI agents stand in for the departments a small studio would otherwise staff. Each is still scoped to a single task rather than general-purpose game-building, so the solo developer always owns final judgment on tone, feel, and fit. See **AI Agent Strategy** for task briefs and handoffs.

- **Dialogue Agent.** Drafts and revises all spoken/barked lines and journal text for Ted, Jeff, Daniel, and the apprentice's log, matched to each character's established voice.
- **Lighting Agent.** Builds and tunes the beacon's sweep, the oil-lamp-versus-storm-light contrast, and the dynamic weather lighting rigs in-engine.
- **Sound Agent.** Sources or generates ambient and diegetic audio — wind, rain, the foghorn motif, creaking metal, radio static — and layers it to the escalation curve.
- **Asset Agent.** Produces first-pass 3D props and set dressing — the lighthouse's broken systems, the outpost's abandoned depot, the shrines and symbols — from the Setting and World specs, for the solo developer to finish.
- **Physics Agent.** Implements and iterates the boat-steering and hazard-collision code — the design's single biggest technical risk — under the solo developer's tuning direction, adding wave reaction only as a later stretch task.
- **Level Layout Agent.** Blocks out the three locations (Lighthouse, Sea, Port/Outpost) to the World & Location Design spec, for the solo developer to dress and refine.
- **QA Agent.** Plays every build against the core loop, flagging breaks, pacing problems, and difficulty-curve issues for the solo developer to prioritise.

Each agent owns exactly one department and hands its output to the solo developer for review — the point is to speed up first passes, not to replace the judgment calls (tone, feel, “does this land”) the Design Pillars above are meant to protect.

## Open Questions & Risks

Open decisions are tracked in **Decisions to be made**.

- **Resolved:** how overtly supernatural should the game get? The ambiguity is permanent by design (see Setting & Atmosphere) — built entirely through environmental storytelling (faulty lighting, strange symbols, shrines to unnamed deities or organisations), with no confirmed monster and no final answer, by intent.
- **Resolved:** the deadline is a true fail state — the passenger ship can actually run aground. The hidden countdown to its arrival only starts once the player boards the boat for the outbound crossing, at which point Jeff names the risk out loud (see Tension & Escalation Systems and Narrative & Story Beats).
- **Resolved:** no combat anywhere in the game. Every threat is environmental — timing, navigation, and pressure, never confrontation.
- **Resolved:** this is a solo-developer project. Target playtime is about 30 minutes for the full game and about 10 minutes for the prototype; budget is assumed to be primarily the developer's own time plus modest asset-store and tooling spend, not a funded team budget.
- **Resolved:** there is no rescue mission. The rowboat crashes onto Bracken Isle, the player opens the gate, and Jeff and Daniel make their own way into the lighthouse. Jeff is the only crossing companion.
- **Resolved:** wave hazards are a stretch goal; the crossings are built around steering past rocks, buoys, and debris.
- Boat steering feel is still the top technical risk for a solo developer's time budget, even simplified to a single control — prototype this first, before greenlighting any other system (see Scope & Platform).

  **Resolved:** the rowboat crash serves two purposes — it introduces Jeff and Daniel, and it proves the beacon's failure has real, immediate stakes. The ship at the climax is a separate, much larger passenger ship, driven onto the rocks by the same storm — a bigger version of the same danger, not the same boat.
