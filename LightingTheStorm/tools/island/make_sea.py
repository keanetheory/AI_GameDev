import bpy, bmesh, sys

out = sys.argv[sys.argv.index("--") + 1]
SIZE, SEGS = 640.0, 256          # metres across, cells per side (2.5 m cells)

bpy.ops.wm.read_factory_settings(use_empty=True)
me = bpy.data.meshes.new("sea")
bm = bmesh.new()
bmesh.ops.create_grid(bm, x_segments=SEGS, y_segments=SEGS, size=SIZE / 2, calc_uvs=True)
bm.to_mesh(me); bm.free()
for p in me.polygons:
    p.use_smooth = True

obj = bpy.data.objects.new("sea", me)
bpy.context.scene.collection.objects.link(obj)

mat = bpy.data.materials.new("sea_surface")
mat.use_nodes = True
bsdf = mat.node_tree.nodes["Principled BSDF"]
bsdf.inputs["Base Color"].default_value = (0.012, 0.055, 0.07, 1.0)
bsdf.inputs["Roughness"].default_value = 0.22
bsdf.inputs["Metallic"].default_value = 0.0
mat.diffuse_color = (0.012, 0.055, 0.07, 1.0)
me.materials.append(mat)

print("SEA verts", len(me.vertices), "tris", sum(len(p.vertices) - 2 for p in me.polygons))
bpy.ops.export_scene.gltf(filepath=out, export_format="GLB")
print("DONE")
