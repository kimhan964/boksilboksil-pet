"""Extract generated full-character cels for inspection; no anatomical edits."""
import argparse,json
from pathlib import Path
import numpy as np
from PIL import Image,ImageDraw,ImageFilter,ImageChops
p=argparse.ArgumentParser();p.add_argument('sheet',type=Path);p.add_argument('out',type=Path);p.add_argument('--columns',type=int,default=4);p.add_argument('--rows',type=int,default=2);p.add_argument('--components',action='store_true');a=p.parse_args()
a.out.mkdir(parents=True,exist_ok=True)
sheet=Image.open(a.sheet).convert('RGBA');w,h=sheet.size;records=[]
cells=[]
if a.components:
    # Layouts can drift a few pixels across a nominal grid boundary. Locate
    # complete silhouettes before cropping, so a curled tail is never severed.
    small=sheet.getchannel('A').resize((w//4,h//4)).point(lambda x:255 if x>96 else 0)
    boxes=[];isolated={}
    for attempt in range(300):
        ar=np.array(small);yy,xx=np.where(ar==255)
        if not len(xx):break
        ImageDraw.floodfill(small,(int(xx[0]),int(yy[0])),128,thresh=0)
        comp=np.array(small)==128;cy,cx=np.where(comp)
        if len(cx)>100:
            box=(max(0,int(cx.min())*4-6),max(0,int(cy.min())*4-6),min(w,(int(cx.max())+1)*4+6),min(h,(int(cy.max())+1)*4+6))
            boxes.append(box)
            # Bounding rectangles can overlap the neighbouring sprite's tail.
            # Keep only this whole silhouette, with an 8px antialias margin.
            isolated[box]=Image.fromarray((comp*255).astype('uint8')).filter(ImageFilter.MaxFilter(5)).resize((w,h),Image.Resampling.NEAREST)
        ar=np.array(small);ar[comp]=0;small=Image.fromarray(ar).copy()
    assert len(boxes)==a.columns*a.rows, f'Expected separate whole sprites, found {len(boxes)}'
    boxes.sort(key=lambda b:(b[1]+b[3])/2)
    ordered=[]
    for row in range(a.rows):ordered+=sorted(boxes[row*a.columns:(row+1)*a.columns],key=lambda b:b[0])
    side=max(max(b[2]-b[0],b[3]-b[1]) for b in ordered)+32
    for box in ordered:
        crop=sheet.crop(box);crop.putalpha(ImageChops.multiply(crop.getchannel('A'),isolated[box].crop(box)))
        cell=Image.new('RGBA',(side,side));cell.alpha_composite(crop,((side-crop.width)//2,side-crop.height-16));cells.append(cell)
gallery=Image.new('RGB',(a.columns*320,a.rows*370),'#fff7ec');d=ImageDraw.Draw(gallery)
for i in range(a.columns*a.rows):
    im=cells[i] if cells else sheet.crop((round(i%a.columns*w/a.columns),round(i//a.columns*h/a.rows),round((i%a.columns+1)*w/a.columns),round((i//a.columns+1)*h/a.rows)))
    im.save(a.out/f'key-{i:02d}.png');mask=np.asarray(im)[:,:,3]>128
    yy,xx=np.where(mask);box=[int(xx.min()),int(yy.min()),int(xx.max()+1),int(yy.max()+1)]
    top=box[1];bottom=box[3];height=bottom-top
    head=mask[top:round(top+height*.42)];hy,hx=np.where(head);left=int(hx.min());right=int(hx.max());center=(left+right)/2
    feet=[]
    for lo,hi in [(int(left+(right-left)*.02),int(center)),(int(center),min(im.width,int(right+10)))]:
        ys,xs=np.where(mask[round(bottom-height*.16):,lo:hi]);sole=int(ys.max()+round(bottom-height*.16))
        sy,sx=np.where(mask[sole-4:sole+1,lo:hi]);feet.append([round(float(sx.mean()+lo),3),sole])
    records.append(dict(index=i,file=f'key-{i:02d}.png',bbox=box,head_center_x=center,head_width=right-left,feet=feet))
    preview=im.resize((320,320));x=i%a.columns*320;y=i//a.columns*370
    gallery.paste(preview,(x,y+25),preview);d.text((x+8,y+5),f'Key {i}',fill='#302820')
    d.text((x+8,y+346),f'feet {feet}; head {right-left}',fill='#302820')
gallery.save(a.out/'review.png');(a.out/'measurements.json').write_text(json.dumps(records,indent=2),encoding='utf8')
print(json.dumps(records,indent=2))
