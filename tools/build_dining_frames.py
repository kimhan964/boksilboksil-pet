"""Connect reviewed whole-character drinking keys with fixed scale and feet.

No anatomical cutouts, recoloring or runtime squash. This prepares a review bank;
--install is a separate step after visual inspection of the result.
"""
import argparse,hashlib,json,shutil,subprocess
from pathlib import Path
import numpy as np
from PIL import Image,ImageDraw

ROOT=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser();p.add_argument('plan');p.add_argument('--build',action='store_true');p.add_argument('--install',action='store_true');a=p.parse_args()
plan_path=ROOT/a.plan;plan=json.loads(plan_path.read_text('utf8'));work=plan_path.parent
out=work/'bake';out.mkdir(exist_ok=True)
factor=plan['reference_height']/plan['master_height']

def matte(im):
    rgb=np.asarray(im.convert('RGB'),dtype=np.float32);r,g,b=rgb[:,:,0],rgb[:,:,1],rgb[:,:,2]
    alpha=np.ones(r.shape,dtype=np.float32);key=(g>=b-24)&(g>r+20)&(b>r+20)
    alpha[key]=1-np.clip((np.minimum(g-r,b-r)[key]-20)/50,0,1);alpha[alpha<.025]=0
    rgba=np.empty((*alpha.shape,4),dtype=np.uint8);safe=np.maximum(alpha,.001)
    rgba[:,:,0]=np.clip(r/safe,0,255);rgba[:,:,1]=np.clip((g-(1-alpha)*255)/safe,0,255);rgba[:,:,2]=np.clip((b-(1-alpha)*255)/safe,0,255);rgba[:,:,3]=np.rint(alpha*255);rgba[alpha==0]=0
    return Image.fromarray(rgba)

def soles(im,regions,y_start,depth):
    mask=np.asarray(im)[:,:,3]>128;points=[]
    for lo,hi in regions:
        yy,xx=np.where(mask[y_start:,lo:hi]);bottom=int(yy.max()+y_start)
        yy,xx=np.where(mask[bottom-depth:bottom+1,lo:hi])
        points.append([float(xx.mean()+lo),float(bottom)])
    return np.array(points)

base=Image.open(ROOT/plan['base']).convert('RGBA')
base_soles=soles(base,[(85,141),(145,205)],205,1)
target=base_soles.mean(axis=0)
keys={'base':base.resize((512,512),Image.Resampling.LANCZOS)}
mouths={'base':np.array(plan['base_mouth'],dtype=float)}
records=[]
for name,key in plan['keys'].items():
    raw=matte(Image.open(work/key['file']))
    source_soles=soles(raw,key['sole_regions'],key.get('sole_y',840),4)
    delta=target-source_soles.mean(axis=0)*factor
    shifted=Image.new('RGBA',(512,512));shifted.alpha_composite(raw.resize((round(raw.width*factor*2),round(raw.height*factor*2)),Image.Resampling.LANCZOS),tuple(np.rint(delta*2).astype(int)))
    keys[name]=shifted;mouths[name]=np.array(key['mouth'])*factor+delta
    measured=soles(shifted.resize((256,256),Image.Resampling.LANCZOS),[(85,141),(145,205)],205,1)
    records.append(dict(name=name,file=key['file'],source_soles=source_soles.tolist(),translation=delta.tolist(),mouth=mouths[name].tolist(),sole_error_vs_base=(measured-base_soles).tolist()))
paths={}
board=Image.new('RGB',(len(keys)*256,282),'#fff8ed');draw=ImageDraw.Draw(board)
for i,(name,im) in enumerate(keys.items()):
    bg=Image.new('RGB',(512,512),'cyan');bg.paste(im,(0,0),im)
    paths[name]=out/f'key-{name}.png';bg.save(paths[name])
    small=im.resize((256,256),Image.Resampling.LANCZOS);board.paste(small,(i*256,24),small);draw.text((i*256+5,5),name,fill='#513d32')
board.save(out/'registered-review.png');(out/'registration.json').write_text(json.dumps(records,indent=2),encoding='utf8')
print(json.dumps(records,indent=2),flush=True)
if not a.build and not a.install:raise SystemExit()
assert plan['allow_trial_bake'], 'Representative poses must be reviewed first'
count=plan['count'];timeline=plan['timeline'];assert timeline[0]['frame']==0 and timeline[-1]['frame']==count-1
rife=Path('C:/Users/rlagk/.cache/rabbit-animation-tools/rife-20221029')
images=[];anchors=[]
for n,(first,last) in enumerate(zip(timeline[:-1],timeline[1:])):
    length=last['frame']-first['frame'];assert length>0
    inp=out/f'interval-{n}-input';dest=out/f'interval-{n}-output';inp.mkdir(exist_ok=True);dest.mkdir(exist_ok=True)
    s,e=first['key'],last['key'];shutil.copyfile(paths[s],inp/'0.png');shutil.copyfile(paths[e],inp/'1.png')
    digest=hashlib.sha256(paths[s].read_bytes()+paths[e].read_bytes()+str(length).encode()).hexdigest();stamp=dest/'source.sha256'
    if not stamp.exists() or stamp.read_text()!=digest:
        run=subprocess.run([str(rife/'rife-ncnn-vulkan.exe'),'-i',str(inp),'-o',str(dest),'-n',str(length*2),'-m',str(rife/'rife-v4.6'),'-g','0','-j','1:2:2','-z'],capture_output=True,text=True)
        if run.returncode:raise RuntimeError(run.stderr)
        stamp.write_text(digest)
    for i in range(length):
        images.append(matte(Image.open(dest/f'{i+1:08d}.png')).resize((256,256),Image.Resampling.LANCZOS))
        anchors.append((mouths[s]*(1-i/length)+mouths[e]*i/length).tolist())
    print('DINING_INTERVAL',n+1,flush=True)
images.append(base.copy());anchors.append(mouths['base'].tolist());images[0]=base.copy()
assert len(images)==count
atlas=Image.new('RGBA',(2048,256*((count+7)//8)));clipped=[];foot_tracks=[]
for i,im in enumerate(images):
    bounds=im.getbbox()
    if not bounds or bounds[0]<=0 or bounds[1]<=0 or bounds[2]>=256 or bounds[3]>=256:clipped.append(i)
    foot_tracks.append(soles(im,[(85,141),(145,205)],205,1).tolist())
    atlas.paste(im,(i%8*256,i//8*256))
assert not clipped,clipped
atlas.save(out/'adult-drink.png')
tracks=np.array(foot_tracks);screen_scale=110*.64/plan['reference_height']
validation=dict(frames=count,distinct=len({hashlib.sha256(im.tobytes()).hexdigest() for im in images}),clipped=clipped,cycle_seconds=plan['cycle_seconds'],sole_range_screen_px=(np.ptp(tracks,axis=0)*screen_scale).tolist(),boundary_matches_idle=images[0].tobytes()==base.tobytes() and images[-1].tobytes()==base.tobytes(),limits='Rigid registration, constant scale and alpha/sole bounds only; every cel and native pond contact still require visual review.')
(out/'validation.json').write_text(json.dumps(validation,indent=2),encoding='utf8')
gallery=Image.new('RGB',(1280,840),'#fff8ed');d=ImageDraw.Draw(gallery)
for j,i in enumerate(range(0,count,8)):
    x=j%5*256;y=j//5*280;gallery.paste(images[i],(x,y+24),images[i]);d.text((x+5,y+5),str(i),fill='#513d32')
gallery.save(out/'motion-contact.png')
for group in range(2):
    all_board=Image.new('RGB',(1280,840),'#fff8ed');d=ImageDraw.Draw(all_board)
    for j,i in enumerate(range(group*60,(group+1)*60)):
        small=images[i].resize((128,128),Image.Resampling.LANCZOS);x=j%10*128;y=j//10*140;all_board.paste(small,(x,y+12),small);d.text((x+2,y+1),str(i),fill='#513d32')
    all_board.save(out/f'all-cels-{group}.png')
manifest=dict(version=13,species='owl',stages={'adult':dict(reference_height=plan['reference_height'],sequences={'drink':dict(file='adult-drink.png',count=count,columns=8,duration=plan['cycle_seconds'],anchors=anchors,contact_mouth=mouths['deep'].tolist(),fixed_cels=True)})})
(out/'manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf8')
if a.install:
    assert plan.get('allow_install',False),'Review all cels before installation'
    asset=ROOT/'assets/dining-v13/owl';asset.mkdir(parents=True,exist_ok=True)
    for name in ['adult-drink.png','manifest.json']:shutil.copyfile(out/name,asset/name)
print(json.dumps(validation,indent=2))
