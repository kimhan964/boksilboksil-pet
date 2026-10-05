"""Extract whole animation cells and measure foot paths before baking."""
import argparse,json
from pathlib import Path
import numpy as np
from PIL import Image,ImageDraw
p=argparse.ArgumentParser();p.add_argument('sheet',type=Path);p.add_argument('out',type=Path);a=p.parse_args()
a.out.mkdir(parents=True,exist_ok=True)
im=Image.open(a.sheet).convert('RGB');w,h=im.size
gallery=Image.new('RGB',(1024,900),'#fff8ed');d=ImageDraw.Draw(gallery);records=[]
for i in range(12):
 c=im.crop((round(i%4*w/4),round(i//4*h/3),round((i%4+1)*w/4),round((i//4+1)*h/3))).resize((1024,1024),Image.Resampling.LANCZOS)
 rgb=np.asarray(c).astype(float);mask=~((rgb[:,:,1]>rgb[:,:,0]+35)&(rgb[:,:,2]>rgb[:,:,0]+35))
 yy,xx=np.where(mask);box=[int(xx.min()),int(yy.min()),int(xx.max()+1),int(yy.max()+1)]
 feet=[]
 for lo,hi in [(270,540),(545,830)]:
  ys,xs=np.where(mask[750:,lo:hi]);bottom=int(ys.max()+750) if len(ys) else 750
  sy,sx=np.where(mask[bottom-5:bottom+1,lo:hi]);feet.append([float(sx.mean()+lo),bottom])
 rec=dict(index=i,file=f'key-{i:02d}.png',bbox=box,feet=feet);records.append(rec);c.save(a.out/rec['file'])
 x=i%4*256;y=i//4*300;gallery.paste(c.resize((256,256)),(x,y+20));d.text((x+8,y+4),str(i),fill='#222')
 d.text((x+4,y+278),' / '.join(f'{f[0]:.0f},{f[1]:.0f}' for f in feet),fill='#222')
gallery.save(a.out/'review.png');(a.out/'measurements.json').write_text(json.dumps(records,indent=2),encoding='utf8')
print(json.dumps(records,indent=2))
