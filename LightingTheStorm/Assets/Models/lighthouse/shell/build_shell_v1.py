"""Saint Calder lighthouse: the authored SHELL v1 (Lighthouse finish, step D). Replaces the generated exterior mesh's walls, floors and roof.
Run: blender -b -P build_shell_v1.py     (Blender 5.2 or 4.2; writes lighthouse_shell_v1.glb beside this script)

Method: constructive solid geometry, so every surface is one clean closed skin and nothing can clip:
    solid = tower cone + house prisms (basement, ground, first-floor slab, first-floor walls, gable roof) + lantern deck + dome cap
    air   = every room's inner volume (the faces the interior is already built to, see rooms_house.gd / rooms_tower.gd / lantern.gd)
    shell = solid - air - openings
The house wins where it meets the tower: the tower's air is cut short by the house wall slab, so the two rooms are separated by a real wall
with the doorways cut through it.

Frames: HOUSE (u along the front wall, v inward, y up) as kit.gd; converted to the Lighthouse node's frame (Godot x, y, z), then to Blender
(X, Y, Z) = (x, -z, y). The house frame sits at (-3.494, 0, 8.874) in the Lighthouse frame, yawed 0.4457 rad (interior_rooms.gd).
"""
import bpy, bmesh, json, math, os
from mathutils import Vector, Matrix

HERE = os.path.dirname(os.path.abspath(__file__))
DATA = os.path.normpath(os.path.join(HERE, "..", "..", "..", "..", "data", "world"))
SPEC = json.load(open(os.path.join(DATA, "shell_spec.json")))      # shared with the Godot code that fits the interior to this shell
HOUSE_O = tuple(SPEC["house_origin"])
YAW = SPEC["house_yaw"]
AX, AZ = SPEC["tower_axis"]          # tower axis, Lighthouse frame
SIDES = 96
T = SPEC["house_wall_t"]             # house wall thickness, outward from the inner faces
WALL_T = SPEC["tower_wall_t"]        # tower wall thickness

# ---- levels (Lighthouse-frame y) ----
B1_FLOOR, B1_CEIL = -2.0, 0.77
GF, G_CEIL = 0.97, 3.75
SLAB_TOP, L1 = SPEC["slab_top"], 5.2025
L1_EAVE, L1_RIDGE = SPEC["l1_eave"], SPEC["l1_ridge"]      # underside heights: eaves at both long walls (v), ridge along u at the middle of v
ROOF_T = 0.28
LANTERN_FLOOR, DECK_TOP, DECK_R = 17.9, 18.33, 4.0
CEIL_Y, APEX = 21.95, 25.18

# ---- room inner faces in the house frame ----
G_U, G_V = tuple(SPEC["ground_u"]), tuple(SPEC["ground_v"])      # ground floor and basement
L1_U, L1_V = tuple(SPEC["first_u"]), tuple(SPEC["first_v"])      # first floor and the attic under the roof
TOWER_CUT_TOP = SPEC["tower_cut_top"]


def hf(u, y, v):
    """House frame (u, y, v) -> Lighthouse frame (x, y, z)."""
    c, s = math.cos(YAW), math.sin(YAW)
    # frame x axis = (cos, 0, -sin), frame local z = -v with frame z axis = (sin, 0, cos)
    x = HOUSE_O[0] + u * c + (-v) * s
    z = HOUSE_O[1] + u * (-s) + (-v) * c
    return (x, y, z)


def G(x, y, z):
    return Vector((x, -z, y))


def r_in(y):
    if y < 4.92:
        return 3.0
    return max(2.9, 3.4 - 0.0385 * (y - 4.92))


def r_out(y):
    return r_in(y) + WALL_T + (0.35 if y < 4.92 else 0.0)


def mat(name, col):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    m.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (*col, 1)
    return m


def link(name, bm, material=None):
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    ob = bpy.data.objects.new(name, me)
    if material:
        ob.data.materials.append(material)
    bpy.context.scene.collection.objects.link(ob)
    return ob


def prism_uv(name, u0, u1, v0, v1, y0, y1):
    """A box in the house frame (u0..u1, v0..v1, y0..y1)."""
    bm = bmesh.new()
    pts = [(u0, v0), (u1, v0), (u1, v1), (u0, v1)]
    lo = [bm.verts.new(G(*hf(u, y0, v))) for u, v in pts]
    hi = [bm.verts.new(G(*hf(u, y1, v))) for u, v in pts]
    bm.faces.new(lo)
    bm.faces.new(hi[::-1])
    for i in range(4):
        j = (i + 1) % 4
        bm.faces.new([lo[i], lo[j], hi[j], hi[i]])
    return link(name, bm)


def gable_uv(name, u0, u1, v0, v1, y_base, y_eave, y_ridge):
    """The first-floor volume: a rectangle up to the eaves under a gable whose ridge runs along u at the middle of v (as the old roof: gables at the u ends)."""
    vm = (v0 + v1) * 0.5
    prof = [(v0, y_base), (v1, y_base), (v1, y_eave), (vm, y_ridge), (v0, y_eave)]
    bm = bmesh.new()
    a = [bm.verts.new(G(*hf(u0, y, v))) for v, y in prof]
    b = [bm.verts.new(G(*hf(u1, y, v))) for v, y in prof]
    bm.faces.new(a[::-1])
    bm.faces.new(b)
    n = len(prof)
    for i in range(n):
        j = (i + 1) % n
        bm.faces.new([a[i], a[j], b[j], b[i]])
    return link(name, bm)


def ring(bm, r, y, n=SIDES):
    return [bm.verts.new(G(AX + r * math.cos(2 * math.pi * i / n), y, AZ + r * math.sin(2 * math.pi * i / n))) for i in range(n)]


def band(bm, lo, hi):
    n = len(lo)
    for i in range(n):
        j = (i + 1) % n
        bm.faces.new([lo[i], lo[j], hi[j], hi[i]])


def solid_revolve(name, prof):
    """A closed solid of revolution about the tower axis. `prof` is the half section as (radius, y): it starts and ends ON the axis (radius 0),
    runs out along the bottom, up the outside and back in along the top. Each end is a fan round one centre vertex."""
    bm = bmesh.new()
    first, last = prof[0], prof[-1]
    mid = prof[1:-1]
    bot = bm.verts.new(G(AX, first[1], AZ))
    top = bm.verts.new(G(AX, last[1], AZ))
    rings = [ring(bm, r, y) for r, y in mid]
    for k in range(len(rings) - 1):
        band(bm, rings[k], rings[k + 1])
    for i in range(SIDES):
        j = (i + 1) % SIDES
        bm.faces.new([bot, rings[0][j], rings[0][i]])
        bm.faces.new([top, rings[-1][i], rings[-1][j]])
    return link(name, bm)


def annulus_revolve(name, prof):
    """A closed ring-shaped solid of revolution: `prof` is a closed loop of (radius, y) that does not touch the axis."""
    bm = bmesh.new()
    rings = [ring(bm, r, y) for r, y in prof]
    for k in range(len(rings)):
        band(bm, rings[k], rings[(k + 1) % len(rings)])
    return link(name, bm)


def tower_solid():
    ys = [-3.0, 0.0, 3.0, 4.92]
    y = 5.17
    while y < LANTERN_FLOOR - 0.01:
        ys.append(y)
        y += 0.5
    ys.append(LANTERN_FLOOR + 0.05)      # the wall ring stops just above the lantern floor and is overlapped by the deck
    prof = [(0.0, ys[0])] + [(r_out(min(y, LANTERN_FLOOR)), y) for y in ys] + [(0.0, ys[-1])]
    return solid_revolve("tower_outer", prof)


def tower_air():
    ys = [0.0, 3.0, 4.92]
    y = 5.17
    while y < LANTERN_FLOOR - 0.001:
        ys.append(y)
        y += 0.5
    ys.append(LANTERN_FLOOR)
    ys.append(DECK_TOP + 0.4)             # the air goes on up through the lamp room (the glass drum is built in code)
    prof = [(0.0, ys[0])] + [(r_in(min(y, LANTERN_FLOOR)), y) for y in ys] + [(0.0, ys[-1])]
    return solid_revolve("tower_air", prof)


def deck_solid():
    """The gallery deck: a ring from inside the wall to r 4.0 with a drip edge, top at 18.33. The lamp-room floor inside r 2.9 is built in code."""
    prof = [(2.5, LANTERN_FLOOR - 0.05), (DECK_R - 0.25, LANTERN_FLOOR - 0.05), (DECK_R - 0.25, DECK_TOP - 0.33), (DECK_R, DECK_TOP - 0.1), (DECK_R, DECK_TOP), (2.5, DECK_TOP)]
    return annulus_revolve("deck", prof)


CAP_OUTER = [(3.30, CEIL_Y - 0.2), (3.30, CEIL_Y), (3.0, CEIL_Y + 0.12), (2.5, CEIL_Y + 0.55), (1.8, CEIL_Y + 1.15), (1.0, CEIL_Y + 2.0), (0.45, CEIL_Y + 2.85), (0.12, APEX - 0.05)]


def cap_solid():
    prof = [(0.0, CAP_OUTER[0][1])] + CAP_OUTER + [(0.0, APEX)]
    return solid_revolve("cap", prof)


def cap_air():
    """The room under the dome: the outer profile pulled in 0.15 and down 0.12, opening at the bottom through r 3.0."""
    inner = [(max(r - 0.15, 0.05), y - 0.12) for r, y in CAP_OUTER[2:]]
    prof = [(0.0, CEIL_Y - 0.5), (3.0, CEIL_Y - 0.5)] + [(3.0, CEIL_Y - 0.08)] + inner + [(0.0, inner[-1][1])]
    return solid_revolve("cap_air", prof)


def tower_cutter(name, bearing_deg, y_c, w, h, r0=1.5, r1=7.0):
    a = math.radians(bearing_deg)
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    L = r1 - r0
    for v in bm.verts:
        v.co = Vector((v.co.x * L, v.co.y * w, v.co.z * h))
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    ob = bpy.data.objects.new(name, me)
    bpy.context.scene.collection.objects.link(ob)
    mid = (r0 + r1) * 0.5
    ob.location = G(AX + mid * math.cos(a), y_c, AZ + mid * math.sin(a))
    ob.rotation_euler = (0, 0, -a)
    return ob


def house_cutter(name, u0, u1, v0, v1, y0, y1):
    return prism_uv(name, u0, u1, v0, v1, y0, y1)


def boolean(target, other, op):
    md = target.modifiers.new("b", "BOOLEAN")
    md.operation = op
    md.solver = "EXACT"
    md.object = other
    bpy.context.view_layer.objects.active = target
    bpy.ops.object.modifier_apply(modifier=md.name)


def union_all(objs, name):
    base = objs[0]
    for o in objs[1:]:
        boolean(base, o, "UNION")
        bpy.data.objects.remove(o, do_unlink=True)
    base.name = name
    return base


def main():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    m_stone = mat("shell_stone", (0.45, 0.42, 0.38))
    # ---------------- solid ----------------
    solids = [tower_solid()]
    solids.append(prism_uv("b1_o", G_U[0] - T, G_U[1] + T, G_V[0] - T, G_V[1] + T, B1_FLOOR - 1.0, GF))
    solids.append(prism_uv("g_o", G_U[0] - T, G_U[1] + T, G_V[0] - T, G_V[1] + T, GF, SLAB_TOP))
    solids.append(prism_uv("slab_o", L1_U[0] - T, L1_U[1] + T, L1_V[0] - T, L1_V[1] + T, SLAB_TOP, L1))
    solids.append(gable_uv("l1_o", L1_U[0] - T, L1_U[1] + T, L1_V[0] - T, L1_V[1] + T, L1, L1_EAVE + 0.1, L1_RIDGE + ROOF_T + 0.25))
    solids.append(deck_solid())
    solids.append(cap_solid())
    shell = union_all(solids, "Shell")
    # ---------------- air ----------------
    # the tower's air is cut short by the house wall slab so a real wall stands between the hall and the tower
    tair = tower_air()
    for nm, o in [("h1", prism_uv("h1", G_U[0] - T, G_U[1] + T, G_V[0] - T, G_V[1] + T, B1_FLOOR - 1.0, SLAB_TOP)),
                  ("h2", prism_uv("h2", L1_U[0] - T, L1_U[1] + T, L1_V[0] - T, L1_V[1] + T, SLAB_TOP, TOWER_CUT_TOP))]:
        boolean(tair, o, "DIFFERENCE")
        bpy.data.objects.remove(o, do_unlink=True)
    boolean(shell, tair, "DIFFERENCE")
    bpy.data.objects.remove(tair, do_unlink=True)
    ca = cap_air()
    boolean(shell, ca, "DIFFERENCE")
    bpy.data.objects.remove(ca, do_unlink=True)
    for o in [prism_uv("b1_a", G_U[0], G_U[1], G_V[0], G_V[1], B1_FLOOR, B1_CEIL),
              prism_uv("g_a", G_U[0], G_U[1], G_V[0], G_V[1], GF, G_CEIL),
              gable_uv("l1_a", L1_U[0], L1_U[1], L1_V[0], L1_V[1], L1, L1_EAVE, L1_RIDGE)]:
        boolean(shell, o, "DIFFERENCE")
        bpy.data.objects.remove(o, do_unlink=True)
    # the stairwell hole through the ground floor slab: a round hole just wider than the spiral (centre and radius in shell_spec.json)
    cx, cv = SPEC["stair_hole_centre"]
    bm = bmesh.new()
    n = 48
    lo = [bm.verts.new(G(*hf(cx + SPEC["stair_hole_r"] * math.cos(2 * math.pi * i / n), B1_CEIL - 0.1, cv + SPEC["stair_hole_r"] * math.sin(2 * math.pi * i / n)))) for i in range(n)]
    hi = [bm.verts.new(G(*hf(cx + SPEC["stair_hole_r"] * math.cos(2 * math.pi * i / n), GF + 0.1, cv + SPEC["stair_hole_r"] * math.sin(2 * math.pi * i / n)))) for i in range(n)]
    bm.faces.new(lo)
    bm.faces.new(hi[::-1])
    for i in range(n):
        j = (i + 1) % n
        bm.faces.new([lo[i], lo[j], hi[j], hi[i]])
    o = link("hole", bm)
    boolean(shell, o, "DIFFERENCE")
    bpy.data.objects.remove(o, do_unlink=True)
    # ---------------- openings ----------------
    cuts = []
    # front door: 1.8 wide, GF to GF+2.95, through the front wall (v from -0.2 to 0.6)
    cuts.append(house_cutter("c_front", -0.9, 0.9, -0.3, 0.9, GF, GF + SPEC["front_door_h"]))
    # hall to tower: the east wall, v 0.8..2.25, 2.3 high, through the wall slab to the tower air
    cuts.append(house_cutter("c_hall_tower", G_U[1] - 0.2, G_U[1] + T + 0.9, 0.8, 2.25, GF, GF + 2.3))
    # ground-floor west window: v 3.0..4.3, sill 1.9 head 2.9
    cuts.append(house_cutter("c_g_west", G_U[0] - T - 0.3, G_U[0] + 0.3, 3.0, 4.3, 1.9, 2.9))
    # first floor to tower: 1.3 wide (v 1.3..2.6?), 2.1 high, east wall
    cuts.append(house_cutter("c_l1_tower", L1_U[1] - 0.2, L1_U[1] + T + 0.9, SPEC["l1_door_v"][0], SPEC["l1_door_v"][1], L1, L1 + 2.1))
    # first-floor windows (data/world/lighthouse_windows.json: house kind, wall west 'at' = v, back 'at' = u; y centre, w, h)
    for w in json.load(open(os.path.join(DATA, "lighthouse_windows.json")))["windows"]:
        if w["kind"] != "house":
            continue
        y0, y1 = w["y"] - w["h"] / 2, w["y"] + w["h"] / 2
        if w["wall"] == "west":
            cuts.append(house_cutter("c_" + w["id"], L1_U[0] - T - 0.3, L1_U[0] + 0.3, w["at"] - w["w"] / 2, w["at"] + w["w"] / 2, y0, y1))
        else:
            cuts.append(house_cutter("c_" + w["id"], w["at"] - w["w"] / 2, w["at"] + w["w"] / 2, L1_V[1] - 0.3, L1_V[1] + T + 0.3, y0, y1))
        # (a window is cut through the wall only: the roof above is untouched)
    wins = [w for w in json.load(open(os.path.join(DATA, "lighthouse_windows.json")))["windows"] if w["kind"] == "tower"]
    wins.append({"id": "T_landing_147", "bearing": 147.0, "y": 15.09, "w": 1.0, "h": 1.8})
    for w in wins:
        cuts.append(tower_cutter("c_" + w["id"], w["bearing"], w["y"], w["w"], w["h"]))
    for c in cuts:
        boolean(shell, c, "DIFFERENCE")
        bpy.data.objects.remove(c, do_unlink=True)
    # weld the near-coincident vertices the exact booleans leave along tangent edges, and report what is still open
    bm = bmesh.new()
    bm.from_mesh(shell.data)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=2e-4)
    bmesh.ops.dissolve_degenerate(bm, edges=bm.edges, dist=1e-5)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    open_e = [e for e in bm.edges if len(e.link_faces) == 1]
    print("OPEN_EDGES_AFTER_WELD", len(open_e), [tuple(round(c, 2) for c in (e.verts[0].co.x, e.verts[0].co.z, -e.verts[0].co.y)) for e in open_e[:12]])
    bm.to_mesh(shell.data)
    bm.free()
    shell.data.materials.append(m_stone)
    for p in shell.data.polygons:
        p.use_smooth = False
    out = os.path.join(HERE, "lighthouse_shell_v1.glb")
    bpy.ops.export_scene.gltf(filepath=out, export_format="GLB", export_yup=True, export_apply=True)
    me = shell.data
    import collections
    edges = collections.Counter()
    for p in me.polygons:
        for i in range(len(p.vertices)):
            a, b = p.vertices[i], p.vertices[(i + 1) % len(p.vertices)]
            edges[(min(a, b), max(a, b))] += 1
    open_edges = sum(1 for c in edges.values() if c == 1)
    print("SHELL_OK", out, "verts", len(me.vertices), "faces", len(me.polygons), "open_edges", open_edges)


main()


def render_previews():
    """RENDER=1: three workbench previews (exterior, exterior from the sea side, a section through the house and tower) into GERFramework/shots."""
    import mathutils
    out_dir = os.path.normpath(os.path.join(HERE, "..", "..", "..", "..", "..", "GERFramework", "shots"))
    sh = bpy.data.objects["Shell"]
    scn = bpy.context.scene
    scn.render.engine = "BLENDER_WORKBENCH"
    scn.display.shading.light = "STUDIO"
    scn.display.shading.color_type = "OBJECT"
    scn.render.resolution_x, scn.render.resolution_y = 1400, 1000
    cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
    scn.collection.objects.link(cam)
    scn.camera = cam
    cam.data.clip_end = 500
    cam.data.lens = 24

    def shoot(name, loc, tgt):
        cam.location = G(*loc)
        d = G(*tgt) - cam.location
        cam.rotation_euler = d.to_track_quat("-Z", "Y").to_euler()
        scn.render.filepath = os.path.join(out_dir, name)
        bpy.ops.render.render(write_still=True)

    shoot("shell_v1_ext_a.png", (-14, 14, 22), (3.0, 9.0, 3.0))
    shoot("shell_v1_ext_b.png", (22, 12, -14), (3.0, 9.0, 3.0))
    # section: cut away everything with z (Godot) greater than the tower axis line, so the camera on that side looks into the rooms
    box = bpy.data.objects.new("secbox", bpy.data.meshes.new("secbox"))
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    bm.to_mesh(box.data)
    bm.free()
    scn.collection.objects.link(box)
    box.scale = (40, 20, 40)
    box.location = Vector((3.5, -3.6 - 20.0, 10.0))      # removes Godot z > 3.6 (Godot z is Blender -Y)
    boolean(sh, box, "DIFFERENCE")
    shoot("shell_v1_section.png", (3.5, 11, 3.6 + 24), (1.0, 8.0, 3.6))


if os.environ.get("RENDER") == "1":
    render_previews()
