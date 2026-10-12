import bpy, bmesh, math, sys
from mathutils import Vector

out_dir = sys.argv[sys.argv.index("--") + 1]

# All geometry is authored in VIEWER WORLD coordinates (metres, Y up) and exported as-is.
# Blender axes: (X, Y, Z) = (world x, -world z, world y).
def B(p):
    return Vector((p[0], -p[2], p[1]))

def make_material(name, rgb, rough):
    m = bpy.data.materials.new(name); m.use_nodes = True
    b = m.node_tree.nodes["Principled BSDF"]
    b.inputs["Base Color"].default_value = (*rgb, 1); b.inputs["Roughness"].default_value = rough
    m.diffuse_color = (*rgb, 1)
    return m

def add_box(bm, center, size, yaw=0.0, pitch=0.0, mat_index=0):
    """center/size in world coords; yaw about world Y, pitch about the box's local X (tilts length axis +z up/down)."""
    hx, hy, hz = size[0] / 2, size[1] / 2, size[2] / 2
    cy, sy = math.cos(yaw), math.sin(yaw)
    cp, sp = math.cos(pitch), math.sin(pitch)
    verts = []
    for sx in (-1, 1):
        for sy_ in (-1, 1):
            for sz in (-1, 1):
                x, y, z = sx * hx, sy_ * hy, sz * hz
                y, z = y * cp - z * sp, y * sp + z * cp          # pitch about X
                x, z = x * cy + z * sy, -x * sy + z * cy         # yaw about Y
                verts.append(bm.verts.new(B((center[0] + x, center[1] + y, center[2] + z))))
    idx = lambda a, b, c: (a * 4 + b * 2 + c)
    for quad in [(0, 1, 3, 2), (4, 6, 7, 5), (0, 4, 5, 1), (2, 3, 7, 6), (0, 2, 6, 4), (1, 5, 7, 3)]:
        f = bm.faces.new([verts[i] for i in quad]); f.material_index = mat_index
    return verts

def build(name, fill, materials):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    me = bpy.data.meshes.new(name); bm = bmesh.new()
    fill(bm)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(me); bm.free()
    obj = bpy.data.objects.new(name, me); bpy.context.scene.collection.objects.link(obj)
    for m in materials(): me.materials.append(m)
    path = f"{out_dir}/1-{name}.glb"
    bpy.ops.export_scene.gltf(filepath=path, export_format="GLB")
    print("EXPORTED", path, "tris", sum(len(p.vertices) - 2 for p in me.polygons))

# ---- gangway: pier end -> door ----------------------------------------------
START = Vector((0.45, -0.30, -7.00))      # pier deck end
END = Vector((1.70, -1.25, -11.85))       # foot of the door
def gangway(bm):
    d = END - START
    length = d.length
    yaw = math.atan2(d.x, d.z)                         # heading about world Y
    pitch = -math.atan2(d.y, math.hypot(d.x, d.z))     # slope (negative = descends)
    mid = (START + END) / 2
    forward = Vector((math.sin(yaw), 0, math.cos(yaw)))
    right = Vector((math.cos(yaw), 0, -math.sin(yaw)))
    width, plank_w, thick = 2.2, 0.32, 0.14
    n = int(length / plank_w)
    for i in range(n):
        t = (i + 0.5) / n
        c = START + d * t
        add_box(bm, (c.x, c.y - thick / 2, c.z), (width, thick, length / n - 0.03), yaw, pitch, 0)
    for side in (-1, 1):                                 # stringers + rails
        off = right * (side * (width / 2 - 0.08))
        add_box(bm, (mid.x + off.x, mid.y - 0.28, mid.z + off.z), (0.12, 0.22, length), yaw, pitch, 0)
        posts = max(3, int(length / 1.4))
        for k in range(posts + 1):
            t = k / posts
            c = START + d * t + off
            add_box(bm, (c.x, c.y + 0.55, c.z), (0.12, 1.1, 0.12), yaw, 0, 0)
        add_box(bm, (mid.x + off.x, mid.y + 1.0, mid.z + off.z), (0.09, 0.09, length), yaw, pitch, 0)
        add_box(bm, (mid.x + off.x, mid.y + 0.55, mid.z + off.z), (0.07, 0.07, length), yaw, pitch, 0)

# ---- gate: solid double door in the wall opening ----------------------------
GX, GY0, GZ = 1.70, -1.30, -12.15
def gate(bm):
    w, h, t = 3.4, 3.3, 0.35
    # frame
    add_box(bm, (GX - w / 2 - 0.15, GY0 + h / 2, GZ), (0.3, h + 0.3, t + 0.2), 0, 0, 1)
    add_box(bm, (GX + w / 2 + 0.15, GY0 + h / 2, GZ), (0.3, h + 0.3, t + 0.2), 0, 0, 1)
    add_box(bm, (GX, GY0 + h + 0.15, GZ), (w + 0.6, 0.3, t + 0.2), 0, 0, 1)
    add_box(bm, (GX, GY0 - 0.05, GZ), (w + 0.6, 0.2, t + 0.2), 0, 0, 1)
    # two leaves made of vertical planks
    for leaf in (-1, 1):
        for k in range(5):
            x = GX + leaf * (0.08 + 0.17 + k * 0.33)
            add_box(bm, (x, GY0 + h / 2, GZ), (0.31, h - 0.1, t), 0, 0, 0)
        for yb in (0.55, h / 2, h - 0.55):                # iron bands
            add_box(bm, (GX + leaf * 0.9, GY0 + yb, GZ - t / 2 - 0.02), (1.7, 0.16, 0.05), 0, 0, 2)
    add_box(bm, (GX, GY0 + h / 2, GZ - t / 2 - 0.03), (0.1, h - 0.1, 0.07), 0, 0, 2)   # centre bar

build("gangway", gangway, lambda: [make_material("wood_gangway", (0.20, 0.12, 0.06), 0.9)])
build("gate", gate, lambda: [make_material("wood_gate", (0.13, 0.08, 0.045), 0.85),
                             make_material("stone_frame", (0.28, 0.27, 0.25), 0.95),
                             make_material("iron_band", (0.05, 0.05, 0.055), 0.6)])
print("DONE")
