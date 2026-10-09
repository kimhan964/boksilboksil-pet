"""Bake reviewed complete costume cels to 60 frames; no separate limb animation.

Candidates stay in design/ until native playback and anatomy review pass.
Preserve the existing frame phases. Do not infer new cadence from frame count.
"""
import hashlib
import json
import subprocess
from pathlib import Path
import numpy as np
from PIL import Image
ROOT = Path(__file__).resolve().parents[1]
WORK = ROOT / 'design/wardrobe-v3/motion/rabbit/adult'
RIFE = Path('C:/Users/rlagk/.cache/rabbit-animation-tools/rife-20221029')

def unmatte(im):
    rgb = np.asarray(im.convert('RGB'), dtype=float)
    r, g, b = rgb[:,:,0], rgb[:,:,1], rgb[:,:,2]
    spill = np.minimum(r-g,b-g)
    # Generated mattes are textured magenta, not exactly (255, 0, 255).
    # Neither cream fur nor these garments contains magenta; reserve only
    # the transition range for antialiasing instead of retaining the matte.
    alpha = np.clip((180-spill)/120, 0, 1)
    alpha[alpha < .04] = 0
    border = np.concatenate([rgb[0], rgb[-1], rgb[:,0], rgb[:,-1]])
    matte = np.median(border, axis=0)
    safe = np.maximum(alpha,.001)
    out = np.empty((*alpha.shape,4),dtype=np.uint8)
    out[:,:,:3] = np.clip((rgb-(1-alpha[:,:,None])*matte)/safe[:,:,None],0,255)
    out[:,:,3] = np.rint(alpha*255)
    out[alpha == 0] = 0
    return Image.fromarray(out)

report = {}
for style in ['vest','knit','apron']:
    source = WORK / f'{style}-generated.png'
    atlas = Image.open(source).convert('RGB')
    assert atlas.width == atlas.height
    keys = [atlas.crop((i%4*atlas.width//4,i//4*atlas.height//4,(i%4+1)*atlas.width//4,(i//4+1)*atlas.height//4)).resize((256,256),Image.Resampling.LANCZOS) for i in range(16)]
    # Exact same neutral cel joins idle and walk, rather than a similar redraw.
    keys[12] = keys[0].copy()
    keys[15] = keys[0].copy()
    for bank, selected, phases in [('walk',list(range(8)),[0,8,16,23,30,38,45,53,60]), ('struggle',list(range(8,12)),[0,15,30,45,60]), ('idle',list(range(12,16)),[0,39,49,59,60])]:
        folder = WORK / style / bank
        folder.mkdir(parents=True,exist_ok=True)
        frames = []
        for k, key in enumerate(selected):
            count = phases[k+1]-phases[k]
            inp, out = folder / f'interval-{k}-in', folder / f'interval-{k}-out'
            inp.mkdir(exist_ok=True); out.mkdir(exist_ok=True)
            keys[key].save(inp/'0.png')
            keys[selected[(k+1)%len(selected)]].save(inp/'1.png')
            sig = hashlib.sha256((inp/'0.png').read_bytes()+(inp/'1.png').read_bytes()+str(count).encode()).hexdigest()
            stamp = out/'source.sha256'
            if count > 1 and (not stamp.exists() or stamp.read_text() != sig):
                result = subprocess.run([str(RIFE/'rife-ncnn-vulkan.exe'),'-i',str(inp),'-o',str(out),'-n',str(count*2),'-m',str(RIFE/'rife-v4.6'),'-g','0','-j','1:2:2','-z'],capture_output=True,text=True)
                if result.returncode: raise RuntimeError(result.stderr)
                stamp.write_text(sig)
            frames.extend([unmatte(keys[key])] if count==1 else [unmatte(Image.open(out/f'{j+1:08d}.png')) for j in range(count)])
        assert len(frames) == 60
        packed = Image.new('RGBA',(2048,2048))
        contact = Image.new('RGB',(1280,768),'#fff8ed')
        for i, cel in enumerate(frames):
            box = cel.getbbox()
            assert box and box[0]>1 and box[1]>1 and box[2]<255 and box[3]<255, (style,bank,i,box)
            packed.paste(cel,(i%8*256,i//8*256))
            thumb = cel.resize((128,128),Image.Resampling.LANCZOS)
            contact.paste(thumb,(i%10*128,i//10*128),thumb)
        packed.save(folder/'frames.png')
        contact.save(folder/'contact.png')
        report[f'{style}/{bank}'] = dict(count=60, distinct=len({hashlib.sha256(im.tobytes()).hexdigest() for im in frames}), source_key_count=len(selected), phases=phases, source=source.relative_to(ROOT).as_posix(), status='candidate_not_runtime_applied')
        print(f'BAKED {style}/{bank}: 60 complete cels',flush=True)
(WORK/'bake-report.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
