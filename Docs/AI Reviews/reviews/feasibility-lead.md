# Technical Feasibility Lead — Round 1

Document reviewed: *Lighting the Storm — Compiled GDD* (29 Sept 2026). Solo developer, about 40 h/week with AI assistance, Godot 4 (proposed), PC/Steam. I judged it against the tools available in 2026: a mature Godot 4, agentic coding assistants, and no outside team.

---

## Finding 1: The six-week schedule never builds the shared "hazard forecast," and week 4 carries too much — MAJOR

**Problem.** Jeff's navigation calls are a core feature, and the prototype needs them to show that players "understand where to head" without markers. They depend on a shared system that no week of the schedule builds. The Technical Strategy says: "Use a shared hazard forecast for hazards..., boat reaction, and Jeff's calls, so his warnings never disagree with the actual threat. Jeff's calls read from the same safe-route signal, with explicit difficulty-dependent lead time and frequency." The Boat/Physics agent's *input contract* is a "Hazard forecast API", so it is treated as if it already exists. But weeks 1-2 build only the boat, collisions and feedback. Week 4 is the first place "Jeff's direction calls" appear, and it shares the week with the one repair, the scripted crash through the window (with a view trigger and fallback), the gate, the NPC walk-in along a scripted path, and Jeff waiting at the boat.

**Why it matters.** Week 4 bundles five scripted or system features with the first working version of a cross-system API. Two things follow. First, the forecast is exactly the kind of interface that Boat/Physics and Gameplay/Systems must "agree on event names before parallel implementation", so leaving it until week 4 means reworking the week 1-3 boat code. Second, Gate 0's go/no-go (week 2) tests steering "on its own" without Jeff. So the main navigation aid is never tested together with steering until two weeks before the tester build. The schedule also has no buffer: week 5 is the only named spare-time slot, and it is already set aside for waves.

**Fix direction.** Move a minimal forecast/safe-route signal into week 2 or 3, and give week 4's scripted beats their own acceptance checks or push some to week 5.

---

## Finding 2: The full game has no schedule, estimate, or cut list beyond waves — MAJOR

**Problem.** The document plans the 10-minute prototype in detail (six weeks, weekly exit tests). After that it gives nothing. Gate 2 (Narrative alpha) and Gate 3 (Content and polish) have deliverables but no dates, durations or staffing. Yet the full-game scope adds several more repairs ("optic, rotation, fuel/fog signal, and stormproofing"), full outpost exploration, optional discoveries, final art, a full voiced cast ("Creator approves voice and lore before recording"), accessibility (remapping, subtitles with speaker attribution, a visual direction option, reduced-intensity preset), checkpoints, and a "finished Steam release flow."

**Why it matters.** Waves are the only feature with a stated cut rule ("the first thing cut if it slips"). The document names "scope creep across repairs, cinematics, and environmental detail" as the second-largest risk but gives no priority order for cutting inside those areas. Voice recording is mentioned with no source (actors, budget, or synthetic voice) and no licensing note, even though the Agent Strategy's rules require provenance. Final art for three locations plus modular set dressing, done solo, is also missing an asset count or estimate. The plan says Gate 0 and the slice "should decide whether the full game is feasible". But without a baseline estimate for Gates 2-3, there is nothing to measure the slice against.

**Fix direction.** Rough week ranges for Gates 2-3, a ranked cut list (for example repairs 4-5, optional discoveries, stormproofing), and an explicit plan for voice work.

---

## Finding 3: Open decisions block work that is already scheduled — MAJOR

**Problem.** Several decisions are marked as undecided, yet they sit directly on the Gate 1 critical path:

- **Engine.** It is "Proposed", with a Unity fallback ("If an existing Unity project or strong Unity experience changes this choice..."). Week 1 is project setup, so this has to be settled before day one. It is listed first in "settle the open decisions" but has no deadline.
- **Ted's presence.** The Agent Strategy says the creator must settle "Ted's presence". But Ted drives Step 1 ("Follow Ted's live guidance"), prompts the crash, and orders the gate to be opened, all inside the Gate 1 slice. If Ted is not physically present, the tutorial and crash-trigger design changes.
- **Fail-state follow-up.** "What follows the fail state (checkpoint retry or restart) is still to be decided." Gate 1 requires the fail outcome to be reachable, and the save contract says "save remaining time at checkpoints". But checkpoints are not scheduled until Gate 3. The save/deadline contract depends on a system scheduled two gates later.
- **Target hardware.** This is an open decision. Yet the Tech Strategy says "prototype rain and fog on target hardware before dressing the levels", and week 3 tunes storm visibility and lighting.

**Why it matters.** Under the Agent Strategy's own rule ("Ask when a canon choice is unresolved; do not silently decide it"), any agent working on these tasks will stall, or will build against a guess that later gets thrown away.

**Fix direction.** A decision log with a "needed by week N" date for each item. Decide checkpoint and retry behaviour before week 5, when the deadline is built.

---

## Finding 4: Deadline tuning and the 30-minute target can only be checked at the very end — MAJOR

**Problem.** "Set the duration from measured playtests so a first-time player who follows cues has room for some mistakes." The deadline is built in week 5, and the only planned playtests are "3-5 new players" in week 6, the same week as bug fixing and the tester build. The full-game outcome check ("A first-time playthrough lasts about 30 minutes") can only be tested at Gate 3 ("demonstrate ... the intended 30 minute pacing"). By then all the content exists.

**Why it matters.** The deadline is the game's only source of pressure, and the whole design depends on it ("The storm sets the clock"). It runs across two crossings, a search and a final climb and repair. Collision penalties, capsize recovery time, cargo-mishandling delays and outpost search time all eat into it, so the duration depends on every other tuning value. Three to five testers in the final week is too few to set one timer that all those values interact with. The document provides debug time scaling for QA but no early estimate of how the deadline should be split. There is also no check before Gate 3 that 10 minutes of prototype content will actually grow to 30 minutes of game.

**Fix direction.** Add a paper time budget per phase now. Start internal timing runs in week 4 or 5. Add a pacing checkpoint at Gate 2.

---

## Finding 5: The prototype's failure policy hides physics and character work that isn't in scope — MINOR

**Problem.** The document says waves are out of scope so that the hardest boat physics stays off the critical path ("keeping waves as a stretch goal removes the hardest part of that risk from the critical path"). But the *prototype* failure policy still requires collisions to add "water, slows the boat or causes a brief capsize-and-recovery at a nearby safe point", plus "cargo mishandling delays progress and creates a clear recovery interaction". Jeff is aboard throughout.

**Why it matters.** A capsize-and-recovery in first person, with an NPC companion and a physical cargo item aboard, is its own chunk of work. It needs a camera transition that respects "no cutaway or exterior cameras", Jeff repositioning and animating, burner state handling, and teleporting to a safe point. None of it appears in the week 1-2 exit tests, which cover only "collides reliably" and "recovery". The cargo-mishandling mechanic also has no defined design ("Proposed: keep the burner recoverable..."). So the Gameplay/Systems "cargo" deliverable has no spec to build against. None of this is blocking, but it is unestimated work sitting in the same weeks as the Gate 0 go/no-go.

**Fix direction.** For the prototype, make "slows the boat plus a brief stop" the only collision response. Defer capsize and cargo-mishandling to Gate 2, or estimate them separately.

---

### Overall

The prototype plan is unusually disciplined for a solo project. It has a hard Gate 0 go/no-go, waves properly isolated behind a toggle, and a clean state and event contract. The weak points are (1) the missing full-game timeline and cut list, (2) open decisions sitting on the Gate 1 critical path, and (3) a tuning dependency (the deadline) that can only be validated at the end. Nothing here is BLOCKING for the prototype. The full game's feasibility cannot be judged from this document as written.

---

## Round 2 — Cross-examination

### 1. CONFLICTS

**Systems Designer #1 and Adversarial QA #2 (the checkpoint time trap, both BLOCKING) against my Finding 3 (fail-state follow-up rated MAJOR).** We agree on what is wrong: the document plans to "save remaining time at checkpoints" and also requires "no dead-end save". Where I disagree is how much it blocks. For Gate 1 it does not. The prototype is a 10-minute slice, so "fail, then restart the slice" is a valid Gate 1 answer and costs almost nothing to build. The trap only becomes real once checkpoints exist, and the document schedules those for Gate 3. My view is that it blocks Gate 2's "no dead-end save" check, not the prototype. Where I agree with them is the fix: store a single run-start snapshot (or a snapshot at the start of each phase) instead of the live remaining time. That is the cheapest save model to build and to QA, and it removes the doomed-loop case without any floor logic, so it should be written down as the decision now. I keep MAJOR for the prototype. I would support BLOCKING for Gate 2 if the board wants a gate-specific rating.

**Narrative Critic #1 (Ted as an open decision, BLOCKING).** Four of us flagged Ted's presence: me, Narrative, QA #4 and Business #4. I still rate it below BLOCKING, because it is a decision, not a build problem. The creator can settle it in a day, and it becomes blocking only if it is still open at week 4. I also push back on part of the fix. Narrative wants Ted to speak in steps 6-8 and react to both outcomes. That adds voiced lines, and the document has no voice plan at all (my Finding 2: no source, budget, or licensing). From a scope point of view, each extra Ted beat is new voice-over cost with no known price. If Ted returns at the end, the board should require that it is done with lines he speaks from the lighthouse (a radio or the window), not new staging or animation.

**Player Psychologist #5 and Systems Designer #4 (add route choice, such as a shortcut on the return or "optional route unlock").** This pulls against my Finding 1. The shared hazard forecast is currently built around a single safe-route signal ("Jeff's calls read from the same safe-route signal"). A branching route would need that signal to handle alternatives, Jeff's lines for each branch, and a second hazard layout to tune. None of that fits a week 4 that is already overloaded. My position: no route branching in the prototype. For the full game, it could be a Gate 2 option only if the forecast API is designed for more than one route from the start. Systems #4's other suggestion, cutting the unused "unlocked routes" field from the save contract, is the cheaper choice, and I support it.

**Player Psychologist #3 (steering warm-up before the clock starts).** I only partly disagree. A sheltered harbour stretch is new level geometry. Starting the deadline once the player clears the harbour mouth is a trigger volume and almost free. I would specify the trigger version. Where I agree strongly is the testing gap it exposes: Gate 0 tests steering without pressure, which matches the problem I raised in Finding 1.

### 2. CONNECTIONS

**Adversarial QA #1 (fail state visible from anywhere) + my Finding 5 and Finding 4.** Put the "no cutaway or exterior cameras" rule together with a deadline that can run out in four phases, indoors or outdoors, and the fail state is no longer one scripted scene. It becomes up to four or more authored presentations, and the week 5 schedule ("deadline, fail state") budgets for one. The cheapest version that works is an audio-only fail (horn, then silence) followed by a first-person view from the lighthouse. That also sidesteps the sightline guarantee, which would otherwise constrain Level Layout across every location. This is unscheduled work in week 5, in the same slot as waves.

**Adversarial QA #3 (no stop, dock, or respawn rules for a boat with a fixed speed) + my Finding 5.** QA's finding shows that the gap I called MINOR is bigger than I said. Arrival and docking at the outpost and lighthouse, getting off the boat, burner pickup, and respawn orientation are not polish. They are the phase transitions (OUTBOUND to OUTPOST to RETURN) that the core state contract depends on, and none of them appears in any week's exit test. A fixed-speed boat also makes each of them a controller mode switch (cutting forward movement, handing control from the boat to walking), which is the kind of code that needs rework if it is added late.

**Systems Designer #2 (weather escalating with elapsed time causes a death spiral) + my Finding 4.** A feedback loop between lost time and difficulty makes the deadline's sensitivity nonlinear. Small changes to collision cost multiply into large changes in failure rate. That makes tuning from 3-5 testers in week 6 even less reliable than I said. Escalating by phase and route position only, as Systems proposes, also makes the timer tunable offline with a per-phase paper budget. I support that fix mainly on tuning grounds.

**Player Psychologist #2 (the clock punishes exploring the outpost) + Systems Designer #3 + my Finding 4.** The outpost search is the one timed phase whose length the designer cannot predict, and full outpost exploration is out of prototype scope. So the week 6 playtests will tune a deadline against an outpost that gets much bigger later. Every duration measured in the prototype is invalid as soon as Gate 2 adds exploration there. Moving optional discoveries to the time before boarding (Psychologist's fix) is also the fix that keeps prototype tuning data valid.

**Business Analyst #2 and Narrative Critic #3 (atmosphere and dread are never validated) + my Finding 3 (target hardware undecided).** The one tonal test that could be run cheaply is "rain and fog on target hardware", which the document already asks for. Target hardware is still an open decision, though, so it cannot be run. A single dressed room with final-quality fog and lighting, measured on a decided minimum spec, would test both the atmosphere risk and the performance risk at once. It could replace some of the week 4 scripting in the prototype.

**Business Analyst #5 (Daniel and the crash as decorative content) + my Finding 1.** This supports my week 4 overload point. Daniel's scripted walk-in is one of the five beats packed into week 4. Removing Daniel from the prototype, or keeping him off-screen, is the cheapest way to free up week 4 for the forecast work. I would add this to my Finding 1 fix. Business #3's point about the size of the AI agent process is also fair from my lens. Eight agent roles with handoffs make coordination a cost the six-week plan does not budget for.

### 3. REVISIONS

- **Finding 5: upgrade MINOR to MAJOR.** Given QA #3 and QA #1, the unspecified work is not just the capsize animation. It includes docking and arrival triggers, burner retrieval with a boat that cannot stop, respawn orientation, and fail presentations for each phase. All of these sit on the prototype's critical path and none are estimated. I am also retitling it in substance: "the prototype's failure and transition policies hide unestimated, critical-path work."
- **Finding 3: sharpen, keep MAJOR.** I split the fail-state item out. It needs a decision before week 5 (retry means restarting the slice for Gate 1, with a snapshot model for Gate 2), and it blocks Gate 2 if still open. Ted gets a "needed by week 3" deadline.
- **Finding 4: strengthened, keep MAJOR.** The death spiral (Systems #2) and the outpost's future growth (Psychologist #2) both make end-of-schedule tuning less reliable than I first said.
- **Overall verdict: slight revision.** I still find nothing BLOCKING for the six-week prototype as a build. But the prototype now carries a larger unscheduled workload than the week plan shows: the forecast API, the phase transitions, and the fail presentations. Week 5 is the only buffer and it is committed to waves, so waves should be cut before work starts, not "if it slips".
