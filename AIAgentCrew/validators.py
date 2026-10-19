"""Deterministic checks that enforce the game's contracts between agents.

These run as CrewAI task guardrails (so a failing agent gets the errors back and
retries) and again in the integrator before any game data is written.
"""
import json
import re

from pydantic import BaseModel, ValidationError

from canon import MAX_WORDS_PER_LINE, OPENING_EVENTS, PLAYER_TERM, SHIP_NAMED_FROM
from schemas import (CrossingBrief, DialogueBrief, HazardForecast, ArthurCallSheet, OpeningDialogue,
                     ReviewReport)

TIMER_WORDS = re.compile(r"\b(\d+\s*(sec|second|min|minute)s?|timer|countdown|clock)\b", re.I)


def extract_json(text: str) -> dict:
    """Pull the first JSON object out of an LLM reply (tolerates ``` fences and prose)."""
    text = re.sub(r"```(?:json)?", "", text)
    start, end = text.find("{"), text.rfind("}")
    if start == -1 or end <= start:
        raise ValueError("No JSON object found in the agent's answer.")
    return json.loads(text[start : end + 1])


def parse(text: str, model: type[BaseModel]):
    """Return (model_instance, None) or (None, error_message)."""
    try:
        return model.model_validate(extract_json(text)), None
    except (ValueError, ValidationError) as exc:
        hint = ""
        if isinstance(exc, ValueError) and not isinstance(exc, ValidationError):
            hint = (" Hint: the reply was not valid JSON. Use only single quotes inside text values, escape "
                    "any double quote with a backslash, and do not truncate the object.")
        return None, f"Output did not match the {model.__name__} contract: {exc}{hint}"


def check_brief(brief: CrossingBrief) -> list[str]:
    errs = []
    ids = [s.segment_id for s in brief.segments]
    expected = [f"SEG_{i:02d}" for i in range(1, len(ids) + 1)]
    if ids != expected:
        errs.append(f"Segment IDs must be sequential {expected}, got {ids}.")
    dens = [s.hazard_density for s in brief.segments]
    if any(b < a for a, b in zip(dens, dens[1:])):
        errs.append(f"hazard_density must never fall along the route (storm split rule); got {dens}.")
    widths = [s.route_width_m for s in brief.segments]
    if any(b > a for a, b in zip(widths, widths[1:])):
        errs.append(f"route_width_m must narrow or hold along the return crossing; got {widths}.")
    if "wave" in " ".join(brief.allowed_hazards).lower():
        errs.append("Wave hazards are a stretch goal and are not approved.")
    return errs


def check_forecast(fc: HazardForecast, brief: CrossingBrief) -> list[str]:
    errs = []
    brief_segs = {s.segment_id: s for s in brief.segments}
    if [s.segment_id for s in fc.segments] != list(brief_segs):
        errs.append(f"Forecast must cover exactly the brief's segments in order: {list(brief_segs)}.")
    counts = []
    for seg in fc.segments:
        sb = brief_segs.get(seg.segment_id)
        n = seg.segment_id[-2:]
        if seg.safe_point_id != f"SAFE_{n}":
            errs.append(f"{seg.segment_id}: safe_point_id must be SAFE_{n}.")
        for hz in seg.hazards:
            if not hz.hazard_id.startswith(f"HZ_{n}_"):
                errs.append(f"{hz.hazard_id}: hazard IDs in {seg.segment_id} must start HZ_{n}_.")
            if hz.lane == seg.safe_lane:
                errs.append(f"{hz.hazard_id} sits in the safe lane ({seg.safe_lane}) of {seg.segment_id}; "
                            "the single safe-route signal must be clear.")
            if hz.type not in brief.allowed_hazards:
                errs.append(f"{hz.hazard_id}: type '{hz.type}' not allowed by the brief.")
            if sb and hz.distance_m > sb.length_m:
                errs.append(f"{hz.hazard_id}: distance {hz.distance_m}m exceeds segment length {sb.length_m}m.")
        counts.append(len(seg.hazards))
        if not seg.hazards:
            errs.append(f"{seg.segment_id} has no hazards; every segment needs something to steer around.")
    if any(b < a for a, b in zip(counts, counts[1:])):
        errs.append(f"Hazard count per segment must not fall along the route (density rule); got {counts}.")
    return errs


def check_calls(sheet: ArthurCallSheet, fc: HazardForecast, brief: CrossingBrief) -> list[str]:
    errs = []
    safe = {s.segment_id: s.safe_lane for s in fc.segments}
    seen = {c.target_segment_id for c in sheet.calls}
    for seg_id in safe:
        if seg_id not in seen:
            errs.append(f"No Arthur call for {seg_id}; every segment needs one direction call.")
    for c in sheet.calls:
        if c.target_segment_id not in safe:
            errs.append(f"{c.call_id} targets unknown segment {c.target_segment_id}.")
            continue
        if c.call_id != f"ARTHUR_RET_{c.target_segment_id[-2:]}":
            errs.append(f"{c.call_id}: ID must be ARTHUR_RET_{c.target_segment_id[-2:]}.")
        if c.direction != safe[c.target_segment_id]:
            errs.append(f"{c.call_id} says '{c.direction}' but the forecast safe lane for "
                        f"{c.target_segment_id} is '{safe[c.target_segment_id]}'. Arthur must never disagree.")
        if c.lead_m < brief.arthur_call_lead_m:
            errs.append(f"{c.call_id}: lead_m {c.lead_m} is below the brief minimum {brief.arthur_call_lead_m}.")
        if not c.subtitle.upper().startswith("ARTHUR:"):
            errs.append(f"{c.call_id}: subtitle needs speaker attribution 'ARTHUR: ...'.")
        if len(c.line.split()) > 14:
            errs.append(f"{c.call_id}: line too long to shout over a storm (max 14 words).")
        if TIMER_WORDS.search(c.line):
            errs.append(f"{c.call_id}: mentions an explicit timer/countdown (breaks Pillar 2).")
    return errs


def check_review(report: ReviewReport) -> list[str]:
    errs = []
    failed = [c.check for c in report.pillar_checks + report.decisions_log_checks if c.result == "fail"]
    if report.verdict == "PASS" and failed:
        errs.append(f"Verdict is PASS but these checks failed: {failed}.")
    return errs


# ---------------- opening dialogue (Dialogue task) ----------------
# Reuses TIMER_WORDS and the "SPEAKER:" subtitle rule from check_calls, and adds the canon rules
# from the Exec Summary and the creator's decisions.
DEADLINE_WORDS = re.compile(r"\b(deadline|hours?|seconds?|minutes?)\b|\d", re.I)
GENDERED_ADDRESS = re.compile(r"\b(lad|lass|man)\b", re.I)
SUPERNATURAL = re.compile(r"\b(ghosts?|haunted|spirits?|curse[sd]?|monsters?|demons?|supernatural)\b", re.I)
SHIP_WORD = re.compile(r"\b(passenger ship|ship)\b", re.I)


def check_dialogue_brief(brief: DialogueBrief, max_words: int | None = None) -> list[str]:
    errs = []
    want = MAX_WORDS_PER_LINE if max_words is None else max_words
    if brief.max_words_per_line != want:
        errs.append(f"max_words_per_line must be {want} (the creator's limit), got {brief.max_words_per_line}.")
    canon_ids = [e[0] for e in OPENING_EVENTS]
    got = [e.event_id for e in brief.events]
    missing = [i for i in canon_ids if i not in got]
    extra = [i for i in got if i not in canon_ids]
    if missing or extra:
        errs.append("events must be exactly the game's event IDs from canon (the game reports these; do not "
                    f"invent or drop any). Missing: {missing[:12]}. Not allowed: {extra[:12]}.")
    if brief.player_term != PLAYER_TERM:
        errs.append(f"player_term must be '{PLAYER_TERM}' (creator decision), got '{brief.player_term}'.")
    if [s.step for s in brief.steps] != [1, 2, 3]:
        errs.append("steps must be 1, 2, 3 in order (arrival and coal, sailors, beacon and burner).")
    ids = [e.event_id for e in brief.events]
    if len(ids) != len(set(ids)):
        errs.append("event IDs must be unique.")
    for s in brief.steps:
        for ev in (s.starts_on, s.ends_on):
            if ev not in ids:
                errs.append(f"step {s.step} references unknown event {ev}.")
    if SHIP_NAMED_FROM not in ids:
        errs.append(f"events must include {SHIP_NAMED_FROM} (the ship is introduced there).")
    return errs


def check_dialogue(sheet: OpeningDialogue, brief: DialogueBrief) -> list[str]:
    errs = []
    events = {e.event_id: e for e in brief.events}
    order = [e.event_id for e in brief.events]
    ship_idx = order.index(SHIP_NAMED_FROM) if SHIP_NAMED_FROM in order else len(order)
    ids = [ln.line_id for ln in sheet.lines]
    for dup in sorted({i for i in ids if ids.count(i) > 1}):
        errs.append(f"{dup}: duplicate line_id.")
    journal_ids = {j.journal_id for j in sheet.journal}
    groups: dict[str, list] = {}
    for ln in sheet.lines:
        lid = ln.line_id
        if not lid.startswith(ln.speaker + "_"):
            errs.append(f"{lid}: ID prefix must match speaker {ln.speaker}.")
        if ln.speaker not in brief.speakers:
            errs.append(f"{lid}: speaker {ln.speaker} is not in the brief.")
        if ln.trigger not in events:
            errs.append(f"{lid}: unknown trigger {ln.trigger}.")
        elif ln.step != events[ln.trigger].step:
            errs.append(f"{lid}: step {ln.step} does not match event {ln.trigger}, which belongs to "
                        f"step {events[ln.trigger].step} (use step 0 for optional events).")
        if not ln.subtitle.upper().startswith(f"{ln.speaker}:"):
            errs.append(f"{lid}: subtitle needs speaker attribution '{ln.speaker}: ...'.")
        words = len(ln.text.split())
        if words > brief.max_words_per_line:
            errs.append(f"{lid}: {words} words (max {brief.max_words_per_line}).")
        if TIMER_WORDS.search(ln.text) or DEADLINE_WORDS.search(ln.text):
            errs.append(f"{lid}: timer, deadline or number in the text (breaks Pillar 2).")
        if re.search(r"\bapprentice\b", ln.text, re.I):
            errs.append(f"{lid}: refer to the player as '{brief.player_term}', not 'apprentice'.")
        if GENDERED_ADDRESS.search(ln.text):
            errs.append(f"{lid}: do not address the player as lad, lass or man.")
        if re.search(r"\blamp head\b", ln.text, re.I):
            errs.append(f"{lid}: say 'burner', not 'lamp head'.")
        if SUPERNATURAL.search(ln.text):
            errs.append(f"{lid}: confirms a supernatural cause; keep it ambiguous.")
        if SHIP_WORD.search(ln.text) and ln.trigger in order and order.index(ln.trigger) < ship_idx                 and not ln.trigger.startswith("IDLE"):
            errs.append(f"{lid}: names the ship before {SHIP_NAMED_FROM} (trigger {ln.trigger}).")
        if ln.kind == "nudge" and ln.tier is None:
            errs.append(f"{lid}: nudge lines need a tier.")
        if ln.journal_id and ln.journal_id not in journal_ids:
            errs.append(f"{lid}: journal_id {ln.journal_id} does not exist.")
        if ln.group:
            groups.setdefault(ln.group, []).append(ln)
    for g, members in groups.items():
        if len(members) < 2:
            errs.append(f"group {g}: needs at least two alternates.")
        if len({m.trigger for m in members}) != 1:
            errs.append(f"group {g}: alternates must share one trigger.")
    for ev in brief.events:
        evl = [ln for ln in sheet.lines if ln.trigger == ev.event_id]
        if ev.existing_crew_event:
            continue
        if not evl:
            errs.append(f"{ev.event_id}: no line plays on this event.")
        if ev.event_id.startswith("IDLE"):
            tiers = sorted(ln.tier or 0 for ln in evl)
            if tiers != list(range(1, len(tiers) + 1)) or len(tiers) < 2:
                errs.append(f"{ev.event_id}: nudge tiers must run 1..n with n >= 2, got {tiers}.")
    for s in brief.steps:
        objs = [ln for ln in sheet.lines if ln.step == s.step and ln.kind == "objective"]
        if not objs:
            errs.append(f"step {s.step}: needs at least one objective line.")
        elif not any(ln.assist_text for ln in objs):
            errs.append(f"step {s.step}: at least one objective needs assist_text.")
        if not any(j.step == s.step for j in sheet.journal):
            errs.append(f"step {s.step}: needs a journal entry.")
    if not any(brief.player_term.lower() in ln.text.lower() for ln in sheet.lines):
        errs.append(f"someone must call the player '{brief.player_term}' at least once.")
    for j in sheet.journal:
        if j.trigger not in events:
            errs.append(f"{j.journal_id}: unknown trigger {j.trigger}.")
        if TIMER_WORDS.search(j.text) or DEADLINE_WORDS.search(j.text):
            errs.append(f"{j.journal_id}: timer, deadline or number in the journal text.")
    return errs


def check_review_claims(report: ReviewReport, sheet: OpeningDialogue) -> list[str]:
    """A model reviewer's evidence is unverified text; reject counts that contradict the data."""
    errs = []
    n = len(sheet.lines)
    for c in report.pillar_checks + report.decisions_log_checks:
        for m in re.findall(r"(?:all|All)\s+(\d+)\s+lines", c.evidence):
            if int(m) != n:
                errs.append(f"check '{c.check[:40]}' says 'all {m} lines' but the dialogue has {n} lines.")
    return errs
