"""Pydantic contracts for every handoff in the Storm Crossing Crew.

Each agent's output is validated against one of these models before the next
agent is allowed to start. The models mirror the hazard-forecast interface and
stable-ID rules in the Lighting the Storm Technical Strategy.
"""
from typing import Literal

from pydantic import BaseModel, Field

Lane = Literal["left", "centre", "right"]
HazardType = Literal["rock", "reef", "buoy", "debris"]  # no waves: stretch goal, not approved
CheckResult = Literal["pass", "fail"]


# ---------- Agent 1: Production Orchestrator -> CrossingBrief ----------
class SegmentBrief(BaseModel):
    segment_id: str = Field(pattern=r"^SEG_\d{2}$")
    length_m: int = Field(ge=40, le=400)
    hazard_density: float = Field(ge=0.0, le=1.0, description="Hazard channel: phase + route position only")
    route_width_m: int = Field(ge=8, le=60)
    min_visibility_m: int = Field(ge=20, description="Hazards must stay readable at this range")
    storm_note: str


class CrossingBrief(BaseModel):
    task_id: str
    crossing_id: Literal["RETURN"]
    difficulty_preset: Literal["assist", "standard"]
    boat_speed_mps: float = Field(gt=0, description="Fixed tuning value, not a player control")
    jeff_call_lead_m: int = Field(ge=10, description="Minimum warning distance for Jeff's calls")
    allowed_hazards: list[HazardType]
    segments: list[SegmentBrief] = Field(min_length=3, max_length=8)
    constraints: list[str]
    open_creator_decisions: list[str]


# ---------- Agent 2: Hazard Forecast Designer -> HazardForecast ----------
class Hazard(BaseModel):
    hazard_id: str = Field(pattern=r"^HZ_\d{2}_\d{2}$")
    type: HazardType
    lane: Lane
    distance_m: int = Field(ge=0, description="Distance from the start of its segment")
    readability_cue: str = Field(description="What the player sees/hears before reaching it")


class SegmentForecast(BaseModel):
    segment_id: str = Field(pattern=r"^SEG_\d{2}$")
    safe_lane: Lane = Field(description="The single safe-route signal for this segment")
    safe_point_id: str = Field(pattern=r"^SAFE_\d{2}$", description="Recovery point for this segment")
    hazards: list[Hazard]


class HazardForecast(BaseModel):
    forecast_id: str
    dock_zone_id: Literal["DOCK_LIGHTHOUSE"]
    segments: list[SegmentForecast]


# ---------- Agent 3: Companion Dialogue Writer -> JeffCallSheet ----------
class JeffCall(BaseModel):
    call_id: str = Field(pattern=r"^JEFF_RET_\d{2}$")
    target_segment_id: str = Field(pattern=r"^SEG_\d{2}$")
    direction: Lane = Field(description="Must equal the forecast's safe_lane for the target segment")
    lead_m: int = Field(description="Metres before the target segment starts that the call fires")
    line: str = Field(description="Jeff's spoken line, coarse seaman voice")
    subtitle: str = Field(description="Subtitle text with speaker attribution, e.g. 'JEFF: ...'")


class JeffCallSheet(BaseModel):
    calls: list[JeffCall]
    arrival_line: str = Field(description="Played on arrival at the lighthouse jetty")


# ---------- Agent 4: Canon & Review Orchestrator -> ReviewReport ----------
class Check(BaseModel):
    check: str
    result: CheckResult
    evidence: str


class ReviewReport(BaseModel):
    verdict: Literal["PASS", "REVISE"]
    pillar_checks: list[Check] = Field(min_length=4, max_length=4)
    decisions_log_checks: list[Check]
    issues: list[str]
    open_creator_decisions: list[str]
    handoff_summary: str
