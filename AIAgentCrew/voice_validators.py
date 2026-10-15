"""Deterministic checks for the voice casting plan (the guardrails of voice_crew.py)."""
import re

from canon import MAX_WORDS_PER_LINE  # noqa: F401  (kept for parity with other validators)
from schemas import OpeningDialogue
from validators import DEADLINE_WORDS, SUPERNATURAL
from voice_schemas import VoiceCastingPlan

TAG = re.compile(r"\[([^\]]+)\]")
ALLOWED_TAGS = {"coughs", "grunts", "clears throat", "whispers", "shouts", "sighs", "exhales", "gasps",
                "laughs", "nervous laugh", "breathless", "hushed", "muttering", "grumbling"}
MAX_TAGS_PER_LINE = 2
LIKENESS = re.compile(r"\b(sounds? like|in the style of|impression of|voice of|imitat\w*|reminiscent of|"
                      r"famous|celebrity|actor|actress)\b", re.I)

# Canon voice_casting_notes (Lore Build character files): words each description must carry.
CANON_VOICE = {
    "TED": {"gender": "male", "age": {"older", "elderly"}, "words": ["gravel", "coast"],
            "source": "chr_ted: 'gravelly older male, coastal accent'"},
    "ARTHUR": {"gender": "male", "age": {"older", "elderly"}, "words": ["wiry"],
               "source": "chr_arthur: 'wiry, old, frantic'"},
    "DANIEL": {"gender": "male", "age": {"young adult"}, "words": ["young", "enthusias"],
               "source": "chr_daniel: 'young, enthusiastic male'"},
}


def norm(s: str) -> str:
    return re.sub(r"\s+", " ", s).strip()


def strip_tags(s: str) -> str:
    return norm(TAG.sub("", s))


def check_voice_plan(plan: VoiceCastingPlan, dlg: OpeningDialogue) -> list[str]:
    errs: list[str] = []
    by = {p.speaker: p for p in plan.profiles}
    if sorted(by) != ["ARTHUR", "DANIEL", "TED"] or len(plan.profiles) != 3:
        errs.append("profiles must be exactly one each for TED, ARTHUR and DANIEL.")
    for sp, p in by.items():
        c = CANON_VOICE[sp]
        d = p.voice_description.lower()
        if not 20 <= len(p.voice_description) <= 1000:
            errs.append(f"{sp}: voice_description must be 20-1000 characters, got {len(p.voice_description)}.")
        if not 100 <= len(p.preview_text) <= 1000:
            errs.append(f"{sp}: preview_text must be 100-1000 characters (ElevenLabs limit), got {len(p.preview_text)}.")
        if LIKENESS.search(p.voice_description) or LIKENESS.search(p.contrast_note):
            errs.append(f"{sp}: describe the sound only; no real people, actors or 'sounds like' comparisons.")
        if p.gender != c["gender"] or p.age_band not in c["age"]:
            errs.append(f"{sp}: canon is {c['source']}; got {p.gender}, {p.age_band}.")
        miss = [w for w in c["words"] if w not in d]
        if miss:
            errs.append(f"{sp}: voice_description must carry the canon casting note ({c['source']}); missing {miss}.")
        if SUPERNATURAL.search(p.voice_description) or SUPERNATURAL.search(p.preview_text):
            errs.append(f"{sp}: no supernatural wording in voice text (never confirm a cause).")
        if DEADLINE_WORDS.search(p.preview_text):
            errs.append(f"{sp}: preview_text has timer/number words.")
        if not p.canon_basis or not p.contrast_note.strip():
            errs.append(f"{sp}: canon_basis and contrast_note are required.")
        own = [norm(x.text) for x in dlg.lines if x.speaker == sp]
        if not any(o in norm(p.preview_text) for o in own):
            errs.append(f"{sp}: preview_text must quote at least one of {sp}'s real script lines.")
    names = list(by.values())
    for i, a in enumerate(names):
        for b in names[i + 1:]:
            if (a.timbre.lower(), a.pace) == (b.timbre.lower(), b.pace):
                errs.append(f"{a.speaker} and {b.speaker} share timbre and pace; voices must be distinct.")
    # one voice per line, script text untouched
    src = {x.line_id: x for x in dlg.lines}
    got = [l.line_id for l in plan.lines]
    if len(got) != len(set(got)):
        errs.append("duplicate line_id in lines.")
    missing = [i for i in src if i not in got]
    extra = [i for i in got if i not in src]
    if missing or extra:
        errs.append(f"lines must cover exactly the dialogue's {len(src)} line IDs. Missing: {missing[:10]}. "
                    f"Unknown: {extra[:10]}.")
    for l in plan.lines:
        s = src.get(l.line_id)
        if not s:
            continue
        if strip_tags(l.tts_text) != norm(s.text):
            errs.append(f"{l.line_id}: tts_text must equal the script text once [tags] are removed (no rewriting).")
        tags = TAG.findall(l.tts_text)
        bad = [t for t in tags if t.lower() not in ALLOWED_TAGS]
        if bad:
            errs.append(f"{l.line_id}: tags not allowed {bad}; use only {sorted(ALLOWED_TAGS)}.")
        if len(tags) > MAX_TAGS_PER_LINE:
            errs.append(f"{l.line_id}: at most {MAX_TAGS_PER_LINE} tags per line.")
    return errs
