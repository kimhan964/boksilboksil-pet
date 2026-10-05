"""Bake reviewed full-image otter poses; one scale, no anatomical cutouts."""
import argparse, hashlib, json, shutil, subprocess
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw

ROOT=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser();p.add_argument('--build',action='store_true');p.add_argument('--version',type=int,default=10);p.add_argument('--stage',choices=['adult','baby'],default='adult');p.add_argument('--species',default='otter')
p.add_argument('--plan',type=Path,help='Candidate plan; relative source paths resolve beside this file')
p.add_argument('--build-dir',type=Path,help='Separate intermediate evidence directory for a candidate')
p.add_argument('--output-assets',type=Path,help='Save candidate assets separately from the live game bank')
args=p.parse_args()
WORK=ROOT/f'design/walk-v{args.version}'
if args.version>=12: WORK=WORK/args.species/args.stage
plan_path=WORK/('accepted-keys.json' if args.version>=12 or args.stage=='adult' else 'baby-accepted-keys.json')
if args.plan:
    plan_path=args.plan.resolve();WORK=plan_path.parent
plan=json.loads(plan_path.read_text('utf8'))
folder=args.build_dir.resolve() if args.build_dir else WORK/f'{args.species}-{args.stage}';folder.mkdir(parents=True,exist_ok=True)
reference_height=plan.get('reference_height',200)
factor=reference_height/plan.get('master_height',734)
center=plan.get('camera_center_x',550);origin=plan.get('canvas_origin_x',138)

def matte(im):
    rgb=np.asarray(im.convert('RGB'),dtype=np.float32);r,g,b=rgb[:,:,0],rgb[:,:,1],rgb[:,:,2]
    alpha=np.ones(r.shape,dtype=np.float32);key=(g>=b-24)&(g>r+20)&(b>r+20)
    alpha[key]=1-np.clip((np.minimum(g-r,b-r)[key]-20)/50,0,1);alpha[alpha<.025]=0
    rgba=np.empty((*alpha.shape,4),dtype=np.uint8);safe=np.maximum(alpha,.001)
    rgba[:,:,0]=np.clip(r/safe,0,255);rgba[:,:,1]=np.clip((g-(1-alpha)*255)/safe,0,255);rgba[:,:,2]=np.clip((b-(1-alpha)*255)/safe,0,255);rgba[:,:,3]=np.rint(alpha*255);rgba[alpha==0]=0
    return Image.fromarray(rgba)

def soles(im,scale=1):
    mask=np.asarray(im)[:,:,3]>128;out=[]
    for lo,hi in plan.get('sole_regions',[(290,555),(565,920)]):
        # Coordinates mapped from the fixed approved-master camera.
        x0=round((origin+(lo-center)*factor)*scale);x1=round((origin+(hi-center)*factor)*scale)
        y0=round(205*scale);ys,xs=np.where(mask[y0:,x0:x1]);bottom=int(ys.max()+y0)
        yy,xx=np.where(mask[bottom-max(1,round(1.3*scale)):bottom+1,x0:x1])
        out.append([float(xx.mean()+x0)/scale,bottom/scale])
    return out

registered=[];records=[];contact=Image.new('RGB',((len(plan['keys'])+1)*256,290),'#fff8ed');draw=ImageDraw.Draw(contact)
for i,item in enumerate([{'file':plan.get('master_file','../all-species-v3/masters/otter/adult.png'),'ground':plan.get('master_ground',894)}]+plan['keys']):
    raw=matte(Image.open(WORK/item['file']).resize((1024,1024),Image.Resampling.LANCZOS))
    # Register each complete drawing to its supporting sole. This is a rigid
    # translation of the whole cel; body proportions and authored bob survive.
    dx=round((origin+(item.get('root_registration_x',0)-center)*factor)*2);dy=round((232-item['ground']*factor)*2)
    fixed=Image.new('RGBA',(512,512));fixed.alpha_composite(raw.resize((round(1024*factor*2),)*2,Image.Resampling.LANCZOS),(dx,dy))
    preview=fixed.resize((256,256),Image.Resampling.LANCZOS)
    contact.paste(preview,(i*256,25),preview);draw.text((i*256+8,6),'MASTER' if i==0 else item['file'],fill='#513d32')
    if i:
        bg=Image.new('RGB',(512,512),'cyan');bg.paste(fixed,(0,0),fixed);path=folder/f'key-{i-1:02d}.png';bg.save(path);registered.append(path)
        records.append(dict(file=item['file'],scale=factor,dx=dx,dy=dy,soles=soles(fixed,2)))
contact.save(folder/'registered-review.png');(folder/'registration.json').write_text(json.dumps(records,indent=2),encoding='utf8')
print(json.dumps(records,indent=2))
if not args.build:raise SystemExit()
assert plan['allow_trial_bake'], 'Review the complete poses first'
rife=Path('C:/Users/rlagk/.cache/rabbit-animation-tools/rife-20221029');images=[]
tta_flags=['-z']+(['-x'] if plan.get('spatial_tta',False) else [])
phases=[item.get('phase_frame',k*15) for k,item in enumerate(plan['keys'])]
assert phases[0]==0 and phases==sorted(set(phases)) and phases[-1]<60, phases
interval_counts=[(phases[(k+1)%len(phases)]-phase)%60 for k,phase in enumerate(phases)]
assert sum(interval_counts)==60 and all(n>0 for n in interval_counts)
for k,count in enumerate(interval_counts):
    inp=folder/f'interval-{k}-input';out=folder/f'interval-{k}-output';inp.mkdir(exist_ok=True);out.mkdir(exist_ok=True)
    next_key=registered[(k+1)%len(registered)]
    shutil.copyfile(registered[k],inp/'0.png');shutil.copyfile(next_key,inp/'1.png')
    sig=hashlib.sha256(registered[k].read_bytes()+next_key.read_bytes()+str(count).encode()+','.join(tta_flags).encode()).hexdigest();stamp=out/'source.sha256'
    if not stamp.exists() or stamp.read_text()!=sig:
        run=subprocess.run([str(rife/'rife-ncnn-vulkan.exe'),'-i',str(inp),'-o',str(out),'-n',str(count*2),'-m',str(rife/'rife-v4.6'),'-g','0','-j','1:2:2']+tta_flags,capture_output=True,text=True)
        if run.returncode:raise RuntimeError(run.stderr)
        stamp.write_text(sig)
    images.extend(matte(Image.open(out/f'{i+1:08d}.png')).resize((256,256),Image.Resampling.LANCZOS) for i in range(count))
    print('interval',k+1,flush=True)
feet=np.array([soles(im) for im in images]);fits=[]
for start,side in [(0,1),(30,0)]:
    x=feet[start:start+30,side,0];fit=np.polyfit(np.arange(30)/60,x,1)
    fits.append(dict(stride=-float(fit[0]),max_residual=float(np.max(np.abs(x-np.polyval(fit,np.arange(30)/60))))))
stride=float(np.mean([f['stride'] for f in fits]))
# Short animals / the 190px atlas can legitimately use less than 15px.
# Reject reversed support travel; naturalness is checked in real screen units.
assert 0<stride<90 and all(f['stride']>0 for f in fits), fits
# Begin/end with the narrow double-support pose, so resting is not a split stance.
images=images[30:]+images[:30]
atlas=Image.new('RGBA',(2048,2048));clipped=[]
for i,im in enumerate(images):
    b=im.getbbox()
    if not b or b[0]<=0 or b[1]<=0 or b[2]>=256 or b[3]>=256:clipped.append(i)
    atlas.paste(im,(i%8*256,i//8*256))
assert not clipped
dest=args.output_assets.resolve() if args.output_assets else ROOT/f'assets/walk-v{args.version}/{args.species}';dest.mkdir(parents=True,exist_ok=True);atlas.save(dest/f'{args.stage}.png');images[0].save(dest/f'{args.stage}-idle.png')
cycle_seconds=float(plan.get('cycle_seconds',1.6))
spec=dict(file=f'{args.stage}.png',idle_file=f'{args.stage}-idle.png',count=60,columns=8,reference_height=reference_height,cycle_seconds=cycle_seconds,stride=stride,source_phase_offset=30,canvas=[256,256],root=[128,232])
manifest_path=dest/'manifest.json'
manifest=json.loads(manifest_path.read_text('utf8')) if manifest_path.exists() else dict(version=args.version,species=args.species,method='Reviewed chubby full-image poses, 60 cels, constant scale and travel speed',stages={})
manifest['stages'][args.stage]=spec
manifest_path.write_text(json.dumps(manifest,indent=2),encoding='utf8')
report=dict(frames=60,distinct=len({hashlib.sha256(im.tobytes()).hexdigest() for im in images}),clipped=clipped,source_keys=len(registered),source_phase_frames=phases,interpolation_options=tta_flags,cycle_seconds=cycle_seconds,stride=stride,support_fits=fits,sole_tracks=feet.tolist())
(folder/'validation.json').write_text(json.dumps(report,indent=2),encoding='utf8');print({k:v for k,v in report.items() if k!='sole_tracks'})
gallery=Image.new('RGB',(1024,840),'#fff8ed');d=ImageDraw.Draw(gallery)
for j,i in enumerate(range(0,60,5)):
    x=j%4*256;y=j//4*280;gallery.paste(images[i],(x,y+24),images[i]);d.text((x+8,y+5),str(i),fill='#513d32')
gallery.save(folder/'60-frame-contact.png')
