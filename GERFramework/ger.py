"""GER Framework CLI. Offline by default: nothing here calls an API or spends tokens.

  python ger.py list                          the 5 creator agents and 7 assessment agents
  python ger.py ingest [assessor|all]         assessors read and store their understanding of the Lore and GDD
  python ger.py audit <glb...>                mesh audit: empty meshes, hole loops, size, textures
  python ger.py review-plan <creator|all>     assessor reviews the plan, creator revises, up to 3 loops
  python ger.py show <creator>                the prioritised plan as it stands
  python ger.py approve <creator> --quote ".."   ONLY the creator (the human) does this: the all clear
  python ger.py execute <creator>             execution brief (refused until approved)
  python ger.py record <creator> <OBJ> done|in_progress|blocked --note ".."
  python ger.py review-work <creator>         assessor re-runs every check and sends feedback (max 3 loops)
  python ger.py assess [assessor|all]         an assessor runs its own checks on existing work (no creator needed)
  python ger.py status                        where every agent is
  python ger.py export-agents                 regenerate .claude/agents/*.md and AGENT_ROSTER.md from the specs
"""
import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from ger_core import knowledge, loop, meshaudit, spec  # noqa: E402
from ger_core.checks import CACHE  # noqa: E402


def ids(arg, table):
    if arg in ("all", None):
        return list(table)
    if arg not in table:
        raise SystemExit(f"unknown id '{arg}'. Known: {', '.join(table)}")
    return [arg]


def main() -> int:
    ap = argparse.ArgumentParser(description="GER Framework (offline)")
    sub = ap.add_subparsers(dest="cmd", required=True)
    sub.add_parser("list")
    sub.add_parser("status")
    sub.add_parser("export-agents")
    p = sub.add_parser("assess")
    p.add_argument("assessor", nargs="?", default="all", help="run an assessor's own checks against existing work")
    for n in ("ingest", "review-plan", "show", "execute", "review-work"):
        p = sub.add_parser(n)
        p.add_argument("agent", nargs="?", default="all")
        if n == "review-plan":
            p.add_argument("--reset", action="store_true", help="discard state and start the plan from the spec again")
    p = sub.add_parser("audit")
    p.add_argument("paths", nargs="+")
    p = sub.add_parser("approve")
    p.add_argument("agent")
    p.add_argument("--quote", required=True, help="the creator's go-ahead, verbatim")
    p = sub.add_parser("record")
    p.add_argument("agent")
    p.add_argument("objective")
    p.add_argument("status", choices=["done", "in_progress", "blocked"])
    p.add_argument("--note", default="")
    a = ap.parse_args()
    C, A = spec.creators(), spec.assessors()

    if a.cmd == "list":
        for c in C.values():
            print(f"CREATOR   {c['id']:<22} {c['name']:<34} reviewed by {c['assessor']}  ({len(c['objectives'])} objectives)")
        for x in A.values():
            print(f"ASSESSOR  {x['id']:<22} {x['name']:<34} reviews {x.get('reviews') or 'existing work'} -> feedback to {', '.join(x['feedback_to'])}")
    elif a.cmd == "ingest":
        for i in ids(a.agent, A):
            k, note = knowledge.ensure(A[i])
            print(f"{i}: {note}; {k['files_read']} docs, {len(k['hard_rules'])} hard rules, {len(k['open_questions'])} open questions")
    elif a.cmd == "audit":
        for p in a.paths:
            print(meshaudit.summarise(meshaudit.audit(spec.REPO / p if not Path(p).is_absolute() else Path(p), CACHE)))
    elif a.cmd == "review-plan":
        for i in ids(a.agent, C):
            s = loop.review_plan(i, a.reset)
            print(f"{i}: {s['phase']}  loops {s['plan_loops']}/3  blocks {s['last_blocks']}  -> GERFramework/reports/{i}_plan.md")
    elif a.cmd == "show":
        for i in ids(a.agent, C):
            s = loop.load_state(i)
            print(f"\n{C[i]['name']}  [{s['phase']}]")
            for o in s["objectives"]:
                print(f"  {o['priority']:>2}  {o['id']:<7} {o['title']}{'   <-- needs you' if o.get('needs_creator') else ''}")
    elif a.cmd == "approve":
        s = loop.approve(a.agent, a.quote)
        print(f"{a.agent}: approved at {s['approval']['at']}")
    elif a.cmd == "execute":
        print(loop.execute_brief(ids(a.agent, C)[0]))
    elif a.cmd == "record":
        loop.record(a.agent, a.objective, a.status, a.note)
        print("recorded")
    elif a.cmd == "review-work":
        for i in ids(a.agent, C):
            s = loop.review_work(i)
            print(f"{i}: {s['phase']}  work loops {s['work_loops']}/3  blocks {s['last_work']['blocks']}  open {s['last_work']['open']}  -> reports/{i}_work.md")
    elif a.cmd == "assess":
        for i in ids(a.assessor, A):
            print(loop.assess_existing(i))
    elif a.cmd == "status":
        for i in C:
            s = loop.load_state(i)
            print(f"{i:<22} {s['phase']:<18} plan loops {s['plan_loops']}/3  work loops {s['work_loops']}/3")
    elif a.cmd == "export-agents":
        from ger_core import export
        export.run()
    return 0


if __name__ == "__main__":
    sys.exit(main())
