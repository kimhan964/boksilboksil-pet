"""Bake whole-character costume edits, preserving authored time phases.

This is asset preparation, not a limb rig: original and generated complete
cels stay together. Strip the generated matte BEFORE optical flow so its
texture cannot bleed into moving paws. Only the selected runtime bank loads.
"""
import argparse, hashlib, json, subprocess
from pathlib import Path
import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
WORK = ROOT / 'design/wardrobe-v3/motion/rabbit/adult'
DEST = ROOT / 'assets/wardrobe-motion-v3/rabbit/adult'
RIFE = Path('C:/Users/rlagk/.cache/rabbit-animation-tools/rife-20221029')

def key_generated(im):
    rgb = np.asarray(im.convert('RGB'), dtype=np.float32)
    spill = np.minimum(rgb[:,:,0]-rgb[:,:,1], rgb[:,:,2]-rgb[:,:,1])
    alpha = np.clip((180-spill)/120, 0, 1)
    alpha[alpha < .04] = 0
    border = np.concatenate([rgb[0],rgb[-1],rgb[:,0],rgb[:,-1]])
    matte = np.median(border,axis=0)
    color = np.clip((rgb-(1-alpha[:,:,None])*matte)/np.maximum(alpha[:,:,None],.001),0,255)
    # Chroma-key spill is absent from cream/sage/peach/blue costume colors.
    # Remove residual magenta only; never alter yellow/cream or blue cloth.
    contamination = np.maximum(0,np.minimum(color[:,:,0]-color[:,:,1],color[:,:,2]-color[:,:,1]))
    color[:,:,2] -= contamination
    out = np.concatenate([color,alpha[:,:,None]*255],axis=2).astype('uint8')
    out[alpha==0] = 0
    return Image.fromarray(out)

def matte(im):
    bg=Image.new('RGBA',im.size,(255,0,255,255));bg.alpha_composite(im)
    return bg.convert('RGB')

def key_flow(im):
    rgb=np.asarray(im.convert('RGB'),dtype=np.float32)
    spill=np.maximum(0,np.minimum(rgb[:,:,0]-rgb[:,:,1],rgb[:,:,2]-rgb[:,:,1]))
    alpha=1-spill/255
    alpha[alpha<.025]=0
    color=np.clip((rgb-(1-alpha[:,:,None])*np.array([255,0,255]))/np.maximum(alpha[:,:,None],.001),0,255)
    out=np.concatenate([color,alpha[:,:,None]*255],axis=2).astype('uint8');out[alpha==0]=0
    return Image.fromarray(out)

def interpolate(a,b,count,folder,endpoint=False):
    inp,out=folder/'in',folder/'out';inp.mkdir(parents=True,exist_ok=True);out.mkdir(exist_ok=True)
    matte(a).save(inp/'0.png');matte(b).save(inp/'1.png')
    signature=hashlib.sha256((inp/'0.png').read_bytes()+(inp/'1.png').read_bytes()+str(count).encode()).hexdigest()
    stamp=out/'source.sha256'
    if count>1 and (not stamp.exists() or stamp.read_text()!=signature):
        run=subprocess.run([str(RIFE/'rife-ncnn-vulkan.exe'),'-i',str(inp),'-o',str(out),'-n',str(count*2),'-m',str(RIFE/'rife-v4.6'),'-g','0','-j','1:2:2','-z'],capture_output=True,text=True)
        if run.returncode: raise RuntimeError(run.stderr)
        stamp.write_text(signature)
    result=[a.copy()]+[key_flow(Image.open(out/f'{j+1:08d}.png')) for j in range(1,count)]
    return result+[b.copy()] if endpoint else result

def pack(frames,style,bank):
    path=DEST/style;path.mkdir(parents=True,exist_ok=True)
    side=frames[0].width
    atlas=Image.new('RGBA',(side*8,side*((len(frames)+7)//8)))
    contact=Image.new('RGB',(1280,128*((len(frames)+9)//10)),'#fff8ed')
    for i,im in enumerate(frames):
        box=im.getbbox()
        assert im.size==(side,side)
        assert box and box[0]>1 and box[1]>1 and box[2]<side-1 and box[3]<side-1,(style,bank,i,box)
        atlas.paste(im,(i%8*side,i//8*side))
        thumb=im.resize((128,128),Image.Resampling.LANCZOS);contact.paste(thumb,(i%10*128,i//10*128),thumb)
    atlas.save(path/f'{bank}.png')
    review=WORK/'short-paws-baked'/style;review.mkdir(parents=True,exist_ok=True)
    contact.save(review/f'{bank}-contact.png')
    return {'file':f'{style}/{bank}.png','count':len(frames),'columns':8,'cell_size':side,'padding':[(side-256)//2]*2,'sha256':hashlib.sha256(atlas.tobytes()).hexdigest(),'clipped_frames':0}

def build(styles):
    manifest={'version':3,'species':'rabbit','stage':'adult','preview_only':True,'method':'complete generated cels, offline optical flow, no runtime limb separation','styles':{}}
    for style in styles:
        sheet=Image.open(WORK/f'{style}-short-paws-generated.png')
        size=sheet.width//4
        keys=[key_generated(sheet.crop((i%4*size,i//4*size,i%4*size+size,i//4*size+size))).resize((256,256),Image.Resampling.LANCZOS) for i in range(16)]
        keys[12]=keys[0].copy();keys[15]=keys[0].copy()
        spec={}
        for bank,indices,phases in [('walk',range(8),[0,8,16,23,30,38,45,53,60]),('struggle',range(8,12),[0,15,30,45,60]),('idle',range(12,16),[0,39,49,59,60])]:
            indices=list(indices);frames=[]
            for k,index in enumerate(indices):
                frames+=interpolate(keys[index],keys[indices[(k+1)%len(indices)]],phases[k+1]-phases[k],WORK/'short-paws-baked'/style/bank/str(k))
            assert len(frames)==60
            spec[bank]=pack(frames,style,bank)
            print(f'WARDROBE {style}/{bank}: 60 cels, clip check passed',flush=True)
        manifest['styles'][style]=spec
    (DEST/'manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')

if __name__=='__main__':
    args=argparse.ArgumentParser();args.add_argument('--styles',nargs='+',default=['vest','knit','apron']);opt=args.parse_args();build(opt.styles)
