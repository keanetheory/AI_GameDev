"""Reads Docs/Lore Build/world/style_guide.md and turns it into deterministic checks.

The Asset agent (and its guardrails) read the guide live, so editing the markdown changes what gets
approved. Nothing in the guide is copied into code except the keyword groups that detect whether a
prompt actually uses the guide's style descriptors.
"""
import re
from dataclasses import dataclass, field
from pathlib import Path

STYLE_GUIDE_PATH = Path(__file__).resolve().parents[1] / "Docs" / "Lore Build" / "world" / "style_guide.md"

# A prompt "uses the style" when it covers at least MIN_GROUPS of these (cel shading is mandatory).
KEYWORD_GROUPS = {
    "cel shading": ("cel-shaded", "cel shaded", "cel-shading", "cel shading"),
    "ink outlines": ("ink outline", "heavy ink", "linework", "line work", "inked"),
    "muted palette": ("muted", "desaturated"),
    "grimy hand-painted texture": ("grimy", "hand-painted", "hand painted"),
}
MIN_GROUPS = 3

# Never allowed in a positive prompt, whatever the guide says (guide: touchstones are human-only).
ALWAYS_FORBIDDEN = {
    "named reference touchstone": r"scanner darkly|borderlands",
    "'in the style of' reference": r"\bstyle of\b",
    "photoreal rendering": r"photo-?real(istic)?",
    "modern or sci-fi era": r"\bmodern\b|futuristic|sci-?fi|cyberpunk",
    "retired city name": r"brusskania",
}
# Negative-list items too abstract to match as words inside a positive prompt.
ABSTRACT_NEGATIVES = {"real artist names", "franchise characters", "text artefacts"}


@dataclass
class StyleGuide:
    art_style: str
    palette: list[str]
    descriptors: list[str]
    negatives: list[str]
    colour_meanings: dict[str, str] = field(default_factory=dict)  # name -> hex
    text: str = ""

    @property
    def palette_all(self) -> set[str]:
        """Global palette plus every hex given a colour meaning (Ted green/red etc.)."""
        return {h.upper() for h in self.palette} | {h.upper() for h in self.colour_meanings.values()}


def load_style_guide(path: Path | None = None) -> StyleGuide:
    path = path or STYLE_GUIDE_PATH
    text = path.read_text(encoding="utf-8")
    art = re.search(r"^art_style:\s*(.+)$", text, re.M)
    pal = re.search(r"^global_palette:\s*\[(.*?)\]", text, re.M)
    palette = re.findall(r"#[0-9A-Fa-f]{6}", pal.group(1)) if pal else []

    descriptors = []
    block = re.search(r"Style descriptors.*?:\*\*\s*\n((?:\s+- .+\n?)+)", text)
    if block:
        descriptors = [m.strip() for m in re.findall(r"^\s+- (.+)$", block.group(1), re.M)]

    neg = re.search(r"## Global Negative Prompts\s*\n+(.+)", text)
    negatives = [n.strip() for n in neg.group(1).split(",") if n.strip()] if neg else []

    meanings = {}
    for name, hexv in re.findall(r"^\|\s*([A-Za-z ]+?)\s*\|\s*(#[0-9A-Fa-f]{6})\s*\|", text, re.M):
        meanings[name.strip()] = hexv
    if not (palette and descriptors and negatives):
        raise ValueError(f"Could not read palette, descriptors and negatives from {path}")
    return StyleGuide(art.group(1).strip() if art else "", palette, descriptors, negatives, meanings, text)


def style_block(guide: StyleGuide) -> str:
    """Text given to the agents as their source of truth for look and feel."""
    return (
        "STYLE GUIDE (locked; source: Docs/Lore Build/world/style_guide.md)\n"
        f"Art style: {guide.art_style}\n"
        "Style descriptors to use in prompts: " + "; ".join(guide.descriptors) + "\n"
        "Palette: " + ", ".join(guide.palette) + "\n"
        "Colour meanings: " + ", ".join(f"{k} {v}" for k, v in guide.colour_meanings.items()) + "\n"
        "Global negative prompts (every submission's negative prompt must include all of these): "
        + ", ".join(guide.negatives) + "\n"
        "Rules: era is mid-to-late 1800s gaslight and steam. Moonlight is absent or eclipsed. Electric arc "
        "and steam light are the only strong sources during the eclipse. Storm light is cold, wet, high-contrast. "
        "Reference touchstones are for humans only: never name them in prompts. Saint Calder's colours are "
        "amber and gold. The Flighted are black, silver and navy."
    )


# ---------------- deterministic prompt checks ----------------
def _terms(text: str) -> set[str]:
    return {t.strip().lower() for t in re.split(r"[,;\n]", text) if t.strip()}


def check_prompt(prompt: str, guide: StyleGuide) -> list[str]:
    errs = []
    low = prompt.lower()
    covered = [g for g, words in KEYWORD_GROUPS.items() if any(w in low for w in words)]
    if "cel shading" not in covered or len(covered) < MIN_GROUPS:
        missing = [g for g in KEYWORD_GROUPS if g not in covered]
        errs.append(f"Prompt must use the style descriptors (cel shading plus at least {MIN_GROUPS} of "
                    f"{len(KEYWORD_GROUPS)} groups). Missing: {missing}.")
    for label, pattern in ALWAYS_FORBIDDEN.items():
        if re.search(pattern, prompt, re.I):
            errs.append(f"Prompt contains a forbidden {label}.")
    if re.search(r"\bby [A-Z][a-z]+ [A-Z][a-z]+\b", prompt):  # case-sensitive: 'by Firstname Lastname'
        errs.append("Prompt appears to name a real artist ('by Firstname Lastname').")
    for neg in guide.negatives:
        if neg.lower() in ABSTRACT_NEGATIVES:
            continue
        if re.search(rf"\b{re.escape(neg.lower().rstrip('s'))}s?\b", low):
            errs.append(f"Prompt asks for '{neg}', which the style guide lists as a negative.")
    stray = [h for h in re.findall(r"#[0-9A-Fa-f]{6}", prompt) if h.upper() not in guide.palette_all]
    if stray:
        errs.append(f"Prompt uses colours outside the style guide palette: {stray}.")
    return errs


def check_negative_prompt(negative: str, guide: StyleGuide) -> list[str]:
    have = _terms(negative)
    missing = [n for n in guide.negatives if n.lower() not in have]
    return [f"Negative prompt is missing global negatives: {missing}."] if missing else []


# ---------------- image palette check (Pillow) ----------------
def check_image(path: Path, guide: StyleGuide) -> tuple[list[str], dict]:
    """Rough look-and-feel check on the source image: muted, dark, near the palette. Returns (errors, metrics)."""
    from PIL import Image
    import colorsys

    img = Image.open(path).convert("RGBA")
    img.thumbnail((96, 96))
    px = [p for p in img.getdata() if p[3] > 200]
    if not px:
        return ["Image is fully transparent."], {}
    pal = [tuple(int(h[i:i + 2], 16) for i in (1, 3, 5)) for h in sorted(guide.palette_all)]
    sat = val = neon = near = 0
    for r, g, b, _ in px:
        h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
        sat += s
        val += v
        neon += s > 0.75 and v > 0.6
        near += min((r - a) ** 2 + (g - c) ** 2 + (b - d) ** 2 for a, c, d in pal) ** 0.5 < 70
    n = len(px)
    m = {"mean_saturation": round(sat / n, 3), "mean_brightness": round(val / n, 3),
         "neon_fraction": round(neon / n, 3), "near_palette_fraction": round(near / n, 3)}
    errs = []
    if m["mean_saturation"] > 0.5:
        errs.append(f"Image is too saturated for a muted, desaturated palette (mean saturation {m['mean_saturation']}).")
    if m["neon_fraction"] > 0.08:
        errs.append(f"Image has bright saturated colours ({m['neon_fraction']:.0%} of pixels); the guide bans neon.")
    if m["mean_brightness"] > 0.72:
        errs.append(f"Image is too bright for a dark, grim look (mean brightness {m['mean_brightness']}).")
    return errs, m
