"""Compute source-region manifests from complete silhouettes, not equal grid cuts."""
from analyze_animation_atlas import ROOT, components, pixels
import json

IDS=['rabbit','otter','squirrel','hedgehog','raccoon','fox','bear','owl','cat','puppy','hamster','panda','red_panda','lamb','koala','penguin']
SHEETS={f'assets/reactions/{id}.png':(8,8) for id in IDS}
SHEETS.update({f'assets/habits/{id}.png':(4,2) for id in IDS[:8]})
SHEETS.update({f'assets/habits/{kind}-{i}.png':(4,4) for kind in ['carry','sleep'] for i in range(2)})
SHEETS.update({f'assets/habits/new-friends-{i}.png':(8,4) for i in range(2)})
SHEETS.update({f'assets/babies/babies-{i}.png':(8,4) for i in range(4)})
SHEETS['assets/babies/puppy-toon-v2.png']=(4,2)
SHEETS['assets/babies/puppy-style-v3.png']=(8,4)
SHEETS.update({f'assets/babies/babies-toon-{i}.png':(8,4) for i in range(4)})
SHEETS.update({f'assets/babies/extra-{i}.png':(8,4) for i in range(4)})
SHEETS.update({f'assets/decor/species-{kind}.png':(4,4) for kind in ['toys','comfort']})
manifest={}; report=[]
SHEETS['assets/reactions/edge-repair.png']=(8,4)
if (ROOT/'assets/specials').exists():
    SHEETS.update({f'assets/specials/adult-{i}.png':(4,4) for i in range(4)})
for path,(cols,rows) in SHEETS.items():
    mask=pixels(ROOT/path,True); h,w=mask.shape; comps=components(mask)
    count=cols*rows; mains=comps[:count]
    if len(mains)<count or mains[-1]['area']<100:
        raise RuntimeError(f'Not enough complete figures: {path}')
    # Sort whole figures into rows by center, then left to right. No anatomy is
    # clipped even when a pose crosses its nominal cell boundary.
    mains.sort(key=lambda c:c['rect'][1]+c['rect'][3]*.5)
    ordered=[]
    for row in range(rows):
        group=mains[row*cols:(row+1)*cols]
        ordered.extend(sorted(group,key=lambda c:c['rect'][0]+c['rect'][2]*.5))
    regions=[]
    for c in ordered:
        x,y,cw,ch=c['rect']
        regions.append(dict(rect=[x,y,cw,ch],body=[x,y,cw,ch],runs=list(c['runs'])))
    # Keep detached gesture marks assigned to their closest figure, but never
    # borrow pixels from any other character's connected silhouette.
    extras=0
    for c in comps[count:]:
        if c['area']<4: continue
        x,y,cw,ch=c['rect']; cx=x+cw/2; cy=y+ch/2
        choices=[]
        for i,main in enumerate(ordered):
            a,b,mw,mh=main['rect']
            dx=max(a-cx,0,cx-a-mw); dy=max(b-cy,0,cy-b-mh)
            choices.append((dx*dx+dy*dy,i))
        dist,i=min(choices)
        if dist<(min(w/cols,h/rows)*.2)**2:
            regions[i]['runs'].extend(c['runs']); extras+=1
    for region in regions:
        runs=region['runs']; x=min(r[1] for r in runs); end=max(r[2] for r in runs)
        y=min(r[0] for r in runs); bottom=max(r[0] for r in runs)+1
        region['rect']=[max(0,x-2),max(0,y-2),min(w,end+2)-max(0,x-2),min(h,bottom+2)-max(0,y-2)]
    manifest['res://'+path]={'columns':cols,'rows':rows,'width':w,'height':h,'regions':regions}
    report.append(dict(path=path,frames=count,smallest=mains[-1]['area'],extras=extras))
out=ROOT/'assets/animation-regions.json'; out.write_text(json.dumps(manifest,separators=(',',':')),encoding='utf8')
(ROOT/'builds/frame-audit/regions-report.json').write_text(json.dumps(report,indent=2),encoding='utf8')
print(f'SHEETS={len(report)} FRAMES={sum(x[0]*x[1] for x in SHEETS.values())} MANIFEST_BYTES={out.stat().st_size}')
if (ROOT/'assets/interactions').exists():
    import runpy
    runpy.run_path(str(ROOT/'tools/build_interaction_regions.py'),run_name='__main__')
