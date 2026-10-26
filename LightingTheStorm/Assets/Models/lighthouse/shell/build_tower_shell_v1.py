"""Saint Calder lighthouse: authored TOWER shell v1 (Lighthouse finish, step D).
Run: blender -b -P build_tower_shell_v1.py        (Blender 4.2; writes lighthouse_tower_shell_v1.glb beside this script)
One closed, watertight tower: thick tapered wall with real window and door openings, the lantern deck and gallery slab, and a closed
dome cap seated on the lantern ring. Dimensions are the ones the interior is already built to (tower_shell.gd wall_radius, lantern.gd,
data/world/lighthouse_windows.json); the inner face IS the room's wall, so no lining is needed on top of it.
Coordinates: the Godot Lighthouse-node frame (x, y up, z); the tower axis is (3.5, y, 3.6). Blender (X, Y, Z) = Godot (x, -z, y).
"""
import bpy, bmesh, json, math, os
from mathutils import Vector

HERE = os.path.dirname(os.path.abspath(__file__))
DATA = os.path.normpath(os.path.join(HERE, "..", "..", "..", "..", "data", "world"))
AX, AZ = 3.5, 3.6
SIDES = 96                       # 3.75 degrees, the same sector the radii table and the lining use
WALL_T = 0.75                    # wall thickness (measured on the exterior: 0.55 to 1.05)
Y0, Y_LANTERN_FLOOR = 0.0, 17.9
DECK_TOP, DECK_T, DECK_R = 18.33, 0.33, 4.0
CEIL_Y = 21.95
APEX = 25.18


def r_in(y):
    """Inner radius: tower_shell.gd wall_radius without the measured pull-in. 3.0 plinth to 4.92, then a cone 3.4 down to 2.9."""
    if y < 4.92:
        return 3.0
    return max(2.9, 3.4 - 0.0385 * (y - 4.92))


def r_out(y):
    return r_in(y) + WALL_T + (0.35 if y < 4.92 else 0.0)      # a heavier plinth


def G(x, y, z):
    """Godot (x, y, z) -> Blender."""
    return Vector((x, -z, y))


def ring(bm, r, y, n=SIDES):
    vs = []
    for i in range(n):
        a = 2 * math.pi * i / n
        vs.append(bm.verts.new(G(AX + r * math.cos(a), y, AZ + r * math.sin(a))))
    return vs


def band(bm, lo, hi, flip=False):
    n = len(lo)
    for i in range(n):
        j = (i + 1) % n
        f = [lo[i], lo[j], hi[j], hi[i]]
        bm.faces.new(f[::-1] if flip else f)


def new_obj(name, bm, material):
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    ob = bpy.data.objects.new(name, me)
    ob.data.materials.append(material)
    bpy.context.scene.collection.objects.link(ob)
    return ob


def mat(name, col):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    m.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (*col, 1)
    return m


def wall_solid(m_stone):
    """A watertight tube: inner and outer skins from y 0 to the lantern floor, closed top and bottom."""
    bm = bmesh.new()
    ys = [Y0, 3.0, 4.92]
    y = 5.17
    while y < Y_LANTERN_FLOOR - 0.01:
        ys.append(y)
        y += 0.25
    ys.append(Y_LANTERN_FLOOR)
    inn = [ring(bm, r_in(y), y) for y in ys]
    out = [ring(bm, r_out(y), y) for y in ys]
    for k in range(len(ys) - 1):
        band(bm, inn[k], inn[k + 1])
        band(bm, out[k], out[k + 1])
    band(bm, inn[0], out[0])
    band(bm, inn[-1], out[-1])
    return new_obj("Tower_Wall", bm, m_stone)


def box_cutter(name, bearing_deg, y_c, w, h, r0, r1):
    """A box through the wall along `bearing` (degrees from +x toward +z round the axis): width w, height h, from radius r0 to r1."""
    a = math.radians(bearing_deg)
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    L = r1 - r0
    for v in bm.verts:
        v.co = Vector((v.co.x * L, v.co.y * w, v.co.z * h))
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    ob = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(ob)
    mid = (r0 + r1) * 0.5
    ob.location = G(AX + mid * math.cos(a), y_c, AZ + mid * math.sin(a))
    ob.rotation_euler = (0, 0, -a)       # Godot bearing (+x toward +z) is Blender angle -a about Z
    return ob


def cut(target, cutters):
    for c in cutters:
        md = target.modifiers.new("cut_" + c.name, "BOOLEAN")
        md.operation = "DIFFERENCE"
        md.solver = "EXACT"
        md.object = c
        bpy.context.view_layer.objects.active = target
        bpy.ops.object.modifier_apply(modifier=md.name)
        bpy.data.objects.remove(c, do_unlink=True)


def deck_and_cap(m_stone, m_roof):
    """Gallery slab (lantern floor to deck top 18.33, out to r 4.0, drip edge) and the closed dome cap on the lantern ring."""
    bm = bmesh.new()
    r_i = r_in(Y_LANTERN_FLOOR)
    r_o = r_out(Y_LANTERN_FLOOR)
    prof = [(r_i, Y_LANTERN_FLOOR), (r_i, DECK_TOP), (DECK_R, DECK_TOP), (DECK_R, DECK_TOP - 0.1), (DECK_R - 0.25, DECK_TOP - DECK_T), (r_o, DECK_TOP - DECK_T), (r_o, Y_LANTERN_FLOOR)]
    rings = [ring(bm, r, y) for r, y in prof]
    for k in range(len(rings)):
        band(bm, rings[k], rings[(k + 1) % len(rings)])
    new_obj("Gallery_Deck", bm, m_stone)
    bm2 = bmesh.new()
    outer = [(3.30, CEIL_Y - 0.2), (3.30, CEIL_Y), (3.0, CEIL_Y + 0.12), (2.5, CEIL_Y + 0.55), (1.8, CEIL_Y + 1.15), (1.0, CEIL_Y + 2.0), (0.45, CEIL_Y + 2.85), (0.12, APEX - 0.05)]
    inner = [(max(r - 0.15, 0.05), y - 0.12) for r, y in outer]
    inner[0] = (3.0, CEIL_Y - 0.2)
    ro = [ring(bm2, r, y) for r, y in outer]
    ri = [ring(bm2, r, y) for r, y in inner]
    for k in range(len(ro) - 1):
        band(bm2, ro[k], ro[k + 1])
        band(bm2, ri[k], ri[k + 1])
    band(bm2, ri[0], ro[0])
    bm2.faces.new(ro[-1])
    bm2.faces.new(ri[-1])
    new_obj("Lantern_Cap", bm2, m_roof)


def main():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    m_stone = mat("shell_stone", (0.45, 0.42, 0.38))
    m_roof = mat("shell_roof", (0.18, 0.2, 0.22))
    wall = wall_solid(m_stone)
    wins = json.load(open(os.path.join(DATA, "lighthouse_windows.json")))["windows"]
    wins = [w for w in wins if w["kind"] == "tower"] + [{"id": "T_landing_147", "bearing": 147.0, "y": 15.09, "w": 1.0, "h": 1.8}]
    cutters = [box_cutter("cut_" + w["id"], w["bearing"], w["y"], w["w"], w["h"], 2.0, 6.0) for w in wins]
    # doorways into the tower from the house: the hall (ground floor, 1.45 wide, 2.3 high) and the first floor (1.3 wide, 2.1 high), bearing 147
    cutters.append(box_cutter("cut_door_G", 147.0, 0.97 + 1.15, 1.45, 2.3, 2.0, 6.0))
    cutters.append(box_cutter("cut_door_L1", 147.0, 5.2025 + 1.05, 1.3, 2.1, 2.0, 6.0))
    cut(wall, cutters)
    deck_and_cap(m_stone, m_roof)
    for ob in bpy.data.objects:
        for p in ob.data.polygons:
            p.use_smooth = False
    out = os.path.join(HERE, "lighthouse_tower_shell_v1.glb")
    bpy.ops.export_scene.gltf(filepath=out, export_format="GLB", export_yup=True, export_apply=True)
    stats = {o.name: (len(o.data.vertices), len(o.data.polygons)) for o in bpy.data.objects}
    print("SHELL_OK", out, stats)


main()
