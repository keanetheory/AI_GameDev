"""Contracts for the Voice Casting crew (Sound agent -> Canon and Review Orchestrator)."""
from typing import Literal

from pydantic import BaseModel, Field

from schemas import SpeakerId


class VoiceSettings(BaseModel):
    stability: float = Field(ge=0, le=1, description="Lower = wider emotional range")
    similarity_boost: float = Field(ge=0, le=1)
    style: float = Field(ge=0, le=1)
    speed: float = Field(ge=0.7, le=1.2)
    use_speaker_boost: bool = True


class VoiceProfile(BaseModel):
    speaker: SpeakerId
    role_category: str = Field(description="Short casting category, e.g. 'gruff mentor'")
    gender: Literal["male", "female"]
    age_band: Literal["young adult", "adult", "older", "elderly"]
    accent: str
    timbre: str = Field(description="Texture of the voice, e.g. gravelly, reedy, bright")
    pace: Literal["slow", "measured", "brisk", "quick"]
    energy: Literal["low", "medium", "high"]
    voice_description: str = Field(description="ElevenLabs Voice Design prompt: sound only, never a real person")
    preview_text: str = Field(description="100-1000 chars: in-character script lines used to audition the voice")
    design_model_id: Literal["eleven_ttv_v3", "eleven_multilingual_ttv_v2"] = "eleven_ttv_v3"
    tts_model_id: str = "eleven_v3"
    settings: VoiceSettings
    canon_basis: list[str] = Field(description="Canon notes this casting rests on (character file, voice_casting_notes)")
    contrast_note: str = Field(description="How this voice is told apart from the other two")


class LineVoice(BaseModel):
    line_id: str
    tts_text: str = Field(description="The script text, unchanged, with optional [audio tags]")
    stability: float | None = Field(default=None, ge=0, le=1, description="Per-line override")


class VoiceCastingPlan(BaseModel):
    profiles: list[VoiceProfile] = Field(min_length=3, max_length=3)
    lines: list[LineVoice]
    suggestions: list[str] = Field(description="Casting suggestions for the creator to accept or reject")
    open_creator_decisions: list[str]
