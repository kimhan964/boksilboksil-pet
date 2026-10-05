"""Bake whole-image RIFE inbetweens. Never split anatomy or register airborne feet."""
import argparse, hashlib, json, shutil, subprocess
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw

ROOT=Path(__file__).resolve().parents[1]
WORK=ROOT/'design/rabbit-frame-pilot-v8'
RIFE=Path('C:/Users/rlagk/.cache/rabbit-animation-tools/rife-20221029')
P=argparse.ArgumentParser()
P.add_argument('--trial',action='store_true')
A=P.parse_args()
for folder in ['anchors','interpolated','packed-selected']: (WORK/folder).mkdir(parents=True,exist_ok=True)

def key_alpha(im):
    rgb=np.array(im.convert('RGB'),dtype=np.float32)
    r,g,b=rgb[:,:,0],rgb[:,:,1],rgb[:,:,2]
    alpha=np.clip(1-(np.minimum(g-r,b-r)-10)/220,0,1)
    alpha[(r<80)&(g>150)&(b>150)]=0
    alpha[alpha<.025]=0
    safe=np.maximum(alpha,.001)
    rgba=np.empty((*alpha.shape,4),dtype=np.uint8)
    rgba[:,:,0]=np.clip(r/safe,0,255)
    rgba[:,:,1]=np.clip((g-(1-alpha)*255)/safe,0,255)
    rgba[:,:,2]=np.clip((b-(1-alpha)*255)/safe,0,255)
    rgba[:,:,3]=np.rint(alpha*255).astype(np.uint8)
    rgba[alpha==0]=0
    return Image.fromarray(rgba)

keys=[]; records=[]
counts=[4,4,8,5,4,5,8,4,4,4,7,3]
assert sum(counts)==60
for i in range(12):
    source=ROOT/'design/rabbit-frame-pilot-v7/keys'/f'{i:02d}.png'
    cel=key_alpha(Image.open(source)); box=cel.getbbox()
    # Contact poses share a floor. Airborne poses retain the same camera origin:
    # tucking a paw must not drag the head/chest down to restore its old baseline.
    grounded=i in [0,1,2,8,9,10,11]
    dy=464-box[3] if grounded else min(-2,464-box[3])
    fixed=Image.new('RGBA',(512,512)); fixed.alpha_composite(cel,(0,dy))
    canvas=Image.new('RGB',(512,512),'cyan'); canvas.paste(fixed,(0,0),fixed)
    target=WORK/'anchors'/f'{i:02d}.png'; canvas.save(target)
    keys.append(target); records.append(dict(index=i,source=str(source.relative_to(ROOT)),grounded=grounded,whole_cel_translation=[0,dy]))
(WORK/'anchor-registration.json').write_text(json.dumps(records,indent=2),encoding='utf8')

intervals=[2,6] if A.trial else list(range(12))
def middle_path(i,j):
    return WORK/'interpolated'/f'key{i:02d}-{j:02d}-of-{counts[i]:02d}.png'
for i in intervals:
    for j in range(1,counts[i]):
        target=middle_path(i,j)
        if target.exists(): continue
        command=[str(RIFE/'rife-ncnn-vulkan.exe'),'-0',str(keys[i]),'-1',str(keys[(i+1)%12]),'-o',str(target),'-s',str(j/counts[i]),'-m',str(RIFE/'rife-v4.6'),'-g','0','-j','1:1:1','-z']
        result=subprocess.run(command,capture_output=True,text=True)
        if result.returncode: raise RuntimeError(result.stderr)
    print(f'interval {i+1}/12 complete',flush=True)
    strip=Image.new('RGB',(512*(counts[i]+1),512),'cyan')
    for j in range(counts[i]+1):
        source=keys[i] if j==0 else keys[(i+1)%12] if j==counts[i] else middle_path(i,j)
        strip.paste(Image.open(source).convert('RGB'),(j*512,0))
    strip.thumbnail((1536,512),Image.Resampling.LANCZOS)
    strip.save(WORK/f'interval-{i:02d}.png')
if A.trial: raise SystemExit(0)

atlas=Image.new('RGBA',(2048,2048)); frames=[]
sources=[]
for i in range(12):
    sources.append(keys[i]);sources.extend(middle_path(i,j) for j in range(1,counts[i]))
for n,source in enumerate(sources):
    cel=key_alpha(Image.open(source)).resize((237,237),Image.Resampling.LANCZOS)
    fixed=Image.new('RGBA',(256,256)); fixed.alpha_composite(cel,(9,17))
    fixed.save(WORK/'packed-selected'/f'{n:02d}.png')
    atlas.paste(fixed,(n%8*256,n//8*256)); frames.append(fixed)
atlas.save(WORK/'adult-walk.png'); frames[0].save(WORK/'adult-idle.png')
contact=Image.new('RGB',atlas.size,'#fff8ed');contact.paste(atlas,(0,0),atlas);contact.save(WORK/'contact-60.png')
manifest=json.loads((ROOT/'assets/rabbit-frame-pilot-v7/manifest.json').read_text(encoding='utf8'))
manifest.update(version=8,method='12 VARCO whole-body keys + 48 local RIFE-v4.6 whole-image inbetweens; fixed airborne camera; no anatomy rig or runtime crossfade')
manifest['stages']['adult']['launch_phase']=10/60
manifest['stages']['adult']['land_phase']=42/60
manifest['stages']['adult']['lift_canvas']=12
(WORK/'selected-frames.json').write_text(json.dumps(dict(interval_counts=counts,frames=[dict(index=n,source=str(p.relative_to(WORK))) for n,p in enumerate(sources)]),indent=2),encoding='utf8')
(WORK/'manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf8')
assert len({hashlib.sha256(im.tobytes()).hexdigest() for im in frames})==60
print('60 unique complete PNG cels baked; candidate remains in design folder',flush=True)
