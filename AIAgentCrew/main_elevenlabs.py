"""Send the Voice Casting crew's ElevenLabs requests. Dry run by default: nothing is sent without --send.

Stage 1, Voice Design previews (the only stage built so far):
  python main_elevenlabs.py design --casting voice_output_picked_live              # dry run: prints what would be sent
  python main_elevenlabs.py design --casting voice_output_picked_live --send       # one request per speaker (3 calls)

Stage 2, save the previews you picked to your ElevenLabs voice library (one call per speaker, no audio credits):
  python main_elevenlabs.py save --casting voice_output_picked_live --pick TED=2 ARTHUR=3 DANIEL=2            # dry run
  python main_elevenlabs.py save --casting voice_output_picked_live --pick TED=2 ARTHUR=3 DANIEL=2 --send
Writes <casting>/elevenlabs/voices.json ({speaker: voice_id}).

Stage 3, generate line audio (spends credits): tts --casting <dir> --lines TED_S1_01 ... [--send]  -> elevenlabs/lines/<ID>.mp3

Stage 1 reads <casting>/elevenlabs/voice_design_requests.json, writes <casting>/elevenlabs/previews/<SPEAKER>_<n>.mp3 and
design_results.json (generated_voice_ids). The API key is read from .env as ELEVENLABS_API_KEY and never printed.
Refuses a casting folder that is not a live, reviewed plan (voice_casting.json mode 'llm') unless --allow-offline.
"""
import argparse
import base64
import json
import os
import sys
import urllib.error
import urllib.request
from pathlib import Path

API = "https://api.elevenlabs.io"


def load_key() -> str | None:
    try:
        from dotenv import load_dotenv
        load_dotenv()
    except ImportError:
        pass
    key = os.getenv("ELEVENLABS_API_KEY") or next((v for k, v in os.environ.items() if k.strip() == "ELEVENLABS_API_KEY"), None)
    return key.strip() if key else None


def post(path: str, body: dict, key: str, query: str = "") -> dict:
    req = urllib.request.Request(f"{API}{path}{query}", data=json.dumps(body).encode("utf-8"), method="POST",
                                 headers={"xi-api-key": key, "Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=180) as r:
        return json.loads(r.read().decode("utf-8"))


def design(args) -> int:
    folder = Path(args.casting)
    plan = json.loads((folder / "voice_casting.json").read_text(encoding="utf-8"))
    if plan.get("mode") != "llm" and not args.allow_offline:
        print(f"[elevenlabs] {folder} is a '{plan.get('mode')}' casting (scripted, not model- and Canon-reviewed). "
              "Run main_voice.py live first, or pass --allow-offline.", file=sys.stderr)
        return 2
    if plan.get("status") != "proposed":
        print(f"[elevenlabs] casting status is '{plan.get('status')}', not 'proposed'; fix the review first.", file=sys.stderr)
        return 2
    reqs = json.loads((folder / "elevenlabs" / "voice_design_requests.json").read_text(encoding="utf-8"))
    if args.only:
        reqs = [r for r in reqs if r["speaker"] in args.only]
    for r in reqs:
        b = r["body"]
        print(f"[{r['speaker']}] {r['endpoint']}\n  model_id: {b['model_id']}\n  voice_description ({len(b['voice_description'])} chars): "
              f"{b['voice_description']}\n  text ({len(b['text'])} chars): {b['text'][:120]}...")
    if not args.send:
        print(f"\n[elevenlabs] dry run: {len(reqs)} request(s) NOT sent. Add --send to call the API.")
        return 0
    key = load_key()
    if not key:
        print("[elevenlabs] ELEVENLABS_API_KEY is not set in .env.", file=sys.stderr)
        return 2
    out = folder / "elevenlabs" / "previews"
    out.mkdir(parents=True, exist_ok=True)
    results = {}
    for r in reqs:
        sp = r["speaker"]
        try:
            resp = post("/v1/text-to-voice/design", r["body"], key, "?output_format=mp3_44100_128")
        except urllib.error.HTTPError as e:
            print(f"[{sp}] HTTP {e.code}: {e.read().decode('utf-8', 'replace')[:500]}", file=sys.stderr)
            return 1
        saved = []
        for i, p in enumerate(resp.get("previews", []), 1):
            f = out / f"{sp}_{i}.mp3"
            f.write_bytes(base64.b64decode(p["audio_base_64"]))
            saved.append({"file": str(f.relative_to(folder)), "generated_voice_id": p["generated_voice_id"],
                          "duration_secs": p.get("duration_secs")})
        results[sp] = {"previews": saved, "text": resp.get("text")}
        print(f"[{sp}] {len(saved)} preview(s): " + ", ".join(f"{s['file']} ({s['duration_secs']:.1f}s)" for s in saved))
    (folder / "elevenlabs" / "design_results.json").write_text(json.dumps(results, indent=1), encoding="utf-8")
    print("\n[elevenlabs] done. Listen to the previews and pick one per speaker; nothing is saved to your voice library yet.")
    return 0


def save(args) -> int:
    folder = Path(args.casting)
    res = json.loads((folder / "elevenlabs" / "design_results.json").read_text(encoding="utf-8"))
    reqs = {r["speaker"]: r["body"] for r in json.loads((folder / "elevenlabs" / "voice_design_requests.json").read_text(encoding="utf-8"))}
    picks = dict(x.split("=") for x in args.pick)
    jobs = []
    for sp, n in picks.items():
        prev = res[sp]["previews"][int(n) - 1]
        jobs.append((sp, prev, {"voice_name": f"Lighting the Storm - {sp.title()}", "voice_description": reqs[sp]["voice_description"],
                                "generated_voice_id": prev["generated_voice_id"], "labels": {"game": "Lighting the Storm", "character": sp.title()}}))
        print(f"[{sp}] preview {n} ({prev['file']}) -> voice '{jobs[-1][2]['voice_name']}'")
    if not args.send:
        print("\n[elevenlabs] dry run: nothing saved. Add --send to save these voices to your library.")
        return 0
    key = load_key()
    if not key:
        print("[elevenlabs] ELEVENLABS_API_KEY is not set in .env.", file=sys.stderr)
        return 2
    voices = {}
    for sp, prev, body in jobs:
        try:
            voices[sp] = post("/v1/text-to-voice", body, key)["voice_id"]
        except urllib.error.HTTPError as e:
            print(f"[{sp}] HTTP {e.code}: {e.read().decode('utf-8', 'replace')[:500]}", file=sys.stderr)
            return 1
        print(f"[{sp}] saved, voice_id {voices[sp]}")
    (folder / "elevenlabs" / "voices.json").write_text(json.dumps(voices, indent=1), encoding="utf-8")
    return 0


def tts(args) -> int:
    folder = Path(args.casting)
    voices = json.loads((folder / "elevenlabs" / "voices.json").read_text(encoding="utf-8"))
    reqs = {r["line_id"]: r for r in json.loads((folder / "elevenlabs" / "tts_requests.json").read_text(encoding="utf-8"))}
    if args.remaining:  # every line that has no audio file yet
        args.lines = [i for i in reqs if not (folder / "elevenlabs" / "lines" / f"{i}.mp3").exists()]
    if not args.lines:
        print("[elevenlabs] no lines to generate.")
        return 0
    unknown = [i for i in args.lines if i not in reqs]
    if unknown:
        print(f"[elevenlabs] unknown line IDs: {unknown}", file=sys.stderr)
        return 2
    chars = sum(len(reqs[i]["body"]["text"]) for i in args.lines)
    for i in args.lines:
        r = reqs[i]
        print(f"[{i}] voice {voices[r['speaker']]} model {r['body']['model_id']}")
        print(f"  text: {r['body']['text']}")
        print(f"  settings: {r['body']['voice_settings']}")
    print(f"\n{len(args.lines)} line(s), {chars} characters of text.")
    if not args.send:
        print("[elevenlabs] dry run: nothing generated. Add --send to generate audio (this spends credits).")
        return 0
    key = load_key()
    if not key:
        print("[elevenlabs] ELEVENLABS_API_KEY is not set in .env.", file=sys.stderr)
        return 2
    out = folder / "elevenlabs" / "lines"
    out.mkdir(parents=True, exist_ok=True)
    for i in args.lines:
        r = reqs[i]
        req = urllib.request.Request(f"{API}/v1/text-to-speech/{voices[r['speaker']]}?output_format=mp3_44100_128",
                                     data=json.dumps(r["body"]).encode("utf-8"), method="POST",
                                     headers={"xi-api-key": key, "Content-Type": "application/json"})
        try:
            with urllib.request.urlopen(req, timeout=180) as resp:
                audio = resp.read()
        except urllib.error.HTTPError as e:
            print(f"[{i}] HTTP {e.code}: {e.read().decode('utf-8', 'replace')[:600]}", file=sys.stderr)
            return 1
        (out / f"{i}.mp3").write_bytes(audio)
        print(f"[{i}] saved {out / (i + '.mp3')} ({len(audio) // 1024} KB)")
    return 0


def main() -> int:
    ap = argparse.ArgumentParser(description="ElevenLabs sender for the Voice Casting crew")
    sub = ap.add_subparsers(dest="stage", required=True)
    d = sub.add_parser("design", help="stage 1: Voice Design previews")
    d.add_argument("--casting", required=True, help="voice casting output folder")
    d.add_argument("--send", action="store_true", help="actually call the API (default: dry run)")
    d.add_argument("--only", nargs="*", help="speakers to send, e.g. TED")
    d.add_argument("--allow-offline", action="store_true")
    v = sub.add_parser("save", help="stage 2: save picked previews as voices")
    v.add_argument("--casting", required=True)
    v.add_argument("--pick", nargs="+", required=True, help="SPEAKER=preview number, e.g. TED=2")
    v.add_argument("--send", action="store_true")
    t = sub.add_parser("tts", help="stage 3: generate line audio")
    t.add_argument("--casting", required=True)
    t.add_argument("--lines", nargs="*", default=[], help="line IDs, e.g. TED_S1_01")
    t.add_argument("--remaining", action="store_true", help="all lines without an audio file yet")
    t.add_argument("--send", action="store_true")
    args = ap.parse_args()
    return {"design": design, "save": save, "tts": tts}[args.stage](args)


if __name__ == "__main__":
    sys.exit(main())
