import math, random
from PIL import Image, ImageDraw, ImageFont, ImageFilter, ImageChops
random.seed(7)
W, H = 1920, 1080
S = 2
w, h = W * S, H * S
import os
HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "INTRO_SPLASH_SCREEN.png")


def hx(c):
    return tuple(int(c[i:i + 2], 16) for i in (1, 3, 5))


INK = hx("#0E0E10"); NAVY = hx("#1F2A44"); SLATE = hx("#2C3A40")
STONE = hx("#6B6B66"); SILV = hx("#B9BEC4"); AMB = hx("#C07A1E"); GOLD = hx("#B8962E")

img = Image.new("RGB", (w, h), INK)
d = ImageDraw.Draw(img)
bands = [INK, (14, 17, 24), (19, 25, 38), (25, 33, 52)]
hor = int(h * 0.60)
for i in range(hor):
    t = i / hor
    idx = min(int(t ** 1.6 * 4), 3)
    d.line([(0, i), (w, i)], fill=bands[idx])


def wline(pts, width, fill, j=1.6, closed=False):
    """Hand-traced ink line: subdivided with perpendicular jitter."""
    if closed:
        pts = list(pts) + [pts[0]]
    out = []
    for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
        L = math.hypot(x1 - x0, y1 - y0)
        n = max(1, int(L / (14 * S)))
        nx, ny = (-(y1 - y0) / (L or 1), (x1 - x0) / (L or 1))
        for k in range(n):
            t = k / n
            o = random.uniform(-j, j) * S
            out.append((x0 + (x1 - x0) * t + nx * o, y0 + (y1 - y0) * t + ny * o))
    out.append(pts[-1])
    d.line(out, fill=fill, width=int(width * S), joint="curve")


def circle_pts(cx, cy, r, n=90):
    return [(cx + math.cos(2 * math.pi * k / n) * r, cy + math.sin(2 * math.pi * k / n) * r) for k in range(n)]


# stepped (banded, not blurred) cold glow where the moon is hidden
mx, my, mr = int(w * 0.72), int(h * 0.27), int(h * 0.15)
for k, c in zip((2.1, 1.75, 1.45, 1.2), ((17, 21, 31), (20, 26, 38), (24, 31, 46), (30, 38, 56))):
    rr = mr * k
    d.ellipse([mx - rr, my - rr, mx + rr, my + rr], fill=c)
# silver moon, fully covered by the dark sphere with a thin rim all round
d.ellipse([mx - mr, my - mr, mx + mr, my + mr], fill=SILV)
sr = int(mr * 0.935)
d.ellipse([mx - sr, my - sr, mx + sr, my + sr], fill=INK)
wline(circle_pts(mx, my, sr), 4, (6, 6, 8), 0.9, True)
# one faint hint of a vessel: a tilted seam and a barely-there keel point
d.line([(mx - sr * 0.97, my + sr * 0.22), (mx - sr * 0.4, my + sr * 0.12), (mx + sr * 0.4, my + sr * 0.04),
        (mx + sr * 0.97, my - sr * 0.12)], fill=(28, 34, 46), width=3 * S, joint="curve")
d.polygon([(mx - 9 * S, my + sr - 2 * S), (mx + 9 * S, my + sr - 2 * S), (mx + 1 * S, my + sr + 11 * S)], fill=INK)


# stormy cel-shaded clouds: pale cold rim, hard shadow, layered back to front
def storm_cloud(cx, cy, wd, ht, shade):
    lobes = []
    for k in range(random.randint(6, 9)):
        lx = cx + random.uniform(-0.5, 0.5) * wd
        r = random.uniform(0.16, 0.30) * wd
        ly = cy - abs(lx - cx) / wd * ht * 0.8 - random.uniform(0, 0.35) * ht
        lobes.append((lx, ly, r))
    rim = (52, 62, 82)
    for lx, ly, r in lobes:
        d.ellipse([lx - r, ly - r * ht / wd * 2.2, lx + r, ly + r * ht / wd * 2.2], fill=rim)
    for lx, ly, r in lobes:
        o = r * 0.16
        d.ellipse([lx - r + o, ly - r * ht / wd * 2.2 + o * 1.6, lx + r + o, ly + r * ht / wd * 2.2 + o * 1.6], fill=shade)


clouds = []
for i in range(60):
    cx = random.randint(-200, w + 200)
    cy = random.randint(int(h * 0.02), int(h * 0.58))
    wd = random.randint(500, 1100)
    if abs(cx - mx) < mr * 1.6 + wd * 0.45 and abs(cy - my) < mr * 1.9:
        continue
    clouds.append((cy, cx, wd))
    if len(clouds) >= 26:
        break
clouds.sort()
for cy, cx, wd in clouds:
    t = cy / (h * 0.6)
    shade = (int(24 - 10 * t), int(30 - 12 * t), int(44 - 16 * t))
    storm_cloud(cx, cy, wd, random.randint(160, 300), shade)
# two low clouds drifting across the eclipse
storm_cloud(mx - mr * 0.5, my + mr * 1.05, mr * 2.2, 120, (14, 17, 24))
storm_cloud(mx + mr * 1.0, my - mr * 0.15, mr * 1.4, 90, (18, 22, 32))


# lightning with a hard-edged flash
def bolt(x, y, ang, length, wdt, depth=0):
    pts = [(x, y)]
    for _ in range(length):
        ang += random.uniform(-0.6, 0.6)
        x += math.sin(ang) * random.randint(22, 46) * S
        y += math.cos(ang) * random.randint(22, 46) * S
        pts.append((x, y))
        if depth < 1 and random.random() < 0.09:
            bolt(x, y, ang + random.choice((-1, 1)) * 0.7, length // 2, max(2, wdt - 2), depth + 1)
    d.line(pts, fill=(110, 130, 170), width=(wdt + 8) * S, joint="curve")
    d.line(pts, fill=(238, 242, 252), width=wdt * S, joint="curve")


lbx = int(w * 0.50)
bolt(int(w * 0.47), int(h * 0.0), 0.10, 15, 6)

# sea
sea_top = hor
d.rectangle([0, sea_top, w, h], fill=SLATE)
for r in range(26):
    t = r / 26
    y0 = sea_top + int((t ** 1.5) * (h - sea_top))
    amp = (5 + t * 40) * S
    per = (90 + t * 330) * S
    col = [(40, 54, 60), (28, 39, 45), (21, 29, 35)][r % 3]
    ph = random.random() * 6
    pts = [(0, h)]
    for x in range(0, w + 20, 10 * S):
        pts.append((x, y0 + math.sin(x / per * 2 * math.pi + ph) * amp))
    pts.append((w, h))
    d.polygon(pts, fill=col)
    wline(pts[1:-1], 2 + t * 4, INK, 1.4)
for k in range(40):
    y = sea_top + random.randint(6 * S, int((h - sea_top) * .7))
    f = 1 + (y - sea_top) / (h - sea_top)
    wd_ = random.randint(20, 120) * S * f
    x = mx + random.randint(-int(80 * S * f), int(80 * S))
    d.line([(x - wd_ / 2, y), (x + wd_ / 2, y)], fill=(58, 66, 80), width=3 * S)

# isle
isle = [(0, h * 0.98), (0, h * 0.74), (w * 0.06, h * 0.70), (w * 0.11, h * 0.66), (w * 0.17, h * 0.60),
        (w * 0.215, h * 0.575), (w * 0.26, h * 0.58), (w * 0.30, h * 0.64), (w * 0.36, h * 0.72),
        (w * 0.44, h * 0.80), (w * 0.55, h * 0.86), (w * 0.62, h * 0.98)]
d.polygon(isle, fill=(30, 31, 32))
d.polygon([(w * 0.11, h * 0.66), (w * 0.17, h * 0.60), (w * 0.215, h * 0.575), (w * 0.26, h * 0.58),
           (w * 0.21, h * 0.80), (w * 0.13, h * 0.9)], fill=(42, 43, 43))
d.polygon([(w * 0.215, h * 0.575), (w * 0.26, h * 0.58), (w * 0.30, h * 0.64), (w * 0.36, h * 0.72),
           (w * 0.25, h * 0.8)], fill=(22, 23, 24))
# cold lightning rim along the isle's right-facing slope
wline([(w * 0.26, h * 0.58), (w * 0.30, h * 0.64), (w * 0.36, h * 0.72), (w * 0.44, h * 0.80)], 3, (96, 110, 134), 1.2)
wline(isle[1:-1], 5, INK, 2.0)
for k in range(30):
    x = random.randint(int(w * .02), int(w * .5))
    y = random.randint(int(h * .7), int(h * .97))
    wline([(x, y), (x + random.randint(30, 90) * S, y + random.randint(-20, 30) * S)], 3, INK, 1.2)

# lighthouse: unlit, lens cracked
bx = int(w * 0.225); by = int(h * 0.585)
bw0 = int(w * 0.032); bw1 = int(w * 0.019); top = int(h * 0.20)
gy = top + int(h * .06)
tower = [(bx - bw0, by), (bx + bw0, by), (bx + bw1, gy), (bx - bw1, gy)]
d.polygon(tower, fill=(58, 59, 57))
d.polygon([(bx - bw0, by), (bx - bw0 * 0.15, by), (bx - bw1 * 0.15, gy), (bx - bw1, gy)], fill=(36, 37, 38))  # shadow side
d.polygon([(bx + bw0 * 0.80, by), (bx + bw0, by), (bx + bw1, gy), (bx + bw1 * 0.80, gy)], fill=(112, 126, 150))  # cold rim
for k in range(1, 9):
    y = gy + k * (by - gy) // 9
    f = k / 9
    hw = bw1 + (bw0 - bw1) * f
    wline([(bx - hw, y), (bx + hw, y)], 2, INK, 1.0)
wline(tower, 5, INK, 1.8, True)
# upper window dark; lower window: dim amber with a figure
y = int(h * 0.38)
d.rectangle([bx - 7 * S, y, bx + 7 * S, y + 34 * S], fill=(10, 11, 14), outline=INK, width=3 * S)
y = int(h * 0.50)
d.rectangle([bx - 8 * S, y, bx + 8 * S, y + 36 * S], fill=(112, 70, 20), outline=INK, width=3 * S)
d.ellipse([bx - 4 * S, y + 9 * S, bx + 4 * S, y + 19 * S], fill=INK)
d.polygon([(bx - 8 * S, y + 36 * S), (bx - 7 * S, y + 22 * S), (bx + 7 * S, y + 22 * S), (bx + 8 * S, y + 36 * S)], fill=INK)
d.line([(bx, y), (bx, y + 36 * S)], fill=INK, width=2 * S)
# gallery, lantern, roof
d.rectangle([bx - bw1 * 1.6, gy - 6 * S, bx + bw1 * 1.6, gy + 8 * S], fill=INK)
d.polygon([(bx + bw1 * 1.0, gy + 8 * S), (bx + bw1 * 1.6, gy + 8 * S), (bx + bw1 * 1.6, gy - 6 * S), (bx + bw1 * 1.0, gy - 6 * S)], fill=(112, 126, 150))
lw = int(bw1 * 0.95)
lt = gy - int(h * .055); lb = gy - 6 * S
d.rectangle([bx - lw, lt, bx + lw, lb], fill=(18, 20, 24))
# cracked lens
cr = (118, 128, 142)
cxl, cyl = bx, (lt + lb) // 2
for ang, ln in ((-2.4, 0.55), (-1.1, 0.5), (0.3, 0.6), (1.4, 0.45), (2.5, 0.55)):
    pts = [(cxl, cyl)]
    x, y = cxl, cyl
    for _ in range(4):
        ang += random.uniform(-0.5, 0.5)
        x += math.cos(ang) * (lb - lt) * ln / 4
        y += math.sin(ang) * (lb - lt) * ln / 4
        pts.append((x, y))
    d.line(pts, fill=cr, width=2 * S)
d.polygon([(cxl + 2 * S, cyl - 12 * S), (cxl + lw * 0.7, cyl - 4 * S), (cxl + 3 * S, cyl + 6 * S)], fill=(4, 4, 6))  # missing shard
wline([(bx - lw, lt), (bx + lw, lt), (bx + lw, lb), (bx - lw, lb)], 4, INK, 1.2, True)
for k in (-1, 0, 1):
    d.line([(bx + k * lw * 0.6, lt), (bx + k * lw * 0.6, lb)], fill=INK, width=3 * S)
d.polygon([(bx - lw * 1.3, lt), (bx + lw * 1.3, lt), (bx, top - int(h * .02))], fill=INK)
d.line([(bx + lw * 0.5, lt - 4 * S), (bx, top - int(h * .02))], fill=(112, 126, 150), width=3 * S)
d.line([(bx, top - int(h * .02)), (bx, top - int(h * .045))], fill=INK, width=3 * S)

d.polygon([(w * 0.55, sea_top - 46 * S), (w, sea_top - 60 * S), (w, sea_top + 6 * S), (w * 0.55, sea_top + 6 * S)], fill=(52, 64, 84))
d.polygon([(w * 0.62, sea_top - 22 * S), (w, sea_top - 30 * S), (w, sea_top + 6 * S), (w * 0.62, sea_top + 6 * S)], fill=(70, 84, 106))
# ship: 1800s steam passenger liner in the swell, one funnel, two masts, smoke plume, one dim lamp
sx, sy = int(w * 0.80), int(h * 0.595)
K = 1.7


def rot(dx, dy, ang=-0.09):
    dx *= K * S; dy *= K * S
    return (sx + dx * math.cos(ang) - dy * math.sin(ang), sy + dx * math.sin(ang) + dy * math.cos(ang))


def poly(pts, fill):
    d.polygon([rot(*p) for p in pts], fill=fill)


SH = (14, 16, 22)
# smoke first so the hull overlaps it
smoke = Image.new("RGBA", (w, h), (0, 0, 0, 0))
sm = ImageDraw.Draw(smoke)
for k in range(14):
    px, py = rot(-5 - k * 24, -66 - k * 2.5)
    rr = (12 + k * 6) * S
    sm.ellipse([px - rr, py - rr * .6, px + rr, py + rr * .6], fill=(10, 11, 15, 235 - k * 13))
img = Image.alpha_composite(img.convert("RGBA"), smoke).convert("RGB")
d = ImageDraw.Draw(img)
poly([(-100, -6), (110, -6), (85, 24), (-75, 24)], INK)
poly([(-60, -26), (55, -26), (55, -6), (-60, -6)], SH)
poly([(-14, -62), (4, -62), (4, -26), (-14, -26)], INK)
poly([(-16, -62), (6, -62), (6, -57), (-16, -57)], (6, 6, 8))
for mxo in (-72, 70):
    d.line([rot(mxo, -6), rot(mxo, -80)], fill=INK, width=3 * S)
d.line([rot(-72, -70), rot(-100, -10)], fill=INK, width=2 * S)
d.line([rot(70, -80), rot(100, -8)], fill=INK, width=2 * S)
lampx, lampy = rot(-20, -14)
d.rectangle([lampx, lampy, lampx + 7 * S, lampy + 7 * S], fill=(150, 92, 26))  # single dim amber lamp
wline([rot(-100, -6), rot(110, -6), rot(85, 24), rot(-75, 24)], 2, (6, 6, 8), 0.8, True)

# whitecaps / spray
for k in range(70):
    x = random.randint(int(w * .55), w); y = random.randint(int(sea_top + 10 * S), int(h * 0.62))
    L = random.randint(30, 140) * S * (0.4 + (y - sea_top) / (h - sea_top))
    d.line([(x, y), (x + L, y - random.randint(0, 8) * S)], fill=(140, 148, 158), width=random.randint(2, 5) * S)

# rain
rain = Image.new("RGBA", (w, h), (0, 0, 0, 0))
rd = ImageDraw.Draw(rain)
for k in range(3200):
    x = random.randint(-300, w); y = random.randint(0, h); l = random.randint(40, 110) * S // 2
    rd.line([(x, y), (x - l * 0.35, y + l)], fill=(185, 190, 196, random.randint(40, 110)), width=S)
img = Image.alpha_composite(img.convert("RGBA"), rain).convert("RGB")
d = ImageDraw.Draw(img)

# grime: scratches, specks, mottled paint texture
for k in range(500):
    x = random.randint(0, w); y = random.randint(0, h)
    d.line([(x, y), (x + random.randint(-60, 60) * S, y + random.randint(-60, 60) * S)], fill=(10, 10, 12), width=S)
for k in range(220):
    x = random.randint(0, w); y = random.randint(0, h); rr = random.randint(1, 4) * S
    d.ellipse([x, y, x + rr, y + rr], fill=(150, 152, 150))
mott = Image.effect_noise((w // 8, h // 8), 60).resize((w, h), Image.BICUBIC).convert("L").point(lambda v: 170 + v // 4)
img = ImageChops.multiply(img, Image.merge("RGB", [mott] * 3))
# vignette
vig = Image.new("L", (w, h), 0)
ImageDraw.Draw(vig).ellipse([-w * 0.25, -h * 0.35, w * 1.25, h * 1.35], fill=255)
vig = vig.filter(ImageFilter.GaussianBlur(160 * S))
img = Image.composite(img, Image.new("RGB", (w, h), INK), vig)
noise = Image.effect_noise((w, h), 38).convert("L").point(lambda v: 200 + v // 5)
img = Image.blend(img, ImageChops.multiply(img, Image.merge("RGB", [noise] * 3)), 0.5)
img = img.resize((W, H), Image.LANCZOS)


def font(p, s):
    return ImageFont.truetype("C:/Windows/Fonts/" + p, s)


def ctext(layer, y, text, f, fill, off=(0, 0), track=0):
    dl = ImageDraw.Draw(layer)
    tw = sum(dl.textlength(c, font=f) + track for c in text) - track
    x = (W - tw) / 2 + off[0]
    for c in text:
        dl.text((x, y + off[1]), c, font=f, fill=fill)
        x += dl.textlength(c, font=f) + track


base = img.convert("RGBA")
fT = font("ROCKEB.TTF", 112)
T = "LIGHTING THE STORM"
ty = 700
lay = Image.new("RGBA", (W, H), (0, 0, 0, 0))
ctext(lay, ty, T, fT, (0, 0, 0, 220), (8, 10), 6)
base = Image.alpha_composite(base, lay.filter(ImageFilter.GaussianBlur(6)))
for off, col in [((-5, -3), NAVY + (255,)), ((5, 3), AMB + (255,))]:
    l = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ctext(l, ty, T, fT, col, off, 6)
    base = Image.alpha_composite(base, l)
l = Image.new("RGBA", (W, H), (0, 0, 0, 0))
ctext(l, ty, T, fT, (172, 178, 184, 255), (0, 0, 0), 6)
stain = Image.new("RGBA", (W, H), (0, 0, 0, 0))
sd_ = ImageDraw.Draw(stain)
for k in range(70):
    x = random.randint(300, 1620); y = random.randint(ty - 10, ty + 150); r = random.randint(8, 36)
    sd_.ellipse([x, y, x + r * 2, y + r], fill=(46, 44, 40, random.randint(60, 130)))
for k in range(30):
    x = random.randint(300, 1620)
    sd_.line([(x, ty + 20), (x + random.randint(-6, 6), ty + random.randint(80, 190))], fill=(34, 34, 34, 110), width=random.randint(2, 4))
stain = stain.filter(ImageFilter.GaussianBlur(2))
alpha = l.getchannel("A")
l = Image.alpha_composite(l, stain)
l.putalpha(alpha)
wear = Image.new("L", (W, H), 255)
wd = ImageDraw.Draw(wear)
for k in range(2200):
    x = random.randint(300, 1620); y = random.randint(ty, ty + 190); r = random.choice([1, 1, 2, 3])
    wd.ellipse([x, y, x + r, y + r], fill=0)
for k in range(40):
    x = random.randint(300, 1620); y = random.randint(ty, ty + 190)
    wd.line([(x, y), (x + random.randint(20, 80), y + random.randint(-3, 3))], fill=0, width=1)
l.putalpha(ImageChops.multiply(l.getchannel("A"), wear))
base = Image.alpha_composite(base, l)

lay = Image.new("RGBA", (W, H), (0, 0, 0, 0))
dl = ImageDraw.Draw(lay)
f2 = font("georgiai.ttf", 34)
tag = "Tonight the beacon has failed."
tw = dl.textlength(tag, font=f2)
dl.text(((W - tw) / 2 + 2, ty + 212), tag, font=f2, fill=(0, 0, 0, 230))
dl.text(((W - tw) / 2, ty + 210), tag, font=f2, fill=AMB + (255,))
for sgn in (-1, 1):
    x0 = W / 2 + sgn * (tw / 2 + 30); x1 = W / 2 + sgn * (tw / 2 + 240)
    dl.line([(x0, ty + 232), (x1, ty + 232)], fill=GOLD + (200,), width=2)
f3 = font("ROCKB.TTF", 17)
pr = "PRESS ANY KEY"
tw3 = sum(dl.textlength(c, font=f3) + 5 for c in pr) - 5
x = W - 56 - tw3
for c in pr:
    dl.text((x + 1, H - 46 + 1), c, font=f3, fill=(0, 0, 0, 220))
    dl.text((x, H - 46), c, font=f3, fill=(185, 190, 196, 190))
    x += dl.textlength(c, font=f3) + 5
base = Image.alpha_composite(base, lay)
out = base.convert("RGB")
out.save(OUT)
