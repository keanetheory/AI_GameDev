"""Renders the style guide and the three agent prompts from style_guide.json and prompts/*.md."""
import json
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent.parent / "AIAgentCrew"))
import canon  # noqa: E402

GUIDE = json.loads((HERE / "style_guide.json").read_text(encoding="utf-8"))
ROLES = ("generator", "evaluator", "refiner")


def rules_block(with_sources: bool = False) -> str:
    out = []
    for t in GUIDE["types"]:
        out.append(f"{t.upper()}")
        for r in GUIDE["rules"]:
            if r["type"] == t:
                src = f"  (source: {r['source']})" if with_sources else ""
                out.append(f"- {r['id']} [weight {r['weight']}] {r['rule']}{src}")
        out.append("")
    return "\n".join(out).strip()


def voices_block() -> str:
    return "\n".join(f"- {k}: {v}" for k, v in GUIDE["speakers"].items())


def events_block() -> str:
    ev = [f"{e[0]} ({e[2]})" for e in canon.OPENING_EVENTS] + [f"{e[0]} ({e[1]})" for e in canon.LATER_EVENTS]
    return "\n".join(f"- {e}" for e in ev) + "\n- ARTHUR_RET_01, ARTHUR_RET_02 ... (Arthur's calls on the return crossing)"


def render(role: str) -> str:
    text = (HERE / "prompts" / f"{role}.md").read_text(encoding="utf-8")
    subs = {"{{GAME}}": canon.GAME_TITLE, "{{PITCH}}": canon.PITCH, "{{RULES}}": rules_block(),
            "{{VOICES}}": voices_block(), "{{EVENTS}}": events_block(), "{{FORMAT}}": GUIDE["record_format"],
            "{{MAX_WORDS}}": str(GUIDE["max_words_per_line"])}
    for k, v in subs.items():
        text = text.replace(k, v)
    return text.strip()
