"""Deterministic checks that enforce the game's contracts between agents.

These run as CrewAI task guardrails (so a failing agent gets the errors back and
retries) and again in the integrator before any game data is written.
"""
import json
import re

from pydantic import BaseModel, ValidationError

from schemas import CrossingBrief, HazardForecast, JeffCallSheet, ReviewReport

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
        return None, f"Output did not match the {model.__name__} contract: {exc}"


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


def check_calls(sheet: JeffCallSheet, fc: HazardForecast, brief: CrossingBrief) -> list[str]:
    errs = []
    safe = {s.segment_id: s.safe_lane for s in fc.segments}
    seen = {c.target_segment_id for c in sheet.calls}
    for seg_id in safe:
        if seg_id not in seen:
            errs.append(f"No Jeff call for {seg_id}; every segment needs one direction call.")
    for c in sheet.calls:
        if c.target_segment_id not in safe:
            errs.append(f"{c.call_id} targets unknown segment {c.target_segment_id}.")
            continue
        if c.call_id != f"JEFF_RET_{c.target_segment_id[-2:]}":
            errs.append(f"{c.call_id}: ID must be JEFF_RET_{c.target_segment_id[-2:]}.")
        if c.direction != safe[c.target_segment_id]:
            errs.append(f"{c.call_id} says '{c.direction}' but the forecast safe lane for "
                        f"{c.target_segment_id} is '{safe[c.target_segment_id]}'. Jeff must never disagree.")
        if c.lead_m < brief.jeff_call_lead_m:
            errs.append(f"{c.call_id}: lead_m {c.lead_m} is below the brief minimum {brief.jeff_call_lead_m}.")
        if not c.subtitle.upper().startswith("JEFF:"):
            errs.append(f"{c.call_id}: subtitle needs speaker attribution 'JEFF: ...'.")
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
