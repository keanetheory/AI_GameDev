"""repair_exterior.py - Lighthouse exterior repair (Blender 5.2, headless): blender -b -P repair_exterior.py
Input : exterior_carved_in.glb  (tools/export_carved_exterior.gd: the exterior as the game sees it after the carves and the stray-mesh clip, Lighthouse frame)
Output: ../lighthouse_exterior_v4.glb  (root node "convert" > mesh node "material", the same names as v3, the same frame and the same texture)

What it does (the creator, 2026-10-26: "fastest, easiest way to resolve the holes" -> repair the mesh itself, once, instead of patching at run time):
  1. weld coincident vertices (the scan is a triangle soup);
  2. find every boundary loop (an open edge ring = a hole or a ragged cut);
  3. fill each loop except the ground rim (y < RIM_Y: the island hides it) and the lantern/gallery (y >= LANTERN_Y: built in code);
     tower holes are subdivided and pushed onto the tower's cylinder so the fill follows the wall's curve;
  4. the fill faces take ONE texel of the surrounding wall (the median-brightness texel along the hole's rim), so they are the wall's own colour and
     the run-time masonry shader (exterior_wall_detail) courses them like the rest;
  5. every real opening (windows, doors) is cut back out of the fill, so the openings are clean rectangles, not ragged holes.
Coordinates: Blender (X, Y, Z) = Godot (x, -z, y) once the node transforms are applied.
"""
import bpy, bmesh, json, math, os
from mathutils import Vector

HERE = os.path.dirname(os.path.abspath(__file__))
DATA = os.path.normpath(os.path.join(HERE, "..", "..", "..", "..", "data", "world"))
SPEC = json.load(open(os.path.join(DATA, "shell_spec.json")))
HO, YAW = SPEC["house_origin"], SPEC["house_yaw"]
AX, AZ = SPEC["tower_axis"]
RIM_Y = 1.0
LANTERN_Y = 17.9
GF, L1 = 0.97, 5.2025
STATS = {}


def god(v):
    """Blender world coordinate -> Godot (Lighthouse frame)."""
    return Vector((v.x, v.z, -v.y))


def blen(g):
    return Vector((g.x, -g.z, g.y))


def to_house(g):
    rx, rz = g.x - HO[0], g.z - HO[1]
    return rx * math.cos(YAW) - rz * math.sin(YAW), -(rx * math.sin(YAW) + rz * math.cos(YAW))


# ---------------------------------------------------------------- openings (Godot frame): True where a point is inside a real opening
def load_openings():
    wins = json.load(open(os.path.join(DATA, "lighthouse_windows.json")))["windows"]
    wins.append({"id": "T_landing_147", "kind": "tower", "bearing": 147.0, "y": 15.09, "w": 1.0, "h": 1.8})
    return wins


WINS = load_openings()


def inside_opening(g, m=0.1):
    y = g.y
    d = math.hypot(g.x - AX, g.z - AZ)
    th = math.degrees(math.atan2(g.z - AZ, g.x - AX)) % 360.0
    if 2.0 < d < 6.5:
        for w in WINS:
            if w["kind"] != "tower":
                continue
            half = math.degrees((w["w"] * 0.5 + m) / 3.3)
            if abs((th - w["bearing"] + 180) % 360 - 180) < half and abs(y - w["y"]) < w["h"] * 0.5 + m:
                return True
        if y < 3.6 and 127.5 < th < 165.0:
            return True           # the hall's doorway into the tower (tower_shell.gd G_DOOR)
        if 4.8 < y < 7.4 and 139.0 < th < 165.0:
            return True           # the first floor's doorway
    u, v = to_house(g)
    for w in WINS:
        if w["kind"] != "house":
            continue
        y0, y1 = w["y"] - w["h"] / 2 - m, w["y"] + w["h"] / 2 + m
        if w["wall"] == "west" and u < -2.0 and abs(v - w["at"]) < w["w"] / 2 + m and y0 < y < y1:
            return True
        if w["wall"] == "back" and v > 8.3 and abs(u - w["at"]) < w["w"] / 2 + m and y0 < y < y1:
            return True
    # (the ground-floor window over the dock, u < -1.9, v 3.0..4.3, y 1.9..2.9, is closed: creator, 2026-10-27 "just close it up for now")
    if -1.0 - m < u < 1.0 + m and -0.7 < v < 0.95 and GF - 0.05 < y < GF + 3.05:
        return True               # the front door
    if 5.0 < u < 9.0 and 0.8 - m < v < 2.25 + m and GF - 0.05 < y < GF + 2.4:
        return True               # the hall's door to the tower (house side)
    if 5.0 < u < 9.0 and 1.0 - m < v < 2.3 + m and L1 - 0.05 < y < L1 + 2.2:
        return True               # the first floor's door to the tower
    return False


def in_tower_window(g, shrink=0.04):
    """True where a point is inside a tower window's opening, `shrink` in from its edges, between the lining and just outside the wall."""
    d = math.hypot(g.x - AX, g.z - AZ)
    if not 2.0 < d < 4.8:
        return False
    th = math.degrees(math.atan2(g.z - AZ, g.x - AX)) % 360.0
    for w in WINS:
        if w["kind"] != "tower":
            continue
        half = math.degrees((w["w"] * 0.5 - shrink) / d)
        if abs((th - w["bearing"] + 180) % 360 - 180) < half and abs(g.y - w["y"]) < w["h"] * 0.5 - shrink:
            return True
    return False


def from_house(u, y, v):
    w = -v
    return Vector((HO[0] + u * math.cos(YAW) + w * math.sin(YAW), y, HO[1] - u * math.sin(YAW) + w * math.cos(YAW)))


def is_chimney_hole(c):
    """The closed ground-floor window: a hole through the chimney breast on the west gable (house u -3.9..-2.7, v 2.7..3.6, y 1.05..3.4)."""
    u, v = to_house(c)
    return u < -2.5 and 2.4 < v < 3.9 and 0.9 < c.y < 3.6


def main():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=os.path.join(HERE, "exterior_carved_in.glb"))
    ob = [o for o in bpy.data.objects if o.type == "MESH"][0]
    me = ob.data
    bm = bmesh.new()
    bm.from_mesh(me)
    bm.transform(ob.matrix_world)
    uvl = bm.loops.layers.uv.active
    mat = me.materials[0]
    img = None
    for n in mat.node_tree.nodes:
        if n.type == "TEX_IMAGE":
            img = n.image
    px = list(img.pixels) if img else None
    W, H = (img.size[0], img.size[1]) if img else (1, 1)
    print("faces", len(bm.faces), "image", img.name if img else None, W, H)

    def texel(uv):
        x = min(W - 1, max(0, int((uv[0] % 1.0) * W)))
        y = min(H - 1, max(0, int((uv[1] % 1.0) * H)))
        i = (y * W + x) * 4
        return (px[i], px[i + 1], px[i + 2])

    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-4)
    # the chimney breast's own stone round the closed window (outward-facing faces on its face plane, u about -3.75): the rim of that hole is mostly
    # brown cut-off flaps, so its fill takes its texel from here instead
    chim = []
    for f in bm.faces:
        g = god(f.calc_center_median())
        u, v = to_house(g)
        n = god(f.normal)
        nu = n.x * math.cos(YAW) - n.z * math.sin(YAW)
        if abs(u + 3.75) < 0.3 and 2.0 < v < 4.4 and 0.9 < g.y < 4.6 and not (2.6 < v < 3.7 and g.y < 3.5) and nu < -0.5:
            col = texel(f.loops[0][uvl].uv)
            chim.append((0.3 * col[0] + 0.59 * col[1] + 0.11 * col[2], tuple(f.loops[0][uvl].uv)))
    chim.sort()
    chim_uv = chim[len(chim) * 4 // 5][1] if chim else None      # the pale stone (the median is a dark mortar/soot texel)
    print("chimney face samples", len(chim), "brightness", [round(c[0], 2) for c in chim], "uv", chim_uv)
    bm.edges.ensure_lookup_table()
    bnd = [e for e in bm.edges if len(e.link_faces) == 1]
    parent = {}

    def find(x):
        while parent[x] != x:
            parent[x] = parent[parent[x]]
            x = parent[x]
        return x

    for e in bnd:
        for v in e.verts:
            parent.setdefault(v.index, v.index)
        a, b = find(e.verts[0].index), find(e.verts[1].index)
        if a != b:
            parent[a] = b
    loops = {}
    for e in bnd:
        loops.setdefault(find(e.verts[0].index), []).append(e)
    filled = skipped = 0
    new_faces_all = []
    for es in loops.values():
        vs = list({v for e in es for v in e.verts})
        gs = [god(v.co) for v in vs]
        ymin = min(g.y for g in gs)
        ymax = max(g.y for g in gs)
        if ymin < RIM_Y or ymax >= LANTERN_Y or len(es) < 3:
            skipped += 1
            continue
        c = sum(gs, Vector()) / len(gs)
        rads0 = sorted(math.hypot(g.x - AX, g.z - AZ) for g in gs)
        samples0 = []
        for v in vs:
            for lp in v.link_loops:
                uv0 = lp[uvl].uv
                col = texel(uv0)
                samples0.append((0.3 * col[0] + 0.59 * col[1] + 0.11 * col[2], (uv0[0], uv0[1])))
                break
        samples0.sort()
        uv_pick = samples0[len(samples0) // 2][1] if samples0 else (0.5, 0.5)
        rim_ids = {v.index for v in vs}
        before = set(bm.faces)
        try:
            res = bmesh.ops.triangle_fill(bm, use_beauty=True, use_dissolve=False, edges=es)
        except Exception as ex:
            print("fill failed", ex)
            skipped += 1
            continue
        nf = [f for f in bm.faces if f not in before]
        if not nf:
            skipped += 1
            continue
        # orientation: match the face across the first rim edge
        ref = es[0].link_faces[0].normal.copy() if es[0].link_faces else None
        fe = [f for f in nf if es[0] in f.edges]
        if ref is not None and fe and fe[0].normal.dot(ref) < 0:
            for f in nf:
                f.normal_flip()
        # tower holes follow the cylinder
        d = math.hypot(c.x - AX, c.z - AZ)
        tower = d < 4.6 and c.y > 4.2
        if tower:
            fe_ = list({e for f in nf for e in f.edges if e not in es})
            bmesh.ops.subdivide_edges(bm, edges=fe_, cuts=2, use_grid_fill=True)
            nf = [f for f in bm.faces if f not in before]
            rr = rads0[len(rads0) // 2]
            interior_verts = {v for f in nf for v in f.verts if v.index not in rim_ids}
            for v in interior_verts:
                g = god(v.co)
                dx, dz = g.x - AX, g.z - AZ
                dd = math.hypot(dx, dz) or 1.0
                v.co = blen(Vector((AX + dx / dd * rr, g.y, AZ + dz / dd * rr)))
        if is_chimney_hole(c):
            # the closed window: a flat stretch of the chimney's face, its inner points pushed onto the face plane, in the chimney's stone
            fe_ = list({e for f in nf for e in f.edges if e not in es})
            bmesh.ops.subdivide_edges(bm, edges=fe_, cuts=3, use_grid_fill=True)
            nf = [f for f in bm.faces if f not in before]
            rim_u = sorted(to_house(g)[0] for g in gs if to_house(g)[0] < -3.4)
            u_face = rim_u[len(rim_u) // 2] if rim_u else -3.75
            for v in {v for f in nf for v in f.verts if v.index not in rim_ids}:
                g = god(v.co)
                v.co = blen(from_house(u_face, g.y, to_house(g)[1]))
            if chim_uv:
                uv_pick = chim_uv
            STATS["chimney_hole"] = {"u_face": round(u_face, 3), "faces": len(nf)}
        faces_now = [f for f in nf if f.is_valid]
        for f in faces_now:
            for lp in f.loops:
                lp[uvl].uv = uv_pick
        new_faces_all.extend(faces_now)
        filled += 1
    # cut the real openings back out of the fill
    cut = 0
    for f in list(new_faces_all):
        if not f.is_valid:
            continue
        if inside_opening(god(f.calc_center_median())):
            bmesh.ops.delete(bm, geom=[f], context="FACES_ONLY")
            cut += 1
    # the scan's own triangles that the carve left reaching into a tower window (the brown shards across the stairwell windows, creator
    # 2026-10-27): any triangle with a corner more than 4 cm inside an opening goes; the reveal and the stone surround hide the notch it leaves
    shards = 0
    for f in list(bm.faces):
        if f.is_valid and any(in_tower_window(god(v.co)) for v in f.verts):
            bmesh.ops.delete(bm, geom=[f], context="FACES_ONLY")
            shards += 1
    STATS["window_shards"] = shards
    # leave smooth shading as the scan had it
    for f in bm.faces:
        f.smooth = True
    bm.normal_update()
    bm.to_mesh(me)
    bm.free()
    ob.matrix_world = ob.matrix_world.copy()
    me.transform(ob.matrix_world.inverted())      # back to local so the node transform stays as imported
    for o in list(bpy.data.objects):      # the importer's own root empty ("Exterior") is not wanted: one root, "convert"
        if o.type == "EMPTY":
            bpy.data.objects.remove(o, do_unlink=True)
    # names as v3: root "convert" > mesh "material"
    root = bpy.data.objects.new("convert", None)
    bpy.context.scene.collection.objects.link(root)
    ob.name = "material"
    ob.parent = root
    ob.matrix_parent_inverse = root.matrix_world.inverted()
    out = os.path.normpath(os.path.join(HERE, "..", "lighthouse_exterior_v4.glb"))
    bpy.ops.export_scene.gltf(filepath=out, export_format="GLB", export_yup=True, export_apply=False, export_image_format="AUTO")
    print("REPAIR_OK", out, "loops filled", filled, "skipped", skipped, "opening faces cut", cut, STATS)


main()
