import bpy, bmesh, math, sys, json
from mathutils import Vector

island_glb, out_glb, path_json = sys.argv[sys.argv.index("--") + 1:][:3]

# ---------------------------------------------------------------- terrain probe (world coords)
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=island_glb)
SC = bpy.context.scene
POS, S = (2.25, 22.275, -22.6), 45.0
DG = bpy.context.evaluated_depsgraph_get()
def terrain(x, z):
    ok, loc, n, i, o, m = SC.ray_cast(DG, Vector(((x - POS[0]) / S, -((z - POS[2]) / S), 3.0)), Vector((0, 0, -1)))
    return loc.z * S + POS[1] if ok else 99.0

# ---------------------------------------------------------------- helpers (authored in world coords)
def B(p): return Vector((p[0], -p[2], p[1]))
def add_box(bm, center, size, yaw=0.0, mat=0):
    hx, hy, hz = size[0] / 2, size[1] / 2, size[2] / 2
    cy, sy = math.cos(yaw), math.sin(yaw)
    vs = []
    for sx in (-1, 1):
        for sy_ in (-1, 1):
            for sz in (-1, 1):
                x, y, z = sx * hx, sy_ * hy, sz * hz
                x, z = x * cy + z * sy, -x * sy + z * cy
                vs.append(bm.verts.new(B((center[0] + x, center[1] + y, center[2] + z))))
    for q in [(0, 1, 3, 2), (4, 6, 7, 5), (0, 4, 5, 1), (2, 3, 7, 6), (0, 2, 6, 4), (1, 5, 7, 3)]:
        bm.faces.new([vs[i] for i in q]).material_index = mat

# ---------------------------------------------------------------- layout
GATE_Z = -12.15
FLOOR0 = -1.30
CX = 1.70                      # corridor centre x
WIDTH = 2.4
HEAD = 2.5                     # clear height
LAND0_Z = (-12.40, -14.40)     # flat landing right behind the gate
STAIR_END_Z = -19.60           # stairs end exactly where the landing (z -19.6 .. -22.0) begins
N_C = 17                       # corridor steps
RISE_C = 0.20
CORR_TOP = FLOOR0 + N_C * RISE_C              # floor height at end of corridor stairs
SC_X, SC_Z = 5.70, -20.80      # spiral shaft centre
R_IN, R_OUT, R_WALL = 0.70, 2.80, 2.95
RING = 1.95                    # walking ring radius used for the test route
N_S = 50
EXIT_ANG = -60.0               # degrees; direction toward the existing steps
THETA0 = 125.0                 # first rising tread (after a flat entry sector 140..215 deg)
THETA_LAST = EXIT_ANG - 360.0  # last tread points at the exit direction after ~1.5 turns
DEL = (THETA_LAST - THETA0) / (N_S - 1)
Y_TOP = 10.65
RISE_S = (Y_TOP - CORR_TOP) / N_S

bm = bmesh.new()
path = []                       # (x, z, y) centre-line for the walking test

# entrance landing (flat) -- solid slab, walls, ceiling
lz0, lz1 = LAND0_Z; zc = (lz0 + lz1) / 2; ln = abs(lz1 - lz0)
add_box(bm, (CX, FLOOR0 - 0.5, zc), (WIDTH, 1.0, ln), 0, 1)
for side in (-1, 1):
    add_box(bm, (CX + side * (WIDTH / 2 + 0.2), FLOOR0 + HEAD / 2 - 0.4, zc), (0.4, HEAD + 1.0, ln), 0, 0)
add_box(bm, (CX, FLOOR0 + HEAD + 0.18, zc), (WIDTH + 0.8, 0.36, ln), 0, 0)
path += [(CX, -12.6, FLOOR0), (CX, -14.2, FLOOR0)]

# ascending corridor (stairs heading -Z)
run = (lz1 - STAIR_END_Z) * -1 if False else (abs(STAIR_END_Z) - abs(lz1)) / N_C
for k in range(N_C):
    z0 = lz1 - k * run; z1 = z0 - run; zc = (z0 + z1) / 2
    top = FLOOR0 + (k + 1) * RISE_C
    add_box(bm, (CX, top - 0.5, zc), (WIDTH, 1.0, run + 0.02), 0, 1)
    for side in (-1, 1):
        add_box(bm, (CX + side * (WIDTH / 2 + 0.2), top + HEAD / 2 - 0.4, zc), (0.4, HEAD + 1.0, run + 0.02), 0, 0)
    add_box(bm, (CX, top + HEAD + 0.18, zc), (WIDTH + 0.8, 0.36, run + 0.02), 0, 0)
    path.append((CX, zc, top))

# corner landing (z -19.6 .. -22.0), then straight into the shaft. Corridor enters from the south.
lx0, lx1 = CX - WIDTH / 2, SC_X - R_OUT + 0.1           # 0.5 .. 3.5
lcx = (lx0 + lx1) / 2; lw = lx1 - lx0
add_box(bm, (lcx, CORR_TOP - 0.5, SC_Z), (lw, 1.0, WIDTH), 0, 1)
add_box(bm, (lcx, CORR_TOP + HEAD + 0.18, SC_Z), (lw + 0.4, 0.36, WIDTH + 0.8), 0, 0)
add_box(bm, (lcx, CORR_TOP + HEAD / 2 - 0.4, SC_Z - WIDTH / 2 - 0.2), (lw + 0.4, HEAD + 1.0, 0.4), 0, 0)         # north wall
add_box(bm, (lx0 - 0.2, CORR_TOP + HEAD / 2 - 0.4, SC_Z), (0.4, HEAD + 1.0, WIDTH + 0.8), 0, 0)                  # west cap
add_box(bm, ((CX + WIDTH / 2 + lx1) / 2 + 0.1, CORR_TOP + HEAD / 2 - 0.4, SC_Z + WIDTH / 2 + 0.2),
        (lx1 - (CX + WIDTH / 2) + 0.4, HEAD + 1.0, 0.4), 0, 0)                                                     # south wall east of corridor mouth
path += [(CX, SC_Z + 1.0, CORR_TOP), (CX + 0.3, SC_Z, CORR_TOP), (SC_X - R_OUT - 0.2, SC_Z, CORR_TOP)]

# spiral shaft
add_box(bm, (SC_X, (CORR_TOP + Y_TOP) / 2 - 0.5, SC_Z), (2 * R_IN, Y_TOP - CORR_TOP + 1.0, 2 * R_IN), math.radians(45), 1)   # central column
rm = (R_IN + R_OUT) / 2
# flat entry sector at landing height, so you can step in anywhere across the landing mouth
for ang in (215, 200, 185, 170, 155, 140):
    th = math.radians(ang)
    add_box(bm, (SC_X + rm * math.cos(th), CORR_TOP - 0.5, SC_Z + rm * math.sin(th)), (0.62, 1.0, R_OUT - R_IN),
            math.atan2(math.cos(th), math.sin(th)), 1)
for ang in (185, 170, 155, 140):
    th = math.radians(ang)
    path.append((SC_X + RING * math.cos(th), SC_Z + RING * math.sin(th), CORR_TOP))
for i in range(N_S):
    th = math.radians(THETA0 + DEL * i)
    top = CORR_TOP + (i + 1) * RISE_S
    cx, cz = SC_X + rm * math.cos(th), SC_Z + rm * math.sin(th)
    # box length axis (local z) must point radially: yaw such that local +z = (cos th, sin th)
    yaw = math.atan2(math.cos(th), math.sin(th))
    add_box(bm, (cx, top - 0.5, cz), (0.52, 1.0, R_OUT - R_IN), yaw, 1)
    path.append((SC_X + RING * math.cos(th), SC_Z + RING * math.sin(th), top))
    ang_deg = (THETA0 + DEL * i) % 360
    d_exit = abs(((ang_deg - EXIT_ANG) + 180) % 360 - 180)
    exposed = i >= N_S - 17
    if (exposed and d_exit < 38) or (i < 2):
        continue                                       # keep the exit and the corridor mouth open
    wx, wz = SC_X + (R_WALL + 0.15) * math.cos(th), SC_Z + (R_WALL + 0.15) * math.sin(th)
    ground = terrain(wx, wz)
    wall_top = max(top + 1.2, min(top + HEAD, ground + 0.25))
    wall_bot = top - 1.0
    add_box(bm, (wx, (wall_top + wall_bot) / 2, wz), (0.42, wall_top - wall_bot, 2 * R_WALL * math.sin(math.radians(abs(DEL)) / 2) + 0.12), yaw, 0)

# exit staircase: from the shaft top to the foot of the existing stone steps (world (9.7, 12.6, -25.75))
ex = math.radians(EXIT_ANG)
P0 = (SC_X + (R_OUT + 0.1) * math.cos(ex), SC_Z + (R_OUT + 0.1) * math.sin(ex))
P1 = (9.70, -25.75)
dxe, dze = P1[0] - P0[0], P1[1] - P0[1]
Le = math.hypot(dxe, dze)
yaw_e = math.atan2(dxe, dze)
n_e = 12
end_h = Y_TOP + 0.2 * (n_e - 1)               # 12.85: meets the existing steps
run_e = Le / n_e
for k in range(n_e):
    t = (k + 0.5) / n_e
    top = Y_TOP + 0.2 * k                      # first step is level with the last spiral tread
    px, pz = P0[0] + dxe * t, P0[1] + dze * t
    add_box(bm, (px, top - 0.6, pz), (1.8, 1.2, run_e + 0.04), yaw_e, 1)
    path.append((px, pz, top))
path.append((P1[0], P1[1], end_h))

# ---------------------------------------------------------------- export
bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
me = bpy.data.meshes.new("tunnel"); bm.to_mesh(me); bm.free()
obj = bpy.data.objects.new("tunnel", me); SC.collection.objects.link(obj)
def mat(name, rgb, rough):
    m = bpy.data.materials.new(name); m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]; b.inputs["Base Color"].default_value = (*rgb, 1); b.inputs["Roughness"].default_value = rough
    m.diffuse_color = (*rgb, 1); return m
me.materials.append(mat("tunnel_wall", (0.16, 0.155, 0.15), 0.95))
me.materials.append(mat("tunnel_steps", (0.24, 0.23, 0.21), 0.9))
bpy.ops.object.select_all(action="DESELECT")
obj.select_set(True); bpy.context.view_layer.objects.active = obj
bpy.ops.export_scene.gltf(filepath=out_glb, export_format="GLB", use_selection=True)
json.dump({"path": path, "exit_height": end_h, "corr_top": CORR_TOP, "rise_s": RISE_S}, open(path_json, "w"))
print("TUNNEL tris", sum(len(p.vertices) - 2 for p in me.polygons), "corr_top", round(CORR_TOP, 2), "rise_s", round(RISE_S, 3), "exit_h", round(end_h, 2))
print("DONE")
