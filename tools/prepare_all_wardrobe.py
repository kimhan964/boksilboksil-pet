"""Extract full original poses for VARCO wardrobe edits; no limb separation."""
import json
from PIL import Image
from bake_wardrobe_v3 import ROOT, matte

def cel(path,index=0,columns=8):
    im=Image.open(ROOT/path).convert('RGBA')
    return im.crop((index%columns*256,index//columns*256,(index%columns+1)*256,(index//columns+1)*256))

def prepare():
    plan=json.loads((ROOT/'design/wardrobe-v3/catalog-plan.json').read_text(encoding='utf-8'))
    for pet in plan['species']:
        species=pet['id']
        if species in ['rabbit','cat']: continue
        folder=ROOT/f'design/wardrobe-v3/motion/{species}/adult'
        folder.mkdir(parents=True,exist_ok=True)
        spec=json.loads((ROOT/f'assets/walk-v14/{species}/manifest.json').read_text())['stages']['adult']
        walk=[cel(f'assets/walk-v14/{species}/'+spec['file'],i) for i in [0,8,16,23,30,38,45,53]]
        idle=cel(f'assets/walk-v14/{species}/'+spec['idle_file'])
        kick=[cel(f'assets/struggle-v1/{species}/adult.png',i) for i in [0,15,30,45]]
        extra=[cel(f'design/hold-transitions-v1/{species}/adult/carry.png')]
        extra += [cel(f'assets/dizzy-v1/{species}/adult.png',i,4) for i in range(4)]
        extra += [cel(f'assets/emotions-v1/{species}/adult.png',i,4) for i in range(4)]
        extra += [idle]*7
        for name,cels in [('core',walk+kick+[idle]*4),('extras',extra)]:
            sheet=Image.new('RGB',(2048,2048),(255,0,255))
            for i,im in enumerate(cels): sheet.paste(matte(im).resize((512,512),Image.Resampling.NEAREST),(i%4*512,i//4*512))
            sheet.save(folder/f'{name}-source.png')
        print(species,'source poses ready',flush=True)

if __name__=='__main__': prepare()
