"""Small deterministic mesh helpers for original game props (Blender, no runtime dependency)."""
import bpy, math
from mathutils import Vector, Matrix

def material(name,color,metal=0,rough=.6,alpha=1):
 m=bpy.data.materials.get(name) or bpy.data.materials.new(name);m.use_nodes=True;p=m.node_tree.nodes.get('Principled BSDF');p.inputs['Base Color'].default_value=(*color,alpha);p.inputs['Metallic'].default_value=metal;p.inputs['Roughness'].default_value=rough
 if alpha<1:p.inputs['Alpha'].default_value=alpha;m.surface_render_method='DITHERED'
 return m

def box(name,loc,scale,mat,bevel=.015):
 bpy.ops.mesh.primitive_cube_add(size=1,location=loc);o=bpy.context.object;o.name=name;o.scale=scale;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);o.data.materials.append(mat)
 if bevel:
  mod=o.modifiers.new('Manufactured edges','BEVEL');mod.width=bevel;mod.segments=2;bpy.ops.object.modifier_apply(modifier=mod.name)
 return o

def cylinder(name,loc,radius,depth,mat,axis=(0,0,1),vertices=16):
 bpy.ops.mesh.primitive_cylinder_add(vertices=vertices,radius=radius,depth=depth,location=loc);o=bpy.context.object;o.name=name;o.rotation_mode='QUATERNION';o.rotation_quaternion=Vector((0,0,1)).rotation_difference(Vector(axis));o.data.materials.append(mat)
 for p in o.data.polygons:p.use_smooth=len(p.vertices)==4
 return o

def sphere(name,loc,scale,mat,segments=16,rings=10):
 bpy.ops.mesh.primitive_uv_sphere_add(segments=segments,ring_count=rings,radius=1,location=loc);o=bpy.context.object;o.name=name;o.scale=scale;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);o.data.materials.append(mat)
 for p in o.data.polygons:p.use_smooth=True
 return o

def tube(name,points,radius,mat):
 curve=bpy.data.curves.new(name,'CURVE');curve.dimensions='3D';curve.bevel_depth=radius;curve.bevel_resolution=1;curve.resolution_u=1;s=curve.splines.new('POLY');s.points.add(len(points)-1)
 for p,co in zip(s.points,points):p.co=(*co,1)
 ob=bpy.data.objects.new(name,curve);bpy.context.collection.objects.link(ob);ob.data.materials.append(mat)
 for o in bpy.context.selected_objects:o.select_set(False)
 ob.select_set(True);bpy.context.view_layer.objects.active=ob;bpy.ops.object.convert(target='MESH');return bpy.context.object

def mesh(name,vertices,faces,mat,smooth=False):
 data=bpy.data.meshes.new(name);data.from_pydata(vertices,[],faces);data.update();o=bpy.data.objects.new(name,data);bpy.context.collection.objects.link(o);data.materials.append(mat)
 if smooth:
  for p in data.polygons:p.use_smooth=True
 return o

def skin_rigid(ob,rig,bone,transform=None):
 world=ob.matrix_world.copy()
 if transform is not None:world=transform@world
 for v in ob.data.vertices:v.co=world@v.co
 ob.parent=rig;ob.matrix_parent_inverse=rig.matrix_world.inverted();ob.matrix_basis=Matrix.Identity(4)
 group=ob.vertex_groups.new(name=bone);group.add(list(range(len(ob.data.vertices))),1,'REPLACE');mod=ob.modifiers.new('Rigid bone binding','ARMATURE');mod.object=rig
 return ob

def join_by_material(objects,prefix):
 groups={}
 for ob in objects:
  if ob.type!='MESH':continue
  key=ob.data.materials[0].name;groups.setdefault(key,[]).append(ob)
 result=[]
 for key,items in groups.items():
  bpy.ops.object.select_all(action='DESELECT')
  for ob in items:ob.select_set(True)
  bpy.context.view_layer.objects.active=items[0];bpy.ops.object.join();o=bpy.context.object;o.name=prefix+'_'+key;result.append(o)
 return result

def rifle_parts():
 """Original fictional rifle prop. Only visual geometry; no shooting simulation."""
 black=material('Rifle polymer',(.027,.034,.038),.15,.62);steel=material('Rifle steel',(.075,.085,.09),.8,.3);rubber=material('Rifle grip',(.018,.022,.023),0,.9)
 items=[]
 def b(name,loc,scale,mat=black,bev=.008):o=box('Rifle '+name,loc,scale,mat,bev);items.append(o);return o
 def c(name,loc,radius,depth,mat=steel,axis=(0,1,0)):o=cylinder('Rifle '+name,loc,radius,depth,mat,axis,12);items.append(o);return o
 b('receiver',(0,0,0),(.072,.31,.095));b('upper',(0,-.025,.068),(.068,.35,.045),steel)
 b('handguard',(0,-.285,.045),(.075,.25,.068));c('barrel',(0,-.49,.048),.014,.23);c('muzzle',(0,-.615,.048),.021,.035)
 c('stock tube',(0,.215,.037),.021,.16);b('stock',(0,.31,.012),(.055,.16,.13));b('buttpad',(0,.39,.01),(.065,.018,.15),rubber)
 grip=b('pistol grip',(0,.085,-.083),(.052,.065,.12),rubber);grip.rotation_euler.x=-.18
 mag=b('magazine',(0,-.055,-.11),(.048,.08,.15),steel);mag.rotation_euler.x=-.12
 for side in [-1,1]:
  b('side rail',(side*.044,-.285,.048),(.014,.21,.018),steel)
  for y in [-.35,-.30,-.25,-.2]:b('vent',(side*.04,y,.078),(.004,.022,.012),rubber,0)
 for i in range(15):b('top rail',(0,-.36+i*.033,.098),(.067,.012,.012),steel,0)
 c('optic',(0,.0,.14),.025,.08,black);b('sight mount',(0,0,.108),(.055,.055,.024),steel)
 b('front sight',(0,-.4,.12),(.02,.02,.06),steel);b('rear sight',(0,.12,.13),(.032,.02,.06),steel)
 items.append(tube('Rifle trigger guard',[(-.025,.04,-.055),(-.025,.01,-.095),(-.025,-.015,-.095),(-.025,-.02,-.04)],.004,steel))
 return items
