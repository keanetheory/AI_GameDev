"""Paths, model and API client settings."""
import os
from pathlib import Path

AGENT_DIR = Path(__file__).resolve().parent.parent          # .../AI_GameDev/GoalOrientedAgent
ROOT = AGENT_DIR.parent                                      # .../AI_GameDev (the working directory)
DOCS = ROOT / "Docs"
GDD = DOCS / "GDD" / "Final_GDD_Post_Review"
CREW = ROOT / "AIAgentCrew"
CONCEPT_ART = ROOT / "ConceptArt"
GAME = ROOT / "LightingTheStorm"

STATE_DIR = AGENT_DIR / "state"
LOG_DIR = AGENT_DIR / "logs"
BACKUP_DIR = STATE_DIR / "backups"
BACKLOG_JSON = STATE_DIR / "backlog.json"

# The agent may only create or change files under these folders (relative to ROOT).
WRITE_ALLOWED = ("LightingTheStorm", "Docs", "AIAgentCrew")
# It may never read these.
READ_BLOCKED_PARTS = {".git", ".godot", "__pycache__", "backups"}
READ_BLOCKED_NAMES = {".env"}

MODEL = os.getenv("GOAL_AGENT_MODEL", "claude-sonnet-5-5")


def load_env() -> None:
    """Load .env from this folder, falling back to the crew's .env (same key, same workspace)."""
    from dotenv import load_dotenv
    for p in (AGENT_DIR / ".env", CREW / ".env"):
        if p.exists():
            load_dotenv(p, override=False)
    global MODEL
    MODEL = os.getenv("GOAL_AGENT_MODEL", "claude-sonnet-5-5")


def make_client():
    import anthropic
    load_env()
    key = os.getenv("ANTHROPIC_API_KEY")
    if not key:
        raise SystemExit("ANTHROPIC_API_KEY is not set. Put it in GoalOrientedAgent/.env (see .env.example).")
    headers = {}
    if os.getenv("ANTHROPIC_WORKSPACE_ID"):
        headers["anthropic-workspace-id"] = os.environ["ANTHROPIC_WORKSPACE_ID"]
    return anthropic.Anthropic(api_key=key, default_headers=headers or None, max_retries=5)
