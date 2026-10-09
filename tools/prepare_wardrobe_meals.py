from PIL import Image
from bake_wardrobe_v3 import ROOT, WORK, matte
PHASES=[0,8,16,23,30,38,45,53]
atlas=Image.new('RGB',(2048,2048),(255,0,255))
for row,bank in enumerate(['eat','drink']):
    source=Image.open(ROOT/f'assets/rabbit-frame-pilot-v9/adult-{bank}.png').convert('RGBA')
    for k,index in enumerate(PHASES):
        cel=source.crop((index%8*256,index//8*256,index%8*256+256,index//8*256+256))
        i=row*8+k
        atlas.paste(matte(cel).resize((512,512),Image.Resampling.NEAREST),(i%4*512,i//4*512))
atlas.save(WORK/'meals-source.png')
