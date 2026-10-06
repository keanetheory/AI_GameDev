"""Offline smoke-test LLM.

Lets markers and the creator run the full CrewAI pipeline with no API key.
It answers each agent role with deterministic, contract-valid JSON built from the
previous agent's handoff (read from the shared `state`). The Dialogue Writer
deliberately makes one mistake on its first attempt so the guardrail feedback
loop (validator -> agent retry) is exercised on every offline run.

This is NOT the creative engine: run without --offline to use a real model.
"""
import json
from typing import Any

from crewai import BaseLLM

LANES = ["left", "centre", "right"]
CUES = {
    "rock": "black silhouette against white surf, lit by each beacon sweep",
    "reef": "line of breaking white water, audible hiss",
    "buoy": "red buoy light and clanging bell",
    "debris": "pale floating timber catching lightning",
}
JEFF = {
    "left": ["Hard left, lad! Rocks to starboard!", "Left! Get us left of that!"],
    "right": ["Bring her right! Right, now!", "Right, lad, right! Mind the reef!"],
    "centre": ["Hold her straight! Straight down the middle!", "Steady, middle! Don't you touch them!"],
}


class OfflineLLM(BaseLLM):
    model: str = "offline-scripted"
    state: dict = {}
    preset: str = "standard"
    segments: int = 5
    mistakes_made: int = 0

    def supports_function_calling(self) -> bool:
        return False

    def call(self, messages, tools=None, callbacks=None, available_functions=None,
             from_task=None, from_agent=None, response_model=None) -> Any:
        role = getattr(from_agent, "role", "") or ""
        text = json.dumps(messages) if not isinstance(messages, str) else messages
        if role == "Production Orchestrator":
            payload = self._brief()
        elif role == "Hazard Forecast Designer":
            payload = self._forecast()
        elif role == "Companion Dialogue Writer":
            payload = self._calls(corrected="Fix these contract violations" in text)
        else:
            payload = self._review()
        return "Thought: I now can give a great answer\nFinal Answer: " + json.dumps(payload)

    # -------- canned, contract-valid outputs --------
    def _brief(self):
        n = self.segments
        assist = self.preset == "assist"
        segs = []
        for i in range(n):
            t = i / max(n - 1, 1)
            segs.append({
                "segment_id": f"SEG_{i + 1:02d}",
                "length_m": 120,
                "hazard_density": round((0.15 if assist else 0.25) + t * 0.5, 2),
                "route_width_m": int(40 - t * (14 if assist else 22)),
                "min_visibility_m": int(90 - t * 30),
                "storm_note": ["Leaving the outpost lee; swell rising", "Open water; rain thickening",
                               "Rocks closing in; beacon dark ahead", "Narrows under Bracken Isle",
                               "Final run to the jetty; foghorn close"][min(i, 4)],
            })
        return {
            "task_id": "GATE1_RETURN_CROSSING", "crossing_id": "RETURN", "difficulty_preset": self.preset,
            "boat_speed_mps": 6.0, "jeff_call_lead_m": 40 if assist else 30,
            "allowed_hazards": ["rock", "reef", "buoy", "debris"], "segments": segs,
            "constraints": ["One fixed speed, one steering axis", "No waves (stretch goal)",
                            "One safe lane per segment; no branching",
                            "Density rises with route position, never elapsed time",
                            "Collisions recover to SAFE_<seg> with a time cost; burner never lost"],
            "open_creator_decisions": ["Exact collision time cost (loose for Gate 1)",
                                       "Deadline length after return-crossing playtest"],
        }

    def _forecast(self):
        brief = self.state["brief"]
        types = brief.allowed_hazards
        segs, k = [], 0
        for i, s in enumerate(brief.segments):
            safe = LANES[[1, 0, 2, 1, 0, 2, 1, 2][i % 8]]
            others = [l for l in LANES if l != safe]
            count = 1 + round(s.hazard_density * 4)
            hz = []
            for j in range(count):
                t = types[k % len(types)]; k += 1
                hz.append({"hazard_id": f"HZ_{i + 1:02d}_{j + 1:02d}", "type": t,
                           "lane": others[j % 2],
                           "distance_m": int((j + 1) * s.length_m / (count + 1)),
                           "readability_cue": CUES[t]})
            segs.append({"segment_id": s.segment_id, "safe_lane": safe,
                         "safe_point_id": f"SAFE_{i + 1:02d}", "hazards": hz})
        return {"forecast_id": "FC_RETURN_" + brief.difficulty_preset.upper(),
                "dock_zone_id": "DOCK_LIGHTHOUSE", "segments": segs}

    def _calls(self, corrected: bool):
        brief, fc = self.state["brief"], self.state["forecast"]
        calls = []
        for i, s in enumerate(fc.segments):
            direction = s.safe_lane
            if not corrected and i == 1 and self.mistakes_made == 0:
                direction = "left" if s.safe_lane != "left" else "right"  # deliberate first-draft error
            line = JEFF[direction][i % 2]
            calls.append({"call_id": f"JEFF_RET_{s.segment_id[-2:]}", "target_segment_id": s.segment_id,
                          "direction": direction, "lead_m": brief.jeff_call_lead_m + 5,
                          "line": line, "subtitle": f"JEFF: {line}"})
        if not corrected:
            self.mistakes_made += 1
        return {"calls": calls, "arrival_line": "That's the jetty! Go, go, go - don't you wait for me!"}

    def _review(self):
        fc, calls = self.state["forecast"], self.state["calls"]
        ids = ", ".join(c.call_id for c in calls.calls)
        p = lambda c, e: {"check": c, "result": "pass", "evidence": e}
        return {
            "verdict": "PASS",
            "pillar_checks": [
                p("1. The light must return", "Route ends at DOCK_LIGHTHOUSE; arrival line sends the player to the lamp."),
                p("2. The storm sets the clock", "No timer words in any line; urgency carried by storm notes and density."),
                p("3. Your hands, your eyes", f"Guidance is Jeff's voice only ({ids}); no markers."),
                p("4. Dread you can read", "Every hazard has a readability cue; one safe lane per segment."),
            ],
            "decisions_log_checks": [
                p("Storm split", "hazard_density rises with segment index only."),
                p("No waves", "allowed_hazards = rock, reef, buoy, debris."),
                p("Single safe route", f"{len(fc.segments)} segments, one safe_lane each."),
                p("Jeff never disagrees", "Every call direction equals its segment's safe_lane."),
                p("No visible timer", "Deadline is never referenced numerically."),
                p("Recoverable collisions", "Every segment has a SAFE_<seg> recovery point."),
            ],
            "issues": [],
            "open_creator_decisions": ["Exact collision time cost (loose for Gate 1)",
                                       "Deadline length after return-crossing playtest",
                                       "Creator to approve Jeff's voice before recording"],
            "handoff_summary": (f"Return-crossing data for Gate 1: {len(fc.segments)} segments, "
                                f"{sum(len(s.hazards) for s in fc.segments)} hazards, {len(calls.calls)} Jeff calls. "
                                "All contract checks pass. Feel, pacing and voice need creator playtesting."),
        }
