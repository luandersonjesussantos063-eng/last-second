"""Original fictional PRF SUV and touring motorcycle, exported as optimized game GLBs.
Run: blender -b --python scripts/build-prf-fleet.py
All geometry and markings are authored here; no vehicle meshes are downloaded.
"""
import bpy,math,json,hashlib,sys
from pathlib import Path
from mathutils import Vector
sys.path.insert(0,str(Path(__file__).resolve().parent))
from model_shapes import material,box,cylinder,sphere,tube,mesh,join_by_material
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'assets/models';OUT.mkdir(exist_ok=True)
manifest={'source':'Original fictional game vehicles authored in scripts/build-prf-fleet.py','files':{}}
def reset():
 bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
 for d in list(bpy.data.materials):
  if not d.users:bpy.data.materials.remove(d)
def p(x,y,z):return (x,-z,y)
def b(name,mat,x,y,z,w,h,d,bevel=.02):return box(name,p(x,y,z),(w,d,h),mat,bevel)
def c(name,mat,x,y,z,r,length,axis=(1,0,0),n=20):return cylinder(name,p(x,y,z),r,length,mat,p(*axis),n)
def path(name,mat,points,r):return tube(name,[p(*q) for q in points],r,mat)
def surf(name,mat,points,faces,smooth=False):return mesh(name,[p(*v) for v in points],faces,mat,smooth)
def empty(name,loc=(0,0,0)):
 ob=bpy.data.objects.new(name,None);bpy.context.collection.objects.link(ob);ob.location=loc;return ob
def label(text,mat,loc,size,rotation,name='Livery'):
 bpy.ops.object.select_all(action='DESELECT');cv=bpy.data.curves.new(name,'FONT');cv.body=text;cv.align_x='CENTER';cv.align_y='CENTER';cv.size=size;cv.extrude=.0005;ob=bpy.data.objects.new(name,cv);bpy.context.collection.objects.link(ob);ob.location=p(*loc);ob.rotation_euler=rotation;cv.materials.append(mat);ob.select_set(True);bpy.context.view_layer.objects.active=ob;bpy.ops.object.convert(target='MESH');return bpy.context.object

def palette():
 paint=material('PRF navy paint',(.015,.045,.105),.65,.28);paint.node_tree.nodes.get('Principled BSDF').inputs['Coat Weight'].default_value=.35
 gold=material('PRF gold markings',(.88,.57,.035),.25,.38);metal=material('Brushed alloy',(.36,.42,.46),.82,.3);rubber=material('Tyre and trim',(.013,.018,.021),0,.88);interior=material('Cabin',(.045,.055,.065),0,.8)
 glass=material('Automotive glass',(.07,.15,.21),.25,.17,.34)
 white=material('Headlamp lens',(.8,.87,.91),.3,.25);pr=white.node_tree.nodes.get('Principled BSDF');pr.inputs['Emission Color'].default_value=(.8,.9,1,1);pr.inputs['Emission Strength'].default_value=1.4
 red=material('Red warning LED',(.8,.015,.025),.1,.24);blue=material('Blue warning LED',(.015,.13,.95),.1,.24)
 for mat,color in [(red,(1,.01,.015,1)),(blue,(.01,.1,1,1))]:pr=mat.node_tree.nodes.get('Principled BSDF');pr.inputs['Emission Color'].default_value=color;pr.inputs['Emission Strength'].default_value=3
 return paint,gold,metal,rubber,interior,glass,white,red,blue

def wheel(name,x,y,z,r,width,metal,rubber,spokes=8):
 # Separate steering and spin nodes allow animation without changing vehicle physics.
 steer=empty('Steer'+name,p(x,y,z));spin=empty('Wheel'+name);spin.parent=steer
 before=set(bpy.data.objects)
 bpy.ops.mesh.primitive_torus_add(major_radius=r*.75,minor_radius=r*.25,major_segments=24,minor_segments=8,location=(0,0,0),rotation=(0,math.pi/2,0));tire=bpy.context.object;tire.name='Radial tyre';tire.data.materials.append(rubber);tire.scale.z=width/(r*.5)
 for poly in tire.data.polygons:poly.use_smooth=True
 cylinder('Brake disc',(0,0,0),r*.55,width*.6,metal,(1,0,0),20)
 cylinder('Wheel hub',(0,0,0),r*.17,width*1.02,metal,(1,0,0),16)
 for i in range(spokes):
  angle=math.tau*i/spokes
  for side in [-1,1]:
   a=(side*width*.48,math.sin(angle)*r*.15,math.cos(angle)*r*.15);e=(side*width*.48,math.sin(angle+.14)*r*.67,math.cos(angle+.14)*r*.67)
   tube('Wheel spoke',[a,e],.018 if spokes<12 else .009,metal)
 for ob in join_by_material(set(bpy.data.objects)-before,'WheelDetail'+name):ob.parent=spin
 return steer

def export(name):
 # Merge stationary pieces by material; keep steering/wheels and LEDs independent.
 static=[o for o in bpy.data.objects if o.type=='MESH' and o.parent is None and not o.name.startswith('Flash')]
 join_by_material(static,'Body')
 bpy.ops.object.select_all(action='SELECT')
 bpy.ops.export_scene.gltf(filepath=str(OUT/name),export_format='GLB',export_yup=True,export_animations=False,export_extras=True)
 data=(OUT/name).read_bytes();triangles=sum(len(f.vertices)-2 for o in bpy.data.objects if o.type=='MESH' for f in o.data.polygons)
 manifest['files'][name]={'sha256':hashlib.sha256(data).hexdigest(),'bytes':len(data),'triangles':triangles}
 print('FLEET_BUILD',name,manifest['files'][name])

reset();paint,gold,metal,rubber,interior,glass,white,red,blue=palette()
# Continuous curved body shell, with physical wheel arch cut-outs.
profiles=[(-2.25,.84,.53,1.02),(-2.12,.98,.50,1.15),(-1.5,1.0,.5,1.18),(-.5,1.01,.5,1.2),(.65,1.0,.5,1.19),(1.45,.98,.51,1.12),(2.05,.94,.58,1.05),(2.24,.84,.63,.98)]
verts=[];faces=[]
for z,w,low,top in profiles:
 for x,y in [(0,low),(.8*w,low),(w,low+.10),(w,top-.13),(.93*w,top-.02),(.72*w,top),(0,top),(-.72*w,top),(-.93*w,top-.02),(-w,top-.13),(-w,low+.1),(-.8*w,low)]:verts.append((x,y,z))
for i in range(len(profiles)-1):
 for j in range(12):a=i*12+j;e=i*12+(j+1)%12;faces.append((a,e,e+12,a+12))
faces+=[tuple(reversed(range(12))),tuple(range((len(profiles)-1)*12,len(profiles)*12))]
body=surf('Curved SUV shell',paint,verts,faces,True)
# Recalculate outward normals before boolean arch cuts.
import bmesh
bm=bmesh.new();bm.from_mesh(body.data);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(body.data);bm.free()
for z in [-1.48,1.45]:
 cutter=c('Arch cutter',rubber,0,.45,z,.515,2.8,n=32);bpy.context.view_layer.objects.active=body;mod=body.modifiers.new('Wheel opening','BOOLEAN');mod.object=cutter;mod.operation='DIFFERENCE';bpy.ops.object.modifier_apply(modifier=mod.name);bpy.data.objects.remove(cutter,do_unlink=True)
for side in [-1,1]:
 for z in [-1.48,1.45]:path('Wheel arch lip',rubber,[(side*1.005,.45+.523*math.sin(i*math.pi/20),z+.523*math.cos(i*math.pi/20)) for i in range(21)],.024)
# Roof curvature and pillars frame actual transparent window openings.
roof_verts=[]
for z,w,h in [(-1.78,.78,1.91),(-1.5,.87,2.02),(-.5,.88,2.055),(.42,.84,2.00),(.57,.77,1.91)]:
 for x,y in [(-w,h-.05),(-w*.92,h+.02),(0,h+.07),(w*.92,h+.02),(w,h-.05)]:roof_verts.append((x,y,z))
roof_faces=[]
for i in range(4):
 for j in range(4):a=i*5+j;roof_faces.append((a,a+1,a+6,a+5))
surf('Sculpted roof',paint,roof_verts,roof_faces,True)
for side in [-1,1]:
 for za,zb in [(-1.7,-1.52),(-.55,-.49),(.82,.46)]:path('Window pillar',paint,[(side*.96,1.14,za),(side*.84,1.94,zb)],.055)
 path('Roof rail',metal,[(side*.73,2.06,-1.45),(side*.73,2.13,-1.2),(side*.73,2.13,.15),(side*.73,2.06,.32)],.022)
 for points in [[(side*.957,1.22,-1.61),(side*.957,1.22,-.58),(side*.858,1.95,-.58),(side*.858,1.91,-1.51)],[(side*.957,1.22,-.44),(side*.957,1.22,.74),(side*.85,1.91,.43),(side*.858,1.96,-.44)]]:surf('Side window',glass,points,[(0,1,2,3)])
 for z in [-1.68,-.51,.80]:path('Door seam',rubber,[(side*1.014,.64,z),(side*1.014,1.15,z)],.006)
 path('Running board',rubber,[(side*1.08,.47,-.92),(side*1.08,.47,.92)],.07)
 b('Door handle',metal,side*1.017,1.15,-.86,.035,.055,.21,.012);b('Door handle',metal,side*1.017,1.15,.31,.035,.055,.21,.012)
 mirror=b('Mirror housing',paint,side*1.13,1.42,.62,.23,.17,.3,.045);b('Mirror glass',metal,side*1.14,1.43,.46,.18,.12,.012,.014)
 # Swept gold side stripe and wide door lettering.
 surf('PRF side stripe',gold,[(side*1.016,.86,-2.03),(side*1.016,.86,1.97),(side*1.006,1.04,1.85),(side*1.016,1.03,.78),(side*1.016,.95,.3),(side*1.016,1.03,-2.03)],[(0,1,2,3,4,5)])
 # Text local normal points outward along X after these rotations.
 label('PRF',gold,(side*1.026,1.12,-.32),.22,(math.pi/2,0,side*math.pi/2),'PRF side identification')
 for z in [1.48,-1.48]:wheel(('F' if z>0 else 'R')+('L' if side<0 else 'R'),side*1.0,.445,z,.425,.235,metal,rubber)
# Front and rear glazing.
surf('Windshield',glass,[(-.85,1.94,.46),(.85,1.94,.46),(.93,1.19,.88),(-.93,1.19,.88)],[(0,1,2,3)])
surf('Rear glass',glass,[(-.77,1.89,-1.74),(.77,1.89,-1.74),(.92,1.22,-1.91),(-.92,1.22,-1.91)],[(3,2,1,0)])
b('Rear liftgate',paint,0,1.04,-2.13,1.7,.3,.08,.03)
for side in [-1,1]:
 for z in [-.8,.12]:
  b('Seat cushion',interior,side*.45,.92,z,.55,.15,.56,.07);seat=b('Seat back',interior,side*.45,1.23,z-.26,.53,.65,.17,.07);seat.rotation_euler.x=-.12;b('Headrest',interior,side*.45,1.6,z-.29,.31,.24,.14,.045)
b('Dashboard',interior,0,1.15,.69,1.66,.28,.38,.05)
path('Steering wheel',rubber,[(-.46+.18*math.cos(i*math.tau/24),1.28+.18*math.sin(i*math.tau/24),.47) for i in range(25)],.022)
b('Grille recess',rubber,0,.91,2.244,1.35,.25,.025,.02)
for x in [i*.105 for i in range(-6,7)]:b('Grille slat',metal,x,.91,2.265,.027,.22,.035,.004)
for y in [.63,1.03]:path('Push bar',metal,[(-.68,y,2.33),(-.56,y,2.42),(.56,y,2.42),(.68,y,2.33)],.032)
for side in [-1,1]:
 path('Push bar upright',metal,[(side*.53,.57,2.38),(side*.53,1.1,2.38)],.028)
 b('Headlight',white,side*.72,1.0,2.19,.37,.17,.06,.035);b('Fog lamp',white,side*.77,.62,2.255,.16,.1,.04,.028)
 b('Tail light',red,side*.82,1.05,-2.20,.18,.37,.04,.025)
 b('Roof lightbar mount',rubber,0,2.14,-.05,1.22,.08,.28,.035)
 b('Roof lightbar lens',glass,side*.31,2.225,-.05,.57,.12,.27,.025)
 for i in range(3):
  flash=b('FlashRed' if side<0 else 'FlashBlue',red if side<0 else blue,side*(.1+i*.17),2.225,-.05,.12,.085,.22,.012)
  flash['part']='warning-light'
path('Radio antenna',rubber,[(.65,2.05,-1.1),(.65,2.61,-1.15)],.008)
label('POLICIA RODOVIARIA FEDERAL',gold,(0,1.08,-2.185),.095,(math.pi/2,0,math.pi),'Rear identification')
label('PRF',gold,(0,1.2,1.65),.26,(0,0,math.pi),'Bonnet identification')
export('prf-suv.glb')

reset();paint,gold,metal,rubber,interior,glass,white,red,blue=palette()
# Touring bike: exposed boxer engine, long suspension, panniers, spokes and screen.
wheel('R',0,.38,-.86,.38,.15,metal,rubber,16);wheel('F',0,.39,.94,.39,.14,metal,rubber,16)
for side in [-1,1]:
 path('Frame',rubber,[(side*.15,.5,-.6),(side*.18,.94,-.15),(side*.13,.95,.44),(side*.17,.48,.25),(side*.15,.5,-.6)],.035)
 path('Rear swingarm',metal,[(side*.16,.56,-.05),(side*.14,.4,-.86)],.045)
 path('Front fork',metal,[(side*.1,.41,.94),(side*.14,1.35,.56)],.038)
 c('Boxer cylinder',metal,side*.25,.64,.05,.13,.30,(1,0,0),16)
 for x in [side*(.19+i*.036) for i in range(5)]:c('Cooling fin',rubber,x,.64,.05,.14,.014,(1,0,0),16)
 path('Crash bar',metal,[(side*.25,.4,-.1),(side*.45,.53,-.05),(side*.45,.91,.35),(side*.25,.98,.44)],.022)
 path('Exhaust header',metal,[(side*.22,.58,.1),(side*.27,.37,.28),(side*.31,.34,-.56)],.028)
 b('Pannier',paint,side*.45,.89,-.73,.36,.47,.55,.045);b('Pannier trim',metal,side*.45,1.14,-.73,.37,.04,.56,.012)
 b('Pannier gold',gold,side*.638,.96,-.73,.012,.09,.47,.005)
 path('Handlebar',metal,[(side*.04,1.28,.53),(side*.24,1.39,.53),(side*.37,1.38,.57)],.02)
 b('Hand grip',rubber,side*.39,1.38,.57,.15,.045,.045,.012)
 path('Mirror stem',metal,[(side*.29,1.4,.58),(side*.39,1.62,.58)],.012);b('Mirror',rubber,side*.4,1.66,.58,.18,.12,.05,.035)
 b('Footpeg',metal,side*.27,.58,-.1,.19,.04,.09,.008)
 label('PRF',gold,(side*.27,1.08,.21),.12,(math.pi/2,0,side*math.pi/2),'Bike identification')
 flash=b('FlashRed' if side<0 else 'FlashBlue',red if side<0 else blue,side*.25,1.23,.87,.11,.08,.06,.015);flash['part']='warning-light'
# Rounded tank and sculpted stepped saddle.
sphere('Fuel tank',p(0,1.05,.16),(.27,.39,.25),paint,24,12)
sphere('Saddle',p(0,1.015,-.43),(.23,.47,.10),rubber,20,10)
b('Tail frame',rubber,0,.96,-.87,.38,.12,.27,.04)
b('Top case',paint,0,1.20,-1.02,.48,.35,.40,.04);b('Top case latch',metal,0,1.2,-1.235,.1,.055,.015,.005)
b('Engine block',metal,0,.64,.03,.3,.3,.37,.045)
c('Muffler',metal,.24,.65,-.72,.08,.53,(0,0,1),16)
surf('Front beak',paint,[(-.24,1.0,.61),(.24,1.0,.61),(.16,.96,1.28),(-.16,.96,1.28)],[(0,1,2,3)])
b('Headlamp fairing',paint,0,1.22,.75,.53,.32,.27,.06)
b('LED headlight',white,0,1.24,.9,.34,.17,.025,.04)
surf('Windshield',glass,[(-.26,1.33,.82),(.26,1.33,.82),(.22,1.81,.68),(-.22,1.81,.68)],[(0,1,2,3)])
label('191',gold,(0,1.1,-1.245),.09,(math.pi/2,0,math.pi),'Bike emergency marking')
export('prf-motorcycle.glb')
(OUT/'fleet-manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
