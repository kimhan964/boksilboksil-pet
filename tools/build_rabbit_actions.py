"""Bake complete VARCO action drawings with local RIFE; preserve approved walk bytes."""
import hashlib, json, shutil, subprocess
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw

ROOT=Path(__file__).resolve().parents[1]
WORK=ROOT/'design/rabbit-actions-v9'
OUT=ROOT/'assets/rabbit-frame-pilot-v9'
RIFE=Path('C:/Users/rlagk/.cache/rabbit-animation-tools/rife-20221029')
OUT.mkdir(exist_ok=True)

def key_alpha(im):
    rgb=np.array(im.convert('RGB'),dtype=np.float32)
    r,g,b=rgb[:,:,0],rgb[:,:,1],rgb[:,:,2]
    a=np.clip(1-(np.minimum(g-r,b-r)-10)/220,0,1)
    a[(r<80)&(g>150)&(b>150)]=0
    a[a<.025]=0
    rgba=np.empty((*a.shape,4),dtype=np.uint8); safe=np.maximum(a,.001)
    rgba[:,:,0]=np.clip(r/safe,0,255)
    rgba[:,:,1]=np.clip((g-(1-a)*255)/safe,0,255)
    rgba[:,:,2]=np.clip((b-(1-a)*255)/safe,0,255)
    rgba[:,:,3]=np.rint(a*255).astype(np.uint8);rgba[a==0]=0
    return Image.fromarray(rgba)

def pack(im):
    cel=key_alpha(im).resize((237,237),Image.Resampling.LANCZOS)
    result=Image.new('RGBA',(256,256)); result.alpha_composite(cel,(9,17))
    return result

base=Image.open(ROOT/'design/rabbit-frame-pilot-v8/anchors/00.png').convert('RGB')
neutral=Image.open(ROOT/'assets/rabbit-frame-pilot-v8/adult-idle.png').convert('RGBA')
manifest=json.loads((ROOT/'assets/rabbit-frame-pilot-v8/manifest.json').read_text('utf8'))
manifest['version']=9
manifest['method']='Approved v8 walk unchanged (lower lift 12); VARCO whole-character actions + local RIFE-v4.6 inbetweens'
shutil.copy2(ROOT/'assets/rabbit-frame-pilot-v8/adult-walk.png',OUT/'adult-walk.png')
# Knot order and authored time. Each bank starts and ends at the EXACT approved neutral cel.
plans={
 'idle':dict(keys=[-1,1,2,-1],counts=[39,10,10],times=[0,2.0,2.18,2.36],duration=4.8),
 'eat':dict(keys=[-1,0,1,2,-1],counts=[13,14,17,15],times=[0,.85,1.7,3.65,5.45],duration=5.5),
 'drink':dict(keys=[-1,1,2,3,2,1,-1],counts=[10,10,9,9,10,11],times=[0,.8,1.6,2.5,3.3,4.35,5.45],duration=5.5),
}
report={}
for action,plan in plans.items():
    folder=WORK/action; folder.mkdir(exist_ok=True)
    sheet=Image.open(WORK/('eat-keys-fixed.png' if action=='eat' else action+'-keys.png')).convert('RGB')
    cells=[]; boxes=[]
    for i in range(4):
        cel=sheet.crop((i%2*512,i//2*512,(i%2+1)*512,(i//2+1)*512))
        # Remove worksheet borders outside the fully visible subject, not anatomy.
        d=ImageDraw.Draw(cel);d.rectangle((0,0,511,511),outline='cyan',width=7)
        cel=key_alpha(cel);cells.append(cel);boxes.append(cel.getbbox())
    factor=420/(boxes[0][3]-boxes[0][1])
    registered=[]; registrations=[]
    for i,cel in enumerate(cells):
        size=round(512*factor); cel=cel.resize((size,size),Image.Resampling.LANCZOS)
        mask=np.array(cel)[:,:,3]>128; ys,xs=np.where(mask)
        floor=int(ys.max())+1
        # Hind-foot contact: left edge of the lowest 15 pixels, fixed across poses.
        low=mask[max(0,floor-15):floor,:]
        left=int(np.where(low)[1].min())
        dx=156-left;dy=464-floor
        fixed=Image.new('RGBA',(512,512)); fixed.alpha_composite(cel,(dx,dy))
        canvas=Image.new('RGB',(512,512),'cyan');canvas.paste(fixed,(0,0),fixed)
        path=folder/f'key-{i}.png';canvas.save(path); registered.append(path)
        registrations.append(dict(key=i,uniform_scale=factor,translation=[dx,dy]))
    basepath=folder/'neutral.png';base.save(basepath)
    paths=[basepath if k==-1 else registered[k] for k in plan['keys']]
    images=[neutral.copy()]; times=[0.0]
    for k,count in enumerate(plan['counts']):
        for j in range(1,count+1):
            endpoint=j==count
            path=paths[k+1] if endpoint else folder/f'between-{k:02d}-{j:02d}.png'
            if not endpoint and not path.exists():
                run=subprocess.run([str(RIFE/'rife-ncnn-vulkan.exe'),'-0',str(paths[k]),'-1',str(paths[k+1]),'-o',str(path),'-s',str(j/count),'-m',str(RIFE/'rife-v4.6'),'-g','0','-j','1:1:1','-z'],capture_output=True,text=True)
                if run.returncode: raise RuntimeError(run.stderr)
            images.append(neutral.copy() if endpoint and plan['keys'][k+1]==-1 else pack(Image.open(path)))
            times.append(plan['times'][k]+(plan['times'][k+1]-plan['times'][k])*j/count)
        print(f'{action} interval {k+1}/{len(plan["counts"])}',flush=True)
    assert len(images)==60
    atlas=Image.new('RGBA',(2048,2048))
    clipped=[]
    for i,im in enumerate(images):
        atlas.paste(im,(i%8*256,i//8*256)); b=im.getbbox()
        if not b or b[0]<=0 or b[1]<=0 or b[2]>=256 or b[3]>=256: clipped.append(i)
        im.save(folder/f'cel-{i:02d}.png')
    atlas.save(OUT/f'adult-{action}.png')
    strip=Image.new('RGB',(5*256,256),'#fff8ed')
    for i,n in enumerate([0,14,29,44,59]):strip.paste(images[n],(i*256,0),images[n])
    strip.save(WORK/f'{action}-review.png')
    gif=[]
    for age in np.arange(0,plan['duration'],1/25):
        index=max(i for i,t in enumerate(times) if t<=age)
        bg=Image.new('RGB',(256,256),'#fff8ed');bg.paste(images[index],(0,0),images[index]);gif.append(bg)
    gif[0].save(WORK/f'{action}-preview.gif',save_all=True,append_images=gif[1:],duration=40,loop=0)
    manifest['stages']['adult']['sequences'][action]=dict(file=f'adult-{action}.png',count=60,columns=8,duration=plan['duration'],phases=[t/plan['duration'] for t in times],one_shot=action!='idle',embedded_food=action=='eat')
    report[action]=dict(frames=60,distinct=len({hashlib.sha256(im.tobytes()).hexdigest() for im in images}),clipped=clipped,endpoint_matches_neutral=images[0].tobytes()==images[-1].tobytes()==neutral.tobytes(),registration=registrations)
    assert not clipped
manifest['stages']['adult']['lift_canvas']=12
(OUT/'manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf8')
(WORK/'manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf8')
(WORK/'asset-validation.json').write_text(json.dumps(report,indent=2),encoding='utf8')
print(json.dumps(report,indent=2))
