"""Measure generated age variants and retain a fixed-camera review board."""
import argparse,json,math
from pathlib import Path
import numpy as np
from PIL import Image,ImageDraw
ROOT=Path(__file__).resolve().parents[1];WORK=ROOT/'design/walk-v11'
p=argparse.ArgumentParser();p.add_argument('--plan',type=Path);a=p.parse_args()

def inspect(path):
    im=Image.open(path).convert('RGB').resize((1024,1024),Image.Resampling.LANCZOS);a=np.asarray(im);r,g,b=[a[:,:,i].astype(float) for i in range(3)]
    alpha=~((g>r+25)&(b>r+25)&(g>b-24));yy,xx=np.where(alpha)
    masks={'fur':(r>145)&(r<245)&(g>85)&(g<190)&(b>55)&(b<140)&(r>g*1.24)&(g>b*1.12),'cream':(r>235)&(g>215)&(b>160)&(b<230),'green':(g>r*1.03)&(r>60)&(r<190)&(b<120)}
    colors={k:np.median(a[m],axis=0).tolist() for k,m in masks.items()}
    rgba=im.convert('RGBA');rgba.putalpha(Image.fromarray((alpha*255).astype('uint8')))
    soles=[]
    for lo,hi in [(270,565),(565,920)]:
        sy,sx=np.where(alpha[790:970,lo:hi]);bottom=int(sy.max()+790);cy,cx=np.where(alpha[bottom-4:bottom+1,lo:hi]);soles.append([float(cx.mean()+lo),bottom])
    top=int(yy.min());head=[]
    for y in range(top+160,top+280):
        xs=np.where(alpha[y])[0]
        if len(xs):head.append(int(xs[-1]-xs[0]+1))
    return rgba,dict(file=str(path.relative_to(ROOT)),colors=colors,bbox=[int(xx.min()),top,int(xx.max()+1),int(yy.max()+1)],head_width=float(np.median(head)),soles=soles)

paths=[ROOT/'design/all-species-v3/masters/otter/adult.png',WORK/'tone-baby-master.png']+[WORK/f for f in ['baby-flat-00.png','tone-baby-03.png','baby-tone-06.png','tone-baby-09.png']]
if a.plan:
    plan_path=a.plan.resolve();plan=json.loads(plan_path.read_text('utf8'));WORK=plan_path.parent
    paths=[ROOT/'design/all-species-v3/masters/otter/adult.png',WORK/plan['master_file']]+[WORK/k['file'] for k in plan['keys']]
board=Image.new('RGB',(1024,math.ceil(len(paths)/4)*280),'#fff8ed');draw=ImageDraw.Draw(board);rows=[]
for i,path in enumerate(paths):
    im,m=inspect(path);rows.append(m);x=i%4*256;y=i//4*280
    thumb=im.resize((256,256),Image.Resampling.LANCZOS);board.paste(thumb,(x,y+24),thumb);draw.text((x+5,y+5),path.stem,fill='#513d32')
for row in rows[1:]:
    row['palette_delta_to_adult']={k:(np.array(c)-np.array(rows[0]['colors'][k])).tolist() for k,c in row['colors'].items()}
board.save(WORK/'palette-review.png');(WORK/'palette-review.json').write_text(json.dumps(rows,indent=2),encoding='utf8');print(json.dumps(rows,indent=2))
