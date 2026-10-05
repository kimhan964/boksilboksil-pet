"""Arrange native game captures for inspection; never used as game assets."""
from pathlib import Path
from PIL import Image,ImageDraw
import json
root=Path(__file__).resolve().parents[1]/'home-v2-native-matrix'
records=json.loads((root/'report.json').read_text(encoding='utf-8'))
for species in dict.fromkeys(r['species'] for r in records):
    page=Image.new('RGB',(1250,880),'#faf8f3');draw=ImageDraw.Draw(page)
    for i,r in enumerate(x for x in records if x['species']==species):
        pet=Image.open(root/(r['name']+'-pet.png')).convert('RGBA')
        if pet.getchannel('A').getbbox() is None:
            raise ValueError('Empty native pet capture: '+r['name'])
        furniture=Image.open(root/(r['name']+'-furniture.png')).convert('RGBA')
        origin=(min(r['pet'][0],r['furniture'][0]),min(r['pet'][1],r['furniture'][1]))
        canvas=Image.new('RGBA',(400,320),(250,248,243,255))
        for im,pos in [(furniture,r['furniture']),(pet,r['pet'])]:
            canvas.alpha_composite(im,(pos[0]-origin[0],pos[1]-origin[1]))
        # Same camera for every review tile: keep native scale, crop only the
        # empty top margin common to this 400 x 320 review canvas.
        canvas=canvas.crop((20,60,330,320));canvas.thumbnail((248,198))
        x=i%5*250;y=i//5*220
        page.paste(canvas,(x,y+20));draw.text((x+4,y+3),r['age']+' / '+r['id'],fill='#494b42')
    page.save(root/(species+'-review.jpg'),quality=92)
print('review pages',len(set(r['species'] for r in records)),'native cases',len(records))
