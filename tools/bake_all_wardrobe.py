"""Bake complete VARCO outfit poses for each remaining adult species."""
import argparse,json
from PIL import Image
import bake_wardrobe_v3 as bake
from bake_wardrobe_extras import keys,PAIRS

def build(species):
    bake.WORK=bake.ROOT/f'design/wardrobe-v3/motion/{species}/adult'
    bake.DEST=bake.ROOT/f'assets/wardrobe-motion-v3/{species}/adult'
    meta=json.loads((bake.ROOT/f'design/hold-transitions-v1/{species}/adult/poses.json').read_text())
    manifest={'version':3,'species':species,'stage':'adult','preview_only':True,'method':'complete generated cels; offline optical flow; no runtime limb separation','styles':{}}
    for style in ['vest','knit','apron']:
        core=keys(bake.WORK/f'{style}-core-generated.png')
        extra=keys(bake.WORK/f'{style}-extras-generated.png')
        spec={}
        for bank,indices,phases in [('walk',list(range(8)),[0,8,16,23,30,38,45,53,60]),('struggle',list(range(8,12)),[0,15,30,45,60])]:
            frames=[]
            for k,index in enumerate(indices):
                frames+=bake.interpolate(core[index],core[indices[(k+1)%len(indices)]],phases[k+1]-phases[k],bake.WORK/'short-paws-baked'/style/bank/str(k))
            spec[bank]=bake.pack(frames,style,bank)
        spec['idle']=bake.pack([core[12]],style,'idle')
        spec['dizzy']=bake.pack(extra[1:5],style,'dizzy')
        spec['emotions']=bake.pack(extra[5:9],style,'emotions')
        poses={'idle':core[12],'carry':extra[0],'dizzy0':extra[1],'dizzy3':extra[4],**{f'kick{i}':core[8+i] for i in range(4)}}
        # Shared transparent padding preserves exact body/grip geometry.
        for name,source in poses.items():
            calibration=meta[name];sx,sy=[200/calibration['height']*v for v in calibration['scale']]
            scaled=source.resize((round(256*sx),round(256*sy)),Image.Resampling.LANCZOS)
            canvas=Image.new('RGBA',(384,384))
            canvas.alpha_composite(scaled,(64+round(128-calibration['anchor'][0]*sx),64+round(232-calibration['anchor'][1]*sy)))
            poses[name]=canvas
        for name,(start,end) in PAIRS.items():
            frames=bake.interpolate(poses[start],poses[end],16,bake.WORK/'short-paws-baked'/style/('hold-'+name),endpoint=True)
            spec['hold-'+name]=bake.pack(frames,style,'hold-'+name)
            spec['hold-'+name].update(first_exact=frames[0].tobytes()==poses[start].tobytes(),last_exact=frames[-1].tobytes()==poses[end].tobytes())
        manifest['styles'][style]=spec
        print(species,style,'265 cels complete',flush=True)
    (bake.DEST/'manifest.json').write_text(json.dumps(manifest,indent=2))

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('species',nargs='+');args=p.parse_args()
    for species in args.species:build(species)
