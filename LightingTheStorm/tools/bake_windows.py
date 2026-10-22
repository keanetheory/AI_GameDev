"""Bake data/world/lighthouse_windows.json into Level.tscn: one carve box per window, appended to the Lighthouse node's
carve_oriented_any (a triangle of the exterior model goes when any corner is inside). Idempotent: the window boxes are the
entries after the first (the first is the room-clearing box). Run from the project root: python tools/bake_windows.py"""
import json, math, re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
TOWER = (3.5, 3.6)
SILL = (-3.494, 8.874)
U = (0.9024, -0.4309)       # house u axis in lighthouse (x, z)
V = (-0.4309, -0.9024)      # house v axis


def house_to_lh(u, v):
    return (SILL[0] + U[0] * u + V[0] * v, SILL[1] + U[1] * u + V[1] * v)


def box(xaxis, yaxis, zaxis, origin):
    # Transform3D(row0, row1, row2, origin): row i = (x_axis[i], y_axis[i], z_axis[i])
    r = [(xaxis[i], yaxis[i], zaxis[i]) for i in range(3)]
    vals = [c for row in r for c in row] + list(origin)
    return "Transform3D(" + ", ".join("%.4f" % v for v in vals) + ")"


def window_box(w):
    h, ww = w["h"] + 0.5, w["w"] + 0.5
    if w["kind"] == "tower":
        a = math.radians(w["bearing"])
        t = (-math.sin(a), 0.0, math.cos(a))
        n = (math.cos(a), 0.0, math.sin(a))
        depth, rc = 2.6, 3.9
        origin = (TOWER[0] + rc * n[0], w["y"], TOWER[1] + rc * n[2])
        return box((t[0] * ww, 0, t[2] * ww), (0, h, 0), (n[0] * depth, 0, n[2] * depth), origin)
    if w["wall"] == "west":
        x, z = house_to_lh(-3.7, w["at"])
        xa = (V[0] * ww, 0, V[1] * ww)
        za = (U[0] * 1.6, 0, U[1] * 1.6)
    else:
        x, z = house_to_lh(w["at"], 9.4)
        xa = (U[0] * ww, 0, U[1] * ww)
        za = (V[0] * 1.8, 0, V[1] * 1.8)
    return box(xa, (0, h, 0), za, (x, w["y"], z))


def clear_box(c):
    """A box inside the tower that removes exterior-model triangles hanging into the stairwell (any corner inside)."""
    a = math.radians(c["bearing"])
    t = (-math.sin(a), 0.0, math.cos(a))
    n = (math.cos(a), 0.0, math.sin(a))
    rc, depth = (c["r0"] + c["r1"]) * 0.5, c["r1"] - c["r0"]
    return box((t[0] * c["tangent"], 0, t[2] * c["tangent"]), (0, c["y1"] - c["y0"], 0), (n[0] * depth, 0, n[2] * depth),
               (TOWER[0] + rc * n[0], (c["y0"] + c["y1"]) * 0.5, TOWER[1] + rc * n[2]))


def main():
    data = json.loads((ROOT / "data/world/lighthouse_windows.json").read_text(encoding="utf-8"))
    tscn = ROOT / "scenes/Level.tscn"
    text = tscn.read_text(encoding="utf-8")
    i = text.index('[node name="Lighthouse" type="Node3D"')
    m = re.compile(r"carve_oriented_any = Array\[Transform3D\]\(\[(.*?)\]\)\n", re.S).search(text, i)
    existing = re.findall(r"Transform3D\([^)]*\)", m.group(1))
    boxes = existing[:1] + [window_box(w) for w in data["windows"]] + [clear_box(c) for c in data.get("clear", [])]
    new = "carve_oriented_any = Array[Transform3D]([" + ", ".join(boxes) + "])\n"
    text = text[:m.start()] + new + text[m.end():]
    tscn.write_text(text, encoding="utf-8")
    print("baked %d window boxes" % (len(boxes) - 1))


if __name__ == "__main__":
    main()
