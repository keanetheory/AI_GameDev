"""Draws the class-assignment illustration for the opening dialogue (SVG, then PNG via Edge).

Reads AIAgentCrew/sample_output_picked/dialogue_opening.json so quotes, counts and event IDs always match the game data.
Run:  python tools/build_illustration.py
"""
import html
import json
import subprocess
import textwrap
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DOCS = ROOT.parent / "Docs" / "Lore Build" / "dialogue"
SRC = ROOT.parent / "AIAgentCrew" / "sample_output_picked" / "dialogue_opening.json"  # creator-picked set in canon beat order (40 lines)
SVG = DOCS / "illustration_opening_dialogue_flow.svg"
PNG = DOCS / "illustration_opening_dialogue_flow.png"
EDGE = r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"

W, H = 1600, 1000
BG, INK, SLATE, STONE, SILVER, AMBER, GOLD = "#0E0E10", "#1F2A44", "#2C3A40", "#6B6B66", "#B9BEC4", "#C07A1E", "#B8962E"
SPK = {"TED": "#1F2A44", "ARTHUR": "#2F4A34", "DANIEL": "#7A2620"}
STEP_COL = {1: AMBER, 2: SILVER, 3: GOLD}
SERIF, SANS, MONO = "Georgia, 'Times New Roman', serif", "'Segoe UI', Arial, sans-serif", "Consolas, 'Courier New', monospace"

data = json.loads(SRC.read_text(encoding="utf-8"))
lines = {l["line_id"]: l for l in data["lines"]}
KEY_LINE = {1: "TED_S1_01", 2: "TED_S2_01", 3: "TED_S3_02"}
# canon story-beat order (2026-10-16): arrival and coal, sailors, then Ted finds the burner broken
CHAIN = [("GAME_STARTED", 1), ("BOILER_FED", 1), ("SAILORS_MOORED", 2), ("GATE_OPENED", 2),
         ("DANIEL_IN_BASEMENT", 2), ("BURNER_DIAGNOSED", 3), ("BURNER_BRIEFING", 3), ("SHIP_SIGHTED", 3),
         ("BURNER_PICKED_UP", 3), ("RETURN_DEPARTED", 3)]

o = []


def add(s):
    o.append(s)


def esc(s):
    return html.escape(s, quote=False)


def text(x, y, s, size=15, fill=SILVER, font=SANS, weight="normal", style="normal", anchor="start", spacing=0):
    add(f'<text x="{x}" y="{y}" font-family="{font}" font-size="{size}" fill="{fill}" font-weight="{weight}" '
        f'font-style="{style}" text-anchor="{anchor}" letter-spacing="{spacing}">{esc(s)}</text>')


def wrapped(x, y, s, width, size, fill, font=SANS, style="normal", lead=1.35):
    for i, ln in enumerate(textwrap.wrap(s, width)):
        text(x, y + i * size * lead, ln, size, fill, font, style=style)
    return len(textwrap.wrap(s, width))


add(f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}">')
add(f'<defs><linearGradient id="beam" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="{AMBER}" stop-opacity="0.35"/>'
    f'<stop offset="1" stop-color="{AMBER}" stop-opacity="0"/></linearGradient>'
    f'<linearGradient id="sky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#14161C"/><stop offset="1" stop-color="{BG}"/></linearGradient></defs>')
add(f'<rect width="{W}" height="{H}" fill="url(#sky)"/>')
# lighthouse glyph + beam (top-left), echoing the game's lighting: warm lamp against cold storm
add(f'<polygon points="118,66 760,20 760,130" fill="url(#beam)"/>')
add(f'<polygon points="96,150 140,150 132,70 104,70" fill="{STONE}" stroke="{BG}" stroke-width="2"/>')
add(f'<rect x="100" y="52" width="36" height="20" fill="{AMBER}" stroke="{BG}" stroke-width="2"/>')
add(f'<polygon points="96,52 140,52 118,30" fill="{INK}" stroke="{SILVER}" stroke-width="1.5"/>')
add(f'<rect x="84" y="150" width="68" height="8" fill="{SLATE}"/>')
text(172, 78, "LIGHTING THE STORM", 38, AMBER, SERIF, "bold", spacing=4)
text(174, 112, "Opening dialogue: how Ted talks the player through the first three steps", 20, SILVER)
text(174, 140, "Gate 1 slice, first-person. Guidance comes from voices, never markers or a timer.", 15, STONE, SANS, style="italic")

# ---------------- step cards ----------------
CW, GAP, X0, Y0, CH = 440, 80, 60, 180, 470
counts = {s["step"]: {k: 0 for k in SPK} for s in data["steps"]}
for l in data["lines"]:
    if l["step"] in counts:
        counts[l["step"]][l["speaker"]] += 1
for i, st in enumerate(data["steps"]):
    x = X0 + i * (CW + GAP)
    col = STEP_COL[st["step"]]
    add(f'<rect x="{x}" y="{Y0}" width="{CW}" height="{CH}" rx="10" fill="#15181F" stroke="{col}" stroke-width="2"/>')
    add(f'<rect x="{x}" y="{Y0}" width="{CW}" height="74" rx="10" fill="{SLATE}"/><rect x="{x}" y="{Y0+50}" width="{CW}" height="24" fill="{SLATE}"/>')
    add(f'<circle cx="{x+40}" cy="{Y0+37}" r="24" fill="{col}"/>')
    text(x + 40, Y0 + 47, str(st["step"]), 28, BG, SERIF, "bold", anchor="middle")
    text(x + 78, Y0 + 34, st["title"], 24, "#F2EFE6", SERIF, "bold")
    text(x + 78, Y0 + 58, textwrap.shorten(st["location"], 46, placeholder="…"), 13, SILVER)
    yy = Y0 + 102
    text(x + 24, yy, "PLAYER DOES", 12, col, SANS, "bold", spacing=2)
    n = wrapped(x + 24, yy + 22, st["player_action"], 52, 15, SILVER)
    yy = yy + 22 + n * 20 + 22
    text(x + 24, yy, "TED SAYS", 12, col, SANS, "bold", spacing=2)
    ted = lines[KEY_LINE[st["step"]]]["text"]
    qlines = textwrap.wrap(ted, 38)
    bh = len(qlines) * 25 + 28
    add(f'<rect x="{x+24}" y="{yy+12}" width="{CW-48}" height="{bh}" rx="6" fill="{INK}" stroke="{SILVER}" stroke-opacity="0.35"/>')
    add(f'<rect x="{x+24}" y="{yy+12}" width="5" height="{bh}" fill="{col}"/>')
    for k, ql in enumerate(qlines):
        text(x + 44, yy + 40 + k * 25, ("\u201c" if k == 0 else "") + ql + ("\u201d" if k == len(qlines) - 1 else ""), 18, "#F2EFE6", SERIF, style="italic")
    yy = yy + 12 + bh + 34
    text(x + 24, yy, "ALSO SPEAKING", 12, col, SANS, "bold", spacing=2)
    cx = x + 24
    for who in ("TED", "ARTHUR", "DANIEL"):
        c = counts[st["step"]][who]
        if c:
            add(f'<circle cx="{cx+8}" cy="{yy+25}" r="8" fill="{SPK[who]}" stroke="{SILVER}" stroke-width="1.2"/>')
            lab = f"{who.title()} {c}"
            text(cx + 22, yy + 30, lab, 14, SILVER)
            cx += 34 + len(lab) * 8
    yy += 56
    text(x + 24, Y0 + CH - 18, f"{st['starts_on']}  \u2192  {st['ends_on']}", 12, STONE, MONO)
    if i < 2:
        ax = x + CW
        add(f'<path d="M{ax+14} {Y0+CH//2} H{ax+GAP-26}" stroke="{AMBER}" stroke-width="3"/>')
        add(f'<polygon points="{ax+GAP-26},{Y0+CH//2-9} {ax+GAP-10},{Y0+CH//2} {ax+GAP-26},{Y0+CH//2+9}" fill="{AMBER}"/>')

# ---------------- event chain ----------------
cy = 700
text(60, cy - 14, "EVENT CHAIN  (each stable event ID triggers the next lines)", 12, STONE, SANS, "bold", spacing=2)
pw, pg = 136, 13
for k, (ev, st) in enumerate(CHAIN):
    x = 60 + k * (pw + pg)
    add(f'<rect x="{x}" y="{cy}" width="{pw}" height="32" rx="16" fill="{STEP_COL[st]}"/>')
    text(x + pw / 2, cy + 21, ev, 11, BG, MONO, "bold", anchor="middle")
    if k < len(CHAIN) - 1:
        add(f'<polygon points="{x+pw+2},{cy+10} {x+pw+pg-2},{cy+16} {x+pw+2},{cy+22}" fill="{STONE}"/>')
text(60, cy + 58, "Step 3 ends at RETURN_DEPARTED, where the Agent Crew's ARTHUR_RET_* calls take over for the return crossing.", 13, STONE, SANS, style="italic")

# ---------------- line budget chart ----------------
by = 800
text(60, by, "AUTHORED LINES PER STEP", 12, STONE, SANS, "bold", spacing=2)
rows = [(s["step"], s["title"]) for s in data["steps"]]
opt = {k: sum(1 for l in data["lines"] if l["step"] == 0 and l["speaker"] == k) for k in SPK}
rows.append((0, "Optional discoveries"))
counts[0] = opt
scale = 17
for r, (stp, label) in enumerate(rows):
    yb = by + 22 + r * 34
    text(60, yb + 17, label, 14, SILVER)
    bx = 230
    for who in ("TED", "ARTHUR", "DANIEL"):
        c = counts[stp][who]
        if c:
            add(f'<rect x="{bx}" y="{yb}" width="{c*scale}" height="24" fill="{SPK[who]}" stroke="{SILVER}" stroke-width="1"/>')
            text(bx + c * scale / 2, yb + 17, str(c), 13, "#F2EFE6", SANS, "bold", anchor="middle")
            bx += c * scale
    text(bx + 10, yb + 17, f"{sum(counts[stp].values())} total", 12, STONE)
lx = 60
for who in ("TED", "ARTHUR", "DANIEL"):
    add(f'<rect x="{lx}" y="{by+168}" width="14" height="14" fill="{SPK[who]}" stroke="{SILVER}"/>')
    text(lx + 22, by + 180, who.title(), 13, SILVER)
    lx += 90
text(lx + 10, by + 180, f"{len(data['lines'])} lines in total", 13, STONE, SANS, style="italic")

# ---------------- design rules ----------------
rx = 800
add(f'<rect x="{rx}" y="{by-6}" width="740" height="172" rx="10" fill="#15181F" stroke="{STONE}" stroke-opacity="0.6"/>')
text(rx + 24, by + 22, "HOW EACH LINE IS WRITTEN", 12, AMBER, SANS, "bold", spacing=2)
rules = [
    ("Voice, not markers", "Ted says where to go and why. Pillar 3: guidance comes from people."),
    ("No clock on screen", "No timer words or numbers. The storm and the ship's lights carry the pressure."),
    ("Stalls get a ladder", "Three nudges: a hint, a sharper hint, then the exact place to go."),
    ("One line per moment", "The creator picked one line for every moment. Assist mode adds a plain-text hint."),
]
for k, (h, d) in enumerate(rules):
    ry = by + 50 + k * 34
    add(f'<circle cx="{rx+32}" cy="{ry-5}" r="5" fill="{AMBER}"/>')
    text(rx + 48, ry, h, 15, "#F2EFE6", SANS, "bold")
    text(rx + 230, ry, d, 14, SILVER)
text(W - 60, H - 10, "Characters and canon: Docs/Lore Build.  Data: dialogue_opening.json (Godot 4).", 11, STONE, SANS, anchor="end")
add("</svg>")

DOCS.mkdir(parents=True, exist_ok=True)
SVG.write_text("\n".join(o), encoding="utf-8")
subprocess.run([EDGE, "--headless", "--disable-gpu", "--hide-scrollbars", f"--screenshot={PNG}",
                f"--window-size={W},{H}", SVG.as_uri()], check=True, capture_output=True, timeout=90)
print("wrote", SVG, "and", PNG)
