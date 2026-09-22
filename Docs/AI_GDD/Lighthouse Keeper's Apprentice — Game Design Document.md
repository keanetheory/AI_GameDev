# Lighthouse Keeper's Apprentice — Game Design Document

Sep 22, 2026 · @Paul

*An apprentice lighthouse keeper must repair a failing tower, rescue two shipwrecked survivors, and cross a worsening sea for the one part that can't be fixed on site — before an oncoming passenger ship is lost on the rocks.*

## Concept Overview

You play the newly arrived apprentice to Ted, keeper of a remote, storm-battered lighthouse. On your first night on the job, working through the building's failing systems under Ted's direction, the one part that won't come right is the beacon itself — it keeps flickering and cutting out. Then Ted spots a rowboat about to be driven onto the rocks by the weak light and shouts the alarm. You find the wreck, rescue its two survivors, and bring one of them along as you cross a worsening sea to fetch the beacon's replacement burner from an abandoned port — and get back before a passenger ship on the horizon runs onto the same rocks in the dark.

**Genre:** Atmospheric survival-exploration with mechanical puzzle-solving and a tense boat-navigation set piece. Single-player, narrative-driven, up to an hour for a full playthrough.

**Tone:** Slow-burn dread rather than jump scares — isolation, wrongness, and the sea itself as the antagonist.

**Comparable titles:** *Dredge* (boat-as-threat, folk horror), *Firewatch* (lone caretaker, isolation), *Return of the Obra Dinn* (mood and restraint), *Iron Lung* (claustrophobic dread), *Subnautica* (pressure of the deep).

**Platform:** PC (Steam) first, controller-supported; console port feasible post-launch.

## Design Pillars

Every system and story beat should be checked against these:

- **Dread, not shock.** Tension builds from sustained unease and isolation, never jump scares. If a moment relies on a sudden loud noise to land, cut it.
- **The sea is the antagonist.** There is no monster to fight, and no combat, ever. Every hazard — waves, wind, the ticking approach of the passenger ship — comes from the environment, not an enemy.
- **Legible under pressure.** Controls and feedback stay simple and readable even as the storm escalates, so panic is something the player feels, not something the interface causes.
- **Small world, read closely.** One lighthouse, one crossing, one outpost — built for repeated, attentive passes rather than breadth. Depth of detail beats size of map.

## Core Gameplay Loop

The loop mirrors a single, worsening night on duty, tightened to fit a sub-hour playthrough, with Ted present from the start and two rescued survivors drawn into it partway through:

1. Start at the lighthouse — Ted puts the apprentice to work on routine checks, barking which system is broken and roughly where to find its part.
2. Find and fix the lighthouse's failing systems one by one — exploration and light puzzle-solving, guided by Ted's directions.
3. Inciting incident — with everything else repaired, the beacon itself is left flickering and cutting out; Ted spots a rowboat about to be driven onto the rocks by the weak light and shouts the alarm.
4. Find the wrecked rowboat and its two survivors, Jeff and Daniel, and escort them back to the lighthouse through the storm.
5. Talk to Ted about retrieving a replacement burner — the one part of the beacon that can't be fixed on site — and choose Jeff or Daniel to accompany you across.
6. Cross the sea to the shore or outpost where the replacement burner is located — boarding the boat starts the hidden countdown to the passenger ship's arrival, immediately called out by your companion — guided by Jeff's verbal warnings, or Daniel's flashlight, which sometimes points the wrong way.
7. Navigate reactive wave patterns by steering the engine-driven boat — the game's signature skill test, with companion assistance fluctuating by difficulty.
8. Retrieve the burner and return to the lighthouse under escalating pressure — the same companion assist, now against a harder return crossing.
9. Fit the burner and restore the beacon before the passenger ship reaches the rocks — the climax, a race against a visible, oncoming light on the horizon.

This full loop plays once across the main story, in under an hour. See **Difficulty & Progression** below for how Ted's and the companion's assistance scale, and how steps 2–8 remix into repeatable "shifts" for replay value.

## Setting & Atmosphere

The game is set at a fictional lighthouse — working title **Wren's Head Light** — on an isolated stretch of North Atlantic coastline, drawing on 19th-century lighthouse-keeping practice rather than a specific real location. The storm is both weather and pressure: it drives the pacing of every system, and its approach is always visible and audible before it's mechanically felt.

The lighthouse itself should feel subtly wrong rather than overtly haunted: corridors that don't quite match the tower's exterior silhouette, a logbook whose entries trail off mid-sentence, a fog that seems to hang around the building longer than the wind should allow. The design intent is **folk-horror ambiguity** — never a confirmed monster. This is a permanent design decision, not a placeholder: the wrongness stays open to interpretation for good, so players are still asking questions after the credits roll rather than getting a final answer.

**Environmental horror devices.** This is built concretely through: faulty, flickering lighting fixtures that never quite behave; strange symbols scored or painted into walls and beams; odd posters left up long past their relevance; and small shrines to deities or organisations the player doesn't recognise, tucked into corners of the building. None of it is explained outright — it should read as things the lighthouse, or whoever was last here, left behind.

**Sound:** constant wind and rain, a foghorn motif, creaking metal, and occasional unexplained sounds (a bell buoy, something breaching far off) that are never explained on-screen.

**Light:** warm oil-lamp glow indoors against cold blue-grey storm light outside, with the lighthouse's beam itself as the game's central visual anchor — visible from every exterior location and the thing the player is ultimately fighting to keep alive.

## Narrative & Story Beats

**Opening.** The apprentice arrives at the lighthouse, where Ted is already hard at work. He puts them straight onto routine checks, barking directions to broken parts — the player's first taste of how he communicates.

**Inciting incident.** With every other system repaired, the beacon itself is still flickering and cutting out. Checking it, Ted spots a rowboat about to be driven onto the rocks by the weak light, and screams the alarm.

**Rescue.** The player finds the wrecked rowboat and its two survivors, Jeff and Daniel, and escorts them back to the lighthouse through the storm.

**Choice & departure.** Back at the lighthouse, the player talks to Ted about the beacon: the burner can't be repaired on site, it has to be fetched from the abandoned port across the water. The player chooses Jeff or Daniel to accompany them. The moment they climb into the boat, the chosen companion names the real risk out loud — a passenger ship is out there, and the clock is now running.

**Outbound crossing.** With the chosen companion's guidance — Jeff's calls, or Daniel's sometimes-mistaken flashlight — the player reaches the port/outpost. Environmental storytelling there raises questions about what happened to the people who were here.

**Return crossing.** Worse conditions, the burner now aboard as fragile cargo, the same companion assist continuing as the storm peaks.

**Climax.** Fitting the burner and restoring the beacon as the passenger ship's lights visibly close on the rocks.

**Endings (lightweight branching):**

- Beacon lit in time — the ship passes safely; Ted's guarded relief hints there's more behind his gruffness than the job.
- Beacon lit late — the ship runs aground; the player and Ted have to live with it together.
- A hidden coda, unlocked by piecing together the lighthouse's journal fragments and its shrines and symbols, that reveals what they actually mean — and what happened to whoever was here before Ted.

## Characters

**The Apprentice (player).** New to the post, thrown into sole charge of the light when the storm hits and Ted needs help. Characterised through action and light interior monologue rather than dialogue trees.

**Ted — The Lighthouse Keeper.** Keeper and guardian of the beacon, late 50s, thirty years in the tower — the machinery and the sea are more familiar to him than people. Burly and weather-beaten, gruff and blunt, with little patience for foolishness; he initially regards the player as just another problem washed in by the sea. His reserve should read as earned, not cruel — underneath it is a tired sense of responsibility and a guarded concern for anyone caught in the lighthouse's failing protection. In play, he's mostly heard rather than seen: barking directions at the apprentice from elsewhere in the building as they work through repairs.

**The Seamen.** Two men aboard a rowing boat that wrecks on the rocks near the lighthouse after the beacon fails to warn them in time. The player rescues both and escorts them back to the lighthouse, then chooses one to accompany them on the crossing to come.

- **Daniel — The Younger Seaman (30s).** The boat's steersman; blames the crash on the lighthouse's weak, flickering beacon — a real problem, though not the whole story, since Daniel was also sailing recklessly in rough water. Defensive when blamed, frightened and angry, he leans on the beacon's failure because admitting his own recklessness would make him responsible. A useful but unreliable witness: right about a real fault, wrong about it being the whole cause. Chosen as a boat companion, he lights the way with a flashlight — faster to read than a shout, but sometimes pointed wrong — and he's the one who names the passenger ship the moment you both board.
- **Jeff — The Older Seaman (60s).** A lifetime at sea has left him hard, suspicious, and openly unimpressed by the lighthouse or anyone in it; coarse, sweary, and unhappy about helping. His instinct is still to keep people alive when things go bad. He's visibly relieved the player isn't Daniel, whom he considers reckless — a flash of relief that briefly breaks his hostility and hints he knows something about earlier arrivals, or has been dreading being left alone with the situation. Chosen as a boat companion, he offers only verbal warnings — no light, just his voice cutting through the storm — and he's the one who spells out, bluntly, exactly how much trouble you're both in the moment you board.

## Lighthouse Repair Mechanics

The lighthouse runs on interdependent systems: the lamp/optic assembly, the clockwork rotation mechanism, the fuel and fog-signal lines, and structural stormproofing (shutters, seals). Each broken system is fixed through a short, diegetic, first-person puzzle — rewire a junction box, swap a gear, patch a leak — using a small, fixed toolkit rather than a crafting menu.

**Ted's guidance.** As the player works through each broken system, Ted barks directions from wherever he is in the building — naming the part and roughly where to find it. This is the game's first assist mechanism, and its verbosity scales with a preset difficulty level: specific on lower difficulties, sparser or silent on higher ones.

The player's journal doubles as an objective tracker: a running, handwritten-feeling checklist of what's broken, updated as systems are diagnosed. Fixing a system often opens access to a new area (repairing the winch opens the hatch to the boat dock, for example), giving the single building light Metroidvania-style gating without needing a large map.

Once every other system is fixed, the beacon itself is left as the outlier: it still flickers and cuts out no matter what's done to it. That unresolved flicker is what draws Ted's attention outward — spotting a rowboat about to be driven onto the rocks by the weak light — turning a mechanical dead end directly into the game's inciting incident, rather than a quest marker telling the player where to go next.

## Sea Crossing & Boat Navigation

The player pilots a small engine-driven boat: the motor supplies steady propulsion on its own, so the player's whole focus is steering — reading incoming waves and turning into or away from them at the right moment. There's no oar mechanic and no separate throttle to juggle; one control, steering, against wave patterns that react to wind direction and storm intensity, skill-expressive in the vein of *Dredge*'s boat handling.

**Companion assist.** The player crosses with either Jeff or Daniel, chosen back at the lighthouse after the rescue. Jeff calls out verbal warnings about waves and obstacles; Daniel points a flashlight toward the way to go, which is faster to read but sometimes mistaken. Like Ted's guidance, how much either companion helps fluctuates with a preset difficulty level.

**Risk states:** capsizing if caught broadside by a large wave; the boat taking on water, requiring a bailing mini-mechanic; losing the cargo overboard if the boat is mishandled on the return leg, where the fragile burner is aboard.

**Navigation aids:** a compass, the lighthouse beam itself as a guiding light when facing home, and silhouettes of buoys and rocks as obstacles to read in low visibility.

Storm intensity should climb across the crossing and peak on the return leg, so the return trip is mechanically and emotionally the harder of the two — the same water, now working against the player instead of merely being crossed.

## Tension & Escalation Systems

The central pressure mechanic is a countdown the player never sees as a number, and it doesn't start until the player boards the boat for the outbound crossing — flagged in that moment by whichever companion came along. Everything before that (the repairs, the rescue) plays at its own pace, free of pressure. Once underway, it's the approaching passenger ship's lights on the horizon, and storm intensity communicated through environmental cues — wind volume, rain density, wave height — rather than a meter or timer UI.

Most failures should be soft: a capsize costs time and risks dropping some cargo rather than ending the run, keeping the player in flow and in the fiction rather than bouncing them to a menu. The exception is the climax, which is a confirmed true fail state — the passenger ship can actually wreck — so the ending means something. There is no combat anywhere in the design; every threat is a matter of timing and navigation, never confrontation.

**Escalation curve:** Act 1, the lighthouse (calm, tutorialised, interrupted by the rowboat crash) → Act 2, the outbound crossing (moderate) → Act 3, the return crossing (severe — the hardest skill test in the game) → Climax, a multi-step timed repair performed under duress.

## World & Location Design

Three locations, kept small and largely linear to fit a lean production:

1. **The Lighthouse.** Vertical and multi-floor — generator/basement, living quarters, spiral stair, lamp room — designed for the repeated pass-throughs the player will make as they diagnose and repair systems.
2. **The Sea.** An open-water traversal space bounded by readable landmarks — rocks, buoys, the wrecked rowboat's remains — plus the escalating passenger ship on the horizon that anchors the endgame.
3. **The Port/Outpost.** A small, self-contained abandoned fishing village or supply depot onshore, holding the burner and the game's strongest environmental storytelling about what happened there.

Keeping the world to one building, one short stretch of coastline, and one small outpost is a deliberate scope decision — it lets the whole game be built and polished by a solo developer, rather than needing an open world or a larger team.

## Art & Audio Direction

**Visual.** Painterly, low-poly or hand-painted-realist style with a restrained palette — oil-lamp amber against storm blue-grey — and heavy use of fog and rain particle effects. The beacon's sweeping beam and its dynamic lighting should be the game's recurring hero visual, the one thing on screen the player is always aware of. Reference points: *Return of the Obra Dinn*'s restraint (not its 1-bit style), *Dredge*'s silhouette-driven horror, *Firewatch*'s warm/cold contrast.

**Audio.** Diegetic-first sound design — wind, rain, groaning timber, a distant foghorn, radio static — with a sparse ambient score that swells only at story beats. No jump-scare stingers; the goal is sustained dread, not shocks. The apprentice has little or no voiced dialogue (perhaps wordless breathing or vocalisation under stress); the keeper is heard only through recordings and journal text.

## Difficulty & Progression

The main story is a single linear playthrough (45 minutes to an hour). Difficulty here is primarily a pacing and tension curve rather than a skill gate, keeping the game accessible to narrative-adventure players. A single preset difficulty level governs both assist mechanisms throughout — how specific Ted's barked directions are, and how much help Jeff's warnings or Daniel's flashlight give on the water — as well as how much it can soften wave intensity for players who want the story without the harder boat sections, without altering narrative outcomes.

Replayability comes from alternate endings, hidden journal fragments that recontextualise the keeper's fate, and an optional **Full Gale** New Game+ modifier that remixes the find-parts and boat-crossing steps (loop steps 2–6) into a tougher, repeatable shift for players who want the navigation to be a real skill test.

## Scope & Platform

This document assumes a solo-developer project: a tight, roughly one-hour narrative experience across three locations, targeting PC via Steam. Unity or Godot both suit this scope well — both are cheap to prototype dynamic lighting and weather in, with mature water/weather assets available.

The boat-navigation system — reactive wave physics plus steering feel — is the single biggest technical risk and time cost in the design, and the one system a solo developer can least afford to get wrong. Reducing it to a single steering control (see Sea Crossing & Boat Navigation) cuts the surface area of that risk, but it should still be prototyped first, before any other system, since the whole game hinges on whether it's fun to steer.

## AI-Assisted Production: Agent Roles

Since this is a solo-developer project, AI agents stand in for the departments a small studio would otherwise staff. Each is still scoped to a single task rather than general-purpose game-building, so the solo developer always owns final judgment on tone, feel, and fit.

- **Dialogue Agent.** Drafts and revises all spoken/barked lines and journal text for Ted, Jeff, Daniel, and the apprentice's log, matched to each character's established voice.
- **Lighting Agent.** Builds and tunes the beacon's sweep, the oil-lamp-versus-storm-light contrast, and the dynamic weather lighting rigs in-engine.
- **Sound Agent.** Sources or generates ambient and diegetic audio — wind, rain, the foghorn motif, creaking metal, radio static — and layers it to the escalation curve.
- **Asset Agent.** Produces first-pass 3D props and set dressing — the lighthouse's broken systems, the outpost's abandoned depot, the shrines and symbols — from the Setting and World specs, for the solo developer to finish.
- **Physics Agent.** Implements and iterates the wave-reaction and boat-steering code — the design's single biggest technical risk — under the solo developer's tuning direction.
- **Level Layout Agent.** Blocks out the three locations (Lighthouse, Sea, Port/Outpost) to the World & Location Design spec, for the solo developer to dress and refine.
- **QA Agent.** Plays every build against the core loop, flagging breaks, pacing problems, and difficulty-curve issues for the solo developer to prioritise.

Each agent owns exactly one department and hands its output to the solo developer for review — the point is to speed up first passes, not to replace the judgment calls (tone, feel, “does this land”) the Design Pillars above are meant to protect.

## Open Questions & Risks

- **Resolved:** how overtly supernatural should the game get? The ambiguity is permanent by design (see Setting & Atmosphere) — built entirely through environmental storytelling (faulty lighting, strange symbols, shrines to unnamed deities or organisations), with no confirmed monster and no final answer, by intent.
- **Resolved:** the climax is a true fail state — the passenger ship can actually wreck. The hidden countdown to its arrival only starts once the player boards the boat for the outbound crossing, at which point their chosen companion names the risk out loud (see Tension & Escalation Systems and Narrative & Story Beats).
- **Resolved:** no combat anywhere in the game. Every threat is environmental — timing, navigation, and pressure, never confrontation.
- **Resolved:** this is a solo-developer project. Target playtime is confirmed at under an hour (see Concept Overview and Difficulty & Progression); budget is assumed to be primarily the developer's own time plus modest asset-store and tooling spend, not a funded team budget.
- The boat's wave physics and steering feel are still the top technical risk for a solo developer's time budget, even simplified to a single control — prototype this first, before greenlighting any other system (see Scope & Platform).

  **Resolved:** the rowboat crash serves two purposes — it introduces Jeff and Daniel and the boat-companion mechanic they bring to the crossing, and it proves the beacon's failure has real, immediate stakes. The ship at the climax is a separate, much larger passenger ship, driven onto the rocks by the same storm — a bigger version of the same danger, not the same boat.
