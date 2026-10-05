"""Extract generated whole poses and bake fixed-camera, 60-cel held protests.

Only whole silhouettes are registered; no anatomical parts are animated.
"""
import argparse, hashlib, json, shutil, subprocess
from pathlib import Path
import numpy as np
from PIL import Image, ImageChops, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
RIFE = Path('C:/Users/rlagk/.cache/rabbit-animation-tools/rife-20221029')

def extract(path):
    sheet = Image.open(path).convert('RGBA'); w,h = sheet.size
    small = sheet.getchannel('A').resize((w//4,h//4)).point(lambda x:255 if x>96 else 0)
    objects = []
    for _ in range(400):
        ar=np.array(small); yy,xx=np.where(ar==255)
        if not len(xx): break
        ImageDraw.floodfill(small,(int(xx[0]),int(yy[0])),128,thresh=0)
        comp=np.array(small)==128; cy,cx=np.where(comp)
        if len(cx)>150:
            box=(max(0,int(cx.min())*4-8),max(0,int(cy.min())*4-8),min(w,(int(cx.max())+1)*4+8),min(h,(int(cy.max())+1)*4+8))
            mask=Image.fromarray((comp*255).astype('uint8')).filter(ImageFilter.MaxFilter(5)).resize((w,h),Image.Resampling.NEAREST)
            im=sheet.crop(box); im.putalpha(ImageChops.multiply(im.getchannel('A'),mask.crop(box)))
            objects.append((box,im))
        ar=np.array(small); ar[comp]=0; small=Image.fromarray(ar).copy()
    assert len(objects)==8, f'{path}: expected 8 separate figures, found {len(objects)}'
    objects.sort(key=lambda pair:(pair[0][1]+pair[0][3])/2)
    return [im for row in range(2) for _,im in sorted(objects[row*4:row*4+4],key=lambda pair:pair[0][0])]

def unmatte(im):
    rgb=np.asarray(im.convert('RGB'),dtype=float); r,g,b=rgb[:,:,0],rgb[:,:,1],rgb[:,:,2]
    alpha=np.ones(r.shape); spill=np.minimum(r-g,b-g); key=spill>60
    alpha[key]=1-np.clip(spill[key]/255,0,1); alpha[alpha<.025]=0
    safe=np.maximum(alpha,.001); rgba=np.empty((*alpha.shape,4),dtype=np.uint8)
    rgba[:,:,0]=np.clip((r-(1-alpha)*255)/safe,0,255); rgba[:,:,1]=np.clip(g/safe,0,255); rgba[:,:,2]=np.clip((b-(1-alpha)*255)/safe,0,255); rgba[:,:,3]=np.rint(alpha*255); rgba[alpha==0]=0
    return Image.fromarray(rgba)

def build(species,register_only=False):
    folder=ROOT/'design/struggle-v1'/species
    keys=extract(folder/'generated.png')
    dest=ROOT/'assets/struggle-v1'/species; dest.mkdir(parents=True,exist_ok=True)
    manifest={'version':1,'species':species,'method':'Generated whole poses, offline RIFE, no runtime blending or limb rigs','stages':{}}
    for row,stage in enumerate(['adult','baby']):
        work=folder/stage; work.mkdir(exist_ok=True)
        cels=keys[row*4:row*4+4]; measures=[]
        for im in cels:
            mask=np.array(im)[:,:,3]>128; yy,xx=np.where(mask)
            top=int(yy.min()); bottom=int(yy.max()+1)
            hy,hx=np.where(mask[top:round(top+(bottom-top)*.35)])
            measures.append({'top':top,'height':bottom-top,'head_x':float((hx.min()+hx.max())/2),'left':int(xx.min()),'right':int(xx.max()+1)})
        height=max(m['height'] for m in measures)
        scale=min(204/height, min(108/max(m['head_x']-m['left'],m['right']-m['head_x']) for m in measures))
        top=232-height*scale
        registered=[]
        for i,(im,m) in enumerate(zip(cels,measures)):
            im.save(work/f'source-{i}.png')
            fixed=Image.new('RGBA',(512,512))
            scaled=im.resize((round(im.width*scale*2),round(im.height*scale*2)),Image.Resampling.LANCZOS)
            fixed.alpha_composite(scaled,(round((128-m['head_x']*scale)*2),round((top-m['top']*scale)*2)))
            fixed.save(work/f'key-{i}.png')
            bg=Image.new('RGBA',fixed.size,(255,0,255,255)); bg.alpha_composite(fixed)
            path=work/f'rife-{i}.png'; bg.convert('RGB').save(path); registered.append(path)
        gallery=Image.new('RGB',(1024,280),'#fff8ed')
        for i in range(4):
            im=Image.open(work/f'key-{i}.png').resize((256,256)); gallery.paste(im,(i*256,24),im)
        gallery.save(work/'keys-review.png')
        (work/'registration.json').write_text(json.dumps({'camera_scale':scale,'reference_height':height*scale,'measurements':measures},indent=2))
        if register_only: continue
        images=[]
        for k in range(4):
            inp=work/f'interval-{k}-in'; out=work/f'interval-{k}-out'; inp.mkdir(exist_ok=True); out.mkdir(exist_ok=True)
            shutil.copyfile(registered[k],inp/'0.png'); shutil.copyfile(registered[(k+1)%4],inp/'1.png')
            sig=hashlib.sha256((inp/'0.png').read_bytes()+(inp/'1.png').read_bytes()).hexdigest(); stamp=out/'source.sha256'
            if not stamp.exists() or stamp.read_text()!=sig:
                run=subprocess.run([str(RIFE/'rife-ncnn-vulkan.exe'),'-i',str(inp),'-o',str(out),'-n','30','-m',str(RIFE/'rife-v4.6'),'-g','0','-j','1:2:2','-z'],capture_output=True,text=True)
                if run.returncode: raise RuntimeError(run.stderr)
                stamp.write_text(sig)
            images.extend(unmatte(Image.open(out/f'{j+1:08d}.png')).resize((256,256),Image.Resampling.LANCZOS) for j in range(15))
        atlas=Image.new('RGBA',(2048,2048)); clipped=[]
        for i,im in enumerate(images):
            box=im.getbbox()
            if not box or box[0]<=2 or box[1]<=2 or box[2]>=254 or box[3]>=254: clipped.append(i)
            atlas.paste(im,(i%8*256,i//8*256))
        assert not clipped,(species,stage,clipped)
        atlas.save(dest/f'{stage}.png')
        manifest['stages'][stage]={'file':f'{stage}.png','count':60,'columns':8,'reference_height':height*scale,'cycle_seconds':1.4,'root':[128,232],'grip':[128,top+height*scale*.45]}
        views=[]
        for im in images:
            bg=Image.new('RGBA',(256,256),'#fff8ed'); bg.alpha_composite(im); views.append(bg.convert('RGB'))
        views[0].save(work/'preview.gif',save_all=True,append_images=views[1:],duration=23,loop=0)
        contact=Image.new('RGB',(1280,768),'#fff8ed')
        for i,im in enumerate(views): contact.paste(im.resize((128,128)),(i%10*128,i//10*128))
        contact.save(work/'all-60-review.png')
        (work/'bake-review.json').write_text(json.dumps({'source_keys':4,'frames':60,'distinct':len({hashlib.sha256(im.tobytes()).hexdigest() for im in images}),'clipped':clipped,'visual_review':'pending'},indent=2))
        print('BAKED',species,stage,flush=True)
    if not register_only: (dest/'manifest.json').write_text(json.dumps(manifest,indent=2))

if __name__=='__main__':
    p=argparse.ArgumentParser(); p.add_argument('species',nargs='+'); p.add_argument('--register-only',action='store_true'); a=p.parse_args()
    for species in a.species: build(species,a.register_only)
