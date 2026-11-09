import numpy as np

def recolor(image,body,material_name):
 size=image.size[0];grid=np.array(image.pixels[:],dtype=np.float32).reshape((size,size,4));original=grid.copy();tags=np.zeros((size,size),dtype=np.uint8)
 uv=body.data.uv_layers.active.data
 for poly in body.data.polygons:
  if body.data.materials[poly.material_index].name!=material_name:continue
  vertices=[body.data.vertices[i] for i in poly.vertices];position=sum((body.matrix_world@v.co for v in vertices),start=body.matrix_world.translation*0)/len(vertices)
  weights={}
  for v in vertices:
   for g in v.groups:
    name=body.vertex_groups[g.group].name;weights[name]=weights.get(name,0)+g.weight
  group=max(weights,key=weights.get) if weights else ''
  tag=1
  if 'head' in material_name:tag=4 if position.z>1.76 else 0
  elif 'Hand' in group or 'Finger' in group:tag=0
  elif 'Thigh' in group or 'Calf' in group or ('Pelvis' in group and position.z<.96):tag=2
  elif 'Foot' in group or 'Toe' in group:tag=3
  loops=list(poly.loop_indices)
  for i in range(1,len(loops)-1):
   triangle=np.array([uv[loops[j]].uv[:] for j in [0,i,i+1]])*size
   low=np.maximum(0,np.floor(triangle.min(axis=0)).astype(int));high=np.minimum(size-1,np.ceil(triangle.max(axis=0)).astype(int))
   if np.any(high<low):continue
   xx,yy=np.meshgrid(np.arange(low[0],high[0]+1)+.5,np.arange(low[1],high[1]+1)+.5)
   a,b,c=triangle;den=(b[1]-c[1])*(a[0]-c[0])+(c[0]-b[0])*(a[1]-c[1])
   if abs(den)<1e-8:continue
   u=((b[1]-c[1])*(xx-c[0])+(c[0]-b[0])*(yy-c[1]))/den;v=((c[1]-a[1])*(xx-c[0])+(a[0]-c[0])*(yy-c[1]))/den;inside=(u>=-.025)&(v>=-.025)&(u+v<=1.025)
   target=tags[low[1]:high[1]+1,low[0]:high[0]+1];target[inside]=tag
 # Dilate masks into UV island padding to avoid blue/khaki seams under mipmapping.
 for _ in range(3):
  for tag in [1,2,3,4]:
   mask=tags==tag;expanded=mask|np.roll(mask,1,0)|np.roll(mask,-1,0)|np.roll(mask,1,1)|np.roll(mask,-1,1);tags[(tags==0)&expanded]=tag
 rgb=original[:,:,:3];luma=rgb.mean(axis=2)
 grid[tags==1,:3]=np.stack([luma*.50,luma*.70,luma*1.02],axis=2)[tags==1]
 grid[tags==2,:3]=np.stack([luma*2.0,luma*1.8,luma*1.22],axis=2)[tags==2]
 grid[tags==3,:3]=rgb[tags==3]*.6
 grid[tags==4,:3]=np.stack([luma*.45,luma*.63,luma*.95],axis=2)[tags==4]
 grid[:,:,:3]=np.clip(grid[:,:,:3],0,1);image.pixels[:]=grid.ravel()
