"""Phase 1 - SURVEY. Deterministic (no model): gather the evidence the analysis compares.

Four sources, matching the brief:
  1. Docs/  - the GDD (Exec Summary, Technical Strategy, AI Agent Strategy) in full, other docs indexed
  2. ConceptArt/ - an index, plus one downscaled image per folder so the model can actually see the look
  3. AIAgentCrew/ - the crew briefs (roles.py roster, README, world_output specs)
  4. LightingTheStorm/ - the game project as it is now (tree, line counts, readme, known issues)
"""
from pathlib import Path

from . import config
from .tools import image_block, IMAGE_SUFFIXES, SKIP_DIRS, SKIP_SUFFIXES

GDD_CORE = ["Exec Summary.md", "Technical Strategy.md", "AI Agent Strategy.md",
            "Supporting_Documentation/Decisions to be made.md", "What's Changed (Concise).md"]


def _read(p: Path, limit=None) -> str:
    t = p.read_text(encoding="utf-8", errors="replace")
    return t if not limit or len(t) <= limit else t[:limit] + f"\n... [truncated, {len(t):,} chars total; read the rest with read_file]"


def _tree(base: Path, skip_names=(), max_depth=6) -> str:
    lines = []

    def walk(d: Path, level: int):
        for c in sorted(d.iterdir(), key=lambda c: (c.is_file(), c.name.lower())):
            if c.name in SKIP_DIRS or c.suffix in SKIP_SUFFIXES or c.name in skip_names:
                continue
            if c.is_dir():
                n = sum(1 for _ in c.rglob("*") if _.is_file() and _.suffix not in SKIP_SUFFIXES)
                lines.append(f"{'  ' * level}{c.name}/  [{n} files]")
                if level + 1 < max_depth:
                    walk(c, level + 1)
            else:
                extra = ""
                if c.suffix in {".gd", ".gdshader", ".tscn", ".json", ".md", ".py"}:
                    try:
                        extra = f", {sum(1 for _ in c.open(encoding='utf-8', errors='ignore'))} lines"
                    except OSError:
                        pass
                lines.append(f"{'  ' * level}{c.name}  ({c.stat().st_size:,} B{extra})")
    walk(base, 0)
    return "\n".join(lines)


def build(images=True) -> dict:
    """Returns {"text": str, "images": [(label, block)], "stats": {...}}."""
    parts, stats = [], {}

    # 1. Docs ---------------------------------------------------------------------------------
    parts.append("# SOURCE 1: DOCS (the GDD, read in full)\n")
    gdd_chars = 0
    for rel in GDD_CORE:
        p = config.GDD / rel
        if p.exists():
            t = _read(p)
            gdd_chars += len(t)
            parts.append(f"\n===== Docs/GDD/Final_GDD_Post_Review/{rel} =====\n{t}")
    stats["gdd_chars"] = gdd_chars
    parts.append("\n===== Other docs available on demand (read_file) =====\n" +
                 _tree(config.DOCS, skip_names={"archive"}, max_depth=3))
    synth = config.DOCS / "GDD" / "AI_Reviews" / "reviews" / "SYNTHESIS.md"
    if synth.exists():
        parts.append(f"\n===== Docs/GDD/AI_Reviews/reviews/SYNTHESIS.md (review board synthesis) =====\n{_read(synth, 9000)}")

    # 2. Concept art --------------------------------------------------------------------------
    parts.append("\n# SOURCE 2: CONCEPT ART (index; one image per folder is attached to the first message)\n")
    imgs, art_lines = [], []
    for folder in sorted(d for d in config.CONCEPT_ART.iterdir() if d.is_dir()):
        files = sorted(f for f in folder.iterdir() if f.suffix.lower() in IMAGE_SUFFIXES)
        art_lines.append(f"ConceptArt/{folder.name}/ ({len(files)} images): " + "; ".join(f.name for f in files))
        if images and files:
            imgs.append((f"ConceptArt/{folder.name}/{files[0].name}", image_block(files[0], 640, 70)))
    root_imgs = [f.name for f in config.CONCEPT_ART.iterdir() if f.suffix.lower() in IMAGE_SUFFIXES]
    if root_imgs:
        art_lines.append("ConceptArt/ (root): " + "; ".join(root_imgs))
    parts.append("\n".join(art_lines))
    stats["art_folders"] = len(art_lines)
    stats["art_images_attached"] = len(imgs)

    # 3. AI crew briefs -----------------------------------------------------------------------
    parts.append("\n# SOURCE 3: AI CREW BRIEFS\n")
    for rel in ("AIAgentCrew/roles.py", "AIAgentCrew/story_beats.py"):
        p = config.ROOT / rel
        if p.exists():
            parts.append(f"\n===== {rel} =====\n{_read(p, 14000)}")
    p = config.CREW / "README.md"
    if p.exists():
        parts.append(f"\n===== AIAgentCrew/README.md (first part) =====\n{_read(p, 9000)}")
    parts.append("\n===== AIAgentCrew/world_output (the crew's world specs; read on demand) =====\n" +
                 _tree(config.CREW / "world_output", max_depth=2))
    parts.append("\n===== AIAgentCrew top level =====\n" +
                 "\n".join(sorted(c.name for c in config.CREW.iterdir() if c.is_file() and c.suffix in {".py", ".md"})))

    # 4. The game -----------------------------------------------------------------------------
    parts.append("\n# SOURCE 4: THE GAME, LightingTheStorm/ as it is now\n")
    parts.append("===== file tree of LightingTheStorm/ (paths shown relative to it; use the LightingTheStorm/ prefix in tools) =====\n" + _tree(config.GAME, max_depth=5))
    for rel in ("project.godot", "readme.md", "things to work on next.md"):
        p = config.GAME / rel
        if p.exists():
            parts.append(f"\n===== LightingTheStorm/{rel} =====\n{_read(p, 8000)}")
    n_gd = sum(1 for _ in config.GAME.rglob("*.gd"))
    stats["game_scripts"] = n_gd

    text = "\n".join(parts)
    stats["context_chars"] = len(text)
    stats["approx_tokens"] = len(text) // 4
    return {"text": text, "images": imgs, "stats": stats}
