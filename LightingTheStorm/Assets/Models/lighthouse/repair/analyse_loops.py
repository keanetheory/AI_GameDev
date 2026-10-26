"""analyse_loops.py - blender -b -P analyse_loops.py: lists the boundary loops of exterior_carved_in.glb (Lighthouse frame: Godot x, y, z)."""
import bpy, bmesh, os, math
HERE=os.path.dirname(os.path.abspath(__file__))
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=os.path.join(HERE,"exterior_carved_in.glb"))
obs=[o for o in bpy.data.objects if o.type=='MESH']
print("MESHES",[(o.name,len(o.data.polygons)) for o in obs])
ob=obs[0]
bm=bmesh.new(); bm.from_mesh(ob.data)
bm.transform(ob.matrix_world)
print("VERTS",len(bm.verts),"FACES",len(bm.faces))
bmesh.ops.remove_doubles(bm,verts=bm.verts,dist=1e-4)
print("AFTER WELD VERTS",len(bm.verts))
bm.edges.ensure_lookup_table()
bnd=[e for e in bm.edges if len(e.link_faces)==1]
print("BOUNDARY EDGES",len(bnd))
# loops by union of shared verts
parent={}
def find(x):
    while parent[x]!=x:
        parent[x]=parent[parent[x]]; x=parent[x]
    return x
for e in bnd:
    for v in e.verts: parent.setdefault(v.index,v.index)
    a,b=find(e.verts[0].index),find(e.verts[1].index)
    if a!=b: parent[a]=b
groups={}
for e in bnd:
    groups.setdefault(find(e.verts[0].index),[]).append(e)
rows=[]
for g,es in groups.items():
    vs={v for e in es for v in e.verts}
    # Blender (X,Y,Z)=Godot (x,-z,y)
    pts=[(v.co.x,v.co.z,-v.co.y) for v in vs]
    lo=[min(p[i] for p in pts) for i in range(3)]; hi=[max(p[i] for p in pts) for i in range(3)]
    per=sum(e.calc_length() for e in es)
    rows.append((per,len(es),lo,hi))
rows.sort(reverse=True)
for per,n,lo,hi in rows[:60]:
    print("LOOP edges %4d perim %6.2f  x %.1f..%.1f y %.1f..%.1f z %.1f..%.1f"%(n,per,lo[0],hi[0],lo[1],hi[1],lo[2],hi[2]))
print("LOOPS",len(rows),"small(<1.5m)",sum(1 for r in rows if r[0]<1.5))
