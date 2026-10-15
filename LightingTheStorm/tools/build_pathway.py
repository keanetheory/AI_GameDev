"""Draws the pathway diagram: prompt -> canon sources -> Opening Dialogue Crew -> checks -> results.

Every number comes from the crew's own output folders, so the picture is evidence of the runs, not a
hand-typed claim.   python tools/build_pathway.py live      (default: the live-model run, with revision rounds)
                      python tools/build_pathway.py offline  (the scripted offline replay)
"""
import html
import json
import re
import subprocess
import sys
from collections import Counter
from pathlib import Path

MODE = sys.argv[1] if len(sys.argv) > 1 else "live"
ROOT = Path(__file__).resolve().parent.parent
CREW = ROOT.parent / "Agent Crew" / "storm_crew" / "storm_crew"
RUN = CREW / ("sample_output_live_revised" if MODE == "live" else "sample_output_dialogue")
OFFLINE = CREW / "sample_output_dialogue"
DOCS = ROOT.parent / "Docs" / "Lore Build" / "dialogue"
SVG = DOCS / f"illustration_pathway_crew_run_{MODE}.svg"
PNG = DOCS / f"illustration_pathway_crew_run_{MODE}.png"
EDGE = r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"


def load(p):
    return json.loads(Path(p).read_text(encoding="utf-8"))


# ---------------- evidence ----------------
log = load(RUN / "run_log.json")
off_log = load(OFFLINE / "run_log.json")
neg = load(OFFLINE / "negative_test_max12_words" / "run_log.json")
game = load(RUN / "dialogue_opening.json")
final_review = load(RUN / "handoffs" / "03_dialogue_review.json")
brief = load(RUN / "handoffs" / "01_dialogue_brief.json")
lines = game["lines"]
spk = {k: sum(1 for x in lines if x["speaker"] == k) for k in ("TED", "ARTHUR", "DANIEL")}
groups = len({x["group"] for x in lines if x.get("group")})
ladders = sum(1 for e in game["events"] if e["event_id"].startswith("IDLE"))
assert not (OFFLINE / "negative_test_max12_words" / "dialogue_opening.json").exists()

# revision rounds: history_round{n-1} holds the dialogue and review that triggered round n
n_rounds = game["generated_by"].get("revision_rounds", 0)
hist = {}
for n in range(n_rounds):
    hist[n] = {"dialogue": load(RUN / "handoffs" / f"history_round{n}_dialogue.json"),
               "review": load(RUN / "handoffs" / f"history_round{n}_review.json")}
first_review = hist[0]["review"] if n_rounds else final_review
pass_review = final_review
status = game["status"]


def checks_of(rv):
    return rv["pillar_checks"] + rv["decisions_log_checks"]


def tasks(prefix, rnd=None):
    name = prefix if rnd is None else f"{prefix}_{rnd}"
    return [e for e in log if e["task"] == name]


write_attempts = tasks("OPENING_DIALOGUE_WRITE")
review_attempts = tasks("OPENING_DIALOGUE_REVIEW")
lines_before = {l["line_id"]: l for l in (hist[0]["dialogue"]["lines"] if n_rounds else [])}
lines_after = {l["line_id"]: l for l in lines}


def kept_verbatim(before, after):
    return sum(1 for k, v in after.items() if k in before and v["text"] == before[k]["text"]
               and v["trigger"] == before[k]["trigger"] and v["step"] == before[k]["step"])


CATS = [("did not match", "reply was not valid JSON"), ("unknown trigger", "unknown trigger IDs"),
        ("no line plays", "events with no line"), ("nudge tiers", "incomplete nudge ladders"),
        ("apprentice", "says 'apprentice'"), ("lad, lass", "gendered address"),
        ("names the ship", "ship named too early"), ("lamp head", "says 'lamp head'"),
        ("words (max", "over the word limit"), ("timer, deadline", "timer or number"),
        ("supernatural", "confirms supernatural"), ("at least once", "'Isaac' unused"),
        ("events must be exactly", "invented event IDs"), ("does not match event", "step differs from event"),
        ("says 'all", "miscounted lines"), ("alternates", "alternate groups")]


def categorise(errors):
    c = Counter()
    for e in errors:
        c[next((lab for key, lab in CATS if key in e), "other")] += 1
    return c.most_common(4)


neg_write = [e for e in neg if e["task"] == "OPENING_DIALOGUE_WRITE"]

W = 1600
BG, INK, SLATE, STONE, SILVER, AMBER, GOLD, CREAM = "#0E0E10", "#1F2A44", "#2C3A40", "#6B6B66", "#B9BEC4", "#C07A1E", "#B8962E", "#F2EFE6"
PASS, BLOCK = "#6FA37A", "#C9605A"
SERIF, SANS, MONO = "Georgia, serif", "'Segoe UI', Arial, sans-serif", "Consolas, monospace"
o = []


def esc(s):
    return html.escape(s, quote=False)


def t(x, y, s, size=13, fill=SILVER, font=SANS, w="normal", anchor="start", style="normal", sp=0):
    o.append(f'<text x="{x}" y="{y}" font-family="{font}" font-size="{size}" fill="{fill}" font-weight="{w}" '
             f'text-anchor="{anchor}" font-style="{style}" letter-spacing="{sp}">{esc(s)}</text>')


def box(x, y, w, h, stroke, fill="#15181F", dash=False, sw=2, rx=9):
    d = ' stroke-dasharray="7 5"' if dash else ""
    o.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{rx}" fill="{fill}" stroke="{stroke}" stroke-width="{sw}"{d}/>')


def arrow(x1, y1, x2, y2, col=AMBER, sw=2.5):
    o.append(f'<line x1="{x1}" y1="{y1}" x2="{x2-8}" y2="{y2}" stroke="{col}" stroke-width="{sw}"/>')
    o.append(f'<polygon points="{x2},{y2} {x2-12},{y2-6} {x2-12},{y2+6}" fill="{col}"/>')


def vline(x, y1, y2, col=AMBER, sw=2):
    o.append(f'<line x1="{x}" y1="{y1}" x2="{x}" y2="{y2}" stroke="{col}" stroke-width="{sw}"/>')


def bullets(x, y, items, size=12.5, fill=SILVER, gap=19, font=SANS):
    for i, s in enumerate(items):
        o.append(f'<circle cx="{x}" cy="{y + i*gap - 4}" r="2.5" fill="{STONE}"/>')
        t(x + 10, y + i * gap, s, size, fill, font)


def pill(x, y, w, label, col, txtcol=BG, h=24, size=12):
    box(x, y, w, h, col, fill=col, sw=0, rx=h / 2)
    t(x + w / 2, y + h / 2 + 4.5, label, size, txtcol, SANS, "bold", anchor="middle")


# ---------------- build the crew column with a cursor so any number of rounds fits ----------------
AX, AW, BX, BW, CX, CW_, DX, DW, EX, EW = 30, 250, 310, 270, 610, 440, 1080, 230, 1340, 230
Y0 = 150
ax, aw = CX + 20, CW_ - 40
col_ops = []  # deferred drawing: (kind, args) so heights are known before the panel is drawn
cursor = Y0 + 18
anchors = {}  # arrow targets for canon inputs


def add_agent(key, title, sub, y, sub_col=SILVER, bold=False):
    col_ops.append(("agent", (title, sub, y, sub_col, bold)))
    anchors[key] = y + 35
    return y + 70


def add_pill(label, ok, y, w=252, col=None):
    col_ops.append(("pill", (label, ok, y, w, col)))
    return y + 24


def add_gbox(title, attempts, y):
    rows = []
    for e in attempts:
        cats = [] if e["passed"] else categorise(e["errors"])
        rows.append((e, cats, 34 + 17 * len(cats) + 8))
    h = 36 + sum(r[2] for r in rows) + 6
    col_ops.append(("gbox", (title, rows, y, h)))
    return y + h


def gap(y, n=12):
    return y + n


cursor = add_agent("a1", "1  Production Orchestrator",
                   f"writes DialogueBrief: {len(brief['events'])} events, limit {brief['max_words_per_line']} words, player term", cursor)
cursor = gap(cursor, 10)
g1 = next(e for e in log if e["task"] == "OPENING_DIALOGUE_BRIEF")
cursor = add_pill(f"Guardrail 1 · attempt {g1['attempt']} · {'PASS' if g1['passed'] else 'BLOCKED'}", g1["passed"], cursor)
cursor = gap(cursor, 14)
a2_y = cursor
cursor = add_agent("a2", "2  Dialogue agent  (the new Dialogue task)",
                   f"writes OpeningDialogue: {len(hist[0]['dialogue']['lines']) if n_rounds else len(lines)} lines, "
                   f"{len((hist[0]['dialogue'] if n_rounds else game)['journal'])} journal entries", cursor)
g2_top = cursor
cursor = add_gbox("Guardrail 2 = check_dialogue (reused checks)", write_attempts, cursor)
cursor = gap(cursor, 14)
fr = first_review
fr_fail = [c for c in checks_of(fr) if c["result"] == "fail"]
a3_y = cursor
vtxt = (f"verdict {fr['verdict']}: {len(checks_of(fr)) - len(fr_fail)} of {len(checks_of(fr))} checks pass"
        + (f", {len(fr['issues'])} issues" if fr["issues"] else ""))
cursor = add_agent("a3", "3  Canon and Review Orchestrator", vtxt, cursor,
                   SILVER if fr["verdict"] == "PASS" else BLOCK, fr["verdict"] != "PASS")
cursor = gap(cursor, 10)
g3 = review_attempts[-1]
cursor = add_pill(f"Guardrail 3 · attempt {g3['attempt']} · {'PASS' if g3['passed'] else 'BLOCKED'}", g3["passed"], cursor)
rev_marks = []  # (y_from, y_to) for the "issues fed back" arrow of each round
prev_a3 = a3_y
for n in range(1, n_rounds + 1):
    cursor = gap(cursor, 18)
    col_ops.append(("bar", (f"REVISION ROUND {n}: reviewer issues fed back to the Dialogue agent", cursor)))
    cursor += 26
    ra_y = cursor
    before = {l["line_id"]: l for l in hist[n - 1]["dialogue"]["lines"]}
    after = {l["line_id"]: l for l in (hist[n]["dialogue"]["lines"] if n in hist else lines)}
    issues = hist[n - 1]["review"]["issues"]
    cursor = add_agent(f"r{n}a", f"2b  Dialogue agent  (revision {n})",
                       f"fixes {len(issues)} issues; keeps {kept_verbatim(before, after)} of {len(after)} lines verbatim", cursor)
    rev_marks.append((prev_a3, ra_y))
    cursor = add_gbox("Guardrail 2 again (same checks)", tasks("OPENING_DIALOGUE_REVISE", n), cursor)
    cursor = gap(cursor, 14)
    rv = pass_review if n == n_rounds else hist[n]["review"]
    rv_fail = [c for c in checks_of(rv) if c["result"] == "fail"]
    rtxt = (f"verdict {rv['verdict']}: {len(checks_of(rv)) - len(rv_fail)} of {len(checks_of(rv))} checks pass"
            + (f", {len(rv['issues'])} issues" if rv["issues"] else ", 0 issues"))
    prev_a3 = cursor
    cursor = add_agent(f"r{n}b", f"3b  Canon and Review  (re-review {n})", rtxt, cursor,
                       PASS if rv["verdict"] == "PASS" else BLOCK, True)
    cursor = gap(cursor, 10)
    gr = tasks("OPENING_DIALOGUE_REREVIEW", n)[-1]
    cursor = add_pill(f"Guardrail 3 · attempt {gr['attempt']} · {'PASS' if gr['passed'] else 'BLOCKED'}", gr["passed"], cursor)
    final_a3 = prev_a3
end_of_agents = cursor
PH = end_of_agents + 18 - Y0
COLH = max(PH, 640)
ty = Y0 + COLH + 34
H = ty + 3 * 70 + 62 + 120

o.append(f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}">')
o.append(f'<defs><linearGradient id="sky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#14161C"/><stop offset="1" stop-color="{BG}"/></linearGradient></defs>')
o.append(f'<rect width="{W}" height="{H}" fill="url(#sky)"/>')
t(30, 52, "FROM PROMPT, THROUGH THE AGENT CREW, TO THE GAME", 30, AMBER, SERIF, "bold", sp=2)
sub = ("Evidence from live runs: a real model wrote the dialogue, the reviewer sent it back, and the Dialogue agent revised it"
       if MODE == "live" and n_rounds else
       "Evidence from a live run: a real model wrote the dialogue through the new Dialogue task and the checks it reuses"
       if MODE == "live" else "Evidence from the scripted offline run of the Dialogue task and the checks it reuses")
t(30, 80, sub, 16, SILVER)

for x, h, s in [(AX, "1  YOUR PROMPTS", "what was asked"), (BX, "2  CANON READ", "sources and rules"),
                (CX, "3  OPENING DIALOGUE CREW", "three CrewAI agents, each gated"), (DX, "4  FINAL GATE", "re-check, then write files"),
                (EX, "5  RESULTS", "what the game gets")]:
    t(x, Y0 - 24, h, 14, AMBER, SANS, "bold", sp=2)
    t(x, Y0 - 8, s, 12, STONE, SANS, style="italic")

# ---- col A: prompts ----
box(AX, Y0, AW, 196, AMBER)
t(AX + 14, Y0 + 26, "Request 1", 15, CREAM, SERIF, "bold")
bullets(AX + 16, Y0 + 52, ["Dialogue options from the GDD", "and the Lore Build folder", "Ted introduces the setting and",
                           "steps: coal, sailors, burner", "Follow the Agent Crew's style", "Godot 4 files + illustration"], 12.5, SILVER, 21)
box(AX, Y0 + 210, AW, 142, GOLD)
t(AX + 14, Y0 + 236, "Request 2", 15, CREAM, SERIF, "bold")
bullets(AX + 16, Y0 + 262, ["Call the player \u201cIsaac\u201d", "Ted's position is fine", "Visualise the pathway"], 12.5, SILVER, 21)
box(AX, Y0 + 366, AW, 220, AMBER, sw=3)
t(AX + 14, Y0 + 392, "Request 3", 15, CREAM, SERIF, "bold")
bullets(AX + 16, Y0 + 418, ["Add a Dialogue task to storm_crew", "Reuse the same checks, rerun it", "live with the Anthropic API key", "Then visualise the pathway"], 12.5, SILVER, 21)
box(AX, Y0 + 600, AW, 150, AMBER, sw=3)
t(AX + 14, Y0 + 626, "Request 4 (this round)", 15, CREAM, SERIF, "bold")
bullets(AX + 16, Y0 + 652, ["Feed the reviewer's issues", "back to the Dialogue agent", "Add the iteration to the diagram"], 12.5, SILVER, 21)

# ---- col B: sources ----
bh = [92, 128, 138, 120]
by = [Y0, Y0 + 106, Y0 + 248, Y0 + 400]
srcs = [
    ("GDD", AMBER, ["Exec Summary: step table", "ship reveal at boarding", "player never speaks"]),
    ("Lore Build", SILVER, ["Ted, Arthur, Daniel, player files", "style guide, pillars", "regions, steam power, coastfolk"]),
    ("Agent Crew (reused)", GOLD, ["roles.py: Dialogue agent", "schemas.py + validators.py", "TIMER_WORDS, 'SPEAKER:' subtitles", "guardrail + retry pattern"]),
    ("canon.py (new block)", AMBER, [f"{len(brief['speakers'])} voices, {len(brief['steps'])} steps", f"{len(brief['events'])} event IDs", f"{len(brief['constraints'])} dialogue rules"]),
]
for (n, c, items), y, h in zip(srcs, by, bh):
    box(BX, y, BW, h, c, sw=2.5 if n.startswith("canon") else 2)
    t(BX + 14, y + 25, n, 14, CREAM, SERIF, "bold")
    bullets(BX + 16, y + 48, items, 12, SILVER, 19)
for ty_ in (Y0 + 46, Y0 + 170, Y0 + 316):
    arrow(AX + AW, Y0 + 98, BX, ty_, STONE)
arrow(AX + AW, Y0 + 476, BX, by[3] + 60, AMBER)

# ---- col C: draw the crew panel from the deferred ops ----
box(CX, Y0, CW_, PH, AMBER, fill="#12161B", sw=3)
for kind, args in col_ops:
    if kind == "agent":
        title, subt, y, sub_col, bold = args
        box(ax, y, aw, 70, GOLD)
        t(ax + 14, y + 26, title, 15, CREAM, SERIF, "bold")
        t(ax + 14, y + 48, subt, 12, sub_col, SANS, "bold" if bold else "normal")
    elif kind == "pill":
        label, ok, y, w, c = args
        pill(ax + 14, y, w, label, c or (PASS if ok else BLOCK))
    elif kind == "bar":
        label, y = args
        box(ax, y, aw, 22, BLOCK, fill="#1A1214", sw=1.2, rx=6)
        t(ax + 10, y + 15, label, 11.5, "#E3A29D", SANS, "bold")
    elif kind == "gbox":
        title, rows, y, h = args
        box(ax, y, aw, h, SLATE, fill="#101216", sw=1.5)
        t(ax + 14, y + 24, title, 13.5, CREAM, SANS, "bold")
        yy = y + 36
        for e, cats, rh in rows:
            if e["passed"]:
                pill(ax + 14, yy, 232, f"attempt {e['attempt']} · PASS · 0 errors", PASS)
            else:
                pill(ax + 14, yy, 232, f"attempt {e['attempt']} · BLOCKED · {len(e['errors'])} errors", BLOCK)
                for i, (lab, n) in enumerate(cats):
                    t(ax + 20, yy + 42 + i * 17, f"{n} x {lab}", 11.5, "#E3A29D", MONO)
            yy += rh
        if len(rows) > 1:
            t(ax + 268, y + 60, "errors are fed", 11.5, BLOCK, SANS, style="italic")
            t(ax + 268, y + 76, "back to the agent", 11.5, BLOCK, SANS, style="italic")
            t(ax + 268, y + 92, "which retries", 11.5, BLOCK, SANS, style="italic")
# connectors between agent and its guardrail box, and into the review
vline(ax + aw / 2, a2_y + 70, g2_top)
if len(write_attempts) > 1:
    o.append(f'<path d="M{ax+aw-8} {g2_top+40} V{a2_y+36} H{ax+aw}" fill="none" stroke="{BLOCK}" stroke-width="2.5" stroke-dasharray="6 4"/>')
    o.append(f'<polygon points="{ax+aw-12},{a2_y+36} {ax+aw},{a2_y+30} {ax+aw},{a2_y+42}" fill="{BLOCK}"/>')
# "REVISE: issues fed back" arrows (dashed, right side) from the review to the revision agent
for i, (src, dst) in enumerate(rev_marks):
    o.append(f'<path d="M{ax+aw+2} {src+35} H{ax+aw+14} V{dst+35} H{ax+aw+2}" fill="none" stroke="{BLOCK}" stroke-width="2.5" stroke-dasharray="6 4"/>')
    o.append(f'<polygon points="{ax+aw-10},{dst+35} {ax+aw+2},{dst+29} {ax+aw+2},{dst+41}" fill="{BLOCK}"/>')
for key in ("a1", "a2", "a3"):
    arrow(BX + BW, by[3] + 60, CX, anchors[key], AMBER)

# ---- col D: final gate + negative test ----
box(DX, Y0, DW, 176, AMBER, sw=3)
t(DX + 14, Y0 + 26, "dialogue_integrator.py", 13.5, CREAM, MONO, "bold")
bullets(DX + 16, Y0 + 52, ["re-runs every check", "end to end, then writes", "the files. A REVISE", "verdict is flagged", "needs_revision"], 12.5, SILVER, 19)
last_key = f"r{n_rounds}b" if n_rounds else "a3"
arrow(CX + CW_, anchors[last_key], DX, Y0 + 88, AMBER)
nbox_y = Y0 + 196
nh = COLH - 196
box(DX, nbox_y, DW, nh, BLOCK, fill="#1A1214", dash=True)
t(DX + 14, nbox_y + 26, "Negative test", 15, CREAM, SERIF, "bold")
t(DX + 14, nbox_y + 46, "offline crew, --max-words 12", 11.5, "#E3A29D", MONO)
for i, e in enumerate(neg_write):
    pill(DX + 14, nbox_y + 62 + i * 30, 200, f"write attempt {e['attempt']} · {len(e['errors'])} errors", BLOCK, size=11.5, h=22)
yy2 = nbox_y + 62 + len(neg_write) * 30 + 14
t(DX + 14, yy2 + 6, "pipeline stops", 13, CREAM, SANS, "bold")
bullets(DX + 16, yy2 + 30, ["no dialogue_opening.json", "only REPORT.md says why", "the gate really blocks"], 12, SILVER, 19)

# ---- col E: results ----
box(EX, Y0, EW, 300, AMBER, sw=3)
t(EX + 14, Y0 + 26, "Files written", 15, CREAM, SERIF, "bold")
pill(EX + 14, Y0 + 36, 200, f"status: {status}", PASS if status == "proposed" else BLOCK, size=11.5, h=22)
files = [("dialogue_opening.json", f"{len(lines)} lines (Ted {spk['TED']}, Arthur {spk['ARTHUR']}, Daniel {spk['DANIEL']})"),
         ("DIALOGUE_OPENING.md", "review list for the creator"), ("run_log.json", f"{len(log)} guardrail attempts"),
         ("HANDOFF.md + REPORT.md", "fixed-format notes"), ("handoffs/*.json", "each agent's output, per round")]
for i, (n, d) in enumerate(files):
    t(EX + 14, Y0 + 86 + i * 40, n, 12, CREAM, MONO, "bold")
    t(EX + 14, Y0 + 103 + i * 40, d, 11.5, SILVER)
arrow(DX + DW, Y0 + 88, EX, Y0 + 88, AMBER)
gy2 = Y0 + 318
box(EX, gy2, EW, COLH - 318, AMBER, sw=3)
t(EX + 14, gy2 + 26, "In the game (dynamic)", 15, CREAM, SERIF, "bold")
t(EX + 14, gy2 + 44, "dialogue_loader.gd reads the JSON", 11.5, AMBER, SANS, style="italic")
bullets(EX + 16, gy2 + 70, ["events trigger the lines", f"{groups} alternate groups: a random", "option plays each run",
                            f"{ladders} nudge ladders escalate", "when the player stalls", "assist mode adds a text hint"], 12, SILVER, 21)
vline(EX + EW / 2, Y0 + 300, gy2)

# ---- bottom: timelines ----
box(30, ty - 10, 1540, 3 * 70 + 36, SLATE, fill="#12161B", sw=1.5)
t(50, ty + 18, "RUN TIMELINE  (read from run_log.json, one chip per guardrail attempt)", 13, AMBER, SANS, "bold", sp=1.5)


def chip(x, y, label, ok, w=150, sub="", col=None):
    c = col or (PASS if ok else BLOCK)
    box(x, y, w, 36, c, fill="#15181F", sw=2, rx=8)
    t(x + 12, y + 16, label, 11.5, CREAM, MONO, "bold")
    t(x + 12, y + 30, sub or ("PASS" if ok else "BLOCKED"), 11, c, SANS, "bold")


SHORT = {"OPENING_DIALOGUE_BRIEF": "BRIEF", "OPENING_DIALOGUE_WRITE": "WRITE", "OPENING_DIALOGUE_REVIEW": "REVIEW"}


def label_for(task):
    if task in SHORT:
        return SHORT[task]
    if task.startswith("OPENING_DIALOGUE_REVISE_"):
        return "REVISE " + task.rsplit("_", 1)[1]
    if task.startswith("OPENING_DIALOGUE_REREVIEW_"):
        return "RE-REVIEW " + task.rsplit("_", 1)[1]
    return task


def row(y, title, entries, tail, tail_ok, tail_col=None, verdicts=None):
    t(50, y - 6, title, 12.5, SILVER, SANS, style="italic")
    x = 50
    for e in entries:
        v = (verdicts or {}).get(e["task"])
        if e["passed"]:
            sub, col = (f"PASS · verdict {v}", (PASS if v == "PASS" else GOLD)) if v else ("PASS", None)
        else:
            sub, col = f"BLOCKED · {len(e['errors'])} errors", None
        chip(x, y, f"{label_for(e['task'])} #{e['attempt']}", e["passed"], 150, sub, col)
        arrow(x + 150, y + 18, x + 170, y + 18, STONE, sw=1.5)
        x += 170
    chip(x, y, tail[0], tail_ok, 210, tail[1], tail_col)


verdicts = {"OPENING_DIALOGUE_REVIEW": first_review["verdict"]}
for n in range(1, n_rounds + 1):
    verdicts[f"OPENING_DIALOGUE_REREVIEW_{n}"] = (pass_review if n == n_rounds else hist[n]["review"])["verdict"]
live_title = ("Run 1: live model, with a revision round" if n_rounds else "Run 1: live model (Anthropic API)") if MODE == "live" else "Run 1: scripted offline replay"
row(ty + 52, live_title, log, ("FINAL CHECKS + FILES", f"written · {status}"), status == "proposed",
    None if status == "proposed" else GOLD, verdicts)
if MODE == "live":
    row(ty + 122, "Run 2: offline replay (scripted model, same checks)", off_log, ("FINAL CHECKS + FILES", "written · proposed"), True)
else:
    t(50, ty + 116, "(live-model run: see illustration_pathway_crew_run_live)", 12.5, STONE, SANS, style="italic")
row(ty + 192, "Run 3: negative test (--max-words 12)", neg, ("STOPPED", "no files written"), False)

# ---- honest scope ----
sy = ty + 3 * 70 + 62
t(30, sy, "WHAT IS REAL AND WHAT IS SCRIPTED", 13, AMBER, SANS, "bold", sp=1.5)
if MODE == "live":
    n_err = sum(len(e["errors"]) for e in write_attempts if not e["passed"])
    t(30, sy + 24, f"Real: a live model wrote the brief, the lines and the reviews through the same agents. The checks blocked "
                   f"{len(write_attempts) - 1} Dialogue attempt(s) ({n_err} errors) before the third passed.", 12.5, SILVER)
    if n_rounds:
        failed_names = "; ".join(c["check"].split(";")[0].split(":")[0].strip() for c in fr_fail)
        fixed = sorted(set(lines_before) ^ set(lines_after)) if lines_before else []
        changed = len(lines_after) - kept_verbatim(lines_before, lines_after)
        t(30, sy + 44, f"The first review returned {fr['verdict']} ({len(fr_fail)} checks failed: {failed_names}). Its {len(fr['issues'])} issues went back to the "
                       f"Dialogue agent, who changed {changed} lines (kept {kept_verbatim(lines_before, lines_after)} verbatim).", 12.5, SILVER)
        t(30, sy + 64, f"The revision passed the same guardrail first time and the re-review returned {pass_review['verdict']} ({len(checks_of(pass_review))} of "
                       f"{len(checks_of(pass_review))} checks). The re-reviewer is the same model marking its own fix, so creator approval is still needed.", 12.5, SILVER)
        t(30, sy + 84, "Two checks were added after run 1: a line's step must match its event's step, and a reviewer's line counts must match the data. "
                       "Output was not copied into the game project.", 12.5, SILVER)
    else:
        t(30, sy + 44, f"The reviewer returned {fr['verdict']}; the data is flagged {status}.", 12.5, SILVER)
else:
    t(30, sy + 24, "Real: three CrewAI agents, their tasks, context passing and guardrails ran; every chip above is from run_log.json.", 12.5, SILVER)
    t(30, sy + 44, "Scripted: no model was called. offline_dialogue_llm.py replayed the earlier draft, with three deliberate faults on attempt 1.", 12.5, SILVER)
o.append("</svg>")

SVG.write_text("\n".join(o), encoding="utf-8")
subprocess.run([EDGE, "--headless", "--disable-gpu", "--hide-scrollbars", f"--screenshot={PNG}",
                f"--window-size={W},{int(H)}", SVG.as_uri()], check=True, capture_output=True, timeout=90)
print("wrote", PNG)
