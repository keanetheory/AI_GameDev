"""Style Guide Agent loop for Lighting the Storm: Generator -> Evaluator -> Refiner, no human in the loop.

    python run_loop.py                      # all cases in cases.json, backend 'claude' (Claude Code headless)
    python run_loop.py --cases ex1_tone     # one case
    python run_loop.py --backend api        # Anthropic API instead (needs ANTHROPIC_API_KEY)
    python run_loop.py --max-rounds 3 --target 10

Per case: the Generator writes content from a request that is designed to break the style guide; the
Evaluator returns "SCORE: [X/10]" and "REASON: ..."; while the score is below the target the Refiner
rewrites the text from the REASON and the Evaluator grades again (at most --max-rounds rewrites).
style_lint.py runs on every draft and its findings go to the Evaluator as evidence; a lint finding also
caps the score at 8 so a lenient grader cannot pass a mechanically provable violation.

Results are written to runs/<timestamp>/ (one JSON per case plus RESULTS.md).
"""
import argparse
import json
import os
import re
import subprocess
import sys
from datetime import datetime
from pathlib import Path

from sg_rules import HERE, render
from style_lint import lint, summary

MODEL = os.getenv("STYLE_MODEL", "sonnet")
API_MODEL = os.getenv("STYLE_API_MODEL", "claude-sonnet-5-5")


def call_llm(system: str, user: str, backend: str) -> str:
    if backend == "api":
        import anthropic
        msg = anthropic.Anthropic().messages.create(model=API_MODEL, max_tokens=3000, system=system,
                                                    messages=[{"role": "user", "content": user}])
        return "".join(b.text for b in msg.content if b.type == "text").strip()
    cmd = ["claude", "-p", "--system-prompt", system, "--tools", "", "--no-session-persistence",
           "--disable-slash-commands", "--model", MODEL]
    r = subprocess.run(cmd, input=user, capture_output=True, text=True, encoding="utf-8", timeout=300)
    if r.returncode != 0:
        raise RuntimeError(f"claude exited {r.returncode}: {r.stderr[:500]}")
    return r.stdout.strip()


def generate(request: str, backend: str) -> str:
    return call_llm(render("generator"), request, backend)


def evaluate(text: str, backend: str) -> dict:
    """Returns {score, reason, raw, lint}. The lint findings are given to the grader and cap the score at 8."""
    text = "\n".join(l for l in text.splitlines() if l.strip())  # blank lines would skew the line numbers
    findings = lint(text)
    user =("Review the following text against the style guide.\n\nTEXT TO REVIEW:\n<<<\n" + text + "\n>>>\n\n"
            "LINT EVIDENCE (script output):\n" + summary(findings))
    raw = call_llm(render("evaluator"), user, backend)
    m = re.search(r"SCORE:\s*\[?\s*(\d+)\s*/\s*10\s*\]?", raw)
    if not m:
        raise RuntimeError("Evaluator did not return 'SCORE: [X/10]':\n" + raw[:400])
    score = max(1, min(10, int(m.group(1))))
    reason = raw.split("REASON:", 1)[1].strip() if "REASON:" in raw else raw
    capped = False
    if findings and score > 8:
        score, capped = 8, True
        reason += "\n[lint guard: script findings capped the score at 8]\n" + summary(findings)
    return {"score": score, "reason": reason, "raw": raw, "lint": [str(f) for f in findings], "lint_capped": capped}


def refine(text: str, reason: str, backend: str) -> str:
    user = ("ORIGINAL TEXT:\n<<<\n" + text + "\n>>>\n\nEVALUATOR'S REASON:\n<<<\n" + reason + "\n>>>\n\n"
            "Rewrite the text so it scores a perfect 10/10 on the style guide.")
    out = call_llm(render("refiner"), user, backend)
    return re.sub(r"^```\w*\n|\n```$", "", out.strip())


def run_case(case: dict, backend: str, max_rounds: int, target: int) -> dict:
    draft = generate(case["request"], backend)
    rounds, text = [], draft
    ev = evaluate(text, backend)
    rounds.append({"round": 0, "text": text, **ev})
    print(f"  [{case['id']}] generated; score {ev['score']}/10", flush=True)
    for i in range(1, max_rounds + 1):
        if ev["score"] >= target:
            break
        text = refine(text, ev["reason"], backend)
        ev = evaluate(text, backend)
        rounds.append({"round": i, "text": text, **ev})
        print(f"  [{case['id']}] refine {i}; score {ev['score']}/10", flush=True)
    return {"case": case, "generated": draft, "rounds": rounds, "final": text, "final_score": ev["score"],
            "passed": ev["score"] >= target, "refinements": len(rounds) - 1}


def results_md(results: list[dict], backend: str) -> str:
    out = [f"# Style Guide Agent run\n\nBackend: {backend}. Generated {datetime.now():%Y-%m-%d %H:%M}.\n"]
    for r in results:
        c = r["case"]
        out.append(f"\n## {c['id']} - {c['violation_class']}\n\n**Request to the Generator:** {c['request']}\n")
        for rd in r["rounds"]:
            label = "BEFORE (Generator output)" if rd["round"] == 0 else f"AFTER refinement {rd['round']}"
            out.append(f"\n### {label}\n\n```\n{rd['text']}\n```\n\n**Evaluator:**\n\nSCORE: [{rd['score']}/10]\n\nREASON: {rd['reason']}\n")
        out.append(f"\n**Result:** {r['rounds'][0]['score']}/10 -> {r['final_score']}/10 in {r['refinements']} refinement(s).\n")
    return "\n".join(out)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--cases", nargs="*", help="case ids (default all)")
    ap.add_argument("--backend", choices=["claude", "api"], default="claude")
    ap.add_argument("--max-rounds", type=int, default=3)
    ap.add_argument("--target", type=int, default=10)
    a = ap.parse_args()
    cases = json.loads((HERE / "cases.json").read_text(encoding="utf-8"))
    if a.cases:
        cases = [c for c in cases if c["id"] in a.cases]
    out_dir = HERE / "runs" / datetime.now().strftime("%Y%m%d_%H%M%S")
    out_dir.mkdir(parents=True)
    results = []
    for c in cases:
        print(f"case {c['id']}", flush=True)
        r = run_case(c, a.backend, a.max_rounds, a.target)
        (out_dir / f"{c['id']}.json").write_text(json.dumps(r, indent=2, ensure_ascii=False), encoding="utf-8")
        results.append(r)
    (out_dir / "RESULTS.md").write_text(results_md(results, a.backend), encoding="utf-8")
    print(f"\nwrote {out_dir}")
    for r in results:
        print(f"{r['case']['id']}: {r['rounds'][0]['score']}/10 -> {r['final_score']}/10 ({r['refinements']} refinements)")
    return 0 if all(r["passed"] for r in results) else 1


if __name__ == "__main__":
    sys.exit(main())
