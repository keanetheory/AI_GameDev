"""build_page_atlas.py - the lighthouse's paper pages and the Flighted posters, from the creator's generated images (2 Nov 2026).

  python -I tools/build_page_atlas.py

Reads Assets/Textures/interior/incoming/ (the images exactly as generated) and writes:
  - Assets/Textures/interior/pages_atlas.png: the 13 pages packed into one 2048 texture, so every page in the lighthouse shares one
    material (the lighthouse material budget, T63);
  - data/world/pages_atlas.json: each page's rectangle in the atlas (0..1 UVs) and its aspect (width / height), read by kit.gd page();
  - Assets/Textures/interior/poster_*.png: the four posters, copied over the old letterpress ones (rooms_house.gd _poster loads them).
Each image keeps its own shape: the page in the game takes its height from the aspect, so nothing is cropped or stretched. White
paper-less margins (a torn edge on a white background, the corners round a sign) are cut to transparency, flood-filled in from the
image border, so the page's own pale paper is never touched. Wording and choices: Docs/Lore Build/regions/reg_bracken_isle.md.
"""
import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "Assets" / "Textures" / "interior" / "incoming"
OUT_TEX = ROOT / "Assets" / "Textures" / "interior" / "pages_atlas.png"
OUT_JSON = ROOT / "data" / "world" / "pages_atlas.json"
SIZE = 2048
PAD = 8                     # pixels between pages, filled with each page's edge colour so mipmaps do not bleed

# slot -> source image (as delivered)
PAGES = {
    "storm_log": "ChatGPT Image Nov 2, 2026, 06_55_12 PM-1.png",
    "radio_log": "ChatGPT Image Nov 2, 2026, 06_55_13 PM-2.png",
    "tide_table": "ChatGPT Image Nov 2, 2026, 06_55_14 PM-3.png",
    "keepers_rules": "ChatGPT Image Nov 2, 2026, 06_55_15 PM-4.png",
    "calendar": "ChatGPT Image Nov 2, 2026, 06_55_16 PM-5.png",
    "barometer_note": "ChatGPT Image Nov 2, 2026, 06_55_18 PM-6.png",
    "chart_saltgate": "ChatGPT Image Nov 2, 2026, 06_55_18 PM-7.png",
    "chart_gullwater": "ChatGPT Image Nov 2, 2026, 06_55_20 PM-8.png",
    "notice": "ChatGPT Image Nov 2, 2026, 06_55_20 PM-9.png",
    "sailings": "ChatGPT Image Nov 2, 2026, 06_55_22 PM-10.png",
    "photo_t": "page_photo_t.png",
    "sign_store": "sign_store.png",
    "plate_steam": "plate_steam.png",
}
# each page's width in the game (metres): pages share one pixels-per-metre, so a small page is as sharp as a big one
WIDTH_M = {"storm_log": 0.9, "radio_log": 0.45, "tide_table": 0.34, "keepers_rules": 0.5, "calendar": 0.32, "barometer_note": 0.36,
           "chart_saltgate": 0.85, "chart_gullwater": 0.5, "notice": 0.2, "sailings": 0.2, "photo_t": 0.22, "sign_store": 0.5,
           "plate_steam": 0.34}
POSTERS = ["poster_storms_a.png", "poster_storms_b.png", "poster_seasons_a.png", "poster_seasons_b.png"]


def cut_white_margin(im: Image.Image) -> Image.Image:
    """Make the near-white background that touches the border transparent (flood fill from every border pixel)."""
    im = im.convert("RGBA")
    w, h = im.size
    px = im.load()

    def white(p):
        r, g, b, a = p
        return a > 0 and min(r, g, b) > 228 and max(r, g, b) - min(r, g, b) < 22

    mask = Image.new("L", (w, h), 0)
    mp = mask.load()
    stack = [(x, y) for x in range(w) for y in (0, h - 1)] + [(x, y) for y in range(h) for x in (0, w - 1)]
    while stack:
        x, y = stack.pop()
        if mp[x, y] or not white(px[x, y]):
            continue
        mp[x, y] = 255
        if x > 0: stack.append((x - 1, y))
        if x < w - 1: stack.append((x + 1, y))
        if y > 0: stack.append((x, y - 1))
        if y < h - 1: stack.append((x, y + 1))
    mask = mask.filter(ImageFilter.MaxFilter(3))          # take the anti-aliased white fringe too
    alpha = im.getchannel("A")
    alpha.paste(0, mask=mask)
    im.putalpha(alpha)
    return im


def bleed(im: Image.Image, n: int) -> Image.Image:
    """Grow the opaque colours n pixels into the transparent area (colour only), so filtering at an edge stays paper-coloured."""
    rgb = im.convert("RGB")
    a = im.getchannel("A")
    solid = Image.new("RGB", im.size)
    solid.paste(rgb, mask=a)
    grown = solid
    m = a
    for _ in range(n):
        grown = grown.filter(ImageFilter.MaxFilter(3))
        m = m.filter(ImageFilter.MaxFilter(3))
    out = grown.copy()
    out.paste(rgb, mask=a)
    res = out.convert("RGBA")
    res.putalpha(a)
    return res


def pack(items, ppm):
    """Shelf packing, tallest first, each page at ppm pixels per metre (never above its source size). items: [(slot, img)].
    Returns {slot: (x, y, w, h)} or None if they do not fit."""
    sized = []
    for s, im in items:
        w = min(im.width, int(WIDTH_M[s] * ppm))
        sized.append((s, max(1, w), max(1, int(w * im.height / im.width))))
    sized.sort(key=lambda t: -t[2])
    x = y = shelf = 0
    out = {}
    for s, w, h in sized:
        if x + w + PAD > SIZE:
            x, y, shelf = 0, y + shelf + PAD, 0
        if y + h + PAD > SIZE or w + PAD > SIZE:
            return None
        out[s] = (x + PAD // 2, y + PAD // 2, w, h)
        x += w + PAD
        shelf = max(shelf, h)
    return out


def main():
    items = []
    for slot, name in PAGES.items():
        items.append((slot, cut_white_margin(Image.open(SRC / name))))
    scale = 3000.0          # pixels per metre, lowered until everything fits
    layout = pack(items, scale)
    while layout is None:
        scale *= 0.97
        layout = pack(items, scale)
    atlas = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    meta = {"note": "Built by tools/build_page_atlas.py from the creator's generated pages (2 Nov 2026). uv: [x, y, w, h] in 0..1 of the atlas; aspect: width / height of the page.", "texture": "res://Assets/Textures/interior/pages_atlas.png", "pages": {}}
    src = dict(items)
    for slot, (x, y, w, h) in layout.items():
        im = bleed(src[slot].resize((w, h), Image.LANCZOS), PAD // 2)
        tile = Image.new("RGBA", (w + PAD, h + PAD), (0, 0, 0, 0))
        tile.paste(bleed(src[slot].resize((w + PAD, h + PAD), Image.LANCZOS), PAD // 2).convert("RGB"), (0, 0))
        tile.putalpha(0)
        atlas.paste(tile, (x - PAD // 2, y - PAD // 2))        # colour only round the page, fully transparent
        atlas.paste(im, (x, y))
        meta["pages"][slot] = {"uv": [x / SIZE, y / SIZE, w / SIZE, h / SIZE], "aspect": round(src[slot].width / src[slot].height, 4), "px": [w, h], "source": PAGES[slot]}
    atlas.save(OUT_TEX)
    OUT_JSON.write_text(json.dumps(meta, indent=1) + "\n", encoding="utf-8")
    print("atlas %dx%d, %.0f px per metre, %d pages -> %s" % (SIZE, SIZE, scale, len(layout), OUT_TEX.relative_to(ROOT)))
    for name in POSTERS:
        im = Image.open(SRC / name).convert("RGBA")
        im.save(ROOT / "Assets" / "Textures" / "interior" / name)
        print("poster", name, im.size)


if __name__ == "__main__":
    main()
