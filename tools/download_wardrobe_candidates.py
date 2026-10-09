"""Fetch MCP-provided output URLs and assemble full-pose review sheets."""
import json,sys,urllib.request
from pathlib import Path
from PIL import Image,ImageDraw
root=Path(__file__).resolve().parents[1]
jobs=json.loads((root/sys.argv[1]).read_text(encoding='utf-8-sig'))
for job in jobs:
    path=root/f"design/wardrobe-v3/motion/{job['species']}/adult/{job['style']}-{job['bank']}-generated.png"
    if not path.exists():
        urllib.request.urlretrieve(job['url'],path)
    with Image.open(path) as image: image.verify()
for species in dict.fromkeys(j['species'] for j in jobs):
    folder=root/f'design/wardrobe-v3/motion/{species}/adult'
    canvas=Image.new('RGB',(1536,1056),'#fff8ec')
    for row,bank in enumerate(['core','extras']):
        for col,style in enumerate(['vest','knit','apron']):
            path=folder/f'{style}-{bank}-generated.png'
            if path.exists():
                with Image.open(path) as image: canvas.paste(image.convert('RGB').resize((512,512)),(col*512,row*528+16))
    ImageDraw.Draw(canvas).text((8,2),species,fill='black')
    canvas.save(folder/'candidates-review.jpg',quality=92)
print('downloaded/verified',len(jobs),'candidates')
