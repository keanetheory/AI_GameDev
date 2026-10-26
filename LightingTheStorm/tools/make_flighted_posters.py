"""Draws the Flighted posters (Lighthouse Finisher Agent, LHF-09) as 2048-safe PNGs with an alpha edge.
Canon (Docs/Lore Build/factions/fac_flighted.md): crude letterpress propaganda, black, silver and navy ink only, a dark sphere
eclipsing a silver moon above stylised waves, misregistered print, weathered and peeling paper; slogans THEY BRING THE STORMS
and THEY CHANGE THE SEASONS (nothing else). Two layouts of each slogan so no two posters on a wall are identical.
usage: python tools/make_flighted_posters.py   -> Assets/Textures/interior/poster_*.png
"""
import math
import random
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont

OUT = Path(__file__).resolve().parent.parent / "Assets" / "Textures" / "interior"
W, H = 576, 800                       # 0.72 x 1.0 m at 800 px per metre
BLACK, NAVY, SILVER = (14, 14, 18), (26, 36, 66), (178, 184, 192)
PAPER = (190, 174, 140)
FONT = "C:/Windows/Fonts/georgiab.ttf"


def paper(rng):
    im = Image.new("RGB", (W, H), PAPER)
    px = im.load()
    for y in range(H):
        for x in range(W):
            n = rng.random() * 18 - 9
            px[x, y] = tuple(max(0, min(255, int(c + n))) for c in PAPER)
    big = Image.effect_noise((W, H), 38).convert("L").filter(ImageFilter.GaussianBlur(12))
    tint = Image.merge("RGB", [big.point(lambda v: 150 + v // 5)] * 3)
    im = ImageChops.multiply(im, tint.point(lambda v: min(255, int(v * 1.12))))
    return im


def shift(layer, dx, dy):
    """Offset a plate without wrapping it round the sheet."""
    out = Image.new("L", layer.size, 0)
    out.paste(layer, (dx, dy))
    return out


def ink_layer(size=(W, H)):
    return Image.new("L", size, 0)


def rough(mask, rng, amt=1.5):
    """Letterpress roughness: ink dropout and a slightly furred edge."""
    noise = Image.effect_noise(mask.size, 80).point(lambda v: 255 if v > 112 else 0)
    return ImageChops.multiply(mask.filter(ImageFilter.GaussianBlur(amt)).point(lambda v: 255 if v > 110 else 0), noise.point(lambda v: 255 if v else 200))


def waves(d, y0, rng, rows=7):
    for r in range(rows):
        y = y0 + r * 19
        amp = 5 + r
        pts = [(x, y + math.sin(x / (22 + r * 3) + r) * amp) for x in range(0, W + 8, 8)]
        d.line(pts, fill=255, width=4 + r // 3)


def eclipse(cx, cy, r, layout):
    moon = ink_layer()
    dm = ImageDraw.Draw(moon)
    dm.ellipse((cx - r, cy - r, cx + r, cy + r), fill=255)
    for k in range(3):                              # moon rays
        dm.ellipse((cx - r - 16 - k * 14, cy - r - 16 - k * 14, cx + r + 16 + k * 14, cy + r + 16 + k * 14), outline=255, width=2)
    sphere = ink_layer()
    ds = ImageDraw.Draw(sphere)
    off = r * (0.42 if layout == 0 else -0.42)
    ds.ellipse((cx + off - r * 0.95, cy + r * 0.12 - r * 0.95, cx + off + r * 0.95, cy + r * 0.12 + r * 0.95), fill=255)
    return moon, sphere


def lettering(text, size, y, ink, rng, fill=255):
    d = ImageDraw.Draw(ink)
    f = ImageFont.truetype(FONT, size)
    for i, line in enumerate(text.split("\n")):
        w = d.textlength(line, font=f)
        d.text(((W - w) / 2 + rng.randint(-2, 2), y + i * (size + 8)), line, font=f, fill=fill)


def torn_alpha(rng):
    a = Image.new("L", (W, H), 255)
    d = ImageDraw.Draw(a)
    for side in range(4):
        for _ in range(26):
            t = rng.random()
            depth = rng.choice([3, 5, 8, 14, 26]) if rng.random() < 0.3 else rng.randint(1, 5)
            w = rng.randint(6, 22)
            if side == 0:
                d.rectangle((t * W, 0, t * W + w, depth), fill=0)
            elif side == 1:
                d.rectangle((t * W, H - depth, t * W + w, H), fill=0)
            elif side == 2:
                d.rectangle((0, t * H, depth, t * H + w), fill=0)
            else:
                d.rectangle((W - depth, t * H, W, t * H + w), fill=0)
    for c in ((0, 0), (W, 0), (0, H), (W, H)):      # a curled or ripped corner
        if rng.random() < 0.7:
            r = rng.randint(30, 80)
            d.polygon([c, (c[0] + (r if c[0] == 0 else -r), c[1]), (c[0], c[1] + (r if c[1] == 0 else -r))], fill=0)
    return a.filter(ImageFilter.GaussianBlur(0.8)).point(lambda v: 255 if v > 128 else 0)


def poster(name, slogan, layout, seed):
    rng = random.Random(seed)
    size = 56 if "SEASONS" in slogan else 62
    im = paper(rng)
    black, navy, silver = ink_layer(), ink_layer(), ink_layer()
    # border: a double rule, as a printer's frame
    for ink in (black,):
        d = ImageDraw.Draw(ink)
        d.rectangle((22, 22, W - 22, H - 22), outline=255, width=6)
        d.rectangle((36, 36, W - 36, H - 36), outline=255, width=2)
    if layout == 0:
        lettering(slogan, size, 62, black, rng)
        cy = 430
    else:
        cy = 300
        lettering(slogan, size, H - 62 - 2 * (size + 8), black, rng)
    moon, sphere = eclipse(W // 2, cy, 118, layout)
    silver = ImageChops.lighter(silver, moon)
    black = ImageChops.lighter(black, sphere)
    sphere_cut = sphere.filter(ImageFilter.MaxFilter(7))
    silver = ImageChops.multiply(silver, sphere_cut.point(lambda v: 255 - v))        # the sphere hides the moon
    wl = ink_layer()
    waves(ImageDraw.Draw(wl), cy + 150 if layout == 0 else cy + 140, rng)
    navy = ImageChops.lighter(navy, wl)
    lettering("THE FLIGHTED" if False else "", 20, 0, black, rng)
    # misregistration: the navy and silver plates are off the black plate by a few pixels, each a little differently
    navy = shift(navy, rng.randint(2, 6), rng.randint(-5, -2))
    silver = shift(silver, rng.randint(-5, -2), rng.randint(2, 5))
    for layer, col, amt in ((silver, SILVER, 1.2), (navy, NAVY, 1.4), (black, BLACK, 1.0)):
        m = rough(layer, rng, amt)
        solid = Image.new("RGB", (W, H), col)
        im = Image.composite(solid, im, m.point(lambda v: int(v * 0.93)))
    # wheat-paste drips and stains, a fold crease, grime toward the bottom
    d = ImageDraw.Draw(im, "RGBA")
    for _ in range(9):
        x = rng.randint(40, W - 40)
        y0 = rng.randint(0, H // 2)
        d.rectangle((x, y0, x + rng.randint(3, 8), y0 + rng.randint(40, 190)), fill=(70, 58, 40, rng.randint(22, 50)))
    d.rectangle((0, H // 2 - 2, W, H // 2 + 2), fill=(40, 34, 28, 60))
    d.rectangle((W // 2 - 2, 0, W // 2 + 2, H), fill=(40, 34, 28, 36))
    grime = Image.linear_gradient("L").resize((W, H)).point(lambda v: int(v * 0.35))
    im = Image.composite(Image.new("RGB", (W, H), (34, 28, 22)), im, grime)
    a = torn_alpha(rng)
    out = im.convert("RGBA")
    out.putalpha(a)
    OUT.mkdir(parents=True, exist_ok=True)
    out.save(OUT / f"{name}.png")
    print("wrote", OUT / f"{name}.png")


if __name__ == "__main__":
    poster("poster_storms_a", "THEY BRING\nTHE STORMS", 0, 11)
    poster("poster_storms_b", "THEY BRING\nTHE STORMS", 1, 12)
    poster("poster_seasons_a", "THEY CHANGE\nTHE SEASONS", 0, 21)
    poster("poster_seasons_b", "THEY CHANGE\nTHE SEASONS", 1, 22)
