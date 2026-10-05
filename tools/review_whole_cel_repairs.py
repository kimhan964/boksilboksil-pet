"""Register AI-cleaned complete cels; compare before saving a separate trial.

No cutout patches, recolouring, or anatomical drawing. The only pixel operations
are the existing cyan matte, one uniform camera transform, and atlas placement.
"""
import argparse, json, shutil
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw

p=argparse.ArgumentParser()
p.add_argument('--plan',type=Path,required=True)
a=p.parse_args();path=a.plan.resolve();work=path.parent
plan=json.loads(path.read_text('utf8'))
source=(work/plan['source_assets']).resolve();dest=(work/plan['output_assets']).resolve()
dest.mkdir(parents=True,exist_ok=True)
manifest=json.loads((source/'manifest.json').read_text('utf8'));spec=manifest['stages']['adult']
atlas=Image.open(source/spec['file']).convert('RGBA');scale=plan['screen_scale']
rows=[];board=Image.new('RGB',(1024,280*len(plan['repairs'])),'#fff8ed');draw=ImageDraw.Draw(board)

def matte(im):
    rgb=np.asarray(im.convert('RGB'),dtype=np.float32);r,g,b=[rgb[:,:,i] for i in range(3)]
    alpha=np.ones(r.shape,dtype=np.float32);key=(g>=b-24)&(g>r+20)&(b>r+20)
    alpha[key]=1-np.clip((np.minimum(g-r,b-r)[key]-20)/50,0,1);alpha[alpha<.025]=0
    out=np.empty((*alpha.shape,4),dtype=np.uint8);safe=np.maximum(alpha,.001)
    out[:,:,0]=np.clip(r/safe,0,255);out[:,:,1]=np.clip((g-(1-alpha)*255)/safe,0,255)
    out[:,:,2]=np.clip((b-(1-alpha)*255)/safe,0,255);out[:,:,3]=np.rint(alpha*255);out[alpha==0]=0
    return Image.fromarray(out)

def head(im,band):
    v=np.asarray(im,dtype=float);alpha=v[band[0]:band[1],:,3]/255
    return np.array([(alpha*np.arange(256)[None,:]).sum()/alpha.sum(),(alpha*np.arange(*band)[:,None]).sum()/alpha.sum()])

def foot_tips(im):
    mask=np.asarray(im)[:,:,3]>128;out=[]
    for lo,hi in [(50,130),(145,215)]:
        yy,xx=np.where(mask[210:244,lo:hi]);bottom=int(yy.max()+210)
        yy,xx=np.where(mask[bottom-1:bottom+1,lo:hi]);out.append([float(xx.mean()+lo),bottom])
    return np.array(out)

for row,item in enumerate(plan['repairs']):
    phase=item['source_phase'];index=(phase+30)%60;x=index%8*256;y=index//8*256
    before=atlas.crop((x,y,x+256,y+256));b=before.getbbox();band=(b[1],b[1]+round((b[3]-b[1])*.44))
    raw=matte(Image.open(work/item['file']).resize((1024,1024),Image.Resampling.LANCZOS))
    s,_,dx,_,_,dy=item['output_to_input_affine']
    repaired=raw.transform((512,512),Image.Transform.AFFINE,(1/s,0,-dx/s,0,1/s,-dy/s),Image.Resampling.BICUBIC).resize((256,256),Image.Resampling.LANCZOS)
    va=np.asarray(before,dtype=float);vb=np.asarray(repaired,dtype=float);ha=head(before,band);hb=head(repaired,band)
    common=(va[:,:,3]>240)&(vb[:,:,3]>240);common[:band[0]]=False;common[band[1]:]=False
    colour=np.mean(np.abs(va[:,:,:3]-vb[:,:,:3])[common],axis=0)
    fur=common & (va[:,:,0]>va[:,:,1]*1.24)&(va[:,:,0]>145)&(va[:,:,1]>85)&(va[:,:,1]<190)&(va[:,:,2]>55)&(va[:,:,2]<140)
    fur_shift=np.median(vb[:,:,:3][fur],axis=0)-np.median(va[:,:,:3][fur],axis=0)
    ma=va[:,:,3]>128;mb=vb[:,:,3]>128;overlap=float((ma&mb).sum()/max(1,(ma|mb).sum()))
    bb=repaired.getbbox();jumps=(hb-ha)*scale
    foot_changes=(foot_tips(repaired)-foot_tips(before))*scale
    support=1 if phase<30 else 0
    issues=[]
    if max(abs(jumps))>.25:issues.append('Head shift exceeds0.25screenpx')
    if max(colour)>4:issues.append('Head mean colour difference exceeds4/255')
    if overlap<.97:issues.append('Whole silhouette overlap below97%')
    if max(abs(foot_changes[support]))>.35:issues.append('Supporting sole shift exceeds0.35screenpx')
    if max(abs(foot_changes[1-support]))>.5:issues.append('Swing sole shift exceeds0.5screenpx')
    if not bb or bb[0]<=0 or bb[1]<=0 or bb[2]>=256 or bb[3]>=256:issues.append('Blank or clipped')
    rows.append(dict(runtime_frame=index,source_phase=phase,file=item['file'],head_shift_screen_px=jumps.tolist(),head_mean_abs_rgb_difference=colour.tolist(),head_fur_median_rgb_shift=fur_shift.tolist(),sole_shift_screen_px=foot_changes.tolist(),supporting_foot=support,silhouette_iou=overlap,issues=issues))
    atlas.paste(repaired,(x,y));repaired.save(dest/f'repair-{index:02d}.png')
    for col,(label,im) in enumerate([('before whole',before),('after whole',repaired),('before toes',before.crop((32,202,224,246)).resize((256,59))),('after toes',repaired.crop((32,202,224,246)).resize((256,59)))]):
        board.paste(im,(col*256,row*280+24),im);draw.text((col*256+5,row*280+5),f'{index} {label}',fill='#513d32')

report={'rows':rows,'pass':not any(r['issues'] for r in rows),'limits':'Local continuity gates only; visually review all60cels and native playback.'}
(dest/'repair-review.json').write_text(json.dumps(report,indent=2),encoding='utf8');board.save(dest/'repair-review.png')
atlas.save(dest/spec['file']);shutil.copyfile(source/spec['idle_file'],dest/spec['idle_file'])
spec['whole_cel_repairs']=[r['runtime_frame'] for r in rows]
(dest/'manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf8')
print(json.dumps(report,indent=2))
