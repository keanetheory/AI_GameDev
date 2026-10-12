# Opening dialogue data (Godot 4)

Ted, Jeff and Daniel lines for steps 1-3 of the Gate 1 slice, as data with stable IDs, in the same style as the Agent Crew's `return_crossing.json` (`JEFF_RET_*`). Status is **proposed**: the creator approves voice and lore before recording.

| File | Purpose |
|---|---|
| `dialogue_opening.json` | The game data: speakers, steps, events, 61 lines, 7 journal entries |
| `../../scripts/dialogue/dialogue_loader.gd` | Plays lines when the game reports an event ID |
| `Agent Crew/.../main_dialogue.py` | Generates and validates this JSON through three CrewAI agents |
| `../../tools/build_illustration.py` | Draws the assignment illustration from the JSON |

The JSON is written by the **Opening Dialogue Crew** (`Agent Crew/storm_crew/storm_crew/main_dialogue.py`), whose guardrails reject any line that breaks a rule (over 22 words, a timer word or number, 'apprentice' instead of 'the new guy', an early mention of the ship, a broken nudge ladder and more). Regenerate with `python main_dialogue.py --offline --godot-dir <this project>`. `tools/build_dialogue.py` is the superseded first draft script and needs `--force`.

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

`line_id`, `step` (0 = optional), `beat`, `speaker` (`TED`/`JEFF`/`DANIEL`), `kind`, `trigger` (event ID), `text`, `subtitle` (`"TED: ..."`), `delivery` (voice direction), `pause_before`, `once`. Optional: `group` (alternates: one is picked at random), `tier` (nudge level), `assist_text`, `journal_id`, `staging`, `note`.

## Not tested in the engine

The JSON is validated by the build script. `dialogue_loader.gd` follows the same patterns as `crossing_loader.gd` but has not been run in Godot, so check it on first import.
