"""Bake a reviewed whole-image short walk. No anatomical parts or runtime warps."""
import argparse,json,hashlib,subprocess,shutil,math
from pathlib import Path
import numpy as np
from PIL import Image,ImageDraw
ROOT=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser();p.add_argument('--build',action='store_true');p.add_argument('--version',type=int,default=8);a=p.parse_args()
WORK=ROOT/f'design/walk-v{a.version}'
def matte(im):
    rgb=np.asarray(im.convert('RGB'),dtype=np.float32);r,g,b=rgb[:,:,0],rgb[:,:,1],rgb[:,:,2]
    alpha=np.ones(r.shape,dtype=np.float32);key=(g>=b-24)&(g>r+20)&(b>r+20)
    alpha[key]=1-np.clip((np.minimum(g-r,b-r)[key]-20)/50,0,1);alpha[alpha<.025]=0
    rgba=np.empty((*alpha.shape,4),dtype=np.uint8);safe=np.maximum(alpha,.001)
    rgba[:,:,0]=np.clip(r/safe,0,255);rgba[:,:,1]=np.clip((g-(1-alpha)*255)/safe,0,255);rgba[:,:,2]=np.clip((b-(1-alpha)*255)/safe,0,255);rgba[:,:,3]=np.rint(alpha*255);rgba[alpha==0]=0
    return Image.fromarray(rgba)
sheet=Image.open(WORK/'otter-finished-12.png');cw=sheet.width//4;ch=sheet.height//3
folder=WORK/'otter-adult';folder.mkdir(exist_ok=True)
keys=[];boxes=[];face_x=[]
for i in range(12):
    cel=matte(sheet.crop((i%4*cw,i//4*ch,(i%4+1)*cw,(i//4+1)*ch)))
    keys.append(cel);boxes.append(cel.getbbox());rgb=np.asarray(cel)
    mask=(rgb[:,:,0]>215)&(rgb[:,:,1]>185)&(rgb[:,:,2]>140)&(rgb[:,:,3]>128);mask[int(ch*.52):]=False
    yy,xx=np.where(mask);face_x.append(float(xx.mean()))
factor=min(200/float(np.median([b[3]-b[1] for b in boxes])),222/max(b[2]-b[0] for b in boxes))
plan=json.loads((WORK/'lane-plan.json').read_text('utf8'));guide_factor=factor*cw/256
records=[];registered=[];contact=Image.new('RGB',(1024,840),'#fff8ed');draw=ImageDraw.Draw(contact)
for i,cel in enumerate(keys):
    near=next(f for f in plan['keys'][i]['feet'] if f['side']=='near')
    baseline=next(f for f in plan['keys'][0]['feet'] if f['side']=='near')['y']
    ground=232+(near['y']-baseline)*guide_factor
    dx=round((150-face_x[i]*factor)*2);dy=round((ground-boxes[i][3]*factor)*2)
    fixed=Image.new('RGBA',(512,512));fixed.alpha_composite(cel.resize((round(cw*factor*2),round(ch*factor*2)),Image.Resampling.LANCZOS),(dx,dy))
    bg=Image.new('RGB',(512,512),'cyan');bg.paste(fixed,(0,0),fixed);f=folder/f'key-{i:02d}.png';bg.save(f);registered.append(f)
    rgba=fixed.resize((256,256),Image.Resampling.LANCZOS);x=i%4*256;y=i//4*280
    contact.paste(rgba,(x,y+20),rgba);draw.text((x+8,y+3),str(i),fill='#513d32')
    records.append(dict(index=i,dx=dx,dy=dy,ground=ground,scale=factor,face_x=face_x[i],source_bbox=boxes[i]))
contact.save(folder/'registered-key-review.png');(folder/'registration.json').write_text(json.dumps(records,indent=2),encoding='utf8')
print(json.dumps(dict(scale=factor,reference_height=200,guide_scale=guide_factor),indent=2))
if not a.build:raise SystemExit()
review=json.loads((WORK/'review.json').read_text('utf8'));assert review['allow_trial_bake']
rife=Path('C:/Users/rlagk/.cache/rabbit-animation-tools/rife-20221029');images=[]
for k in range(12):
    inp=folder/f'interval-{k:02d}-input';out=folder/f'interval-{k:02d}-output';inp.mkdir(exist_ok=True);out.mkdir(exist_ok=True)
    shutil.copyfile(registered[k],inp/'0.png');shutil.copyfile(registered[(k+1)%12],inp/'1.png')
    sig=hashlib.sha256(registered[k].read_bytes()+registered[(k+1)%12].read_bytes()+b'5').hexdigest();stamp=out/'source.sha256'
    if not stamp.exists() or stamp.read_text()!=sig:
        run=subprocess.run([str(rife/'rife-ncnn-vulkan.exe'),'-i',str(inp),'-o',str(out),'-n','10','-m',str(rife/'rife-v4.6'),'-g','0','-j','1:2:2','-z'],capture_output=True,text=True)
        if run.returncode:raise RuntimeError(run.stderr)
        stamp.write_text(sig)
    images.extend(matte(Image.open(out/f'{i+1:08d}.png')).resize((256,256),Image.Resampling.LANCZOS) for i in range(5))
    print('interval',k+1,flush=True)
sole_x=[]
for im in images[:35]:
    mask=np.asarray(im)[:,:,3]>128
    ys,xs=np.where(mask);bottom=int(ys.max())
    yy,xx=np.where(mask[bottom-3:bottom+1]);sole_x.append(float(xx.mean()))
# Calibrate constant root speed to the actual drawn supporting sole, not the guide.
stride=-float(np.polyfit(np.arange(35)/60,sole_x,1)[0])
assert 30<stride<80
# Begin/end on the less extended double-support pose, retaining the cyclic order.
images=images[30:]+images[:30]
atlas=Image.new('RGBA',(2048,2048));clipped=[]
for i,im in enumerate(images):
    b=im.getbbox()
    if not b or b[0]<=0 or b[1]<=0 or b[2]>=256 or b[3]>=256:clipped.append(i)
    atlas.paste(im,(i%8*256,i//8*256))
assert not clipped
dest=ROOT/f'assets/walk-v{a.version}/otter';dest.mkdir(parents=True,exist_ok=True);atlas.save(dest/'adult.png');images[0].save(dest/'adult-idle.png')
spec=dict(file='adult.png',idle_file='adult-idle.png',count=60,columns=8,reference_height=200,cycle_seconds=1.6,stride=stride,source_phase_offset=30,canvas=[256,256],root=[128,232])
(dest/'manifest.json').write_text(json.dumps(dict(version=a.version,species='otter',method='Short two-lane whole-image gait, constant phase and root speed',stages={'adult':spec}),indent=2),encoding='utf8')
report=dict(frames=60,distinct=len({hashlib.sha256(im.tobytes()).hexdigest() for im in images}),clipped=clipped,source_keys=12,cycle_seconds=1.6,stride=stride)
(folder/'validation.json').write_text(json.dumps(report,indent=2),encoding='utf8');print(report)
