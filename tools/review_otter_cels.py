"""Inspect full cels against the approved otter without hiding scale drift."""
import argparse,json
from pathlib import Path
import numpy as np
from PIL import Image,ImageDraw
ROOT=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser();p.add_argument('--version',type=int,default=10);a=p.parse_args()
work=ROOT/f'design/walk-v{a.version}'
def extract(path):
    im=Image.open(path).convert('RGB').resize((1024,1024),Image.Resampling.LANCZOS)
    rgb=np.asarray(im).astype(float);r,g,b=rgb[:,:,0],rgb[:,:,1],rgb[:,:,2]
    mask=~((g>r+25)&(b>r+25)&(g>b-24));yy,xx=np.where(mask)
    rgba=im.convert('RGBA');rgba.putalpha(Image.fromarray((mask*255).astype('uint8')))
    head=[];body=[]
    for y in range(260,470):
        xs=np.where(mask[y])[0]
        if len(xs):head.append(int(xs[-1]-xs[0]+1))
    for y in range(560,660):
        xs=np.where(mask[y])[0]
        if len(xs):body.append(int(xs[-1]-xs[0]+1))
    soles=[];sole_x=[]
    for lo,hi in [(300,550),(560,890)]:
        fy,fx=np.where(mask[790:960,lo:hi]);bottom=int(fy.max()+790) if len(fy) else None;soles.append(bottom)
        by,bx=np.where(mask[bottom-4:bottom+1,lo:hi]);sole_x.append(float(bx.mean()+lo))
    return rgba,dict(bbox=[int(xx.min()),int(yy.min()),int(xx.max()+1),int(yy.max()+1)],head_width=float(np.median(head)),body_width=float(np.median(body)),tail_side_bottom=soles[0],scarf_side_bottom=soles[1],tail_sole_x=sole_x[0],scarf_sole_x=sole_x[1])
paths=[ROOT/'design/all-species-v3/masters/otter/adult.png']+sorted(work.glob('pose-*.png'))
canvas=Image.new('RGB',(256*min(4,len(paths)),280*((len(paths)+3)//4)),'#fff8ed');draw=ImageDraw.Draw(canvas);records=[]
for i,path in enumerate(paths):
    im,metrics=extract(path);thumb=im.resize((256,256),Image.Resampling.LANCZOS);x=i%4*256;y=i//4*280
    canvas.paste(thumb,(x,y+24),thumb);draw.text((x+8,y+5),'MASTER' if i==0 else path.stem,fill='#513d32')
    records.append(dict(file=str(path),**metrics))
master=records[0]
for r in records[1:]:
    r['body_width_ratio_to_master']=r['body_width']/master['body_width']
    r['head_width_ratio_to_master']=r['head_width']/master['head_width']
    r['volume_check']=.92<r['body_width_ratio_to_master']<1.08 and .92<r['head_width_ratio_to_master']<1.08
canvas.save(work/'representative-review.png');(work/'representative-review.json').write_text(json.dumps(records,indent=2),encoding='utf8');print(json.dumps(records,indent=2))
