"""Pack unchanged full-body action references; retain per-cell registration."""
from pathlib import Path
from PIL import Image
import json
ROOT=Path(__file__).resolve().parents[1]
DEST=ROOT/'design/wardrobe-v3/motion/rabbit/adult'
sheet=Image.new('RGBA',(2048,2048),(255,0,255,255));records=[]
def add(path,index,columns,bank):
    im=Image.open(ROOT/path).convert('RGBA')
    cel=im.crop((index%columns*256,index//columns*256,index%columns*256+256,index//columns*256+256))
    i=len(records);sheet.alpha_composite(cel.resize((512,512),Image.Resampling.NEAREST),(i%4*512,i//4*512))
    records.append(dict(cell=i,source=path,index=index,columns=columns,bank=bank))
add('design/hold-transitions-v1/rabbit/adult/carry.png',0,1,'carry')
for i in range(4):add('assets/dizzy-v1/rabbit/adult.png',i,4,'dizzy')
for i in range(4):add('assets/emotions-v1/rabbit/adult.png',i,4,'expression')
for i in [0,15,30,45]:add('assets/rabbit-frame-pilot-v9/adult-eat.png',i,8,'eat')
for i in [0,20,40]:add('assets/rabbit-frame-pilot-v9/adult-drink.png',i,8,'drink')
assert len(records)==16
sheet.convert('RGB').save(DEST/'extra-source.png')
(DEST/'extra-source.json').write_text(json.dumps(records,indent=2))
