"""Blender 4.3+: convert the MIT Rocketbox Military_Male_01 + motions to a local game GLB.
Usage: blender -b --python scripts/build-prf-agent.py -- /path/Microsoft-Rocketbox
Source FBX/TGA files stay outside the game's runtime checkout. No downloads in this script.
"""
import bpy, bmesh, sys, math, json, hashlib
from pathlib import Path
from mathutils import Vector, Matrix
sys.path.insert(0,str(Path(__file__).resolve().parent))
from model_shapes import material,box,sphere,mesh,skin_rigid,join_by_material,rifle_parts
from rig_pose import carry_arms
from officer_textures import recolor
ROOT=Path(__file__).resolve().parents[1]
SOURCE=Path(next(value for value in sys.argv[sys.argv.index('--')+1:] if not value.startswith('--')))
OFFICER='--officer' in sys.argv
MODEL='Police_Male_01' if OFFICER else 'Military_Male_01'
FILENAME='prf-officer.glb' if OFFICER else 'prf-agent.glb'
OUT=ROOT/'assets/models'; OUT.mkdir(parents=True,exist_ok=True)
WORK=Path('/tmp/prf-agent-build');WORK.mkdir(exist_ok=True)
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
bpy.context.scene.render.fps=30
asset=SOURCE/'Assets/Avatars/Professions'/MODEL
bpy.ops.import_scene.fbx(filepath=str(asset/'Export'/(MODEL+'.fbx')),use_anim=False)
rig=next(o for o in bpy.data.objects if o.type=='ARMATURE')
body=next(o for o in bpy.data.objects if o.type=='MESH')
rig.animation_data_clear();rig.name='PRF_Officer_Rig' if OFFICER else 'PRF_Commander_Rig';body.name='PRF_Officer' if OFFICER else 'PRF_Commander'
# Remove knife geometry; keep the rest of the uniform and equipment.
bm=bmesh.new();bm.from_mesh(body.data)
bmesh.ops.delete(bm,geom=[f for f in bm.faces if any(word in body.data.materials[f.material_index].name for word in ['knife','pistol'])],context='FACES');bm.to_mesh(body.data);bm.free()
# Preserve the face/hands; a modest collapse on the complete mesh limits skinning cost.
bpy.context.view_layer.objects.active=body
body.select_set(True)
mod=body.modifiers.new('Mobile mesh budget','DECIMATE');mod.ratio=.63 if OFFICER else .68
bpy.ops.object.modifier_apply(modifier=mod.name)
# Rebuild materials as metallic/roughness PBR with embedded, resized maps.
import numpy as np
for mat in body.data.materials:
 if any(word in mat.name for word in ['knife','pistol']):continue
 stem=mat.name
 nodes=mat.node_tree.nodes;nodes.clear();links=mat.node_tree.links
 output=nodes.new('ShaderNodeOutputMaterial');p=nodes.new('ShaderNodeBsdfPrincipled');links.new(p.outputs['BSDF'],output.inputs['Surface'])
 p.inputs['Metallic'].default_value=.02;p.inputs['Roughness'].default_value=.82 if 'head' not in stem else .62
 for kind in ['color','normal']:
  files=list((asset/'Textures').glob(stem+'_'+kind+'*.tga'))
  if not files:continue
  image=bpy.data.images.load(str(files[0]),check_existing=False)
  size=(1024 if 'body' in stem else 512) if kind=='color' else (256 if OFFICER else 512)
  image.scale(size,size)
  if OFFICER and kind=='color' and ('body' in stem or 'head' in stem):recolor(image,body,stem)
  if not OFFICER and kind=='color' and 'head' not in stem:
   pixels=np.array(image.pixels[:],dtype=np.float32).reshape((-1,4))
   pixels[:,:3]*=np.array([1.05,1.03,.76]);pixels[:,:3]=np.clip(pixels[:,:3],0,1)
   if stem=='sm002_body':
    # Replace the source US-unit patches with subdued fictional PRF name tapes.
    grid=pixels.reshape((size,size,4))
    def tape(x0,y0,x1,y1):
     x0,y0,x1,y1=[round(v*size) for v in [x0,y0,x1,y1]]
     grid[size-y1:size-y0,x0:x1,:3]=[.22,.25,.16]
     glyphs={'P':['11110','10001','10001','11110','10000','10000','10000'],'R':['11110','10001','10001','11110','10100','10010','10001'],'F':['11111','10000','10000','11110','10000','10000','10000']}
     factor=max(1,(x1-x0-6)//18);left=x0+(x1-x0-17*factor)//2;top=y0+(y1-y0-7*factor)//2
     for i,letter in enumerate('PRF'):
      for y,row in enumerate(glyphs[letter]):
       for x,on in enumerate(row):
        if on=='1':
         gx=left+(i*6+x)*factor;gy=top+y*factor;grid[size-gy-factor:size-gy,gx:gx+factor,:3]=[.82,.72,.37]
    tape(.149,.530,.204,.622);tape(.802,.532,.864,.624)
    tape(.474,.358,.528,.374)
   image.pixels[:]=pixels.ravel()
  image.filepath_raw=str(WORK/(stem+'_'+kind+('.jpg' if kind=='color' else '.png')))
  image.file_format='JPEG' if kind=='color' else 'PNG';image.save()
  texture=nodes.new('ShaderNodeTexImage');texture.image=image
  if kind=='color':links.new(texture.outputs['Color'],p.inputs['Base Color'])
  else:
   image.colorspace_settings.name='Non-Color';normal=nodes.new('ShaderNodeNormalMap');normal.inputs['Strength'].default_value=.7
   links.new(texture.outputs['Color'],normal.inputs['Color']);links.new(normal.outputs['Normal'],p.inputs['Normal'])
# Rooted, in-place retargeting. Copy world rotations into the target bind axes,
# preserve its limb lengths, and retain only vertical pelvis bob, never locomotion.
rest={b.name:b.matrix_local.copy() for b in rig.data.bones}
body_bones=[b.name for b in rig.data.bones if b.name in ['Bip01 Pelvis','Bip01 Spine','Bip01 Spine1','Bip01 Spine2','Bip01 Neck','Bip01 Head'] or any(w in b.name for w in ['Clavicle','UpperArm','Forearm','Hand','Finger','Thigh','Calf','Foot','Toe'])]
clips=[('Idle','static/m_idle_breathe_01.max.fbx',120),('Walk','xy/m_walk_neutral.max.fbx',999),('Run','xy/m_run_neutral.max.fbx',999),('Documents','static/m_documents_check.max.fbx',150),('Seated','static/m_sit_table_idle_neutral_01.max.fbx',120),('Signal','static/m_gestic_presentation_left_01.max.fbx',90)]
if OFFICER:
 clips += [('Riding','static/m_sit_table_idle_neutral_01.max.fbx',60),('Radio','static/m_idle_breathe_01.max.fbx',90)]
else:
 clips += [('RifleIdle','static/m_idle_breathe_01.max.fbx',120),('RifleWalk','xy/m_walk_neutral.max.fbx',999),('RifleRun','xy/m_run_neutral.max.fbx',999)]
clip_stats=[]
carry_reference={}

for name,path,limit in clips:
 before=set(bpy.data.objects)
 bpy.ops.import_scene.fbx(filepath=str(SOURCE/'Assets/Animations'/('all_animations_max_motextr_'+path)))
 imported=set(bpy.data.objects)-before
 src=next(o for o in imported if o.type=='ARMATURE')
 source_action=src.animation_data.action
 start,end=[int(x) for x in source_action.frame_range];end=min(end,start+limit-1)
 bpy.context.scene.frame_set(start);bpy.context.view_layer.update()
 origin_z=(src.matrix_world@src.pose.bones['Bip01 Pelvis'].matrix).translation.z
 action=bpy.data.actions.new(name);rig.animation_data_create();rig.animation_data.action=action
 for frame in range(start,end+1):
  bpy.context.scene.frame_set(frame);bpy.context.view_layer.update()
  source_root=(src.matrix_world@src.pose.bones['Bip01 Pelvis'].matrix).translation
  desired={}
  for bone in rig.data.bones:
   pb=rig.pose.bones[bone.name];local=rest[bone.name] if not bone.parent else rest[bone.parent.name].inverted()@rest[bone.name]
   parent=desired[bone.parent.name] if bone.parent else Matrix.Identity(4)
   if bone.name in body_bones and bone.name in src.pose.bones:
    q=(rig.matrix_world.inverted()@src.matrix_world@src.pose.bones[bone.name].matrix).to_quaternion()
    position=parent@local.translation
    if not bone.parent:
     # Keep the floor anchoring of the avatar, allowing only small breathing/gait bob.
     dz=source_root.z-(rig.matrix_world.translation.z if name in ['Seated','Riding'] else origin_z)
     position+=rig.matrix_world.inverted().to_3x3()@Vector((0,0,dz))
    pose=Matrix.Translation(position)@q.to_matrix().to_4x4()
    basis=local.inverted()@parent.inverted()@pose
    pb.rotation_mode='QUATERNION';pb.rotation_quaternion=basis.to_quaternion();pb.location=basis.translation if not bone.parent else (0,0,0);pb.scale=(1,1,1)
    pb.keyframe_insert(data_path='rotation_quaternion',frame=frame-start+1,group=bone.name)
    if not bone.parent:pb.keyframe_insert(data_path='location',frame=frame-start+1,group=bone.name)
    desired[bone.name]=pose
   else:
    pb.matrix_basis=Matrix.Identity(4);desired[bone.name]=parent@local
  if name.startswith('Rifle') or name in ['Riding','Radio']:
   carry_arms(rig,rest,desired,name,frame-start+1)
   if frame==start:
    bpy.context.view_layer.update();carry_reference[name]=rig.matrix_world@rig.pose.bones['Bip01 R Hand'].matrix
 for f in action.fcurves:
  for k in f.keyframe_points:k.interpolation='LINEAR'
 action.use_fake_user=True
 clip_stats.append({'name':name,'seconds':(end-start)/30,'frames':end-start+1})
 rig.animation_data.action=None
 for o in imported:bpy.data.objects.remove(o,do_unlink=True)
 # Source FBX action datablocks are not exported.
 if source_action.users==0:bpy.data.actions.remove(source_action)
# Only target armature actions go through NLA. No imported source rigs/extras.
rig.animation_data_clear();rig.animation_data_create()
for clip in clip_stats:
 track=rig.animation_data.nla_tracks.new();track.name=clip['name'];action=bpy.data.actions[clip['name']]
 track.strips.new(clip['name'],1,action);track.mute=True
# Reset bind pose for deterministic export; the runtime immediately starts Idle.
for pb in rig.pose.bones:pb.matrix_basis=Matrix.Identity(4)
bpy.context.scene.frame_set(1)
# Add tactical PRF/command name tapes, parented to the chest bone for animation.
# Plates use geometry + solid material; text is mesh, avoiding extra texture fetches.
def patch(text,back=False):
 for selected in bpy.context.selected_objects:selected.select_set(False)
 curve=bpy.data.curves.new('Command name tape','FONT');curve.body=text;curve.align_x='CENTER';curve.align_y='CENTER';curve.size=.085 if OFFICER and back else .042;curve.extrude=.0005
 ob=bpy.data.objects.new('PRF identification',curve);bpy.context.collection.objects.link(ob)
 ob.location=(0,(.15 if back else -.205) if OFFICER else (.27 if back else -.29),1.46);ob.rotation_euler=(math.pi/2 if not back else math.pi/2,0,math.pi if back else 0)
 mat=bpy.data.materials.get('Name tape') or bpy.data.materials.new('Name tape');mat.diffuse_color=(.84,.77,.42,1);ob.data.materials.append(mat)
 bpy.context.view_layer.objects.active=ob;ob.select_set(True);bpy.ops.object.convert(target='MESH');ob=bpy.context.object
 # Rigid skin weights avoid bone-parent tail offsets in glTF animation.
 world=ob.matrix_world.copy()
 for v in ob.data.vertices:v.co=world@v.co
 ob.parent=rig;ob.matrix_parent_inverse=rig.matrix_world.inverted();ob.matrix_basis=Matrix.Identity(4)
 group=ob.vertex_groups.new(name='Bip01 Spine2');group.add(list(range(len(ob.data.vertices))),1,'REPLACE')
 modifier=ob.modifiers.new('Chest binding','ARMATURE');modifier.object=rig
 # Cloth backing keeps lettering readable over the camouflage.
 y=((.149 if back else -.204) if OFFICER else (.269 if back else -.289));w=.4 if back else .14;h=.065;z=1.46
 mesh=bpy.data.meshes.new('Name tape backing');verts=[(-w/2,y,z-h/2),(w/2,y,z-h/2),(w/2,y,z+h/2),(-w/2,y,z+h/2)]
 mesh.from_pydata(verts,[],[(3,2,1,0) if back else (0,1,2,3)]);mesh.update()
 backing=bpy.data.objects.new('Name tape backing',mesh);bpy.context.collection.objects.link(backing)
 material=bpy.data.materials.get('Tape cloth') or bpy.data.materials.new('Tape cloth');material.diffuse_color=(.09,.13,.075,1);mesh.materials.append(material)
 backing.parent=rig;backing.matrix_parent_inverse=rig.matrix_world.inverted();backing.matrix_basis=Matrix.Identity(4)
 group=backing.vertex_groups.new(name='Bip01 Spine2');group.add(list(range(4)),1,'REPLACE')
 modifier=backing.modifiers.new('Chest binding','ARMATURE');modifier.object=rig
 return ob
# Patch mesh is attached after retarget bake so it follows all clips.
patch('PRF' if OFFICER else 'COMANDO GERAL',True);patch('PRF',False)
if OFFICER:
 reflective=material('Reflective yellow',(.64,.72,.06),.1,.6);silver=material('Reflective tape',(.68,.73,.67),.25,.4)
 for side in [-1,1]:
  for x in [-.13,.13]:
   obj=box('SafetyVest strap',(x,side*.19,1.32),(.075,.018,.5),reflective,.008);skin_rigid(obj,rig,'Bip01 Spine2')
  for z in [1.19,1.43]:
   obj=box('SafetyVest tape',(0,side*.205,z),(.38,.012,.035),silver,.004);skin_rigid(obj,rig,'Bip01 Spine2')
 white=material('Moto helmet',(.8,.82,.77),.15,.3);navy=material('Helmet trim',(.025,.05,.09),.05,.4)
 # Open-face helmet shell leaves the model's eyes unobstructed.
 verts=[];faces=[];rows=9;cols=20
 for row in range(rows+1):
  theta=.02+row/rows*2.25
  for col in range(cols+1):
   phi=col/cols*math.tau;verts.append((.165*math.sin(theta)*math.cos(phi),-.01+.18*math.sin(theta)*math.sin(phi),1.72+.205*math.cos(theta)))
 for row in range(rows):
  for col in range(cols):
   phi=(col+.5)/cols*math.tau
   if row>3 and math.sin(phi)<-.55:continue
   a=row*(cols+1)+col;faces.append((a,a+1,a+cols+2,a+cols+1))
 skin_rigid(mesh('MotoHelmet shell',verts,faces,white,True),rig,'Bip01 Head')
 for side in [-1,1]:skin_rigid(box('MotoHelmet strap',(side*.135,-.01,1.59),(.018,.13,.12),navy,.01),rig,'Bip01 Head')
 skin_rigid(box('MotoHelmet chin',(0,-.125,1.54),(.22,.08,.045),white,.02),rig,'Bip01 Head')
 skin_rigid(box('MotoHelmet peak',(0,-.17,1.82),(.31,.12,.02),navy,.008),rig,'Bip01 Head')
 radio=box('HandRadio',(0,0,0),(.045,.035,.10),navy,.006)
 transform=rig.matrix_world@rest['Bip01 R Hand']@carry_reference['Radio'].inverted()@Matrix.Translation(Vector((-.16,-.09,1.55)))
 skin_rigid(radio,rig,'Bip01 R Hand',transform)
else:
 # The held version binds in its authored carry pose; the slung version follows the chest.
 desired=Matrix.Translation(Vector((-.12,-.33,1.29)))@Matrix.Rotation(.65,4,'Z')
 transform=rig.matrix_world@rest['Bip01 R Hand']@carry_reference['RifleIdle'].inverted()@desired
 for obj in join_by_material(rifle_parts(),'HeldRifle'):skin_rigid(obj,rig,'Bip01 R Hand',transform)
 transform=Matrix.Translation(Vector((0,.29,1.12)))@Matrix.Rotation(.25,4,'Y')@Matrix.Rotation(-math.pi/2,4,'X')
 for obj in join_by_material(rifle_parts(),'SlungRifle'):skin_rigid(obj,rig,'Bip01 Spine2',transform)

if OFFICER:
 for prefix in ['SafetyVest','MotoHelmet']:
  join_by_material([o for o in bpy.data.objects if o.type=='MESH' and o.name.startswith(prefix)],prefix)
for o in bpy.context.selected_objects:o.select_set(False)
rig.select_set(True);body.select_set(True)
for o in rig.children_recursive:
 if o.type=='MESH':o.select_set(True)
# NLA tracks must be unmuted for the exporter to discover them.
for t in rig.animation_data.nla_tracks:t.mute=False
bpy.ops.export_scene.gltf(filepath=str(OUT/FILENAME),export_format='GLB',use_selection=True,export_animations=True,export_animation_mode='NLA_TRACKS',export_nla_strips=True,export_skins=True,export_morph=False,export_yup=True,export_force_sampling=True,export_frame_step=2,export_image_format='AUTO',export_keep_originals=False)
binary=(OUT/FILENAME).read_bytes()
manifest={'source':'Microsoft Rocketbox '+MODEL,'source_repository':'https://github.com/microsoft/Microsoft-Rocketbox','source_commit':'0943055db6ec570bcef9f2c8b41c9e5467c808f9','license':'MIT','file':FILENAME,'sha256':hashlib.sha256(binary).hexdigest(),'bytes':len(binary),'body_triangles':sum(len(p.vertices)-2 for p in body.data.polygons),'triangles':sum(len(p.vertices)-2 for o in bpy.data.objects if o.type=='MESH' for p in o.data.polygons),'bones':len(rig.data.bones),'animations':clip_stats,'modifications':[('Body reduced to 63%; foreign patches recoloured; source pistol removed' if OFFICER else 'Body reduced to 68%; source knife removed; original rifle added'),('PBR materials; embedded 1024/512 colour maps and 256 normal maps' if OFFICER else 'PBR metallic/roughness materials, 512/1024 embedded colour and normal maps'),('Navy shirt and khaki trousers; PRF markings; optional safety vest, motorcycle helmet and radio' if OFFICER else 'Olive/tan colour adaptation; source US-unit markings replaced; PRF/Comando Geral name tapes'),'Retargeted body animation; preserved limb lengths; removed horizontal root motion']}
(OUT/('officer-manifest.json' if OFFICER else 'manifest.json')).write_text(json.dumps(manifest,indent=2)+'\n')
print('PRF_BUILD',json.dumps(manifest))
