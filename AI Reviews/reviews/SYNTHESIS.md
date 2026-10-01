# Review Board Synthesis — *Lighting the Storm* (Compiled GDD, 29 Sept 2026)

Moderator synthesis of six reviews (systems-designer, narrative-critic, player-psychologist, feasibility-lead, adversarial-qa, business-analyst), Rounds 1–2. Every item below traces to those files; the moderator adds no critiques of their own.

---

## 1. Top 5 Issues (ranked by severity × confidence)

### #1 — What happens after a fail is undecided, and saving the remaining time at checkpoints produces unwinnable saves
**Severity:** BLOCKING
**Problem:** The document leaves the retry model open ("checkpoint retry or restart ... still to be decided") while proposing to "save remaining time at checkpoints". A player who reaches a checkpoint low on time reloads into a guaranteed fail. That breaks Gate 2's "no dead-end save" rule and the invariant that the outcome "resolves exactly once". Checkpoints are also scheduled for Gate 3, even though Gate 1 needs a fail-then-what answer.
**Flagged by:** systems-designer (#1, BLOCKING), adversarial-qa (#2, BLOCKING), player-psychologist (#1, BLOCKING), feasibility-lead (#3, MAJOR), narrative-critic (#4.2), business-analyst (Round 2 X2)
**Cross-examination:** STRENGTHENED. adversarial-qa widened it: combined with systems-designer's death spiral, the reload gives the weakest player the least time *and* the worst weather, so the save must also cover weather state. business-analyst added the commercial side: a full restart at minutes 20–30 happens inside Steam's refund window, at the moment the player is most annoyed. Four reviewers converged on the same fix, a run-start or phase-start time snapshot. feasibility-lead disputes BLOCKING for the prototype (see Disagreement A).

### #2 — The fail state can't be shown from where the deadline usually runs out, and the player can't tell why (or even that) they failed
**Severity:** BLOCKING
**Problem:** The deadline can run out mid-crossing, inside the outpost, or on the lighthouse stairs. But the fail is defined as the ship running aground "seen in first person" from the lighthouse, and cutaways are banned. The deadline is also hidden: with one fixed boat speed it works as an invisible count of allowed mistakes, which the ship's lights can't convey. Either way, Pillar 4's promise that the player "always knows ... why they failed" breaks.
**Flagged by:** adversarial-qa (#1, BLOCKING), player-psychologist (#1, BLOCKING), systems-designer (#3, MAJOR), narrative-critic (#4, BLOCKING after Round 2), feasibility-lead (Round 2 connection)
**Cross-examination:** STRENGTHENED. Combining adversarial-qa #1 with player-psychologist #2 turns it from an edge case into the common case: curious players are most likely to be in the outpost when time runs out, where there's no sightline to the ship. feasibility-lead notes this means up to four authored fail presentations, while week 5 budgets for one. systems-designer rejected adversarial-qa's "let the ship keep going" option because it creates a doomed run the player can't read. Audio-only (horn, then silence) was backed by feasibility-lead and systems-designer, and narrative-critic accepts it if chosen deliberately.

### #3 — The passenger ship, the game's only stakes, is never introduced in-game, and the ending it resolves has no human payoff
**Severity:** BLOCKING
**Problem:** No scene tells the player the ship exists or what happens if the beacon stays dark. It first appears as a hidden deadline at boarding. Nobody aboard is named, the aftermath of a fail is undecided, and Ted, Jeff and Daniel never react to either outcome. The whole pressure design (Pillar 2) and the "consequential ending" depend on the player knowing and caring about this ship.
**Flagged by:** player-psychologist (#4, BLOCKING after Round 2), narrative-critic (#4, BLOCKING after Round 2), business-analyst (Round 2 X4), adversarial-qa (#5 frozen-ship bullet, MAJOR if psychologist #4 is adopted)
**Cross-examination:** STRENGTHENED. Two reviewers raised it from MAJOR to BLOCKING. player-psychologist showed that four other findings depend on the ship being seen and understood: narrative-critic #4, systems-designer #3's milestones, and adversarial-qa #1 and #5. business-analyst added that the game currently has no pitch line, because a trailer can't sell stakes the game never sets up. The tension over pre-boarding visibility (adversarial-qa: out of sight or frozen) was resolved by player-psychologist and narrative-critic both proposing a reveal at the boarding threshold. adversarial-qa had already listed "showing it only at the boarding moment" as acceptable.

### #4 — Ted is essential to the design, but whether he is physically present is still undecided, and he vanishes after Step 2
**Severity:** BLOCKING (narrative-critic) / MAJOR (business-analyst, feasibility-lead, adversarial-qa)
**Problem:** Ted gives the repair guidance, prompts the crash view, orders the gate opened, and explains the errand. He is Pillar 3's answer to "no markers" and the game's only tutorial. Yet "Ted's presence" is listed as an open decision. Even with him confirmed, he has nothing to do in Steps 6–8, and the document never says why an experienced keeper sends a new apprentice into the storm.
**Flagged by:** narrative-critic (#1, BLOCKING), business-analyst (#4, MAJOR), feasibility-lead (#3, MAJOR), adversarial-qa (#4, MAJOR), player-psychologist (Round 2 connection: "Ted is the onboarding")
**Cross-examination:** SURVIVED. Four reviewers confirmed the diagnosis, but three rejected BLOCKING: it's one decision the creator can make in a day, and it becomes blocking only if still open by week 3–4 (see Disagreement E). adversarial-qa softened its own Ted point and redirected it to a related problem nobody else raised: rules marked "Proposed" are already enforced as invariants and gate criteria. narrative-critic's point that Ted has no role in the second half stands and was not contested.

### #5 — The hidden clock penalises the wrong players: weather that worsens with elapsed time, a clock running during first steering, and a clock running during outpost exploration
**Severity:** MAJOR
**Problem:** Collisions cost time, and weather escalates with elapsed time, so struggling players face denser hazards and worse visibility. That is a death spiral. The clock starts at boarding, so a novice's first learning collisions feed straight into it. It also keeps running through the outpost search, where the folk-horror content lives, so the curious player pays twice, in time and in harder weather on the return.
**Flagged by:** systems-designer (#2, MAJOR), player-psychologist (#2 and #3, MAJOR), feasibility-lead (Round 2 connection), adversarial-qa (Round 2 connection), narrative-critic (Round 2 connection), business-analyst (Round 2 X1)
**Cross-examination:** STRENGTHENED. systems-designer showed that three other choices feed the loop: the clock during learning, the clock during exploration, and the respawn rules. feasibility-lead showed the loop makes deadline tuning from 3–5 week-6 testers unreliable. narrative-critic and business-analyst independently found that the game's distinctive content sits exactly where the clock punishes engaging with it, so rushing players finish without seeing the hook. How to fix the weather driver and where to put the discoveries remain disputed (Disagreements B and D).

---

## 2. Unresolved Disagreements

### A. Is the retry/checkpoint trap BLOCKING for the prototype, or only for Gate 2?
- **systems-designer, adversarial-qa, player-psychologist:** BLOCKING now. The Gate 1 slice has to reach both outcomes, and a Gate 1 acceptance criterion that depends on a Gate 3 system means the prototype can't pass its own gate (adversarial-qa). Playtesters can't judge fairness with no retry model (systems-designer).
- **feasibility-lead:** MAJOR for the prototype, BLOCKING for Gate 2. "Fail, then restart the slice" is a valid, nearly free Gate 1 answer for a 10-minute build. The trap only becomes real once checkpoints exist.
- **Common ground:** all agree on the snapshot fix.
- **Escalated decision:** Does Gate 1 accept "restart the slice" as its retry model, or must the final retry and save model be settled before the prototype is built?

### B. What should drive storm escalation?
- **systems-designer (backed by feasibility-lead and player-psychologist):** escalate by phase and route position only, or cap the share driven by elapsed time. Otherwise the loop punishes struggling players twice and can't be tuned offline.
- **narrative-critic:** tying weather only to position breaks Pillar 2 ("The storm sets the clock"). A struggling and a skilled player would see the same sky at the same rock, and the world would stop reporting lateness. The proposal is to split the channel: the *readable* storm (sound, lightning, wind, ship lights) follows elapsed time, and *hazard density* follows phase and position.
- **Escalated decision:** Does elapsed time drive anything the player *collides with*, or only what the player *perceives*?

### C. Should the return crossing branch into a riskier shortcut?
- **player-psychologist (#5) and systems-designer (Round 2):** yes. It gives the pressure an outlet without a second control, gives repairs a mechanical output, uses the dead "unlocked routes" field, and adds replay value. systems-designer rates it MAJOR in combination.
- **feasibility-lead:** no branching in the prototype. The hazard forecast is built around one safe-route signal, and week 4 is already overloaded. The cheaper answer is to cut the unused save field.
- **adversarial-qa:** at fixed speed, a survivable shortcut is always optimal. It breaks the singular safe-route signal behind Jeff's calls and doubles the tuning load.
- **business-analyst:** defer to Gate 2 and put it on the ranked cut list.
- **Escalated decision:** Commit to route choice, which means designing the forecast API for multiple routes from day one, or remove "unlocked routes" from the save contract?

### D. Where should the optional folk-horror discoveries live?
- **business-analyst, feasibility-lead:** move them before boarding, to the lighthouse and island. That removes the time penalty on the game's distinctive content, keeps prototype tuning data valid (the outpost won't grow after week 6), and reuses environments that already have to be built. narrative-critic partly agrees: the core of the wrongness can live in the lighthouse if it's tied to *why the beacon failed*.
- **player-psychologist (who withdrew this fix in Round 2), citing systems-designer #4:** moving more untimed content into a front half that already holds about 20 of the 30 minutes makes the pacing imbalance worse. The preferred fix is to keep discoveries at the outpost, budget explicit exploration time, and have Jeff signal when it's used up.
- **Escalated decision:** Protect the atmosphere by moving discoveries into the untimed act, or protect pacing by keeping them in the timed act with a budgeted allowance?

### E. How severe is Ted's open status, and should he return in the second half?
- **narrative-critic:** BLOCKING. Beyond the open decision, Ted has no arc after Step 2. He should be at the lamp for the climax and react to both outcomes.
- **business-analyst, feasibility-lead, adversarial-qa:** MAJOR with a "needed by" date (week 3 per feasibility-lead, before week 4 per business-analyst). feasibility-lead warns that every added Ted beat is unpriced voice-over cost, and would allow only lines delivered from the lighthouse (radio or window). business-analyst proposes spending the ending's human payoff on Ted and folding Daniel into Jeff.
- **Escalated decision:** Lock Ted's presence by a fixed week, and decide whether his second-half role is a staged scene or voice-only lines.

---

## 3. Quick Wins

1. **Replace "save remaining time at checkpoints" with a run-start or phase-start time snapshot**, and reword the invariant to "resolves exactly once per attempt." This removes the doomed-save loop with no floor logic. *(systems-designer, adversarial-qa, feasibility-lead, business-analyst)*
2. **Start the deadline when the player clears the harbour mouth, not on boarding.** It's one trigger volume that gives a free steering warm-up and removes the earliest input to the death spiral. *(player-psychologist #3; feasibility-lead and business-analyst specified this near-zero-cost version)*
3. **Script the ship reveal at the boarding threshold.** Ted names the ship's lights as the reason for the errand. This introduces the stakes, starts the clock on a story beat, and removes the frozen-ship window. *(player-psychologist, narrative-critic; compatible with adversarial-qa #5)*

---

## 4. Verdict

This document is not ready to drive full production, and its prototype is not ready to test fairly until the fail loop is defined. The board found the prototype plan unusually disciplined (feasibility-lead): a hard Gate 0 go/no-go, waves isolated behind a toggle, and a clean state contract. But the only failure system in the game has no decided retry model, no way to be shown where it usually triggers, no way for the player to read why it happened, and no introduced stakes for it to resolve. Five of six reviewers independently landed on some part of that loop. Beyond the prototype, feasibility-lead and business-analyst agree that "the full game's feasibility cannot be judged from this document as written," because there is no schedule, estimate or cut list past week 6. The single change that matters most is to write the fail-state contract before week 5: what the player perceives when the deadline expires in each phase, how the world tells them why, and what a retry restores (a run-start or phase-start snapshot). Issues #1, #2 and #3 all depend on that one decision.
