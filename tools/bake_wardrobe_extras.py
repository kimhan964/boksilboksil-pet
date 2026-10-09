"""Prepare complete costume cels and calibrated pickup/release bridges."""
import json
from PIL import Image
from bake_wardrobe_v3 import ROOT, WORK, DEST, key_generated, interpolate, pack

PAIRS={'pickup':('idle','carry'),'idle_entry':('idle','kick0'),
       'carry_entry':('carry','kick0'),'recover':('dizzy3','idle'),
       **{f'release{i}':(f'kick{i}','dizzy0') for i in range(4)}}

def keys(path):
    im=Image.open(path); size=im.width//4
    return [key_generated(im.crop((i%4*size,i//4*size,(i%4+1)*size,(i//4+1)*size))).resize((256,256),Image.Resampling.LANCZOS) for i in range(16)]

def build():
    manifest=json.loads((DEST/'manifest.json').read_text(encoding='utf-8'))
    meta=json.loads((ROOT/'design/hold-transitions-v1/rabbit/adult/poses.json').read_text())
    for style in ['vest','knit','apron']:
        core=keys(WORK/f'{style}-short-paws-generated.png')
        extra=keys(WORK/f'{style}-extras-generated.png')
        spec=manifest['styles'][style]
        for bank,indices in [('eat',[9,10,11,12]),('drink',[13,14,15])]:
            frames=[]; interval=60//len(indices)
            for k,index in enumerate(indices):
                frames+=interpolate(extra[index],extra[indices[(k+1)%len(indices)]],interval,WORK/'short-paws-baked'/style/bank/str(k))
            spec[bank]=pack(frames,style,bank)
        spec['dizzy']=pack(extra[1:5],style,'dizzy')
        spec['emotions']=pack(extra[5:9],style,'emotions')
        poses={'idle':core[0],'carry':extra[0],'dizzy0':extra[1],'dizzy3':extra[4],**{f'kick{i}':core[8+i] for i in range(4)}}
        for name,source in poses.items():
            calibration=meta[name]
            sx,sy=[200/calibration['height']*v for v in calibration['scale']]
            scaled=source.resize((round(256*sx),round(256*sy)),Image.Resampling.LANCZOS)
            canvas=Image.new('RGBA',(256,256))
            canvas.alpha_composite(scaled,(round(128-calibration['anchor'][0]*sx),round(232-calibration['anchor'][1]*sy)))
            poses[name]=canvas
        for name,(start,end) in PAIRS.items():
            frames=interpolate(poses[start],poses[end],16,WORK/'short-paws-baked'/style/('hold-'+name),endpoint=True)
            spec['hold-'+name]=pack(frames,style,'hold-'+name)
            spec['hold-'+name].update(first_exact=frames[0].tobytes()==poses[start].tobytes(),last_exact=frames[-1].tobytes()==poses[end].tobytes())
        print('WARDROBE EXTRAS',style,'meals/expressions/dizzy and 8 bridges complete',flush=True)
        (DEST/'manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')

if __name__=='__main__': build()
