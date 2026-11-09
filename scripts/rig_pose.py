"""Retarget pose helpers for visual two-hand carries and motorcycle controls."""
from mathutils import Vector, Matrix, Quaternion
import math

def carry_arms(rig,rest,desired,name,frame):
 world=rig.matrix_world;inverse=world.inverted();chest='Bip01 Spine2'
 chest_delta=world@desired[chest]@(world@rest[chest]).inverted()
 if name.startswith('Rifle'):
  targets={'R':((-.12,-.33,1.21),(-.50,-.12,1.03)),'L':((.03,-.53,1.265),(.5,-.20,1.03))}
 elif name=='Riding':targets={'R':((-.33,-.64,.83),(-.6,-.25,.73)),'L':((.33,-.64,.83),(.6,-.25,.73))}
 elif name=='Radio':targets={'R':((-.16,-.06,1.52),(-.50,-.08,1.18))}
 else:return
 changed=set()
 for side,(goal,pole) in targets.items():
  names=[f'Bip01 {side} UpperArm',f'Bip01 {side} Forearm',f'Bip01 {side} Hand']
  old=[world@desired[n] for n in names];p,e,h=[m.translation.copy() for m in old]
  # Riding already has a seated torso; keep targets in the seated world frame.
  target=Vector(goal) if name=='Riding' else chest_delta@Vector(goal)
  pole=Vector(pole) if name=='Riding' else chest_delta@Vector(pole)
  a=(e-p).length;b=(h-e).length;delta=target-p;d=max(.001,min(delta.length,a+b-.005));axis=delta.normalized();target=p+axis*d
  bend=pole-p-axis*((pole-p).dot(axis));bend.normalize()
  along=(a*a-b*b+d*d)/(2*d);height=max(0,a*a-along*along)**.5;elbow=p+axis*along+bend*height
  q1=(e-p).rotation_difference(elbow-p);q2=(h-e).rotation_difference(target-elbow)
  matrices=[Matrix.Translation(p)@(q1@old[0].to_quaternion()).to_matrix().to_4x4(),Matrix.Translation(elbow)@(q2@old[1].to_quaternion()).to_matrix().to_4x4(),Matrix.Translation(target)@(q2@old[2].to_quaternion()).to_matrix().to_4x4()]
  for n,matrix in zip(names,matrices):desired[n]=inverse@matrix;changed.add(n)
  # Preserve the original fingers relative to the changed wrist.
  for bone in rig.data.bones:
   if f'Bip01 {side} Finger' in bone.name:
    parent=bone.parent.name;desired[bone.name]=desired[parent]@rest[parent].inverted()@rest[bone.name];changed.add(bone.name)
 for bone in rig.data.bones:
  if bone.name not in changed:continue
  parent=desired[bone.parent.name] if bone.parent else Matrix.Identity(4);local=rest[bone.parent.name].inverted()@rest[bone.name] if bone.parent else rest[bone.name]
  basis=local.inverted()@parent.inverted()@desired[bone.name];pb=rig.pose.bones[bone.name];pb.rotation_mode='QUATERNION';pb.rotation_quaternion=basis.to_quaternion();pb.location=(0,0,0);pb.scale=(1,1,1)
  if 'Finger' in bone.name:
   side='R' if ' R ' in bone.name else 'L';digit=bone.name.split('Finger')[-1]
   if not digit.startswith('0'):
    across=rest[f'Bip01 {side} Finger1'].translation-rest[f'Bip01 {side} Finger4'].translation
    axis=rest[bone.name].to_quaternion().inverted()@across.normalized()
    degrees=32 if len(digit)==1 else 48 if len(digit)==2 else 28
    pb.rotation_quaternion=Quaternion(axis,math.radians(degrees)*(1 if side=='L' else -1))
  pb.keyframe_insert(data_path='rotation_quaternion',frame=frame,group=bone.name)
