from PIL import Image
from bake_wardrobe_v3 import ROOT, matte
import json
folder=ROOT/'design/wardrobe-v3/motion/cat/adult';folder.mkdir(parents=True,exist_ok=True)
spec=json.loads((ROOT/'assets/walk-v14/cat/manifest.json').read_text())['stages']['adult']
def cel(path,index=0,columns=8):
    im=Image.open(ROOT/path).convert('RGBA')
    return im.crop((index%columns*256,index//columns*256,index%columns*256+256,index//columns*256+256))
walk=[cel('assets/walk-v14/cat/'+spec['file'],i) for i in [0,8,16,23,30,38,45,53]]
idle=cel('assets/walk-v14/cat/'+spec['idle_file'])
kick=[cel('assets/struggle-v1/cat/adult.png',i) for i in [0,15,30,45]]
extra=[cel('design/hold-transitions-v1/cat/adult/carry.png')]
extra += [cel('assets/dizzy-v1/cat/adult.png',i,4) for i in range(4)]
extra += [cel('assets/emotions-v1/cat/adult.png',i,4) for i in range(4)]
extra += [idle]*7
for name,cels in [('core',walk+kick+[idle]*4),('extras',extra)]:
    sheet=Image.new('RGB',(2048,2048),(255,0,255))
    for i,im in enumerate(cels): sheet.paste(matte(im).resize((512,512),Image.Resampling.NEAREST),(i%4*512,i//4*512))
    sheet.save(folder/f'{name}-source.png')
