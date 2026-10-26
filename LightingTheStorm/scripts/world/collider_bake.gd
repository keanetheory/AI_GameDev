# collider_bake.gd - what collider_builder.gd computed for one node, saved so the next load can skip the work.
# Written by tools/bake_colliders.gd into res://Assets/Baked/colliders/. `key` is a hash of the node's settings and of
# the model's meshes, so a changed carve or a regenerated .glb no longer matches and the builder works it out live again.
extends Resource

@export var key := ""
## One entry per mesh the builder treats (in find_children order, markers left out). Each is a Dictionary:
##   "indices"  Array of PackedInt32Array, one per surface: the triangles kept by the carve (absent when nothing is carved)
##   "verts"    Array of PackedVector3Array, one per surface: the vertices after flattening (absent when nothing is flattened)
##   "normals"  Array of PackedVector3Array, as "verts"
##   "shape"    the collision Shape3D, or null when the node is not solid
@export var meshes: Array = []
