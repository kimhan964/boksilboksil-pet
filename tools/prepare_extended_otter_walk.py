"""Register whole-image otter keys at authored phases; never alter anatomy."""
import argparse, json, math
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw

ROOT=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser()
p.add_argument('--key', action='append', required=True, help='source phase=file, 0..59')
p.add_argument('--approve', action='store_true')
p.add_argument('--output-plan',default='accepted-keys.json',help='Separate candidate plan filename')
p.add_argument('--review-name',default='extended-source-review',help='Separate candidate review basename')
p.add_argument('--species',default='otter')
p.add_argument('--stage',choices=['baby','adult'],default='adult')
p.add_argument('--base-plan',type=Path,help='Reviewed four-pose plan supplying the fixed master camera and sole regions')
a=p.parse_args()
work=ROOT/f'design/walk-v12/{a.species}/{a.stage}'
if a.species!='otter' or a.stage!='adult':
    if a.base_plan is None:p.error('A non-default animal requires --base-plan')
base=json.loads(a.base_plan.read_text('utf8')) if a.base_plan else {}
items=sorted((int(v.split('=',1)[0]),v.split('=',1)[1]) for v in a.key)
phases=[phase for phase,_ in items]
assert len(set(phases))==len(phases) and phases[0]==0 and phases[-1]<60
assert all(phase in phases for phase in [0,15,30,45])
regions=base.get('sole_regions',[(270,565),(565,920)])

def inspect(path):
    im=Image.open(path).convert('RGB').resize((1024,1024),Image.Resampling.LANCZOS)
    rgb=np.asarray(im); r,g,b=[rgb[:,:,i].astype(float) for i in range(3)]
    mask=~((g>r+25)&(b>r+25)&(g>b-24)); yy,xx=np.where(mask)
    feet=[]
    for lo,hi in regions:
        sy,sx=np.where(mask[810:980,lo:hi]); bottom=int(sy.max()+810)
        sy,sx=np.where(mask[bottom-4:bottom+1,lo:hi]);feet.append([float(sx.mean()+lo),bottom])
    top=int(yy.min());end=int(top+.44*(yy.max()-top));headmask=mask[top:end]
    head=float((headmask*np.arange(1024)[None,:]).sum()/headmask.sum())
    masks={'fur':(r>145)&(r<245)&(g>85)&(g<190)&(b>55)&(b<140)&(r>g*1.24)&(g>b*1.12),
           'cream':(r>235)&(g>215)&(b>160)&(b<230),
           'green':(g>r*1.03)&(r>60)&(r<190)&(b<120)}
    colors={k:np.median(rgb[m],axis=0).tolist() for k,m in masks.items() if np.any(m)}
    rgba=im.convert('RGBA');rgba.putalpha(Image.fromarray((mask*255).astype('uint8')))
    return rgba,dict(file=path.name,soles=feet,head_center_x=head,bbox=[int(xx.min()),top,int(xx.max()+1),int(yy.max()+1)],colors=colors)

master=(a.base_plan.parent/base['master_file']).resolve() if a.base_plan else ROOT/'design/all-species-v3/masters/otter/adult.png'
images=[]; rows=[]
for path in [master]+[work/name for _,name in items]:
    im,row=inspect(path);images.append(im);rows.append(row)
byphase={phase:r for (phase,_),r in zip(items,rows[1:])}
c0,c30=byphase[0],byphase[30]
n0,f0=c0['soles'];n30,f30=c30['soles']
stride=(n30[0]-n0[0])+(f0[0]-f30[0])
x30=(f0[0]+n0[0]-f30[0]-n30[0])/2
keys=[];issues=[];progress=[];swing_review=[]
for i,((phase,name),row) in enumerate(zip(items,rows[1:])):
    side=1 if phase<30 else 0
    target=f0[0]-stride*phase/60 if phase<30 else n30[0]+x30-stride*(phase-30)/60
    keys.append(dict(file=name,phase_frame=phase,ground=row['soles'][side][1],soles=row['soles'],root_registration_x=target-row['soles'][side][0]))
    end=rows[1:][(i+1)%len(items)];endphase=phases[(i+1)%len(items)]
    travel=(row['soles'][side][0]-row['head_center_x'])-(end['soles'][side][0]-end['head_center_x'])
    span=(endphase-phase)%60;expected=stride*span/60
    progress.append(dict(source_interval=[phase,endphase],runtime_interval=[(phase+30)%60,(endphase+30)%60],support=side,source_travel=travel,expected_travel=expected))
    swing=1-side
    swing_dx=(end['soles'][swing][0]-end['head_center_x'])-(row['soles'][swing][0]-row['head_center_x'])
    swing_dy=end['soles'][swing][1]-row['soles'][swing][1]
    half_start,half_end=(c0,c30) if phase<30 else (c30,c0)
    half_travel=abs((half_end['soles'][swing][0]-half_end['head_center_x'])-(half_start['soles'][swing][0]-half_start['head_center_x']))
    swing_fraction=abs(swing_dx)/max(half_travel,.001)
    swing_review.append(dict(source_interval=[phase,endphase],foot=swing,dx_source_px=swing_dx,dy_source_px=swing_dy,interval_seconds=span/60*1.6,fraction_of_half_swing=swing_fraction))
    # A near-contact extra drawing must not consume most of the recovery in
    # only three cels. Support-only checks previously missed this regression.
    if phase in (0,30) and span<=3 and swing_fraction>.4:
        issues.append(f'Premature swing at source phase {phase}..{endphase}: {swing_fraction:.1%} of half-cycle recovery')
    if travel<=0:issues.append(f'Nonforward support at source phase {phase}..{endphase}')
    elif travel<expected*.2 or travel>expected*2:issues.append(f'Uneven support at source phase {phase}..{endphase}: {travel:.2f} vs {expected:.2f}')
clearance=[byphase[15]['soles'][1][1]-byphase[15]['soles'][0][1],byphase[45]['soles'][0][1]-byphase[45]['soles'][1][1]]
if min(clearance)<8:issues.append('Passing clearance below 8 source pixels')
near=(n30[0]-c30['head_center_x'])-(n0[0]-c0['head_center_x'])
far=(f0[0]-c0['head_center_x'])-(f30[0]-c30['head_center_x'])
review=dict(support_intervals=progress,swing_intervals=swing_review,contact_travel_source_px=[near,far],contact_ratio=max(near,far)/min(near,far),passing_clearance=clearance,issues=issues,
            limits='Silhouette and sole proxies only. Whole-image visual and native runtime review are required.')
plan=dict(allow_trial_bake=a.approve and not issues,master_file=base.get('master_file','../../../all-species-v3/masters/otter/adult.png'),master_height=base.get('master_height',734),master_ground=base.get('master_ground',894),sole_regions=regions,keys=keys,source_gait_review=review)
for name in ['reference_height','camera_center_x','canvas_origin_x']:
    if name in base:plan[name]=base[name]
(work/a.output_plan).write_text(json.dumps(plan,indent=2),encoding='utf8')
(work/(a.review_name+'.json')).write_text(json.dumps(rows,indent=2),encoding='utf8')
board=Image.new('RGB',(1024,math.ceil(len(images)/4)*280),'#fff8ed');d=ImageDraw.Draw(board)
for i,(im,row) in enumerate(zip(images,rows)):
    x=i%4*256;y=i//4*280;thumb=im.resize((256,256),Image.Resampling.LANCZOS);board.paste(thumb,(x,y+24),thumb);d.text((x+4,y+5),'MASTER' if not i else f'{phases[i-1]} {row["file"]}',fill='#513d32')
board.save(work/(a.review_name+'.png'))
print(json.dumps(review,indent=2))
if a.approve and issues:raise SystemExit('Review failed; bake remains disabled')
