# Opening Dialogue: Steps 1-3 (Gate 1 slice)

Status: **creator_picked**. Creator walkthrough picks applied (17 'pick one' groups, one line kept each) to the live revised crew output, then the 2026-10-16 story-beat order. Review below is deterministic, not a model review.

**Voice rules used:** Ted is gruff, snarky and old-school, calls city folk "new money toffs", and grunts and coughs. Arthur is wry, wiry and frantic under pressure. Daniel is light-hearted and anxious. The player, called Isaac, never speaks. Nothing mentions a timer, shows a marker or confirms a supernatural cause.

Lines reusing a canon sample line say so in their delivery note. There are no random alternates left: the creator chose one line per group.

## Step 1: Arrive and feed the boiler

*Location:* Outside the lighthouse door, the hall, the basement engine room  
*Player does:* Wait outside until Ted opens the door, step into the lighthouse, then go down to the basement and shovel coal into the boiler until the gauge reaches working pressure.

### On `GAME_STARTED`
*New game begins OUTSIDE the lighthouse; Ted opens the door.*

- **TED** `TED_S1_01` (setting): "Hrmph. You're the new guy, then. Storm season, and they send me a new money toff. In."  
  *delivery: Gruff, weary, dry. Ends on a cough.*
  *staging:* Isaac stands outside the lighthouse door in the wind; Ted opens it and looks him over.
  *note:* Introduces eclipse, storm season and the Saltgate. | Story-beat revision 2026-10-16 (creator canon: arrival outside, coal, sailors, then Ted finds the burner broken).

### On `LIGHTHOUSE_ENTERED`
*Player steps inside; after a beat Ted sends them to the boiler.*

- **TED** `TED_S1_03` (objective): "Boiler's cold and the beacon's starving. Down to the engine room. Shovel coal, Isaac."  
  *delivery: Blunt, barking an order.*
  *assist hint:* Go to the basement engine room and shovel coal into the boiler firebox until the gauge climbs.
  *staging:* Inside the hall, after a beat. Ted points toward the basement stairs.
  *note:* Creator pick, 2026-10-15. Canon and Review rules applied line by line; the other option in this group was dropped. | Story-beat revision 2026-10-16 (creator canon: arrival outside, coal, sailors, then Ted finds the burner broken).

### On `ENGINE_ROOM_ENTERED`
*Player enters the basement engine room.*

- **TED** `TED_S1_04` (reaction): "That's the firebox. Feed it coal, mind your sleeves, and don't stand gawping."  
  *delivery: Gruff, shouted down the stairwell.*

### On `COAL_LOADED_FIRST`
*First shovelful lands in the firebox.*

- **TED** `TED_S1_05` (reaction): "There she goes. Keep shovelling; the needle won't climb on good intentions."  
  *delivery: Snarky, muffled through the floor.*
  *note:* Creator pick, 2026-10-15. Canon and Review rules applied line by line; the other option in this group was dropped.

### On `COAL_LOADED_HALF`
*Steam gauge reaches roughly half.*

- **TED** `TED_S1_08` (reaction): "Gauge is waking up. Put your back into it."  
  *delivery: Shouted, gruff.*
  *note:* Creator pick, 2026-10-15. Canon and Review rules applied line by line; the other option in this group was dropped.

### On `BOILER_FED`
*Gauge reaches working pressure; the dynamo whines (the beacon stays dark).*

- **TED** `TED_S1_09` (objective): "Hear that dynamo whine? Good. Now we'll see if the old girl lights."  
  *delivery: Gruff, a rare note of satisfaction.*
  *note:* Story-beat revision 2026-10-16 (creator canon: arrival outside, coal, sailors, then Ted finds the burner broken).

### On `IDLE_STEP_1`
*Player has made no progress on step 1.*

- **TED** `TED_S1_I1` (nudge tier 1): "Standing there won't warm the boiler. Think where the heat comes from, Isaac."  
  *delivery: Dry, sarcastic.*
- **TED** `TED_S1_I2` (nudge tier 2): "Basement, Isaac. The engine room. Coal's piled by the firebox."  
  *delivery: Impatient, louder.*
- **TED** `TED_S1_I3` (nudge tier 3): "Go down to the engine room. Take the shovel. Load coal into the firebox."  
  *delivery: Flat, slow and clear, exasperated.*
  *assist hint:* Go to the basement engine room, take the shovel and load coal into the firebox until the gauge climbs.

## Step 2: Let the sailors in

*Location:* Lighthouse window, the path from the dock, the island gate  
*Player does:* Notice the moored rowboat, go down the path and open the island gate for the stranded sailors Arthur and Daniel. Daniel goes down to the basement and stays there.

### On `SAILORS_MOORED`
*Rowboat appears moored at the dock (no crash).*

- **TED** `TED_S2_01` (objective): "Rowboat's moored at my dock. Stranded sailors, by the look. Go let them in at the island gate."  
  *delivery: Gruff, reluctantly charitable.*
  *assist hint:* Go to the island gate by the dock and open it for the stranded sailors.
  *staging:* Ted at the window, wind rattling the glass.
  *note:* Creator pick, 2026-10-15. Canon and Review rules applied line by line; the other option in this group was dropped.

### On `WINDOW_LOOKED`
*Player looks out of the window at the dock.*

- **TED** `TED_S2_03` (reaction): "See them? Soaked and stranded. The gate's down the path from the dock. Go on."  
  *delivery: Grunting, gesturing.*

### On `GATE_APPROACHED`
*Player reaches the island gate.*

- **ARTHUR** `ARTHUR_S2_02` (reaction): "Easy now, we mean no harm. Just cold and wet. The gate, please?"  
  *delivery: Wry, wary, hands raised.*
  *note:* Creator pick, 2026-10-15. Canon and Review rules applied line by line; the other option in this group was dropped.

### On `GATE_OPENED`
*Player opens the island gate.*

- **ARTHUR** `ARTHUR_S2_04` (reaction): "Good hands on that gate. Daniel, move. Quick, now."  
  *delivery: Frantic, slightly flustered.*
  *note:* Creator pick, 2026-10-15. Canon and Review rules applied line by line; the other option in this group was dropped.

### On `SAILORS_INSIDE`
*Arthur and Daniel reach the lighthouse hall.*

- **ARTHUR** `ARTHUR_S2_05` (reaction): "Ted, you old rock. Thought you'd be drowned by now."  
  *delivery: Wry, warm underneath.*
  *note:* Proposal: Ted and Arthur relationship is TBD in lore.
- **TED** `TED_S2_04` (reaction): "Thought the same of you. Hrmph. Dry yourselves. The boy can warm up downstairs."  
  *delivery: Gruff, a cough hiding a smile.*
  *note:* Proposal pairing with ARTHUR_S2_05. 'The boy' means Daniel.

### On `DANIEL_IN_BASEMENT`
*Daniel reaches the basement and stays there.*

- **DANIEL** `DANIEL_OPT_02` (reaction): "Down here suits me fine. Did the walls just... never mind. Warm is good."  
  *delivery: Anxious, trailing off, forced cheer.*
  *staging:* Daniel settles beside the boiler.
  *note:* Ambiguous hint only; never confirmed. | Creator pick, 2026-10-15. Canon and Review rules applied line by line; the other option in this group was dropped.

### On `IDLE_STEP_2`
*Player has made no progress on step 2.*

- **TED** `TED_S2_I1` (nudge tier 1): "Those sailors won't dry themselves on my dock, Isaac."  
  *delivery: Dry, impatient.*
- **TED** `TED_S2_I2` (nudge tier 2): "The gate, Isaac. Down the path from the dock. Someone's shouting out there."  
  *delivery: Louder, irritated.*
- **TED** `TED_S2_I3` (nudge tier 3): "Walk to the island gate and open it. Let them in."  
  *delivery: Flat, slow and clear.*
  *assist hint:* Walk to the island gate near the dock and open it to let the sailors in.

## Step 3: Fetch a new burner

*Location:* Lantern room, hall, dock, steam launch, the Saltgate quays  
*Player does:* Follow Ted up to the lantern room, where he finds the burner broken; then board the steam launch with Arthur, cross the Gullwater and pick up the replacement burner at the Saltgate quays.

### On `BEACON_STILL_DARK`
*Dynamo running but the beacon stays dark; Ted heads up to the lantern room.*

- **TED** `TED_S3_00` (objective): "Dynamo's running and still no light. Something's wrong up top. Lantern room, Isaac. With me."  
  *delivery: Gruff and uneasy, looking up the stairs; the hum of the dynamo under him.*
  *assist hint:* Follow Ted up the tower stairs to the lantern room.
  *staging:* Ted at the foot of the tower stairs, looking up at the dark lantern.
  *note:* Story-beat revision 2026-10-16 (creator canon: arrival outside, coal, sailors, then Ted finds the burner broken).

### On `LAMP_ROOM_ENTERED`
*Player follows Ted into the lantern room.*

- **TED** `TED_S1_10` (reaction): "Arc lamp's in the middle. Let's open her up and see what's ailing her."  
  *delivery: Shouted up the stairs, wheezing.*
  *note:* Story-beat revision 2026-10-16 (creator canon: arrival outside, coal, sailors, then Ted finds the burner broken).

### On `BURNER_DIAGNOSED`
*Ted opens the arc lamp, finds the burner broken and says a new one is needed.*

- **TED** `TED_S1_11` (discovery): "Cracked clean through. The burner's finished. Hrmph. We need a new one."  
  *delivery: Low, grim, with a cough.*
  *note:* Story-beat revision 2026-10-16 (creator canon: arrival outside, coal, sailors, then Ted finds the burner broken).

### On `BURNER_BRIEFING`
*Player talks with Ted and Arthur in the hall.*

- **TED** `TED_S3_02` (objective): "No burner, no beacon. There's a spare at the Saltgate, across the Gullwater. Go with Arthur, Isaac."  
  *delivery: Grim, urgent, coughing.*
  *assist hint:* Board the steam launch with Arthur and cross the Gullwater to the Saltgate quays to fetch the replacement burner.
  *staging:* Ted in the lighthouse hall, lamplight swaying as the wind shakes the walls.
  *note:* Creator pick, 2026-10-15. Canon and Review rules applied line by line; the other option in this group was dropped. | Story-beat revision 2026-10-16 (creator canon: arrival outside, coal, sailors, then Ted finds the burner broken).

### On `BOARDING_THRESHOLD`
*Player reaches the launch at the dock.*

- **ARTHUR** `ARTHUR_S3_01` (reaction): "In you get. One hand on the wheel, eyes on the rocks."  
  *delivery: Wry, brisk, wary.*
  *note:* Creator pick, 2026-10-15. Canon and Review rules applied line by line; the other option in this group was dropped.

### On `SHIP_SIGHTED`
*Passenger ship's lights appear on the horizon.*

- **ARTHUR** `ARTHUR_S3_11` (discovery): "There! Ship's lights, out in the swell. She can't see the rocks. No beacon."  
  *delivery: Hushed, tight, urgent.*
  *note:* Creator pick, 2026-10-15. Canon and Review rules applied line by line; the other option in this group was dropped.

### On `BOAT_CAST_OFF`
*Outbound crossing begins (untimed steering practice).*

- **ARTHUR** `ARTHUR_S3_03` (reaction): "Keep her off the rocks, Isaac. Watch the water, not the dark."  
  *delivery: Frantic, shouting over the engine.*
  *note:* Creator pick, 2026-10-15. Canon and Review rules applied line by line; the other option in this group was dropped.

### On `OUTBOUND_NEAR_MISS`
*Boat clears a hazard narrowly.*

- **ARTHUR** `ARTHUR_S3_07` (reaction): "Too close! Give the rocks some room, Isaac."  
  *delivery: Sharp, breathless.*
  *note:* Creator pick, 2026-10-15. Canon and Review rules applied line by line; the other option in this group was dropped.

### On `OUTBOUND_COLLISION`
*Boat hits a hazard (recoverable).*

- **ARTHUR** `ARTHUR_S3_08` (reaction): "Hold on! Swing wide of the rock and steer clear. Gently now."  
  *delivery: Shouted, rattled but steady.*
  *note:* Creator pick, 2026-10-15. Canon and Review rules applied line by line; the other option in this group was dropped. Reworded from: "Hold on! Back her off the rock and steer clear. Gently now."

### On `SALTGATE_REACHED`
*Boat docks at the Saltgate quays.*

- **ARTHUR** `ARTHUR_S3_04` (reaction): "There's the Saltgate quay. Fetch the burner. I'll keep the engine turning."  
  *delivery: Quick, tense.*
  *note:* Story-beat revision 2026-10-16 (creator canon: arrival outside, coal, sailors, then Ted finds the burner broken).

### On `BURNER_PICKED_UP`
*Replacement burner is aboard.*

- **ARTHUR** `ARTHUR_S3_05` (discovery): "That's it? Good. Hold it close. Back across we go."  
  *delivery: Relieved, still wary.*

### On `IDLE_STEP_3`
*Player has made no progress on step 3 (reaching the dock).*

- **ARTHUR** `ARTHUR_S3_I1` (nudge tier 1): "Ted wants that burner, Isaac. Boat's waiting on you."  
  *delivery: Wry, nudging.*
- **ARTHUR** `ARTHUR_S3_I2` (nudge tier 2): "Come on! The Saltgate, across the Gullwater. Get in the boat."  
  *delivery: Frantic, louder.*
- **ARTHUR** `ARTHUR_S3_I3` (nudge tier 3): "Board the boat, take the wheel, steer for the Saltgate quays. Go!"  
  *delivery: Flat, urgent, clear.*
  *assist hint:* Board the engine boat, steer across the Gullwater and land at the Saltgate quays to fetch the burner.

### On `IDLE_SALTGATE`
*Player has not found the burner at the Saltgate quays.*

- **ARTHUR** `ARTHUR_S3_O1` (nudge tier 1): "Burner won't walk to the boat, Isaac."  
  *delivery: Dry, calling from the landing.*
- **ARTHUR** `ARTHUR_S3_O2` (nudge tier 2): "Find the burner! Keep looking. Look sharp!"  
  *delivery: Frantic, louder.*
- **ARTHUR** `ARTHUR_S3_O3` (nudge tier 3): "Find the burner, pick it up, and bring it to the boat."  
  *delivery: Flat, urgent, clear.*
  *assist hint:* Find the replacement burner, pick it up and bring it back to the boat.

## Optional discoveries

*Location:* Lighthouse and basement  
*Player does:* Unprompted reactions to the haunted-lighthouse details (Pillar 1).

### On `POSTER_EXAMINED`
*Optional: player examines a Flighted poster.*

- **ARTHUR** `ARTHUR_S0_13` (reaction): "Nothing there for us. Leave it be. The burner, the burner."  
  *delivery: Brusque, uneasy.*
  *note:* Optional event; location-neutral. Gate: play only once Arthur is present (after SAILORS_INSIDE). Poster stays ambiguous. | Creator pick, 2026-10-15. Canon and Review rules applied line by line; the other option in this group was dropped.

### On `WALL_WHISPER_HEARD`
*Optional: whisper in the lighthouse walls.*

- **DANIEL** `DANIEL_OPT_08` (reaction): "Don't listen to it. Wind makes all sorts of voices. Hum something. I'm humming."  
  *delivery: Whispered, nervous, half-laughing.*
  *staging:* Daniel in the basement, close to the wall.
  *note:* Ambiguous; never confirm a cause. Optional event. Gate: play only when the player is in the basement and DANIEL_IN_BASEMENT has fired; never elsewhere. | Creator pick, 2026-10-15. Canon and Review rules applied line by line; the other option in this group was dropped.

### On `BASEMENT_BANG`
*Optional: bang in the basement wall.*

- **DANIEL** `DANIEL_OPT_06` (reaction): "Did you hear that? Tell me you heard that. Pipes, right? Say pipes."  
  *delivery: Anxious, breathless.*
  *note:* Cause stays ambiguous. Optional event; basement only, after DANIEL_IN_BASEMENT. | Creator pick, 2026-10-15. Canon and Review rules applied line by line; the other option in this group was dropped.

### On `BASEMENT_TALK`
*Optional: player stands near Daniel.*

- **DANIEL** `DANIEL_OPT_04` (reaction): "Arthur says it's just weather. I'm sure Arthur's right. He's usually right. Mostly."  
  *delivery: Anxious chatter, nervous laugh.*
  *note:* Optional event. Basement only, after DANIEL_IN_BASEMENT. | Creator pick, 2026-10-15. Canon and Review rules applied line by line; the other option in this group was dropped.

## Objective journal (handwritten, Isaac's own words)

| ID | Step | Written on | Entry |
|---|---|---|---|
| `JRN_01` | 1 | `GAME_STARTED` | Ted has let me in. The beacon is starved: shovel coal into the boiler in the basement engine room until the gauge climbs. |
| `JRN_02` | 2 | `SAILORS_MOORED` | A rowboat is moored at the dock. Open the island gate and let the stranded sailors in. |
| `JRN_03` | 3 | `BURNER_BRIEFING` | Ted found the beacon's burner cracked. Cross the Gullwater with Arthur, fetch the replacement burner from the Saltgate quays, and bring it back. |

## Open creator decisions

1. Which lines are voiced is a cost decision for the creator; subtitles exist for every line.
2. Why Arthur and Daniel were on the water (smugglers?) remains open; no line states or implies a reason.
3. Ted and Arthur's relationship is TBD in the lore; the 'drowned by now' exchange (ARTHUR_S2_05, TED_S2_04) is a proposal only.
4. Arthur-knows-more thread: the picks DANIEL_OPT_04 ('Arthur says it's just weather') and ARTHUR_S0_13 (uneasy about the poster) together hint that Arthur knows about the Flighted. His link to them is undecided in the lore.
5. ARTHUR_S3_08 was reworded by the creator's pick (drops 'back her off', which implied a reverse control); needs a Dialogue agent and Canon re-review.
6. Story-beat revision (2026-10-16): TED_S1_01, TED_S1_09, TED_S1_10, TED_S1_11, TED_S3_02, ARTHUR_S3_04 and the new TED_S3_00 were rewritten to the creator's beat order; they need a Dialogue agent and Canon re-review before recording.
7. Fail-reason and outcome lines belong to the Story / Fail-State agent and are not written here.
8. Where the Flighted poster physically sits is still undecided; ARTHUR_S0_13 is location-neutral.

## Assumptions to confirm

1. Lore vs GDD: WORLD.md puts the ship reveal before the crossing; the GDD (1 Oct 2026) puts it at the boarding threshold. The brief follows the GDD.
2. The part is the 'burner' (creator canon, 2026-10-16; supersedes the lore's earlier 'arc lamp head').
3. Story order follows canon.STORY_BEATS (2026-10-16): arrival outside, coal, sailors, then Ted finds the burner broken, then the Saltgate crossing.
4. The engine room is assumed to be the basement (Daniel's shelter). Level Layout should confirm.
5. Decided by the creator: the player is 'Isaac'; Ted's position in steps 2-3 is fine as written.
6. Existing offline Arthur return-crossing lines (offline_llm.py) still say 'lad'; the dialogue checks would reject that for the player.
7. Step 1's coal is the only repair before the crossing; the burner fit at the end (beat 7) belongs to the Story / Fail-State agent.

*40 lines: Ted 19, Arthur 17, Daniel 4.*
