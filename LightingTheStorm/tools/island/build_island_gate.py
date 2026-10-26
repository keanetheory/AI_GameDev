"""Turns the FAL island gate into the game model: darker stone, the leaf split out on its hinge, decimated.

Run: blender -b -P tools/island/build_island_gate.py -- <source/island_gate_full2k.glb> <island_gate.glb>

- Tint: the generated stone came out pale and cool (texture median ~130); the island rock is ~99 and warm.
  Every texel is scaled towards the island's stone, and yellow/orange (the brass padlock) loses most of its saturation.
- Split: the leaf is fused to the pillars, so faces are split by position: the largest connected piece between the pillars'
  inner faces (and off the ground) becomes the object "Leaf", the rest "Frame". The Leaf's origin is put on the
  hinge line (the +X edge of the leaf, at the ground), so gate.gd can swing it by rotating the node about Y.
- Decimate: Collapse to about FRAME_TRIS / LEAF_TRIS triangles (UVs are kept per loop).
Coordinates below are the raw FAL units (glTF: x across, y up, z through the gate), read off the mesh.
"""
import sys

import bmesh
import bpy
import numpy as np

argv = sys.argv[sys.argv.index("--") + 1:]
SRC, OUT = argv[0], argv[1]

OPENING_X = (-0.224, 0.139)   # between the pillars' inner faces (left pillar ends -0.229, right begins 0.143)
GROUND_Y = 0.012              # faces whose centre is lower than this stay with the frame
FRAME_TRIS = 30000
LEAF_TRIS = 12000
TINT = np.array([0.74, 0.71, 0.64])   # per-channel scale towards the island's warm stone grey
DESAT = 0.25                          # pulls every texel this far towards its own grey
BRASS_DESAT = 0.7                     # extra desaturation for yellow/orange texels

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=SRC)
obj = [o for o in bpy.data.objects if o.type == "MESH"][0]

# --- tint the texture ---
img = [i for i in bpy.data.images if i.size[0] > 0][0]
w, h = img.size
px = np.empty(w * h * 4, dtype=np.float32)
img.pixels.foreach_get(px)
px = px.reshape(-1, 4)
rgb = px[:, :3]
grey = rgb.mean(axis=1, keepdims=True)
rgb = grey + (rgb - grey) * (1.0 - DESAT)
r, g, b = rgb[:, 0], rgb[:, 1], rgb[:, 2]
brass = (r > b + 0.08) & (g > b + 0.04)
grey = rgb.mean(axis=1, keepdims=True)
rgb[brass] = grey[brass] + (rgb[brass] - grey[brass]) * (1.0 - BRASS_DESAT)
rgb = np.clip(rgb * TINT, 0.0, 1.0)
px[:, :3] = rgb
img.pixels.foreach_set(px.ravel())
img.update()
img.pack()
print("tinted %dx%d, brass texels %d" % (w, h, int(brass.sum())))

# --- work in glTF space: the importer leaves the Y-up conversion on the object, so apply it ---
bpy.context.view_layer.objects.active = obj
obj.select_set(True)
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
# Blender (x, y, z) = glTF (x, -z, y) from here on

bm = bmesh.new()
bm.from_mesh(obj.data)
bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-5)
cand = set()
for f in bm.faces:
    c = f.calc_center_median()
    f.select = False
    if OPENING_X[0] < c.x < OPENING_X[1] and c.z > GROUND_Y:
        cand.add(f.index)
# keep only the largest connected piece: the iron leaf. A sliver of the left capstone's inner face also falls inside
# the opening and would otherwise swing round with the leaf.
bm.faces.ensure_lookup_table()
seen, best = set(), []
for i in cand:
    if i in seen:
        continue
    stack, piece = [i], []
    seen.add(i)
    while stack:
        f = bm.faces[stack.pop()]
        piece.append(f)
        for e in f.edges:
            for g in e.link_faces:
                if g.index in cand and g.index not in seen:
                    seen.add(g.index)
                    stack.append(g.index)
    if len(piece) > len(best):
        best = piece
for f in best:
    f.select = True
leaf_faces = len(best)
bm.to_mesh(obj.data)
bm.free()
print("leaf faces", leaf_faces, "of", len(obj.data.polygons))

bpy.ops.object.mode_set(mode="EDIT")
bpy.ops.mesh.separate(type="SELECTED")
bpy.ops.object.mode_set(mode="OBJECT")
frame, leaf = obj, [o for o in bpy.context.selected_objects if o != obj][0]
frame.name = frame.data.name = "Frame"
leaf.name = leaf.data.name = "Leaf"

for o, tris in ((frame, FRAME_TRIS), (leaf, LEAF_TRIS)):
    n = sum(len(p.vertices) - 2 for p in o.data.polygons)
    m = o.modifiers.new("Decimate", "DECIMATE")
    m.ratio = min(1.0, tris / max(n, 1))
    m.use_collapse_triangulate = True
    bpy.context.view_layer.objects.active = o
    bpy.ops.object.modifier_apply(modifier=m.name)
    print("%s: %d -> %d tris" % (o.name, n, sum(len(p.vertices) - 2 for p in o.data.polygons)))

# --- leaf origin on the hinge line: +X edge of the leaf, middle of its thickness, at the ground ---
vs = np.array([v.co[:] for v in leaf.data.vertices])
mn, mx = vs.min(axis=0), vs.max(axis=0)
print("leaf bbox (blender) min", mn.round(3), "max", mx.round(3))
hinge = (mx[0], (mn[1] + mx[1]) * 0.5, 0.0)
bpy.context.scene.cursor.location = hinge
bpy.ops.object.select_all(action="DESELECT")
leaf.select_set(True)
bpy.context.view_layer.objects.active = leaf
bpy.ops.object.origin_set(type="ORIGIN_CURSOR")
print("hinge (gltf) x %.4f y 0 z %.4f" % (hinge[0], -hinge[1]))

bpy.ops.object.select_all(action="SELECT")
bpy.ops.export_scene.gltf(filepath=OUT, export_format="GLB", use_selection=True, export_yup=True,
                          export_image_format="AUTO", export_apply=True)
print("wrote", OUT)
