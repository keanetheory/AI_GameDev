# Opening dialogue data (Godot 4)

Ted, Arthur and Daniel lines for steps 1-3 of the Gate 1 slice, as data with stable IDs, in the same style as the Agent Crew's `return_crossing.json` (`ARTHUR_RET_*`). The steps follow the creator's story beats (2026-10-16, `AIAgentCrew/canon.py` `STORY_BEATS`):

1. **Arrive and feed the boiler.** The game starts outside the lighthouse; Ted opens the door (`GAME_STARTED`: "You're the new guy, then"). Inside, after a beat (`LIGHTHOUSE_ENTERED`), he sends Isaac down to shovel coal (`BOILER_FED` ends the step).
2. **Let the sailors in.** `SAILORS_MOORED` ... `GATE_OPENED` (the island gate on the path from the dock) ... `DANIEL_IN_BASEMENT`.
3. **Fetch a new burner.** `BEACON_STILL_DARK` (the dynamo runs, the light stays dark) -> `LAMP_ROOM_ENTERED` -> `BURNER_DIAGNOSED` (Ted finds the burner broken) -> `BURNER_BRIEFING` -> the crossing to `SALTGATE_REACHED` -> `BURNER_PICKED_UP` -> `RETURN_DEPARTED`, where the crossing crew's `ARTHUR_RET_*` calls take over.

Status is **creator_picked**: one line per moment, chosen by the creator. The lines rewritten for the story beats still need a review, and the creator approves voice and lore before recording.

| File | Purpose |
|---|---|
| `dialogue_opening.json` | The game data: speakers, steps, events, 40 lines, 3 journal entries |
| `../../scripts/dialogue/dialogue_loader.gd` | Plays lines when the game reports an event ID |
| `AIAgentCrew/apply_creator_picks.py` | Builds this JSON from the creator's picks in the story-beat order (`--install` writes it here) |
| `AIAgentCrew/main_dialogue.py` | Generates and validates dialogue through three CrewAI agents |
| `../../tools/build_illustration.py` | Draws the assignment illustration from the JSON |

The lines come from the **Opening Dialogue Crew** (`AIAgentCrew/main_dialogue.py`), whose guardrails reject any line that breaks a rule (over 22 words, a timer word or number, 'apprentice' instead of 'Isaac', an early mention of the ship, a broken nudge ladder and more), then the creator's picks. Rebuild this file with `python apply_creator_picks.py --install` in `AIAgentCrew/`. `tools/build_dialogue.py` is the superseded first draft script and needs `--force`.

## Using it in Godot 4

1. Copy `data/` and `scripts/` into the Godot project so the paths are `res://data/dialogue/dialogue_opening.json` and `res://scripts/dialogue/dialogue_loader.gd`.
2. Add a Node with `dialogue_loader.gd` (or register it as an autoload named `Dialogue`).
3. Connect the signals and report events from gameplay:

```gdscript
func _ready() -> void:
	Dialogue.line_started.connect(_on_line)              # show subtitle, play voice
	Dialogue.journal_entry_added.connect(_on_journal)
	Dialogue.assist_hint.connect(_on_hint)               # only fires when assist_mode is true
	Dialogue.trigger("GAME_STARTED")

func _on_line(line_id: String, speaker: String, subtitle: String, delivery: String) -> void:
	subtitle_label.text = subtitle

# elsewhere, when things happen:
Dialogue.trigger("BOILER_FED")
Dialogue.trigger("GATE_OPENED")
Dialogue.idle("IDLE_STEP_2")   # player stalled on step 2 -> next nudge tier
```

With `auto_advance` on, each line lasts an estimated reading time. For real voice audio, set it off and call `Dialogue.notify_audio_finished()` when the clip ends. Call `reset_for_restart()` for the Gate 1 "fail, then restart the slice" model.

## Line fields

`line_id`, `step` (0 = optional), `beat`, `speaker` (`TED`/`ARTHUR`/`DANIEL`), `kind`, `trigger` (event ID), `text`, `subtitle` (`"TED: ..."`), `delivery` (voice direction), `pause_before`, `once`. Optional: `group` (alternates: one is picked at random), `tier` (nudge level), `assist_text`, `journal_id`, `staging`, `note`.

## Not tested in the engine

The JSON is validated by the build script. `dialogue_loader.gd` has been run headless against this file (2026-10-16): the events fire their lines and journal entries. Nothing in the level reports the events yet.
