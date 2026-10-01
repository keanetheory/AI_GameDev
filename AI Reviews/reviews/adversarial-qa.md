# Adversarial QA — Round 1

Reviewer lens: contradictions between sections, unhandled edge cases, sequence breaks, exploits, and fail states nobody planned for.

---

## 1. The fail state cannot be shown from wherever the deadline actually expires — BLOCKING

**Problem.** The deadline runs "through both crossings, the pickup, and the final repair." So it can run out while the player is mid-crossing, inside the abandoned outpost, or on the lighthouse stairs. But the fail state is defined as something the player watches from the lighthouse: Step 8 is "Watch the ship from the lighthouse," and the doc says "the ship outcome from the lighthouse, so both need clear sightlines." Cutaways are banned outright ("There are no cutaway or exterior cameras"). If the player is inside the outpost, facing away from the ship at sea, or indoors when time runs out, the design has no legal way to show "the ship runs aground, seen in first person." Pillar 4's promise that the player "always knows ... why they failed" breaks in exactly the case where it matters most.

**Source.** Exec Summary, sequence table step 8 and "All viewpoints are first-person..."; Technical Strategy, "On expiry, trigger the fail state: the ship runs aground, seen in first person" and Presentation ("the ship outcome from the lighthouse"). No section says where the player is, or what they perceive, when expiry happens away from the lighthouse.

**Needed.** Define the fail presentation for every phase where expiry can occur (OUTBOUND, OUTPOST, RETURN, FINAL_REPAIR, and indoor versus outdoor). Choose one: guarantee sightlines to the ship from all of these places, allow an audio-only fail (foghorn or distress horn followed by silence), or let the ship keep going until the player can see it (which makes the deadline softer than the invariant states).

---

## 2. Checkpoints that save remaining time can create unwinnable saves, and the retry model contradicts "resolves exactly once" — BLOCKING

**Problem.** The proposed rules "save remaining time at checkpoints." Suppose a checkpoint lands after a run of collisions has used up most of the budget, for example at the start of the RETURN crossing with too little time left to cross and climb. Every reload of that checkpoint then leads to a guaranteed fail: a doomed loop. Gate 2 requires "no dead-end save," so this breaks its own acceptance criterion. It gets worse because the document leaves the retry model undecided: "What follows the fail state (checkpoint retry or restart) is still to be decided." If retry is from a checkpoint, the invariant "the ship outcome resolves exactly once" is wrong on its face. The same save slot resolves FAIL, reloads, then resolves again. Validation also expects "reload resumes a consistent phase," but nothing says whether ship state rewinds with the deadline.

**Source.** Technical Strategy, deadline paragraph ("save remaining time at checkpoints", "still to be decided"); Core state contract invariants ("resolves exactly once"); Gate 2 acceptance ("no dead-end save"); Gate 3 lists "checkpoints" as polish-phase work, even though Gate 1 already needs a fail-then-what answer.

**Needed.** Settle the retry model before Gate 1. Then do one of two things: add a minimum-viable-time floor that stops a checkpoint from saving when the time left can't finish the route at par, or keep one run-start snapshot that restores time on retry. Reword the invariant to "resolves exactly once per attempt" and say which fields roll back on reload.

---

## 3. A boat with one fixed speed and no throttle has no defined way to stop, dock, disembark, or reach a recovery point — MAJOR

**Problem.** The boat is "a forward-moving boat with one fixed speed," and "the player steers but has no throttle." The loop still needs the player to stop at the outpost ("Find and pick up the replacement burner"), get off and back on, stop at the lighthouse and "Climb to the lamp," and, under the proposed cargo rule, collect the burner "at a marked nearby point." None of these transitions is specified. Edge cases this leaves open:
- Can the player circle the outpost forever without landing? The deadline keeps running, so that is only a pacing problem, but nothing says what triggers arrival.
- Can the player steer straight home without landing at the outpost? The invariant "a burner pickup precedes return completion" forbids the result but not the path. What happens when a burner-less boat reaches the lighthouse: bounce, a Jeff line, or a soft-lock?
- If the burner is dropped at "a marked nearby point," how does a boat that cannot stop retrieve it? This also collides with the "one-control steering promise" the same paragraph protects.
- A capsize respawns the boat "at a nearby safe point." If that point is behind the player or facing a rock at fixed speed, you get a chain of immediate collisions.

**Source.** Technical Strategy, Boat and weather simulation; Prototype failure policy; Core state contract (the OUTBOUND to OUTPOST to RETURN transitions have no stated triggers); the example Gate 0 brief ("one fixed speed with no throttle").

**Needed.** Specify arrival and docking triggers (auto-dock volumes, for instance), what happens when the player arrives without the burner, how the burner is retrieved when the boat can't stop, and respawn rules: face the safe route and give a grace period before a collision can count.

---

## 4. "Proposed" items are enforced as invariants and gate criteria, and a load-bearing character (Ted) is still an open decision — MAJOR

**Problem.** The Exec Summary says items marked Proposed "need the creator's approval before they become canon," and agents are told "do not silently decide" unresolved canon. Yet several Proposed rules are already hard requirements elsewhere:
- The deadline rules (start on boarding, pauses, checkpoint saves) are all Proposed, but the Core state contract invariant is "the deadline is inactive before the first boarding event," and Gate 1 acceptance says "the ship deadline starts only on boarding."
- "Keep the burner recoverable ... never permanently lost" is Proposed, but Gate 2 acceptance already demands "no ... cargo loss."
- The crash trigger with a fallback delay is Proposed, but the crash is mandatory Gate 1 content.

On top of that, the Recommended sequence lists "Ted's presence" as an open decision, while every early gate relies on Ted. He gives the repair guidance, prompts the window look that triggers the crash, orders the gate opened, and explains the outpost. If Ted is cut or turned into, say, a voice on a radio, steps 1–2 lose their triggers. The Gameplay/Systems and Dialogue agents would be building against a contract that can legally vanish.

**Source.** Exec Summary status line; Technical Strategy ("Proposed rules: start on first outbound boarding..."; "Proposed: keep the burner recoverable..."; "Proposed: trigger the crash when the window is in view..."); Gate 1 and Gate 2 acceptance; AI Agent Strategy, working rule 1 and Recommended sequence step 1.

**Needed.** Either promote these items to canon or mark the matching invariants and gate criteria as provisional. Decide Ted's presence before step 3 of the Recommended sequence. Also say whether the crash and gate triggers depend on Ted's line or on world state, so the phase controller has one owner.

---

## 5. Deadline pause and preset rules open exploits, and the pre-boarding state is frozen and ambiguous — MINOR

**Problem.** Four small issues:
- **Pause scope.** The clock stops "during menus and deliberate pause." The apprentice's "handwritten objective journal" is the main guidance tool. If it opens as a menu, the player can freeze the deadline at will to plan the route; if it is a diegetic item in the world (which fits Pillar 3), the clock keeps running while the player reads. Neither choice is stated.
- **Mid-run preset swap.** The difficulty preset is saved state and changes Jeff's lead time and hazard intensity. Nothing says whether it can change mid-run, or whether it also changes the deadline duration. If it can be toggled during a crossing, a player can drop to the reduced preset for the hard return and switch back. If duration depends on the preset, switching during a run needs a rule.
- **Frozen ship before boarding.** The ship's lights are visible before boarding (the player is at the window), but the deadline hasn't started, so the ship is frozen however long the player explores. That contradicts Pillar 2 ("The storm sets the clock"), and a sharp-eyed player will notice.
- **Gate timing.** The gate is "a single interaction," but nothing says whether it can be used before the crash. If the player opens it early, does CRASH_AND_GATE skip ahead, double-fire, or ignore the input?

**Source.** Technical Strategy deadline paragraph ("stop during menus and deliberate pause"); Core state contract (difficulty preset saved); Jeff's "difficulty-dependent lead time"; Exec Summary ("Before boarding, exploration has no ship deadline"); crash and gate paragraph.

**Needed.** List which UI states pause the deadline. Lock the preset per run, or define what switching does. Keep the pre-boarding ship out of sight or give it a scripted holding pattern. Make the gate uninteractable until the crash event fires.

---

## Round 2 — Cross-examination

### Conflicts

**Feasibility Lead, Overall ("Nothing here is BLOCKING for the prototype").** I disagree. The Gate 1 slice has to reach both outcomes, so fail presentation (my #1) and the fail-then-what model (my #2) are prototype problems, not full-game ones. Feasibility's own Finding 3 concedes the point: Gate 1 needs the fail outcome reachable, and the checkpoint contract it depends on isn't scheduled until Gate 3. When a Gate 1 acceptance criterion depends on a Gate 3 system, the prototype can't pass its own gate. That is what BLOCKING means. Systems Designer #1 and Player Psychologist #1 reached BLOCKING on the same passage independently, so the prototype-only reading is the outlier.

**Player Psychologist #4 (Ted points out the ship's lights before boarding) versus my #5 (frozen ship before boarding).** Their fix is right for motivation, but it turns my edge case into a guaranteed bug. The deadline is inactive before boarding, and that is enforced as an invariant (my #4). So the ship Ted points out has to hold still for as long as the player stays in the untimed act. Systems #4 estimates that act at roughly two-thirds of the 30 minutes. A player who looks, spends 15 minutes on repairs, then looks again will see the ship in the same place, and Pillar 2's "the storm sets the clock" falls apart right where it is introduced. If the board adopts Psychologist #4, the document also has to say what the ship does before boarding: a scripted holding pattern, a separate slow pre-boarding clock, or showing it only at the boarding moment.

**Player Psychologist #5 (a riskier reef shortcut on the return).** This helps the player feel in control, but it creates exploits the document has no way to catch. (a) Jeff's calls and the hazard forecast read from "the same safe-route signal", which is singular. A second route means Jeff either stays silent on the shortcut or has to call two routes, which breaks the rule that his warnings "never disagree with the actual threat." (b) At a fixed speed with no throttle, a shortcut is a straight saving of deadline time. If it is survivable at all, skilled players always take it, and deadline tuning (Feasibility #4) now has to cover two route lengths from 3–5 testers. (c) It gives the orphaned "unlocked routes" save field that Systems #4 found a purpose, but that field is not in the gate criteria. If the shortcut goes in, it needs its own penalty entry in the table Systems #5 asks for, and the invariants need a line about Jeff on the shortcut.

**Narrative Critic #1 (Ted's open status as BLOCKING).** I keep it at MAJOR. The document is honest that Ted is undecided, and it tells agents to ask rather than guess. That is a known open question with a process around it. The half of my #4 that nobody else raised is the dangerous half. Proposed rules (the boarding start, burner recoverability, the crash trigger) are already enforced as invariants and gate criteria, so an agent following the contract will build them as canon without anyone noticing. Silent canonisation is worse than an open question that has been flagged.

### Connections

**Systems Designer #2 (death spiral) combined with my #2 (doomed checkpoints).** Separately these are a tuning problem and a save problem. Together they make an unwinnable save the normal outcome for a struggling player, not a rare one. Weather escalates on elapsed deadline time, so a player who collides a lot reaches the RETURN checkpoint with less time and a harsher storm. Nothing says whether weather state is saved with the time or recalculated from it on reload. Either way, the reload hands the weakest player the least time and the worst conditions every time. A minimum-time floor alone doesn't fix this. It needs to be paired with Systems #2's cap on time-driven escalation, and the save contract has to list weather intensity as a field that is either saved or derived.

**Systems Designer #1 ("first outbound boarding") combined with my #3 (no docking).** "First" implies you can board again, and my #3 shows there's no defined way to get off. So the document implies a disembark and re-board cycle and specifies neither half. For example, if the player lands at the outpost, walks back to the boat without the burner, and leaves, nothing says whether the invariant "burner pickup precedes return completion" soft-locks the player at the lighthouse or sends them back. Both findings are fixed by the same thing: docking and boarding trigger volumes, plus a rule that the boat won't leave the outpost without the burner (Jeff refuses to cast off).

**Systems Designer #5 (water has no sink) and Feasibility #5 (cut capsize for the prototype) combined with my #3.** Feasibility's fix ("slows the boat plus a brief stop") partly settles my respawn-chain edge case, because no teleport means no badly oriented safe point. But "a brief stop" is itself undefined for a boat whose only stated property is fixed forward speed, so it is the same missing stop rule as my #3. The collision response, the docking rule, and the burner-retrieval rule should be one spec for "the boat is not moving". Also, as Systems says, water without a threshold does nothing, so the only route to capsize is unspecified. If the prototype cuts capsize, water should be cut from it too.

**Narrative Critic #5 (let the apprentice choose to open the gate) combined with my #5 (gate timing).** If the gate becomes a real choice, the player can refuse it. Jeff is the only source of navigation and he comes through that gate, so refusing leads to a crossing with no navigator, or the game waits forever. The document needs a rule for when the gate can be interacted with and for refusal: either the gate can't be refused and the story keeps going, or refusal is a scripted third outcome. Business #5's suggestion to cut Daniel doesn't touch this, because Jeff is the load-bearing sailor either way.

**Player Psychologist #2 (outpost curiosity punished) combined with my #1 (fail visibility).** The outpost interior is where curious players will be when the clock runs out, and it is also the place with no sightline to the ship. So the players the psychologist says are most likely to fail are the ones for whom a first-person fail is impossible to show. This makes my #1 a common case, not a corner case.

### Revisions

- **#5, frozen-ship bullet: upgrade from MINOR to MAJOR if Player Psychologist #4 is adopted.** A pointed-out ship that holds still breaks Pillar 2 on every playthrough, not just for sharp-eyed players. The other three bullets (pause scope, preset swap, gate timing) stay MINOR.
- **#2: severity stays, scope wider.** The fix has to cover weather state on reload (see the Systems #2 connection), not only the time value.
- **#3: stays MAJOR, reframed.** Together with Systems #1, #5 and Feasibility #5, this is a missing "boat stopped or boarding" spec with four consumers: collision response, docking, re-boarding, and burner retrieval.
- **#4: Ted half softened, invariant half kept.** Four other reviewers flag Ted, so that part adds nothing new here. What I'm adding is the Proposed-as-invariant contradiction, and I stand by MAJOR for it.
