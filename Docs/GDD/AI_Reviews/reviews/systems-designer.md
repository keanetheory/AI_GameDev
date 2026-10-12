# Systems Designer — Round 1

Scope of this review: core loop, progression, pacing across the ~30 minute playthrough, difficulty curve, and the deadline/penalty economy. The document's central system is a single hidden deadline that collision and cargo penalties spend. Most of my findings are about whether that economy is actually closed.

---

## 1. What happens after failure is undefined, and saving remaining time at checkpoints can produce unwinnable saves — BLOCKING

**Problem.** The deadline is the only failure system in the game, and the document leaves its aftermath open. Technical Strategy says: *"What follows the fail state (checkpoint retry or restart) is still to be decided,"* and also proposes *"save remaining time at checkpoints."* Together these create a trap. If a player reaches a checkpoint (for example, arriving at the outpost) after several collisions, the save locks in a time budget that may already be too small to finish the return crossing and final repair. A "checkpoint retry" then drops them into a run they cannot win, over and over. The only way out is a full restart, which means replaying up to 30 minutes, including all the untimed repairs.

**Source.** Technical Strategy, "Repairs, crash and gate, and final pressure" (deadline paragraph). Also Gate 2's acceptance line, *"no dead-end save,"* which this proposal quietly contradicts. There is also an ordering problem: checkpoints are scheduled for Gate 3 ("Content and polish"), but the fail state has to work at Gate 1. So the prototype will test failure with no retry model at all, and playtesters cannot judge whether the fail state is fair.

**Related inconsistency.** The Exec Summary says *"Boarding starts the hidden passenger-ship deadline."* The Technical Strategy says *"start on first outbound boarding."* The word "first" implies you can board more than once, for example by leaving and re-boarding at the lighthouse or the outpost, but nothing says whether re-boarding happens or what the clock does if it does.

**Needed.** Decide retry-vs-restart now. If checkpoints store time, put a minimum-remaining-time floor on each checkpoint, or checkpoint the time value as it was when that phase *started*. Otherwise pillar 4's "fair and recoverable mistakes" doesn't hold.

---

## 2. Weather escalating with elapsed deadline time creates a death spiral — MAJOR

**Problem.** Two rules feed each other in a loop:
- *"these events [collisions] consume deadline time"* (Prototype failure policy)
- *"Weather escalates by phase and elapsed deadline time through coherent changes to sea motion, hazard density, ... visibility"* (Boat and weather simulation)

A player who collides loses time. Losing time pushes the weather further along, which means denser hazards and lower visibility, which means more collisions. The system punishes struggling players twice and leaves skilled players under less pressure. That's the reverse of the recoverable-mistake promise in pillar 4 (*"fair and recoverable mistakes"*) and the prototype check (*"a recoverable error state"*). The "reduced hazard-intensity preset" softens the slope but keeps the loop.

**Source.** Technical Strategy, "Boat and weather simulation" and "Prototype failure policy."

**Needed.** Choose one of two approaches. Either escalate weather by *phase and route position* only, so it works as a designed difficulty curve rather than a punishment, or cap how much of the escalation elapsed time can drive. Whichever is chosen, write it down. Otherwise the tuning team will find this loop through playtest variance and blame the steering.

---

## 3. The hidden deadline is really an invisible mistake budget, and the player can't read it — MAJOR

**Problem.** The boat has *"one fixed speed"* and *"no throttle."* Route length is authored. That means a flawless run always takes the same time. The only thing that varies between runs is how many mistakes the player makes, plus how long the outpost search and final climb take. So the deadline is functionally a count of allowed collisions, which fits the stated tuning goal: *"a first-time player who follows cues has room for some mistakes."* The player never sees that count. The ship's lights are one continuous signal, and the player can't turn them into "I can afford two more hits." When they fail, they can't tell whether the cause was the collision on the outbound leg, the time spent searching the outpost, or the climb to the lamp. That conflicts with pillar 4's claim that *"the player always knows ... why they failed."*

There are also two phases that spend the budget without testing a skill:
- **Outpost search** runs on the clock (*"continue through ... outpost search"*), yet full outpost exploration is out of prototype scope. How long the search takes, and whether it's a skill test or a scavenger hunt, is not specified.
- **Final repair** is *"Climb to the lamp and fit the burner."* This is the climax of the loop, but it's written as a traversal-plus-single-interaction with no challenge. It spends time without offering any way to make it back. A player who arrives with little margin just walks and hopes.

**Source.** Exec Summary step table (steps 5 and 7), pillar 4. Technical Strategy, "Boat and weather simulation" and the deadline paragraph.

**Needed.** Two things. First, readable milestones for the budget: fixed ship positions at each phase transition that tell the player "on pace" or "behind." Second, either give the final repair a short skill-based interaction or keep it out of the deadline.

---

## 4. Pacing is front-loaded with untimed repairs that don't feed the crossings — MAJOR

**Problem.** The 10-minute prototype already covers the *whole* critical path: crash, gate, both crossings, pickup, fitting, and both outcomes. The only things it drops are *"the remaining lighthouse repairs, full outpost exploration, optional discoveries."* So roughly 20 of the full game's 30 minutes must come from content that is mostly *before boarding*, and before boarding *"exploration has no ship deadline."* The pressure half of the game, pillar 2 ("the storm sets the clock"), covers maybe a third of the runtime. The first two-thirds have no pressure at all.

Those repairs also don't connect to the core loop. The later repairs (*"optic, rotation, fuel/fog signal, and stormproofing"*) have no stated effect on the crossings. The document says to *"use ... the beacon when facing home,"* but the beacon *"alone still flickers"* after the repairs. There's no link between how well the player repaired the lighthouse and how readable the way home is. The repair data schema includes *"optional route unlock,"* and the save includes *"unlocked routes,"* but the crossings are one authored corridor with no route choice anywhere. That field has nothing to connect to. Pillar 1's test (*"does this connect to getting the light back?"*) passes for the repairs in the narrative sense, but they have no mechanical effect on the crossings.

**Source.** Exec Summary, "Scope and release target" and the step table. Technical Strategy, "Repairs ..." paragraph and the "Core state contract" save list.

**Needed.** Give the repairs mechanical outputs in the crossing. For example, a repaired fog signal gives Jeff earlier calls on the return, or a repaired rotation makes the flickering beam readable as a homing landmark. Alternatively, define what "routes" means, or remove it from the contract. Also budget the 30 minutes by phase so the untimed-to-timed ratio is a deliberate choice.

---

## 5. The crossing penalty system lists outcomes without rules, and one penalty has no input — MINOR

**Problem.** The failure policy says a collision *"adds water, slows the boat or causes a brief capsize-and-recovery."* That's three alternative consequences with nothing saying which applies when: by impact severity, by hazard type, or by accumulated count. Two of them don't close as systems:
- **Water** accumulates, but nothing drains it: bailing is *"only if it improves the crossing in playtests"*. Its only stated effect is the slowdown. With no threshold and no sink, water is a stat with no effect on play.
- **Cargo mishandling**: *"On return, cargo mishandling delays progress and creates a clear recovery interaction."* The player's entire input set on the boat is one steering axis. No input or event is described that could cause mishandling, so it's either an automatic collision side effect (undefined) or a new control that breaks the one-control promise.

**Source.** Technical Strategy, "Prototype failure policy." Exec Summary prototype check: *"one steering control, one fixed speed."*

**Needed.** A penalty table: hazard type × impact severity → consequence and approximate time cost. Also state whether water is a real resource with a threshold (for example, water reaching a level triggers a capsize) or should be cut. And describe what triggers cargo loss.

---

## Round 2 — Cross-examination

### CONFLICTS

**Adversarial QA, Finding 1 (fail state can't be shown where the deadline expires).** I agree with the diagnosis. I disagree with one of QA's three proposed remedies: *"let the ship keep going until the player can see it."* From a systems view that is the worst option. It creates a doomed run: once the deadline hits zero on the outbound leg, the player keeps steering, searching the outpost and climbing the lamp for maybe ten more minutes of play that cannot change anything. Because the clock is hidden (my Finding 3), they don't even know it's over. That is exactly the "punishment the player can't read" problem, made longer. My position is that expiry has to resolve at expiry. Use QA's audio-only option (foghorn, then silence) wherever the ship isn't in view, and end the run there. If the designer wants the ship to be *seen* running aground, the alternative is to make the deadline mean "the ship reaches the reef when the lamp is lit or not." In that case the outcome is checked once at final repair and the fail is always shown from the lamp. That approach is only legitimate if there are readable pace milestones along the way (my Finding 3), so the player isn't surprised at the end. Pick one. Don't pick the soft-deadline hybrid.

**Feasibility Lead, Finding 5 (make "slow plus brief stop" the only prototype collision response; defer capsize and cargo mishandling to Gate 2).** I support simplifying the penalty set, since it answers most of my Finding 5. But the proposal creates a tuning problem the Feasibility Lead didn't flag. The deadline is tuned in weeks 5-6 from measured playtests. If cargo mishandling and capsize are added at Gate 2, every value measured in week 6 becomes wrong, because the time costs that the deadline was sized against change. The deferral only works if the penalty table (my Finding 5) is written *now*, with a time cost for each event, including the deferred ones, so that the prototype deadline carries a known reserve for them. Otherwise it's cheap now and a retune later.

**Narrative Critic, Finding 4.2 (instant checkpoint retry turns the ending into a game-over screen).** This is a tension with my Finding 1, where I push for a retry model so the player doesn't lose 30 minutes of progress. I hold my position: a full restart as the only option makes failure so expensive that most players will never see the fail ending as anything other than a quit point (Player Psychologist Finding 1 says the same). But the two goals aren't incompatible. Play the fail outcome in full as a consequence, and only then offer a retry from a phase-start time snapshot. The fail still happens and is seen, and the retry cost is bounded. What the narrative side must not get is a design where the only way to respect the consequence is to erase the whole run.

### CONNECTIONS

**Player Psychologist, Finding 3 (first steering happens after the clock starts), combined with my Finding 2 (death spiral).** Individually, each is a fairness problem. Together they are worse. The collisions a player makes while learning the controls don't just cost time. Through elapsed-time weather escalation they also make the *rest* of the outbound crossing and the whole return harder. So the learning curve and the difficulty curve feed each other, starting in the first minute of steering. A sheltered harbour stretch before the clock starts, as the Psychologist suggests, fixes the onboarding problem *and* removes the earliest input to the spiral. This strengthens my Finding 2.

**Player Psychologist, Finding 2 (the clock punishes curiosity at the outpost), combined with my Findings 2 and 3.** The Psychologist frames outpost exploration as a direct time cost. It's worse than that. Because weather escalates with elapsed time, every minute spent reading shrines at the outpost also produces denser hazards and lower visibility on the return. The curious player pays twice: once in deadline and once in difficulty. This is the clearest case that elapsed-time escalation is a design bug and not a tuning knob.

**Player Psychologist, Finding 5 (the player can't act on the pressure; suggests a risky shortcut vs. a safe route), combined with my Findings 3 and 4.** This is the connection I'd most like the board to take forward. My Finding 4 noted that the schema carries *"optional route unlock"* and *"unlocked routes"* with nothing for them to connect to. My Finding 3 noted that with a fixed speed, the deadline is only a mistake budget. A route choice solves both. Repairs (for example the rotation or fog signal) unlock a shorter but more dangerous return line, which Jeff can call. That gives the repairs a mechanical output, gives the dead schema field a purpose, and gives the deadline a second variable besides collision count, so the player's decisions matter and not only their errors. It also addresses Business Analyst Finding 1 (little reason to replay a 30-minute single-path game), because the route choice creates run-to-run variance. I'd rate the Psychologist's MINOR as MAJOR when taken together with these. One caveat from Feasibility Finding 1: a branching route needs the hazard forecast/safe-route signal to support branches, and that system already has no scheduled week. It has to be designed in from the start.

**Adversarial QA, Finding 3 (no docking or arrival model; respawn at a "nearby safe point"), combined with my Findings 2 and 5.** A respawn facing a rock at a fixed speed produces chained collisions. Under the current rules, each collision costs time *and* advances the weather. The respawn rule is therefore also an input to the death spiral. QA's suggested grace period should be written into the penalty table as a rule, not left as a polish item. QA's point that a boat which can't stop can't retrieve a burner dropped "at a marked nearby point" also confirms my Finding 5 that cargo mishandling has no workable input or recovery under a one-control boat.

**Feasibility Lead, Finding 4 (the deadline can only be tuned at the end with 3-5 testers), combined with my Finding 3.** The fixed-speed design makes the paper budget the Feasibility Lead asks for cheap to produce. Par time is route length divided by boat speed, plus par outpost time, plus par climb time. None of this needs a playtest. Only the mistake allowance needs one. The document could state a target par and mistake reserve today. And because of the death spiral, 3-5 testers will produce high variance that small samples can't separate from steering skill. That is another reason to fix Finding 2 before week 6, not after.

**Adversarial QA, Finding 5 (the ship is frozen before boarding), combined with my Finding 4.** If about two-thirds of the full game's runtime happens before boarding, the ship sits frozen and visible on the horizon for roughly 20 minutes. That turns QA's MINOR exploit into a pacing problem at full-game scale. Pillar 2's clock is absent for most of the game, and the player can see that it is absent.

### REVISIONS

- **Finding 5 (penalty system): upgrade MINOR to MAJOR.** Three colleagues independently depend on it. Feasibility Finding 5 notes that the cargo deliverable has no spec. QA Finding 3 shows that recovery is physically impossible under the current boat model. Feasibility Finding 4 needs per-event time costs to tune the deadline at all. The penalty table is the input to the only failure system, so leaving it undefined isn't a detail.
- **Finding 2 (death spiral): stays MAJOR, strengthened.** The connections with Psychologist Findings 2 and 3 and QA Finding 3 show that at least three other design choices (clock on the learning phase, clock on exploration, respawn rules) feed the loop.
- **Finding 4 (pacing/repairs): stays MAJOR, recommendation revised.** Instead of "define 'routes' or remove it from the contract," I now recommend the specific use set out above: repairs unlock return route options, which serves my Finding 4, Psychologist Finding 5 and Business Analyst Finding 1 together.
- **Finding 1, "first boarding" sub-point: withdrawn as a separate issue.** It is subsumed by QA Finding 3. Re-boarding is one case of the larger missing docking and arrival model, and should be fixed there. The core of Finding 1 (unwinnable checkpoint saves) stays BLOCKING. QA Finding 2 reached it independently and added a second contradiction: the "resolves exactly once" invariant fails under retry.
- **Finding 3: unchanged in severity.** Player Psychologist Finding 1 independently reached the "can't tell why they failed" half of it. I note that QA Finding 1 adds a case where the player can't even tell *that* they failed.
