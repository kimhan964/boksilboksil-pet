"""Find empty atlas gutters and retain complete animal AND prop silhouettes."""
from pathlib import Path
import json
import numpy as np
from analyze_animation_atlas import ROOT, pixels, components

def cuts(projection, count):
    length=len(projection); result=[0]
    for i in range(1,count):
        mid=length*i/count; radius=length/count*.28
        lo,hi=int(mid-radius),int(mid+radius)
        # Prefer the middle of the widest empty gutter, avoiding an off-center
        # equal-grid cut through the feet or the edge of a house.
        options=[]; start=None
        for x in range(lo,hi+1):
            empty=x<hi and projection[x]==0
            if empty and start is None:start=x
            elif not empty and start is not None:
                options.append((x-start,-abs((x+start)/2-mid),(x+start)//2));start=None
        if not options: raise RuntimeError(f'No clear gutter near {mid}')
        result.append(max(options)[2])
    return result+[length]

manifest_path=ROOT/'assets/animation-regions.json'
manifest=json.loads(manifest_path.read_text(encoding='utf8'))
report=[]
for path in sorted((ROOT/'assets/interactions').glob('*.png')):
    print(path.name,flush=True)
    mask=pixels(path,True);h,w=mask.shape
    # Row heights vary: a canopy can extend below the next row's nominal cut.
    # Assign WHOLE connected silhouettes to cells; never cut through anatomy.
    groups=[[] for _ in range(32)]
    for component in components(mask):
        if component['area']<4:continue
        x,y,cw,ch=component['rect']
        if cw>w/8*1.4 or ch>h/4*1.5:raise RuntimeError(f'Merged neighboring frames: {path}:{component["rect"]}')
        col=min(7,max(0,int((x+cw/2)*8/w)));row=min(3,max(0,int((y+ch/2)*4/h)))
        groups[row*8+col].extend(component['runs'])
    regions=[]
    for index,runs in enumerate(groups):
        if sum(r[2]-r[1] for r in runs)<100:raise RuntimeError(f'Empty interaction {path}:{index}')
        x0=min(r[1] for r in runs);x1=max(r[2] for r in runs)
        y0=min(r[0] for r in runs);y1=max(r[0] for r in runs)+1
        regions.append({'rect':[max(0,x0-2),max(0,y0-2),min(w,x1+2)-max(0,x0-2),min(h,y1+2)-max(0,y0-2)],'body':[x0,y0,x1-x0,y1-y0],'runs':runs})
    key='res://'+path.relative_to(ROOT).as_posix()
    manifest[key]={'columns':8,'rows':4,'width':w,'height':h,'regions':regions}
    report.append({'path':key,'frames':len(regions),'method':'complete-silhouette groups'})
manifest_path.write_text(json.dumps(manifest,separators=(',',':')),encoding='utf8')
(ROOT/'builds/frame-audit/interaction-regions.json').write_text(json.dumps(report,indent=2),encoding='utf8')
print('INTERACTION_SHEETS',len(report),'FRAMES',sum(r['frames'] for r in report))
