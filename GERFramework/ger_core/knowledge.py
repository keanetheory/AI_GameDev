"""Each Assessment Agent reads the Lore Build and the final GDD itself, and stores its own understanding.

Offline and deterministic: no model, no tokens. For every source document the agent keeps a content hash (so it
knows when it is out of date), the headings, and the lines that touch its own domain keywords. From those lines it
extracts the hard rules it will hold work to (must / never / not approved / stretch goal) and the open questions
(TBD / decision) it must NOT let a creator settle silently.
"""
import hashlib
import json
import re
from datetime import datetime, timezone

from .spec import REPO, ROOT

SOURCE_DIRS = ["Docs/Lore Build", "Docs/GDD/Final_GDD_Post_Review"]
RULE = re.compile(r"\b(must|never|do not|don't|not approved|stretch goal|only|always|no fail|cannot|fixed)\b", re.I)
OPEN = re.compile(r"\b(TBD|to be decided|open question|decision|undecided|unresolved|cause TBD)\b", re.I)


def sources() -> list:
    out = []
    for d in SOURCE_DIRS:
        out += sorted((REPO / d).rglob("*.md"))
    return out


def _sha(p) -> str:
    return hashlib.sha256(p.read_bytes()).hexdigest()[:16]


def path_for(assessor_id: str):
    return ROOT / "knowledge" / f"{assessor_id}.json"


def ingest(a: dict) -> dict:
    kw = [k.lower() for k in a["keywords"]]
    files, rules, opens = {}, [], []
    for p in sources():
        rel = str(p.relative_to(REPO)).replace("\\", "/")
        lines = p.read_text(encoding="utf-8", errors="replace").splitlines()
        heads = [l.lstrip("# ").strip() for l in lines if l.startswith("#")][:40]
        hits = []
        for i, l in enumerate(lines, 1):
            low = l.lower()
            if any(k in low for k in kw) and len(l.strip()) > 12:
                hits.append({"line": i, "text": l.strip()[:400]})
                if RULE.search(l):
                    rules.append({"src": f"{rel}:{i}", "text": l.strip()[:400]})
                if OPEN.search(l):
                    opens.append({"src": f"{rel}:{i}", "text": l.strip()[:400]})
        files[rel] = {"sha": _sha(p), "headings": heads, "domain_hits": len(hits), "hits": hits[:25]}
    k = {"assessor": a["id"], "ingested_utc": datetime.now(timezone.utc).isoformat(timespec="seconds"),
         "keywords": a["keywords"], "files_read": len(files), "sources": files,
         "hard_rules": rules[:60], "open_questions": opens[:60],
         "most_relevant": sorted(((f, v["domain_hits"]) for f, v in files.items() if v["domain_hits"]),
                                 key=lambda x: -x[1])[:12]}
    path_for(a["id"]).write_text(json.dumps(k, indent=1), encoding="utf-8")
    return k


def load(a: dict) -> dict | None:
    p = path_for(a["id"])
    return json.loads(p.read_text(encoding="utf-8")) if p.exists() else None


def stale(k: dict) -> list[str]:
    """Source files that changed, appeared or vanished since this assessor last read them."""
    now = {str(p.relative_to(REPO)).replace("\\", "/"): _sha(p) for p in sources()}
    old = {f: v["sha"] for f, v in k["sources"].items()}
    return sorted([f for f in now if old.get(f) != now[f]] + [f for f in old if f not in now])


def ensure(a: dict) -> tuple[dict, str]:
    """Return fresh knowledge, re-reading the docs only if they changed. Second value says what happened."""
    k = load(a)
    if k is None:
        return ingest(a), "read the Lore and GDD for the first time"
    changed = stale(k)
    if changed or k.get("keywords") != a["keywords"]:
        return ingest(a), f"re-read the docs ({len(changed)} changed)"
    return k, "knowledge up to date"
