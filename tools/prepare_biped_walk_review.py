"""Inspect selected complete cels and register the supporting soles for review."""
import argparse,json,os
from pathlib import Path
import numpy as np
from PIL import Image,ImageDraw
ROOT=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser();p.add_argument('--version',type=int,default=12);p.add_argument('--species',default='squirrel');p.add_argument('--stage',choices=['adult','baby']);p.add_argument('--master',type=Path);p.add_argument('--keys',nargs=4,default=['strong-00.png','passing-03.png','pose-06.png','passing-09.png']);p.add_argument('--approve',action='store_true')
p.add_argument('--output-plan',default='accepted-keys.json',help='Separate plan for an uninstalled candidate')
p.add_argument('--review-name',default='selected-review',help='Separate candidate comparison basename')
a=p.parse_args()
regions=[(250,580),(625,945)] if a.species in ['raccoon','fox'] else [(360,640),(640,960)]
if a.species=='bear': regions=[(250,545),(555,860)]
if a.species=='owl': regions=[(300,555),(570,820)]
if a.species=='otter': regions=[(270,565),(565,920)]
if a.species=='penguin': regions=[(260,550),(560,860)]
if a.species=='koala': regions=[(300,540),(560,820)]

def inspect(path):
    im=Image.open(path).convert('RGB').resize((1024,1024),Image.Resampling.LANCZOS);rgb=np.asarray(im);r,g,b=[rgb[:,:,i].astype(float) for i in range(3)]
    mask=~((g>r+25)&(b>r+25)&(g>b-24));yy,xx=np.where(mask)
    rgba=im.convert('RGBA');rgba.putalpha(Image.fromarray((mask*255).astype('uint8')))
    feet=[]
    for lo,hi in regions:
        fy,fx=np.where(mask[820:980,lo:hi]);bottom=int(fy.max()+820);sy,sx=np.where(mask[bottom-4:bottom+1,lo:hi]);feet.append([float(sx.mean()+lo),bottom])
    fur=(r>145)&(r<245)&(g>85)&(g<190)&(b>55)&(b<140)&(r>g*1.24)&(g>b*1.12)
    if a.species=='raccoon':
        # Taupe fur is less saturated than squirrel caramel. The caramel mask
        # otherwise selects cheeks/shadows and falsely reports a hue shift.
        fur=(r>145)&(r<215)&(g>115)&(g<185)&(b>95)&(b<170)&(r>g+12)&(g>b+5)
    elif a.species=='fox':
        fur=(r>230)&(g>120)&(g<200)&(b>40)&(b<150)&(r>g+45)&(g>b+30)
    elif a.species=='owl':
        fur=(r>130)&(r<235)&(g>120)&(g<225)&(b>145)&(b<240)&(b>g+3)&(r>g+3)
    elif a.species=='penguin':
        fur=(r>65)&(r<170)&(g>60)&(g<160)&(b>55)&(b<155)&(abs(r-g)<25)&(abs(g-b)<20)
    elif a.species=='koala':
        fur=(r>145)&(r<230)&(g>140)&(g<225)&(b>130)&(b<220)&(abs(r-g)<18)&(abs(g-b)<20)
    cream=(r>235)&(g>215)&(b>160)&(b<240)
    if a.species=='owl': cream=(r>240)&(g>240)&(b>240)
    if a.species=='penguin': cream=(r>235)&(g>235)&(b>230)&(abs(r-b)<12)
    top=int(yy.min());end=int(top+.44*(yy.max()-top));head_mask=mask[top:end]
    head_center=float((head_mask*np.arange(1024)[None,:]).sum()/head_mask.sum())
    colors={'fur':np.median(rgb[fur],axis=0).tolist(),'cream':np.median(rgb[cream],axis=0).tolist()}
    if a.species=='penguin':
        scarf=(r>140)&(r<235)&(g>110)&(g<205)&(b>g+20)&(r>g+5)&(b>r+3)
        colors['scarf']=np.median(rgb[scarf],axis=0).tolist()
    return rgba,dict(file=path.name,bbox=[int(xx.min()),int(yy.min()),int(xx.max()+1),int(yy.max()+1)],soles=feet,head_center_x=head_center,colors=colors)

allrows={}
for age in ([a.stage] if a.stage else ['adult','baby']):
    work=ROOT/f'design/walk-v{a.version}/{a.species}/{age}'
    master=a.master.resolve() if a.master else ROOT/f'design/all-species-v3/masters/{a.species}/{age}.png'
    names=a.keys
    board=Image.new('RGB',(1280,280),'#fff8ed');d=ImageDraw.Draw(board);rows=[]
    for i,path in enumerate([master]+[work/n for n in names]):
        im,record=inspect(path);rows.append(record);im.thumbnail((256,256));board.paste(im,(i*256,24),im);d.text((i*256+4,5),'MASTER' if i==0 else path.name,fill='#513d32')
    board.save(work/(a.review_name+'.png'));(work/(a.review_name+'.json')).write_text(json.dumps(rows,indent=2),encoding='utf8')
    keys=[dict(file=n,ground=r['soles'][1 if i<2 else 0][1],soles=r['soles']) for i,(n,r) in enumerate(zip(names,rows[1:]))]
    n0,f0=keys[0]['soles'];n6,f6=keys[2]['soles'];x6=(f0[0]+n0[0]-f6[0]-n6[0])/2;x3=(f0[0]+f6[0]+x6)/2-keys[1]['soles'][1][0];x9=(n6[0]+x6+n0[0])/2-keys[3]['soles'][0][0]
    for k,x in zip(keys,[0,x3,x6,x9]):k['root_registration_x']=x
    progress=[]
    for first,last,side in [(0,1,1),(1,2,1),(2,3,0),(3,0,0)]:
        start=rows[first+1];end=rows[last+1]
        progress.append((start['soles'][side][0]-start['head_center_x'])-(end['soles'][side][0]-end['head_center_x']))
    # A diagnostic gate for this four-pose biped workflow, not a universal
    # naturalness score. Subpixel noise is handled in native review later.
    average=float(np.mean(progress));issues=[]
    contact_travel={'near':float(sum(progress[2:])), 'far':float(sum(progress[:2]))}
    smaller=min(contact_travel.values());larger=max(contact_travel.values())
    contact_ratio=larger/smaller if smaller>0 else None
    warnings=[]
    quarter_progress_ratio=max(progress)/min(progress) if min(progress)>0 else None
    if quarter_progress_ratio is not None and quarter_progress_ratio>3:
        warnings.append('Quarter-step progress differs by more than 3x. Inspect hesitation followed by a rushed step even when the minimum-progress gate passes; this ratio is diagnostic, not universal naturalness approval.')
    if contact_ratio is None or contact_ratio>2:
        warnings.append('Opposite contact travel is strongly unequal. Inspect the contact drawings before repeatedly correcting passing poses; projection can affect the ratio, so this is not a universal rejection threshold.')
    if average<=0: issues.append('Support motion does not move forward overall')
    if min(progress)<-3: issues.append('A supporting foot reverses relative to the head')
    if min(progress)<max(0,average*.2): issues.append('One quarter of the gait has too little body progress')
    # Passing drawings must have one lifted foot. A position-only gate can
    # otherwise accept two planted feet and produce a shuffling interpolation.
    passing_clearance=[keys[1]['soles'][1][1]-keys[1]['soles'][0][1],keys[3]['soles'][0][1]-keys[3]['soles'][1][1]]
    if min(passing_clearance)<=3:
        issues.append('A passing pose has no clearly lifted swing foot')
    elif min(passing_clearance)<8:
        warnings.append('A passing foot lifts less than 8 source pixels; inspect visibility at native game size.')
    ground_to_top=[k['ground']-r['bbox'][1] for k,r in zip(keys,rows[1:])]
    contact_height=(ground_to_top[0]+ground_to_top[2])/2
    passing_rise=[ground_to_top[1]-contact_height,ground_to_top[3]-contact_height]
    if abs(passing_rise[0]-passing_rise[1])>10:
        warnings.append('Opposite passing silhouettes rise by different amounts (>10 source pixels). Inspect head/body weight transfer; ear motion also affects this proxy.')
    plan=dict(allow_trial_bake=a.approve and not issues,review='Whole-image visual review AND source support progression required; numeric checks do not validate anatomy or final naturalness.',master_file=os.path.relpath(master,work).replace('\\','/'),master_height=rows[0]['bbox'][3]-rows[0]['bbox'][1],master_ground=max(s[1] for s in rows[0]['soles']),sole_regions=regions,keys=keys,source_gait_review=dict(support_progress_source_px=progress,runtime_intervals=['30-45','45-60','0-15','15-30'],issues=issues))
    plan['source_gait_review'].update(contact_travel_source_px=contact_travel,contact_travel_ratio=contact_ratio,quarter_progress_ratio=quarter_progress_ratio,passing_clearance_source_px=passing_clearance,ground_to_top_source_px=ground_to_top,passing_silhouette_rise_source_px=passing_rise,warnings=warnings)
    prior_path=work/'accepted-keys.json'
    if prior_path.exists():
        prior=json.loads(prior_path.read_text('utf8'))
        if 'reference_height' in prior: plan['reference_height']=prior['reference_height']
    (work/a.output_plan).write_text(json.dumps(plan,indent=2),encoding='utf8');allrows[age]=rows
    if a.approve and issues: raise SystemExit('Source gait review failed; trial gate remains closed: '+ '; '.join(issues))
print(json.dumps(allrows,indent=2))
