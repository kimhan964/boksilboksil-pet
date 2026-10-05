"""Inspect pet/prop native renders at their recorded desktop positions.

Composites preserve recorded pixel scale and position, but are not OS screenshots
and do not establish native-window stacking order. Mouth coordinates are authored
anchors: treat proximity estimates as a diagnostic, then inspect actual artwork.
"""
import argparse,json
from pathlib import Path
import numpy as np
from PIL import Image,ImageDraw

ROOT=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser();p.add_argument('--source',default=str(ROOT));p.add_argument('--output',default='design/all-animal-motion-review/dining-native-owl');p.add_argument('--report',default='dining-native-report.json');a=p.parse_args()
source=Path(a.source);out=ROOT/a.output;out.mkdir(parents=True,exist_ok=True)
report=json.loads((source/a.report).read_text('utf8'))
results=[]
for case in report['results']:
    frames=case['frames'];images=[];bounds=[];water_distances=[]
    for f in frames:
        pet=Image.open(source/f['file']).convert('RGBA');prop=Image.open(source/f['prop_file']).convert('RGBA')
        locations=[(pet,f['window']),(prop,f['prop_window'])]
        for im,pos in locations:
            b=im.getbbox()
            if b:bounds.append((pos[0]+b[0],pos[1]+b[1],pos[0]+b[2],pos[1]+b[3]))
        images.append(locations)
        if case['prop']=='water' and f['phase']=='drink':
            arr=np.asarray(prop).astype(float)
            mask=(arr[:,:,3]>128)&(arr[:,:,2]>arr[:,:,0]*1.08)&(arr[:,:,1]>arr[:,:,0]*1.05)
            yy,xx=np.where(mask)
            if len(xx):
                dx=xx+f['prop_window'][0]-f['mouth_world'][0]
                dy=yy+f['prop_window'][1]-f['mouth_world'][1]
                water_distances.append(float(np.hypot(dx,dy).min()))
    left=min(b[0] for b in bounds)-10;top=min(b[1] for b in bounds)-10
    right=max(b[2] for b in bounds)+10;bottom=max(b[3] for b in bounds)+10
    composites=[]
    for locations in images:
        im=Image.new('RGBA',(int(right-left),int(bottom-top)),'#fff8ed')
        for tile,pos in reversed(locations):im.alpha_composite(tile,(int(pos[0]-left),int(pos[1]-top)))
        composites.append(im.convert('RGB'))
    requested=case['requested_action'];action=[i for i,f in enumerate(frames) if f['phase']==requested]
    walking=[i for i,f in enumerate(frames) if f['phase']=='visit']
    picks=[0,walking[-1] if walking else 0]
    for age in [.05,.3,.7,1.2,1.8,2.4,3.2,5.3]:
        picks.append(min(action,key=lambda i:abs(frames[i]['action_elapsed']-age)) if action else 0)
    picks.extend([min(len(frames)-1,(action[-1]+1) if action else 0),len(frames)-1])
    tilew=max(300,composites[0].width);tileh=max(190,composites[0].height+24)
    board=Image.new('RGB',(tilew*4,tileh*3),'#fff8ed');draw=ImageDraw.Draw(board)
    for n,i in enumerate(picks):
        x=n%4*tilew;y=n//4*tileh
        board.paste(composites[i],(x,y+24))
        f=frames[i];draw.text((x+4,y+4),f"{f['phase']} / {f['action']} {f['index']} t={f['time']:.2f}",fill='#513d32')
    name=f"{case['species']}-{case['stage']}-{case['prop']}"
    board.save(out/f'{name}-contact.png')
    durations=[max(10,round((frames[min(i+1,len(frames)-1)]['time']-frames[i]['time'])*1000)) for i in range(len(frames))]
    composites[0].save(out/f'{name}.gif',save_all=True,append_images=composites[1:],duration=durations,loop=0)
    item={k:case[k] for k in ['species','stage','prop','modern_walk','travel_timed_out']}
    item.update(captures=len(frames),rendered_actions=sorted({f['action'] for f in frames}),requested_action_cels=sorted({f['index'] for f in frames if f['phase']==requested}),
                water_anchor_gap_px=[min(water_distances),max(water_distances)] if water_distances else None,
                arrival_error_px=float(np.linalg.norm(np.array(frames[action[0]]['feet'])-np.array(frames[action[0]]['target']))) if action else None)
    results.append(item)
summary=dict(renderer=report['renderer'],cases=len(results),captures=sum(r['captures'] for r in results),results=results,limits=__doc__)
(out/'review.json').write_text(json.dumps(summary,indent=2),encoding='utf8')
(out/a.report).write_text((source/a.report).read_text('utf8'),encoding='utf8')
print(json.dumps(summary,indent=2))
