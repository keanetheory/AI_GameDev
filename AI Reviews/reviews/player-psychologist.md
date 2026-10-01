# Player Psychologist — Round 1

Lens: what a first-time player actually experiences, minute by minute, across a ~30 minute single session.

---

## Finding 1 — Failing late is undefined and the player can't tell why they failed
**Severity: BLOCKING**

**Problem.** The fail state happens at the very end of the run (step 7/8, roughly minutes 20-30), and the document hasn't decided what happens next. If failing means a full restart, the player has to replay 20+ minutes of repairs, the crash cutscene and two crossings to try again. In a 30 minute atmospheric game, that is where people quit and leave a negative review. It gets worse because the deadline is hidden. When the ship runs aground, the player has no way to tell whether they lost because of collisions, because they spent too long at the outpost, because they were slow fitting the burner, or because the timer was always tight. Pillar 4 promises the player "always knows ... why they failed", and the hidden timer combined with one lumped-together penalty (every mistake "consumes deadline time") can't deliver that. A loss the player can't explain feels arbitrary, not tragic.

**Source.** Tech Strategy, deadline: "What follows the fail state (checkpoint retry or restart) is still to be decided." Exec Summary, Pillar 4: "the player always knows what to do and why they failed." Deadline: "store a numeric internal time but display only the passenger ship's position/lights and weather cues." Step 8: "Fail: the ship runs aground."

**Why it matters to the player.** The fail ending is described as "consequential", but only for the ship. What it costs the player in replay time is unspecified. The retry policy decides whether the fail ending feels like a meaningful tragedy or like punishment. It should be settled before Gate 1 playtests, because the week-6 testers' reaction to failing depends entirely on it. The doc also needs some diegetic post-mortem so the player can see why they failed, for example Jeff or Ted saying "we lost too long on the rocks", or journal text reflecting the delays.

---

## Finding 2 — The invisible clock quietly punishes curiosity at the outpost
**Severity: MAJOR**

**Problem.** The outpost is where the folk-horror payoff lives: "log fragments, shrines, symbols, and subtly strange architecture". The full game promises "full outpost exploration" and "optional discoveries" there. But the deadline keeps running through "outpost search", and the player can't see it. This rewards exactly the wrong thing. The curious player who reads the environment closely, which is what the "small world, read closely" rule asks for, is the one most likely to fail, and nothing tells them the clock is the reason. The players who find the game's best content get the bad ending and blame the game. The players who rush get the good ending and never see the lore.

**Source.** Tech Strategy, deadline: "continue through playable crossings, outpost search, recoveries, and final repair." Exec Summary: "Before boarding, exploration has no ship deadline." Scope: "full outpost exploration, optional discoveries" (full game). Scope rule: "small world, read closely."

**Why it matters to the player.** Exploration is free before boarding and secretly costly after, and nothing in the world marks that switch. Either move the optional discoveries to the pre-boarding lighthouse and island, or budget exploration time into the deadline and signal it clearly (Jeff urging "leave it, we've no time"). Otherwise players will feel tricked.

---

## Finding 3 — The player first touches the boat after the clock has started
**Severity: MAJOR**

**Problem.** Repairs teach interaction ("Repair work teaches interaction"), but nothing before boarding teaches steering, which is the game's "central player skill". Boarding is what starts the deadline, so the first seconds a player ever spends steering the boat, with its fixed speed, one axis, and collisions that capsize it, are already costing them the ending. A new player's first collisions come from not knowing the controls yet, not from making choices, and the hidden timer silently counts them against the player. On top of that, the outbound crossing is at night, in a storm, with Jeff shouting directions, so the player is learning a control scheme, reading hazards and parsing spoken navigation all at once.

**Source.** Step 3: "Boarding starts the hidden passenger-ship deadline." Pitch: "The central player skill is steering a powered boat past rocks and other hazards." Step 1: "Repair work teaches interaction." Tech failure policy: collisions "slows the boat or causes a brief capsize-and-recovery ... these events consume deadline time."

**Why it matters to the player.** Unfair early losses are one of the most common reasons players quit. The document needs a safe steering warm-up, such as a sheltered harbour stretch before the deadline begins, or a deadline that starts once the player clears the harbour mouth. Failing that, the opening of the outbound route should carry no time cost. The Gate 0 test ("steering past hazards is fun on its own") doesn't cover this, because it tests the feel without the pressure. The two need testing together.

---

## Finding 4 — The stakes are never introduced to the player in-game
**Severity: MAJOR**

**Problem.** The whole motivation structure depends on the player caring about a passenger ship, and the gameplay sequence never shows the moment the player learns it exists. Steps 1-2 are about repairing the beacon and the rowboat crash. Ted's exposition is about the burner ("Ted explains that the burner must be collected"). The ship first shows up as a hidden mechanical deadline at boarding, and its fate is the ending. If the player doesn't know about the ship and its approach before they leave, Pillar 2 ("can the player feel time running out without any UI?") fails because nothing tells the player time is short at all. The pressure only works if the player knows who is at risk and can find the ship's lights on their own. The document also doesn't say whether the ship is visible from the outpost interior, during the burner pickup, or while climbing to the lamp. Those are all stretches with the timer running.

**Source.** Sequence table steps 1-3 (no ship introduction). Pillar 2: "pressure comes from the world (the approaching ship's lights ...)". Prototype check: "The ship's lights and position, seen in first person, communicate the stakes." Pillar 3: "guidance comes from Ted and Jeff, not markers."

**Why it matters to the player.** Dread needs a target. Add an explicit beat, before or at boarding, where Ted points out the ship's lights on the horizon and says what happens if the beacon stays dark. Also add a rule that the ship is periodically visible, or can be heard through the foghorn and ship-proximity audio, during every stretch where the deadline is running.

---

## Finding 5 — The player can't do anything about the pressure
**Severity: MINOR** (a risk to confirm in the week-6 playtests)

**Problem.** The boat has "one fixed speed" and "no throttle". The worsening storm tells the player to hurry, but they have no way to hurry. The only thing under their control is to avoid mistakes. With waves likely cut and the return trip being the same route with "denser hazards and lower visibility", the second crossing may feel like a harder repeat of the first rather than a new challenge. Pressure the player can't act on tends to feel like helplessness rather than tension. That can fit dread, but it can also read as "the game is playing itself". This is worth watching, not a defect yet. The one-control design is a deliberate legibility choice and it serves Pillar 4.

**Source.** Tech Strategy, boat: "one fixed speed and one player steering axis. The player steers but has no throttle." Step 6: "Steer back through a worsening storm, with denser hazards and lower visibility." Waves: "they are the first thing cut if it slips."

**Why it matters to the player.** Make sure the return crossing gives the player at least one meaningful choice, such as a riskier shortcut past the reef versus the long safe way round, signalled by Jeff. That would give the pressure an outlet without adding a second control. The week-6 tests should ask directly whether players felt the return was "new" or "the same, but harder".

---

## Round 2 — Cross-examination

### Conflicts

**vs. Adversarial QA #5 ("Frozen ship before boarding": keep the pre-boarding ship out of sight).** This runs straight into my Finding 4, which asks Ted to point out the ship's lights before or at boarding. QA is right that a ship frozen on the horizon for 20 minutes of untimed repairs breaks the fiction for an attentive player. But hiding it entirely until boarding leaves the player with no idea who they are racing for, and that is the worse failure. A frozen prop costs some immersion. A clock with no known stakes means nothing makes the player feel pressure. I would resolve it by making the reveal the moment the clock starts: the ship's lights first appear, and Ted names them, at the dock just before boarding. The frozen-ship problem goes away, and the player learns about the stakes at the exact moment they start to count. So QA's requirement ("out of sight before boarding") and mine ("introduced before the player leaves") can both be met, but only if the reveal is scripted at the boarding threshold. The document currently has no such beat.

**vs. Business Analyst #5 (Daniel and the rowboat crash are decorative and should be deferred).** From the player's side I disagree about the crash, though not about Daniel. The rowboat crash is the only pre-boarding moment that shows the player, first-hand, that boats die on these rocks tonight. That is the emotional primer for the passenger-ship stakes, which Narrative #4 and my Finding 4 both say are missing. If you cut the crash, the ending stakes lean even more on abstract strangers. What the crash lacks is a connection to the ship: the document never uses it to foreshadow the ship. That makes it a reason to rewrite the crash, not cut it. Daniel as a second body with no role I'll leave to Business and Narrative.

**vs. Systems Designer #4 (the first two-thirds is untimed and pressure-free).** This conflicts with my own Finding 2 fix. One of my two options was to "move the optional discoveries to the pre-boarding lighthouse and island." Systems shows that would make the imbalance worse: more untimed content in a front half that already carries roughly 20 of the 30 minutes. I concede the point (see Revisions). I still disagree that the untimed front half is automatically a flaw. Untimed repairs are where a first-time player learns to interact without penalty, and that is the one onboarding the document does get right. The question is the ratio, not whether untimed time exists.

**vs. Feasibility Lead #5 (prototype should use "slows the boat plus a brief stop" as the only collision response).** For production I agree, and a single consequence is more legible. But it means the week-6 testers never go through a first-person capsize-and-recovery, which is the most disorienting and frustrating penalty in the design. Gate 1 would then measure a friendlier game than the one that ships, and frustration data would come in too low. If capsize is deferred, the document should say that the Gate 1 fairness verdict does not cover it.

### Connections

- **Systems #2 (weather death spiral) + my Finding 3 (first steering happens under the clock).** Together these are worse than either one alone. A novice's first collisions happen in the first minute of the outbound crossing because they are still learning the controls. Under Systems' rule, those collisions push the weather forward, so the player who is least skilled at that moment gets denser hazards and lower visibility straight away. For a first-time player the spiral starts at the worst possible moment, before any skill exists. Putting a grace stretch at the harbour and escalating by route position only (Systems' fix) should be treated as one fix.
- **Adversarial QA #1 (fail can't be shown away from the lighthouse) + my Finding 1 (player can't tell why they failed).** QA's case goes further than mine. If time runs out while the player is inside the outpost or on the stairs, the player may not realise they have failed at all. They carry on to the lamp, fit the burner, and then see a wreck they had no chance to prevent. That is the most "cheated" moment a player can have. Fail presentation and fail explanation are the same design problem and need a single answer.
- **Systems #3 (invisible mistake budget; proposes fixed ship positions as milestones) + my Finding 4.** Systems' milestone fix only works if the ship can be seen or heard at each phase transition. That is the visibility rule my Finding 4 asks for and the document doesn't have. Without guaranteed sightlines or audio, the milestones do nothing.
- **Adversarial QA #5 (journal as pause exploit) + my Finding 2.** If the journal is diegetic, which Pillar 3 favours, the clock runs while the player reads their own objectives. The game then penalises the player for checking what to do, as well as for being curious. Either the journal pauses the clock and becomes an exploit, or it doesn't and becomes a trap. The player-friendly option is a diegetic journal that pauses, which also has to be chosen deliberately.
- **Narrative #1 (Ted vanishes after Step 2; his presence is an open decision) + my Findings 1 and 3.** Ted is the onboarding. Step 1's "live guidance" is the game's only tutorial. If Ted's presence changes, the first ten minutes lose their teacher. And since Ted has no second-half role, only Jeff can give the diegetic post-mortem I asked for in Finding 1. That puts the job of explaining failure on a character Narrative #2 says has no defined voice.
- **Feasibility #4 (3-5 testers in week 6 is too few, too late) + my Finding 5.** My Finding 5 was left as "confirm in week-6 playtests." Feasibility shows that plan isn't enough. Whether players feel helpless or tense under a fixed speed cannot be judged from 3-5 people in the bug-fix week.

### Revisions

- **Finding 4 upgraded MAJOR to BLOCKING.** Four other reviews quietly assume the player knows about the ship and can read it: Narrative #4 (unnamed victim), Systems #3 (ship positions as milestones), QA #1 (fail shown via the ship) and QA #5 (ship visibility before boarding). If the player never learns the ship exists, Pillar 2's pressure, the milestone fix and the fail ending all fail together. It is cheap to fix, but the impact is blocking.
- **Finding 1 stays BLOCKING, strengthened** by QA #1 and #2 and Systems #1. Doomed checkpoint loops are a quit trigger on top of the unexplained loss.
- **Finding 3 stays MAJOR, strengthened** by Systems #2. The combined issue is close to blocking for first-time players specifically.
- **Finding 2 recommendation revised.** I withdraw "move optional discoveries pre-boarding" as the preferred fix because of Systems #4. The preferred fix is to keep discoveries at the outpost, budget explicit exploration time into the deadline, and have Jeff signal diegetically when that budget is used up. Severity stays MAJOR.
- **Finding 5 stays MINOR but is partly absorbed** by Systems #3. The "can't act on pressure" feeling is the player-side experience of Systems' "the deadline is really a mistake budget." QA #3 (no defined docking or arrival) adds a concrete worry: a fixed-speed boat circling the outpost with no clear landing trigger is exactly where helplessness would show up. The playtest check should be moved earlier than week 6, following Feasibility #4.
