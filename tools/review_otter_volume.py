"""Compare whole-character silhouettes at equal height; never alter game artwork."""
import json
from pathlib import Path
import numpy as np
from PIL import Image,ImageDraw
ROOT=Path(__file__).resolve().parents[1]
work=ROOT/'design/walk-v8'
def subject(im):
    rgb=np.asarray(im.convert('RGB'));r,g,b=[rgb[:,:,i].astype(float) for i in range(3)]
    mask=~((g>r+25)&(b>r+25)&(g>b-24))
    yy,xx=np.where(mask);box=(int(xx.min()),int(yy.min()),int(xx.max()+1),int(yy.max()+1))
    out=im.convert('RGBA');out.putalpha(Image.fromarray((mask*255).astype('uint8')))
    crop=mask[box[1]:box[3],box[0]:box[2]]
    def width_at(a,b):
        widths=[]
        for row in crop[int(len(crop)*a):int(len(crop)*b)]:
            x=np.where(row)[0];widths.append(float(x.max()-x.min()+1) if len(x) else 0)
        return float(np.median(widths))
    head=width_at(.15,.4);body=width_at(.55,.69)
    return out.crop(box),dict(head_width=head,body_width=body,body_to_head=body/head)
master=Image.open(ROOT/'design/all-species-v3/masters/otter/adult.png')
thin=Image.open(ROOT/'design/walk-v7/rejected-thin-12.png')
fresh=Image.open(work/'otter-finished-12.png')
samples=[('MASTER',master),('REJECTED',thin.crop((0,0,thin.width//4,thin.height//3)))]
for i in [0,4,8]:
    cw=fresh.width//4;ch=fresh.height//3;samples.append((f'REVISED {i}',fresh.crop((i%4*cw,i//4*ch,(i%4+1)*cw,(i//4+1)*ch))))
canvas=Image.new('RGB',(5*230,270),'#fff8ed');draw=ImageDraw.Draw(canvas);report=[]
for i,(name,im) in enumerate(samples):
    cut,measure=subject(im);f=200/cut.height;cut=cut.resize((round(cut.width*f),200),Image.Resampling.LANCZOS)
    canvas.paste(cut,(i*230+(230-cut.width)//2,45),cut);draw.text((i*230+12,12),name,fill='#513d32');report.append(dict(name=name,**measure))
canvas.save(work/'body-volume-comparison.png');(work/'body-volume-review.json').write_text(json.dumps(report,indent=2),encoding='utf8');print(json.dumps(report,indent=2))
