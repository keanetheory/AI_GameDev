"""Scripted model for the voice casting crew (no API key). Real agents, tasks and guardrails run; only the
text is scripted. The first Sound-agent attempt contains faults (a likeness comparison, a rewritten line) so
the guardrail feedback loop shows on every offline run. Not the creative engine: run without --offline."""
import json
from typing import Any

from crewai import BaseLLM

from voice_validators import CANON_VOICE

PROFILES = {
    "TED": dict(role_category="gruff old lighthouse master", gender="male", age_band="older",
                accent="rough British coastal, weathered", timbre="gravelly", pace="measured", energy="medium",
                voice_description="A gravelly older male voice in his late sixties with a rough coastal British accent, "
                "weathered by salt and tobacco. Gruff, dry and snarky, slow to warm up, with a rasp and an occasional "
                "cough. Speaks in short barking sentences.",
                settings=dict(stability=0.5, similarity_boost=0.8, style=0.3, speed=0.95, use_speaker_boost=True),
                canon_basis=["chr_ted voice_casting_notes: gravelly older male, coastal accent",
                             "chr_ted verbal_habits: grunts, coughs"],
                contrast_note="Lowest and slowest of the three; gravel and rasp where Arthur is reedy and Daniel bright."),
    "ARTHUR": dict(role_category="wry frantic sea guide", gender="male", age_band="older",
                   accent="coastal British, sailor's cadence", timbre="reedy", pace="brisk", energy="high",
                   voice_description="A wiry, old male voice, reedy and thin, with a coastal sailor's accent. Wry and "
                   "warm underneath, quick and frantic under pressure, voice cracking when he shouts over wind and an "
                   "engine.",
                   settings=dict(stability=0.35, similarity_boost=0.8, style=0.4, speed=1.05, use_speaker_boost=True),
                   canon_basis=["chr_arthur voice_casting_notes: wiry, old, frantic",
                                "chr_arthur speech_pattern: snarky, funny"],
                   contrast_note="Higher and faster than Ted, thin and reedy; older and more cracked than Daniel."),
    "DANIEL": dict(role_category="anxious young sailor", gender="male", age_band="young adult",
                   accent="soft coastal British, youthful", timbre="bright", pace="quick", energy="medium",
                   voice_description="A young male voice in his early twenties, bright and enthusiastic, soft coastal "
                   "accent. Light-hearted and chatty, with nervous laughs and a voice that thins and speeds up when "
                   "anxious.",
                   settings=dict(stability=0.4, similarity_boost=0.75, style=0.35, speed=1.05, use_speaker_boost=True),
                   canon_basis=["chr_daniel voice_casting_notes: young, enthusiastic male",
                                "chr_daniel speech_pattern: light-hearted, anxious"],
                   contrast_note="The only young voice: bright and quick, where Ted and Arthur are older."),
}
FAULT_LIKENESS = "Sounds like a famous Scottish actor, gravelly and older, coastal."


def _tags(delivery: str, speaker: str) -> tuple[list[str], list[str]]:
    d = delivery.lower()
    pre, post = [], []
    if "whisper" in d:
        pre.append("whispers")
    elif "hushed" in d or "quiet" in d:
        pre.append("hushed")
    elif "breathless" in d:
        pre.append("breathless")
    if "laugh" in d:
        post.append("nervous laugh" if speaker == "DANIEL" else "laughs")
    if "cough" in d:
        post.append("coughs")
    return pre[:1], post[:1]


def _stab(delivery: str) -> float:
    d = delivery.lower()
    if any(w in d for w in ("frantic", "shout", "sharp", "panic")):
        return 0.25
    if any(w in d for w in ("flat", "slow and clear")):
        return 0.8
    return 0.5


class OfflineVoiceLLM(BaseLLM):
    model: str = "offline-scripted-voice"
    state: dict = {}
    inject_errors: bool = True
    first_done: bool = False

    def supports_function_calling(self) -> bool:
        return False

    def call(self, messages, tools=None, callbacks=None, available_functions=None,
             from_task=None, from_agent=None, response_model=None) -> Any:
        text = json.dumps(messages) if not isinstance(messages, str) else messages
        payload = self._review() if "[TASK VOICE_CASTING_REVIEW]" in text else self._plan(text)
        return "Thought: I now can give a great answer\nFinal Answer: " + json.dumps(payload)

    def _plan(self, text: str):
        dlg = self.state["dialogue"]
        profiles = []
        for sp, p in PROFILES.items():
            own = [l.text for l in dlg.lines if l.speaker == sp]
            prev, i = "", 0
            while len(prev) < 100 and i < len(own):
                prev = (prev + " " + own[i]).strip()
                i += 1
            profiles.append(dict(p, speaker=sp, preview_text=prev, design_model_id="eleven_ttv_v3",
                                 tts_model_id="eleven_v3"))
        lines = []
        for l in dlg.lines:
            pre, post = _tags(l.delivery, l.speaker)
            t = " ".join([f"[{x}]" for x in pre] + [l.text] + [f"[{x}]" for x in post])
            lines.append({"line_id": l.line_id, "tts_text": t, "stability": _stab(l.delivery)})
        corrected = "Fix these contract violations" in text
        if self.inject_errors and not corrected and not self.first_done:
            profiles[0]["voice_description"] = FAULT_LIKENESS
            lines[0]["tts_text"] = "Hrmph. New apprentice, then. " + lines[0]["tts_text"]
        self.first_done = True
        return {"profiles": profiles, "lines": lines,
                "suggestions": ["Audition Ted first: his cough tags depend on v3 handling them well.",
                                "Consider a light filter on lines shouted across the Gullwater (a Sound agent mix "
                                "decision, not a voice change)."],
                "open_creator_decisions": [
                    "Which lines are voiced is a cost decision for the creator; character counts are in the report.",
                    "Creator approves each voice preview before any line is generated."]}

    def _review(self):
        plan = self.state["voice_plan"]
        p = lambda c, e: {"check": c, "result": "pass", "evidence": e}
        n = len(plan.lines)
        return {"verdict": "PASS",
                "pillar_checks": [
                    p("1. The light must return", "Ted's objective lines keep their meaning; only delivery tags were added."),
                    p("2. The storm sets the clock", f"No timer or number wording in the {n} tts_text lines or previews."),
                    p("3. Your hands, your eyes", "Guidance stays spoken by Ted and Arthur; voices carry no markers."),
                    p("4. Dread you can read", "Daniel's whisper and bang lines gain only tone tags; no cause is named."),
                ],
                "decisions_log_checks": [
                    p("Canon casting notes honoured", "; ".join(f"{k}: {v['source']}" for k, v in CANON_VOICE.items())),
                    p("No real-person likeness", "All three descriptions describe sound only."),
                    p("Script text unchanged", f"All {n} tts_text lines equal the script once tags are stripped."),
                    p("Voices distinct", "Timbre and pace differ for every pair of speakers."),
                ],
                "issues": [],
                "open_creator_decisions": plan.open_creator_decisions,
                "handoff_summary": f"Voice casting for 3 speakers and {n} lines. All deterministic checks pass. "
                                   "Nothing has been sent to ElevenLabs; the creator approves voices first."}
