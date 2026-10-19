"""Persistent goal state (requirements + backlog) and the human-readable session log."""
import json
from datetime import datetime

from . import config

GOAL = ("Bring LightingTheStorm to the state the GDD (Exec Summary, Technical Strategy, AI Agent Strategy) "
        "describes for the Gate 1 vertical slice, consistent with the concept art and the AI crew briefs, "
        "or document precisely what remains so work can resume later.")


class State:
    def __init__(self):
        self.goal = GOAL
        self.requirements = []     # {id, text, source, status: met|partial|unmet, evidence}
        self.tasks = []            # see normalise_task
        self.history = []          # {time, task_id, event, note}
        self.analysed_at = None

    # ---- persistence -----------------------------------------------------------------------
    @classmethod
    def load(cls):
        s = cls()
        if config.BACKLOG_JSON.exists():
            d = json.loads(config.BACKLOG_JSON.read_text(encoding="utf-8"))
            s.goal = d.get("goal", GOAL)
            s.requirements, s.tasks = d.get("requirements", []), d.get("tasks", [])
            s.history, s.analysed_at = d.get("history", []), d.get("analysed_at")
        return s

    def save(self):
        config.STATE_DIR.mkdir(parents=True, exist_ok=True)
        config.BACKLOG_JSON.write_text(json.dumps({
            "goal": self.goal, "analysed_at": self.analysed_at, "requirements": self.requirements,
            "tasks": self.tasks, "history": self.history}, indent=2), encoding="utf-8")

    # ---- tasks -----------------------------------------------------------------------------
    def next_id(self):
        nums = [int(t["id"][1:]) for t in self.tasks if t["id"][1:].isdigit()]
        return f"T{(max(nums) if nums else 0) + 1:02d}"

    def add_tasks(self, raw_tasks):
        for r in raw_tasks:
            t = normalise_task(r)
            t["id"] = self.next_id()
            self.tasks.append(t)

    def open_tasks(self):
        return sorted((t for t in self.tasks if t["status"] == "open"), key=lambda t: (-t["priority"], t["id"]))

    def get(self, tid):
        tid = tid.upper() if tid.upper().startswith("T") else f"T{int(tid):02d}"
        return next((t for t in self.tasks if t["id"] == tid), None)

    def waiting_on(self, t):
        """The task's dependencies that are still open (an empty list means it can be started)."""
        return [x for x in t.get("depends_on", []) if (self.get(x) or {}).get("status") == "open"]

    def log(self, task_id, event, note=""):
        self.history.append({"time": datetime.now().isoformat(timespec="seconds"),
                             "task_id": task_id, "event": event, "note": note})

    def progress(self):
        n = len(self.requirements)
        if not n:
            return 0.0, 0, 0, 0
        met = sum(r["status"] == "met" for r in self.requirements)
        part = sum(r["status"] == "partial" for r in self.requirements)
        return (met + 0.5 * part) / n * 100, met, part, n - met - part


def normalise_task(r: dict) -> dict:
    pr = r.get("priority", 5)
    try:
        pr = max(1, min(10, int(pr)))
    except (TypeError, ValueError):
        pr = 5
    return {
        "id": r.get("id", ""), "title": r.get("title", "(untitled)"), "priority": pr,
        "category": r.get("category", "code"),
        "summary": r.get("summary", ""), "why_this_score": r.get("why_this_score", ""),
        "evidence": r.get("evidence", []), "requirement_ids": r.get("requirement_ids", []),
        "owner_role": r.get("owner_role", ""), "effort": r.get("effort", "M"),
        "agent_can_execute": bool(r.get("agent_can_execute", True)),
        "blocked_by": r.get("blocked_by", ""), "depends_on": r.get("depends_on", []),
        "status": "open", "result": None,
    }


class SessionLog:
    """Writes the whole session (prompts, tool calls, decisions) to a Markdown file for the tutor."""

    def __init__(self):
        config.LOG_DIR.mkdir(parents=True, exist_ok=True)
        self.path = config.LOG_DIR / f"session_{datetime.now():%Y%m%d_%H%M%S}.md"
        self.path.write_text(f"# Goal-Oriented Agent session {datetime.now():%Y-%m-%d %H:%M}\n\n"
                             f"Model: `{config.MODEL}`\n\n", encoding="utf-8")

    def _w(self, s):
        with self.path.open("a", encoding="utf-8") as f:
            f.write(s)

    def add(self, heading, body):
        self._w(f"\n## {heading}\n\n{body}\n")

    def human(self, text):
        self._w(f"\n**Human:** `{text}`\n")

    def agent(self, text):
        self._w(f"\n**Agent:** {text}\n")

    def add_tool(self, name, args, out, is_err):
        shown = {k: (v if len(str(v)) < 300 else str(v)[:300] + "...") for k, v in args.items()}
        o = out if len(out) < 600 else out[:600] + f"... [{len(out):,} chars]"
        self._w(f"\n<details><summary>tool: {name} {'(error)' if is_err else ''}</summary>\n\n"
                f"args: `{json.dumps(shown)}`\n\n```\n{o}\n```\n</details>\n")
