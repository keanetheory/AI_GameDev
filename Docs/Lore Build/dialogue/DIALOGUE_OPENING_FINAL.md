# Opening Dialogue: Steps 1-5

Status: `creator_picked`. The game's script ([data](../../../LightingTheStorm/data/dialogue/dialogue_opening.json)): the Opening Dialogue Crew's creator-picked lines (2026-10-15/16), the T50/T52 humour pass and the creator's edits since. Character pages: [Ted](characters/DIALOGUE_TED.md), [Arthur](characters/DIALOGUE_ARTHUR.md), [Daniel](characters/DIALOGUE_DANIEL.md).

*Creator walkthrough picks applied on 2026-10-15 to the live revised crew output, then the creator's story-beat order applied on 2026-10-16. Creator still approves voice and lore before recording.*

## Step 1: Arrive and feed the boiler

*Location:* Outside the lighthouse door, the hall, the basement engine room  
*Player does:* Wait outside until Ted opens the door, step into the lighthouse, then go down to the basement and shovel coal into the boiler until the gauge reaches working pressure.

### On `GAME_STARTED`
*New game begins OUTSIDE the lighthouse; Ted opens the door.*

- **TED** `TED_S1_01` (setting): "Hrmph. The new guy. Storm season, and they send me a money toff in shoes like that. In. Mind the gull, he's the landlord."  
  *delivery: Gruff, weary, dry. Ends on a cough.*
  *staging:* Isaac stands outside the lighthouse door in the wind; Ted opens it and looks him over.
  *note:* Introduces eclipse, storm season and the Saltgate. | Story-beat revision 2026-10-16 (creator canon: arrival outside, coal, sailors, then Ted finds the burner broken). | Plays when the player knocks (the one Ted line spoken with the player outside, creator 30 Oct 2026).

### On `LIGHTHOUSE_ENTERED`
*Player steps inside; after a beat Ted sends them to the boiler.*

- **TED** `TED_S1_03` (objective): "Boiler's cold and the beacon's starving. Hasn't eaten since the Pleistocene. Engine room, Isaac. Shovel coal. Quickly. It's sulking."  
  *delivery: Blunt, barking an order.*
  *requires:* player_inside
  *staging:* Inside the hall, after a beat. Ted points toward the basement stairs.
  *assist hint:* Go to the basement engine room and shovel coal into the boiler firebox until the gauge climbs.
  *note:* Creator pick, 2026-10-15. Canon and Review rules applied line by line; the other option in this group was dropped. | Story-beat revision 2026-10-16 (creator canon: arrival outside, coal, sailors, then Ted finds the burner broken).

### On `FIREBOX_APPROACHED`
*Player comes within reach of the firebox in the engine room (creator, 3 November 2026).*

- **TED** `TED_S1_04` (reaction): "That's the firebox. Feed it coal, mind your sleeves, and don't make eye contact. It holds grudges."  
  *delivery: Gruff, shouted down the stairwell.*
  *requires:* player_inside
  *note:* Creator, 2026-11-03: plays when the player is at the firebox (FIREBOX_APPROACHED), not on entering the engine room.
- **TED** `TED_S1_04b` (reaction): "Also, if you hear singing down there, that's the pipes. Don't sing back."  
  *delivery: Gruff, shouted down the stairwell.*
  *requires:* player_inside
  *note:* Creator, 2026-11-03: plays when the player is at the firebox (FIREBOX_APPROACHED), not on entering the engine room.

### On `COAL_LOADED_FIRST`
*First shovelful lands in the firebox.*

- **TED** `TED_S1_05` (reaction): "There she goes. Keep shovelling. The needle is a coward and only moves when watched."  
  *delivery: Snarky, muffled through the floor.*
  *requires:* player_inside
  *note:* Creator pick, 2026-10-15. Canon and Review rules applied line by line; the other option in this group was dropped.
- **TED** `TED_S1_05b` (reaction): "One shovel's worth. The old girl ate it and didn't even say thank you. Rude."  
  *delivery: Snarky, muffled through the floor.*
  *requires:* player_inside
  *note:* Creator pick, 2026-10-15. Canon and Review rules applied line by line; the other option in this group was dropped.

### On `COAL_LOADED_HALF`
*Steam gauge reaches roughly half.*

- **TED** `TED_S1_08` (reaction): "Gauge is waking up. Nobody tell it what year it is. It'll want its pension."  
  *delivery: Shouted, gruff.*
  *requires:* player_inside
  *note:* Creator pick, 2026-10-15. Canon and Review rules applied line by line; the other option in this group was dropped.

### On `BOILER_FED`
*Gauge reaches working pressure; the dynamo whines (the beacon stays dark).*

- **TED** `TED_S1_09` (objective): "Hear that dynamo whine? That's joy, that is. Or a mouse in the works. Either way, she lives, and I'm putting it in the log as a miracle."  
  *delivery: Gruff, a rare note of satisfaction.*
  *requires:* player_inside
  *note:* Story-beat revision 2026-10-16 (creator canon: arrival outside, coal, sailors, then Ted finds the burner broken).

### On `IDLE_STEP_1`
*Player has made no progress on step 1.*

- **TED** `TED_S1_I1` (nudge tier 1): "Standing there won't warm the boiler. I tried it for a whole winter. Boiler stayed cold. I got a cold."  
  *delivery: Dry, sarcastic.*
  *requires:* player_inside
- **TED** `TED_S1_I2` (nudge tier 2): "Basement, Isaac. Engine room. The coal's the big black heap. It's not a sleeping dog. Don't pet it."  
  *delivery: Impatient, louder.*
  *requires:* player_inside
- **TED** `TED_S1_I3` (nudge tier 3): "Engine room. Shovel. Firebox. In that order. I've written it on my hand in case I forget too."  
  *delivery: Flat, slow and clear, exasperated.*
  *requires:* player_inside
  *assist hint:* Go to the basement engine room, take the shovel and load coal into the firebox until the gauge climbs.
- **TED** `TED_S1_I4` (nudge tier 4): "I'll tell you what's down there: coal, a boiler, and my last shred of hope. Go and fetch all three."  
  *delivery: Flat, slow and clear, exasperated.*
  *requires:* player_inside
- **TED** `TED_S1_I5` (nudge tier 5): "I'm not angry, Isaac. I'm a lighthouse keeper. We don't get angry. We just glare, slowly, in a circle."  
  *delivery: Flat, slow and clear, exasperated.*
  *requires:* player_inside
- **TED** `TED_S1_I6` (nudge tier 6): "Go down the stairs. They're the ones that go down. Isaac, I believe in you, which is a first for me."  
  *delivery: Flat, slow and clear, exasperated.*
  *requires:* player_inside

## Step 2: Let the sailors in

*Location:* Lighthouse window, the path from the dock, the island gate  
*Player does:* Notice the moored rowboat, go down the path and open the island gate for the stranded sailors Arthur and Daniel. Daniel goes down to the basement and stays there.

### On `SAILORS_MOORED`
*Rowboat appears moored at the dock (no crash).*

- **TED** `TED_S2_01` (objective): "Rowboat at my dock. Two men in it, wetter than the sea itself, which I didn't think possible. Go and let them in at the island gate."  
  *delivery: Gruff, reluctantly charitable.*
  *requires:* player_inside
  *staging:* Ted at the window, wind rattling the glass.
  *assist hint:* Go to the island gate by the dock and open it for the stranded sailors.
  *note:* Creator pick, 2026-10-15. Canon and Review rules applied line by line; the other option in this group was dropped.

### On `WINDOW_LOOKED`
*Player looks out of the window at the dock.*

- **TED** `TED_S2_03` (reaction): "See them? Soaked and stranded. One of them's waving a sock like a flag of surrender. Gate's down the path. Go on."  
  *delivery: Grunting, gesturing.*
  *requires:* player_inside

### On `GATE_APPROACHED`
*Player reaches the island gate.*

- **ARTHUR** `ARTHUR_S2_02` (reaction): "Easy now, we mean no harm. Just cold and wet. And Daniel's been apologising to a seagull since the rowboat. Gate, please?"  
  *delivery: Wry, wary, hands raised.*
  *note:* Creator pick, 2026-10-15. Canon and Review rules applied line by line; the other option in this group was dropped.

### On `GATE_OPENED`
*Player opens the island gate.*

- **ARTHUR** `ARTHUR_S2_04` (reaction): "Good hands on that gate. Daniel, move. No, the other way. Quick, now."  
  *delivery: Frantic, slightly flustered.*
  *note:* Creator pick, 2026-10-15. Canon and Review rules applied line by line; the other option in this group was dropped.

### On `SAILORS_INSIDE`
*Arthur and Daniel reach the lighthouse hall.*

- **ARTHUR** `ARTHUR_S2_05` (reaction): "Ted, you old rock. Thought you'd be drowned by now. Or at least moss."  
  *delivery: Wry, warm underneath.*
  *note:* Proposal: Ted and Arthur relationship is TBD in lore.
- **TED** `TED_S2_04` (reaction): "Thought the same of you. Hrmph. Dry yourselves."  
  *delivery: Gruff, a cough hiding a smile.*
  *requires:* player_inside
  *note:* Proposal pairing with ARTHUR_S2_05. 'The boy' means Daniel.
- **TED** `TED_S2_04b` (reaction): "The boy can warm up downstairs. Boiler's finally working now it's fed. Don't tell it I said that. It's sensitive."  
  *delivery: Gruff, a cough hiding a smile.*
  *requires:* player_inside
  *note:* Proposal pairing with ARTHUR_S2_05. 'The boy' means Daniel.
- **ARTHUR** `ARTHUR_S2_06` (reaction): "I'll wait here until Daniel has settled in. He gets homesick in new buildings. He once cried at a staircase."  
  *delivery: Steady, a little weary, watching the stairwell.*
  *staging:* Arthur stands just inside the main door and stays there while Daniel goes down.
  *note:* Creator, 30 Oct 2026: Arthur waits just past the main door and says this once he is in. Plays after TED_S2_04. Passes the offline rules.

### On `BASEMENT_VISITED`
*Player comes down into the basement while Daniel is there; repeatable, one Daniel line per visit (creator, 3 November 2026).*

- **DANIEL** `DANIEL_OPT_02` (reaction): "Down here suits me fine. Did the walls just... never mind. Warm is good. I'm going to name the boiler Gary."  
  *delivery: Anxious, trailing off, forced cheer.*
  *requires:* player_and_daniel_in_basement
  *staging:* Daniel settles beside the boiler.
  *note:* Ambiguous hint only; never confirmed. | Creator pick, 2026-10-15. Canon and Review rules applied line by line; the other option in this group was dropped. | Creator, 2026-11-03: Daniel's line for the player's visit 1 to the basement (BASEMENT_VISITED, sequence daniel_basement); after the third visit he says nothing more.

### On `IDLE_STEP_2`
*Player has made no progress on step 2.*

- **TED** `TED_S2_I1` (nudge tier 1): "Those sailors won't dry themselves on my dock, Isaac. I checked. For an hour."  
  *delivery: Dry, impatient.*
  *requires:* player_inside
- **TED** `TED_S2_I2` (nudge tier 2): "The gate, Isaac. Down the path from the dock. One of them's started negotiating with the gate. He's not winning."  
  *delivery: Louder, irritated.*
  *requires:* player_inside
- **TED** `TED_S2_I3` (nudge tier 3): "Walk to the island gate and open it. Let them in. Before they start naming the rocks."  
  *delivery: Flat, slow and clear.*
  *requires:* player_inside
  *assist hint:* Walk to the island gate near the dock and open it to let the sailors in.
- **TED** `TED_S2_I4` (nudge tier 4): "I can hear them from here, and so can the fish. Isaac, the gate. It's a door that lives outdoors."  
  *delivery: Flat, slow and clear.*
  *requires:* player_inside

## Step 3: Fetch a new burner

*Location:* Lantern room, hall, dock, steam launch, the Saltgate quays  
*Player does:* Follow Ted up to the lantern room, where he finds the burner broken; then board the steam launch with Arthur, cross the Gullwater and pick up the replacement burner at the Saltgate quays.

### On `BEACON_STILL_DARK`
*Dynamo running but the beacon stays dark; Ted heads up to the lantern room.*

- **TED** `TED_S3_00` (objective): "Dynamo's running and still no light. Something's wrong up top. Lantern room, Isaac. With me. Let's see if we can't get this old girl glowing."  
  *delivery: Gruff and uneasy, looking up the stairs; the hum of the dynamo under him.*
  *requires:* player_inside
  *staging:* Ted at the foot of the tower stairs, looking up at the dark lantern.
  *assist hint:* Follow Ted up the tower stairs to the lantern room.
  *note:* Story-beat revision 2026-10-16 (creator canon: arrival outside, coal, sailors, then Ted finds the burner broken).

### On `LAMP_ROOM_ENTERED`
*Player follows Ted into the lantern room.*

- **TED** `TED_S1_10` (reaction): "Arc lamp's in the middle. Let's open her up. It's an examination, except only one of us knows what they're doing. No offence...actually, take offence, you'll get used to it."  
  *delivery: Shouted up the stairs, wheezing.*
  *requires:* player_inside
  *note:* Story-beat revision 2026-10-16 (creator canon: arrival outside, coal, sailors, then Ted finds the burner broken).

### On `BURNER_DIAGNOSED`
*Ted opens the arc lamp, finds the burner broken and says a new one is needed.*

- **TED** `TED_S1_11` (discovery): "Cracked clean through. The burner's finished. Hrmph. We need a new one."  
  *delivery: Low, grim, with a cough.*
  *requires:* player_inside
  *note:* Story-beat revision 2026-10-16 (creator canon: arrival outside, coal, sailors, then Ted finds the burner broken).
- **TED** `TED_S3_05` (discovery): "A passenger ship? Now? It's not in the log! Without the beacon she'll find the rocks. Go, Isaac! Take the boat, take the sailor, take a coat!"  
  *delivery: Shocked, then barking; shouted from the dock path.*
  *requires:* player_inside
  *note:* Creator pick, 29 Oct 2026; moved the same day: Ted names the ship in the lamp room straight after "The burner's finished", with the ship in view (creator order: coal, up to the lamp room, "the burner is busted", then the unplanned ship). Plays after TED_S1_11. Passes the offline rules.

### On `BURNER_BRIEFING`
*Player talks with Ted and Arthur in the hall.*

- **TED** `TED_S3_02` (objective): "No burner, no beacon. There's a spare at the Saltgate. Go with Arthur, Isaac. He knows the way. He's also the only one who knows where the boat keeps its feelings."  
  *delivery: Grim, urgent, coughing.*
  *requires:* player_inside
  *staging:* Ted in the lighthouse hall, lamplight swaying as the wind shakes the walls.
  *assist hint:* Board the steam launch with Arthur and cross the Gullwater to the Saltgate quays to fetch the replacement burner.
  *note:* Creator pick, 2026-10-15. Canon and Review rules applied line by line; the other option in this group was dropped. | Story-beat revision 2026-10-16 (creator canon: arrival outside, coal, sailors, then Ted finds the burner broken).

### On `BOARDING_THRESHOLD`
*Player reaches the launch at the dock.*

- **ARTHUR** `ARTHUR_S3_01` (reaction): "In you get. One hand on the wheel, eyes on the rocks. Not on me. I'm not a rock. Ask Ted."  
  *delivery: Wry, brisk, wary.*
  *note:* Creator pick, 2026-10-15. Canon and Review rules applied line by line; the other option in this group was dropped.

### On `SHIP_SIGHTED`
*Passenger ship's lights appear on the horizon.*

- **ARTHUR** `ARTHUR_S3_11` (discovery): "There! Ship's lights, out in the swell. She can't see the rocks. No beacon. She's about as lost as Daniel in a staircase."  
  *delivery: Hushed, tight, urgent.*
  *note:* Creator pick, 2026-10-15. Canon and Review rules applied line by line; the other option in this group was dropped.

### On `BOAT_CAST_OFF`
*Outbound crossing begins (untimed steering practice).*

- **ARTHUR** `ARTHUR_S3_03` (reaction): "Keep her off the rocks, Isaac. Watch the water, not the dark. The dark's just showing off."  
  *delivery: Frantic, shouting over the engine.*
  *note:* Creator pick, 2026-10-15. Canon and Review rules applied line by line; the other option in this group was dropped.

### On `ARTHUR_NEAR_1`
*Dialogue trigger fired by crossing_sequence.gd (not a GameState event): level 1 of the near-miss / collision lines.*

- **ARTHUR** `ARTHUR_S3_07` (reaction): "Too close! Give the rocks some room, Isaac. Plenty of time to hug them later."  
  *delivery: Sharp, breathless.*
  *note:* Creator pick, 2026-10-15. Canon and Review rules applied line by line; the other option in this group was dropped. | Now triggered by crossing_sequence.gd on every near miss, outbound or return, as level 1 of three that get more frantic (creator, 31 Oct 2026).

### On `ARTHUR_HIT_1`
*Dialogue trigger fired by crossing_sequence.gd (not a GameState event): level 1 of the near-miss / collision lines.*

- **ARTHUR** `ARTHUR_S3_08` (reaction): "Hold on! Swing wide of the rock. Gently now. It's had worse."  
  *delivery: Shouted, rattled but steady.*
  *note:* Creator pick, 2026-10-15. Canon and Review rules applied line by line; the other option in this group was dropped. Reworded from: "Hold on! Back her off the rock and steer clear. Gently now." | Now triggered by crossing_sequence.gd on a collision, outbound or return, as level 1 of three (creator, 31 Oct 2026).

### On `ARTHUR_NEAR_2`
*Dialogue trigger fired by crossing_sequence.gd (not a GameState event): Near miss, level 2 (worried).*

- **ARTHUR** `ARTHUR_NEAR_2` (reaction): "Careful, Isaac! Far too close. One of them winked at me!"  
  *delivery: Tight, worried, louder.*
  *note:* Creator, 31 Oct 2026: near-miss lines get more frantic each time.

### On `ARTHUR_NEAR_3`
*Dialogue trigger fired by crossing_sequence.gd (not a GameState event): Near miss, level 3 (frantic).*

- **ARTHUR** `ARTHUR_NEAR_3` (reaction): "Isaac! We'll be on the rocks! Steer away, steer away, now, now, now!"  
  *delivery: Frantic, near panic, shouted over the engine.*
  *note:* Level 3 repeats for every further near miss on the crossing.

### On `ARTHUR_HIT_2`
*Dialogue trigger fired by crossing_sequence.gd (not a GameState event): Collision, level 2 (alarmed).*

- **ARTHUR** `ARTHUR_HIT_2` (reaction): "Hold on, Isaac! She's taking a beating! Swing wide and steady her, quick! She's not even ours!"  
  *delivery: Alarmed, shouted.*
  *note:* Creator, 31 Oct 2026: three levels of concern.

### On `ARTHUR_HIT_3`
*Dialogue trigger fired by crossing_sequence.gd (not a GameState event): Collision, level 3 (desperate).*

- **ARTHUR** `ARTHUR_HIT_3` (reaction): "She won't take much more! Get clear and steer true! I'm too handsome to drown!"  
  *delivery: Desperate, hoarse.*
  *note:* Level 3 repeats for every further collision on the crossing.

### On `DOCKING_DIALOGUE`
*Dialogue trigger fired by crossing_sequence.gd (not a GameState event): Docking: hands off.*

- **ARTHUR** `ARTHUR_DOCK_01` (reaction): "Hands off now, you've done the steering, I'll bring her in while you get ready to jump. Try not to land on a fish."  
  *delivery: Steadying, calm, taking the wheel.*
  *note:* Creator, 31 Oct 2026 (DOCKING_DIALOGUE): plays every time the boat starts auto-docking, at the Saltgate and at the lighthouse. Wording is the creator's.

### On `DOCKING_DIALOGUE_LIGHTHOUSE_1`
*Dialogue trigger fired by crossing_sequence.gd (not a GameState event): Docking at the lighthouse after a rough return, level 1.*

- **ARTHUR** `ARTHUR_DOCK_L1` (reaction): "Hands off now. That was rough going, Isaac. I'll bring her in; you get ready to jump. We only brushed the sea once."  
  *delivery: Dry, a little pointed.*
  *note:* Replaces DOCKING_DIALOGUE at the lighthouse when the return had 1 collision (creator, 31 Oct 2026). Plays before "go go go".

### On `DOCKING_DIALOGUE_LIGHTHOUSE_2`
*Dialogue trigger fired by crossing_sequence.gd (not a GameState event): Docking at the lighthouse after a rough return, level 2.*

- **ARTHUR** `ARTHUR_DOCK_L2` (reaction): "Hands off! You nearly wrecked us out there, Isaac. I'll bring her in; be ready to jump. I owe a lot of apologies to them rocks!"  
  *delivery: Sharp, angry under the relief.*
  *note:* Replaces DOCKING_DIALOGUE at the lighthouse when the return had 2 or 3 collisions.

### On `DOCKING_DIALOGUE_LIGHTHOUSE_3`
*Dialogue trigger fired by crossing_sequence.gd (not a GameState event): Docking at the lighthouse after a rough return, level 3.*

- **ARTHUR** `ARTHUR_DOCK_L3` (reaction): "Hands off, for pity's sake! You hit everything out there! I'll bring her in, you just be ready to jump! The sea sent a strongly worded letter!"  
  *delivery: Furious, shouted.*
  *note:* Replaces DOCKING_DIALOGUE at the lighthouse when the return had 4 or more collisions.

### On `SALTGATE_REACHED`
*Boat docks at the Saltgate quays.*

- **ARTHUR** `ARTHUR_S3_04` (reaction): "There's the Saltgate quay. Fetch the burner. I'll keep the engine turning. Touch nothing you can't pronounce."  
  *delivery: Quick, tense.*
  *note:* Story-beat revision 2026-10-16 (creator canon: arrival outside, coal, sailors, then Ted finds the burner broken).

### On `BURNER_PICKED_UP`
*Replacement burner is aboard.*

- **ARTHUR** `ARTHUR_S3_05` (discovery): "That's it? Good. Hold it close. Back across we go. Don't sneeze on it."  
  *delivery: Relieved, still wary.*

### On `ARTHUR_RET_01`
*Arthur's call for SEG_01 (centre lane safe): played by crossing_sequence.gd when the boat passes route_m 0 (the crossing crew's forecast, data/world/return_crossing.json).*

- **ARTHUR** `ARTHUR_RET_01` (reaction): "Straight down the middle! It's a corridor!"  
  *delivery: Shouted over the engine and the storm, urgent.*
  *note:* From the Storm Crossing Crew's forecast (AIAgentCrew/output/return_crossing.json), added to the opening data for T10. Safe lane: centre.

### On `ARTHUR_RET_02`
*Arthur's call for SEG_02 (left lane safe): played by crossing_sequence.gd when the boat passes route_m 85 (the crossing crew's forecast, data/world/return_crossing.json).*

- **ARTHUR** `ARTHUR_RET_02` (reaction): "Left! Your left! The left one!"  
  *delivery: Shouted over the engine and the storm, urgent.*
  *note:* From the Storm Crossing Crew's forecast (AIAgentCrew/output/return_crossing.json), added to the opening data for T10. Safe lane: left.

### On `ARTHUR_RET_03`
*Arthur's call for SEG_03 (right lane safe): played by crossing_sequence.gd when the boat passes route_m 205 (the crossing crew's forecast, data/world/return_crossing.json).*

- **ARTHUR** `ARTHUR_RET_03` (reaction): "Bring her right! Right, now! Not wrong, right!"  
  *delivery: Shouted over the engine and the storm, urgent.*
  *note:* From the Storm Crossing Crew's forecast (AIAgentCrew/output/return_crossing.json), added to the opening data for T10. Safe lane: right.

### On `ARTHUR_RET_04`
*Arthur's call for SEG_04 (centre lane safe): played by crossing_sequence.gd when the boat passes route_m 325 (the crossing crew's forecast, data/world/return_crossing.json).*

- **ARTHUR** `ARTHUR_RET_04` (reaction): "Steady, middle! Don't you touch them! They bite!"  
  *delivery: Shouted over the engine and the storm, urgent.*
  *note:* From the Storm Crossing Crew's forecast (AIAgentCrew/output/return_crossing.json), added to the opening data for T10. Safe lane: centre.

### On `ARTHUR_RET_05`
*Arthur's call for SEG_05 (left lane safe): played by crossing_sequence.gd when the boat passes route_m 445 (the crossing crew's forecast, data/world/return_crossing.json).*

- **ARTHUR** `ARTHUR_RET_05` (reaction): "Hard left! Rocks to starboard! It's a rock convention!"  
  *delivery: Shouted over the engine and the storm, urgent.*
  *note:* From the Storm Crossing Crew's forecast (AIAgentCrew/output/return_crossing.json), added to the opening data for T10. Safe lane: left. Changed from 'Hard left, lad!' (canon: nobody calls the player lad).

### On `IDLE_STEP_3`
*Player has made no progress on step 3 (reaching the dock).*

- **ARTHUR** `ARTHUR_S3_I1` (nudge tier 1): "Ted wants that burner, Isaac. Boat's waiting on you. It's started tapping its foot."  
  *delivery: Wry, nudging.*
- **ARTHUR** `ARTHUR_S3_I2` (nudge tier 2): "Come on! The Saltgate, across the Gullwater. Get in the boat. It's sulking. Everything here sulks."  
  *delivery: Frantic, louder.*
- **ARTHUR** `ARTHUR_S3_I3` (nudge tier 3): "Board the boat, take the wheel, steer for the Saltgate quays. Go!"  
  *delivery: Flat, urgent, clear.*
  *assist hint:* Board the engine boat, steer across the Gullwater and land at the Saltgate quays to fetch the burner.

### On `IDLE_SALTGATE`
*Player has not found the burner at the Saltgate quays.*

- **ARTHUR** `ARTHUR_S3_O1` (nudge tier 1): "Burner won't walk to the boat, Isaac. I've asked it. Twice."  
  *delivery: Dry, calling from the landing.*
- **ARTHUR** `ARTHUR_S3_O2` (nudge tier 2): "Find the burner! Keep looking. Look sharp! Look blunt, if sharp isn't working!"  
  *delivery: Frantic, louder.*
- **ARTHUR** `ARTHUR_S3_O3` (nudge tier 3): "Find the burner, pick it up, and bring it to the boat."  
  *delivery: Flat, urgent, clear.*
  *assist hint:* Find the replacement burner, pick it up and bring it back to the boat.

## Step 4: Fit the burner

*Location:* Lighthouse dock, hall, tower stairs, lamp room  
*Player does:* Carry the burner up the tower and fit it into the arc lamp, with Ted waiting in the lamp room.

### On `RETURN_ARRIVED`
*Boat docks at the lighthouse jetty with the burner; Arthur says go, go, go.*

- **ARTHUR** `ARTHUR_S4_01` (reaction): "That's the jetty! Go, go, go. Don't you wait for me! I'll tie her up. Badly. Go!"  
  *delivery: Urgent, shouted, already stepping onto the jetty.*
  *note:* The crossing crew's arrival_line (AIAgentCrew/output/return_crossing.json), added to the opening data for T11. Plays before TED_S4_01.
- **TED** `TED_S4_01` (objective): "Bring the burner up here, Isaac! Don't you dare drop it! I've had a day, and it's only half over!"  
  *delivery: Shouted down the stairwell, hoarse, urgent.*
  *requires:* player_inside
  *staging:* Ted calls from the lamp room.
  *note:* Creator pick, 29 Oct 2026 (T16/T37). Passes the offline rules; not yet through a live Dialogue/Canon review. Plays after Arthur's "Go, go, go" arrival line.

### On `LAMP_ROOM_REENTERED`
*Player enters the lamp room carrying the burner, where Ted waits. Accepted 29 October 2026 (Decisions A17); the emitter is not built yet.*

- **TED** `TED_S4_03` (objective): "Socket's open! Burner in, Isaac. Quick but gentle. Finesse!"  
  *delivery: Urgent, quick, close beside Isaac at the lamp.*
  *requires:* player_inside
  *assist hint:* Fit the burner into the lamp socket.
  *note:* Creator pick, 29 Oct 2026 (T16/T37). Passes the offline rules; not yet through a live Dialogue/Canon review. Needs the new LAMP_ROOM_REENTERED event. | Creator, 2026-11-03: halved and made urgent (was: "Socket's open. Burner in, and be quick about it. Slowly, mind. She's old. Quick and slow, Isaac. It's called finesse.").

### On `BURNER_FITTED`
*Player fits the burner into the arc-lamp socket.*

- **TED** `TED_S4_06` (reaction): "That's the burner home. Stand back, Isaac. Give her room to wake. She's not a morning person."  
  *delivery: Gruff, hushed.*
  *requires:* player_inside
  *note:* Creator pick, 29 Oct 2026 (T16/T37). Passes the offline rules; not yet through a live Dialogue/Canon review.

## Step 5: Resolution

*Location:* Lamp room and the sea  
*Player does:* Watch the ship pass the rocks safely (win) or run aground (fail).

### On `SHIP_WIN`
*Ship sails safely past the rocks; resolves once.*

- **TED** `TED_S5_02` (reaction): "She sees us! Look at her go, clear of the rocks. You did it, you money toff."  
  *delivery: Cracked, half-laughing.*
  *requires:* player_inside
  *note:* Creator pick, 29 Oct 2026 (T16/T37). Passes the offline rules; not yet through a live Dialogue/Canon review.

### On `SHIP_FAIL`
*Ship runs aground on the rock; resolves once; the Failed screen follows.*

- **TED** `TED_F_01` (reaction): "No. No, turn! Turn, you fool, the rocks! Oh, no."  
  *delivery: Shouted, then a breaking whisper.*
  *requires:* player_inside
  *note:* Creator pick, 29 Oct 2026 (T16/T37). Passes the offline rules; not yet through a live Dialogue/Canon review. Reason line TED_F_03 follows once the creator has reworded it.
- **TED** `TED_F_03` (reaction): "That ship...we didn't get the burner out in time...those poor souls on board...we've failed...FAILED!!"  
  *delivery: Sorrowful, upset: grief breaking into anguish on the last word.*
  *requires:* player_inside
  *note:* Creator wording, 29 Oct 2026 (replaces the 19 Oct 'All is lost for those on board' line, canon FAIL_REASON_LINE). Plays after TED_F_01, then silence and the Failed screen. Pause 9 s so it starts as the ship strikes (about 13.6 s after SHIP_FAIL, after TED_F_01).

## Optional discoveries

### On `POSTER_EXAMINED`
*Optional: player examines a Flighted poster.*

- **TED** `TED_S0_13` (reaction): "Nothing there for us. Leave it be. The burner, the burner."  
  *delivery: Brusque, uneasy.*
  *requires:* burner_diagnosed
  *note:* Optional event; location-neutral. Gate: play only after BURNER_DIAGNOSED; read earlier, the line is dropped. Poster stays ambiguous. | Creator pick, 2026-10-15. Canon and Review rules applied line by line; the other option in this group was dropped. | Creator, 2026-11-03: Ted's line, not Arthur's (was ARTHUR_S0_13).

### On `BASEMENT_VISITED`
*Player comes down into the basement while Daniel is there; repeatable, one Daniel line per visit (creator, 3 November 2026).*

- **DANIEL** `DANIEL_OPT_06` (reaction): "Did you hear that? Tell me you heard that. Pipes, right? Say pipes."  
  *delivery: Anxious, breathless.*
  *requires:* player_and_daniel_in_basement
  *note:* Cause stays ambiguous. Optional event; basement only, after DANIEL_IN_BASEMENT. | Creator pick, 2026-10-15. Canon and Review rules applied line by line; the other option in this group was dropped. | Creator, 2026-11-03: Daniel's line for the player's visit 3 to the basement (BASEMENT_VISITED, sequence daniel_basement); after the third visit he says nothing more.
- **DANIEL** `DANIEL_OPT_04` (reaction): "Arthur says it's just weather. I'm sure Arthur's right. He's usually right. Mostly."  
  *delivery: Anxious chatter, nervous laugh.*
  *requires:* player_and_daniel_in_basement
  *note:* Optional event. Basement only, after DANIEL_IN_BASEMENT. | Creator pick, 2026-10-15. Canon and Review rules applied line by line; the other option in this group was dropped. | Creator, 2026-11-03: Daniel's line for the player's visit 2 to the basement (BASEMENT_VISITED, sequence daniel_basement); after the third visit he says nothing more.

## Objective journal (handwritten, Isaac's own words)

| ID | Step | Written on | Entry |
|---|---|---|---|
| `JRN_01` | 1 | `GAME_STARTED` | Ted has let me in. The beacon is starved: shovel coal into the boiler in the basement engine room until the gauge climbs. |
| `JRN_02` | 2 | `SAILORS_MOORED` | A rowboat is moored at the dock. Open the island gate and let the stranded sailors in. |
| `JRN_03` | 3 | `BURNER_BRIEFING` | Ted found the beacon's burner cracked. Cross the Gullwater with Arthur, fetch the replacement burner from the Saltgate quays, and bring it back. |

---
*Generated by `LightingTheStorm/tools/build_character_pages.py` from `data/dialogue/dialogue_opening.json`. Do not edit by hand.*
