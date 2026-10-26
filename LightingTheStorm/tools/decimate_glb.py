"""Decimates every mesh in a GLB to about <target_tris> triangles in total (Blender Collapse, UVs kept per loop).

Run: blender -b -P tools/decimate_glb.py -- <in.glb> <out.glb> <target_tris>
Used for FAL models outside the prop folder (props use tools/decimate_props.gd). Keep the full-detail original in source/.
"""
import sys

import bpy

src, out, target = sys.argv[sys.argv.index("--") + 1:][:3]
target = int(target)
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=src)
meshes = [o for o in bpy.data.objects if o.type == "MESH"]
total = sum(len(p.vertices) - 2 for o in meshes for p in o.data.polygons)
for o in meshes:
    m = o.modifiers.new("Decimate", "DECIMATE")
    m.ratio = min(1.0, target / max(total, 1))
    m.use_collapse_triangulate = True
    bpy.context.view_layer.objects.active = o
    bpy.ops.object.modifier_apply(modifier=m.name)
after = sum(len(p.vertices) - 2 for o in meshes for p in o.data.polygons)
print("decimate_glb: %d -> %d tris" % (total, after))
bpy.ops.export_scene.gltf(filepath=out, export_format="GLB", export_image_format="AUTO")
