"""Loads GER agent specs (agents/creators/*.json, agents/assessors/*.json)."""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent      # GERFramework/
REPO = ROOT.parent                                  # repo root
GAME = REPO / "LightingTheStorm"
CREW = REPO / "AIAgentCrew"

# Names a spec may list under collaborates_with besides the roster in AIAgentCrew/roles.py and the GER agents.
EXTRA_COLLABORATORS = {
    "Creator",
    "Experience (Player Movement + QA agents)",
    "World crew (Boat, Player Movement, Lighting)",
    "Offline AI Crew",
}


def _load(kind: str) -> dict:
    out = {}
    for f in sorted((ROOT / "agents" / kind).glob("*.json")):
        d = json.loads(f.read_text(encoding="utf-8"))
        d["_file"] = str(f.relative_to(REPO)).replace("\\", "/")
        out[d["id"]] = d
    return out


def creators() -> dict:
    return _load("creators")


def assessors() -> dict:
    return _load("assessors")


def crews() -> dict:
    out = {}
    for f in sorted((ROOT / "crews").glob("*.json")):
        d = json.loads(f.read_text(encoding="utf-8"))
        out[d["id"]] = d
    return out


def pair(creator_id: str) -> tuple[dict, dict]:
    c = creators()[creator_id]
    return c, assessors()[c["assessor"]]


def known_collaborators() -> set[str]:
    names = set(EXTRA_COLLABORATORS)
    sys.path.insert(0, str(CREW))
    try:
        from roles import ROSTER
        names |= {r.name for r in ROSTER}
    except Exception:
        pass
    names |= {c["name"] for c in creators().values()} | {a["name"] for a in assessors().values()}
    return names
