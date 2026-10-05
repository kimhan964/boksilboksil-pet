"""Bake generated WHOLE cels. Never cut, rotate or reconstruct body parts.

Uniform camera registration and support-foot translation precede optical flow.
Generated sheets remain candidates until source and native playback reviews pass.
"""
import argparse,hashlib,json,shutil,subprocess
from pathlib import Path
import numpy as np
from PIL import Image,ImageDraw
ROOT=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser();p.add_argument('folder',type=Path);p.add_argument('--species',required=True);p.add_argument('--stage',default='adult');p.add_argument('--cycle',type=float,default=2.25);p.add_argument('--quadruped',action='store_true');p.add_argument('--hop',action='store_true');p.add_argument('--build',action='store_true');a=p.parse_args()
folder=a.folder.resolve();meta=json.loads((folder/'measurements.json').read_text());frames=[Image.open(folder/r['file']).convert('RGBA') for r in meta]
fix=folder/'contact-04-fix.png'
if fix.exists() and len(frames)>4: frames[4]=Image.open(fix).convert('RGBA').resize(frames[4].size,Image.Resampling.LANCZOS)
order_path=folder/'frame-order.json'
if order_path.exists(): frames=[frames[i] for i in json.loads(order_path.read_text())]
count_keys=len(frames)
assert count_keys in [4,8]
phases=[0,8,15,23,30,38,45,53] if count_keys==8 else [0,15,30,45]
if a.hop: phases=[0,8,28,45]
extra_path=folder/'extra-whole-keys.json'
if extra_path.exists():
    for extra in json.loads(extra_path.read_text()):
        phases.append(extra['phase']);frames.append(Image.open(folder/extra['file']).convert('RGBA'))
    pairs=sorted(zip(phases,frames),key=lambda pair:pair[0]);phases=[p[0] for p in pairs];frames=[p[1] for p in pairs]
    count_keys=len(frames)
contact_mask=np.asarray(frames[0])[:,:,3]>128
contact_bottom=np.where(contact_mask)[0].max()
band=5
if a.quadruped: band=round((contact_bottom-np.where(contact_mask)[0].min())*.045)
columns=np.any(contact_mask[contact_bottom-band:contact_bottom+1],axis=0)
edges=np.diff(np.r_[False,columns,False].astype(int));runs=list(zip(np.where(edges==1)[0],np.where(edges==-1)[0]))
if a.quadruped:
    # The lifted forepaw may sit above the lowest hind paw. Use separate
    # fore/hind zones instead of requiring the same horizontal ground line.
    xs=np.where(contact_mask)[1];width=int(xs.max()-xs.min())
    runs=[(int(xs.min()),int(xs.min()+width*.36)),(int(xs.max()-width*.29),int(xs.max()+1))]
else: runs=sorted(sorted(runs,key=lambda r:r[1]-r[0],reverse=True)[:2])
assert len(runs)==2,'First contact must show two separate planted paws'
split=(runs[0][1]+runs[1][0])//2
def measure(im):
    mask=np.asarray(im)[:,:,3]>128;yy,xx=np.where(mask);top=int(yy.min());bottom=int(yy.max());height=bottom-top+1
    hy,hx=np.where(mask[top:round(top+height*.42)]);left=int(hx.min());right=int(hx.max());center=(left+right)/2
    feet=[]
    regions=[(max(0,runs[0][0]-40),split),(split,min(im.width,runs[1][1]+40))]
    if a.quadruped:
        _,paw_x=np.where(mask[round(bottom-height*.16):])
        width=int(paw_x.max()-paw_x.min())
        regions=[(int(paw_x.min()),int(paw_x.min()+width*.36)),(int(paw_x.max()-width*.29),int(paw_x.max()+1))]
    for lo,hi in regions:
        y0=round(bottom-height*.16);ys,xs=np.where(mask[y0:,lo:hi]);sole=int(ys.max()+y0)
        sy,sx=np.where(mask[sole-4:sole+1,lo:hi]);feet.append([float(sx.mean()+lo),float(sole)])
    return {'head_width':right-left,'head_center':center,'mass_center_x':float(xx.mean()),'height':height,'feet':feet,'top':top,'bottom':bottom}
metrics=[measure(im) for im in frames]
# A generated edit can arrive at a different resolution. It is first reduced
# to its reference canvas; all final cels then share one camera scale.
height=float(metrics[0]['height'] if a.hop else np.median([m['height'] for m in metrics]));scale=200/height
f0=np.array(metrics[0]['feet']);f4=np.array(metrics[phases.index(30) if 30 in phases else count_keys//2]['feet'])
half=((f0[1,0]-f0[0,0])-(f4[1,0]-f4[0,0]))/2
if a.quadruped:
    # Fore/hind paws have separate perspective baselines. A biped's alternating
    # left/right support registration would make the whole quadruped lurch.
    fore=[m['feet'][1][0]-m['mass_center_x'] for m in metrics]
    half=(max(fore)-min(fore))
assert a.hop or half>3, f'Contact poses do not describe a forward stride: {half}'
center=float(f0[:,0].mean())
registered=[];records=[]
def registration_dx(m,phase):
    if a.hop or a.quadruped:return metrics[0]['mass_center_x']-m['mass_center_x']
    side=1 if phase<30 else 0
    target=f0[1,0]-half*phase/30 if side==1 else f0[0,0]+half*(2-phase/30)
    return target-m['feet'][side][0]
for im,m,phase in zip(frames,metrics,phases):
    side=1 if phase<30 else 0
    target=f0[1,0]-half*phase/30 if side==1 else f0[0,0]+half*(2-phase/30)
    dx=registration_dx(m,phase);b=im.getbbox()
    scale=min(scale,114/max(1,center-(b[0]+dx)),114/max(1,b[2]+dx-center))
stride=half*2*scale;origin=128-center*scale;reference_height=height*scale
if a.hop:stride=24.0
for i,(im,m,phase) in enumerate(zip(frames,metrics,phases)):
    side=1 if phase<30 else 0
    target=f0[1,0]-half*phase/30 if side==1 else f0[0,0]+half*(2-phase/30)
    dx=registration_dx(m,phase)
    fixed=Image.new('RGBA',(512,512))
    scaled=im.resize((round(im.width*scale*2),round(im.height*scale*2)),Image.Resampling.LANCZOS)
    ground=m['bottom'] if a.quadruped or a.hop else m['feet'][side][1]
    xy=(round((origin+dx*scale)*2),round((232-ground*scale)*2))
    fixed.alpha_composite(scaled,xy)
    fixed.save(folder/f'registered-{i:02d}.png')
    # Magenta does not collide with the raccoon's blue scarf or grey fur.
    bg=Image.new('RGBA',fixed.size,(255,0,255,255));bg.alpha_composite(fixed);path=folder/f'rife-key-{i:02d}.png';bg.convert('RGB').save(path);registered.append(path)
    records.append(dict(index=i,phase=phase,translation=xy,source=m,rigid_dx_source=dx))
gallery=Image.new('RGB',(1024,580),'#fff8ed');d=ImageDraw.Draw(gallery)
for i in range(count_keys):
    im=Image.open(folder/f'registered-{i:02d}.png').resize((256,256));x=i%4*256;y=i//4*290
    gallery.paste(im,(x,y+25),im);d.text((x+8,y+5),f'key {i}',fill='#302820')
gallery.save(folder/'registered-review.png')
(folder/'registration.json').write_text(json.dumps({'stride':stride,'camera_scale':scale,'records':records},indent=2))
print('REGISTERED',a.species,a.stage,'stride',stride,flush=True)
if not a.build:raise SystemExit()
rife=Path('C:/Users/rlagk/.cache/rabbit-animation-tools/rife-20221029')
def unmatte(im):
    rgb=np.asarray(im.convert('RGB'),dtype=float);r,g,b=rgb[:,:,0],rgb[:,:,1],rgb[:,:,2]
    alpha=np.ones(r.shape);spill=np.minimum(r-g,b-g);key=spill>60
    alpha[key]=1-np.clip(spill[key]/255,0,1);alpha[alpha<.025]=0
    safe=np.maximum(alpha,.001);rgba=np.empty((*alpha.shape,4),dtype=np.uint8)
    rgba[:,:,0]=np.clip((r-(1-alpha)*255)/safe,0,255);rgba[:,:,1]=np.clip(g/safe,0,255);rgba[:,:,2]=np.clip((b-(1-alpha)*255)/safe,0,255);rgba[:,:,3]=np.rint(alpha*255);rgba[alpha==0]=0
    return Image.fromarray(rgba)
images=[]
for k,phase in enumerate(phases):
    count=(phases[(k+1)%count_keys]-phase)%60;inp=folder/f'interval-{k}-in';out=folder/f'interval-{k}-out';inp.mkdir(exist_ok=True);out.mkdir(exist_ok=True)
    shutil.copyfile(registered[k],inp/'0.png');shutil.copyfile(registered[(k+1)%count_keys],inp/'1.png')
    sig=hashlib.sha256((inp/'0.png').read_bytes()+(inp/'1.png').read_bytes()+str(count).encode()).hexdigest();stamp=out/'source.sha256'
    if not stamp.exists() or stamp.read_text()!=sig:
        run=subprocess.run([str(rife/'rife-ncnn-vulkan.exe'),'-i',str(inp),'-o',str(out),'-n',str(count*2),'-m',str(rife/'rife-v4.6'),'-g','0','-j','1:2:2','-z'],capture_output=True,text=True)
        if run.returncode: raise RuntimeError(run.stderr)
        stamp.write_text(sig)
    images.extend(unmatte(Image.open(out/f'{j+1:08d}.png')).resize((256,256),Image.Resampling.LANCZOS) for j in range(count))
    print('INTERVAL',k,flush=True)
dest=ROOT/'design/walk-v14/candidates'/a.species;dest.mkdir(parents=True,exist_ok=True)
atlas=Image.new('RGBA',(2048,2048));clipped=[]
for i,im in enumerate(images):
    box=im.getbbox()
    if not box or box[0]<=0 or box[1]<=0 or box[2]>=256 or box[3]>=256:clipped.append(i)
    atlas.paste(im,(i%8*256,i//8*256))
assert not clipped,clipped
atlas.save(dest/f'{a.stage}.png');images[0].save(dest/f'{a.stage}-idle.png')
manifest_path=dest/'manifest.json';manifest=json.loads(manifest_path.read_text()) if manifest_path.exists() else dict(version=14,species=a.species,method='Built-in image generation whole poses; offline RIFE to 60 cels; no runtime crossfade',stages={})
manifest['stages'][a.stage]=dict(file=f'{a.stage}.png',idle_file=f'{a.stage}-idle.png',count=60,columns=8,reference_height=reference_height,cycle_seconds=a.cycle,stride=stride,source_key_count=count_keys,gait='quadruped' if a.quadruped else 'biped',root=[128,232])
if a.hop: manifest['stages'][a.stage].update(locomotion='short_hop',launch_phase=1/6,land_phase=.7,lift_canvas=10)
manifest_path.write_text(json.dumps(manifest,indent=2))
views=[]
for im in images:
    bg=Image.new('RGBA',(256,256),'#fff8ed');bg.alpha_composite(im);views.append(bg.convert('RGB'))
views[0].save(folder/'candidate.gif',save_all=True,append_images=views[1:],duration=round(a.cycle*1000/60),loop=0)
contact=Image.new('RGB',(1280,1536),'#fff8ed')
for i,im in enumerate(views):contact.paste(im.resize((128,128)),(i%10*128,i//10*256))
contact.save(folder/'all-60-review.png')
(folder/'bake-review.json').write_text(json.dumps(dict(source_keys=count_keys,frames=60,distinct=len({hashlib.sha256(im.tobytes()).hexdigest() for im in images}),clipped=clipped,stride=stride,status='candidate; visual approval and native review required'),indent=2))
