"""Adds a "mixamorig:Jaw" bone to a Meshy (Mixamo-skeleton) character and weights the lower face to it, so
scripts/character/jaw_lipsync.gd can open the mouth from the voice. Offline, in Blender. Keeps every animation.

  blender -b -P tools/add_jaw_bone.py -- <in.glb> <out.glb> [--test-pose]

All the positions are fractions of the head length L (the Head bone to HeadTop_End), measured on Ted (the Meshy "Ironclad
Mariner", 30 Oct 2026): the hinge sits under the ear, the mouth line a little below the nose, the chin at the bottom of the
beard. Arthur and Daniel come from the same Meshy rig and head size, so the same fractions should do; override on the command
line (--hinge_up, --hinge_front, --mouth, --chin, all in units of L from the Head bone's origin; up is positive; --fwd0 and
--fwd1 set how far forward of the head the face starts) if a face differs (Arthur and Daniel needed their own: see Assets/Characters/SOURCES.md). The front is found from the model's "headfront" bone, so a character facing either way works.

Weights: a vertex that the Head bone already moves (and is in front of the hinge, within the lower face) gives part of its Head
weight to the jaw: 0 at the mouth line rising smoothly to 1 at the chin, faded out toward the ears so the cheeks near the
hinge hardly move. The coat collar and neck keep their own weights (a vertex only gives up Head weight it already has).
--test-pose opens the jaw 12 degrees on the evaluated mesh and prints how far the chin and the mouth line move.
"""
import argparse
import math
import sys

import bpy
from mathutils import Vector

argv = sys.argv[sys.argv.index("--") + 1:]
ap = argparse.ArgumentParser()
ap.add_argument("src")
ap.add_argument("out")
ap.add_argument("--hinge_up", type=float, default=0.28)
ap.add_argument("--hinge_front", type=float, default=0.49)
ap.add_argument("--mouth", type=float, default=0.2)
ap.add_argument("--chin", type=float, default=-0.28)
ap.add_argument("--fwd0", type=float, default=0.35, help="forward from the Head origin (units of L) where the jaw weight starts")
ap.add_argument("--fwd1", type=float, default=0.55, help="and where it is full: the neck, scarf and collar sit behind this, the face and beard in front")
ap.add_argument("--test-pose", action="store_true")
a = ap.parse_args(argv)

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=a.src)
arm = next(o for o in bpy.data.objects if o.type == "ARMATURE")
mesh = next(o for o in bpy.data.objects if o.type == "MESH" and o.parent == arm and len(o.vertex_groups) > 10)
M = arm.matrix_world
head_b = arm.data.bones["mixamorig:Head"]
top_b = arm.data.bones["mixamorig:HeadTop_End"]
front_b = arm.data.bones["headfront"]
head = M @ head_b.head_local
L = (M @ top_b.head_local - head).length
front = (M @ front_b.head_local - head)
front.z = 0.0
front.normalize()
up = Vector((0, 0, 1))
print("jaw: head length L = %.3f, front = %s" % (L, tuple(round(v, 2) for v in front)))

hinge = head + up * (a.hinge_up * L) + front * (a.hinge_front * L)
chin_pt = head + up * (a.chin * L) + front * (a.hinge_front * L * 1.4)

# the bone: from the hinge, pointing forward and down to the chin
bpy.context.view_layer.objects.active = arm
bpy.ops.object.mode_set(mode="EDIT")
eb = arm.data.edit_bones.new("mixamorig:Jaw")
eb.head = arm.matrix_world.inverted() @ hinge
eb.tail = arm.matrix_world.inverted() @ chin_pt
eb.parent = arm.data.edit_bones["mixamorig:Head"]
eb.use_connect = False
bpy.ops.object.mode_set(mode="OBJECT")

# the weights: by position (Meshy's own weights put much of the beard on the shoulders, so a share of the Head weight is not enough)
mw = mesh.matrix_world
jg = mesh.vertex_groups.new(name="mixamorig:Jaw")
z_mouth = head.z + a.mouth * L
z_chin = head.z + a.chin * L
f_hinge = hinge.dot(front)
f_head = head.dot(front)
side = front.cross(up)
moved = 0
for v in mesh.data.vertices:
    p = mw @ v.co
    t = (z_mouth - p.z) / (z_mouth - z_chin)          # 0 at the mouth line, 1 at the chin
    if t <= 0.0 or t > 1.4:
        continue
    t = min(t, 1.0)
    w = t * t * (3.0 - 2.0 * t)
    ahead = (p.dot(front) - f_hinge) / (0.25 * L)     # in front of the hinge, so the cheeks by the ears stay put
    w *= max(0.0, min(ahead, 1.0))
    fwd = (p.dot(front) - f_head) / L                 # far enough forward to be face or beard, not the neck, scarf or collar
    w *= max(0.0, min(1.0, (fwd - a.fwd0) / (a.fwd1 - a.fwd0)))
    lat = abs(p.dot(side) - head.dot(side)) / (0.55 * L)
    w *= 1.0 - max(0.0, min(1.0, (lat - 0.6) / 0.4))
    if w < 0.02:
        continue
    total = 0.0
    for g in v.groups:
        total += g.weight
    for g in v.groups:
        mesh.vertex_groups[g.group].add([v.index], g.weight * (1.0 - w) / max(total, 1e-6), "REPLACE")
    jg.add([v.index], w, "REPLACE")
    moved += 1
ws = [g.weight for v in mesh.data.vertices for g in v.groups if g.group == jg.index]
print("jaw: %d vertices weighted to the jaw (of %d), weights up to %.2f, mean %.2f" % (moved, len(mesh.data.vertices), max(ws), sum(ws) / len(ws)))

if a.test_pose:
    pb = arm.pose.bones["mixamorig:Jaw"]
    pb.rotation_mode = "XYZ"
    # two jaw-weighted vertices: the lowest (the chin) and the most forward one near the mouth line
    jv = [v for v in mesh.data.vertices if any(g.group == jg.index and g.weight > 0.05 for g in v.groups)]
    cands = [min(jv, key=lambda v: (mw @ v.co).z)]
    cands.append(max((v for v in jv if abs((mw @ v.co).z - (z_mouth - 0.1 * L)) < 0.1 * L), key=lambda v: (mw @ v.co).dot(front)))
    print("TEST using %d jaw vertices; chin z %.3f, mouth vertex z %.3f" % (len(jv), (mw @ cands[0].co).z, (mw @ cands[1].co).z))
    def evaluated(angle):
        pb.rotation_euler = (angle, 0, 0)
        bpy.context.view_layer.update()
        dg = bpy.context.evaluated_depsgraph_get()
        ev = mesh.evaluated_get(dg).to_mesh()
        return [mw @ ev.vertices[v.index].co for v in cands]
    base = evaluated(0.0)
    for sign in (1.0, -1.0):
        now = evaluated(math.radians(12.0) * sign)
        for name, b, n in zip(("chin", "mouth"), base, now):
            d = n - b
            print("TEST rot X %+d deg: %s moves dz %+.3f dfront %+.3f" % (12 * sign, name, d.z, d.dot(front)))
    pb.rotation_euler = (0, 0, 0)

bpy.ops.export_scene.gltf(filepath=a.out, export_format="GLB", export_image_format="AUTO", export_animations=True,
                          export_animation_mode="ACTIONS", export_force_sampling=True, export_optimize_animation_size=False)
print("jaw: wrote", a.out)
