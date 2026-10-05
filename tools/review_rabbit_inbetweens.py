"""Display A, generated one-third, generated two-thirds, B in chronological rows."""
import json,urllib.request
from pathlib import Path
from PIL import Image,ImageDraw
ROOT=Path(__file__).resolve().parents[1]
WORK=ROOT/'design/rabbit-frame-pilot-v6'
jobs=json.loads((WORK/'generation-jobs.json').read_text(encoding='utf8'))['jobs']
indices=sorted({j['interval'] for j in jobs})
for page,start in enumerate(range(0,len(indices),5)):
    chunk=indices[start:start+5]
    out=Image.new('RGB',(1024,276*len(chunk)),'#fff8ed');d=ImageDraw.Draw(out)
    for row,i in enumerate(chunk):
        files=[WORK/'anchors'/f'{i:02d}.png',WORK/'inbetweens'/f'{i:02d}-1.png',WORK/'inbetweens'/f'{i:02d}-2.png',WORK/'anchors'/f'{(i+1)%19:02d}.png']
        for col,path in enumerate(files):
            if path.exists():out.paste(Image.open(path).convert('RGB').resize((256,256)),(col*256,row*276))
            d.text((col*256+10,row*276+256),f"{i:02d}: {['A','33%','67%','B'][col]}",fill='black')
    out.save(WORK/f'interval-review-{page+1}.png')
print(f'{len(indices)} intervals on {(len(indices)+4)//5} contact sheets')
