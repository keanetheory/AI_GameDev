import bpy, sys, numpy as np
from mathutils import Vector

src, out_visual, out_collider = sys.argv[sys.argv.index("--") + 1:][:3]
PATH = np.array([(0.282, 0.206, -0.104), (0.166, 0.07, -0.214), (0.076, -0.039, -0.258),
                 (0.003, -0.098, -0.317), (-0.16, -0.555, -0.406), (-0.05, -0.491, -0.495),
                 (0.25, -0.59, -0.497), (-0.065, -0.839, -0.486), (0.299, -0.806, -0.484),
                 (-0.040, -0.347, -0.502),   # 9: pier deck end (gangway start)
                 (-0.012, -0.231, -0.506)])  # 10: pier-end door / gate
SEGMENTS = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 6), (5, 7), (6, 8), (7, 8), (5, 9), (9, 10)]

def fresh_import():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=src)
    obj = [o for o in bpy.context.scene.objects if o.type == "MESH"][0]
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    return obj

# Blender-space boxes (xmin, xmax, ymin, ymax, zmin, zmax) around the two floating boats.
BOAT_BOXES = [(-0.02, 0.115, -0.62, -0.48, -0.575, -0.503),
              (0.095, 0.21, -0.45, -0.315, -0.575, -0.503)]

def remove_boats(obj):
    import bmesh
    me = obj.data
    n = len(me.vertices)
    co = np.empty(n * 3, dtype=np.float32); me.vertices.foreach_get("co", co); co = co.reshape(-1, 3)
    inside = np.zeros(n, dtype=bool)
    for x0, x1, y0, y1, z0, z1 in BOAT_BOXES:
        inside |= ((co[:, 0] >= x0) & (co[:, 0] <= x1) & (co[:, 1] >= y0) & (co[:, 1] <= y1)
                   & (co[:, 2] >= z0) & (co[:, 2] <= z1))
    # tunnel openings (world coords -> island-local Blender coords)
    def w2b(wx, wy, wz):
        return ((wx - 2.25) / 45.0, -((wz + 22.6) / 45.0), (wy - 22.275) / 45.0)
    # 1) opening behind the gate
    ax0, ay0, az0 = w2b(0.2, -12.0, -1.6)      # placeholder order fixed below
    lo = w2b(0.2, -1.6, -14.2); hi = w2b(3.2, 1.7, -12.0)
    inside |= ((co[:, 0] >= min(lo[0], hi[0])) & (co[:, 0] <= max(lo[0], hi[0]))
               & (co[:, 1] >= min(lo[1], hi[1])) & (co[:, 1] <= max(lo[1], hi[1]))
               & (co[:, 2] >= min(lo[2], hi[2])) & (co[:, 2] <= max(lo[2], hi[2])))
    # 3) trench along the exit staircase: shaft top (7.05,-23.14) -> foot of the existing steps (9.7,-25.75)
    p0 = np.array(w2b(7.15, 10.7, -23.31)[:2]); p1 = np.array(w2b(9.7, 10.7, -25.75)[:2])
    seg = p1 - p0; tt = ((co[:, :2] - p0) @ seg) / (seg @ seg)
    dist = np.linalg.norm(co[:, :2] - (p0 + np.clip(tt, 0, 1)[:, None] * seg), axis=1)
    # flat ends (tt in [0, 0.9]): no round caps, so the hillside past the last step is kept
    inside |= (tt >= 0) & (tt <= 0.9) & (dist < 1.3 / 45.0) & (co[:, 2] > (10.7 - 22.275) / 45.0) & (co[:, 2] < (16.0 - 22.275) / 45.0)
    # 2) open top of the spiral shaft (cylinder r<2.6 m about the shaft centre, above y = 8 m)
    scx, scy, _ = w2b(5.7, 0.0, -20.8)
    inside |= (((co[:, 0] - scx) ** 2 + (co[:, 1] - scy) ** 2) < (3.1 / 45.0) ** 2) & (co[:, 2] > (8.0 - 22.275) / 45.0)
    bm = bmesh.new(); bm.from_mesh(me); bm.verts.ensure_lookup_table()
    doomed = [v for v in bm.verts if inside[v.index]]
    bmesh.ops.delete(bm, geom=doomed, context="VERTS")
    loose = [v for v in bm.verts if not v.link_faces]
    if loose: bmesh.ops.delete(bm, geom=loose, context="VERTS")
    # drop tiny orphan fragments left near the boats (components < 1500 faces fully inside a padded zone)
    PAD = 0.05   # xy padding only: fragments must also sit entirely in the boat height band (below the planks)
    def in_zone(v):
        return any(x0 - PAD <= v.co.x <= x1 + PAD and y0 - PAD <= v.co.y <= y1 + PAD and z0 <= v.co.z <= z1
                   for x0, x1, y0, y1, z0, z1 in BOAT_BOXES)
    bm.faces.ensure_lookup_table()
    seen, orphans = set(), []
    for f in bm.faces:
        if f.index in seen or not all(in_zone(v) for v in f.verts):
            continue
        # traverse the WHOLE connected component, then decide
        stack, comp = [f], []
        seen.add(f.index)
        while stack:
            cur = stack.pop(); comp.append(cur)
            for e in cur.edges:
                for nf in e.link_faces:
                    if nf.index not in seen:
                        seen.add(nf.index); stack.append(nf)
        if len(comp) < 400 and all(in_zone(v) for c in comp for v in c.verts):
            orphans.extend(comp)
    if orphans:
        bmesh.ops.delete(bm, geom=list({f for f in orphans}), context="FACES")
        loose = [v for v in bm.verts if not v.link_faces]
        if loose: bmesh.ops.delete(bm, geom=loose, context="VERTS")
    print(f"BOATS orphan faces removed: {len(orphans)}")
    before = len(me.polygons)
    bm.to_mesh(me); bm.free()
    print(f"BOATS removed faces: {before} -> {len(me.polygons)}")

def arrays(obj):
    me = obj.data
    n = len(me.vertices)
    co = np.empty(n * 3, dtype=np.float32); me.vertices.foreach_get("co", co); co = co.reshape(-1, 3)
    nl = len(me.loops)
    vi = np.empty(nl, dtype=np.int32); me.loops.foreach_get("vertex_index", vi)
    assert len(me.polygons) * 3 == nl, "mesh is not all triangles"
    return co, vi.reshape(-1, 3)

def dist_to_path(co):
    best = np.full(len(co), 1e9, dtype=np.float32)
    for a, b in SEGMENTS:
        pa, pb = PATH[a], PATH[b]
        ab = pb - pa
        t = np.clip(((co - pa) @ ab) / (ab @ ab), 0, 1)
        q = pa + t[:, None] * ab
        best = np.minimum(best, np.linalg.norm(co - q, axis=1))
    return best

def region_tris_at(dist, tris, radius):
    return int((dist[tris] < radius).all(axis=1).sum())

def pick_radius(dist, tris, budget):
    lo, hi = 0.0, 0.3
    for _ in range(25):
        mid = (lo + hi) / 2
        if region_tris_at(dist, tris, mid) > budget: hi = mid
        else: lo = mid
    return lo

def build(total_target, region_budget, shrink_px=None, strip=False):
    rest_target = total_target - region_budget
    for attempt in range(3):
        obj = fresh_import()
        remove_boats(obj)
        co, tris = arrays(obj)
        start = len(tris)
        dist = dist_to_path(co)
        radius = pick_radius(dist, tris, region_budget)
        r0 = region_tris_at(dist, tris, radius)
        vg = obj.vertex_groups.new(name="protect")
        vg.add([int(i) for i in np.nonzero(dist < radius)[0]], 1.0, "REPLACE")
        mod = obj.modifiers.new("dec", "DECIMATE")
        mod.decimate_type = "COLLAPSE"
        mod.vertex_group = vg.name
        mod.invert_vertex_group = True          # protected region = untouched
        mod.ratio = min(1.0, total_target / start)   # ratio applies to the whole mesh; protected tris are skipped
        bpy.context.view_layer.objects.active = obj
        bpy.ops.object.modifier_apply(modifier=mod.name)
        co2, tris2 = arrays(obj)
        d2 = dist_to_path(co2)
        r1 = region_tris_at(d2, tris2, radius)
        total = len(tris2)
        print(f"RESULT try={attempt} radius={radius:.3f} total={total} (target {total_target}) region {r0} -> {r1}")
        break
    if shrink_px:
        for img in bpy.data.images:
            w, h = img.size
            if max(w, h) > shrink_px:
                s = shrink_px / max(w, h)
                img.scale(int(w * s), int(h * s))
    if strip:
        obj.data.materials.clear()

build(150000, 85000, shrink_px=4096)
bpy.ops.export_scene.gltf(filepath=out_visual, export_format="GLB",
                          export_image_format="JPEG", export_jpeg_quality=85)
build(30000, 12000, strip=True)
bpy.ops.export_scene.gltf(filepath=out_collider, export_format="GLB", export_materials="NONE")
print("DONE")
