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
    arthur_call_lead_m: int = Field(ge=10, description="Minimum warning distance for Arthur's calls")
    allowed_hazards: list[HazardType]
    segments: list[SegmentBrief] = Field(min_length=3, max_length=8)
    constraints: list[str]
    open_creator_decisions: list[str]


# ---------- Agent 2: Hazard Forecast agent -> HazardForecast ----------
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


# ---------- Agent 3: Dialogue agent -> ArthurCallSheet ----------
class ArthurCall(BaseModel):
    call_id: str = Field(pattern=r"^ARTHUR_RET_\d{2}$")
    target_segment_id: str = Field(pattern=r"^SEG_\d{2}$")
    direction: Lane = Field(description="Must equal the forecast's safe_lane for the target segment")
    lead_m: int = Field(description="Metres before the target segment starts that the call fires")
    line: str = Field(description="Arthur's spoken line, coarse seaman voice")
    subtitle: str = Field(description="Subtitle text with speaker attribution, e.g. 'ARTHUR: ...'")


class ArthurCallSheet(BaseModel):
    calls: list[ArthurCall]
    arrival_line: str = Field(description="Played on arrival at the lighthouse jetty")


# ---------- Agent 4: Canon and Review Orchestrator -> ReviewReport ----------
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


# ================= Opening dialogue task (Dialogue agent) =================
SpeakerId = Literal["TED", "ARTHUR", "DANIEL"]
LineKind = Literal["intro", "setting", "objective", "reaction", "nudge", "discovery"]


# ---------- Production Orchestrator -> DialogueBrief ----------
class StepSpec(BaseModel):
    step: int = Field(ge=1, le=3)
    title: str
    location: str
    player_action: str
    starts_on: str
    ends_on: str


class EventSpec(BaseModel):
    event_id: str = Field(pattern=r"^[A-Z][A-Z0-9_]+$")
    step: int = Field(ge=0, le=3, description="0 = optional discovery")
    note: str
    existing_crew_event: bool = False


class DialogueBrief(BaseModel):
    task_id: str
    slice: str
    max_words_per_line: int = Field(ge=8, le=30)
    player_term: str = Field(description="The only way characters refer to the player")
    speakers: list[SpeakerId]
    steps: list[StepSpec] = Field(min_length=3, max_length=3)
    events: list[EventSpec]
    constraints: list[str]
    open_creator_decisions: list[str]


# ---------- Dialogue agent -> OpeningDialogue ----------
class DialogueLine(BaseModel):
    line_id: str = Field(pattern=r"^(TED|ARTHUR|DANIEL)_[A-Z0-9]+_[A-Za-z0-9]+$")
    step: int = Field(ge=0, le=3)
    beat: str
    speaker: SpeakerId
    kind: LineKind
    trigger: str = Field(description="Event ID from the brief that plays this line")
    text: str
    subtitle: str = Field(description="'SPEAKER: text'")
    delivery: str = Field(description="Voice direction for recording")
    pause_before: float = Field(default=0.0, ge=0)
    once: bool = True
    group: str | None = Field(default=None, description="Lines sharing a group are alternates; one is picked at random")
    tier: int | None = Field(default=None, ge=1, description="Nudge level for IDLE_* triggers")
    assist_text: str | None = None
    journal_id: str | None = None
    staging: str | None = None
    note: str | None = None


class JournalEntry(BaseModel):
    journal_id: str = Field(pattern=r"^JRN_\d{2}$")
    step: int = Field(ge=1, le=3)
    trigger: str
    text: str


class OpeningDialogue(BaseModel):
    lines: list[DialogueLine] = Field(min_length=10)
    journal: list[JournalEntry]
