"""Copies named animation clips from one Meshy (Mixamo-skeleton) character to another, offline in Blender, so a character whose
download lacks a clip (Arthur's Idle_03 is a stretch, Daniel has no idle) can borrow Ted's. Keeps every clip the target already has.

  blender -b -P tools/copy_clips.py -- <from.glb> <to.glb> <out.glb> Idle_3 [more clip names]

Both rigs come from the same Meshy T-pose template with the same bone names, so the bone rotations carry over as they are. Bones
the source has and the target lacks (fingers, a jaw) are dropped from the copy, and so are their location and scale keys apart
from the Hips, so the copy never stretches the target's bones. The jaw is left out too: jaw_lipsync.gd drives it.
"""
import sys

import bpy

argv = sys.argv[sys.argv.index("--") + 1:]
src, dst, out, clips = argv[0], argv[1], argv[2], argv[3:]

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=src)
src_objs = list(bpy.data.objects)
copied = {}
for name in clips:
    act = bpy.data.actions.get(name)
    if act is None:
        sys.exit("copy_clips: %s has no clip %s (has %s)" % (src, name, [a.name for a in bpy.data.actions]))
    act.use_fake_user = True
    copied[name] = act
for o in src_objs:
    bpy.data.objects.remove(o, do_unlink=True)
for act in list(bpy.data.actions):                     # the source's other clips must not ride along into the export
    if act not in copied.values():
        bpy.data.actions.remove(act)
keep_actions = set(bpy.data.actions)

bpy.ops.import_scene.gltf(filepath=dst)
arm = next(o for o in bpy.data.objects if o.type == "ARMATURE")
bones = {b.name for b in arm.data.bones}
for name, act in copied.items():
    if name in [a.name for a in bpy.data.actions if a not in keep_actions]:
        sys.exit("copy_clips: %s already has a clip called %s" % (dst, name))
    act.name = name                                    # the target's import may have taken the bare name
    fcurves = act.fcurves if hasattr(act, "fcurves") and len(act.fcurves) else [fc for l in act.layers for s in l.strips for cb in s.channelbags for fc in cb.fcurves]
    dropped = 0
    for fc in list(fcurves):
        path = fc.data_path
        bone = path.split('"')[1] if path.startswith("pose.bones[") else None
        bad = bone is not None and (bone not in bones or bone == "mixamorig:Jaw" or (not path.endswith("rotation_quaternion") and bone != "mixamorig:Hips"))
        if bad:
            try:
                act.fcurves.remove(fc)
            except Exception:
                for l in act.layers:
                    for s in l.strips:
                        for cb in s.channelbags:
                            if fc in list(cb.fcurves):
                                cb.fcurves.remove(fc)
            dropped += 1
    ad = arm.animation_data or arm.animation_data_create()
    track = ad.nla_tracks.new()
    track.name = name
    strip = track.strips.new(name, int(act.frame_range[0]), act)
    if hasattr(strip, "action_slot") and len(act.slots):
        strip.action_slot = act.slots[0]
    track.mute = True
    print("copy_clips: %s -> %s (%d curves dropped)" % (name, dst, dropped))

bpy.ops.export_scene.gltf(filepath=out, export_format="GLB", export_image_format="AUTO", export_animations=True,
                          export_animation_mode="ACTIONS", export_force_sampling=True, export_optimize_animation_size=False)
print("copy_clips: wrote", out)
