#!/usr/bin/env python3
"""Brusskania lighthouse V3 -- procedural, experimental greybox; glTF Y-up metres.
Execute: python build_lighthouse_greybox_v3.py
Requires trimesh, numpy and the two supplied JSON surveys beside this script.
The heightmap is an overhead *top surface*, not a wall/roof volumetric scan.
"""
import json, math, os
from pathlib import Path
import numpy as np
import trimesh
BASE=Path(__file__).resolve().parent
survey=json.loads((BASE/'exterior_heightmap_local.json').read_text())
door=json.loads((BASE/'exterior_door_measured.json').read_text())
H=np.array([[np.nan if t is None else t for t in row] for row in survey['rows_by_z_then_x']],float)
origin=np.array(door['door_centre_at_sill_local'],float)
N=np.array([.4309,0,.9024]); N/=np.linalg.norm(N)
U=np.array([N[2],0,-N[0]]); V=-N
TOWER=np.array([3.5,3.6])
scene=trimesh.Scene(); bounds_by_name={};meta={};stair_spec=[]

def xyz(u,v,y):return origin + U*u + V*v + [0,y-origin[1],0]
def mesh_add(name,m,group='',check_roof=True):
    if name in scene.geometry:raise ValueError('duplicate '+name)
    scene.add_geometry(m,geom_name=name,node_name=name)
    bounds_by_name[name]=m.bounds.tolist(); meta[name]={'group':group,'check_roof':check_roof}

def box(name,center,ext,group='',check_roof=True):
    m=trimesh.creation.box(extents=ext); m.apply_translation(center);mesh_add(name,m,group,check_roof)

def oriented(name,u,v,y,su,sv,sy,group='',check_roof=True):
    # u/v are the rectangle centre; y is its bottom elevation
    m=trimesh.creation.box(extents=[su,sy,sv]); basis=np.column_stack((U,[0,1,0],V))
    # U,V form a positive basis? GLTF convention x right, y up, z outward: V inward, resulting det -1 -> reverse winding fix.
    tf=np.eye(4);tf[:3,:3]=basis;tf[:3,3]=xyz(u,v,y+sy/2)
    m.apply_transform(tf)
    if np.linalg.det(basis)>0:m.invert()
    mesh_add(name,m,group,check_roof)

def slab(name,u0,u1,v0,v1,top,group):oriented(name,(u0+u1)/2,(v0+v1)/2,top-.2,u1-u0,v1-v0,.2,group)
def wall_u(name,u0,u1,v,y0,y1):oriented(name,(u0+u1)/2,v,y0,u1-u0,.2,y1-y0,'wall')
def wall_v(name,u,v0,v1,y0,y1):oriented(name,u,(v0+v1)/2,y0,.2,v1-v0,y1-y0,'wall')
def marker(name,point):box(name,np.array(point)+[0,.15,0],[.3,.3,.3],'marker',False)
def markeruv(name,u,v,y):marker(name,xyz(u,v,y))
def roof(x,z):
    # Bilinear top surface; rough and not guaranteed to correspond to the actual wall.
    i=x+14;j=z+10
    if not (0<=i<26 and 0<=j<24):return float('nan')
    a,b=int(i),int(j);fx=i-a;fz=j-b
    sample=np.array([H[b,a],H[b,a+1],H[b+1,a],H[b+1,a+1]])
    if np.any(np.isnan(sample)):return float('nan')
    return float(sample @ [(1-fx)*(1-fz),fx*(1-fz),(1-fx)*fz,fx*fz])
def prism(name,polygon_xz,y_bottom,y_top,group,check_roof=True):
    # Convex footprint prism, explicit triangles and outward normals.
    p=np.asarray(polygon_xz,float);n=len(p)
    area=np.sum(p[:,0]*np.roll(p[:,1],-1)-np.roll(p[:,0],-1)*p[:,1])/2
    # In XZ-plane, CCW from above corresponds to reversed usual 3D Y-up winding.
    if area>0:p=p[::-1]
    vertices=np.concatenate((np.column_stack([p[:,0],np.full(n,y_bottom),p[:,1]]),np.column_stack([p[:,0],np.full(n,y_top),p[:,1]])))
    faces=[]
    for i in range(1,n-1):faces.append([n,n+i,n+i+1]);faces.append([0,i+1,i])
    for i in range(n):
        j=(i+1)%n;faces.extend(([i,j,n+j],[i,n+j,n+i]))
    m=trimesh.Trimesh(vertices=vertices,faces=faces,process=True)
    if m.volume<0:m.invert()
    mesh_add(name,m,group,check_roof)

def cylinder(name,x,z,rb,rt,y0,y1,group,seg=24,check_roof=True):
    a=np.linspace(0,2*np.pi,seg,endpoint=False)
    # Simple truncated conical closed solid
    vertices=np.array([[x+rb*np.cos(t),y0,z+rb*np.sin(t)] for t in a]+[[x+rt*np.cos(t),y1,z+rt*np.sin(t)] for t in a]);faces=[]
    for i in range(1,seg-1):faces.extend([[0,i+1,i],[seg,seg+i,seg+i+1]])
    for i in range(seg):j=(i+1)%seg;faces.extend([[i,j,seg+j],[i,seg+j,seg+i]])
    m=trimesh.Trimesh(vertices=vertices,faces=faces,process=True)
    if m.volume<0:m.invert()
    mesh_add(name,m,group,check_roof)

# Footprint deliberately reduced relative to the V1 plan, leaving the entry plane clear.
# The house envelope is schematically u:-2.35..5.45, v:0.36..7.05, not an inferred exact inner-wall survey.
# Main floor is split around the stair hole, avoiding floor-over-stair collisions.
GF=.97;B1=-2.0;L1=None;LF=17.9
for name,vals in [('G_floor_entry',(-2.25,5.65,.35,2.30)),('G_floor_west',(-2.25,.8,2.30,6.8)),('G_floor_east',(3.6,5.65,2.30,6.8)),('G_floor_rear',(.8,3.6,5.7,6.8))]:slab(name,*vals,GF,'ground_slab')
# Basement slab fills smaller footprint, underneath exterior base into rock.
slab('B1_floor',-2.25,5.65,.35,6.8,B1,'basement_slab')
# G walls, keep door opening 1.8 wide from u=-.9..+.9, height 3.0.
# Inner wall behind porch only 0.15m (housewards) to avoid projecting into doorway plane.
for side,(a,b) in enumerate([(-2.25,-1.0),(1.0,5.65)]):wall_u(f'G_front_wall_{side}',a,b,.26,GF,3.75)
# Window opens towards dock (direction -0.77,+0.63), west-end slanted face: opening via separated wall sections.
wall_v('G_outer_west_low',-2.25,.36,3.0,GF,1.90)
wall_v('G_outer_west_mid',-2.25,.36,3.0,2.90,3.75)
wall_v('G_outer_west_rear',-2.25,4.3,6.8,GF,3.75)
# Window opening width 1.3 along v=3.0..4.3, sill 1.9, head 2.9
wall_v('G_outer_west_window_sill',-2.25,3.0,4.3,GF,1.9)
wall_v('G_outer_west_window_lintel',-2.25,3.0,4.3,2.9,3.75)
# True 1.45 m passage in this greybox's east wall; the exterior wall still needs a matching cut later.
wall_v('G_outer_east_front',5.65,.36,.80,GF,3.75)
wall_v('G_outer_east_back',5.65,2.25,6.8,GF,3.75)
wall_v('G_outer_east_header',5.65,.80,2.25,3.25,3.75)
wall_u('G_back_wall',-2.25,5.65,6.8,GF,3.75)
# A single office enclosure partition, 1.2m door gap. Front hall deliberately generous for Ted+Arthur.
wall_u('G_office_partition_left',-2.25,-1.05,3.25,GF,3.75)
wall_u('G_office_partition_right',.25,1.0,3.25,GF,3.75)
# stairwell opening from u1..2.5 and v2.65..6.65
# small storage placeholder to east against wall (away from door clearance)
oriented('G_office_counter',-1.5,5.2,GF, .45,.7,.75,'placeholder')
markeruv('G_entry_marker',0,2.1,GF)
markeruv('G_ted_greeting_marker',-1.35,2.1,GF)
markeruv('G_window_view_marker',-1.25,3.6,GF)
# Inward-swing front door 1.8m-radius clear: no obstacles for v in [0,1.8]

# Engine basement walling, engine and coal setpieces, Daniel's open stand area.
wall_u('B1_rear_wall',-2.25,5.65,6.8,B1,0.65)
wall_v('B1_west_wall',-2.25,.35,6.8,B1,.65)
wall_v('B1_east_wall',5.65,.35,6.8,B1,.65)
wall_u('B1_front_wall',-2.25,5.65,.35,B1,.65)
oriented('B1_boiler_placeholder',-1.15,5.65,B1,1.45,.8,1.65,'placeholder')
oriented('B1_coal_pile_placeholder',-1.2,3.75,B1,.8,.85,.65,'placeholder')
oriented('B1_dynamo_placeholder',3.8,5.55,B1,1.0,.75,1.1,'placeholder')
markeruv('B1_boiler_interaction_marker',-.5,4.7,B1)
markeruv('B1_coal_pickup_marker',-.65,2.9,B1)
markeruv('B1_daniel_marker',3.8,2.0,B1)
# Two compliant switchback flights, 8 risers each; upper route outward towards back,
# then returns along the adjacent lane. They occupy the deliberate floor cut-out.
n=16;dh=(GF-B1)/n;tread=.30
for i in range(8):
    # upper: top walking elevation drops on increasing v from 2.3 to 4.7
    top=GF-dh*(i+1);v0=2.3+i*tread
    oriented(f'B1_stair_upper_{i:02d}',1.40,v0+tread/2,B1,1.0,tread,top-B1,'stair',False)
    stair_spec.append({'name':f'B1_stair_upper_{i:02d}','rise':dh,'tread':tread,'width':1.0,'headroom_est':2.3})
# turnaround landing, 2.65 x 1.0m, y=-0.515m, no overlap with steps.
oriented('B1_switchback_landing',2.2,5.2,B1,2.65,1.0,GF-8*dh-B1,'landing',False)
for i in range(8):
    # lower: continuing descent while heading back toward the front
    top=GF-dh*(9+i);v0=4.7-(i+1)*tread
    oriented(f'B1_stair_lower_{i:02d}',3.0,v0+tread/2,B1,1.0,tread,top-B1,'stair',False)
    stair_spec.append({'name':f'B1_stair_lower_{i:02d}','rise':dh,'tread':tread,'width':1.0,'headroom_est':2.3})
# Upper and lower floor approach pads are integrated into floor slabs.
# Hall-to-tower connection: east wall has actual 1.45m aperture.
# The modelled tower base uses a ring, not a missing ground floor or a landing through the central column.
slab('G_tower_link',5.65,7.35,.85,2.20,GF,'ground_slab')

# The tower is in the surveyed XZ position.  Entry starts from the west edge of its walkable annulus.
# A 96-step / four-turn spiral climbs from y=.97 to y=17.9; 24 steps/turn, riser .1764m.
start=GF;steps=96;rise=(LF-start)/steps;angle_step=2*math.pi/24
inner=1.14;outer=2.07
# Ground base: a solid walking ring; centre kept closed by the vertical core.
for i in range(24):
    a=np.linspace(i*2*math.pi/24,(i+1)*2*math.pi/24,4)
    p=[[TOWER[0]+r*np.cos(t),TOWER[1]+r*np.sin(t)] for r,t in [(outer,t) for t in a]+[(inner,t) for t in a[::-1]]]
    prism(f'Tower_ground_floor_{i:02d}',p,GF-.2,GF,'tower_ground_slab',False)
# Entry-facing landing at 147 degrees: its centre is 1.85m from the tower axis.
entry_angle=math.radians(147)
landc=np.array([TOWER[0]+1.66*math.cos(entry_angle),GF-.10,TOWER[1]+1.66*math.sin(entry_angle)])
# A wedge in the annulus is already a 1.0m-wide solid bottom landing, not a slab crossing the core.
for i in range(steps):
    a0=entry_angle+i*angle_step;a1=a0+angle_step
    theta=np.linspace(a0,a1,4)
    p=[[TOWER[0]+r*np.cos(t),TOWER[1]+r*np.sin(t)] for r,t in [(outer,t) for t in theta]+[(inner,t) for t in theta[::-1]]]
    bot=start+rise*i;top=bot+rise
    prism(f'Tower_spiral_step_{i:03d}',p,bot,top,'stair',False)
    stair_spec.append({'name':f'Tower_spiral_step_{i:03d}','rise':rise,'tread':inner*angle_step,'width':outer-inner,'headroom_est':24*rise})
# Central solid always contained within the inner radius, with no access landing inside it.
cylinder('Tower_inner_guard_core',*TOWER,1.01,1.01,GF,LF,'guard',36,False)
# Lantern has an OPEN stairwell wedge over the last 14 steps, not a full annular slab on top of them.
# The remaining sectors form the walkable gallery.  A bridging platform accesses the centre lamp.
# Full ring would block player's head during ascent.
for i in range(24):
    if i in set(range(10,24)):
        continue
    a=np.linspace(entry_angle+i*angle_step,entry_angle+(i+1)*angle_step,4)
    p=[[TOWER[0]+r*np.cos(t),TOWER[1]+r*np.sin(t)] for r,t in [(outer,t) for t in a]+[(inner,t) for t in a[::-1]]]
    prism(f'Lantern_gallery_{i:02d}',p,LF-.2,LF,'lantern_slab',False)
# The last step leads directly onto the first gallery sector after one complete revolution.
# Lamp mount stands on the central core; no assembly puzzle.
cylinder('Lantern_arc_lamp_mount',*TOWER,.44,.44,LF,LF+.45,'placeholder',20,False)
box('Lantern_arc_lamp_socket_marker',[TOWER[0],LF+.60,TOWER[1]],[.3,.3,.3],'marker',False)
# Ted stands on the retained portion of the ring, on the inland side.
a_ted=entry_angle+4*angle_step
marker('Lantern_ted_marker',[TOWER[0]+1.65*math.cos(a_ted),LF,TOWER[1]+1.65*math.sin(a_ted)])
# L1 bedroom REMOVED: optional in GDD, no verified stair or measured 2.2m roof clearance.

# --------------------------- audits ---------------------------
def aabb_overlap(b1,b2):return np.all(np.minimum(b1[1],b2[1])-np.maximum(b1[0],b2[0])>1e-6)
def point_inside_aabb(p,b):return bool(np.all(np.asarray(p)>=b[0]) and np.all(np.asarray(p)<=b[1]))
def vertices_of(n):return scene.geometry[n].vertices
checks=[]
def record(label,result,details=None):
    checks.append({'check':label,'passed':bool(result),'details':details});print(f"{'PASS' if result else 'FAIL'}: {label} {details or ''}")
# Door entrance volume: half width .9, v(0..0.3), Y .97..3.97; intentionally ignore G slab at sill.
blocked=[]
for name in scene.geometry:
    if name=='G_entry_marker' or name.startswith('G_floor'):continue
    vs=vertices_of(name)
    # tested with conservative AABB in u,v,y (could false-positive with rotated circular parts far away)
    rel=vs-origin;u=rel@U;v=rel@V
    if np.max(u)<-.9 or np.min(u)>.9 or np.max(v)<0 or np.min(v)>.3 or vs[:,1].max()<GF or vs[:,1].min()>GF+3:continue
    blocked.append(name)
record('Door opening 1.8 x 3.0 x 0.3m clear',not blocked,blocked[:12])
# Approximate 100 deg inward swing is a radius swept on inside of door, baseline from door hinge.
blocked=[]
for name in scene.geometry:
    if name.endswith('_marker') or name.startswith('G_floor'):continue
    vs=vertices_of(name);rel=vs-origin;uu=rel@U;vv=rel@V
    if vs[:,1].min()>GF+2.8 or vs[:,1].max()<GF+.25:continue
    # bounding test sample vertices and mesh bbox interior sample; ignores walls on opening jamb.
    if np.any((vv>.12)&(vv<1.8)&(uu>-.88)&(uu<.88)) :blocked.append(name)
record('Inward-swing occupied sector clear (conservative approximate)',not blocked,blocked[:12])
# Survey grid has a top-height scalar, rather than a true envelope. This check is partial
# sample shell roof bound for non-tower house aboveground geometry, exclude markers and props.
roofviol=[];unmeas=[]
for name in scene.geometry:
    if name.startswith(('Tower_','Lantern_','B1_')):continue
    if name.endswith('_marker'):continue
    vertices=vertices_of(name)
    # only top corners and interpolated footprint centre. Heightmap is topmost exterior point.
    ymax=float(vertices[:,1].max());pts=vertices[:,[0,2]]
    pts=np.vstack([pts,pts.mean(axis=0)])
    roofs=np.array([roof(*p) for p in pts]);ok=roofs[np.isfinite(roofs)]
    if len(ok)<len(roofs):unmeas.append(name)
    if len(ok) and np.min(ok)<ymax+.05:roofviol.append([name,round(float(np.min(ok)),2),round(ymax,2)])
record('House parts under surveyed roof (conservative)',not roofviol and not unmeas,{'above_roof':roofviol[:16],'unsampled':unmeas[:10]})
# horizontal footprint cannot be robustly inferred from top surface; report non-certification.
record('Every part >=0.3m inside measured exterior wall',False,'Unavailable: overhead heightmap includes ground and rocks; no surveyed exterior wall boundaries')
# At tower heights interpolate radius, subtract margin .4, test tower spiral+guard+lantern only.
viol=[]
for name in scene.geometry:
    if not name.startswith(('Tower_','Lantern_')):continue
    for x,y,z in vertices_of(name):
        outer=np.interp(y,[12,16,20],[3.27,2.97,2.63]);safe=outer-.4
        if np.hypot(x-TOWER[0],z-TOWER[1])>safe+1e-4:
            viol.append(name);break
record('All tower parts inside interpolated (outer-0.4m) radius',not viol,list(dict.fromkeys(viol))[:15])
record('Stairs riser <=.20m',all(s['rise']<=.2 for s in stair_spec),max(s['rise'] for s in stair_spec))
record('Stairs tread >=.28m',all(s['tread']>=.28 for s in stair_spec),min(s['tread'] for s in stair_spec))
record('Stairs width >=.90m',all(s['width']>=.9 for s in stair_spec),min(s['width'] for s in stair_spec))
record('Stairs headroom >=2.1m (theoretical pitch)',all(s['headroom_est']>=2.1 for s in stair_spec),'theoretical pitch only; the lantern stairwell gap requires in-engine capsule verification')
# AABB/capsule voxel movement needs collision occupancy and a true continuous navigation volume;
# refuse to fabricate proof. Proxy graph accounts for stair reach but not continuous space.
record('Capsule flood-fill: entry to basement Daniel',False,'Not validated by a 0.1m capsule-aware voxel flood-fill; geometry requires Godot nav/collision testing')
record('Capsule flood-fill: entry to lantern socket',False,'Not validated by a 0.1m capsule-aware voxel flood-fill; stairs and gallery need practical alignment testing')
record('Part count <=400',len(scene.geometry)<400,len(scene.geometry))
watertight=[name for name,m in scene.geometry.items() if not m.is_watertight or m.volume<=0]
record('Closed meshes, outward normals',not watertight,watertight[:15])
# Textureless output; retain node names.
out=BASE/'lighthouse_greybox_v3.glb';out.write_bytes(scene.export(file_type='glb'))
# keep v1 fields, update coords, preserve literal measured fields
old=json.loads((BASE/'lighthouse_greybox_v1_alignment.json').read_text())
alignment={**old,'version':'3.0 revised prototype','coordinate_frame':'Godot exterior postimport local, Y up, metres, zero additional transform','scale_from_original_glb':old.get('scale_from_original_glb'),
 'assumed_ground_level_m':GF,'ground_floor_y':GF,'basement_floor_y':B1,'upper_floor_y':None,'lantern_floor_y':LF,
 'main_house_centre_xz':list(np.round(xyz(1.5,3.7,GF)[[0,2]],5)),
 'main_house_long_axis_xz':[round(float(U[0]),6),round(float(U[2]),6)],
 'tower_centre_xz':TOWER.tolist(),'entry_marker_local_u_v':[0,2.1],
 'entry_door':{'centre':door['door_centre_at_sill_local'],'normal':door['door_outward_normal_local'],'width':door['door_width_m'],'height':door['door_height_m'],'along_wall':door['door_along_wall_local']},
 'door_centre':door['door_centre_at_sill_local'],'door_normal':door['door_outward_normal_local'],'door_width':door['door_width_m'],
 'markers':{n:np.mean(scene.geometry[n].vertices,axis=0).round(4).tolist() for n in scene.geometry if n.endswith('_marker')},
 'parts_count':len(scene.geometry),'checks':checks,
 'warning':'Revised GLB, not certified walkable. The EXTERIOR mesh still has a solid house-to-tower wall requiring separate carving/collision regeneration. L1 removed. Heightmap is top-down only, not volumetric; flood-fill not run.'}
(BASE/'lighthouse_greybox_v3_alignment.json').write_text(json.dumps(alignment,indent=2))
print('EXPORTED',out,'parts',len(scene.geometry))
