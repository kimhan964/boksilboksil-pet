"""Whole-character key poses -> 60 baked cels, no body-part rig or runtime blending."""
import argparse, json, subprocess, hashlib, shutil
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw
ROOT=Path(__file__).resolve().parents[1]
WORK=ROOT/'design/walk-v5'
OUT=ROOT/'assets/walk-v5'
RIFE=Path('C:/Users/rlagk/.cache/rabbit-animation-tools/rife-20221029')
P=argparse.ArgumentParser();P.add_argument('--species',default='otter');P.add_argument('--stage',default='baby,adult');P.add_argument('--approved-only',action='store_true');A=P.parse_args()
PERIOD={'otter':2.0,'squirrel':1.7,'hedgehog':2.0,'raccoon':2.0,'fox':1.9,'bear':2.3,'owl':2.1,'cat':1.9,'puppy':1.8,'hamster':1.7,'panda':2.3,'red_panda':2.0,'lamb':2.0,'koala':2.3,'penguin':2.1}
def alpha(im,remove_green_spill=False):
    rgb=np.asarray(im.convert('RGB'),dtype=np.float32);r,g,b=rgb[:,:,0],rgb[:,:,1],rgb[:,:,2]
    # Remove only the cyan key hue, preserving the raccoon's blue scarf.
    # Interpolated edges can contain darker cyan, not just the source's pure key.
    a=np.ones(r.shape,dtype=np.float32)
    cyan=np.abs(g-b)<24
    a[cyan]=1-np.clip((np.minimum(g-r,b-r)[cyan]-20)/70,0,1)
    if remove_green_spill:
        # RIFE can shift keyed cyan toward green around occluded orange talons.
        spill=(g>=b-24)&(g>r+25)&(b>r+25)
        a[spill]=np.minimum(a[spill],1-np.clip((np.minimum(g-r,b-r)[spill]-25)/30,0,1))
    a[a<.025]=0
    out=np.empty((*a.shape,4),dtype=np.uint8);safe=np.maximum(a,.001)
    out[:,:,0]=np.clip(r/safe,0,255);out[:,:,1]=np.clip((g-(1-a)*255)/safe,0,255);out[:,:,2]=np.clip((b-(1-a)*255)/safe,0,255);out[:,:,3]=np.rint(a*255);out[a==0]=0
    return Image.fromarray(out)
def build(species,stage):
    if A.approved_only:
        checks=json.loads((WORK/'representative-review.json').read_text('utf8'))
        if not any(c['species']==species and c['stage']==stage and c['approved'] for c in checks):
            print('AWAITING_REPAIR',species,stage,flush=True);return
    source=WORK/'raw'/f'{species}-{stage}.png'
    if not source.exists(): print('MISSING',source,flush=True);return
    folder=WORK/species/stage;folder.mkdir(parents=True,exist_ok=True)
    out=OUT/species;out.mkdir(parents=True,exist_ok=True)
    sheet=Image.open(source).convert('RGB');w,h=sheet.size
    keys=[]; heights=[];feet=[];boxes=[]
    legacy=json.loads((ROOT/'assets/species-v3'/species/'manifest.json').read_text('utf8'))['stages'][stage]
    old=Image.open(ROOT/'assets/species-v3'/species/legacy['sequences']['idle']['file']).convert('RGBA')
    old_heights=[old.crop((i*256,0,(i+1)*256,256)).getbbox() for i in range(16)]
    target=float(np.median([b[3]-b[1] for b in old_heights if b]))
    for i in range(4):
        cell=sheet.crop((round(i%2*w/2),round(i//2*h/2),round((i%2+1)*w/2),round((i//2+1)*h/2))).resize((512,512),Image.Resampling.LANCZOS)
        ImageDraw.Draw(cell).rectangle((0,0,511,511),outline='cyan',width=5)
        cel=alpha(cell);b=cel.getbbox();keys.append(cel);boxes.append(b);heights.append(b[3]-b[1])
        mask=np.array(cel)[:,:,3]>128; yy,xx=np.where(mask[max(0,b[3]-20):b[3],:]);feet.append((xx.min()+xx.max())/2)
    factor=min(target/float(np.median(heights)),232/max(b[2]-b[0] for b in boxes))
    # One camera scale and one horizontal origin for the ENTIRE action.
    origin_x=128-float(np.median(feet))*factor
    # Preserve silhouette extrema in a single common canvas; never resize per cel.
    origin_x=max(6-min(b[0] for b in boxes)*factor,min(origin_x,250-max(b[2] for b in boxes)*factor))
    registered=[]
    for i,cel in enumerate(keys):
        # RIFE sees 512px frames. Ground contact is fixed; the head/chest motion remains authored.
        size=round(512*factor*2);scaled=cel.resize((size,size),Image.Resampling.LANCZOS)
        fixed=Image.new('RGBA',(512,512));fixed.alpha_composite(scaled,(round(origin_x*2),464-round(boxes[i][3]*factor*2)))
        bg=Image.new('RGB',(512,512),'cyan');bg.paste(fixed,(0,0),fixed)
        path=folder/f'key-{i}.png';bg.save(path);registered.append(path)
    batch_in=folder/'batch-input';batch_out=folder/'batch-75'
    batch_in.mkdir(exist_ok=True);batch_out.mkdir(exist_ok=True)
    for i in range(5):shutil.copyfile(registered[i%4],batch_in/f'{i:02d}.png')
    signature=hashlib.sha256(b''.join(p.read_bytes() for p in registered)+b'rife-v4.6:n75:z').hexdigest()
    stamp=batch_out/'source.sha256'
    if not stamp.exists() or stamp.read_text()!=signature or not (batch_out/'00000075.png').exists():
        # RIFE directory sampling is i * input_count / output_count.
        # Five inputs (including closing pose) / 75 gives 15 samples per interval.
        # Keep the first 60; the last 15 are the repeated closing pose.
        run=subprocess.run([str(RIFE/'rife-ncnn-vulkan.exe'),'-i',str(batch_in),'-o',str(batch_out),'-n','75','-m',str(RIFE/'rife-v4.6'),'-g','0','-j','1:2:2','-z'],capture_output=True,text=True)
        if run.returncode:raise RuntimeError(run.stderr)
        stamp.write_text(signature)
    for i,key in enumerate(registered):
        assert np.array_equal(np.asarray(Image.open(key).convert('RGB')),np.asarray(Image.open(batch_out/f'{i*15+1:08d}.png').convert('RGB'))), 'Batch key timing mismatch'
    images=[alpha(Image.open(batch_out/f'{n+1:08d}.png'),remove_green_spill=species=='owl').resize((256,256),Image.Resampling.LANCZOS) for n in range(60)]
    print(species,stage,'60 cels interpolated',flush=True)
    atlas=Image.new('RGBA',(2048,2048));clipped=[];boxes=[]
    for n,im in enumerate(images):
        atlas.paste(im,(n%8*256,n//8*256));b=im.getbbox();boxes.append(b)
        if not b or b[0]<=0 or b[1]<=0 or b[2]>=256 or b[3]>=256:clipped.append(n)
    assert not clipped,(species,stage,clipped)
    atlas.save(out/f'{stage}.png');images[0].save(out/f'{stage}-idle.png')
    contact=Image.new('RGB',(1024,512),'#fff8ed')
    for k,n in enumerate([0,7,15,22,30,37,45,52]):
        im=images[n];contact.paste(im,(k%4*256,k//4*256),im)
    contact.save(folder/'contact.png')
    gifs=[]
    for im in images:
        bg=Image.new('RGB',(256,256),'#fff8ed');bg.paste(im,(0,0),im);gifs.append(bg)
    gifs[0].save(folder/'preview.gif',save_all=True,append_images=gifs[1:],duration=round(PERIOD[species]/60*1000),loop=0)
    manifest_path=out/'manifest.json';manifest=json.loads(manifest_path.read_text('utf8')) if manifest_path.exists() else dict(version=5,species=species,method='4 VARCO whole-body walk keys + 56 local RIFE-v4.6 inbetweens',stages={})
    reference_height=legacy['reference_height']*float(np.median(heights))*factor/target
    manifest['stages'][stage]=dict(file=f'{stage}.png',idle_file=f'{stage}-idle.png',count=60,columns=8,reference_height=reference_height,cycle_seconds=PERIOD[species],stride=72,canvas=[256,256],root=[128,232])
    manifest_path.write_text(json.dumps(manifest,indent=2),encoding='utf8')
    report=dict(species=species,stage=stage,frames=60,distinct=len({hashlib.sha256(im.tobytes()).hexdigest() for im in images}),clipped=clipped,scale=factor,origin_x=origin_x,height_range=[min(b[3]-b[1] for b in boxes),max(b[3]-b[1] for b in boxes)],source=str(source.relative_to(ROOT)))
    (folder/'validation.json').write_text(json.dumps(report,indent=2),encoding='utf8');print(json.dumps(report),flush=True)
for species in A.species.split(','):
    for stage in A.stage.split(','):build(species,stage)
