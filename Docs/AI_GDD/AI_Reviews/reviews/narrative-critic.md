# Narrative Critic — Round 1

Document reviewed: `gdd.txt` ("Lighting the Storm — Compiled GDD", compiled 29 September 2026).

## Finding 1 — Ted is the narrative spine, but his presence is still an open decision, and he disappears after Step 2
**Severity: BLOCKING**

**Problem.** The whole opening act depends on Ted. He gives "live guidance" during repairs (Step 1), tells the player to look out of the window, tells them to open the gate, and explains the burner errand (Step 2). Pillar 3 says "guidance comes from Ted and Jeff, not markers". Yet the AI Agent Strategy, Recommended sequence item 1, lists "Ted's presence" among the creator's unsettled open decisions. If Ted is cut or turned into a voice on a radio, the opening loses its guide, and Pillar 3's answer to "how does the player know what to do without markers" goes with it.

Even with Ted in, the story drops him. After Step 2 he is never mentioned again: not at the return (Step 6), not at the final repair (Step 7), not at the outcome (Step 8). The Dialogue agent's deliverable is "Ted/Jeff/Daniel lines", but the sequence gives Ted nothing to say in the second half. It also never explains why an "experienced keeper" sends a new apprentice to steer through a lethal storm instead of going himself. His "guarded sense of care" is the one emotional note the cast list gives him, and that choice is exactly where it should show. The document doesn't address it.

**Passages.** Story and gameplay sequence Steps 1-2 and 6-8; Pillar 3; Cast ("Ted: gruff, experienced keeper… guarded sense of care"); AI Agent Strategy, Recommended sequence item 1 ("Ted's presence").

## Finding 2 — Jeff's motivation and knowledge are unexplained, which undercuts the companion relationship the crossings rely on
**Severity: MAJOR**

**Problem.** Jeff is the player's only company for the whole deadline half of the game. He is also the source of every navigation cue ("reliable verbal navigation cues despite his reluctance to help"). The document never says:
- why a man who has just been shipwrecked would go straight back out into the same storm;
- what his reluctance is about, or whether it changes over the two crossings;
- how a stranger who has just washed up knows the way to the island's abandoned outpost, and its hazards, well enough to call a safe route that the apprentice or Ted could not.

The rowboat itself is unexplained too. Why were two sailors in an open rowboat in this storm? Are they connected to the passenger ship? The document gives no reason. So the crash, the second-biggest event in the game, reads as a device for delivering a navigator rather than as story. "Reluctance" is written as a character trait with no cause behind it and no change over the game. The Dialogue agent is asked to write Jeff's voice from "Character voices", but none are defined beyond one adjective pair.

**Passages.** Pitch ("A rowboat carrying two sailors crashes onto Bracken Isle"); Cast ("Jeff: older, coarse seaman… despite his reluctance to help"); Steps 2-6; Technical Strategy, "Jeff's calls read from the same safe-route signal".

## Finding 3 — The folk-horror layer has no link to the plot, so "dread you can read" has nothing to read
**Severity: MAJOR**

**Problem.** The pitch promises "sustained dread", and Pillar 4 is "Dread you can read". But every source of dread named in the document is scenery: "log fragments, shrines, symbols, and subtly strange architecture". None of it touches the main story. The document never says why the beacon is failing, why the outpost is abandoned, or why a spare burner sits there. Those are the three places where suggested wrongness could meet the player's actual goal.

Pillar 1's own test ("does this connect to getting the light back?") would reject the folk-horror detail as written. The prototype also removes it entirely ("full outpost exploration, optional discoveries" are out of scope). So the vertical slice cannot test whether the game's main tonal promise works. The only full-game check is that the build "preserves unexplained environmental wrongness". That protects ambiguity but never requires it to mean anything.

The Dialogue agent's input includes an "ambiguity constraint", but no private canon is given for the ambiguity to hide. Without one, individual pieces will contradict each other instead of adding up to one unsettling story.

**Passages.** Exec Summary ("Folk-horror details invite interpretation"; atmosphere paragraph); Pillars 1 and 4; Out of first-prototype scope; Outcome checks, Full game; AI Agent Strategy, Dialogue row ("ambiguity constraint").

## Finding 4 — The "consequential ending" has an unnamed victim, an undecided aftermath, and no payoff for the cast
**Severity: MAJOR**

**Problem.** The pitch promises "a consequential ending". The design gives a binary result based only on time: "the ship sails calmly into port" or "the ship runs aground". Three things weaken it:
1. **Who is at risk is never established.** No character, cargo, or relationship links the player or the cast to the passenger ship. It is only lights on the horizon. The stakes rest on abstract care for strangers who are never introduced.
2. **What happens after failure is undecided.** "What follows the fail state (checkpoint retry or restart) is still to be decided." This is a narrative choice, not a technical one. If a failure is followed by an instant checkpoint retry, it plays as a game-over screen, not a consequence, and the promise changes depending on which option is picked.
3. **No resolution for anyone the player met.** Ted, Jeff and Daniel get no reaction to either outcome. Daniel "stays at the lighthouse" and has no further role. The two people who survived a wreck themselves never respond to watching, or preventing, another one. That is the obvious emotional echo, and the document leaves it unused.

A smaller tone issue: "sails calmly into port" sits oddly at the peak of a storm that has been "worsening" all game, and the document never mentions a port.

**Passages.** Exec Summary ("a consequential ending"); Step 8; Cast (Daniel); Technical Strategy deadline paragraph ("What follows the fail state… is still to be decided").

## Finding 5 — The apprentice's one moral beat is scripted by someone else
**Severity: MINOR**

**Problem.** The pitch presents the gate as the apprentice's own act: "the apprentice opens the lighthouse gate to let them in". In the sequence, Ted "tells the player to open the lighthouse gate", it is "a single interaction", and Jeff and Daniel "walk into the lighthouse on their own… with no escort". The player never decides anything or meets the survivors. They follow an instruction. The apprentice is otherwise "characterised by actions and a handwritten objective journal", and that journal only "reflects state". So the apprentice has almost no inner life, and the one scene that could show character (letting strangers in during a storm) is flattened into a door switch.

This fits the minimal-UI goal, but it means the player first meets Jeff at the engine boat, not at the rescue. That weakens both Jeff's arc (Finding 2) and the ending (Finding 4). A small change would help: the apprentice is the one who first sees the wreck, or the journal records what they think and not only their objectives.

**Passages.** Pitch; Step 2; Technical Strategy crash-and-gate paragraph; Cast ("Apprentice: mostly characterised by actions and a handwritten objective journal"); Core state contract ("The journal reflects state, but never determines it").

## Round 2 — Cross-examination

### Conflicts

**Business Analyst, Finding 5 (Daniel and the crash are "mostly decorative content that fails the document's own feature test").** I partly agree and partly disagree. On Daniel, BA is right about the document as written. "Stays at the lighthouse" gives him no job, and my own Finding 4.3 shows he gets no payoff either. Where I disagree is the claim that the crash's "only load-bearing job is delivering Jeff." The crash is the only moment in the game where the player sees a shipwreck happen. The fail ending is a shipwreck, so the crash is the game's one chance to show the player, before the deadline starts, what failure looks like. If it is cut or reduced to "a navigator appears", the passenger ship's fate at Step 8 loses its only point of reference, and the stakes problem that Player Psychologist F4 and I both raise gets worse. My position: keep the crash, and make Daniel earn his place or merge him away. For example, Daniel is hurt, which is why Jeff comes (this also gives Jeff the motive I asked for in F2), and Daniel is at the lamp room for the outcome. If Daniel can't be given that role, I accept deferring him. The cost argument and the story argument agree about Daniel, but they do not agree about the crash.

**Systems Designer, Finding 2 (weather that escalates with elapsed time is a death spiral; escalate "by phase and route position only").** The death-spiral point is fair, but the proposed fix breaks a story promise. Pillar 2 is "The storm sets the clock." The storm getting worse as the ship gets closer is how the game tells time without UI. If weather is tied only to route position, a player who struggled and a player who didn't see the same sky at the same rock. The world then stops reporting how late it is, and Player Psychologist F1's legibility problem (why did I fail?) gets worse, not better. My side: split the channel. Tie the *readable* storm (sound, lightning frequency, wind, the ship's lights) to elapsed time so it carries the story of lateness, and tie *hazard density* to phase and position so it carries fairness. That keeps the pillar and removes the loop.

**Adversarial QA, Finding 5 (keep the pre-boarding ship "out of sight or give it a scripted holding pattern").** Hiding the ship before boarding conflicts with Player Psychologist F4 and my F4.1. Nobody can care about a ship they have never seen. Showing a frozen ship breaks the fiction, as QA says. The narrative fix removes both problems. The ship should first appear *at the end of the pre-boarding act*, as the reason Ted gives the errand: Ted sees the lights, and that is what sends the apprentice out. Its first appearance and the start of the deadline then become one story beat, so the "frozen" window never exists.

### Connections

- **Player Psychologist F2 + my F3: the folk-horror is placed exactly where the clock punishes reading it.** I flagged that the dread content has no plot link. Player Psychologist shows it also sits in the outpost, after boarding, on a running hidden clock. Taken together, the game's tonal promise and its pressure system work against each other by design. The player who does what Pillar 4 asks ("read" the dread) is the player who gets the bad ending. That is a theme failure, not only a UX one: the game ends up teaching that the strangeness doesn't matter. The fix is the private canon I asked for. If the wrongness is tied to *why the beacon failed*, the core of it can live in the lighthouse before boarding (untimed), and the outpost only needs to confirm it in passing.
- **Adversarial QA F1 + my F4: the payoff scene has no defined presentation.** I argued that the ending's stakes and aftermath are thin. QA shows that in many expiry cases the ending *cannot be shown at all* under the no-cutaway rule. So the "consequential ending" is undefined both in meaning and in presentation. An audio-only fail (QA's option) is a strong narrative choice if it is designed on purpose: a distress horn heard from inside the outpost, Jeff falling silent. But someone has to choose it.
- **Player Psychologist F1 (diegetic post-mortem) + my F1 and F4.3: one fix covers both.** The psychologist wants Jeff or Ted to explain why the player failed. I noted that neither character has anything to say after Step 2 or at the outcome. Giving Ted and Jeff outcome lines that refer to the player's actual delays ("we lost too long on the rocks") fixes the legibility problem and gives the cast the missing payoff at the same time.
- **Systems Designer F3 (final repair is a traversal plus one interaction) + my F1.** The mechanical climax is flat, and so is the story climax: Ted, who owns the lighthouse and the repair knowledge, isn't there when the burner is fitted. Having Ted at the lamp, where the player's arrival is the thing he couldn't do himself, would give the climb weight without adding a skill test.
- **Feasibility Lead F2 (voice recording with no plan) + my F2.** The problem goes beyond budget. The document asks for voiced performance ("Creator approves voice and lore before recording") of characters whose voices are not written down: Jeff is two adjectives, and Ted's arc stops at Step 2. Recording before the character bible exists is where rework will happen.
- **Business Analyst F2 and F1 + my F3.** BA's point that the prototype never tests atmosphere supports my F3. BA's refund-window concern suggests a use for the fix: a coherent hidden canon is the only replay reason the design could have, because a second playthrough would be for reading the strangeness again with knowledge from the first.

### Revisions

- **Finding 4: upgrade MAJOR → BLOCKING.** On its own, I judged the thin ending a craft problem. Combined with Player Psychologist F4 (the ship is never introduced in-game) and Adversarial QA F1 (the fail outcome often can't be shown), the game's single payoff has no introduced stakes, no defined aftermath, and no guaranteed presentation. This is the promise the whole pitch rests on.
- **Finding 4, "sails calmly into port" note: withdrawn.** It's a wording issue, and next to the problems above it isn't worth the board's attention.
- **Finding 4.3 (Daniel): revised.** After BA F5, I no longer just ask for "reaction lines". Either give Daniel a causal role (see Conflicts above) or defer him. A character who exists only to react is exactly what the cut rule should remove.
- **Finding 1: keep BLOCKING.** Feasibility, QA and BA all flagged Ted's undecided presence as a production dependency. That confirms the first half of my finding, but the second half is mine alone and matters more to story: even if Ted is confirmed, he has no arc after Step 2.
- **Finding 3: keep MAJOR, strengthened.** Player Psychologist F2 and BA F2 each approach it from another direction.
- **Finding 5: keep MINOR, new suggestion.** The gate scene is a natural place for the ship-introduction beat that Player Psychologist F4 asks for. If the apprentice spots the wreck *and* the far-off lights from the gate, the player makes the moral choice and learns the stakes in the same moment.
