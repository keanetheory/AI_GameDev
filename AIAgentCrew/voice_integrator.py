"""Writes the voice casting outputs. Nothing here calls ElevenLabs.

  voice_casting.json                    profiles + per-line tts text/settings
  VOICE_CASTING.md                      creator review sheet (voices, suggestions, per-speaker character counts)
  elevenlabs/voice_design_requests.json bodies for POST /v1/text-to-voice/design (one per speaker)
  elevenlabs/tts_requests.json          bodies for POST /v1/text-to-speech/{voice_id} (voice_id is a placeholder)
  handoffs/, run_log.json, HANDOFF.md
"""
import json
from pathlib import Path

from validators import check_review
from voice_validators import check_voice_plan


def final_checks(state):
    if not all(k in state for k in ("dialogue", "voice_plan", "voice_review")):
        return ["Pipeline incomplete."]
    return check_voice_plan(state["voice_plan"], state["dialogue"]) + check_review(state["voice_review"])


def write_outputs(state, out_dir, mode):
    problems = final_checks(state)
    if problems:
        return None, problems
    out = Path(out_dir)
    (out / "elevenlabs").mkdir(parents=True, exist_ok=True)
    (out / "handoffs").mkdir(exist_ok=True)
    plan, rev, dlg = state["voice_plan"], state["voice_review"], state["dialogue"]
    prof = {p.speaker: p for p in plan.profiles}
    src = {l.line_id: l for l in dlg.lines}
    status = "proposed" if rev.verdict == "PASS" else "needs_revision"
    chars = {sp: sum(len(src[l.line_id].text) for l in plan.lines if src[l.line_id].speaker == sp) for sp in prof}
    w = lambda path, obj: path.write_text(json.dumps(obj, indent=1), encoding="utf-8")
    w(out / "voice_casting.json", {
        "status": status, "mode": mode, "profiles": [p.model_dump() for p in plan.profiles],
        "lines": [dict(l.model_dump(), speaker=src[l.line_id].speaker) for l in plan.lines],
        "suggestions": plan.suggestions, "script_characters_by_speaker": chars})
    w(out / "elevenlabs" / "voice_design_requests.json", [
        {"speaker": p.speaker, "endpoint": "POST https://api.elevenlabs.io/v1/text-to-voice/design",
         "body": {"voice_description": p.voice_description, "text": p.preview_text, "model_id": p.design_model_id}}
        for p in plan.profiles])
    w(out / "elevenlabs" / "tts_requests.json", [
        {"line_id": l.line_id, "speaker": src[l.line_id].speaker,
         "endpoint": f"POST https://api.elevenlabs.io/v1/text-to-speech/<{src[l.line_id].speaker}_VOICE_ID>",
         "body": {"text": l.tts_text, "model_id": prof[src[l.line_id].speaker].tts_model_id,
                  "voice_settings": dict(prof[src[l.line_id].speaker].settings.model_dump(),
                                         **({"stability": l.stability} if l.stability is not None else {}))}}
        for l in plan.lines])
    (out / "handoffs" / "01_voice_plan.json").write_text(plan.model_dump_json(indent=1), encoding="utf-8")
    (out / "handoffs" / "02_voice_review.json").write_text(rev.model_dump_json(indent=1), encoding="utf-8")
    w(out / "run_log.json", state["log"])
    md = ["# Voice Casting: opening dialogue", "",
          f"Status: **{status}** (mode {mode}, verdict {rev.verdict}). Nothing has been sent to ElevenLabs. "
          "Approve each voice preview before generating lines.", ""]
    for p in plan.profiles:
        md += [f"## {p.speaker}: {p.role_category}",
               f"- {p.gender}, {p.age_band}, {p.accent}; timbre {p.timbre}, pace {p.pace}, energy {p.energy}",
               f"- Voice Design prompt: {p.voice_description}",
               f"- Contrast: {p.contrast_note}", f"- Canon basis: {'; '.join(p.canon_basis)}",
               f"- Settings: {p.settings.model_dump()} (design `{p.design_model_id}`, TTS `{p.tts_model_id}`)",
               f"- Script characters: {chars[p.speaker]}", ""]
    md += ["## Suggestions for the creator", *[f"- {s}" for s in plan.suggestions], "",
           "## Open creator decisions", *[f"- {d}" for d in plan.open_creator_decisions], "",
           "## Review", rev.handoff_summary,
           *[f"- {c.result.upper()}: {c.check}: {c.evidence}" for c in rev.pillar_checks + rev.decisions_log_checks], "",
           "## Guardrail log",
           *[f"- {e['task']} attempt {e['attempt']}: "
             f"{'PASS' if e['passed'] else 'BLOCKED: ' + ' | '.join(e['errors'])[:300]}" for e in state["log"]]]
    (out / "VOICE_CASTING.md").write_text("\n".join(md), encoding="utf-8")
    (out / "HANDOFF.md").write_text(
        f"# HANDOFF - voice casting\n\n{rev.handoff_summary}\n\nRegenerate: `python main_voice.py --out {out_dir}`\n\n"
        "Not verified: how any voice sounds; ElevenLabs v3 audio-tag and stability behaviour (audition first).\n",
        encoding="utf-8")
    return out, []
