# Production/Business Analyst — Round 1

Document reviewed: *Lighting the Storm — Compiled GDD* (compiled 29 September 2026).

## Finding 1 — No audience, market positioning, or price, and the product sits inside Steam's refund window
**Severity: MAJOR**

**Problem.** The document names a platform ("PC via Steam is the initial release target") and a length ("designed for a 30 minute complete playthrough"), and nothing else about the market. It gives no target player, no comparable titles, no price, no positioning against the many short first-person atmospheric/folk-horror games already on Steam in 2026, and no wishlist or launch plan. The commercial issue this hides is specific: a 30-minute, single-path game with a binary ending can be finished well inside Steam's standard refund window (under 2 hours played). Nothing in the document gives a player a reason to keep it after one run. The only replay-related content is "optional discoveries", which is also cut from the prototype, and the fail-state follow-up is still open ("What follows the fail state (checkpoint retry or restart) is still to be decided").

**Source.** Exec Summary, "Pitch and player promise" and "Scope and release target". The omission covers all three parts: none of them has an audience, pricing, or market section.

**Why it matters.** Price, length, and replay value have to be decided together. The document fixes one of them (length) and leaves the other two blank. That could make the project unsellable at any price above a token amount, and the document can't show otherwise.

## Finding 2 — The prototype tests a boat-steering game, but the pitch sells a folk-horror atmosphere game
**Severity: MAJOR**

**Problem.** The document is effectively two products with different risks, and only one is tested. The go/no-go gate tests steering in isolation: "Go/no-go: steering past hazards is fun on its own" (Week 2), and "Stop or redesign if the core crossing is not enjoyable" (Gate 0). The emotional hook is something else: "sustained dread", "Folk-horror details invite interpretation", "unexplained environmental wrongness", shrines, symbols, strange architecture. The prototype allows "Greybox art and placeholder audio" and drops "full outpost exploration, optional discoveries, final art". None of the four prototype outcome checks measures dread, ambiguity, or atmosphere. The "Dread you can read" pillar and the full-game check "preserves unexplained environmental wrongness" are therefore never validated before full production begins. The atmosphere is the stated differentiator, yet it is treated as a polish item for Gate 3.

**Source.** Exec Summary "Design pillars" (pillars 1–4), "Outcome checks" (Prototype vs. Full game); Technical Strategy "Milestones and gates" and "Six-week prototype schedule".

**Why it matters.** A greybox slice can pass every gate and still produce a competent but generic boat-dodging minigame. The feature that would make the game marketable has had no go/no-go test by the time the money is spent.

## Finding 3 — No full-game plan: the schedule stops at the prototype, and the release target has no timeline, budget, or release work
**Severity: MAJOR**

**Problem.** Planning detail ends at Gate 1. There is a week-by-week six-week plan for the 10-minute slice. Gates 2 (Narrative alpha) and 3 (Content and polish) have no dates, durations, or staffing. Nothing links the prototype's 10 minutes to the full game's 30. The shipping work itself is explicitly out of scope, with no plan for when it happens: "a finished Steam release flow" is listed as out of first-prototype scope, and nothing covers store page, capsule art, trailer, localisation, ratings, or QA certification. Meanwhile about a third of the document goes to an eight-role AI Agent Strategy with branching, handoff, and licence-provenance procedure. That is a lot of process overhead for a solo, 30-minute project, and it is detailed well beyond the release plan it serves.

**Source.** Technical Strategy "Milestones and gates" and "Six-week prototype schedule"; Exec Summary "Out of first-prototype scope"; Part 3 "Ownership and handoffs" (eight agent roles). The largest omission is any schedule or cost estimate past week 6.

**Why it matters.** The document itself names "scope creep across repairs, cinematics, and environmental detail" as the second-largest risk. Without a full-game schedule, the plan has no way to detect that creep.

## Finding 4 — A load-bearing feature (Ted) is still an open decision
**Severity: MAJOR**

**Problem.** Ted is central to the core vision. Pillar 3 says "guidance comes from Ted and Jeff, not markers". Repairs are done by following "Ted's live guidance". Ted prompts the crash view and the gate interaction, and explains the outpost objective. Yet the AI Agent Strategy lists "Ted's presence" among the open decisions the creator must settle first. If Ted's presence changes (for example, off-screen, radio-only, or cut), the replacement for quest markers in the first act goes with him. That affects Dialogue, Level Layout (sightlines), Gameplay/Systems (crash trigger), and the pillar test. For production, this is an unfrozen dependency sitting under the first playable act. It is not a flavour choice.

**Source.** Exec Summary pillar 3 and "Story and gameplay sequence" steps 1–2; AI Agent Strategy, "Recommended sequence", item 1 ("settle the open decisions, starting with the engine, Ted's presence…").

**Why it matters.** Week 4 of the schedule builds "One repair, crash through the window, gate opening". If Ted is not locked by then, that week's work is at risk of rework.

## Finding 5 — Daniel and the rowboat crash are expensive, mostly decorative content that fails the document's own feature test
**Severity: MINOR**

**Problem.** The document sets a clear cut rule: "A feature that fails a pillar's test, or expands the world without deepening the main loop, should be deferred." Daniel is a second rescued sailor who "stays at the lighthouse". He has no gameplay role, but he still needs a character model, animation along a scripted walk path, dialogue lines, and a distinct presence in the crash sequence. The crash-and-gate step adds a scripted first-person set piece, a second boat that "must stay visibly distinct", and a gate that is a single interaction. Its only load-bearing job is delivering Jeff. Yet it is in the Gate 1 slice and takes part of week 4 of a six-week prototype whose purpose is to prove steering. It is the kind of cinematic content the document itself names as the second scope-creep risk.

**Source.** Exec Summary "Cast and atmosphere" (Daniel; two distinct boats) and "Design pillars" scope rule; Technical Strategy "Repairs, crash and gate, and final pressure" and the Week 4 row; the final risk paragraph ("scope creep across repairs, cinematics, and environmental detail").

**Why it matters.** Daniel might earn his place in the story, which is the narrative reviewer's call. From a production standpoint, though, he is the clearest example of content the document's own cut rule would defer, and he is currently scheduled into the prototype.

## Round 2 — Cross-examination

### Conflicts

**C1. Narrative Critic F1 (Ted = BLOCKING) vs. my F4 (Ted = MAJOR).** Four of six reviewers flagged Ted's open status (Narrative F1, Feasibility F3, Adversarial QA F4, and my F4), so confidence is high. I still disagree that it is BLOCKING. It is one decision the creator can make in a day, and nothing in the document argues against keeping Ted physically present. Every other section already assumes he is. Calling it BLOCKING suggests a design hole, when what's actually missing is a signature. The right fix is Feasibility's decision log with a "needed by week N" date. Ted has to be locked before week 4, or before week 1 if Level Layout sightlines depend on him. Past that date, I agree it becomes blocking. I am keeping MAJOR, with that deadline attached.

**C2. Narrative Critic F4 and F1 (give Ted, Jeff and Daniel reactions to the outcome, and give Ted second-half presence) vs. my F5 (defer Daniel).** The narrative fix adds content: outcome reactions for three characters across two endings, plus new Ted lines in steps 6–8. Voice recording is unbudgeted (Feasibility F2), so every added line is also an unpriced cost. I accept the narrative diagnosis that the ending has no human payoff. My counter-proposal is to spend that payoff on Ted, who already exists, is already on site at the lighthouse for step 8, and already has an unused emotional note ("guarded sense of care"). Fold Daniel's survivor-echo role into Jeff, who is on the boat and present for both crossings. That gives the narrative critic's payoff while shrinking the cast by one. It also answers Narrative F2 ("why two sailors?") by removing the question.

**C3. Player Psychologist F5 (add a riskier return shortcut), Systems F3 (make the final repair a skill interaction), and Systems F4 (give repairs mechanical outputs) vs. my F3 (no full-game plan, scope creep is the named risk).** All three are reasonable. All three add features to a project that, as Feasibility F2 also found, has no schedule past week 6 and only one cut rule (waves). I rank them by cost against what they recover:
- *Systems F4, repairs feeding the crossing* (for example, a repaired fog signal lengthens Jeff's lead time). **Accept.** It reuses parameters that already exist ("difficulty-dependent lead time", beacon visibility), and it turns four decorative repairs into load-bearing ones. That is the cheapest way to make the pre-boarding 20 minutes pass the document's own cut rule.
- *Psychologist F3, a steering warm-up.* **Accept in its zero-cost form:** start the deadline at the harbour mouth, not on boarding. This needs no new content.
- *Psychologist F5, a shortcut route, and Systems F3, a skill-based final repair.* **Defer to Gate 2.** Both are new authored content. They should go on the ranked cut list Feasibility asked for, not into the slice.

### Connections

**X1. The differentiator is placed exactly where the design punishes engaging with it.** Three findings combine here: Psychologist F2 (the hidden clock punishes curiosity at the outpost), Narrative F3 (the folk-horror layer has no link to the plot), and my F2 (atmosphere is never tested). Together they show a commercial problem none of them states alone. The folk-horror content is the only thing that sets this game apart on a store page. It is concentrated at the outpost, the one place where the timer makes exploring it cost the good ending. Players who rush, which is what the design rewards, finish in 30 minutes without seeing the hook. That makes the refund-window risk in my F1 worse. The fix is also a scope saving: move the optional discoveries to the lighthouse and island before boarding, where the environments already have to be built at Gate 1, and a lore slice can go into the prototype's atmosphere test.

**X2. The retry model is a commercial decision, not just a systems one.** Systems F1, Adversarial QA F2 and Psychologist F1 all treat the undecided retry and checkpoint behaviour as a fairness or integrity bug. Add the business lens: the fail state lands around minutes 20–30. If failing means a full restart, a first-time player who fails has to replay 20+ minutes to see the good ending. That total still fits inside Steam's 2-hour refund window, and at the moment the player is most annoyed. QA's option of a single run-start snapshot (restore to boarding with the full timer) is also the cheapest to build, because it needs no per-checkpoint time floor. I would back it on cost grounds. It also partly answers my F1: the fail ending becomes content the player chooses to replay, not a punishment.

**X3. Week 4 overload makes Daniel a schedule problem.** Feasibility F1 found that week 4 carries five scripted features plus the first version of the hazard-forecast API, with no buffer. Removing Daniel takes out one NPC walk path, one character model, and a set of lines from that exact week. That frees room for the forecast work Feasibility wants moved earlier. This changes my F5 from a "decorative content" point to a schedule-relief point (see R2).

**X4. The stakes are never set up, so there is no pitch line.** Psychologist F4 notes that the passenger ship is never introduced in-game, and Narrative F4 notes that its victims are unnamed. For marketing, that means the one-sentence hook ("save a ship you can see but can't reach") isn't in the game yet. A trailer can't sell stakes the first five minutes don't establish. This supports my F1: positioning can't be written until the stakes beat exists.

### Revisions

**R1. Upgrade F3 (no full-game plan) from MAJOR to BLOCKING, for the full-production decision only.** Feasibility F2 reached the same conclusion on its own, and its closing line, "The full game's feasibility cannot be judged from this document as written", is the production verdict in one sentence. The document says the slice "should decide whether the full game is feasible", but with no Gate 2–3 estimate there is nothing to compare the slice against. So Gate 1 cannot produce a real go/no-go on production. I agree with Feasibility that this does not block the six-week prototype.

**R2. Upgrade F5 (Daniel) from MINOR to MAJOR, and narrow it.** Given X3 and C2, the recommendation is now specific: cut Daniel from the Gate 1 slice and fold his role into Jeff, but keep the crash. The crash has a real job (it delivers Jeff), and Narrative F5 suggests ways to make it matter more.

**R3. Downgrade the AI Agent Strategy sub-point in F3.** Feasibility called the prototype plan "unusually disciplined", and no other reviewer saw the agent process as a cost. It is the creator's tooling, not player-facing scope, and its provenance rules are what surfaced the unlicensed-voice gap in Feasibility F2. I withdraw "process overhead" as a criticism. My point is only that it is planned in more detail than the release plan, and the missing release plan is the real problem.

**R4. F1 stays MAJOR but is now better supported.** X1, X2 and X4 each show a specific mechanism that feeds refund risk. The finding no longer rests only on "no price in the document".
