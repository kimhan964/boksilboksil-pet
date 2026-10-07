"""Prepare whole VARCO cels, fixed camera and offline RIFE inbetweens (no limb rig)."""
import argparse,json,subprocess,hashlib
from pathlib import Path
import numpy as np
from PIL import Image
ROOT=Path(__file__).resolve().parents[1]
RIFE=Path('C:/Users/rlagk/.cache/rabbit-animation-tools/rife-20221029')
def unmatte(im):
    rgb=np.array(im.convert('RGB'),dtype=np.float32)
    r,g,b=rgb[:,:,0],rgb[:,:,1],rgb[:,:,2]
    a=np.clip(1-(np.minimum(g-r,b-r)-8)/235,0,1)
    a[(r<70)&(g>160)&(b>160)]=0
    a[a<.035]=0
    result=np.empty((*a.shape,4),dtype=np.uint8)
    safe=np.maximum(a,.001)
    result[:,:,0]=np.clip(r/safe,0,255)
    result[:,:,1]=np.clip((g-(1-a)*255)/safe,0,255)
    result[:,:,2]=np.clip((b-(1-a)*255)/safe,0,255)
    result[:,:,3]=np.rint(a*255).astype(np.uint8)
    result[a==0]=0
    return Image.fromarray(result)
def build(species,age,source):
    folder=ROOT/'design/slapstick-varco-v1'/f'{species}-{age}'
    out=ROOT/'assets/slapstick-varco-v1'/species
    folder.mkdir(parents=True,exist_ok=True);out.mkdir(parents=True,exist_ok=True)
    base=ROOT/('assets/rabbit-frame-pilot-v9' if species=='rabbit' else f'assets/walk-v14/{species}')
    manifest=json.loads((base/'manifest.json').read_text(encoding='utf-8'))
    reference=Image.open(base/f'{age}-idle.png').convert('RGBA').crop((0,0,256,256))
    sheet=unmatte(Image.open(source))
    mask=np.array(sheet)[:,:,3]>128
    boxes=[]
    seen=np.zeros(mask.shape,dtype=bool)
    for y,x in zip(*np.where(mask)):
        if seen[y,x]: continue
        stack=[(int(x),int(y))]; seen[y,x]=True; xs=[];ys=[]
        while stack:
            cx,cy=stack.pop();xs.append(cx);ys.append(cy)
            for nx,ny in [(cx-1,cy),(cx+1,cy),(cx,cy-1),(cx,cy+1)]:
                if 0<=nx<mask.shape[1] and 0<=ny<mask.shape[0] and mask[ny,nx] and not seen[ny,nx]:
                    seen[ny,nx]=True;stack.append((nx,ny))
        if len(xs)>1500: boxes.append((min(xs),min(ys),max(xs)+1,max(ys)+1))
    if len(boxes)!=16: raise ValueError(f'Expected 16 complete characters, got {len(boxes)}')
    boxes.sort(key=lambda b:(b[1]+b[3])/2)
    boxes=[b for row in range(4) for b in sorted(boxes[row*4:row*4+4],key=lambda b:b[0])]
    refbox=reference.getbbox()
    factor=(refbox[3]-refbox[1])/(boxes[0][3]-boxes[0][1])
    widest=max(round((b[2]-b[0])*factor) for b in boxes)
    tallest=max(round((b[3]-b[1])*factor) for b in boxes)
    cell_size=max(256,((max(widest+16,tallest+40)+31)//32)*32)
    padding=(cell_size-256)//2
    if padding:
        padded=Image.new('RGBA',(cell_size,cell_size));padded.alpha_composite(reference,(padding,padding));reference=padded
    keys=[]
    for i,box in enumerate(boxes):
        # Crop only separated background; use ONE scale across all 16 full-body cels.
        crop=sheet.crop(box)
        crop=crop.resize((round(crop.width*factor),round(crop.height*factor)),Image.Resampling.LANCZOS)
        cel=Image.new('RGBA',(cell_size,cell_size))
        cel.alpha_composite(crop,(round(128+padding-crop.width/2),232+padding-crop.height))
        keys.append(cel)
    report={}
    for action,start in [('stumble',0),('sneeze',8)]:
        inp=folder/action/'input';dest=folder/action/'output'
        inp.mkdir(parents=True,exist_ok=True);dest.mkdir(parents=True,exist_ok=True)
        sequence=[reference]+keys[start+1:start+7]+[reference]
        if action=='stumble': sequence[6]=reference.copy()
        for i,cel in enumerate(sequence):
            bg=Image.new('RGB',(cell_size,cell_size),'cyan');bg.paste(cel,(0,0),cel);bg.save(inp/f'{i:08d}.png')
        run=subprocess.run([str(RIFE/'rife-ncnn-vulkan.exe'),'-i',str(inp),'-o',str(dest),'-n','60','-m',str(RIFE/'rife-v4.6'),'-g','0','-j','1:2:2'],capture_output=True,text=True)
        if run.returncode: raise RuntimeError(run.stderr[-2000:])
        paths=sorted(dest.glob('*.png'))
        if len(paths)!=60: raise ValueError('Wrong frame count')
        frames=[unmatte(Image.open(p)) for p in paths]
        frames[0]=reference.copy();frames[-1]=reference.copy()
        atlas=Image.new('RGBA',(cell_size*8,cell_size*8));distinct=set();gif=[]
        for i,frame in enumerate(frames):
            b=frame.getbbox()
            if not b or min(b[:2])<=0 or max(b[2:])>=cell_size: raise ValueError(f'Clipping frame {i}')
            atlas.paste(frame,(i%8*cell_size,i//8*cell_size));distinct.add(hashlib.sha256(frame.tobytes()).hexdigest())
            bg=Image.new('RGB',(cell_size,cell_size),'#faf8f3');bg.paste(frame,(0,0),frame);gif.append(bg)
        atlas.save(out/f'{age}-{action}.png')
        gif[0].save(folder/f'{action}.gif',save_all=True,append_images=gif[1:],duration=47 if action=='stumble' else 40,loop=0)
        contact=Image.new('RGB',(6*cell_size,cell_size),'#faf8f3')
        for k,n in enumerate([0,10,22,32,45,59]):contact.paste(gif[n],(k*cell_size,0))
        contact.save(folder/f'{action}-review.png')
        report[action]={'frames':60,'distinct':len(distinct),'clipped':0,'neutral_endpoints':True}
    (out/f'{age}.json').write_text(json.dumps({'cell_size':cell_size,'root':[128+padding,232+padding],'reference_height':manifest['stages'][age]['reference_height'],'method':'VARCO whole-character keys + offline RIFE v4.6 inbetweens','source':str(source),'validation':report},indent=2),encoding='utf-8')
    print(json.dumps({'species':species,'stage':age,**report}),flush=True)
if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('species');p.add_argument('age');p.add_argument('source',type=Path);a=p.parse_args();build(a.species,a.age,a.source)
