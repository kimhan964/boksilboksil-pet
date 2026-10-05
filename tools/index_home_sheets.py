"""Index complete generated cels; never repaint, deform or recolor the assets."""
from pathlib import Path
import json
import numpy as np
from PIL import Image

ROOT=Path(__file__).resolve().parents[1]/'assets/home-v2'
ACTIONS=['rest','tea','read','nap','groom','music','play']

def spans(mask, wanted):
    edges=np.diff(np.r_[False,mask,False].astype(int))
    groups=list(zip(np.flatnonzero(edges==1),np.flatnonzero(edges==-1)))
    groups=[tuple(map(int,g)) for g in groups if g[1]-g[0]>3]
    while len(groups)>wanted:
        i=min(range(len(groups)-1),key=lambda i:groups[i+1][0]-groups[i][1])
        groups[i:i+2]=[(groups[i][0],groups[i+1][1])]
    if len(groups)!=wanted: raise ValueError(f'Expected {wanted} separated groups, found {groups}')
    return groups

def index(path, override=False):
    rgba=np.array(Image.open(path).convert('RGBA'));alpha=rgba[:,:,3]>40
    rows=spans(alpha.sum(axis=1)>8,2 if override else 7)
    age=path.stem.split('-')[0]
    ref=np.array(Image.open(ROOT/'references'/f'{path.parent.name}-{age}.png').convert('RGBA'))
    colors=ref[ref[:,:,3]>220,:3].astype(int)
    q=colors//24;values,counts=np.unique(q,axis=0,return_counts=True)
    fur=values[counts.argmax()]*24+12
    sequences={}
    for action,(top,bottom) in zip(['part1','part2'] if override else ACTIONS,rows):
        projection=alpha[top:bottom].sum(axis=0)
        # Very faint outlines / loose yarn can bridge adjacent sprites. Find
        # the transparent valley near each grid gutter, then keep all pixels
        # within that cell (including detached yarn and ear tips).
        width=rgba.shape[1]
        cuts=[0]
        count=3 if override else 6
        has_repair=not override and action=='play' and path.with_stem(age+'-play').exists()
        for i in range(1,count):
            expected=width*i/count
            lo=int(expected-width/count*.24);hi=int(expected+width/count*.24)
            scores=projection[lo:hi].astype(float)+abs(np.arange(lo,hi)-expected)*.015
            cut=lo+int(np.argmin(scores))
            if projection[cut]>max(12,(bottom-top)*.12) and not has_repair:
                raise ValueError(f'No safe gutter {path} {action}/{i}')
            cuts.append(cut)
        cuts.append(width)
        columns=list(zip(cuts[:-1],cuts[1:]))
        frames=[]
        for left,right in columns:
            x=left;y=max(0,top-2);end_x=right;end_y=min(rgba.shape[0],bottom+2)
            cell=rgba[y:end_y,x:end_x];mask=cell[:,:,3]>40
            fy,fx=np.where(mask)
            if len(fx)<500: raise ValueError(f'Empty cel {path} {action}')
            # Register the body without moving/drawing individual parts. The
            # fur centroid excludes the green book/yarn and locks body placement.
            fur_mask=(np.linalg.norm(cell[:,:,:3].astype(float)-fur,axis=2)<65)&mask
            cy,cx=np.where(fur_mask)
            root_x=float(np.median(cx)) if len(cx)>100 else float(np.median(fx))
            root_y=float(fy.max()+1)
            frames.append({'rect':[x,y,end_x-x,end_y-y],'anchor':[round(root_x,2),root_y],
                           'bounds':[int(fx.min()),int(fy.min()),int(fx.max()+1),int(fy.max()+1)]})
        sequences[action]=frames
    if override: return sequences['part1']+sequences['part2']
    first=sequences['rest'][0]['bounds']
    source_manifest=ROOT.parent/('rabbit-frame-pilot-v9/manifest.json' if path.parent.name=='rabbit' else f'walk-v14/{path.parent.name}/manifest.json')
    original=json.loads(source_manifest.read_text())['stages'][age]['reference_height']
    ref_y=np.where(ref[:,:,3]>40)[0]
    camera=(first[3]-first[1])*original/(ref_y.max()-ref_y.min()+1)
    result={'file':path.name,'reference_height':round(float(camera),3),'sequences':sequences,'columns':6,'rows':7,'authored_frames':42}
    repair=path.with_stem(age+'-play')
    if repair.exists():
        frames=index(repair,True)
        old=sequences['play'][0]['bounds'];new=frames[0]['bounds']
        ratio=(new[3]-new[1])/(old[3]-old[1])
        result['overrides']={'play':{'file':repair.name,'reference_height':round(float(camera)*ratio,3)}}
        result['sequences']['play']=frames
    return result

if __name__=='__main__':
    errors=[]
    for folder in ROOT.iterdir():
        if not folder.is_dir() or folder.name=='references': continue
        stages={}
        for stage in ['baby','adult']:
            path=folder/(stage+'.png')
            if path.exists():
                try: stages[stage]=index(path)
                except ValueError as error:
                    errors.append(str(error)); print('REJECTED',error)
        if stages:
            (folder/'manifest.json').write_text(json.dumps({'stages':stages},ensure_ascii=False,indent=2),encoding='utf-8')
            print(folder.name,','.join(stages),sum(s['authored_frames'] for s in stages.values()))
    (ROOT/'index-errors.json').write_text(json.dumps(errors,ensure_ascii=False,indent=2),encoding='utf-8')
    if errors: raise SystemExit(1)
