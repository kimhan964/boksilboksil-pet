"""Slice generated sprite atlases by connected silhouettes, without repainting pixels.

Keep all originals. Do not assume evenly spaced rows in image generator output.
"""
from pathlib import Path
import json
import numpy as np
from PIL import Image,ImageDraw,ImageFont,ImageFilter
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'assets/species-props-v2'
REVIEW=ROOT/'design/species-props-v2'
IDS='rabbit otter squirrel hedgehog raccoon fox bear owl cat puppy hamster panda red_panda lamb koala penguin'.split()
KINDS=['plant','lamp','cushion','shelter']

def components(mask):
    parent=[];runs=[];previous=[]
    def find(i):
        while parent[i]!=i:parent[i]=parent[parent[i]];i=parent[i]
        return i
    for y,row in enumerate(mask):
        edges=np.flatnonzero(np.diff(np.r_[False,row,False].astype(np.int8)))
        current=[];j=0
        for left,right in zip(edges[::2],edges[1::2]):
            idx=len(parent);parent.append(idx);runs.append((int(left),int(right),y))
            while j<len(previous) and previous[j][1]<left:j+=1
            k=j
            while k<len(previous) and previous[k][0]<=right:
                parent[find(previous[k][2])]=find(idx);k+=1
            current.append((left,right,idx))
        previous=current
    groups={}
    for i,(left,right,y) in enumerate(runs):
        key=find(i)
        g=groups.setdefault(key,{'area':0,'bbox':[left,y,right,y+1],'runs':[]})
        g['runs'].append((left,right,y))
        g['area']+=right-left;b=g['bbox']
        b[0]=min(b[0],left);b[1]=min(b[1],y);b[2]=max(b[2],right);b[3]=max(b[3],y+1)
    return list(groups.values())

def slices(path,count):
    img=Image.open(path).convert('RGBA');a=np.array(img)
    assert np.count_nonzero(a[:,:,3]==0)>a.shape[0]*a.shape[1]*.12,'Missing true transparency'
    parts=components(a[:,:,3]>=24)
    main=sorted(parts,key=lambda p:p['area'],reverse=True)[:count]
    assert len(main)==count and min(p['area'] for p in main)>2500,'Missing sprite silhouettes'
    center=lambda p:((p['bbox'][0]+p['bbox'][2])/2,(p['bbox'][1]+p['bbox'][3])/2)
    main.sort(key=lambda p:center(p)[1])
    ordered=[]
    for row in range(count//4):ordered.extend(sorted(main[row*4:row*4+4],key=lambda p:center(p)[0]))
    boxes=[list(p['bbox']) for p in ordered]
    result=[]
    for i,b in enumerate(boxes):
        assert 0<b[0]<b[2]<img.width and 0<b[1]<b[3]<img.height,f'Atlas edge clipping {path.name}/{i}: {b}'
        box=(max(0,b[0]-3),max(0,b[1]-3),min(img.width,b[2]+3),min(img.height,b[3]+3))
        # Select this complete connected object, preserving its RGB and edge alpha.
        # Atlas noise and neighboring objects must not enter the individual sprite.
        mask=Image.new('L',img.size);md=ImageDraw.Draw(mask)
        for left,right,y in ordered[i]['runs']:md.line((left,y,right-1,y),fill=255)
        mask=mask.filter(ImageFilter.MaxFilter(3))
        pixels=a.copy();pixels[:,:,3]=np.where(np.array(mask)>0,a[:,:,3],0)
        crop=Image.fromarray(pixels).crop(box)
        canvas=Image.new('RGBA',(crop.width+12,crop.height+12));canvas.paste(crop,(6,6))
        result.append(canvas)
    return result,boxes

def montage(directory,target):
    canvas=Image.new('RGB',(1000,16*132+45),'#faf8f3');draw=ImageDraw.Draw(canvas)
    font=ImageFont.truetype('C:/Windows/Fonts/malgun.ttf',15)
    for j,kind in enumerate(KINDS):draw.text((105+j*225,12),kind,fill='#59564f',font=font)
    for row,id in enumerate(IDS):
        draw.text((8,65+row*132),id,fill='#59564f',font=font)
        for col,kind in enumerate(KINDS):
            im=Image.open(directory/(id+'-'+kind+'.png')).convert('RGBA');im.thumbnail((158,105),Image.Resampling.LANCZOS)
            x=130+col*218+(158-im.width)//2;y=43+row*132+(105-im.height)//2
            canvas.paste(im,(x,y),im)
    target.parent.mkdir(parents=True,exist_ok=True);canvas.save(target)

def main():
    toys,tb=slices(OUT/'toys-atlas.png',16)
    comforts,cb=slices(OUT/'comfort-atlas.png',16)
    homes,hb=slices(OUT/'homes-atlas.png',16)
    existing,eb=slices(ROOT/'assets/decor/cozy-props-v1.png',24)
    manifest={'version':'species-props-v2-20261009','animals':{},'atlas_regions':{'toys':tb,'comfort':cb,'homes':hb,'cozy_reused':eb}}
    after=REVIEW/'after';after.mkdir(parents=True,exist_ok=True)
    for i,id in enumerate(IDS):
        art={'plant':toys[i],'lamp':comforts[i],
             'cushion':existing[i] if i<8 else homes[i-8],
             'shelter':existing[i+8] if i<8 else homes[i]}
        manifest['animals'][id]={}
        for kind,image in art.items():
            p=OUT/(id+'-'+kind+'.png');image.save(p)
            image.save(after/p.name)
            manifest['animals'][id][kind]='res://'+p.relative_to(ROOT).as_posix()
    (OUT/'manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
    montage(REVIEW/'before',REVIEW/'before-contact.jpg')
    montage(after,REVIEW/'after-contact.jpg')
    print('Prepared 64 individually cropped props; source pixels and alpha preserved')
if __name__=='__main__':main()
