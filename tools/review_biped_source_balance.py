"""Compare opposite support travel relative to the head in contact drawings."""
import json,argparse
from pathlib import Path
import numpy as np
from PIL import Image
ROOT=Path(__file__).resolve().parents[1];results=[]
p=argparse.ArgumentParser();p.add_argument('--output',default='design/walk-v12/latest-source-contact-balance.json');a=p.parse_args()
for species in ['otter','squirrel','raccoon','fox','bear','owl','penguin']:
    for stage in ['baby','adult']:
        folder=ROOT/'design/walk-v11' if species=='otter' else ROOT/f'design/walk-v12/{species}/{stage}'
        planfile=folder/('baby-accepted-keys.json' if species=='otter' and stage=='baby' else 'accepted-keys.json')
        current=ROOT/f'design/walk-v12/{species}/{stage}/accepted-keys.json'
        if species=='otter' and current.exists():
            current_plan=json.loads(current.read_text('utf8'))
            if current_plan.get('allow_trial_bake',False):
                folder=current.parent;planfile=current
        if not planfile.exists():continue
        plan=json.loads(planfile.read_text('utf8'));heads=[]
        # Extended banks include authored recoil/reach poses. Compare the same
        # contact/passing phases instead of treating array positions as phases.
        by_phase={key.get('phase_frame',i*15):key for i,key in enumerate(plan['keys'])}
        plan['keys']=[by_phase[phase] for phase in [0,15,30,45]]
        for key in plan['keys']:
            v=np.array(Image.open(folder/key['file']).convert('RGB').resize((1024,1024)),dtype=float);r,g,b=v[:,:,0],v[:,:,1],v[:,:,2]
            mask=~((g>r+25)&(b>r+25)&(g>b-24));ys,xs=np.where(mask)
            top=int(ys.min());end=int(top+.44*(ys.max()-top));m=mask[top:end];heads.append(float((m*np.arange(1024)[None,:]).sum()/m.sum()))
        start,end=plan['keys'][0]['soles'],plan['keys'][2]['soles'];near=(end[0][0]-heads[2])-(start[0][0]-heads[0]);far=(start[1][0]-heads[0])-(end[1][0]-heads[2])
        progress=[]
        for first,last,side in [(0,1,1),(1,2,1),(2,3,0),(3,0,0)]:
            progress.append((plan['keys'][first]['soles'][side][0]-heads[first])-(plan['keys'][last]['soles'][side][0]-heads[last]))
        results.append(dict(species=species,stage=stage,head_centers=heads,near_forward_source_px=near,far_backward_source_px=far,support_progress_source_px=progress,runtime_intervals=['30-45','45-60','0-15','15-30'],limits='Authored contacts and passing poses, head silhouette reference; not a foot identity or gait quality pass. Negative travel warrants visual review.'))
out=ROOT/a.output;out.write_text(json.dumps(results,indent=2),encoding='utf8');print(json.dumps(results,indent=2))
