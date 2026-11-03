"""Builds the assessment video from real material: the offline crew run's own output, the repo's files, and gameplay recorded by
Godot's movie writer (intro.avi, prop.avi). Writes pipeline_to_game.mp4 next to this script."""
import json
import subprocess
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

HERE = Path(__file__).resolve().parent
REPO = Path("C:/GameDev/AI_GameDev")
FF = "C:/Users/pmkea/AppData/Local/Programs/Python/Python313/Lib/site-packages/imageio_ffmpeg/binaries/ffmpeg-win-x86_64-v7.1.exe"
W, H = 1280, 720
BG = (16, 20, 28)
PANEL = (26, 32, 44)
SILVER = (185, 190, 196)
AMBER = (192, 122, 30)
GREEN = (120, 190, 120)
RED = (215, 95, 85)
DIM = (120, 128, 140)
FONT = "C:/Windows/Fonts/segoeui.ttf"
FONT_B = "C:/Windows/Fonts/segoeuib.ttf"
MONO = "C:/Windows/Fonts/consola.ttf"
SERIF_B = "C:/Windows/Fonts/georgiab.ttf"
OUT = HERE / "build"
OUT.mkdir(exist_ok=True)


def f(path, size):
    return ImageFont.truetype(path, size)


def wrap(draw, text, font, width):
    words, lines, cur = text.split(), [], ""
    for w in words:
        t = (cur + " " + w).strip()
        if draw.textlength(t, font=font) <= width:
            cur = t
        else:
            lines.append(cur)
            cur = w
    if cur:
        lines.append(cur)
    return lines


def card(step, title, sub, body_lines=None, mono_lines=None, source=None):
    im = Image.new("RGB", (W, H), BG)
    d = ImageDraw.Draw(im)
    y = 60
    if step:
        d.text((80, y), step.upper(), font=f(FONT_B, 22), fill=AMBER)
        y += 40
    d.text((80, y), title, font=f(SERIF_B, 44), fill=SILVER)
    y += 70
    for ln in wrap(d, sub, f(FONT, 24), W - 160):
        d.text((80, y), ln, font=f(FONT, 24), fill=SILVER)
        y += 34
    y += 18
    if mono_lines:
        box_h = 26 * len(mono_lines) + 36
        d.rounded_rectangle((70, y, W - 70, y + box_h), radius=10, fill=PANEL)
        yy = y + 18
        for ln, col in mono_lines:
            d.text((92, yy), ln, font=f(MONO, 19), fill=col)
            yy += 26
        y += box_h + 18
    for ln in body_lines or []:
        for w in wrap(d, ln, f(FONT, 22), W - 180):
            d.text((90, y), w, font=f(FONT, 22), fill=SILVER)
            y += 31
        y += 4
    if source:
        d.text((80, H - 50), "Source: " + source, font=f(FONT, 17), fill=DIM)
    return im


def caption(step, text):
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    lines = wrap(d, text, f(FONT, 21), 640)
    h = 44 + 29 * len(lines)
    d.rounded_rectangle((24, 24, 24 + 690, 24 + h), radius=10, fill=(10, 14, 20, 215))
    d.text((44, 36), step.upper(), font=f(FONT_B, 17), fill=AMBER)
    y = 62
    for ln in lines:
        d.text((44, y), ln, font=f(FONT, 21), fill=SILVER)
        y += 29
    return im


def run(args):
    r = subprocess.run([FF, "-hide_banner", "-loglevel", "error", "-y"] + args, capture_output=True, text=True)
    if r.returncode:
        sys.exit(r.stderr)


V_OUT = ["-c:v", "libx264", "-pix_fmt", "yuv420p", "-r", "30", "-preset", "medium", "-crf", "20",
         "-c:a", "aac", "-b:a", "160k", "-ar", "48000", "-ac", "2"]


def seg_still(png, secs, name):
    run(["-loop", "1", "-t", str(secs), "-i", str(png), "-f", "lavfi", "-t", str(secs), "-i", "anullsrc=r=48000:cl=stereo",
         "-vf", f"scale={W}:{H}", *V_OUT, "-shortest", str(OUT / name)])
    return OUT / name


def seg_frames(pattern, fps, name):
    run(["-framerate", str(fps), "-i", str(pattern), "-f", "lavfi", "-i", "anullsrc=r=48000:cl=stereo",
         "-vf", f"scale={W}:{H}", *V_OUT, "-shortest", str(OUT / name)])
    return OUT / name


def seg_clip(avi, start, secs, cap_png, name):
    run(["-ss", str(start), "-t", str(secs), "-i", str(avi), "-i", str(cap_png),
         "-filter_complex", f"[0:v]scale={W}:{H}[v];[v][1:v]overlay=0:0[o]", "-map", "[o]", "-map", "0:a", *V_OUT, str(OUT / name)])
    return OUT / name


segs = []

# 0. title
im = card("", "Lighting the Storm: pipeline to game",
          "From the GDD to the playable build: one line of dialogue and one 3D model traced from the agent that made them "
          "to the moment they play in the engine. Everything shown is real output from the repository (keanetheory/AI_GameDev).",
          ["1. The GDD's rules become code", "2. A crew run: generate, validate, retry, review, write into the project",
           "3. The contract the engine reads", "4. In the engine: the line and its voice play in the scene",
           "5. An asset: a FAL model, its provenance, in place", "6. Verified by the headless test suite"])
im.save(OUT / "c0.png")
segs.append(seg_still(OUT / "c0.png", 7, "s0.mp4"))

# 1. canon
im = card("Step 1", "The GDD's rules become code",
          "AIAgentCrew/canon.py turns the GDD and Lore Build into rules every crew must obey: the story beats, the stable "
          "event IDs the game fires, and the words and claims that are not allowed.",
          mono_lines=[
              ("OPENING_EVENTS = [", SILVER),
              ('    ("GAME_STARTED", 1, "New game begins OUTSIDE the lighthouse; Ted opens the door."),', SILVER),
              ('    ("LIGHTHOUSE_ENTERED", 1, "Player steps inside; after a beat Ted sends them to the boiler."),', SILVER),
              ("    ...", DIM),
              ("OPENING_DIALOGUE_RULES = [", SILVER),
              ("    \"Refer to the player only as 'Isaac' (never 'apprentice').\",", AMBER),
              ("    \"Ted never names the passenger ship before ... BURNER_DIAGNOSED\",", AMBER),
              ("    \"Say 'burner', never 'lamp head'. No timers, countdowns, numbers ...\",", AMBER)],
          body_lines=["The same event IDs are in the game: scripts/core/game_state.gd EVENTS."],
          source="AIAgentCrew/canon.py (OPENING_EVENTS, OPENING_DIALOGUE_RULES)")
im.save(OUT / "c1.png")
segs.append(seg_still(OUT / "c1.png", 9, "s1.mp4"))

# 2. the crew run, typed out from its real stdout and run_log
log = json.loads((HERE / "crew_run" / "run_log.json").read_text(encoding="utf-8"))
log = log if isinstance(log, list) else log.get("log", log)
errors = [e for x in log if not x.get("passed") for e in x["errors"]]
term = [("$ python main_dialogue.py --offline --godot-dir <the Godot project>", AMBER), ("", SILVER)]
for x in log:
    ok = x.get("passed")
    term.append((f"[guardrail] {x['task']} attempt {x['attempt']}: " + ("PASS" if ok else f"BLOCKED ({len(x['errors'])} errors)"),
                 GREEN if ok else RED))
    if not ok:
        for e in x["errors"]:
            term.append(("      - " + e, RED))
        term.append(("      (the errors go back to the Dialogue agent, which retries)", DIM))
term += [("[crew] copied game data to <the Godot project>/data/dialogue/dialogue_opening.json", GREEN),
         ("[crew] done.", GREEN)]
frames = HERE / "build" / "term"
frames.mkdir(exist_ok=True)
for old in frames.glob("*.png"):
    old.unlink()
n = 0
head = card("Step 2", "A crew run: generate, validate, retry, review, write",
            "The Opening Dialogue Crew (Production Orchestrator, Dialogue agent, Canon and Review Orchestrator), run offline "
            "with its scripted model so it costs nothing; a live run uses Claude. Its real output:")
for shown in range(1, len(term) + 1):
    im = head.copy()
    d = ImageDraw.Draw(im)
    top = 260
    d.rounded_rectangle((70, top, W - 70, top + 26 * len(term) + 40), radius=10, fill=(8, 10, 14))
    yy = top + 20
    for ln, col in term[:shown]:
        d.text((92, yy), ln, font=f(MONO, 18), fill=col)
        yy += 26
    d.text((80, H - 50), "Source: AIAgentCrew/main_dialogue.py; this run's run_log.json and stdout (3 Nov 2026)", font=f(FONT, 17), fill=DIM)
    hold = 14 if shown < len(term) else 75          # 15 fps: about 1 s a line, then 5 s on the finished run
    for _ in range(hold):
        im.save(frames / f"t{n:04d}.png")
        n += 1
segs.append(seg_frames(frames / "t%04d.png", 15, "s2.mp4"))

# 3. the contract
dlg = json.loads((REPO / "LightingTheStorm/data/dialogue/dialogue_opening.json").read_text(encoding="utf-8"))
line = next(x for x in dlg["lines"] if x["line_id"] == "TED_S1_01")
im = card("Step 3", "The contract the engine reads",
          "The crew's output has to validate against a typed schema (schemas.py), and the game's loader reads exactly those "
          "fields. Ted's first line, as the game loads it:",
          mono_lines=[
              ('{ "line_id": "TED_S1_01",  "speaker": "TED",  "trigger": "GAME_STARTED",', SILVER),
              ('  "text": "' + line["text"][:68] + '...",', SILVER),
              ('  "delivery": "' + line["delivery"] + '" }', SILVER),
              ("", SILVER),
              ("# scripts/dialogue/dialogue_loader.gd", DIM),
              ("_enqueue(_pick_lines(_by_trigger.get(event_id, [])))      # the event fires: its lines play", AMBER),
              ('var path := "%s/%s.mp3" % [voice_dir, line_id]           # the voice clip, found by line ID', AMBER)],
          body_lines=["The voice clip TED_S1_01.mp3 was cast by the Voice Casting Crew and recorded through ElevenLabs. "
                      "No file is reformatted on the way: the trigger is the event the scene fires, the file name is the line ID."],
          source="LightingTheStorm/data/dialogue/dialogue_opening.json; scripts/dialogue/dialogue_loader.gd; Assets/Audio/voice/TED_S1_01.mp3")
im.save(OUT / "c3.png")
segs.append(seg_still(OUT / "c3.png", 11, "s3.mp4"))

# 4. in the engine
cap = caption("Step 4: in the engine (recorded by Godot's movie writer)",
              "The player knocks; GameState fires GAME_STARTED; dialogue_loader plays TED_S1_01: the subtitle and the voice "
              "clip, muffled because Ted is inside and the player outside.")
cap.save(OUT / "cap4.png")
segs.append(seg_clip(HERE / "intro.avi", 0.5, 21.0, OUT / "cap4.png", "s4.mp4"))

# 5. the asset
fal = json.loads((REPO / "LightingTheStorm/Assets/Models/prop/lhi_barograph.fal_result.json").read_text(encoding="utf-8"))
sub = fal["submission"]
im = card("Step 5", "An asset: generated, recorded, imported, placed",
          "The Asset agent's submission is checked offline, then main_fal.py sends it to FAL and writes the model straight into "
          "the project with a record of the request. An import script scales it to its category's real size.",
          mono_lines=[
              ("LightingTheStorm/Assets/Models/prop/lhi_barograph.fal_result.json", DIM),
              (f'  "fal_model":  "{sub["fal_model"]}"', SILVER),
              (f'  "request_id": "{fal["request_id"]}"', SILVER),
              (f'  "category":   "{sub["category"]}"', SILVER),
              ('  "prompt":     "' + sub["prompt"][:70] + '..."', SILVER),
              ("", SILVER),
              ('tools/import_scale_pivot.gd: scales by category, pivot to the base   (1 unit = 1 m)', AMBER)],
          source="AIAgentCrew/main_fal.py; the .fal_result.json beside the model; Game Audit/FAL_SPEND.md ($0.375 per text-to-3D model)")
im.save(OUT / "c5.png")
segs.append(seg_still(OUT / "c5.png", 9, "s5.mp4"))
cap = caption("Step 5: in the level",
              "lhi_barograph.glb on the L2 side table in the tower, placed by hero_props.gd and shaded by the game's toon look.")
cap.save(OUT / "cap5.png")
segs.append(seg_clip(HERE / "prop.avi", 2.5, 7.0, OUT / "cap5.png", "s5b.mp4"))

# 6. verified
im = card("Step 6", "Verified by the headless test suite",
          "63 test scripts run against the real level. The full playthrough plays the slice from the knock to the win and "
          "fails if any story moment's line is not spoken.",
          mono_lines=[
              ("$ tools/run_all_tests.sh -j 4", AMBER),
              ("63 pass, 1 skipped (by design), 0 fail of 64", GREEN),
              ("", SILVER),
              ("$ godot --headless --path . --script res://tools/test_slice_playthrough.gd", AMBER),
              ("PASS  every moment had its line spoken (nothing left unspoken: [])", GREEN),
              ("RESULT: OK (0 failed)", GREEN)],
          body_lines=["Also from the pipeline and in the build: the return crossing (Storm Crossing Crew: 5 segments, 15 hazards, "
                      "Arthur's calls), the boat, movement and lighting specs (World Crew), 68 voiced lines, 78 FAL models."],
          source="GERFramework/reports/playtest_qa_suite.md (3 Nov 2026)")
im.save(OUT / "c6.png")
segs.append(seg_still(OUT / "c6.png", 10, "s6.mp4"))

lst = OUT / "list.txt"
lst.write_text("".join(f"file '{p.as_posix()}'\n" for p in segs), encoding="utf-8")
final = HERE / "pipeline_to_game.mp4"
run(["-f", "concat", "-safe", "0", "-i", str(lst), "-c", "copy", "-movflags", "+faststart", str(final)])
print("wrote", final)
