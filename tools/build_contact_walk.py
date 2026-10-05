"""Prepare/inspect a full-cel gait; only accepted images may be installed."""
import argparse,json,hashlib,subprocess,shutil
from pathlib import Path
import numpy as np
from PIL import Image,ImageDraw
ROOT=Path(__file__).resolve().parents[1];WORK=ROOT/'design/walk-v6'
p=argparse.ArgumentParser();p.add_argument('--build',action='store_true');a=p.parse_args()
def matte(im):
    rgb=np.asarray(im.convert('RGB'),dtype=np.float32);r,g,b=rgb[:,:,0],rgb[:,:,1],rgb[:,:,2]
    alpha=np.ones(r.shape,dtype=np.float32);key=(g>=b-24)&(g>r+20)&(b>r+20)
    alpha[key]=1-np.clip((np.minimum(g-r,b-r)[key]-20)/50,0,1);alpha[alpha<.025]=0
    rgba=np.empty((*alpha.shape,4),dtype=np.uint8);safe=np.maximum(alpha,.001)
    rgba[:,:,0]=np.clip(r/safe,0,255);rgba[:,:,1]=np.clip((g-(1-alpha)*255)/safe,0,255);rgba[:,:,2]=np.clip((b-(1-alpha)*255)/safe,0,255);rgba[:,:,3]=np.rint(alpha*255);rgba[alpha==0]=0
    return Image.fromarray(rgba)
sheet=Image.open(WORK/'otter-finished-12.png');keys=[];boxes=[];face_x=[]
folder=WORK/'otter-adult';folder.mkdir(exist_ok=True)
for i in range(12):
    im=sheet.crop((i%4*384,i//4*384,(i%4+1)*384,(i//4+1)*384))
    if i==11 and (WORK/'otter-key11-fixed.png').exists(): im=Image.open(WORK/'otter-key11-fixed.png').resize((384,384),Image.Resampling.LANCZOS)
    cel=matte(im);keys.append(cel);boxes.append(cel.getbbox())
    rgb=np.asarray(cel);mask=(rgb[:,:,0]>215)&(rgb[:,:,1]>185)&(rgb[:,:,2]>140)&(rgb[:,:,3]>128);mask[195:]=False
    yy,xx=np.where(mask);face_x.append(float(xx.mean()))
factor=200/float(np.median([b[3]-b[1] for b in boxes]));common_x=150-np.median(face_x)*factor
registered=[];records=[];contact=Image.new('RGB',(4*256,3*280),'#fff8ed');draw=ImageDraw.Draw(contact)
for i,cel in enumerate(keys):
    size=round(384*factor*2);scaled=cel.resize((size,size),Image.Resampling.LANCZOS)
    dx=round((common_x+(np.median(face_x)-face_x[i])*factor)*2)
    ground=232
    dy=round((ground-boxes[i][3]*factor)*2)
    fixed=Image.new('RGBA',(512,512));fixed.alpha_composite(scaled,(dx,dy))
    bg=Image.new('RGB',(512,512),'cyan');bg.paste(fixed,(0,0),fixed);f=folder/f'key-{i:02d}.png';bg.save(f);registered.append(f)
    rgba=fixed.resize((256,256),Image.Resampling.LANCZOS);x=i%4*256;y=i//4*280;contact.paste(rgba,(x,y+20),rgba);draw.text((x+8,y+3),str(i),fill='#513d32')
    arr=np.asarray(rgba)[:,:,3]/255.;band=arr[ground-3:ground,:];xs=np.arange(256);support_x=float((band*xs).sum()/max(.001,band.sum()))
    records.append(dict(index=i,dx=dx,dy=dy,ground=ground,support_x=support_x,scale=factor,face_x=face_x[i]))
contact.save(folder/'registered-key-review.png');(folder/'registration.json').write_text(json.dumps(records,indent=2),encoding='utf8')
print(json.dumps(records,indent=2))
if not a.build:raise SystemExit()
plan=json.loads((folder/'contact-plan.json').read_text('utf8'))
assert plan['approved'] and len(plan['travel_curve'])==61
assert all(x<=y for x,y in zip(plan['travel_curve'],plan['travel_curve'][1:]))
assert plan['travel_curve'][0]==0 and plan['travel_curve'][-1]==1
rife=Path('C:/Users/rlagk/.cache/rabbit-animation-tools/rife-20221029');images=[]
assert sum(plan['counts'])==60
for k,count in enumerate(plan['counts']):
    inp=folder/f'interval-{k:02d}-input';out=folder/f'interval-{k:02d}-output';inp.mkdir(exist_ok=True);out.mkdir(exist_ok=True)
    shutil.copyfile(registered[k],inp/'0.png');shutil.copyfile(registered[(k+1)%12],inp/'1.png')
    sig=hashlib.sha256(registered[k].read_bytes()+registered[(k+1)%12].read_bytes()+str(count).encode()).hexdigest();stamp=out/'source.sha256'
    if not stamp.exists() or stamp.read_text()!=sig:
        run=subprocess.run([str(rife/'rife-ncnn-vulkan.exe'),'-i',str(inp),'-o',str(out),'-n',str(2*count),'-m',str(rife/'rife-v4.6'),'-g','0','-j','1:2:2','-z'],capture_output=True,text=True)
        if run.returncode:raise RuntimeError(run.stderr)
        stamp.write_text(sig)
    images.extend(matte(Image.open(out/f'{i+1:08d}.png')).resize((256,256),Image.Resampling.LANCZOS) for i in range(count))
    print('interval',k+1,'count',count,flush=True)
atlas=Image.new('RGBA',(2048,2048));clipped=[]
for i,im in enumerate(images):
    b=im.getbbox()
    if not b or b[0]<=0 or b[1]<=0 or b[2]>=256 or b[3]>=256:clipped.append(i)
    atlas.paste(im,(i%8*256,i//8*256))
assert not clipped
dest=ROOT/'assets/walk-v6/otter';dest.mkdir(parents=True,exist_ok=True);atlas.save(dest/'adult.png');images[0].save(dest/'adult-idle.png')
spec=dict(file='adult.png',idle_file='adult-idle.png',count=60,columns=8,reference_height=200,cycle_seconds=2.0,stride=plan['stride'],travel_curve=plan['travel_curve'],canvas=[256,256],root=[128,232])
(dest/'manifest.json').write_text(json.dumps(dict(version=6,species='otter',method='Contact-guided whole-body cels; fixed camera, measured support-foot travel',stages={'adult':spec}),indent=2),encoding='utf8')
report=dict(frames=60,distinct=len({hashlib.sha256(im.tobytes()).hexdigest() for im in images}),clipped=clipped,source_keys=12,installed=str(dest))
(folder/'validation.json').write_text(json.dumps(report,indent=2),encoding='utf8');print(report)
