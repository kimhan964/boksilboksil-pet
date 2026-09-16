"""Read-only pixel analysis. Emits region metadata, never changes source PNGs."""
from pathlib import Path
import json
import numpy as np
from PIL import Image

ROOT=Path(__file__).resolve().parents[1]

def components(mask):
    parents=[]; records=[]; previous=[]
    def find(i):
        while parents[i]!=i:
            parents[i]=parents[parents[i]]; i=parents[i]
        return i
    for y,line in enumerate(mask):
        changes=np.diff(np.r_[False,line,False].astype(np.int8))
        starts=np.flatnonzero(changes==1); ends=np.flatnonzero(changes==-1)
        current=[]; j=0
        for x,end in zip(starts,ends):
            x=int(x); end=int(end); i=len(parents); parents.append(i)
            while j<len(previous) and previous[j][1]<x: j+=1
            k=j
            while k<len(previous) and previous[k][0]<=end:
                a=find(i); b=find(previous[k][2]); parents[a]=b; k+=1
            records.append((i,y,x,end)); current.append((x,end,i))
        previous=current
    groups={}
    for i,y,x,end in records: groups.setdefault(find(i),[]).append([y,x,end])
    result=[]
    for runs in groups.values():
        area=sum(end-x for _,x,end in runs)
        x=min(r[1] for r in runs); right=max(r[2] for r in runs)
        top=runs[0][0]; bottom=runs[-1][0]+1
        result.append(dict(area=area,rect=[x,top,right-x,bottom-top],runs=runs))
    return sorted(result,key=lambda c:c['area'],reverse=True)

def pixels(path,keyed=False):
    rgba=np.asarray(Image.open(path).convert('RGBA')).astype(np.int16)
    mask=rgba[:,:,3]>16
    if keyed: mask &= np.minimum(rgba[:,:,0],rgba[:,:,2])-rgba[:,:,1]<140
    return mask

def audit(stage):
    rows=[]
    for path in sorted((ROOT/'builds/frame-audit'/stage).glob('*/*/*.png')):
        mask=pixels(path); comps=components(mask)
        issues=[]
        if not comps: issues.append('empty')
        else:
            edge=int(mask[0].sum()+mask[-1].sum()+mask[:,0].sum()+mask[:,-1].sum())
            if edge: issues.append('edge')
            fragments=[c for c in comps[1:] if c['area']>=4]
            if fragments: issues.append('separate_parts')
        rows.append(dict(frame=path.relative_to(ROOT/'builds/frame-audit'/stage).as_posix(),issues=issues,
                         components=[dict(area=c['area'],rect=c['rect']) for c in comps if c['area']>=4]))
    out=ROOT/'builds/frame-audit'/f'{stage}.json'; out.write_text(json.dumps(rows),encoding='utf8')
    print(json.dumps(dict(stage=stage,total=len(rows),edge=sum('edge' in r['issues'] for r in rows),
                         separate_parts=sum('separate_parts' in r['issues'] for r in rows))))

if __name__=='__main__':
    import sys
    audit(sys.argv[1] if len(sys.argv)>1 else 'before')
