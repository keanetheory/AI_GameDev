"""build_rock_patch.py - Island Creator ISL-01 (Blender 5.2, headless): blender -b -P build_rock_patch.py
Input : ../island_craggy.glb
Output: ../rock_patch.glb, already in the frame island_craggy has IN GODOT (tools/import_scale_pivot.gd scales the island to a 90 m footprint
        and puts its pivot at the base centre): the same transform is applied here, so rock_patch.glb needs no import script and the
        RockPatch nodes keep their transforms.

The three RockPatch nodes in Level.tscn reuse a piece of island_craggy cut out at run time by collider_builder's keep_boxes
(AABB(-31.5, 0.9, -8.6, 6, 10, 4.2): a triangle is kept when its centre is inside). The cut left open edges, and from the harbour the two
patches by the stair foot read as hollow, paper-thin shells (creator, 2026-10-29). This makes that piece once, offline, and closes it:
  1. keep the same triangles (centre inside the box, Godot frame);
  2. weld, then fill every open boundary loop (a fan, its inner points pulled toward the loop's centre and inward so the cap bulges into
     the rock like a broken face rather than a flat lid);
  3. the cap takes a texel from the darkest tenth of the rock along its rim (the inside of broken rock is in shadow);
  4. export with the same root/mesh names as island_craggy ("convert" > "material").
Coordinates: Blender (X, Y, Z) = Godot (x, -z, y).
"""
import bpy, bmesh, os
from mathutils import Vector

HERE = os.path.dirname(os.path.abspath(__file__))
SRC = os.path.normpath(os.path.join(HERE, "..", "island_craggy.glb"))
OUT = os.path.normpath(os.path.join(HERE, "..", "rock_patch.glb"))
BOX_LO = Vector((-31.5, 0.9, -8.6))
BOX_HI = BOX_LO + Vector((6.0, 10.0, 4.2))


def god(v):
    return Vector((v.x, v.z, -v.y))


def main():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=SRC)
    ob = [o for o in bpy.data.objects if o.type == "MESH"][0]
    me = ob.data
    bm = bmesh.new()
    bm.from_mesh(me)
    bm.transform(ob.matrix_world)
    # the import script's transform (Godot frame): s = 90 / max(x, z extent), pivot at the base centre
    gs = [god(v.co) for v in bm.verts]
    lo = Vector((min(g.x for g in gs), min(g.y for g in gs), min(g.z for g in gs)))
    hi = Vector((max(g.x for g in gs), max(g.y for g in gs), max(g.z for g in gs)))
    sc = 90.0 / max(hi.x - lo.x, hi.z - lo.z)
    base = Vector(((lo.x + hi.x) * 0.5, lo.y, (lo.z + hi.z) * 0.5))
    for v in bm.verts:
        g = (god(v.co) - base) * sc
        v.co = Vector((g.x, -g.z, g.y))
    print("import transform: scale %.4f, base %s" % (sc, tuple(round(x, 3) for x in base)))
    uvl = bm.loops.layers.uv.active
    img = None
    for n in me.materials[0].node_tree.nodes:
        if n.type == "TEX_IMAGE":
            img = n.image
    px = list(img.pixels) if img else None
    W, H = (img.size[0], img.size[1]) if img else (1, 1)

    def lum(uv):
        x = min(W - 1, max(0, int((uv[0] % 1.0) * W)))
        y = min(H - 1, max(0, int((uv[1] % 1.0) * H)))
        i = (y * W + x) * 4
        return 0.3 * px[i] + 0.59 * px[i + 1] + 0.11 * px[i + 2]

    drop = []
    for f in bm.faces:
        c = god(f.calc_center_median())
        if not (BOX_LO.x <= c.x <= BOX_HI.x and BOX_LO.y <= c.y <= BOX_HI.y and BOX_LO.z <= c.z <= BOX_HI.z):
            drop.append(f)
    bmesh.ops.delete(bm, geom=drop, context="FACES")
    kept = len(bm.faces)
    bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=1e-4)
    bm.edges.ensure_lookup_table()
    bnd = [e for e in bm.edges if len(e.link_faces) == 1]
    # group the open edges into loops
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
    centre_all = sum((v.co for v in bm.verts), Vector()) / max(1, len(bm.verts))
    filled = 0
    cap_faces = 0
    for es in loops.values():
        if len(es) < 3 or not all(e.is_valid for e in es):
            continue                          # an earlier fill already used these edges
        vs = list({v for e in es for v in e.verts})
        samples = []
        for v in vs:
            for lp in v.link_loops:
                samples.append((lum(lp[uvl].uv) if px else 0.5, tuple(lp[uvl].uv)))
                break
        samples.sort()
        uv_pick = samples[len(samples) // 10][1] if samples else (0.5, 0.5)      # broken rock is dark inside: the darkest tenth of the rim
        before = set(bm.faces)
        try:
            bmesh.ops.triangle_fill(bm, use_beauty=True, use_dissolve=False, edges=es)
        except Exception as ex:
            print("fill failed", ex)
            continue
        nf = [f for f in bm.faces if f not in before]
        if not nf:
            continue
        # outward: away from the patch's own middle
        c = sum((v.co for v in vs), Vector()) / len(vs)
        out = (c - centre_all).normalized()
        n_sum = sum((f.normal * f.calc_area() for f in nf), Vector())
        if n_sum.dot(out) < 0.0:
            for f in nf:
                f.normal_flip()
        # subdivide and push the inner points into the rock a little, so the cap is a broken face, not a flat lid
        inner_edges = list({e for f in nf for e in f.edges if e not in es})
        if inner_edges:
            bmesh.ops.subdivide_edges(bm, edges=inner_edges, cuts=1, use_grid_fill=False)
        nf = [f for f in bm.faces if f not in before]
        rim = {v for v in vs if v.is_valid}
        span = max(((v.co - c).length for v in rim), default=0.0)
        for v in {v for f in nf for v in f.verts if v not in rim}:
            d = 1.0 - min(1.0, (v.co - c).length / max(span, 1e-3))
            v.co -= out * (0.12 * span * d)
        for f in nf:
            for lp in f.loops:
                lp[uvl].uv = uv_pick
            f.smooth = True
        filled += 1
        cap_faces += len(nf)
    bm.normal_update()
    bm.edges.ensure_lookup_table()
    open_left = sum(1 for e in bm.edges if len(e.link_faces) == 1)
    bm.to_mesh(me)
    bm.free()
    ob.matrix_world = ob.matrix_world.copy()
    ob.matrix_world.identity()
    for o in list(bpy.data.objects):
        if o.type == "EMPTY":
            bpy.data.objects.remove(o, do_unlink=True)
    root = bpy.data.objects.new("convert", None)
    bpy.context.scene.collection.objects.link(root)
    ob.name = "material"
    ob.parent = root
    ob.matrix_parent_inverse = root.matrix_world.inverted()
    bpy.ops.export_scene.gltf(filepath=OUT, export_format="GLB", export_yup=True, export_apply=False, export_image_format="AUTO")
    print("ROCK_PATCH_OK", OUT, "kept faces", kept, "loops", len(loops), "filled", filled, "cap faces", cap_faces, "open edges left", open_left)


main()
