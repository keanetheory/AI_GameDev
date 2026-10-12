import bpy, bmesh, json, sys
from mathutils import Vector

escapes_json, out_glb = sys.argv[sys.argv.index("--") + 1:][:2]
boxes = json.load(open(escapes_json))
bpy.ops.wm.read_factory_settings(use_empty=True)
bm = bmesh.new()
def B(p): return Vector((p[0], -p[2], p[1]))
for b in boxes:
    cx, cz, top = b["x"], b["z"], b["y"]
    y0, y1 = top - 1.0, top + 3.0
    hx = hz = 0.34
    vs = [bm.verts.new(B((cx + sx * hx, y, cz + sz * hz))) for sx in (-1, 1) for y in (y0, y1) for sz in (-1, 1)]
    for q in [(0, 1, 3, 2), (4, 6, 7, 5), (0, 4, 5, 1), (2, 3, 7, 6), (0, 2, 6, 4), (1, 5, 7, 3)]:
        bm.faces.new([vs[i] for i in q])
bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
me = bpy.data.meshes.new("barriers"); bm.to_mesh(me); bm.free()
obj = bpy.data.objects.new("barriers", me); bpy.context.scene.collection.objects.link(obj)
bpy.ops.export_scene.gltf(filepath=out_glb, export_format="GLB", export_materials="NONE")
print("BARRIERS", len(boxes), "boxes, tris", sum(len(p.vertices) - 2 for p in me.polygons))
