"""Bake bridges between complete existing cels using exact runtime calibration."""
import argparse,json,hashlib,subprocess
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor
import numpy as np
from PIL import Image,ImageDraw
from build_struggle_v1 import unmatte,RIFE
ROOT=Path(__file__).resolve().parents[1]
IDS='rabbit otter squirrel hedgehog raccoon fox bear owl cat puppy hamster panda red_panda lamb koala penguin'.split()
PAIRS={'pickup':('idle','carry'),'idle_entry':('idle','kick0'),'carry_entry':('carry','kick0'),'recover':('dizzy3','idle'),**{f'release{i}':(f'kick{i}','dizzy0') for i in range(4)}}
COUNT=17
def build_case(args):
    species,stage=args
    folder=ROOT/'design/hold-transitions-v1'/species/stage
    meta=json.loads((folder/'poses.json').read_text()); poses={}
    for name,spec in meta.items():
        source=Image.open(folder/f'{name}.png').convert('RGBA')
        sx,sy=[200/spec['height']*v for v in spec['scale']]
        canvas=Image.new('RGBA',(256,256)); scaled=source.resize((round(256*sx),round(256*sy)),Image.Resampling.LANCZOS)
        canvas.alpha_composite(scaled,(round(128-spec['anchor'][0]*sx),round(232-spec['anchor'][1]*sy)))
        poses[name]=canvas;canvas.save(folder/f'normalized-{name}.png')
    dest=ROOT/'assets/hold-transitions-v1'/species/stage;dest.mkdir(parents=True,exist_ok=True)
    records={}
    for name,(start,end) in PAIRS.items():
        work=folder/name;inp=work/'in';out=work/'out';inp.mkdir(parents=True,exist_ok=True);out.mkdir(exist_ok=True)
        for i,pose in enumerate([poses[start],poses[end]]):
            bg=Image.new('RGBA',(256,256),(255,0,255,255));bg.alpha_composite(pose);bg.convert('RGB').save(inp/f'{i}.png')
        sig=hashlib.sha256((inp/'0.png').read_bytes()+(inp/'1.png').read_bytes()).hexdigest(); stamp=out/'source.sha256'
        if not stamp.exists() or stamp.read_text()!=sig:
            result=subprocess.run([str(RIFE/'rife-ncnn-vulkan.exe'),'-i',str(inp),'-o',str(out),'-n','32','-m',str(RIFE/'rife-v4.6'),'-g','0','-j','1:2:2','-z'],capture_output=True,text=True)
            if result.returncode:raise RuntimeError(result.stderr)
            stamp.write_text(sig)
        # Exact authored endpoints, not neural reconstructions of them.
        images=[poses[start]]+[unmatte(Image.open(out/f'{i+1:08d}.png')) for i in range(1,16)]+[poses[end]]
        atlas=Image.new('RGBA',(2048,768))
        for i,im in enumerate(images):atlas.paste(im,(i%8*256,i//8*256))
        atlas.save(dest/f'{name}.png')
        view=Image.new('RGB',(17*96,120),'#fff8ed');draw=ImageDraw.Draw(view)
        for i,im in enumerate(images):
            cel=im.resize((96,96));view.paste(cel,(i*96,22),cel);draw.text((i*96+3,4),str(i),fill='black')
        view.save(work/'review.png')
        records[name]={'count':COUNT,'start':start,'end':end,'first_exact':images[0].tobytes()==poses[start].tobytes(),'last_exact':images[-1].tobytes()==poses[end].tobytes()}
    (folder/'bake-review.json').write_text(json.dumps(records,indent=2))
    print('BRIDGES',species,stage,flush=True)
if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('species',nargs='*');p.add_argument('--jobs',type=int,default=2);a=p.parse_args()
    with ThreadPoolExecutor(max_workers=a.jobs) as pool:list(pool.map(build_case,[(s,stage) for s in (a.species or IDS) for stage in ['adult','baby']]))
